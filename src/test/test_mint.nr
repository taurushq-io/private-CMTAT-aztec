use crate::test::utils;
use dep::aztec::{test::helpers::cheatcodes};
use crate::{ Token};
use crate::types::access_controlModule::{DEFAULT_ADMIN_ROLE, MINTER_ROLE};


//TODO we do not test minter role yet because we know that it won't revert according to error that we have spotted.

#[test]
unconstrained fn mint_private_success() {
    // Setup without account contracts. We are not using authwits here, so dummy accounts are enough
    let (env, token_contract_address, issuer, _) = utils::setup(/* with_account_contracts */ false);

    let grant_pause_roles_call_interface = Token::at(token_contract_address).grant_role(MINTER_ROLE, issuer);
    env.call_public(grant_pause_roles_call_interface);

    let get_is_pause_roles_call_interface = Token::at(token_contract_address).has_role(MINTER_ROLE, issuer);
    let ret = env.call_public(get_is_pause_roles_call_interface);

    //issuer does have minter role
    assert(ret == 1);

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
    
    let grant_pause_roles_call_interface = Token::at(token_contract_address).grant_role(MINTER_ROLE, issuer);
    env.call_public(grant_pause_roles_call_interface);

    let mint_amount = [10000];
    let addresses = [user1];

    let mint_private_call_interface = Token::at(token_contract_address).mint_batch(addresses, mint_amount);
    env.call_private_void(mint_private_call_interface);

    utils::check_private_balance(token_contract_address, addresses[0], mint_amount[0]);

    let total_supply_call_interface = Token::at(token_contract_address).total_supply();
    let total_supply = env.call_public(total_supply_call_interface);

    let mut total_mint_amount = 0;
    for i in 0..1 {
        total_mint_amount += mint_amount[i];
    }

    assert(total_supply == total_mint_amount);
}


#[test(should_fail_with="Assertion failed: AccessControlUnauthorizedAccount")]
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

//TODO: this test does not fail


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
