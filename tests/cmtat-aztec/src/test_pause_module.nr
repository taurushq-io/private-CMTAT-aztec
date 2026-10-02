use crate::utils;
use cmtat_aztec::CMTATAztec as Token;
use cmtat_aztec_lib::modules::access_controlModule::{BURNER_ROLE, MINTER_ROLE, PAUSE_ROLE};

#[test]
unconstrained fn get_paused() {
    let (env, token_contract_address, _, _) = utils::setup(/* with_account_contracts */ false);

    let ret = env.view_public(Token::at(token_contract_address).public_get_pause());
    assert(ret == 0);
}

#[test]
unconstrained fn pause_test() {
    let (env, token_contract_address, issuer, _) = utils::setup(/* with_account_contracts */ false);

    //check if issuer has pause role
    let ret = env.view_public(Token::at(token_contract_address).has_role(PAUSE_ROLE, issuer));

    //issuer does not have pause role
    assert(ret == 0);

    //give pause role to issuer
    env.call_public(issuer, Token::at(token_contract_address).grant_role(PAUSE_ROLE, issuer));

    //checks that issuer has pause role
    let ret = env.view_public(Token::at(token_contract_address).has_role(PAUSE_ROLE, issuer));
    assert(ret == 1);

    //checks if contract is paused
    let ret = env.view_public(Token::at(token_contract_address).public_get_pause());
    assert(ret == 0);

    //issuer pauses the contract
    env.call_public(issuer, Token::at(token_contract_address).pause_contract());

    //checks if contract is indeed paused
    let ret = env.view_public(Token::at(token_contract_address).public_get_pause());
    assert(ret == 1);

    //issuer unpauses the contract
    env.call_public(issuer, Token::at(token_contract_address).unpause_contract());

    //checks that the contract has been unpaused correctly
    let ret = env.view_public(Token::at(token_contract_address).public_get_pause());
    assert(ret == 0);
}

/// As in CMTAT Solidity, a pause stops transfers but not issuance or redemption: `_canMintBurnByModule`
/// checks deactivation and freeze, not `paused()`. Only deactivation stops mint and burn.
#[test]
unconstrained fn mint_when_paused_succeeds() {
    let (env, token_contract_address, issuer, _) = utils::setup(/* with_account_contracts */ false);

    let mint_amount = 10000 as u128;

    env.call_public(issuer, Token::at(token_contract_address).grant_role(PAUSE_ROLE, issuer));
    env.call_public(issuer, Token::at(token_contract_address).grant_role(MINTER_ROLE, issuer));
    env.call_public(issuer, Token::at(token_contract_address).pause_contract());

    let ret = env.view_public(Token::at(token_contract_address).public_get_pause());
    assert(ret == 1);

    env.call_private(issuer, Token::at(token_contract_address).mint_to_private(issuer, mint_amount));

    utils::check_private_balance(env, token_contract_address, issuer, mint_amount);
    let total_supply = env.view_public(Token::at(token_contract_address).total_supply());
    assert(total_supply == mint_amount);
}

#[test]
unconstrained fn burn_when_paused_succeeds() {
    let (env, token_contract_address, issuer, _, mint_amount) =
        utils::setup_and_mint(/* with_account_contracts */ false);

    env.call_public(issuer, Token::at(token_contract_address).grant_role(PAUSE_ROLE, issuer));
    env.call_public(issuer, Token::at(token_contract_address).grant_role(BURNER_ROLE, issuer));
    env.call_public(issuer, Token::at(token_contract_address).pause_contract());

    let burn_amount = 1000 as u128;
    env.call_private(issuer, Token::at(token_contract_address).burn(issuer, burn_amount, 0));

    utils::check_private_balance(
        env,
        token_contract_address,
        issuer,
        mint_amount - burn_amount,
    );
    let total_supply = env.view_public(Token::at(token_contract_address).total_supply());
    assert(total_supply == mint_amount - burn_amount);
}

#[test(should_fail_with = "Error: token contract is paused")]
unconstrained fn transfer_when_paused_fails() {
    let (env, token_contract_address, issuer, user1, _) =
        utils::setup_and_mint(/* with_account_contracts */ false);

    let transfer_amount = 100 as u128;

    env.call_public(issuer, Token::at(token_contract_address).grant_role(PAUSE_ROLE, issuer));
    env.call_public(issuer, Token::at(token_contract_address).grant_role(MINTER_ROLE, issuer));
    env.call_public(issuer, Token::at(token_contract_address).pause_contract());

    let ret = env.view_public(Token::at(token_contract_address).public_get_pause());
    assert(ret == 1);

    env.call_private(
        issuer,
        Token::at(token_contract_address).transfer_private_to_private(
            issuer,
            user1,
            transfer_amount,
            0,
        ),
    );
}

#[test(should_fail_with = "error: contract already paused")]
unconstrained fn pause_twice_throws() {
    let (env, token_contract_address, issuer, _) = utils::setup(/* with_account_contracts */ false);

    env.call_public(issuer, Token::at(token_contract_address).grant_role(PAUSE_ROLE, issuer));
    env.call_public(issuer, Token::at(token_contract_address).pause_contract());
    env.call_public(issuer, Token::at(token_contract_address).pause_contract());
}

//pause fails when caller does not have pause role
#[test(should_fail_with = "AccessControlUnauthorizedAccount")]
unconstrained fn test_pause_roles() {
    let (env, token_contract_address, _, user1) = utils::setup(/* with_account_contracts */ false);

    env.call_public(user1, Token::at(token_contract_address).pause_contract());
}

//owner has role when pause but not the role when unpause
#[test(should_fail_with = "AccessControlUnauthorizedAccount")]
unconstrained fn test_pause_role_2() {
    let (env, token_contract_address, issuer, user) =
        utils::setup(/* with_account_contracts */ false);

    env.call_public(issuer, Token::at(token_contract_address).grant_role(PAUSE_ROLE, user));

    env.call_public(user, Token::at(token_contract_address).pause_contract());

    //checks if contract is indeed paused
    let ret = env.view_public(Token::at(token_contract_address).public_get_pause());
    assert(ret == 1);

    env.call_public(issuer, Token::at(token_contract_address).revoke_role(PAUSE_ROLE, user));

    env.call_public(user, Token::at(token_contract_address).unpause_contract());
}

/* ==========================================================
 * ===================== DEACTIVATION ========================
 * ======================================================== */

#[test]
unconstrained fn get_deactivated_default() {
    let (env, token_contract_address, _, _) = utils::setup(/* with_account_contracts */ false);

    let ret = env.view_public(Token::at(token_contract_address).public_get_deactivated());
    assert(ret == 0);
}

#[test]
unconstrained fn deactivate_test() {
    let (env, token_contract_address, issuer, _) = utils::setup(/* with_account_contracts */ false);

    env.call_public(issuer, Token::at(token_contract_address).grant_role(PAUSE_ROLE, issuer));
    env.call_public(issuer, Token::at(token_contract_address).pause_contract());

    env.call_public(issuer, Token::at(token_contract_address).deactivate_contract());

    let ret = env.view_public(Token::at(token_contract_address).public_get_deactivated());
    assert(ret == 1);
    // deactivation freezes the pause in place
    let paused = env.view_public(Token::at(token_contract_address).public_get_pause());
    assert(paused == 1);
}

#[test(should_fail_with = "error: contract already unpaused")]
unconstrained fn deactivate_requires_pause() {
    let (env, token_contract_address, issuer, _) = utils::setup(/* with_account_contracts */ false);

    // Not paused: deactivation must be refused.
    env.call_public(issuer, Token::at(token_contract_address).deactivate_contract());
}

#[test(should_fail_with = "AccessControlUnauthorizedAccount")]
unconstrained fn deactivate_requires_admin() {
    let (env, token_contract_address, issuer, user) =
        utils::setup(/* with_account_contracts */ false);

    env.call_public(issuer, Token::at(token_contract_address).grant_role(PAUSE_ROLE, issuer));
    env.call_public(issuer, Token::at(token_contract_address).pause_contract());

    // `user` holds neither the admin role nor any other.
    env.call_public(user, Token::at(token_contract_address).deactivate_contract());
}

#[test(should_fail_with = "error: contract is deactivated")]
unconstrained fn deactivate_twice_throws() {
    let (env, token_contract_address, issuer, _) = utils::setup(/* with_account_contracts */ false);

    env.call_public(issuer, Token::at(token_contract_address).grant_role(PAUSE_ROLE, issuer));
    env.call_public(issuer, Token::at(token_contract_address).pause_contract());
    env.call_public(issuer, Token::at(token_contract_address).deactivate_contract());
    env.call_public(issuer, Token::at(token_contract_address).deactivate_contract());
}

#[test(should_fail_with = "error: contract is deactivated")]
unconstrained fn unpause_after_deactivate_throws() {
    let (env, token_contract_address, issuer, _) = utils::setup(/* with_account_contracts */ false);

    env.call_public(issuer, Token::at(token_contract_address).grant_role(PAUSE_ROLE, issuer));
    env.call_public(issuer, Token::at(token_contract_address).pause_contract());
    env.call_public(issuer, Token::at(token_contract_address).deactivate_contract());

    // This is what makes deactivation permanent.
    env.call_public(issuer, Token::at(token_contract_address).unpause_contract());
}

#[test(should_fail_with = "Error: token contract is deactivated")]
unconstrained fn mint_when_deactivated_fails() {
    let (env, token_contract_address, issuer, _) = utils::setup(/* with_account_contracts */ false);

    env.call_public(issuer, Token::at(token_contract_address).grant_role(PAUSE_ROLE, issuer));
    env.call_public(issuer, Token::at(token_contract_address).grant_role(MINTER_ROLE, issuer));
    env.call_public(issuer, Token::at(token_contract_address).pause_contract());
    env.call_public(issuer, Token::at(token_contract_address).deactivate_contract());

    // Mint survives a pause, so deactivation is checked explicitly in `_mint`.
    env.call_private(
        issuer,
        Token::at(token_contract_address).mint_to_private(issuer, 10000 as u128),
    );
}

#[test(should_fail_with = "Error: token contract is paused")]
unconstrained fn transfer_when_deactivated_fails() {
    let (env, token_contract_address, issuer, user1, _) =
        utils::setup_and_mint(/* with_account_contracts */ false);

    env.call_public(issuer, Token::at(token_contract_address).grant_role(PAUSE_ROLE, issuer));
    env.call_public(issuer, Token::at(token_contract_address).pause_contract());
    env.call_public(issuer, Token::at(token_contract_address).deactivate_contract());

    env.call_private(
        issuer,
        Token::at(token_contract_address).transfer_private_to_private(issuer, user1, 100 as u128, 0),
    );
}

#[test(should_fail_with = "Error: token contract is deactivated")]
unconstrained fn burn_when_deactivated_fails() {
    let (env, token_contract_address, issuer, _, _) =
        utils::setup_and_mint(/* with_account_contracts */ false);

    env.call_public(issuer, Token::at(token_contract_address).grant_role(PAUSE_ROLE, issuer));
    env.call_public(issuer, Token::at(token_contract_address).grant_role(BURNER_ROLE, issuer));
    env.call_public(issuer, Token::at(token_contract_address).pause_contract());
    env.call_public(issuer, Token::at(token_contract_address).deactivate_contract());

    env.call_private(issuer, Token::at(token_contract_address).burn(issuer, 100 as u128, 0));
}
