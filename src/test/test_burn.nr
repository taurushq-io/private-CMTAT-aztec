use crate::test::utils;
use dep::authwit::cheatcodes as authwit_cheatcodes;
use crate::CMTAToken as Token;
use crate::modules::access_controlModule::{BURNER_ROLE, MINTER_ROLE};


#[test]
unconstrained fn burn_private_on_behalf_of_self() {
    let (env, token_contract_address, issuer, _, mint_amount) = utils::setup_and_mint(/* with_account_contracts */ false);
    let burn_amount = mint_amount / 10;

    Token::at(token_contract_address).grant_role(BURNER_ROLE, issuer).call(&mut env.public());

    // Burn less than balance 
    Token::at(token_contract_address).burn(issuer, burn_amount,0).call(&mut env.private());
    utils::check_private_balance(token_contract_address, issuer, mint_amount - burn_amount);
}

#[test]
unconstrained fn burn_private_on_behalf_of_other() {
    let (env, token_contract_address, issuer, user1, mint_amount) = utils::setup_and_mint(/* with_account_contracts */ true);

    let mint_amount = 1000;
    let burn_amount = mint_amount / 10;

    Token::at(token_contract_address).mint(user1, mint_amount).call(&mut env.private());

    Token::at(token_contract_address).grant_role(BURNER_ROLE, issuer).call(&mut env.public());

    // Burn on behalf of other
    let burn_call_interface = Token::at(token_contract_address).burn(user1, burn_amount,1);
    authwit_cheatcodes::add_private_authwit_from_call_interface(user1, issuer, burn_call_interface);
    // Impersonate issuer to perform the call
    // Burn tokens
    env.impersonate(issuer);

    burn_call_interface.call(&mut env.private());
    utils::check_private_balance(token_contract_address, user1, mint_amount - burn_amount);
}

#[test(should_fail_with="Balance too low")]
unconstrained fn burn_private_failure_more_than_balance() {
    let (env, token_contract_address, issuer, _, mint_amount) = utils::setup_and_mint(/* with_account_contracts */ false);

    Token::at(token_contract_address).grant_role(BURNER_ROLE, issuer).call(&mut env.public());
    // Burn more than balance 
    let burn_amount = mint_amount * 10;
    Token::at(token_contract_address).burn(issuer, burn_amount, 0).call(&mut env.private());
    // Private doesnt revert, so we cannot check balances here since notes have already been nullified. Test is done.
}

#[test(should_fail)]
unconstrained fn burn_private_failure_on_behalf_of_other_more_than_balance() {
    let (env, token_contract_address, issuer, user1, mint_amount) = utils::setup_and_mint(/* with_account_contracts */ true);

    Token::at(token_contract_address).grant_role(BURNER_ROLE, issuer).call(&mut env.public());

    // Burn more than balance 
    let burn_amount = mint_amount * 10;
    // Burn on behalf of other
    let burn_call_interface = Token::at(token_contract_address).burn(issuer, burn_amount, 1);
    authwit_cheatcodes::add_private_authwit_from_call_interface(issuer, user1, burn_call_interface);
    // Impersonate user1 to perform the call
    env.impersonate(user1);
    burn_call_interface.call(&mut env.private());
}

#[test(should_fail)]
unconstrained fn burn_private_failure_on_behalf_of_other_without_approval() {
    let (env, token_contract_address, issuer, user1, mint_amount) = utils::setup_and_mint(/* with_account_contracts */ true);

    Token::at(token_contract_address).grant_role(BURNER_ROLE, issuer).call(&mut env.public());

    let burn_amount = mint_amount / 10;
    let burn_call_interface = Token::at(token_contract_address).burn(issuer, burn_amount, 1);
    // Impersonate user1 to perform the call
    env.impersonate(user1);
    burn_call_interface.call(&mut env.private());
}

#[test(should_fail)]
unconstrained fn burn_private_failure_on_behalf_of_other_wrong_designated_caller() {
    let (env, token_contract_address, issuer, user1, mint_amount) = utils::setup_and_mint(/* with_account_contracts */ true);

    Token::at(token_contract_address).grant_role(BURNER_ROLE, issuer).call(&mut env.public());

    let burn_amount = mint_amount / 10;
    // Burn on behalf of other
    let burn_call_interface = Token::at(token_contract_address).burn(issuer, burn_amount,1);
    authwit_cheatcodes::add_private_authwit_from_call_interface(issuer, issuer, burn_call_interface);
    // Impersonate user1 to perform the call
    env.impersonate(user1);
    burn_call_interface.call(&mut env.private());
}

//TODO: test does not pass
#[test]
unconstrained fn burn_private_batch_success() {
    // Setup without account contracts. We are not using authwits here, so dummy accounts are enough
    let (env, token_contract_address, issuer, user1, _ , _) = utils::setup_and_more_addresses(/* with_account_contracts */ false);
    
    Token::at(token_contract_address).grant_role(MINTER_ROLE, issuer).call(&mut env.public());

    let mint_amount = [10000];
    let addresses = [user1];

    Token::at(token_contract_address).mint_batch(addresses, mint_amount).call(&mut env.private());

    utils::check_private_balance(token_contract_address, addresses[0], mint_amount[0]);

    let total_supply = Token::at(token_contract_address).total_supply().view(&mut env.public());

    let mut total_mint_amount = 0;
    for i in 0..1 {
        total_mint_amount += mint_amount[i];
    }

    assert(total_supply == total_mint_amount);

    Token::at(token_contract_address).grant_role(BURNER_ROLE, issuer).call(&mut env.public());

    let burn_amount = [mint_amount[0] / 2];

    // Burn on behalf of other
    let burn_call_interface = Token::at(token_contract_address).burn_batch(addresses, burn_amount,1);
    authwit_cheatcodes::add_private_authwit_from_call_interface(addresses[0], issuer, burn_call_interface);
    // Impersonate issuer to perform the call
    // Burn tokens
    env.impersonate(issuer);
    burn_call_interface.call(&mut env.private());

    utils::check_private_balance(token_contract_address, addresses[0], mint_amount[0] - burn_amount[0]);
    let total_supply_after_burn = Token::at(token_contract_address).total_supply().view(&mut env.public());
    assert(total_supply_after_burn == total_supply - burn_amount[0]);
}