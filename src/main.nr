mod types;
mod test;

contract Token {
    // Libs
 
    use dep::compressed_string::FieldCompressedString;

    use dep::aztec::{
        prelude::{NoteGetterOptions, Map, PublicMutable, SharedImmutable,SharedMutable, PrivateSet, AztecAddress},
        encrypted_logs::{encrypted_note_emission::{encode_and_encrypt_note},encrypted_event_emission::{encode_and_encrypt_event_unconstrained}},
        unencrypted_logs::{unencrypted_event_emission::{emit, encode_event}},
    };

    use dep::authwit::{auth::{assert_current_call_valid_authwit, assert_current_call_valid_authwit_public, compute_authwit_nullifier}};

    use crate::types::{ token_note::{TokenNote, TOKEN_NOTE_LEN}, balances_map::BalancesMap,  validationModule::{SetFlag, UserFlags, ValidationModule}, pauseModule::{Pausable, BoolEmul}, access_control::{AccessControl, Role, RoleData, DEFAULT_ADMIN_ROLE, MINTER_ROLE, BURNER_ROLE},  enforcementModule::{Freezable, FreezableFlag}};

    use crate::types::extensions::{creditEventsModule::{CreditEventsStruct, CreditEvents}, debtBaseModule::{DebtBase, DebtBaseStruct}};
    

    // Changing an address' roles has a certain block delay before it goes into effect.
    global CHANGE_ROLES_DELAY_BLOCKS = 2;
    //This global is used when doing batching. We set a 
    global MAX_ADDR_PER_CALL = 4;

    #[aztec(event)]
    struct Paused {
        account: AztecAddress
    }

    #[aztec(event)]
    struct Unpaused {
        account: AztecAddress
    }

    #[aztec(event)]
    struct Transfer {
        from: AztecAddress,
        to: AztecAddress,
        amount: Field,
    }



    #[aztec(storage)]
    struct Storage {

        pause_module: Pausable<BoolEmul>,
        validation_module: ValidationModule<UserFlags>,
        enforcement_module: Freezable<FreezableFlag>,
        access_control: AccessControl<bool>,
        credit_event_module: CreditEvents<bool>,
        debt_base_module: DebtBase<bool>,

        balances: BalancesMap<TokenNote>,
        total_supply: PublicMutable<U128>,

        symbol: SharedImmutable<FieldCompressedString>,
        name: SharedImmutable<FieldCompressedString>,
        decimals: SharedImmutable<u8>,        

    }

    #[aztec(public)]
    #[aztec(initializer)]
    //TODO a ABI encoding problem in core library doesn't allow us to input a tokenName, tokenSymbol and tokenDecimals for now
    fn constructor(admin: AztecAddress, name: str<31>, symbol: str<31>, decimals: u8) {
        assert(!admin.is_zero(), "invalid admin");
        storage.name.initialize(FieldCompressedString::from_string(name));
        storage.symbol.initialize(FieldCompressedString::from_string(symbol));
        storage.decimals.initialize(decimals);
        storage.access_control._grant_role(DEFAULT_ADMIN_ROLE, admin);
    }



//############ AUTHORIZATION MODULE ############

    #[aztec(public)]
    // #[aztec(view)]
    fn has_role( role: Field, account: AztecAddress) -> pub Field {
        storage.access_control.has_role(role,account).to_field()
    }

    #[aztec(public)]
    fn only_role(role: Field, caller: AztecAddress) {
        storage.access_control.only_role(role,caller);
    }

    #[aztec(public)]
    fn grant_role( role: Field, account: AztecAddress) {
         storage.access_control.grant_role(role,account);
    }

    #[aztec(public)]
    fn revoke_role(role: Field, account: AztecAddress) {
        storage.access_control.revoke_role(role,account)
    }

    #[aztec(public)]
    fn renounce_role(role: Field, callerConfirmation: AztecAddress) {
        storage.access_control.renounce_role(role,context.msg_sender(), callerConfirmation);
    }


//############ VALIDATION MODULE ############

    #[aztec(public)]
    #[aztec(view)]
    fn get_operations() -> pub Field {
        storage.validation_module.get_operations()
    }

    #[aztec(public)]
    fn set_operations(operations: SetFlag) {
        storage.validation_module.set_operations(context.msg_sender(), operations, storage.access_control);
    }

    #[aztec(public)]
    fn add_to_list(newListAddress: AztecAddress, userFlag: UserFlags) {
        storage.validation_module.add_to_list(context.msg_sender(), newListAddress, userFlag, storage.access_control);
    }

    #[aztec(public)]
    fn remove_from_list( removeListAddress: AztecAddress, userFlag: UserFlags) {
        storage.validation_module.remove_from_list(context.msg_sender(), removeListAddress, userFlag, storage.access_control);
    }



//############ PAUSE MODULE ############



    #[aztec(public)]
    #[aztec(view)]
    fn public_get_pause() -> pub Field {
        storage.pause_module.is_paused().to_field()
    }

    /**
     * Pause the contract transfers
     * @roles: onlyAdmin
     * 
     */
    #[aztec(public)]
    fn pause_contract() {
        let admin = context.msg_sender();
        storage.pause_module.pause(admin, storage.access_control);
    }

     #[aztec(public)]
    fn unpause_contract() {
        let admin = context.msg_sender();
        storage.pause_module.unpause(admin, storage.access_control);

    }


//############ ENFORCEMENT MODULE ############



    #[aztec(public)]
    #[aztec(view)]
    fn get_frozen(user: AztecAddress) -> pub Field{
        storage.enforcement_module.is_frozen(user).to_field()
    }

    #[aztec(public)]
    fn freeze(user: AztecAddress, value: FreezableFlag) {
        storage.enforcement_module.freeze(context.msg_sender(), user, value, storage.access_control);
    }

    #[aztec(public)]
    fn unfreeze(user: AztecAddress, value: FreezableFlag) {
        storage.enforcement_module.unfreeze(context.msg_sender(), user, value, storage.access_control);
    }



//############ CREDIT EVENTS MODULE ############


    //Note: as events are only allowed in the main contract, we have decided not to put them yet for this function. 
    #[aztec(public)]
    fn set_credit_events(flagDefault_: bool, flagRedeemed_: bool, rating_: str<31>) {
        storage.credit_event_module.setCreditEvents(flagDefault_, flagRedeemed_, rating_);
    }


//############ DEBT BASE MODULE ############



    #[aztec(public)]
    fn set_debt_base(debt_base_: DebtBaseStruct) {
        storage.debt_base_module.setDebt(debt_base_);
    }



//############ GETTERS ############



    #[aztec(public)]
    #[aztec(view)]
    fn public_get_name() -> pub FieldCompressedString {
        storage.name.read_public()
    }

    #[aztec(private)]
    #[aztec(view)]
    fn private_get_name() -> pub FieldCompressedString {
        storage.name.read_private()
    }

    #[aztec(public)]
    #[aztec(view)]
    fn public_get_symbol() -> pub FieldCompressedString {
        storage.symbol.read_public()
    }

    #[aztec(private)]
    #[aztec(view)]
    fn private_get_symbol() -> pub FieldCompressedString {
        storage.symbol.read_private()
    }

    #[aztec(public)]
    #[aztec(view)]
    fn public_get_decimals() -> pub u8 {
        storage.decimals.read_public()
    }

    #[aztec(private)]
    #[aztec(view)]
    fn private_get_decimals() -> pub u8 {
        storage.decimals.read_private()
    }

    #[aztec(public)]
    #[aztec(view)]
    fn total_supply() -> Field {
        storage.total_supply.read().to_integer()
    }



//############ MINT ############



    /*
    * @info : wether the contract is paused or not is checked in the _mint function
    * @TODO: should we restrict the "to" address to not be the issuer, in order to prevent a "malicious" issuer from not
    * revealing the "real" supply of the token, ex: by minting 100% of tokens to himself, he can hide the supply held by users
    */
    #[aztec(private)]
    fn mint(to: AztecAddress, amount: Field) {
        assert(!storage.enforcement_module.is_frozen(to), "Frozen: Recipient");

        let note = storage.balances.add(to, U128::from_integer(amount)).emit(encode_and_encrypt_note(&mut context,to,to));
        Token::at(context.this_address())._mint(amount).enqueue(&mut context);

    }

    //everyone can call this function, but will revert in _mint if not minter role
    #[aztec(private)]
    fn mint_batch(accounts: [AztecAddress; MAX_ADDR_PER_CALL], amount: [Field; MAX_ADDR_PER_CALL]) {
        assert(accounts.len() != 0,"Mint module empty" );
        assert(accounts.len() == amount.len(), "Accounts and values arrays mismatch");

        for i in 0..accounts.len() {
            //who is the caller here? contract or issuer, bc if it's the contract, it will fail
            Token::at(context.this_address()).mint(accounts[i], amount[i]).call(&mut context);
        }
    }



//############ TRANSFER ############



    /*
    * @info : wether the contract is paused or not is checked in the _mint function
    * NOTE: the nonce here is used to prevent replay attacks. By constraining it to be equal to 0 afterwards,
    * we assure that the signature of this function call can only be done once 
    */
    #[aztec(private)]
    fn transfer( to: AztecAddress, amount: Field) {
        let from = context.msg_sender();
        std::println(from);

        assert(!storage.enforcement_module.is_frozen(from), "Frozen: Sender");
        assert(!storage.enforcement_module.is_frozen(to), "Frozen: Recipient");

        storage.validation_module.operateOnTransfer(context.msg_sender(),to);


        let amount = U128::from_integer(amount);
        storage.balances.sub(from, amount).emit(encode_and_encrypt_note(&mut context,from,from));
        storage.balances.add(to, amount).emit(encode_and_encrypt_note(&mut context,from,to));

        Token::at(context.this_address())._transfer().enqueue(&mut context);

        Transfer { from, to, amount: amount.to_field() }.emit(encode_and_encrypt_event_unconstrained(&mut context, from, to));

    }

    #[aztec(private)]
    //does nonce need to change?
    fn transfer_batch(accounts: [AztecAddress; MAX_ADDR_PER_CALL], amount: [Field; MAX_ADDR_PER_CALL], nonce: Field) {
        // assert(storage.rule_module.is_issuer(context.msg_sender()), "Caller is not issuer");
        assert(accounts.len() != 0,"Mint module empty" );
        assert(accounts.len() == amount.len(), "Accounts and values arrays mismatch");

        for i in 0..MAX_ADDR_PER_CALL {
            //who is the caller here? contract or issuer, bc if it's the contract, it will fail
            Token::at(context.this_address()).transfer_from(context.msg_sender(), accounts[i], amount[i], nonce).call(&mut context);
        }
    }


    //Same pattern as ERC20. 
    #[aztec(private)]
    fn transfer_from(from: AztecAddress, to: AztecAddress, amount: Field, nonce: Field) {
        //the authwit is used to allow a thrid party to spend funds of a user upon approval. 
        //should we check if the 3rd party initiating this transaction is able to do the transfer? 
        assert(!storage.enforcement_module.is_frozen(from), "Frozen: Sender");
        assert(!storage.enforcement_module.is_frozen(to), "Frozen: Recipient");

        storage.validation_module.operateOnTransfer(from,to);

        if (!from.eq(context.msg_sender())) {
            assert_current_call_valid_authwit(&mut context, from);
        } else {
            assert(nonce == 0, "invalid nonce");
        }

        let amount = U128::from_integer(amount);

        storage.balances.sub(from, amount).emit(encode_and_encrypt_note(&mut context, from, from));
        storage.balances.add(to, amount).emit(encode_and_encrypt_note(&mut context, from, to));


        Token::at(context.this_address())._transferFrom().enqueue(&mut context);

        Transfer { from, to, amount: amount.to_field() }.emit(encode_and_encrypt_event_unconstrained(&mut context, from, to));
    }

    /**
     * Cancel a private authentication witness.
     * @param inner_hash The inner hash of the authwit to cancel.
     */
    #[aztec(private)]
    fn cancel_authwit(inner_hash: Field) {
        let on_behalf_of = context.msg_sender();
        let nullifier = compute_authwit_nullifier(on_behalf_of, inner_hash);
        context.push_nullifier(nullifier, 0);
    }



//############ BURN ############



    #[aztec(private)]
    fn burn(from: AztecAddress, amount: Field, nonce: Field) {
        assert(!storage.enforcement_module.is_frozen(from), "Frozen: Sender");

        // assert(!storage.rule_module.is_blacklisted(from), "Blacklisted: Sender");
        // assert(storage.rule_module.is_issuer(context.msg_sender()), "Caller is not issuer");

        if (!from.eq(context.msg_sender())) {
            assert_current_call_valid_authwit(&mut context, from);
        } else {
            assert(nonce == 0, "invalid nonce");
        }

        storage.balances.sub(from, U128::from_integer(amount)).emit(encode_and_encrypt_note(&mut context, from, from));
        Token::at(context.this_address())._burn(amount).enqueue(&mut context);
    }
    
    //can nonce be the same for all accounts?
    #[aztec(private)]
    fn burn_batch(accounts: [AztecAddress; MAX_ADDR_PER_CALL], amount: [Field; MAX_ADDR_PER_CALL], nonce: Field) {
        // assert(storage.rule_module.is_issuer(context.msg_sender()), "Caller is not issuer");
        assert(accounts.len() != 0,"Mint module empty" );
        assert(accounts.len() == amount.len(), "Accounts and values arrays mismatch");

        for i in 0..MAX_ADDR_PER_CALL {
            //who is the caller here? contract or issuer, bc if it's the contract, it will fail
            Token::at(context.this_address()).burn(accounts[i], amount[i], nonce);
        }
    }


//############ INTERNAL ############



    #[aztec(public)]
    #[aztec(internal)]
    fn _mint(amount: Field) {
        storage.access_control.only_role(MINTER_ROLE, context.msg_sender());
        assert(!storage.pause_module.is_paused(), "Error: token contract is paused");
        let supply = storage.total_supply.read().add(U128::from_integer(amount));
        storage.total_supply.write(supply);
    }

    #[aztec(public)]
    #[aztec(internal)]
    fn _burn(amount: Field) {
        storage.access_control.only_role(BURNER_ROLE, context.msg_sender());
        assert(!storage.pause_module.is_paused(), "Error: token contract is paused");
        let new_supply = storage.total_supply.read().sub(U128::from_integer(amount));
        storage.total_supply.write(new_supply);
    }

    #[aztec(public)]
    #[aztec(internal)]
    fn _transfer() {
        assert(!storage.pause_module.is_paused(), "Error: token contract is paused");
    }

    #[aztec(public)]
    #[aztec(internal)]
    fn _transferFrom() {
        assert(!storage.pause_module.is_paused(), "Error: token contract is paused");
    }



//############ UNCONSTRAINED ############



    unconstrained fn balance_of_private(owner: AztecAddress) -> pub Field {
        storage.balances.balance_of(owner).to_field()
    }

}


