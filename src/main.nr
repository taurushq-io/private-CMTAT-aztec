
mod types;
mod test;
mod modules;

use dep::aztec::macros::aztec;

#[aztec]
contract CMTAToken {
    // Libs
    use dep::compressed_string::FieldCompressedString;
    use std::ops::{Add, Sub};

    use dep::authwit::auth::{
        assert_current_call_valid_authwit,
        compute_authwit_nullifier,
    };
    use dep::aztec::{
        event::event_interface::EventInterface,
        macros::{
            events::event,
            functions::{initializer, internal, private, public, view, utility},
            storage::storage,
        },
        messages::logs::{
            event::encode_and_encrypt_event_unconstrained,
        },
        unencrypted_logs::unencrypted_event_emission::encode_event,
        prelude::{
            AztecAddress, Map, PublicMutable, PublicImmutable,
            SharedMutable,
        },
        protocol_types::traits::{ToField,Serialize},
    };

    use crate::modules::{
    access_controlModule::{AccessControlModule, BURNER_ROLE, DEFAULT_ADMIN_ROLE, MINTER_ROLE, VALIDATION_ROLE},
    pauseModule::{PauseModule},
    validationModule::{SetFlag, UserFlags, ValidationModule},
    enforcementModule::{Freezable, FreezableFlag},
    extensions::{
    creditEventsModule::{CreditEvents, CreditEventsStruct},
    debtBaseModule::{DebtBase, DebtBaseStruct},},
    };
    use crate::types::balance_set::BalanceSet;

    

    // Changing an address' roles has a certain block delay before it goes into effect.
    global CHANGE_ROLES_DELAY_BLOCKS: u32 = 2;
    //This global is used when doing batching. We set a limit of 1 address per call for now due to the 4 encrypted logs limit.
    global MAX_ADDR_PER_CALL: u32 = 1;

    #[derive(Serialize)]
    #[event]
    struct Transfer {
        from: AztecAddress,
        to: AztecAddress,
        amount: u128,
    }

    #[derive(Serialize)]
    #[event]
    struct NewRole {
        role: Field,
        account: AztecAddress,
    }

    #[storage]
    struct Storage<Context> {

        pause_module: PauseModule<Context>,
        validation_module: ValidationModule<UserFlags, Context>,
        enforcement_module: Freezable<FreezableFlag, Context>,
        access_control: AccessControlModule<bool, Context>,
        credit_event_module: CreditEvents<bool, Context>,
        debt_base_module: DebtBase<bool, Context>,

        issuer_address: SharedMutable<AztecAddress, CHANGE_ROLES_DELAY_BLOCKS, Context>,

        private_balances: Map<AztecAddress, BalanceSet<Context>, Context>,
        
        total_supply: PublicMutable<u128, Context>,
        symbol: PublicImmutable<FieldCompressedString, Context>,
        name: PublicImmutable<FieldCompressedString, Context>,
        decimals: PublicImmutable<u8, Context>,
    }

    #[public]
    #[initializer]
    fn constructor(admin: AztecAddress, name: str<31>, symbol: str<31>, decimals: u8) {
        assert(!admin.is_zero(), "invalid admin");
        storage.name.initialize(FieldCompressedString::from_string(name));
        storage.symbol.initialize(FieldCompressedString::from_string(symbol));
        storage.decimals.initialize(decimals);
        storage.access_control._grant_role(DEFAULT_ADMIN_ROLE, admin);
        storage.access_control._grant_role(VALIDATION_ROLE, admin);

        storage.issuer_address.schedule_value_change(admin);
    }

    /** ==========================================================
     * ===================== AUTHORIZATION MODULE ================
     * ======================================================== */

    #[public]
    #[view]
    fn has_role(role: Field, account: AztecAddress) -> pub Field {
        storage.access_control.has_role(role, account).to_field()
    }

    #[public]
    fn only_role(role: Field, caller: AztecAddress) {
        storage.access_control.only_role(role, caller);
    }

    #[public]
    fn grant_role(role: Field, account: AztecAddress) {
        storage.access_control.grant_role(role, account, context.msg_sender());
        NewRole { role, account }.emit(encode_event(&mut context));
    }

    /**
     * @roles: onlyAdmin
     * @notice: revoking a pause contract role when the contract is paused can cause the contract to be stuck in a paused state.
     */
    #[public]
    fn revoke_role(role: Field, account: AztecAddress) {
        storage.access_control.revoke_role(role, account, context.msg_sender());
    }

    #[public]
    fn renounce_role(role: Field, callerConfirmation: AztecAddress) {
        storage.access_control.renounce_role(role, context.msg_sender(), callerConfirmation);
    }

    /** ==========================================================
     * ===================== VALIDATION MODULE ===================
     * ======================================================== */

    #[public]
    #[view]
    fn get_operations() -> pub Field {
        storage.validation_module.get_operations()
    }

    #[public]
    fn set_operations(operations: SetFlag) {
        storage.validation_module.set_operations(
            context.msg_sender(),
            operations,
            storage.access_control,
        );
    }

    #[public]
    fn add_to_list(newListAddress: AztecAddress, userFlag: UserFlags) {
        storage.validation_module.add_to_list(
            context.msg_sender(),
            newListAddress,
            userFlag,
            storage.access_control,
        );
    }

    #[public]
    fn remove_from_list(removeListAddress: AztecAddress, userFlag: UserFlags) {
        storage.validation_module.remove_from_list(
            context.msg_sender(),
            removeListAddress,
            userFlag,
            storage.access_control,
        );
    }

    /** ==========================================================
     * ===================== PAUSE MODULE ========================
     * ======================================================== */

    #[public]
    #[view]
    fn public_get_pause() -> pub Field {
        storage.pause_module.is_paused().to_field()
    }

    /**
     * @roles: onlyAdmin
     * @notice: The contract must not be paused.
     */
    #[public]
    fn pause_contract() {
        let admin = context.msg_sender();
        storage.pause_module.pause(admin, storage.access_control);
    }

    #[public]
    fn unpause_contract() {
        let admin = context.msg_sender();
        storage.pause_module.unpause(admin, storage.access_control);
    }

    /** ==========================================================
     * ===================== ENFORCEMENT MODULE ==================
     * ======================================================== */

    #[public]
    #[view]
    fn get_frozen(user: AztecAddress) -> pub Field {
        storage.enforcement_module.is_frozen(user).to_field()
    }

    #[public]
    fn freeze(user: AztecAddress, value: FreezableFlag) {
        storage.enforcement_module.freeze(context.msg_sender(), user, value, storage.access_control);
    }

    #[public]
    fn unfreeze(user: AztecAddress, value: FreezableFlag) {
        storage.enforcement_module.unfreeze(
            context.msg_sender(),
            user,
            value,
            storage.access_control,
        );
    }

    /** ==========================================================
     * ===================== CREDIT EVENTS MODULE ================
     * ======================================================== */

    #[public]
    fn set_credit_events(credit_events: CreditEventsStruct) {
        storage.credit_event_module.setCreditEvents(
            credit_events,
            context.msg_sender(),
            storage.access_control,
        );
    }

    #[public]
    fn get_credit_events() -> [Field; 3] {
        storage.credit_event_module.get_credit_events()
    }

    /** ==========================================================
     * ===================== DEBT BASE MODULE ====================
     * ======================================================== */

    #[public]
    fn set_debt_base(debt_base_: DebtBaseStruct) {
        storage.debt_base_module.setDebt(debt_base_, context.msg_sender(), storage.access_control);
    }

    #[public]
    fn get_debt_base() -> [Field; 12] {
        storage.debt_base_module.get_debt_base()
    }

    /** ==========================================================
     * ===================== VIEW FUNCTIONS ======================
     * ======================================================== */

    #[public]
    #[view]
    fn public_get_name() -> pub FieldCompressedString {
        storage.name.read()
    }

    #[private]
    #[view]
    fn private_get_name() -> pub FieldCompressedString {
        storage.name.read()
    }

    #[public]
    #[view]
    fn public_get_symbol() -> pub FieldCompressedString {
        storage.symbol.read()
    }

    #[private]
    #[view]
    fn private_get_symbol() -> pub FieldCompressedString {
        storage.symbol.read()
    }

    #[public]
    #[view]
    fn public_get_decimals() -> pub u8 {
        storage.decimals.read()
    }

    #[private]
    #[view]
    fn private_get_decimals() -> pub u8 {
        storage.decimals.read()
    }

    #[public]
    #[view]
    fn total_supply() -> u128 {
        storage.total_supply.read()
    }
    //TODO: we should be able to change the address of the issuer and put some ACL on it
    #[public]
    #[view]
    fn public_get_issuer() -> pub AztecAddress {
        storage.issuer_address.get_current_value()
    }

    #[private]
    #[view]
    fn private_get_issuer() -> pub AztecAddress {
        storage.issuer_address.get_current_value()
    }

    /** ==========================================================
     * ===================== MINT ================================
     * ======================================================== */

    #[private]
    #[internal]
    /*
    @dev: We do not use authwits for minting, as the issuer is the only one allowed to mint.
    @info: the minting function is called by the issuer, who is the only one allowed to mint.
    */
    fn _mint_internal(to: AztecAddress, amount: u128) {
        assert(!storage.enforcement_module.is_frozen(to), "Frozen: Recipient");

        let issuer = storage.issuer_address.get_current_value();

        //TODO: here, we send two notes to the same issuer
        storage.private_balances.at(to).add(amount, to, issuer, issuer);
    }

    /**
    * @dev: Mints tokens to the specified address. Enqueues a public call to increase the total supply and to check for pause.
    *
    * @TODO: should we restrict the "to" address to not be the issuer, in order to prevent a "malicious" issuer from not
    * revealing the "real" supply of the token, ex: by minting 100% of tokens to himself, he can hide the supply held by users
    *
    * Requirements:
    * - The contract must not be paused.
    * - The recipient must not be frozen.
    * - The recipient must respect the allowlist constraints of the validation module.
    * - The caller must have the minter role.
    */
    #[private]
    fn mint(to: AztecAddress, amount: u128) {
        CMTAToken::at(context.this_address())._mint_internal(to, amount).call(&mut context);
        CMTAToken::at(context.this_address())._mint(context.msg_sender(), amount).enqueue(&mut context);
    }

    //everyone can call this function, but will revert in _mint if not minter role
    #[private]
    fn mint_batch(accounts: [AztecAddress; MAX_ADDR_PER_CALL], amount: [u128; MAX_ADDR_PER_CALL]) {
        assert(accounts.len() != 0, "Mint module empty");
        assert(accounts.len() == amount.len(), "Accounts and values arrays mismatch");
        let mut acc = 0;

        for i in 0..accounts.len() {
            //who is the caller here? contract or issuer, bc if it's the contract, it will fail
            CMTAToken::at(context.this_address())._mint_internal(accounts[i], amount[i]).call(
                &mut context,
            );
            acc += amount[i];
        }

        CMTAToken::at(context.this_address())._mint(context.msg_sender(), acc).enqueue(&mut context);
    }

    /** ==========================================================
     * ===================== TRANSFER ============================
     * ======================================================== */

    /**
    * @dev Spends notes, emits a new note (UintNote) with any remaining change, and sends a note to the recipient. Sends 
    the 'change' encrypted note to the issuer.
    *
    * - If caller (context.msg_sender()) =! from: it validates an authwit. In order to
    * not allow double spending of the authwit, the nonce is used to ensure that the authwit
    * can only be used once. Effectively, repeating the same nonce emits the same nullifer, which is not allowed at
    * protocol level.
    * - If caller == from: it's a usual transfer
    *
    * Requirements:
    * - The contract must not be paused.
    * - The sender/recipient must not be frozen.
    * - The sender/recipient must respect the allowlist constraints of the validation module. 
    * - The amount must be greater than 0.
    * - The sender must have enough balance to cover the transfer.
    * - The authwit must be valid if the caller is not the sender.
    */

    #[private]
    fn transfer(from: AztecAddress, to: AztecAddress, amount: u128, _nonce: Field) {
        if (!from.eq(context.msg_sender())) {
            assert_current_call_valid_authwit(&mut context, from);
        } 
        CMTAToken::at(context.this_address())._transfer_internal(from, to, amount).call(&mut context);
        CMTAToken::at(context.this_address())._transfer().enqueue(&mut context);
        Transfer { from, to, amount }.emit(encode_and_encrypt_event_unconstrained(
            &mut context,
            to,
            from,
        ));
    }

    /*
    * as the max number of encrypted logs is 4 per call, and a transfer has 4 encrypted logs, 
    * batching the transfers won't work for more than one call, equivalent as not batching.
    */
    #[private]
    fn transfer_batch(
        from: AztecAddress,
        accounts: [AztecAddress; MAX_ADDR_PER_CALL],
        amount: [u128; MAX_ADDR_PER_CALL],
        _nonce: Field,
    ) {
        if (!from.eq(context.msg_sender())) {
            assert_current_call_valid_authwit(&mut context, from);
        } 
        //assert(storage.rule_module.is_issuer(context.msg_sender()), "Caller is not issuer");
        assert(accounts.len() != 0, "Mint module empty");
        assert(accounts.len() == amount.len(), "Accounts and values arrays mismatch");

        for i in 0..MAX_ADDR_PER_CALL {

            CMTAToken::at(context.this_address())
                ._transfer_internal(context.msg_sender(), accounts[i], amount[i])
                .call(&mut context);
        }
        CMTAToken::at(context.this_address())._transfer().enqueue(&mut context);
    }

    #[private]
    #[internal]
    fn _transfer_internal(from: AztecAddress, to: AztecAddress, amount: u128) {
        assert(!storage.enforcement_module.is_frozen(from), "Frozen: Sender");
        assert(!storage.enforcement_module.is_frozen(to), "Frozen: Recipient");
        storage.validation_module.operateOnTransfer(from, to);

        let issuer = storage.issuer_address.get_current_value();

        storage.private_balances.at(from).sub(amount, from, issuer, from);
        storage.private_balances.at(to).add(amount, to, issuer, from);
    }

    /**
     * Cancel a private authentication witness.
     * @param inner_hash The inner hash of the authwit to cancel.
     */
    #[private]
    fn cancel_authwit(inner_hash: Field) {
        let on_behalf_of = context.msg_sender();
        let nullifier = compute_authwit_nullifier(on_behalf_of, inner_hash);
        context.push_nullifier(nullifier);
    }
    /** ==========================================================
     * ===================== BURN ================================
     * ======================================================== */


    #[private]
    #[internal]
    fn _burn_internal(from: AztecAddress, amount: u128) {
        assert(!storage.enforcement_module.is_frozen(from), "Frozen: Recipient");

        let issuer = storage.issuer_address.get_current_value();

        storage.private_balances.at(from).sub(amount, from, issuer, from);
    }


    /**
    * @dev Burns tokens on behalf of the specified address. Enqueues a public call to decrease the total supply and to check for pause.
    *
    * An authwit from the 'from' address is required to burn tokens on their behalf.
    *
    * Requirements:
    * - The contract must not be paused.
    * - The sender must not be frozen.    
    * - The caller must have the burner role.
    */

    #[private]
    fn burn(from: AztecAddress, amount: u128, nonce: Field) {
        assert(!storage.enforcement_module.is_frozen(from), "Frozen: Sender");

        if (!from.eq(context.msg_sender())) {
            assert_current_call_valid_authwit(&mut context, from);
        } 

        CMTAToken::at(context.this_address())._burn_internal(from, amount).call(&mut context);
        CMTAToken::at(context.this_address())._burn(context.msg_sender(), amount).enqueue(&mut context);
    }

    #[private]
    fn burn_batch(
        accounts: [AztecAddress; MAX_ADDR_PER_CALL],
        amount: [u128; MAX_ADDR_PER_CALL],
        nonce: Field,
    ) {
        assert(accounts.len() != 0, "Mint module empty");
        assert(accounts.len() == amount.len(), "Accounts and values arrays mismatch");

        let mut acc = 0;

        for i in 0..MAX_ADDR_PER_CALL {
            if (!accounts[i].eq(context.msg_sender())) {
                assert_current_call_valid_authwit(&mut context, accounts[i]);
            }
            //who is the caller here? contract or issuer, bc if it's the contract, it will fail
            CMTAToken::at(context.this_address())._burn_internal(accounts[i], amount[i]).call(&mut context);
            acc += amount[i];
        }

        CMTAToken::at(context.this_address())._burn(context.msg_sender(), acc).enqueue(&mut context);
    }

    /** ==========================================================
     * ===================== INTERNAL ============================
     * ======================================================== */

    #[public]
    #[internal]
    fn _mint(caller: AztecAddress, amount: u128) {
        storage.access_control.only_role(MINTER_ROLE, caller);
        assert(!storage.pause_module.is_paused(), "Error: token contract is paused");
        let supply = storage.total_supply.read().add(amount);
        storage.total_supply.write(supply);
    }

    #[public]
    #[internal]
    fn _transfer() {
        assert(!storage.pause_module.is_paused(), "Error: token contract is paused");
    }

    #[public]
    #[internal]
    fn _burn(caller: AztecAddress, amount: u128) {
        storage.access_control.only_role(BURNER_ROLE, caller);
        assert(!storage.pause_module.is_paused(), "Error: token contract is paused");
        let new_supply = storage.total_supply.read().sub(amount);
        storage.total_supply.write(new_supply);
    }


    /** ==========================================================
     * ===================== UNCONSTRAINED =======================
     * ======================================================== */

    #[utility]
    pub unconstrained fn balance_of_private(owner: AztecAddress) -> pub u128 {
        storage.private_balances.at(owner).balance_of()
    }
}
