use aztec::macros::aztec;

#[aztec]
pub contract CMTATAztecDebt {
    // Libs
    use compressed_string::FieldCompressedString;

    use aztec::{
        authwit::auth::compute_authwit_nullifier,
        context::PrivateContext,
        macros::{
            events::event,
            functions::{authorize_once, external, initializer, internal, only_self, view},
            storage::storage,
        },
        messages::delivery::MessageDelivery,
        protocol::{address::AztecAddress, traits::ToField},
        state_vars::{DelayedPublicMutable, Owned, PublicImmutable, PublicMutable},
    };

    use balance_set::BalanceSet;

    use cmtat_aztec_lib::modules::{
        access_controlModule::{AccessControlModule, DEFAULT_ADMIN_ROLE, VALIDATION_ROLE},
        enforcementModule::{
            CHANGE_ROLES_DELAY_SECONDS as FREEZE_DELAY_SECONDS, Freezable, FreezableFlag,
        },
        extensions::{
            creditEventsModule::{CreditEvents, CreditEventsStruct},
            debtModule::{Debt, DebtInformation, DebtInstrument},
        },
        extraInformationModule::{DocumentInfo, ExtraInformation},
        hybridModule::{PRIVATE_ADDRESS_MAGIC_VALUE, PublicBalances, require_public_side_enabled},
        pauseModule::PauseModule,
        tokenModule::{
            bridge_private_to_public, bridge_public_to_private, burn_private, burn_public,
            credit_public, debit_public, debit_recursive, FreezeAndLists, mint_private, mint_public,
            open_commitment, pay_commitment, require_transfer, transfer_private,
        },
        validationModule::{SetFlag, UserFlags, ValidationModule},
    };

    // The initial delay of every delayed value of this contract (issuer address, freeze flags, list flags,
    // list mode): the library's constant, re-exported so tests and scripts read it from the contract.
    // Adjustable at runtime with `set_roles_delay`; see the library constant's comment and review
    // finding H-6 for the choice of one hour.
    pub global CHANGE_ROLES_DELAY_SECONDS: u64 = FREEZE_DELAY_SECONDS;
    /// Upper bound accepted by `set_roles_delay`: the protocol's transaction lifetime. A longer delay
    /// would widen no validity window (the protocol caps inclusion at 24 h) and only lengthen the
    /// freeze window; at exactly this value the token's transactions expire like any transaction that
    /// reads no delayed value, the largest privacy set (H-6).
    pub global MAX_ROLES_DELAY_SECONDS: u64 = 86400;

    // The version of this token implementation, following semantic versioning, exposed by `version()`.
    //
    // Deliberately a compile-time constant rather than a stored value: it therefore cannot be
    // desynchronised from the deployed code, which is the failure the CMTAT criteria warn about for
    // admin-writable version fields. It must be bumped in the same commit as any release.
    //
    // Padded to 31 characters because `FieldCompressedString::from_string` takes a `str<31>`;
    // consumers should trim the trailing spaces.
    pub global VERSION: str<31> = "0.4.0                          ";

    // How many addresses one batched call may act on.
    //
    // 4 is the measured ceiling, not a guess. `transfer` is the binding path: it creates two notes
    // and two constrained deliveries per recipient, so it saturates the per-call note-hash and log
    // budgets at roughly twice the rate of mint. Running the Noir suite at each value:
    //
    //   1, 2, 4 -> every test passes
    //   5       -> transfer passes, but batched mint and burn end with a wrong total supply
    //   6, 8    -> transfer aborts with "Assertion failed: push out of bounds"
    //
    // The private-call budget (MAX_PRIVATE_CALL_STACK_LENGTH_PER_CALL) does not enter into it: the
    // `_*_internal` helpers are `#[internal("private")]` and are inlined, so a batch makes no nested
    // private calls at all whatever this value is.
    //
    // Raising this further requires re-measuring, not re-reading the protocol constants - and note
    // that the per-recipient work is what grows, so the proof the *user's own device* must produce
    // grows with it (453k gates for a 4-recipient transfer against 119k for one).
    global MAX_ADDR_PER_CALL: u32 = 4;

    // `transfer_batch` has its own, lower cap. A transfer delivers four constrained messages per
    // recipient - the change note to the sender, the recipient's note, and the Transfer event to
    // both the recipient and the issuer - where a mint or burn delivers one or two. Measured under
    // that delivery: 2 recipients pass, 3 and 4 abort with "push out of bounds". A model consistent
    // with every observation is that each constrained delivery consumes two of the sixteen
    // key-validation requests a call may make (4 x 2 x 2 = 16 fitted before the issuer event was
    // constrained; 3 x 4 x 2 = 24 does not), but the number is the measurement, not the model.
    global MAX_TRANSFER_ADDR_PER_CALL: u32 = 2;

    // How every note created by this contract is additionally delivered to the issuer (see the
    // `deliver_to(issuer, ...)` calls below), which is what makes holder balances auditable.
    //
    // This is offchain rather than onchain because PXE cannot process an onchain note message addressed
    // to someone who is not the note's owner: note discovery computes the note's nullifier, and that
    // needs the owner's nullifier key, which the issuer does not have. Switching this to
    // `MessageDelivery::onchain_constrained()` is what the framework documents for an auditor, and it
    // compiles, but every note the issuer receives for another holder then fails discovery.
    //
    // The consequence of offchain delivery is that the issuer's copy has no onchain data availability:
    // the issuer must capture these messages as they are produced, and a sender who drops them is not
    // detectable onchain.

    #[event]
    struct Transfer {
        from: AztecAddress,
        to: AztecAddress,
        amount: u128,
    }

    // Hybrid: the issuer's record of a partial note opened for `to` (see initialize_transfer_commitment).
    #[event]
    struct CommitmentInitialized {
        to: AztecAddress,
        completer: AztecAddress,
        commitment: Field,
    }

    #[event]
    struct NewRole {
        role: Field,
        account: AztecAddress,
    }

    #[event]
    struct Deactivated {
        account: AztecAddress,
    }

    #[event]
    struct TokenId {
        tokenId: FieldCompressedString,
    }

    // Mirrors the CMTAT Solidity `event Terms(CMTATTerms newTerm)`, which carries the whole stored
    // terms rather than just the caller: `_setTerms` emits `Terms($._terms)` after writing. The
    // fields are the flattened `CMTATTerms` — the document name, its URI, the 256-bit content hash
    // split into two 128-bit halves, and the `lastModified` the contract stamped.
    #[event]
    struct Terms {
        name: FieldCompressedString,
        uri: FieldCompressedString,
        documentHashHigh: u128,
        documentHashLow: u128,
        lastModified: u64,
    }

    // CMTAT Solidity emits `DebtLogEvent`, `DebtInstrumentLogEvent` and `CreditEventsLogEvent` with
    // no payload, to keep the contract small: a reader is expected to call the getter afterwards.
    // These carry the caller instead, matching `NewRole` and `Deactivated` above - the values
    // themselves are public state and can still be read with `get_debt()` / `get_credit_events()`.
    #[event]
    struct DebtLogEvent {
        account: AztecAddress,
    }

    #[event]
    struct DebtInstrumentLogEvent {
        account: AztecAddress,
    }

    #[event]
    struct CreditEventsLogEvent {
        account: AztecAddress,
    }

    // --- C-6: administrative operations now leave a trail ---------------------------------------
    // Names follow the reference where one exists: `Paused` / `Unpaused` and `RoleRevoked` are the
    // OpenZeppelin events CMTAT Solidity inherits (`NewRole` above corresponds to `RoleGranted`);
    // `AddressFrozen` is CMTAT's own. The freeze and list flags are DelayedPublicMutable, so those
    // events also carry `effective_at`: the timestamp from which the scheduled value is current.
    // It is computed as block timestamp + the module's delay, which is exactly what
    // DelayedPublicMutable::schedule_value_change records; it stays exact because neither module ever
    // reschedules its delay.

    #[event]
    struct Paused {
        account: AztecAddress,
    }

    #[event]
    struct Unpaused {
        account: AztecAddress,
    }

    #[event]
    struct RoleRevoked {
        role: Field,
        account: AztecAddress,
        sender: AztecAddress,
    }

    #[event]
    struct IssuerChanged {
        issuer: AztecAddress,
        operator: AztecAddress,
        effective_at: u64,
    }

    /// The delay setting of the delayed values changed. `effective_at` is when the new delay governs the
    /// issuer address (and the list mode, where present): at once for an increase, after the difference
    /// for a decrease. Per-address entries adopt it when they are next written.
    #[event]
    struct RolesDelayChanged {
        new_delay: u64,
        operator: AztecAddress,
        effective_at: u64,
    }

    #[event]
    struct AddressFrozen {
        account: AztecAddress,
        is_frozen: bool,
        enforcer: AztecAddress,
        effective_at: u64,
    }

    #[event]
    struct AddressListed {
        account: AztecAddress,
        is_blacklisted: bool,
        is_whitelisted: bool,
        operator: AztecAddress,
        effective_at: u64,
    }

    #[event]
    struct OperationsSet {
        operate_blacklist: bool,
        operate_whitelist: bool,
        operator: AztecAddress,
        effective_at: u64,
    }

    #[storage]
    struct Storage<Context> {
        pause_module: PauseModule<Context>,
        validation_module: ValidationModule<UserFlags, Context>,
        enforcement_module: Freezable<FreezableFlag, Context>,
        access_control: AccessControlModule<bool, Context>,
        credit_event_module: CreditEvents<bool, Context>,
        debt_module: Debt<bool, Context>,
        extra_information_module: ExtraInformation<bool, Context>,

        issuer_address: DelayedPublicMutable<AztecAddress, CHANGE_ROLES_DELAY_SECONDS, Context>,

        private_balances: Owned<BalanceSet<Context>, Context>,

        total_supply: PublicMutable<u128, Context>,
        symbol: PublicImmutable<FieldCompressedString, Context>,
        name: PublicImmutable<FieldCompressedString, Context>,
        decimals: PublicImmutable<u8, Context>,

        // Hybrid: the public balances and whether the bridges to them are open. Appended last so the
        // slots above are unchanged.
        public_balances: PublicBalances<Context>,
        public_side_enabled: PublicImmutable<bool, Context>,
        // Appended last so that no existing slot moves (the private-balance slot is pinned by a test).
        roles_delay: PublicMutable<u64, Context>,
    }

    #[external("public")]
    #[initializer]
    // `public_side_enabled` is the issuer's deployment-time choice: whether holders may move value
    // between their private notes and a public balance (the four AIP-20 bridges). Off reproduces the
    // fully private token; it cannot be changed after deployment.
    fn constructor(
        admin: AztecAddress,
        name: str<31>,
        symbol: str<31>,
        decimals: u8,
        public_side_enabled: bool,
    ) {
        assert(!admin.is_zero(), "invalid admin");
        self.storage.name.initialize(FieldCompressedString::from_string(name));
        self.storage.symbol.initialize(FieldCompressedString::from_string(symbol));
        self.storage.decimals.initialize(decimals);
        self.storage.public_side_enabled.initialize(public_side_enabled);
        self.internal._grant_role_internal(DEFAULT_ADMIN_ROLE, admin);
        self.internal._grant_role_internal(VALIDATION_ROLE, admin);

        self.storage.issuer_address.schedule_value_change(admin);
        self.storage.roles_delay.write(CHANGE_ROLES_DELAY_SECONDS);
    }

    /** ==========================================================
     * ===================== AUTHORIZATION MODULE ================
     * ======================================================== */

    #[external("public")]
    #[view]
    fn has_role(role: Field, account: AztecAddress) -> pub Field {
        self.storage.access_control.has_role(role, account).to_field()
    }

    #[external("public")]
    #[view]
    fn only_role(role: Field, caller: AztecAddress) {
        self.storage.access_control.only_role(role, caller);
    }

    #[external("public")]
    fn grant_role(role: Field, account: AztecAddress) {
        self.storage.access_control.only_role_admin(role, self.msg_sender());
        self.internal._grant_role_internal(role, account);
    }

    /**
     * @roles: onlyAdmin
     * @notice: revoking a pause contract role when the contract is paused can cause the contract to be stuck in a paused state.
     */
    #[external("public")]
    fn revoke_role(role: Field, account: AztecAddress) {
        let sender = self.msg_sender();
        self.storage.access_control.revoke_role(role, account, sender);
        self.emit(RoleRevoked { role, account, sender });
    }

    #[external("public")]
    fn renounce_role(role: Field, callerConfirmation: AztecAddress) {
        let sender = self.msg_sender();
        self.storage.access_control.renounce_role(role, sender, callerConfirmation);
        self.emit(RoleRevoked { role, account: sender, sender });
    }

    /** ==========================================================
     * ===================== VALIDATION MODULE ===================
     * ======================================================== */

    #[external("public")]
    #[view]
    fn get_operations() -> pub Field {
        self.storage.validation_module.get_operations()
    }

    #[external("public")]
    fn set_operations(operations: SetFlag) {
        let operator = self.msg_sender();
        let effective_at = self.storage.validation_module.set_operations(
            operator,
            operations,
            self.storage.access_control,
        );
        self.emit(
            OperationsSet {
                operate_blacklist: operations.operate_blacklist,
                operate_whitelist: operations.operate_whitelist,
                operator,
                effective_at,
            },
        );
    }

    #[external("public")]
    fn add_to_list(newListAddress: AztecAddress, userFlag: UserFlags) {
        let operator = self.msg_sender();
        let effective_at = self.storage.validation_module.add_to_list(
            operator,
            newListAddress,
            userFlag,
            self.storage.access_control,
            self.storage.roles_delay.read(),
        );
        self.internal._emit_listed(newListAddress, userFlag, operator, effective_at);
    }

    #[external("public")]
    fn remove_from_list(removeListAddress: AztecAddress, userFlag: UserFlags) {
        let operator = self.msg_sender();
        let effective_at = self.storage.validation_module.remove_from_list(
            operator,
            removeListAddress,
            userFlag,
            self.storage.access_control,
            self.storage.roles_delay.read(),
        );
        self.internal._emit_listed(removeListAddress, userFlag, operator, effective_at);
    }

    /// `add_to_list` and `remove_from_list` both schedule the same kind of change - a new flag set for
    /// an address - so they share one event, emitted here so its shape lives in one place.
    #[internal("public")]
    fn _emit_listed(
        account: AztecAddress,
        flags: UserFlags,
        operator: AztecAddress,
        effective_at: u64,
    ) {
        self.emit(
            AddressListed {
                account,
                is_blacklisted: flags.is_blacklisted,
                is_whitelisted: flags.is_whitelisted,
                operator,
                effective_at,
            },
        );
    }

    /** ==========================================================
     * ===================== PAUSE MODULE ========================
     * ======================================================== */

    #[external("public")]
    #[view]
    fn public_get_pause() -> pub Field {
        self.storage.pause_module.is_paused().to_field()
    }

    /**
     * @roles: onlyAdmin
     * @notice: The contract must not be paused.
     */
    #[external("public")]
    fn pause_contract() {
        let admin = self.msg_sender();
        self.storage.pause_module.pause(admin, self.storage.access_control);
        self.emit(Paused { account: admin });
    }

    #[external("public")]
    fn unpause_contract() {
        let admin = self.msg_sender();
        self.storage.pause_module.unpause(admin, self.storage.access_control);
        self.emit(Unpaused { account: admin });
    }

    #[external("public")]
    #[view]
    fn public_get_deactivated() -> pub Field {
        self.storage.pause_module.is_deactivated().to_field()
    }

    /**
     * @roles: onlyAdmin
     * @notice: Permanently deactivates the token. This cannot be undone.
     *
     * Requirements:
     * - The caller must have the admin role.
     * - The contract must already be paused.
     * - The contract must not already be deactivated.
     */
    #[external("public")]
    fn deactivate_contract() {
        let admin = self.msg_sender();
        self.storage.pause_module.deactivate(admin, self.storage.access_control);
        self.emit(Deactivated { account: admin });
    }

    /** ==========================================================
     * ===================== ENFORCEMENT MODULE ==================
     * ======================================================== */

    #[external("public")]
    #[view]
    fn get_frozen(user: AztecAddress) -> pub Field {
        self.storage.enforcement_module.is_frozen(user).to_field()
    }

    #[external("public")]
    fn freeze(user: AztecAddress, value: FreezableFlag) {
        let enforcer = self.msg_sender();
        let effective_at = self.storage.enforcement_module.freeze(
            enforcer,
            user,
            value,
            self.storage.access_control,
            self.storage.roles_delay.read(),
        );
        self.emit(
            AddressFrozen { account: user, is_frozen: value.is_freezed, enforcer, effective_at },
        );
    }

    #[external("public")]
    fn unfreeze(user: AztecAddress, value: FreezableFlag) {
        let enforcer = self.msg_sender();
        let effective_at = self.storage.enforcement_module.unfreeze(
            enforcer,
            user,
            value,
            self.storage.access_control,
            self.storage.roles_delay.read(),
        );
        self.emit(
            AddressFrozen { account: user, is_frozen: value.is_freezed, enforcer, effective_at },
        );
    }

    /** ==========================================================
     * ===================== CREDIT EVENTS MODULE ================
     * ======================================================== */

    /**
     * @dev Replaces all three credit-event attributes, as in CMTAT Solidity: a caller that wants to
     * keep a value MUST re-supply it.
     *
     * Requirements:
     * - the caller must have the DEBT_CREDIT_EVENT_ROLE role.
     */
    #[external("public")]
    fn set_credit_events(credit_events: CreditEventsStruct) {
        self.storage.credit_event_module.setCreditEvents(
            credit_events,
            self.msg_sender(),
            self.storage.access_control,
        );
        self.emit(CreditEventsLogEvent { account: self.msg_sender() });
    }

    #[external("public")]
    #[view]
    fn get_credit_events() -> pub [Field; 3] {
        self.storage.credit_event_module.get_credit_events()
    }

    /** ==========================================================
     * ===================== DEBT MODULE =========================
     * ======================================================== */

    /**
     * @dev Replaces the whole debt record - both the identifier and the instrument - as in CMTAT
     * Solidity `setDebt`. A caller that wants to keep a value MUST re-supply it.
     *
     * Requirements:
     * - the caller must have the DEBT_ROLE role.
     */
    #[external("public")]
    fn set_debt(debt_: DebtInformation) {
        self.storage.debt_module.setDebt(debt_, self.msg_sender(), self.storage.access_control);
        self.emit(DebtLogEvent { account: self.msg_sender() });
    }

    /**
     * @dev Replaces only the instrument's terms, leaving the debt identifier as it is, as in CMTAT
     * Solidity `setDebtInstrument`.
     *
     * Requirements:
     * - the caller must have the DEBT_ROLE role.
     */
    #[external("public")]
    fn set_debt_instrument(debt_instrument_: DebtInstrument) {
        self.storage.debt_module.setDebtInstrument(
            debt_instrument_,
            self.msg_sender(),
            self.storage.access_control,
        );
        self.emit(DebtInstrumentLogEvent { account: self.msg_sender() });
    }

    /**
     * @dev Returns the debt record serialized: the four identifier attributes first, then the
     * twelve instrument attributes, in the order of the CMTAT Solidity structs.
     */
    #[external("public")]
    #[view]
    fn get_debt() -> pub [Field; 16] {
        self.storage.debt_module.get_debt()
    }

    /** ==========================================================
     * ===================== EXTRA INFORMATION MODULE ============
     * ======================================================== */

    /**
     * @roles: onlyExtraInformationManager
     * @notice: Sets the reference to the legally required documentation.
     * @dev: Every field is replaced; a caller that wants to keep a value must re-supply it.
     * `lastModified` is stamped by the contract from the block timestamp.
     */
    #[external("public")]
    fn set_terms(terms_: DocumentInfo) {
        // Read the timestamp once so the event reports exactly the `lastModified` that was stored.
        let last_modified = self.context.timestamp();
        self.storage.extra_information_module.setTerms(
            terms_,
            last_modified,
            self.msg_sender(),
            self.storage.access_control,
        );
        self.emit(
            Terms {
                name: terms_.name,
                uri: terms_.uri,
                documentHashHigh: terms_.documentHashHigh,
                documentHashLow: terms_.documentHashLow,
                lastModified: last_modified,
            },
        );
    }

    #[external("public")]
    #[view]
    fn terms() -> pub [Field; 5] {
        self.storage.extra_information_module.get_terms()
    }

    /**
     * @roles: onlyExtraInformationManager
     * @notice: Sets the token identifier of the tokenized asset.
     * @dev: As in CMTAT Solidity, the value is written even when it equals the current one.
     */
    #[external("public")]
    fn set_token_id(tokenId_: FieldCompressedString) {
        self.storage.extra_information_module.setTokenId(
            tokenId_,
            self.msg_sender(),
            self.storage.access_control,
        );
        self.emit(TokenId { tokenId: tokenId_ });
    }

    #[external("public")]
    #[view]
    fn token_id() -> pub FieldCompressedString {
        self.storage.extra_information_module.get_token_id()
    }

    /** ==========================================================
     * ===================== VIEW FUNCTIONS ======================
     * ======================================================== */

    /**
     * @notice The version of this token implementation, e.g. "0.3.0".
     * @dev A compile-time constant, as in the CMTAT Solidity `VersionModule`: it identifies the
     * version of the code, not of the issued security and not of any assessment document. It changes
     * only through a new deployment. Aztec's contract class ID also identifies the deployed artifact,
     * but it is a hash and does not carry a semantic version, so the two are complementary.
     */
    #[external("public")]
    #[view]
    fn version() -> pub FieldCompressedString {
        FieldCompressedString::from_string(VERSION)
    }

    #[external("public")]
    #[view]
    fn name() -> pub FieldCompressedString {
        self.storage.name.read()
    }

    #[external("private")]
    #[view]
    fn private_get_name() -> pub FieldCompressedString {
        self.storage.name.read()
    }

    #[external("public")]
    #[view]
    fn symbol() -> pub FieldCompressedString {
        self.storage.symbol.read()
    }

    #[external("private")]
    #[view]
    fn private_get_symbol() -> pub FieldCompressedString {
        self.storage.symbol.read()
    }

    #[external("public")]
    #[view]
    fn decimals() -> pub u8 {
        self.storage.decimals.read()
    }

    #[external("private")]
    #[view]
    fn private_get_decimals() -> pub u8 {
        self.storage.decimals.read()
    }

    #[external("public")]
    #[view]
    fn total_supply() -> pub u128 {
        self.storage.total_supply.read()
    }

    /**
     * @roles: onlyAdmin
     * @notice: Schedules a change of the issuer - the address that receives a copy of every note and
     * so can audit holder balances. Takes effect after CHANGE_ROLES_DELAY_SECONDS, like every other
     * DelayedPublicMutable here; until then mint, transfer and burn keep addressing the old issuer.
     * @dev: Copies already delivered to the previous issuer are not recalled - a delivered note cannot
     * be. Rotating the issuer therefore transfers *future* audit visibility only; the previous issuer
     * keeps what it has. Choose the new address with that in mind: it needs a PXE that can decrypt
     * and store the copies from the moment the change takes effect.
     *
     * Requirements:
     * - The caller must have the admin role.
     * - The new issuer must not be the zero address.
     */
    #[external("public")]
    fn set_issuer(new_issuer: AztecAddress) {
        assert(!new_issuer.is_zero(), "invalid issuer");
        let operator = self.msg_sender();
        self.storage.access_control.only_role(DEFAULT_ADMIN_ROLE, operator);
        self.storage.issuer_address.schedule_value_change(new_issuer);
        let (_, effective_at) = self.storage.issuer_address.get_scheduled_value();
        self.emit(IssuerChanged { issuer: new_issuer, operator, effective_at });
    }

    /**
     * @dev Changes the delay of every delayed value (review H-6). Applies at once to the issuer address and the
     * list mode (a longer delay immediately, a shorter one after the difference, as the library
     * guarantees); per-address freeze and list entries adopt the new setting when they are next
     * written, because a `Map` entry carries its own delay. Bounded by `MAX_ROLES_DELAY_SECONDS`.
     *
     * Requirements:
     * - The caller must have the DEFAULT_ADMIN_ROLE.
     * - `1 <= new_delay <= MAX_ROLES_DELAY_SECONDS`.
     */
    #[external("public")]
    fn set_roles_delay(new_delay: u64) {
        assert(new_delay > 0, "invalid delay");
        assert(new_delay <= MAX_ROLES_DELAY_SECONDS, "delay above the transaction lifetime");
        let operator = self.msg_sender();
        self.storage.access_control.only_role(DEFAULT_ADMIN_ROLE, operator);
        self.storage.roles_delay.write(new_delay);
        self.storage.issuer_address.schedule_delay_change(new_delay);
        self.storage.validation_module.operationsFlag.schedule_delay_change(new_delay);
        let (_, effective_at) = self.storage.issuer_address.get_scheduled_delay();
        self.emit(RolesDelayChanged { new_delay, operator, effective_at });
    }

    /// The delay setting new writes adopt, in seconds. Not the delay currently governing every entry:
    /// an entry written before a change keeps its previous delay until it is written again.
    #[external("public")]
    #[view]
    fn roles_delay() -> pub u64 {
        self.storage.roles_delay.read()
    }

    #[external("public")]
    #[view]
    fn public_get_issuer() -> pub AztecAddress {
        self.storage.issuer_address.get_current_value()
    }

    #[external("private")]
    #[view]
    fn private_get_issuer() -> pub AztecAddress {
        self.storage.issuer_address.get_current_value()
    }

    /** ==========================================================
     * ===================== MINT ================================
     * ======================================================== */

    /**
    * @dev: Mints tokens to the specified address. The chain (recipient screening, note + issuer copy)
    * is `tokenModule::mint_private`; the enqueued `_mint` checks MINTER_ROLE and deactivation and
    * updates the supply. No authwit: only a minter may mint.
    *
    * Requirements:
    * - The contract must not be deactivated. A pause does not stop a mint, as in CMTAT Solidity.
    * - The recipient must not be frozen and must pass the validation module's list check (blacklist or whitelist).
    * - The caller must have the minter role.
    */
    #[external("private")]
    fn mint_to_private(to: AztecAddress, amount: u128) {
        let issuer = self.storage.issuer_address.get_current_value();
        mint_private(
            self.storage.private_balances,
            screening(self.storage),
            to,
            amount,
            issuer,
        );
        self.enqueue_self._mint(self.msg_sender(), amount);
        // The issuer's on-chain record of the issuance (H-10, route A): the note copy it receives
        // offchain cannot be processed by a stock PXE (it does not own the note), the event can.
        // `from` is the zero address, the ERC-20 / AIP-20 convention for a mint, so one `Transfer`
        // stream replays every movement. Constrained, so the minter cannot forge it.
        self.emit(Transfer { from: AztecAddress::zero(), to, amount }).deliver_to(
            issuer,
            MessageDelivery::onchain_constrained(),
        );
    }

    //everyone can call this function, but will revert in _mint if not minter role
    #[external("private")]
    fn mint_batch(accounts: [AztecAddress; MAX_ADDR_PER_CALL], amount: [u128; MAX_ADDR_PER_CALL]) {
        let mut acc: u128 = 0;
        // Loop-invariant: one issuer for the whole call, read once rather than per address.
        let issuer = self.storage.issuer_address.get_current_value();
        for i in 0..MAX_ADDR_PER_CALL {
            mint_private(
                self.storage.private_balances,
                screening(self.storage),
                accounts[i],
                amount[i],
                issuer,
            );
            acc += amount[i];
            // One issuance record per recipient, as in `mint_to_private` (H-10, route A).
            self
                .emit(Transfer { from: AztecAddress::zero(), to: accounts[i], amount: amount[i] })
                .deliver_to(issuer, MessageDelivery::onchain_constrained());
        }
        self.enqueue_self._mint(self.msg_sender(), acc);
    }

    /** ==========================================================
     * ===================== TRANSFER ============================
     * ======================================================== */

    /**
    * @dev Spends notes, emits a new note (UintNote) with any remaining change, and sends a note to the recipient. Sends
    the 'change' encrypted note to the issuer. The chain is `tokenModule::transfer_private`.
    *
    * - If caller (self.msg_sender()) != from: the #[authorize_once] macro validates an authwit. In order to
    * not allow double spending of the authwit, the nonce is used to ensure that the authwit
    * can only be used once. Effectively, repeating the same nonce emits the same nullifier, which is not allowed at
    * protocol level.
    * - If caller == from: it's a usual transfer and `authwit_nonce` must be 0.
    *
    * Requirements:
    * - The contract must not be paused.
    * - The sender/recipient must not be frozen and must respect the list constraints of the validation module.
    * - The sender must have enough balance to cover the transfer.
    * - The authwit must be valid if the caller is not the sender.
    */
    #[authorize_once("from", "authwit_nonce")]
    #[external("private")]
    fn transfer_private_to_private(
        from: AztecAddress,
        to: AztecAddress,
        amount: u128,
        authwit_nonce: Field,
    ) {
        let issuer = self.storage.issuer_address.get_current_value();
        transfer_private(
            self.storage.private_balances,
            screening(self.storage),
            from,
            to,
            amount,
            issuer,
            |a, r| self.call_self._recurse_debit(a, r),
        );
        self.enqueue_self._transfer();
        // Delivered constrained to BOTH parties that need it, deliberately - see the event list in
        // doc/README.md for the reasoning. Constrained, because an unconstrained receipt lets the sender forge
        // `from`; to the issuer, because this is the only on-chain, data-available record it has of
        // who paid whom (its note copies are offchain by necessity, events are not). Measured at
        // ~20,200 gates per constrained delivery.
        let transfer_event = self.emit(Transfer { from, to, amount });
        transfer_event.deliver_to(to, MessageDelivery::onchain_constrained());
        transfer_event.deliver_to(issuer, MessageDelivery::onchain_constrained());
    }

    /*
    * Batched transfers from a single sender. See MAX_TRANSFER_ADDR_PER_CALL for the measured limit,
    * which is lower than the mint and burn cap because each recipient costs four constrained deliveries.
    *
    * Emits one Transfer event per recipient, in the same mode as the single path, so that the batched
    * and the single path leave the same trail.
    */
    #[authorize_once("from", "authwit_nonce")]
    #[external("private")]
    fn transfer_batch(
        from: AztecAddress,
        accounts: [AztecAddress; MAX_TRANSFER_ADDR_PER_CALL],
        amount: [u128; MAX_TRANSFER_ADDR_PER_CALL],
        authwit_nonce: Field,
    ) {
        // Loop-invariant: one issuer for the whole call, read once rather than per recipient.
        let issuer = self.storage.issuer_address.get_current_value();
        for i in 0..MAX_TRANSFER_ADDR_PER_CALL {
            transfer_private(
                self.storage.private_balances,
                screening(self.storage),
                from,
                accounts[i],
                amount[i],
                issuer,
                |a, r| self.call_self._recurse_debit(a, r),
            );
            let transfer_event = self.emit(Transfer { from, to: accounts[i], amount: amount[i] });
            transfer_event.deliver_to(accounts[i], MessageDelivery::onchain_constrained());
            transfer_event.deliver_to(issuer, MessageDelivery::onchain_constrained());
        }
        self.enqueue_self._transfer();
    }

    /**
     * Cancel a private authentication witness.
     * @param inner_hash The inner hash of the authwit to cancel.
     */
    #[external("private")]
    fn cancel_authwit(inner_hash: Field) {
        let on_behalf_of = self.msg_sender();
        let nullifier = compute_authwit_nullifier(on_behalf_of, inner_hash);
        self.context.push_nullifier_unsafe(nullifier);
    }

    /** ==========================================================
     * ===================== BURN ================================
     * ======================================================== */

    /**
    * @dev Burns tokens on behalf of the specified address (`account`, named as in the CMTAT Solidity
    * burn module). The chain is `tokenModule::burn_private`; the enqueued `_burn` checks BURNER_ROLE
    * and deactivation and updates the supply. An authwit from `account` is required to burn on its behalf.
    *
    * Requirements:
    * - The contract must not be deactivated. A pause does not stop a burn, as in CMTAT Solidity.
    * - The account must not be frozen and must pass the validation module's list check.
    * - The caller must have the burner role.
    */
    #[authorize_once("account", "authwit_nonce")]
    #[external("private")]
    fn burn(account: AztecAddress, amount: u128, authwit_nonce: Field) {
        let issuer = self.storage.issuer_address.get_current_value();
        burn_private(
            self.storage.private_balances,
            screening(self.storage),
            account,
            amount,
            issuer,
            |a, r| self.call_self._recurse_debit(a, r),
        );
        self.enqueue_self._burn(self.msg_sender(), amount);
        // The issuer's on-chain record of the redemption (H-10, route A); `to` is the zero address,
        // the ERC-20 / AIP-20 convention for a burn. Constrained, so the burner cannot forge it.
        self.emit(Transfer { from: account, to: AztecAddress::zero(), amount }).deliver_to(
            issuer,
            MessageDelivery::onchain_constrained(),
        );
    }

    /*
    * Batched burns from a single holder: the #[authorize_once] macro authorizes a single `account`,
    * so the batch debits one holder.
    */
    #[authorize_once("account", "authwit_nonce")]
    #[external("private")]
    fn burn_batch(account: AztecAddress, amount: [u128; MAX_ADDR_PER_CALL], authwit_nonce: Field) {
        let mut acc: u128 = 0;
        // Loop-invariant: one issuer for the whole call, read once rather than per entry.
        let issuer = self.storage.issuer_address.get_current_value();
        for i in 0..MAX_ADDR_PER_CALL {
            burn_private(
                self.storage.private_balances,
                screening(self.storage),
                account,
                amount[i],
                issuer,
                |a, r| self.call_self._recurse_debit(a, r),
            );
            acc += amount[i];
        }
        self.enqueue_self._burn(self.msg_sender(), acc);
        // One holder, one record for the total: the batch debits a single account (H-10, route A).
        self.emit(Transfer { from: account, to: AztecAddress::zero(), amount: acc }).deliver_to(
            issuer,
            MessageDelivery::onchain_constrained(),
        );
    }

    /** ==========================================================
     * ===================== INTERNAL ============================
     * ======================================================== */

    /**
     * @dev The recursive half of a debit (review A-5). A debit first tries `DEBIT_INITIAL_MAX_NOTES`
     * notes; when the holder's balance is spread over more, the chain calls this entry point, which
     * spends up to `DEBIT_RECURSIVE_MAX_NOTES` more and calls itself again if needed. Only the contract
     * may call it: the `#[only_self]` check is what keeps a caller from spending another holder's
     * notes through it. The scheme is AIP-20's `recurse_subtract_balance_internal`.
     */
    #[external("private")]
    #[only_self]
    fn _recurse_debit(account: AztecAddress, remaining: u128) -> pub u128 {
        debit_recursive(
            self.storage.private_balances,
            account,
            remaining,
            |a, r| self.call_self._recurse_debit(a, r),
        )
    }

    /// The parties' screening this variant applies before any note moves: freeze flags on every party plus the blacklist / whitelist.
    /// A plain library method (it returns a struct of state variables, which an entry point may not),
    /// built in one place so that every value-moving entry point passes the same thing.
    #[contract_library_method]
    fn screening(storage: Storage<&mut PrivateContext>) -> FreezeAndLists {
        FreezeAndLists {
            enforcement: storage.enforcement_module,
            validation: storage.validation_module,
        }
    }

    /**
     * @dev Writes a role and emits `NewRole`. Every path that grants a role goes through here, so
     * the event cannot be attached to one path and forgotten on another — which is exactly how the
     * constructor's grants came to be silent while `grant_role` was observable.
     *
     * Authorisation deliberately stays with the caller rather than moving in here: `grant_role`
     * checks that the sender administers the role, and the constructor cannot, because at
     * construction time no account holds `DEFAULT_ADMIN_ROLE` yet.
     */
    #[internal("public")]
    fn _grant_role_internal(role: Field, account: AztecAddress) {
        self.storage.access_control._grant_role(role, account);
        self.emit(NewRole { role, account });
    }

    #[external("public")]
    // PRIVACY: `caller` and `amount` are published - every public argument is. The amount is
    // inferable from the total_supply delta anyway, and `caller` always holds MINTER_ROLE, which is
    // public state. Do NOT add `to`: the recipient is the one thing a mint keeps private.
    #[only_self]
    fn _mint(caller: AztecAddress, amount: u128) {
        mint_public(
            self.storage.access_control,
            self.storage.pause_module,
            self.storage.total_supply,
            caller,
            amount,
        );
    }

    #[external("public")]
    // PRIVACY: this function MUST take no arguments. It exists only to read the pause flag, which is
    // PublicMutable and so unreadable from private execution. Anything passed here is published;
    // `from`, `to` and `amount` never cross, and that is the single most important property of a
    // transfer in this contract.
    #[only_self]
    fn _transfer() {
        require_transfer(self.storage.pause_module);
    }

    #[external("public")]
    // PRIVACY: `caller` and `amount` are published, as for `_mint`. The debited `account` is not -
    // but only because the burner and the holder are different parties. A holder granted
    // BURNER_ROLE who redeems its own tokens publishes itself. Keep BURNER_ROLE an issuer role.
    #[only_self]
    fn _burn(caller: AztecAddress, amount: u128) {
        burn_public(
            self.storage.access_control,
            self.storage.pause_module,
            self.storage.total_supply,
            caller,
            amount,
        );
    }

    /** ==========================================================
     * ===================== HYBRID: PRIVATE/PUBLIC BRIDGES ======
     * ======================================================== */
    // The four AIP-20 paths that move value between the private notes and a public balance, offered
    // as the holder's own choice and only when the token was deployed with `public_side_enabled`.
    // Same names, parameter types and selectors as AIP-20. What each publishes is stated in
    // doc/README.md, "Private/public bridges". The chains are in tokenModule (`bridge_*`,
    // `open_commitment`, `pay_commitment`); the derived AIP-20 helpers and their licence are in
    // hybridModule.nr. The enqueued public halves publish their arguments (the public party and the
    // amount) by design.

    #[external("public")]
    #[view]
    fn balance_of_public(owner: AztecAddress) -> pub u128 {
        self.storage.public_balances.balance_of(owner)
    }

    #[external("public")]
    #[view]
    fn public_get_public_side_enabled() -> pub Field {
        self.storage.public_side_enabled.read().to_field()
    }

    /**
     * @dev: Spends `from`'s notes in private and credits `to`'s PUBLIC balance. `to` and `amount` become
     * public; `from` stays private. Both parties are screened as for a private transfer.
     *
     * Requirements:
     * - The public side must be enabled.
     * - The contract must not be paused.
     * - Neither party may be frozen and must respect the list constraints of the validation module.
     */
    #[authorize_once("from", "authwit_nonce")]
    #[external("private")]
    fn transfer_private_to_public(
        from: AztecAddress,
        to: AztecAddress,
        amount: u128,
        authwit_nonce: Field,
    ) {
        require_public_side_enabled(self.storage.public_side_enabled.read());
        let issuer = self.storage.issuer_address.get_current_value();
        bridge_private_to_public(
            self.storage.private_balances,
            screening(self.storage),
            from,
            to,
            amount,
            issuer,
            |a, r| self.call_self._recurse_debit(a, r),
        );
        self.enqueue_self._credit_public(to, amount);
    }

    /**
     * @dev: Debits `from`'s PUBLIC balance and creates a note for `to`. `from` and `amount` become
     * public; `to` stays private. Both parties are screened as for a private transfer.
     *
     * Requirements: as transfer_private_to_public, plus a sufficient public balance.
     */
    #[authorize_once("from", "authwit_nonce")]
    #[external("private")]
    fn transfer_public_to_private(
        from: AztecAddress,
        to: AztecAddress,
        amount: u128,
        authwit_nonce: Field,
    ) {
        require_public_side_enabled(self.storage.public_side_enabled.read());
        let issuer = self.storage.issuer_address.get_current_value();
        bridge_public_to_private(
            self.storage.private_balances,
            screening(self.storage),
            from,
            to,
            amount,
            issuer,
        );
        self.enqueue_self._debit_public(from, amount);
    }

    /**
     * @dev: Opens a partial note for `to` that only `completer` can later fill with an amount
     * (transfer_private_to_commitment). The recipient is screened HERE, because at completion the
     * contract holds only the commitment; the issuer is told which address the commitment belongs
     * to through a constrained event, since the library delivers the partial note to `to` alone.
     *
     * Requirements:
     * - The public side must be enabled.
     * - `to` must not be frozen and must pass the enabled list.
     */
    #[external("private")]
    fn initialize_transfer_commitment(to: AztecAddress, completer: AztecAddress) -> pub Field {
        require_public_side_enabled(self.storage.public_side_enabled.read());
        let issuer = self.storage.issuer_address.get_current_value();
        self.internal._open_commitment(to, completer, issuer)
    }

    /**
     * @dev: Spends `from`'s notes and completes `commitment` with `amount`. The parties stay private;
     * the completion log carries the amount unencrypted, tagged by the commitment. The recipient was
     * screened when the commitment was opened; the sender is screened here.
     *
     * Requirements:
     * - The public side must be enabled.
     * - The contract must not be paused.
     * - `from` must not be frozen and must pass the enabled list.
     * - The caller must be the completer the commitment was opened for.
     */
    #[authorize_once("from", "authwit_nonce")]
    #[external("private")]
    fn transfer_private_to_commitment(
        from: AztecAddress,
        commitment: Field,
        amount: u128,
        authwit_nonce: Field,
    ) {
        require_public_side_enabled(self.storage.public_side_enabled.read());
        let issuer = self.storage.issuer_address.get_current_value();
        pay_commitment(
            self.context,
            self.storage.private_balances,
            screening(self.storage),
            from,
            commitment,
            self.msg_sender(),
            amount,
            issuer,
            |a, r| self.call_self._recurse_debit(a, r),
        );
        self.enqueue_self._transfer();
    }

    /**
     * @dev: transfer_private_to_public plus a partial note for `to` that the SENDER may later
     * complete - the AIP-20 "deposit now, receive the private output later" pattern.
     */
    #[authorize_once("from", "authwit_nonce")]
    #[external("private")]
    fn transfer_private_to_public_with_commitment(
        from: AztecAddress,
        to: AztecAddress,
        amount: u128,
        authwit_nonce: Field,
    ) -> pub Field {
        require_public_side_enabled(self.storage.public_side_enabled.read());
        let issuer = self.storage.issuer_address.get_current_value();
        bridge_private_to_public(
            self.storage.private_balances,
            screening(self.storage),
            from,
            to,
            amount,
            issuer,
            |a, r| self.call_self._recurse_debit(a, r),
        );
        self.enqueue_self._credit_public(to, amount);
        self.internal._open_commitment(to, self.msg_sender(), issuer)
    }

    /// Opens the commitment and hands the issuer its record of it: who it belongs to and its tag, so
    /// the issuer can later match the (unencrypted, commitment-tagged) completion log to a holder.
    #[internal("private")]
    fn _open_commitment(to: AztecAddress, completer: AztecAddress, issuer: AztecAddress) -> Field {
        let commitment = open_commitment(self.context, screening(self.storage), to, completer);
        self.emit(CommitmentInitialized { to, completer, commitment }).deliver_to(
            issuer,
            MessageDelivery::onchain_constrained(),
        );
        commitment
    }

    #[external("public")]
    #[only_self]
    // PRIVACY: `to` and `amount` are published - that is the nature of a public credit, chosen by the
    // sender. `from` never reaches this half.
    fn _credit_public(to: AztecAddress, amount: u128) {
        credit_public(
            self.storage.pause_module,
            self.storage.public_balances,
            to,
            amount,
        );
        self.emit(Transfer { from: PRIVATE_ADDRESS_MAGIC_VALUE, to, amount });
    }

    #[external("public")]
    #[only_self]
    // PRIVACY: `from` and `amount` are published - the debited balance is public state anyway. `to`
    // never reaches this half.
    fn _debit_public(from: AztecAddress, amount: u128) {
        debit_public(
            self.storage.pause_module,
            self.storage.public_balances,
            from,
            amount,
        );
        self.emit(Transfer { from, to: PRIVATE_ADDRESS_MAGIC_VALUE, amount });
    }

    /** ==========================================================
     * ===================== UNCONSTRAINED =======================
     * ======================================================== */

    #[external("utility")]
    unconstrained fn balance_of_private(owner: AztecAddress) -> pub u128 {
        self.storage.private_balances.at(owner).balance_of()
    }
}
