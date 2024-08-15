use crate::test::utils;
use dep::aztec::{test::helpers::cheatcodes, oracle::unsafe_rand::unsafe_rand, hash::compute_secret_hash};
use crate::{ Token};

#[test]
unconstrained fn mint_private_success() {
    // Setup without account contracts. We are not using authwits here, so dummy accounts are enough
    let (env, token_contract_address, issuer, _) = utils::setup(/* with_account_contracts */ false);

    let mint_amount = 10000;
    let mint_private_call_interface = Token::at(token_contract_address).mint(issuer, mint_amount);
    env.call_private_void(mint_private_call_interface);

    utils::check_private_balance(token_contract_address, issuer, mint_amount);

    let total_supply_call_interface = Token::at(token_contract_address).total_supply();
    let total_supply = env.call_public(total_supply_call_interface);

    assert(total_supply == mint_amount);
}

#[test]
unconstrained fn mint_private_batch_success() {
    // Setup without account contracts. We are not using authwits here, so dummy accounts are enough
    let (env, token_contract_address, issuer, user1,user2,user3) = utils::setup_and_more_addresses(/* with_account_contracts */ false);

    let mint_amount = [10000,1000,0,0];
    let addresses = [issuer, user1,user2,user2];

    let mint_private_call_interface = Token::at(token_contract_address).mint_batch(addresses, mint_amount);
    env.call_private_void(mint_private_call_interface);

    utils::check_private_balance(token_contract_address, addresses[0], mint_amount[0]);
    utils::check_private_balance(token_contract_address, addresses[1], mint_amount[1]);

    let total_supply_call_interface = Token::at(token_contract_address).total_supply();
    let total_supply = env.call_public(total_supply_call_interface);

    let mut total_mint_amount = 0;
    for i in 0..4 {
        total_mint_amount += mint_amount[i];
    }

    assert(total_supply == total_mint_amount);
}



#[test(should_fail_with="Caller is not issuer")]
unconstrained fn mint_private_failure_non_minter() {
    // Setup without account contracts. We are not using authwits here, so dummy accounts are enough
    let (env, token_contract_address, _, user1) = utils::setup(/* with_account_contracts */ false);
    let mint_amount = 10000;
    // Try to mint some tokens impersonating user1
    env.impersonate(user1);

    let mint_private_call_interface = Token::at(token_contract_address).mint(user1, mint_amount);
    env.call_private_void(mint_private_call_interface);
}

#[test(should_fail_with="call to assert_max_bit_size")]
unconstrained fn mint_private_failure_overflow() {
    // Setup without account contracts. We are not using authwits here, so dummy accounts are enough
    let (env, token_contract_address, issuer, _) = utils::setup(/* with_account_contracts */ false);

    // Overflow user1
    let mint_amount = 2.pow_32(128);
    let mint_private_call_interface = Token::at(token_contract_address).mint(issuer, mint_amount);
    env.call_private_void(mint_private_call_interface);
}

// #[test(should_fail_with="attempt to add with overflow")]
// unconstrained fn mint_private_failure_overflow_recipient() {
//     // Setup without account contracts. We are not using authwits here, so dummy accounts are enough
//     let (env, token_contract_address, issuer, _) = utils::setup(/* with_account_contracts */ false);
//     let mint_amount = 10000;
//     // Mint some tokens
//     let mint_private_call_interface = Token::at(token_contract_address).mint(issuer, mint_amount);
//     env.call_private_void(mint_private_call_interface);

//     // TODO: understand: Time travel so we can read keys from the registry - ?? Don't understand this
//     env.advance_block_by(6);

//     utils::check_private_balance(token_contract_address, issuer, mint_amount);

//     let mint_amount = 2.pow_32(128)-mint_amount;
//     let mint_private_call_interface = Token::at(token_contract_address).mint(issuer, mint_amount);
//     env.call_private_void(mint_private_call_interface);

//     let total_supply_call_interface = Token::at(token_contract_address).total_supply();
//     let total_supply = env.call_public(total_supply_call_interface);

//     std::println(total_supply);

// }

// #[test(should_fail_with="attempt to add with overflow")]
// unconstrained fn mint_private_failure_overflow_total_supply() {
//     // Setup without account contracts. We are not using authwits here, so dummy accounts are enough
//     let (env, token_contract_address, issuer, user1) = utils::setup(/* with_account_contracts */ false);
//     let mint_amount = 10000;
//     // Mint some tokens
//     let secret_owner = unsafe_rand();
//     let secret_recipient = unsafe_rand();
//     let secret_hash_owner = compute_secret_hash(secret_owner);
//     let secret_hash_recipient = compute_secret_hash(secret_recipient);

//     let mint_private_call_interface = Token::at(token_contract_address).mint_private(mint_amount, secret_hash_owner);
//     env.call_public(mint_private_call_interface);
//     let mint_private_call_interface = Token::at(token_contract_address).mint_private(mint_amount, secret_hash_recipient);
//     env.call_public(mint_private_call_interface);

//     // Time travel so we can read keys from the registry
//     env.advance_block_by(6);

//     // Store 2 notes in the cache so we can redeem it for issuer and user1
//     env.store_note_in_cache(
//         &mut TransparentNote::new(mint_amount, secret_hash_owner),
//         Token::storage().pending_shields.slot,
//         token_contract_address
//     );
//     env.store_note_in_cache(
//         &mut TransparentNote::new(mint_amount, secret_hash_recipient),
//         Token::storage().pending_shields.slot,
//         token_contract_address
//     );

//     // Redeem issuer's shielded tokens
//     env.impersonate(issuer);
//     let redeem_shield_call_interface = Token::at(token_contract_address).redeem_shield(issuer, mint_amount, secret_owner);
//     env.call_private_void(redeem_shield_call_interface);

//     // Redeem user1's shielded tokens
//     env.impersonate(user1);
//     let redeem_shield_call_interface = Token::at(token_contract_address).redeem_shield(user1, mint_amount, secret_recipient);
//     env.call_private_void(redeem_shield_call_interface);

//     utils::check_private_balance(token_contract_address, issuer, mint_amount);
//     utils::check_private_balance(token_contract_address, user1, mint_amount);

//     env.impersonate(issuer);
//     let mint_amount = 2.pow_32(128) - 2 * mint_amount;
//     // Try to mint some tokens
//     let secret = unsafe_rand();
//     let secret_hash = compute_secret_hash(secret);
//     let mint_private_call_interface = Token::at(token_contract_address).mint_private(mint_amount, secret_hash);
//     env.call_public(mint_private_call_interface);
// }