use aztec::macros::aztec;

/// CMTATAztecAuthMultiToken - an ARC-403 authorization contract that applies CMTAT's pause,
/// deactivation and freeze rules to a stock ARC-1155 `MultiToken` from `aztec-standards`.
///
/// The MultiToken hook carries the token `id` in addition to the AIP-20 hook's arguments, and Noir
/// has no overloading, so the AIP-20 rules live in the sibling `CMTATAztecAuth` contract. The two
/// share every rule through `cmtat_aztec_lib::modules::authorizationHookModule`; the `id` is
/// accepted and ignored - CMTAT's pause, deactivation and freeze apply to every id alike.
///
/// The token is deployed with this contract's address as its `auth_contract`; it then calls
/// `authorize_private` from every private transfer and burn and `authorize_public` from every
/// public one, passing `(from, id, amount, selector)`. This contract holds no balances and moves no
/// value: it only refuses. What it can and cannot enforce, and how it differs from the CMTAT token
/// contracts in this repository, is described in `doc/auth/README.md`.
///
/// The four modules are the same `cmtat_aztec_lib` modules the CMTAT token contracts use, with the
/// same roles, events and delays, so an operator runs them the same way. The list check is
/// sender-only, because the hook never receives the recipient.
#[aztec]
pub contract CMTATAztecAuthMultiToken {
    use compressed_string::FieldCompressedString;

    use aztec::{
        macros::{
            events::event,
            functions::{external, initializer, internal, only_self, view},
            storage::storage,
        },
        protocol::{address::AztecAddress, traits::ToField},
        state_vars::PublicMutable,
    };

    use cmtat_aztec_lib::modules::{
        access_controlModule::{AccessControlModule, DEFAULT_ADMIN_ROLE, VALIDATION_ROLE},
        authorizationHookModule::{
            ARC1155_BURN_PRIVATE_SELECTOR, ARC1155_BURN_PUBLIC_SELECTOR, is_burn_selector,
            require_from_listed_private, require_from_listed_public,
            require_from_not_frozen_private, require_from_not_frozen_public,
            require_lifecycle_allows,
        },
        enforcementModule::{
            CHANGE_ROLES_DELAY_SECONDS as FREEZE_DELAY_SECONDS, Freezable, FreezableFlag,
        },
        pauseModule::PauseModule,
        validationModule::{SetFlag, UserFlags, ValidationModule},
    };

    // Kept equal to the `VERSION` of the CMTAT token contracts (`contracts/cmtat-aztec*/src/main.nr`)
    // for now: the authorization contract ships with the token release it is built and tested
    // against. Bump the four together. Padded to 31 characters for `FieldCompressedString`.
    pub global VERSION: str<31> = "0.4.0                          ";

    // The two selectors the hook treats as a burn; every other selector is a transfer.
    global BURN_SELECTORS: [Field; 2] =
        [ARC1155_BURN_PRIVATE_SELECTOR, ARC1155_BURN_PUBLIC_SELECTOR];

    #[storage]
    struct Storage<Context> {
        access_control: AccessControlModule<bool, Context>,
        pause_module: PauseModule<Context>,
        enforcement_module: Freezable<FreezableFlag, Context>,
        validation_module: ValidationModule<UserFlags, Context>,
        // The delay setting new freeze / list writes adopt; appended last so no existing slot moves.
        roles_delay: PublicMutable<u64, Context>,
    }

    // Same events as the CMTAT token contracts, so one indexer serves both.
    #[event]
    struct NewRole {
        role: Field,
        account: AztecAddress,
    }

    #[event]
    struct RoleRevoked {
        role: Field,
        account: AztecAddress,
        sender: AztecAddress,
    }

    #[event]
    struct Paused {
        account: AztecAddress,
    }

    #[event]
    struct Unpaused {
        account: AztecAddress,
    }

    #[event]
    struct Deactivated {
        account: AztecAddress,
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

    /// Same event as the token contracts (review H-6): the delay setting changed; per-address entries
    /// adopt it when next written, the list mode at `effective_at`.
    #[event]
    struct RolesDelayChanged {
        new_delay: u64,
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

    #[external("public")]
    #[initializer]
    fn constructor(admin: AztecAddress) {
        assert(!admin.is_zero(), "invalid admin");
        self.internal._grant_role_internal(DEFAULT_ADMIN_ROLE, admin);
        self.internal._grant_role_internal(VALIDATION_ROLE, admin);
        self.storage.roles_delay.write(FREEZE_DELAY_SECONDS);
    }

    /** ==========================================================
     * ===================== ARC-403 HOOK ========================
     * ======================================================== */

    /**
     * @notice: Called by the token from its private transfers and burns.
     * @dev: The freeze and list flags are DelayedPublicMutable and are checked here, in private. The pause and
     * deactivation flags are PublicMutable - immediate, as an emergency lever must be - so they are
     * checked by the enqueued public half. `is_burn` is the only thing that half publishes; a burn is
     * already public through the token's own enqueued supply update, and a transfer publishes only
     * that a transfer of a CMTAT-restricted token occurred - the same disclosure the CMTAT token
     * contracts make through their `_transfer()`.
     *
     * PRIVACY: never pass `from`, `id` or `amount` to the public half; every public argument is
     * published, and the id is private to the token's private domain.
     */
    #[external("private")]
    fn authorize_private(from: AztecAddress, id: Field, amount: u128, selector: Field) {
        let _ = (id, amount);
        require_from_not_frozen_private(self.storage.enforcement_module, from);
        require_from_listed_private(self.storage.validation_module, from);
        let is_burn = is_burn_selector(selector, BURN_SELECTORS);
        self.enqueue_self._require_lifecycle_allows(is_burn);
    }

    /**
     * @notice: Called by the token from its public transfers and burns.
     */
    #[external("public")]
    fn authorize_public(from: AztecAddress, id: Field, amount: u128, selector: Field) {
        let _ = (id, amount);
        require_from_not_frozen_public(self.storage.enforcement_module, from);
        require_from_listed_public(self.storage.validation_module, from);
        let is_burn = is_burn_selector(selector, BURN_SELECTORS);
        require_lifecycle_allows(self.storage.pause_module, is_burn);
    }

    #[external("public")]
    #[only_self]
    fn _require_lifecycle_allows(is_burn: bool) {
        require_lifecycle_allows(self.storage.pause_module, is_burn);
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
     * @notice: revoking a pause role while the contract is paused can leave it paused for good.
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

    // Sender-only: the hook never receives the recipient, so a listed address cannot send or burn
    // but can still receive. Same entry points, roles, delay and events as the token contracts.

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

    /** ==========================================================
     * ===================== PAUSE MODULE ========================
     * ======================================================== */

    #[external("public")]
    #[view]
    fn public_get_pause() -> pub Field {
        self.storage.pause_module.is_paused().to_field()
    }

    /**
     * @roles: onlyPauser
     * @notice: Stops every transfer of every token wired to this contract. Burns continue.
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
     * @notice: Permanently stops transfers and burns of every token wired to this contract.
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

    /**
     * @roles: onlyEnforcer
     * @notice: Takes effect after FREEZE_DELAY_SECONDS; until then the address can still send.
     */
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
     * ===================== VERSION =============================
     * ======================================================== */

    /// Changes the delay setting of the freeze and list flags (review H-6): the list mode adopts it at
    /// once for an increase and after the difference for a decrease; per-address entries adopt it when
    /// next written. Bounded by the protocol's 24 h transaction lifetime. DEFAULT_ADMIN_ROLE.
    #[external("public")]
    fn set_roles_delay(new_delay: u64) {
        assert(new_delay > 0, "invalid delay");
        assert(new_delay <= 86400, "delay above the transaction lifetime");
        let operator = self.msg_sender();
        self.storage.access_control.only_role(DEFAULT_ADMIN_ROLE, operator);
        self.storage.roles_delay.write(new_delay);
        self.storage.validation_module.operationsFlag.schedule_delay_change(new_delay);
        let (_, effective_at) = self.storage.validation_module.operationsFlag.get_scheduled_delay();
        self.emit(RolesDelayChanged { new_delay, operator, effective_at });
    }

    #[external("public")]
    #[view]
    fn roles_delay() -> pub u64 {
        self.storage.roles_delay.read()
    }

    #[external("public")]
    #[view]
    fn version() -> pub FieldCompressedString {
        FieldCompressedString::from_string(VERSION)
    }

    /** ==========================================================
     * ===================== INTERNAL ============================
     * ======================================================== */

    #[internal("public")]
    fn _grant_role_internal(role: Field, account: AztecAddress) {
        self.storage.access_control._grant_role(role, account);
        self.emit(NewRole { role, account });
    }

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
}
