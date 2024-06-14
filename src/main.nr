// docs:start:token_all
// docs:start:imports
mod types;

// Minimal token implementation that supports `AuthWit` accounts.
// The auth message follows a similar pattern to the cross-chain message and includes a designated caller.
// The designated caller is ALWAYS used here, and not based on a flag as cross-chain.
// message hash = H([caller, contract, selector, ...args])
// To be read as `caller` calls function at `contract` defined by `selector` with `args`
// Including a nonce in the message hash ensures that the message can only be used once.

contract Token {
    // Libs

    use dep::compressed_string::FieldCompressedString;

    use dep::aztec::{
        hash::compute_secret_hash,
        prelude::{NoteGetterOptions, Map, PublicMutable, SharedImmutable, PrivateSet, AztecAddress}
    };

    // docs:start:import_authwit
    use dep::authwit::{auth::{assert_current_call_valid_authwit, assert_current_call_valid_authwit_public}};
    // docs:end:import_authwit

    use crate::types::{transparent_note::TransparentNote, token_note::{TokenNote, TOKEN_NOTE_LEN}, balances_map::BalancesMap};
    // docs:end::imports

    // docs:start:storage_struct
    #[aztec(storage)]
    struct Storage {
        admin: PublicMutable<AztecAddress>,
        minters: Map<AztecAddress, PublicMutable<bool>>,
        balances: BalancesMap<TokenNote>,
        total_supply: PublicMutable<U128>,
        pending_shields: PrivateSet<TransparentNote>,

        symbol: SharedImmutable<FieldCompressedString>,
        name: SharedImmutable<FieldCompressedString>,
        decimals: SharedImmutable<u8>,
    }
    // docs:end:storage_struct

    // docs:start:constructor
    #[aztec(public)]
    #[aztec(initializer)]
    //TODO a ABI encoding problem in core library doesn't allow us to input a tokenName, tokenSymbol and tokenDecimals for now
    fn constructor(admin: AztecAddress) {
        assert(!admin.is_zero(), "invalid admin");
        storage.admin.write(admin);
        storage.minters.at(admin).write(true);
        storage.name.initialize(FieldCompressedString::from_string("TOKEN00000000000000000000000000"));
        storage.symbol.initialize(FieldCompressedString::from_string("TKN0000000000000000000000000000"));
        // docs:start:initialize_decimals
        let decimal: u8 = 18;
        storage.decimals.initialize(decimal);
        // docs:end:initialize_decimals
    }
    // docs:end:constructor

    // docs:start:set_admin
    #[aztec(public)]
    fn set_admin(new_admin: AztecAddress) {
        assert(storage.admin.read().eq(context.msg_sender()), "caller is not admin");
        // docs:start:write_admin
        storage.admin.write(new_admin);
        // docs:end:write_admin
    }
    // docs:end:set_admin

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
        // docs:start:read_decimals_public
        storage.decimals.read_public()
        // docs:end:read_decimals_public
    }

    #[aztec(private)]
    fn private_get_decimals() -> pub u8 {
        // docs:start:read_decimals_private
        storage.decimals.read_private()
        // docs:end:read_decimals_private
    }

    // docs:start:set_minter
    #[aztec(public)]
    fn set_minter(minter: AztecAddress, approve: bool) {
        // docs:start:read_admin
        assert(storage.admin.read().eq(context.msg_sender()), "caller is not admin");
        // docs:end:read_admin
        // docs:start:write_minter
        storage.minters.at(minter).write(approve);
        // docs:end:write_minter
    }
    // docs:end:set_minter


    // docs:start:mint_private
    #[aztec(public)]
    fn mint_private(amount: Field, secret_hash: Field) {
        assert(storage.minters.at(context.msg_sender()).read(), "caller is not minter");
        let pending_shields = storage.pending_shields;
        let mut note = TransparentNote::new(amount, secret_hash);
        let supply = storage.total_supply.read().add(U128::from_integer(amount));

        storage.total_supply.write(supply);
        // docs:start:insert_from_public
        pending_shields.insert_from_public(&mut note);
        // docs:end:insert_from_public
    }
    // docs:end:mint_private

    #[aztec(private)]
    fn privately_mint_private_note(amount: Field) {
        storage.balances.add(context.msg_sender(), U128::from_integer(amount));
        Token::at(context.this_address()).assert_minter_and_mint(context.msg_sender(), amount).enqueue(&mut context);
    }

    #[aztec(public)]
    #[aztec(internal)]
    fn assert_minter_and_mint(minter: AztecAddress, amount: Field) {
        assert(storage.minters.at(minter).read(), "caller is not minter");
        let supply = storage.total_supply.read() + U128::from_integer(amount);
        storage.total_supply.write(supply);
    }

    // docs:start:redeem_shield
    #[aztec(private)]
    fn redeem_shield(to: AztecAddress, amount: Field, secret: Field) {
        let pending_shields = storage.pending_shields;
        let secret_hash = compute_secret_hash(secret);
        // Get 1 note (set_limit(1)) which has amount stored in field with index 0 (select(0, amount)) and secret_hash
        // stored in field with index 1 (select(1, secret_hash)).
        let mut options = NoteGetterOptions::new();
        options = options.select(TransparentNote::properties().amount, amount, Option::none()).select(
            TransparentNote::properties().secret_hash,
            secret_hash,
            Option::none()
        ).set_limit(1);
        let notes = pending_shields.get_notes(options);
        let note = notes[0].unwrap_unchecked();
        // Remove the note from the pending shields set
        pending_shields.remove(note);

        // Add the token note to user's balances set
        storage.balances.add(to, U128::from_integer(amount));
    }
    // docs:end:redeem_shield


    // docs:start:transfer
    #[aztec(private)]
    fn transfer(from: AztecAddress, to: AztecAddress, amount: Field, nonce: Field) {
        // docs:start:assert_current_call_valid_authwit
        if (!from.eq(context.msg_sender())) {
            assert_current_call_valid_authwit(&mut context, from);
        } else {
            assert(nonce == 0, "invalid nonce");
        }
        // docs:end:assert_current_call_valid_authwit

        let amount = U128::from_integer(amount);
        storage.balances.sub(from, amount);
        // docs:start:increase_private_balance
        storage.balances.add(to, amount);
        // docs:end:increase_private_balance
    }
    // docs:end:transfer

    // docs:start:burn
    #[aztec(private)]
    fn burn(from: AztecAddress, amount: Field, nonce: Field) {
        if (!from.eq(context.msg_sender())) {
            assert_current_call_valid_authwit(&mut context, from);
        } else {
            assert(nonce == 0, "invalid nonce");
        }

        storage.balances.sub(from, U128::from_integer(amount));

        Token::at(context.this_address())._reduce_total_supply(amount).enqueue(&mut context);
    }
    // docs:end:burn

    /// Internal ///


    // docs:start:reduce_total_supply
    #[aztec(public)]
    #[aztec(internal)]
    fn _reduce_total_supply(amount: Field) {
        // Only to be called from burn.
        let new_supply = storage.total_supply.read().sub(U128::from_integer(amount));
        storage.total_supply.write(new_supply);
    }
    // docs:end:reduce_total_supply

    /// Unconstrained ///

    // docs:start:admin
    unconstrained fn admin() -> pub Field {
        storage.admin.read().to_field()
    }
    // docs:end:admin

    // docs:start:is_minter
    unconstrained fn is_minter(minter: AztecAddress) -> pub bool {
        storage.minters.at(minter).read()
    }
    // docs:end:is_minter

    // docs:start:total_supply
    unconstrained fn total_supply() -> pub Field {
        storage.total_supply.read().to_integer()
    }
    // docs:end:total_supply

    // docs:start:balance_of_private
    unconstrained fn balance_of_private(owner: AztecAddress) -> pub Field {
        storage.balances.balance_of(owner).to_integer()
    }
    // docs:end:balance_of_private
}
// docs:end:token_all