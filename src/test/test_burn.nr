use crate::test::utils;
use dep::aztec::{test::helpers::cheatcodes};
use dep::authwit::cheatcodes as authwit_cheatcodes;
use crate::Token;
use crate::types::access_controlModule::{DEFAULT_ADMIN_ROLE, BURNER_ROLE};


#[test]
unconstrained fn burn_private_on_behalf_of_self() {
    let (env, token_contract_address, issuer, _, mint_amount) = utils::setup_and_mint(/* with_account_contracts */ false);
    let burn_amount = mint_amount / 10;

    let grant_pause_roles_call_interface = Token::at(token_contract_address).grant_role(BURNER_ROLE, issuer);
    env.call_public(grant_pause_roles_call_interface);

    // Burn less than balance 
    let burn_call_interface = Token::at(token_contract_address).burn(issuer, burn_amount,0);
    env.call_private_void(burn_call_interface);
    utils::check_private_balance(token_contract_address, issuer, mint_amount - burn_amount);
}

#[test]
unconstrained fn burn_private_on_behalf_of_other() {
    let (env, token_contract_address, issuer, user1, mint_amount) = utils::setup_and_mint(/* with_account_contracts */ true);

    let mint_amount = 1000;
    let burn_amount = mint_amount / 10;

    let mint_private_call_interface = Token::at(token_contract_address).mint(user1, mint_amount);
    env.call_private_void(mint_private_call_interface);

    let grant_pause_roles_call_interface = Token::at(token_contract_address).grant_role(BURNER_ROLE, issuer);
    env.call_public(grant_pause_roles_call_interface);

    // Burn on behalf of other
    let burn_call_interface = Token::at(token_contract_address).burn(user1, burn_amount,1);
    authwit_cheatcodes::add_private_authwit_from_call_interface(user1, issuer, burn_call_interface);
    // Impersonate issuer to perform the call
    // Burn tokens
    env.impersonate(issuer);

    env.call_private_void(burn_call_interface);
    utils::check_private_balance(token_contract_address, user1, mint_amount - burn_amount);
}

#[test(should_fail_with="Balance too low")]
unconstrained fn burn_private_failure_more_than_balance() {
    let (env, token_contract_address, issuer, _, mint_amount) = utils::setup_and_mint(/* with_account_contracts */ false);

    let grant_pause_roles_call_interface = Token::at(token_contract_address).grant_role(BURNER_ROLE, issuer);
    env.call_public(grant_pause_roles_call_interface);
    // Burn more than balance 
    let burn_amount = mint_amount * 10;
    let burn_call_interface = Token::at(token_contract_address).burn(issuer, burn_amount, 0);
    env.call_private_void(burn_call_interface);
    // Private doesnt revert, so we cannot check balances here since notes have already been nullified. Test is done.
}

#[test(should_fail_with="invalid nonce")]
unconstrained fn burn_private_failure_on_behalf_of_self_non_zero_nonce() {
    let (env, token_contract_address, issuer, _, mint_amount) = utils::setup_and_mint(/* with_account_contracts */ false);

    let grant_pause_roles_call_interface = Token::at(token_contract_address).grant_role(BURNER_ROLE, issuer);
    env.call_public(grant_pause_roles_call_interface);

    let burn_amount = mint_amount / 10;
    let burn_call_interface = Token::at(token_contract_address).burn(issuer, burn_amount, 1);
    env.call_private_void(burn_call_interface);
}

#[test(should_fail)]
unconstrained fn burn_private_failure_on_behalf_of_other_more_than_balance() {
    let (env, token_contract_address, issuer, user1, mint_amount) = utils::setup_and_mint(/* with_account_contracts */ true);

    let grant_pause_roles_call_interface = Token::at(token_contract_address).grant_role(BURNER_ROLE, issuer);
    env.call_public(grant_pause_roles_call_interface);

    // Burn more than balance 
    let burn_amount = mint_amount * 10;
    // Burn on behalf of other
    let burn_call_interface = Token::at(token_contract_address).burn(issuer, burn_amount, 1);
    authwit_cheatcodes::add_private_authwit_from_call_interface(issuer, user1, burn_call_interface);
    // Impersonate user1 to perform the call
    env.impersonate(user1);
    env.call_private_void(burn_call_interface);
}

#[test(should_fail)]
unconstrained fn burn_private_failure_on_behalf_of_other_without_approval() {
    let (env, token_contract_address, issuer, user1, mint_amount) = utils::setup_and_mint(/* with_account_contracts */ true);

    let grant_pause_roles_call_interface = Token::at(token_contract_address).grant_role(BURNER_ROLE, issuer);
    env.call_public(grant_pause_roles_call_interface);

    let burn_amount = mint_amount / 10;
    let burn_call_interface = Token::at(token_contract_address).burn(issuer, burn_amount, 1);
    // Impersonate user1 to perform the call
    env.impersonate(user1);
    env.call_private_void(burn_call_interface);
}

#[test(should_fail)]
unconstrained fn burn_private_failure_on_behalf_of_other_wrong_designated_caller() {
    let (env, token_contract_address, issuer, user1, mint_amount) = utils::setup_and_mint(/* with_account_contracts */ true);

    let grant_pause_roles_call_interface = Token::at(token_contract_address).grant_role(BURNER_ROLE, issuer);
    env.call_public(grant_pause_roles_call_interface);

    let burn_amount = mint_amount / 10;
    // Burn on behalf of other
    let burn_call_interface = Token::at(token_contract_address).burn(issuer, burn_amount,1);
    authwit_cheatcodes::add_private_authwit_from_call_interface(issuer, issuer, burn_call_interface);
    // Impersonate user1 to perform the call
    env.impersonate(user1);
    env.call_private_void(burn_call_interface);
}