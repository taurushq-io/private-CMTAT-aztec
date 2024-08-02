mod types;
mod test;

contract Token {
    // Libs
 
    use dep::compressed_string::FieldCompressedString;

    use dep::aztec::{
        hash::compute_secret_hash,
        prelude::{NoteGetterOptions, Map, PublicMutable, SharedImmutable,SharedMutable, PrivateSet, AztecAddress},
        encrypted_logs::{encrypted_note_emission::{encode_and_encrypt_note},
        encrypted_event_emission::{encode_and_encrypt_event_unconstrained}}
    };

    use dep::authwit::{auth::{assert_current_call_valid_authwit, assert_current_call_valid_authwit_public, compute_authwit_nullifier}};

    use crate::types::{ token_note::{TokenNote, TOKEN_NOTE_LEN}, balances_map::BalancesMap,  authorizations::UserFlags, pausable::Pausable};

    // Changing an address' roles has a certain block delay before it goes into effect.
    global CHANGE_ROLES_DELAY_BLOCKS = 2;

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
        balances: BalancesMap<TokenNote>,
        total_supply: PublicMutable<U128>,

        symbol: SharedImmutable<FieldCompressedString>,
        name: SharedImmutable<FieldCompressedString>,
        decimals: SharedImmutable<u8>,

        authorizationModule: Map<AztecAddress, SharedMutable<UserFlags,CHANGE_ROLES_DELAY_BLOCKS >>,
        pauseModule: PublicMutable<Pausable>,
        //freezeModule: Freezable,
    }

    #[aztec(public)]
    #[aztec(initializer)]
    //TODO a ABI encoding problem in core library doesn't allow us to input a tokenName, tokenSymbol and tokenDecimals for now
    fn constructor(admin: AztecAddress, name: str<31>, symbol: str<31>, decimals: u8) {
        assert(!admin.is_zero(), "invalid admin");
        storage.name.initialize(FieldCompressedString::from_string(name));
        storage.symbol.initialize(FieldCompressedString::from_string(symbol));
        storage.decimals.initialize(decimals);
        let admin_roles = UserFlags { is_admin: true, is_issuer: true, is_blacklisted: false };
        storage.authorizationModule.at(admin).schedule_value_change(admin_roles);
    }


    #[aztec(public)]
    #[aztec(view)]
    fn get_roles(user: AztecAddress) -> pub Field {
        storage.authorizationModule.at(user).get_current_value_in_public().to_field()
    }

    #[aztec(public)]
    fn grant_roles(user: AztecAddress, authorizationModule: UserFlags) {
        let caller_roles = storage.authorizationModule.at(context.msg_sender()).get_current_value_in_public();
        assert(caller_roles.is_admin, "caller is not admin");
        storage.authorizationModule.at(user).schedule_value_change(authorizationModule);
    }

    #[aztec(public)]
    #[aztec(view)]
    fn public_get_pause() -> pub Field {
        storage.pauseModule.read().is_paused.to_field()
    }

    /**
     * Pause the contract transfers
     * @roles: onlyAdmin
     * 
     */
    #[aztec(public)]
    fn pause_contract() {
        let admin = context.msg_sender();
        let caller_roles = storage.authorizationModule.at(admin).get_current_value_in_public();
        assert(caller_roles.is_admin, "caller is not admin");

        let mut pause_val = storage.pauseModule.read();
        pause_val.pause();
        storage.pauseModule.write(pause_val);
    }

     #[aztec(public)]
    fn unpause_contract() {
        let admin = context.msg_sender();
        let caller_roles = storage.authorizationModule.at(admin).get_current_value_in_public();
        assert(caller_roles.is_admin, "caller is not admin");

        let mut pause_val = storage.pauseModule.read();
        pause_val.unpause();
        storage.pauseModule.write(pause_val);
    }

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


    /*
    * @info : wether the contract is paused or not is checked in the _mint function
    * @TODO: should we restrict the "to" address to not be the issuer, in order to prevent a "malicious" issuer from not
    * revealing the "real" supply of the token, ex: by minting 100% of tokens to himself, he can hide the supply held by users
    */
    #[aztec(private)]
    fn mint(to: AztecAddress, amount: Field) {
        let to_roles = storage.authorizationModule.at(to).get_current_value_in_private();
        assert(!to_roles.is_blacklisted, "Blacklisted: Recipient");

        let issuer_role = storage.authorizationModule.at(context.msg_sender()).get_current_value_in_private();
        assert(issuer_role.is_issuer, "Caller is not issuer");

        let note = storage.balances.add(to, U128::from_integer(amount)).emit(encode_and_encrypt_note(&mut context,to,to));
        Token::at(context.this_address())._mint(amount).enqueue(&mut context);
    }

    /*
    * @info : wether the contract is paused or not is checked in the _mint function
    * NOTE: the nonce here is used to prevent replay attacks. By constraining it to be equal to 0 afterwards,
    * we assure that the signature of this function call can only be done once 
    */
    #[aztec(private)]
    fn transfer( to: AztecAddress, amount: Field) {
        let from = context.msg_sender();

        let from_roles = storage.authorizationModule.at(from).get_current_value_in_private();
        assert(!from_roles.is_blacklisted, "Blacklisted: Sender");
        let to_roles = storage.authorizationModule.at(to).get_current_value_in_private();
        assert(!to_roles.is_blacklisted, "Blacklisted: Recipient");

        let amount = U128::from_integer(amount);
        storage.balances.sub(from, amount).emit(encode_and_encrypt_note(&mut context,from,from));
        storage.balances.add(to, amount).emit(encode_and_encrypt_note(&mut context,from,to));

        Token::at(context.this_address())._transfer().enqueue(&mut context);

        Transfer { from, to, amount: amount.to_field() }.emit(encode_and_encrypt_event_unconstrained(&mut context, from, to));

    }

    //Same pattern as ERC20. 
    #[aztec(private)]
    fn transfer_from(from: AztecAddress, to: AztecAddress, amount: Field, nonce: Field) {
        //the authwit is used to allow a thrid party to spend funds of a user upon approval. 
        //should we check if the 3rd party initiating this transaction is able to do the transfer? 

        let from_roles = storage.authorizationModule.at(from).get_current_value_in_private();
        assert(!from_roles.is_blacklisted, "Blacklisted: Sender");
        let to_roles = storage.authorizationModule.at(to).get_current_value_in_private();
        assert(!to_roles.is_blacklisted, "Blacklisted: Recipient");

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

    #[aztec(private)]
    fn burn(from: AztecAddress, amount: Field) {

        let from_roles = storage.authorizationModule.at(from).get_current_value_in_private();
        assert(!from_roles.is_blacklisted, "Blacklisted: Sender");

        let issuer_role = storage.authorizationModule.at(context.msg_sender()).get_current_value_in_private();
        assert(issuer_role.is_issuer, "Caller is not issuer");

        storage.balances.sub(from, U128::from_integer(amount)).emit(encode_and_encrypt_note(&mut context, from, from));
        Token::at(context.this_address())._burn(amount).enqueue(&mut context);
    }


    //internal
    #[aztec(public)]
    #[aztec(internal)]
    fn _mint(amount: Field) {
        assert(!storage.pauseModule.read().is_paused, "Error: token contract is paused");
        let supply = storage.total_supply.read().add(U128::from_integer(amount));
        storage.total_supply.write(supply);
    }

    #[aztec(public)]
    #[aztec(internal)]
    fn _burn(amount: Field) {
        assert(!storage.pauseModule.read().is_paused, "Error: token contract is paused");

        let new_supply = storage.total_supply.read().sub(U128::from_integer(amount));
        storage.total_supply.write(new_supply);
    }

    #[aztec(public)]
    #[aztec(internal)]
    fn _transfer() {
        assert(!storage.pauseModule.read().is_paused, "Error: token contract is paused");
    }

    #[aztec(public)]
    #[aztec(internal)]
    fn _transferFrom() {
        assert(!storage.pauseModule.read().is_paused, "Error: token contract is paused");
    }




    /// Unconstrained ///

    unconstrained fn balance_of_private(owner: AztecAddress) -> pub Field {
        storage.balances.balance_of(owner).to_field()
    }

}


