use crate::test::utils;
use dep::aztec::{test::helpers::cheatcodes, oracle::unsafe_rand::unsafe_rand, protocol_types::address::AztecAddress};
use dep::authwit::cheatcodes as authwit_cheatcodes;
use crate::Token;

#[test]
unconstrained fn transfer_private() {
    // Setup without account contracts. We are not using authwits here, so dummy accounts are enough
    let (env, token_contract_address, issuer, user1, mint_amount) = utils::setup_and_mint(/* with_account_contracts */ false);

    // Transfer tokens
    let transfer_amount = 100;
    let transfer_private_call_interface = Token::at(token_contract_address).transfer(user1, transfer_amount);
    env.call_private_void(transfer_private_call_interface);

    // Check balances
    utils::check_private_balance(token_contract_address, issuer, mint_amount - transfer_amount);
    utils::check_private_balance(token_contract_address, user1, transfer_amount);
}

#[test]
unconstrained fn transfer_private_to_self() {
    // Setup without account contracts. We are not using authwits here, so dummy accounts are enough
    let (env, token_contract_address, issuer, user1, mint_amount) = utils::setup_and_mint(/* with_account_contracts */ false);

    // Transfer tokens
    let transfer_amount = 1000;
    let transfer_private_call_interface = Token::at(token_contract_address).transfer(issuer, transfer_amount);
    env.call_private_void(transfer_private_call_interface);

    // Check balances
    utils::check_private_balance(token_contract_address, issuer, mint_amount);
}

#[test]
unconstrained fn transfer_private_to_non_deployed_account() {
    // Setup without account contracts. We are not using authwits here, so dummy accounts are enough
    let (env, token_contract_address, issuer, user1, mint_amount) = utils::setup_and_mint(/* with_account_contracts */ false);
    let not_deployed = cheatcodes::create_account();

    // Transfer tokens
    let transfer_amount = 1000;
    let transfer_private_call_interface = Token::at(token_contract_address).transfer(not_deployed.address, transfer_amount);
    env.call_private_void(transfer_private_call_interface);

    // Check balances
    utils::check_private_balance(token_contract_address, issuer, mint_amount - transfer_amount);
    utils::check_private_balance(token_contract_address, not_deployed.address, transfer_amount);
}

#[test]
unconstrained fn transfer_private_on_behalf_of_other() {
    // Setup with account contracts. Slower since we actually deploy them, but needed for authwits.
    let (env, token_contract_address, issuer, user1, mint_amount) = utils::setup_and_mint(/* with_account_contracts */ true);

    // Add authwit
    // docs:start:private_authwit
    let transfer_amount = 1000;
    let transfer_private_from_call_interface = Token::at(token_contract_address).transfer_from(issuer, user1, transfer_amount, 1);
    authwit_cheatcodes::add_private_authwit_from_call_interface(issuer, user1, transfer_private_from_call_interface);
    // Impersonate issuer to perform the call
    env.impersonate(user1);
    // Transfer tokens
    env.call_private_void(transfer_private_from_call_interface);
    // docs:end:private_authwit
    // Check balances
    utils::check_private_balance(token_contract_address, issuer, mint_amount - transfer_amount);
    utils::check_private_balance(token_contract_address, user1, transfer_amount);
}

#[test(should_fail_with="Balance too low")]
unconstrained fn transfer_private_failure_more_than_balance() {
    // Setup without account contracts. We are not using authwits here, so dummy accounts are enough
    let (env, token_contract_address, _, user1, mint_amount) = utils::setup_and_mint(/* with_account_contracts */ false);
    // Transfer tokens
    let transfer_amount = mint_amount + 1;
    let transfer_private_call_interface = Token::at(token_contract_address).transfer(user1, transfer_amount);
    env.call_private_void(transfer_private_call_interface);
}

// docs:start:fail_with_message
#[test(should_fail_with="invalid nonce")]
unconstrained fn transfer_private_failure_on_behalf_of_self_non_zero_nonce() {
    // Setup with account contracts. Slower since we actually deploy them, but needed for authwits.
    let (env, token_contract_address, issuer, user1, _) = utils::setup_and_mint(/* with_account_contracts */ true);
    // Add authwit
    let transfer_amount = 1000;
    let transfer_private_from_call_interface = Token::at(token_contract_address).transfer_from(issuer, user1, transfer_amount, 1);
    // Transfer tokens
    env.call_private_void(transfer_private_from_call_interface);
}
// docs:end:fail_with_message


// //SHELL command fails when there are more than 6 tests in a file. The tests are temprarly moved to "transfer_private_2.nr"



#[test(should_fail_with="Balance too low")]
unconstrained fn transfer_private_failure_on_behalf_of_more_than_balance() {
    // Setup with account contracts. Slower since we actually deploy them, but needed for authwits.
    let (env, token_contract_address, issuer, user1, mint_amount) = utils::setup_and_mint(/* with_account_contracts */ true);
    // Add authwit
    let transfer_amount = mint_amount + 1;
    let transfer_private_from_call_interface = Token::at(token_contract_address).transfer_from(issuer, user1, transfer_amount, 1);
    authwit_cheatcodes::add_private_authwit_from_call_interface(issuer, user1, transfer_private_from_call_interface);
    // Impersonate user1 to perform the call
    env.impersonate(user1);
    // Transfer tokens
    env.call_private_void(transfer_private_from_call_interface);
}

#[test(should_fail)]
unconstrained fn transfer_private_failure_on_behalf_of_other_without_approval() {
    // Setup with account contracts. Slower since we actually deploy them, but needed for authwits.
    let (env, token_contract_address, issuer, user1, mint_amount) = utils::setup_and_mint(/* with_account_contracts */ true);
    // Add authwit
    let transfer_amount = 1000;
    let transfer_private_from_call_interface = Token::at(token_contract_address).transfer_from(issuer, user1, transfer_amount, 1);
    // Impersonate user1 to perform the call
    env.impersonate(user1);
    // Transfer tokens
    env.call_private_void(transfer_private_from_call_interface);
    // Check balances
    utils::check_private_balance(token_contract_address, issuer, mint_amount - transfer_amount);
    utils::check_private_balance(token_contract_address, user1, transfer_amount);
}

// #[test(should_fail)]
// unconstrained fn transfer_private_failure_on_behalf_of_other_wrong_caller() {
//     // Setup with account contracts. Slower since we actually deploy them, but needed for authwits.
//     let (env, token_contract_address, issuer, user1, mint_amount) = utils::setup_and_mint(/* with_account_contracts */ true);
//     // Add authwit
//     let transfer_amount = 1000;
//     let transfer_private_from_call_interface = Token::at(token_contract_address).transfer_from(issuer, user1, transfer_amount, 1);
//     authwit_cheatcodes::add_private_authwit_from_call_interface(issuer, issuer, transfer_private_from_call_interface);
//     // Impersonate user1 to perform the call
//     env.impersonate(user1);
//     // Transfer tokens
//     env.call_private_void(transfer_private_from_call_interface);
//     // Check balances
//     utils::check_private_balance(token_contract_address, issuer, mint_amount - transfer_amount);
//     utils::check_private_balance(token_contract_address, user1, transfer_amount);
// }