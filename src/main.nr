mod types;


contract Token {
    // Libs
 
    use dep::compressed_string::FieldCompressedString;

    use dep::aztec::{
        hash::compute_secret_hash,
        prelude::{NoteGetterOptions, Map, PublicMutable, SharedImmutable, PrivateSet, AztecAddress}
    };

    use dep::authwit::{auth::{assert_current_call_valid_authwit, assert_current_call_valid_authwit_public}};

    use crate::types::{ token_note::{TokenNote, TOKEN_NOTE_LEN}, balances_map::BalancesMap};

    #[aztec(storage)]
    struct Storage {
        admin: PublicMutable<AztecAddress>,
        issuers: Map<AztecAddress, PublicMutable<bool>>,
        balances: BalancesMap<TokenNote>,
        total_supply: PublicMutable<U128>,

        symbol: SharedImmutable<FieldCompressedString>,
        name: SharedImmutable<FieldCompressedString>,
        decimals: SharedImmutable<u8>,
    }

    #[aztec(public)]
    #[aztec(initializer)]
    //TODO a ABI encoding problem in core library doesn't allow us to input a tokenName, tokenSymbol and tokenDecimals for now
    fn constructor(admin: AztecAddress) {
        assert(!admin.is_zero(), "invalid admin");
        storage.admin.write(admin);
        storage.issuers.at(admin).write(true);
        storage.name.initialize(FieldCompressedString::from_string("TOKEN00000000000000000000000000"));
        storage.symbol.initialize(FieldCompressedString::from_string("TKN0000000000000000000000000000"));
        let decimal: u8 = 18;
        storage.decimals.initialize(decimal);
    }

    #[aztec(public)]
    fn set_admin(new_admin: AztecAddress) {
        assert(storage.admin.read().eq(context.msg_sender()), "caller is not admin");
        storage.admin.write(new_admin);
    }

    unconstrained fn un_get_name() -> pub [u8; 31] {
        storage.name.read_public().to_bytes()
    }

    #[aztec(public)]
    fn public_get_name() -> pub FieldCompressedString {
        storage.name.read_public()
    }

    #[aztec(private)]
    fn private_get_name() -> pub FieldCompressedString {
        storage.name.read_private()
    }

    unconstrained fn un_get_symbol() -> pub [u8; 31] {
        storage.symbol.read_public().to_bytes()
    }

    #[aztec(public)]
    fn public_get_symbol() -> pub FieldCompressedString {
        storage.symbol.read_public()
    }

    #[aztec(private)]
    fn private_get_symbol() -> pub FieldCompressedString {
        storage.symbol.read_private()
    }

    unconstrained fn un_get_decimals() -> pub u8 {
        storage.decimals.read_public()
    }

    #[aztec(public)]
    fn public_get_decimals() -> pub u8 {
        storage.decimals.read_public()
    }

    #[aztec(private)]
    fn private_get_decimals() -> pub u8 {
        storage.decimals.read_private()
    }

    #[aztec(public)]
    fn set_issuer(issuer: AztecAddress, approve: bool) {
        assert(storage.admin.read().eq(context.msg_sender()), "caller is not admin");
        storage.issuers.at(issuer).write(approve);
    }


    #[aztec(private)]
    fn mint(to: AztecAddress, amount: Field) {
        storage.balances.add(to, U128::from_integer(amount));
        Token::at(context.this_address()).assert_issuer_and_mint(context.msg_sender(), amount).enqueue(&mut context);
    }

    //NOTE: in the docs, it is stated that the nonce should prevent replay attacks, but here it does strictly nothing
    #[aztec(private)]
    fn transfer(from: AztecAddress, to: AztecAddress, amount: Field, nonce: Field) {
        //the authwit is used to allow a thrid party to spend funds of a user upon approval
        if (!from.eq(context.msg_sender())) {
            assert_current_call_valid_authwit(&mut context, from);
        } else {
            assert(nonce == 0, "invalid nonce");
        }

        let amount = U128::from_integer(amount);
        storage.balances.sub(from, amount);
        storage.balances.add(to, amount);
    }

    #[aztec(private)]
    fn burn(from: AztecAddress, amount: Field) {
        storage.balances.sub(from, U128::from_integer(amount));
        Token::at(context.this_address()).assert_issuer_and_burn(context.msg_sender(),amount).enqueue(&mut context);
    }

    //internal
    #[aztec(public)]
    #[aztec(internal)]
    fn assert_issuer_and_mint(issuer: AztecAddress, amount: Field) {
        assert(storage.issuers.at(issuer).read(), "caller is not issuer");
        let supply = storage.total_supply.read().add(U128::from_integer(amount));
        storage.total_supply.write(supply);
    }

    #[aztec(public)]
    #[aztec(internal)]
    fn assert_issuer_and_burn(issuer: AztecAddress, amount: Field) {
        assert(storage.issuers.at(issuer).read(), "caller is not issuer");
        let new_supply = storage.total_supply.read().sub(U128::from_integer(amount));
        storage.total_supply.write(new_supply);
    }


    /// Unconstrained ///

    unconstrained fn admin() -> pub Field {
        storage.admin.read().to_field()
    }

    unconstrained fn is_minter(issuer: AztecAddress) -> pub bool {
        storage.issuers.at(issuer).read()
    }

    unconstrained fn total_supply() -> pub Field {
        storage.total_supply.read().to_integer()
    }

    unconstrained fn balance_of_private(owner: AztecAddress) -> pub Field {
        storage.balances.balance_of(owner).to_integer()
    }
}
