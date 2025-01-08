use crate::test::utils;
use dep::aztec::{test::helpers::cheatcodes};
use dep::authwit::cheatcodes as authwit_cheatcodes;
use crate::Token;

#[test]
unconstrained fn transfer_private() {
    // Setup without account contracts. We are not using authwits here, so dummy accounts are enough
    let (env, token_contract_address, issuer, user1, mint_amount) = utils::setup_and_mint(/* with_account_contracts */ false);

    // Transfer tokens
    let transfer_amount = 100;
    Token::at(token_contract_address).transfer(user1, transfer_amount).call(&mut env.private());

    // Check balances
    utils::check_private_balance(token_contract_address, issuer, mint_amount - transfer_amount);
    utils::check_private_balance(token_contract_address, user1, transfer_amount);

}
#[test]
unconstrained fn transfer_private_check_issuer_view(){
        // Setup without account contracts. We are not using authwits here, so dummy accounts are enough
    let (env, token_contract_address, issuer, user1, mint_amount) = utils::setup_and_mint(/* with_account_contracts */ false);

    // Transfer tokens
    let transfer_amount = 100;
    Token::at(token_contract_address).transfer(user1, 2*transfer_amount).call(&mut env.private());
    let user2 = env.create_account();

    env.impersonate(user1);
    Token::at(token_contract_address).transfer(user2, transfer_amount).call(&mut env.private());

    // Check balances
    utils::check_private_balance(token_contract_address, issuer, mint_amount - 2*transfer_amount);
    utils::check_private_balance(token_contract_address, user1, transfer_amount);
    utils::check_private_balance(token_contract_address, user2, transfer_amount);

    

}

#[test]
unconstrained fn transfer_private_to_self() {
    // Setup without account contracts. We are not using authwits here, so dummy accounts are enough
    let (env, token_contract_address, issuer, user1, mint_amount) = utils::setup_and_mint(/* with_account_contracts */ false);

    // Transfer tokens
    let transfer_amount = 1000;
    Token::at(token_contract_address).transfer(issuer, transfer_amount).call(&mut env.private());

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
    Token::at(token_contract_address).transfer(not_deployed.address, transfer_amount).call(&mut env.private());

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
    transfer_private_from_call_interface.call(&mut env.private());
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
    Token::at(token_contract_address).transfer(user1, transfer_amount).call(&mut env.private());
}

#[test(should_fail_with="invalid nonce")]
unconstrained fn transfer_private_failure_on_behalf_of_self_non_zero_nonce() {
    // Setup with account contracts. Slower since we actually deploy them, but needed for authwits.
    let (env, token_contract_address, issuer, user1, _) = utils::setup_and_mint(/* with_account_contracts */ true);
    // Add authwit
    let transfer_amount = 1000;
    Token::at(token_contract_address).transfer_from(issuer, user1, transfer_amount, 1).call(&mut env.private());
    // Transfer tokens
}


/*
*
* the below test is only done with an array of 1 value, as otherwise private calls would exceed protocol limitations
*/

#[test]
unconstrained fn transfer_private_batch_success() {
    // Setup without account contracts. We are not using authwits here, so dummy accounts are enough
    let (env, token_contract_address, issuer, user1, mint_amount) = utils::setup_and_mint(/* with_account_contracts */ false);
    let user2 = env.create_account_contract(3);
    let user3 = env.create_account_contract(4); 

    env.impersonate(issuer);


    let mut total_transfer_amount = 100;


    Token::at(token_contract_address).transfer_batch([user1], [100], 0).call(&mut env.private());


    utils::check_private_balance(token_contract_address, issuer, mint_amount - total_transfer_amount);
    utils::check_private_balance(token_contract_address, user1, total_transfer_amount);

}


#[test(should_fail_with="Balance too low")]
unconstrained fn transfer_private_failure_on_behalf_of_more_than_balance() {
    // Setup with account contracts. Slower since we actually deploy them, but needed for authwits.
    let (env, token_contract_address, owner, recipient, mint_amount) = utils::setup_and_mint(/* with_account_contracts */ true);
    // Add authwit
    let transfer_amount = mint_amount + 1;
    let transfer_private_from_call_interface = Token::at(token_contract_address).transfer_from(owner, recipient, transfer_amount, 1);
    authwit_cheatcodes::add_private_authwit_from_call_interface(owner, recipient, transfer_private_from_call_interface);
    // Impersonate recipient to perform the call
    env.impersonate(recipient);
    // Transfer tokens
    transfer_private_from_call_interface.call(&mut env.private());
}

#[test]
unconstrained fn transfer_private_failure_on_behalf_of_other_without_approval() {
    // Setup with account contracts. Slower since we actually deploy them, but needed for authwits.
    let (env, token_contract_address, owner, recipient, mint_amount) = utils::setup_and_mint(/* with_account_contracts */ true);
    // Add authwit
    let transfer_amount = 1000;
    let transfer_private_from_call_interface = Token::at(token_contract_address).transfer_from(owner, recipient, transfer_amount, 1);
    // Impersonate recipient to perform the call
    env.impersonate(recipient);
    // Transfer tokens
    env.assert_private_call_fails(transfer_private_from_call_interface);
}

#[test]
unconstrained fn transfer_private_failure_on_behalf_of_other_wrong_caller() {
    // Setup with account contracts. Slower since we actually deploy them, but needed for authwits.
    let (env, token_contract_address, owner, recipient, mint_amount) = utils::setup_and_mint(/* with_account_contracts */ true);
    // Add authwit
    let transfer_amount = 1000;
    let transfer_private_from_call_interface = Token::at(token_contract_address).transfer_from(owner, recipient, transfer_amount, 1);
    authwit_cheatcodes::add_private_authwit_from_call_interface(owner, owner, transfer_private_from_call_interface);
    // Impersonate recipient to perform the call
    env.impersonate(recipient);
    // Transfer tokens
    env.assert_private_call_fails(transfer_private_from_call_interface);

}