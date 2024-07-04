


mod types;


contract Token {
    // Libs
 
    use dep::compressed_string::FieldCompressedString;

    use dep::aztec::{
        hash::compute_secret_hash,
        prelude::{NoteGetterOptions, Map, PublicMutable, SharedImmutable,SharedMutable, PrivateSet, AztecAddress},
        encrypted_logs::encrypted_note_emission::{encode_and_encrypt_note, encode_and_encrypt_note_with_keys}
    };



    use dep::authwit::{auth::{assert_current_call_valid_authwit, assert_current_call_valid_authwit_public}};

    use crate::types::{ token_note::{TokenNote, TOKEN_NOTE_LEN}, balances_map::BalancesMap,  roles::UserFlags};

    // Changing an address' roles has a certain block delay before it goes into effect.
    global CHANGE_ROLES_DELAY_BLOCKS = 2;

    #[aztec(storage)]
    struct Storage {
        issuers: Map<AztecAddress, PublicMutable<bool>>,
        balances: BalancesMap<TokenNote>,
        total_supply: PublicMutable<U128>,
        roles: Map<AztecAddress, SharedMutable<UserFlags, CHANGE_ROLES_DELAY_BLOCKS>>,

        symbol: SharedImmutable<FieldCompressedString>,
        name: SharedImmutable<FieldCompressedString>,
        decimals: SharedImmutable<u8>,
    }

    #[aztec(public)]
    #[aztec(initializer)]
    //TODO a ABI encoding problem in core library doesn't allow us to input a tokenName, tokenSymbol and tokenDecimals for now
    fn constructor(admin: AztecAddress) {
        assert(!admin.is_zero(), "invalid admin");
        storage.name.initialize(FieldCompressedString::from_string("TOKEN00000000000000000000000000"));
        storage.symbol.initialize(FieldCompressedString::from_string("TKN0000000000000000000000000000"));
        let decimal: u8 = 18;
        storage.decimals.initialize(decimal);
        let admin_roles = UserFlags { is_admin: true, is_issuer: true, is_blacklisted: false };
        storage.roles.at(admin).schedule_value_change(admin_roles);
    }


    #[aztec(public)]
    #[aztec(view)]
    fn get_roles(user: AztecAddress) -> pub Field {
        storage.roles.at(user).get_current_value_in_public().to_field()
    }

    #[aztec(public)]
    fn update_roles(user: AztecAddress, roles: UserFlags) {
        let caller_roles = storage.roles.at(context.msg_sender()).get_current_value_in_public();
        assert(caller_roles.is_admin, "caller is not admin");

        storage.roles.at(user).schedule_value_change(roles);
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


    #[aztec(private)]
    fn mint(to: AztecAddress, amount: Field) {
        let to_roles = storage.roles.at(to).get_current_value_in_private();
        assert(!to_roles.is_blacklisted, "Blacklisted: Recipient");

        let issuer_role = storage.roles.at(context.msg_sender()).get_current_value_in_private();
        assert(issuer_role.is_issuer, "Caller is not issuer");

        storage.balances.add(to, U128::from_integer(amount)).emit(encode_and_encrypt_note(&mut context,to,to));
        Token::at(context.this_address())._mint(amount).enqueue(&mut context);
    }

    //NOTE: in the docs, it is stated that the nonce should prevent replay attacks, but here it does strictly nothing
    #[aztec(private)]
    fn transfer(from: AztecAddress, to: AztecAddress, amount: Field, nonce: Field) {
        let from_roles = storage.roles.at(from).get_current_value_in_private();
        assert(!from_roles.is_blacklisted, "Blacklisted: Sender");
        let to_roles = storage.roles.at(to).get_current_value_in_private();
        assert(!to_roles.is_blacklisted, "Blacklisted: Recipient");


        //the authwit is used to allow a thrid party to spend funds of a user upon approval
        if (!from.eq(context.msg_sender())) {
            assert_current_call_valid_authwit(&mut context, from);
        } else {
            assert(nonce == 0, "invalid nonce");
        }

        let amount = U128::from_integer(amount);
        storage.balances.sub(from, amount).emit(encode_and_encrypt_note(&mut context,from,from));
        storage.balances.add(to, amount).emit(encode_and_encrypt_note(&mut context,to,to));
    }

    #[aztec(private)]
    fn burn(from: AztecAddress, amount: Field) {
        let from_roles = storage.roles.at(from).get_current_value_in_private();
        assert(!from_roles.is_blacklisted, "Blacklisted: Sender");

        let issuer_role = storage.roles.at(context.msg_sender()).get_current_value_in_private();
        assert(issuer_role.is_issuer, "Caller is not issuer");

        storage.balances.sub(from, U128::from_integer(amount)).emit(encode_and_encrypt_note(&mut context, from, from));
        Token::at(context.this_address())._burn(amount).enqueue(&mut context);
    }

    //internal
    #[aztec(public)]
    #[aztec(internal)]
    fn _mint(amount: Field) {
        let supply = storage.total_supply.read().add(U128::from_integer(amount));
        storage.total_supply.write(supply);
    }

    #[aztec(public)]
    #[aztec(internal)]
    fn _burn(amount: Field) {
        let new_supply = storage.total_supply.read().sub(U128::from_integer(amount));
        storage.total_supply.write(new_supply);
    }


    /// Unconstrained ///

    unconstrained fn balance_of_private(owner: AztecAddress) -> pub Field {
        storage.balances.balance_of(owner).to_field()
    }

}

