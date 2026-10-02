use crate::utils;
use cmtat_aztec::CMTATAztec as Token;
use cmtat_aztec_lib::modules::access_controlModule::MINTER_ROLE;

#[test]
unconstrained fn mint_private_success() {
    // Setup without account contracts. We are not using authwits here, so dummy accounts are enough
    let (env, token_contract_address, issuer, _) = utils::setup(/* with_account_contracts */ false);

    env.call_public(issuer, Token::at(token_contract_address).grant_role(MINTER_ROLE, issuer));

    let ret = env.view_public(Token::at(token_contract_address).has_role(MINTER_ROLE, issuer));

    //issuer does have minter role
    assert(ret == 1);

    let mint_amount = 10000 as u128;
    env.call_private(issuer, Token::at(token_contract_address).mint_to_private(issuer, mint_amount));

    utils::check_private_balance(env, token_contract_address, issuer, mint_amount);

    let total_supply = env.view_public(Token::at(token_contract_address).total_supply());
    assert(total_supply == mint_amount);
}

#[test]
unconstrained fn mint_private_batch_success() {
    // Setup without account contracts. We are not using authwits here, so dummy accounts are enough
    let (env, token_contract_address, issuer, user1, user2, _) =
        utils::setup_and_more_addresses(/* with_account_contracts */ false);

    env.call_public(issuer, Token::at(token_contract_address).grant_role(MINTER_ROLE, issuer));

    // Amounts are all different and two entries share a recipient, so a note that is dropped,
    // duplicated or credited to the wrong address changes a balance the assertions below read.
    let mint_amount = [1000 as u128, 2000 as u128, 300 as u128, 400 as u128];
    let addresses = [user1, user2, user1, user2];

    env.call_private(issuer, Token::at(token_contract_address).mint_batch(addresses, mint_amount));

    utils::check_private_balance(env, token_contract_address, user1, 1300 as u128);
    utils::check_private_balance(env, token_contract_address, user2, 2400 as u128);

    let total_supply = env.view_public(Token::at(token_contract_address).total_supply());
    assert(total_supply == 3700 as u128);
}

#[test(should_fail_with = "AccessControlUnauthorizedAccount")]
unconstrained fn mint_private_failure_non_minter() {
    // Setup without account contracts. We are not using authwits here, so dummy accounts are enough
    let (env, token_contract_address, _, user1) = utils::setup(/* with_account_contracts */ false);
    let mint_amount = 10000 as u128;
    // Try to mint some tokens as user1, who has no minter role
    env.call_private(user1, Token::at(token_contract_address).mint_to_private(user1, mint_amount));
}

#[test(should_fail)]
unconstrained fn mint_private_failure_overflow() {
    // Setup without account contracts. We are not using authwits here, so dummy accounts are enough
    let (env, token_contract_address, issuer, _) = utils::setup(/* with_account_contracts */ false);

    env.call_public(issuer, Token::at(token_contract_address).grant_role(MINTER_ROLE, issuer));

    // Overflow the issuer
    // We have to do this in 2 steps because we have to pass in a valid u128
    let amount_until_overflow = 1000 as u128;
    let mint_amount = (2.pow_32(128) - amount_until_overflow as Field) as u128;
    env.call_private(issuer, Token::at(token_contract_address).mint_to_private(issuer, mint_amount));
    env.call_private(issuer, Token::at(token_contract_address).mint_to_private(issuer, mint_amount));
}
