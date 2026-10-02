use crate::utils;
use aztec::test::helpers::authwit::add_private_authwit_from_call;
use cmtat_aztec::CMTATAztec as Token;
use cmtat_aztec_lib::modules::access_controlModule::{BURNER_ROLE, MINTER_ROLE};

global AUTHWIT_NONCE: Field = 7;

#[test]
unconstrained fn burn_private_on_behalf_of_self() {
    let (env, token_contract_address, issuer, _, mint_amount) =
        utils::setup_and_mint(/* with_account_contracts */ false);
    let burn_amount = mint_amount / 10 as u128;

    env.call_public(issuer, Token::at(token_contract_address).grant_role(BURNER_ROLE, issuer));

    // Burn less than balance
    env.call_private(issuer, Token::at(token_contract_address).burn(issuer, burn_amount, 0));
    utils::check_private_balance(
        env,
        token_contract_address,
        issuer,
        mint_amount - burn_amount,
    );
}

#[test]
unconstrained fn burn_private_on_behalf_of_other() {
    let (env, token_contract_address, issuer, user1, _) =
        utils::setup_and_mint(/* with_account_contracts */ true);

    // The issuer burns on user1's behalf, so msg_sender in the token differs from `from`
    let caller = issuer;
    let user1_amount = 1000 as u128;
    let burn_amount = user1_amount / 10 as u128;

    env.call_private(issuer, Token::at(token_contract_address).mint_to_private(user1, user1_amount));
    env.call_public(issuer, Token::at(token_contract_address).grant_role(BURNER_ROLE, caller));

    // Burn on behalf of other
    let burn_call = Token::at(token_contract_address).burn(user1, burn_amount, AUTHWIT_NONCE);
    add_private_authwit_from_call(env, user1, caller, burn_call);

    utils::call_private_on_behalf_of(env, caller, user1, burn_call);
    utils::check_private_balance(
        env,
        token_contract_address,
        user1,
        user1_amount - burn_amount,
    );
}

#[test(should_fail_with = "Balance too low")]
unconstrained fn burn_private_failure_more_than_balance() {
    let (env, token_contract_address, issuer, _, mint_amount) =
        utils::setup_and_mint(/* with_account_contracts */ false);

    env.call_public(issuer, Token::at(token_contract_address).grant_role(BURNER_ROLE, issuer));
    // Burn more than balance
    let burn_amount = mint_amount * 10 as u128;
    env.call_private(issuer, Token::at(token_contract_address).burn(issuer, burn_amount, 0));
}

#[test(should_fail_with = "Balance too low")]
unconstrained fn burn_private_failure_on_behalf_of_other_more_than_balance() {
    let (env, token_contract_address, issuer, user1, mint_amount) =
        utils::setup_and_mint(/* with_account_contracts */ true);

    let caller = user1;
    env.call_public(issuer, Token::at(token_contract_address).grant_role(BURNER_ROLE, caller));

    // Burn more than balance
    let burn_amount = mint_amount * 10 as u128;
    let burn_call = Token::at(token_contract_address).burn(issuer, burn_amount, AUTHWIT_NONCE);
    add_private_authwit_from_call(env, issuer, caller, burn_call);

    utils::call_private_on_behalf_of(env, caller, issuer, burn_call);
}

#[test(should_fail_with = "Unknown auth witness for message hash")]
unconstrained fn burn_private_failure_on_behalf_of_other_without_approval() {
    let (env, token_contract_address, issuer, user1, mint_amount) =
        utils::setup_and_mint(/* with_account_contracts */ true);

    let caller = user1;
    env.call_public(issuer, Token::at(token_contract_address).grant_role(BURNER_ROLE, caller));

    let burn_amount = mint_amount / 10 as u128;
    let burn_call = Token::at(token_contract_address).burn(issuer, burn_amount, AUTHWIT_NONCE);
    // No authwit is added

    utils::call_private_on_behalf_of(env, caller, issuer, burn_call);
}

#[test(should_fail_with = "Unknown auth witness for message hash")]
unconstrained fn burn_private_failure_on_behalf_of_other_wrong_designated_caller() {
    let (env, token_contract_address, issuer, user1, mint_amount) =
        utils::setup_and_mint(/* with_account_contracts */ true);

    let caller = user1;
    env.call_public(issuer, Token::at(token_contract_address).grant_role(BURNER_ROLE, caller));

    let burn_amount = mint_amount / 10 as u128;
    let burn_call = Token::at(token_contract_address).burn(issuer, burn_amount, AUTHWIT_NONCE);
    // The authwit designates `issuer` as the caller, but user1 is the one that calls
    add_private_authwit_from_call(env, issuer, issuer, burn_call);

    utils::call_private_on_behalf_of(env, caller, issuer, burn_call);
}

#[test]
unconstrained fn burn_private_batch_success() {
    // Setup without account contracts. We are not using authwits here, so dummy accounts are enough
    let (env, token_contract_address, issuer, user1, user2, _) =
        utils::setup_and_more_addresses(/* with_account_contracts */ false);

    env.call_public(issuer, Token::at(token_contract_address).grant_role(MINTER_ROLE, issuer));

    let mint_amount = [1000 as u128, 2000 as u128, 300 as u128, 400 as u128];
    let addresses = [user1, user2, user1, user2];

    env.call_private(issuer, Token::at(token_contract_address).mint_batch(addresses, mint_amount));

    let total_supply = env.view_public(Token::at(token_contract_address).total_supply());
    assert(total_supply == 3700 as u128);

    env.call_public(issuer, Token::at(token_contract_address).grant_role(BURNER_ROLE, user1));

    // burn_batch debits a single account, so every entry comes out of user1's 1300.
    let burn_amount = [100 as u128, 200 as u128, 30 as u128, 40 as u128];
    let burnt = 370 as u128;

    // user1 burns from their own balance, so no authwit is needed and the nonce must be zero.
    env.call_private(user1, Token::at(token_contract_address).burn_batch(user1, burn_amount, 0));

    utils::check_private_balance(env, token_contract_address, user1, 1300 as u128 - burnt);
    utils::check_private_balance(env, token_contract_address, user2, 2400 as u128);

    let total_supply_after_burn = env.view_public(Token::at(token_contract_address).total_supply());
    assert(total_supply_after_burn == total_supply - burnt);
}
