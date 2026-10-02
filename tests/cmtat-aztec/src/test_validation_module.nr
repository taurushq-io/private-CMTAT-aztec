use crate::utils;
use cmtat_aztec::CMTATAztec as Token;
use cmtat_aztec_lib::modules::access_controlModule::{
    ADDRESS_LIST_ADD_ROLE, ADDRESS_LIST_REMOVE_ROLE, BURNER_ROLE, MINTER_ROLE, VALIDATION_ROLE,
};
use cmtat_aztec_lib::modules::validationModule::{CHANGE_ROLES_DELAY_SECONDS, SetFlag, UserFlags};

#[test]
unconstrained fn get_operations_test() {
    let (env, token_contract_address, _, _) = utils::setup(/* with_account_contracts */ false);

    let ret = env.view_public(Token::at(token_contract_address).get_operations());
    assert(ret == 0);
}

#[test]
unconstrained fn set_operations_test() {
    let (env, token_contract_address, issuer, _) = utils::setup(/* with_account_contracts */ false);

    env.call_public(issuer, Token::at(token_contract_address).grant_role(VALIDATION_ROLE, issuer));

    let operations = SetFlag { operate_blacklist: true, operate_whitelist: false };
    env.call_public(issuer, Token::at(token_contract_address).set_operations(operations));
    utils::advance_past_delay(env, CHANGE_ROLES_DELAY_SECONDS);

    let ret = env.view_public(Token::at(token_contract_address).get_operations());
    assert(ret == 1);
}

#[test(should_fail_with = "The recipient is in the blacklist")]
unconstrained fn transfer_when_blacklisted() {
    let (env, token_contract_address, issuer, user, _) =
        utils::setup_and_mint(/* with_account_contracts */ false);

    env.call_public(issuer, Token::at(token_contract_address).grant_role(VALIDATION_ROLE, issuer));

    let operations = SetFlag { operate_blacklist: true, operate_whitelist: false };
    env.call_public(issuer, Token::at(token_contract_address).set_operations(operations));
    utils::advance_past_delay(env, CHANGE_ROLES_DELAY_SECONDS);

    let ret = env.view_public(Token::at(token_contract_address).get_operations());
    assert(ret == 1);

    env.call_public(
        issuer,
        Token::at(token_contract_address).grant_role(ADDRESS_LIST_ADD_ROLE, issuer),
    );

    let userFlag = UserFlags { is_blacklisted: true, is_whitelisted: false };
    env.call_public(issuer, Token::at(token_contract_address).add_to_list(user, userFlag));
    utils::advance_past_delay(env, CHANGE_ROLES_DELAY_SECONDS);

    let transfer_amount = 100 as u128;
    env.call_private(
        issuer,
        Token::at(token_contract_address).transfer_private_to_private(
            issuer,
            user,
            transfer_amount,
            0,
        ),
    );
}

#[test(should_fail_with = "The sender is not in the whitelist")]
unconstrained fn transfer_when_not_whitelisted() {
    let (env, token_contract_address, issuer, user, _) =
        utils::setup_and_mint(/* with_account_contracts */ false);

    env.call_public(issuer, Token::at(token_contract_address).grant_role(VALIDATION_ROLE, issuer));

    let operations = SetFlag { operate_blacklist: false, operate_whitelist: true };
    env.call_public(issuer, Token::at(token_contract_address).set_operations(operations));
    utils::advance_past_delay(env, CHANGE_ROLES_DELAY_SECONDS);

    let ret = env.view_public(Token::at(token_contract_address).get_operations());
    assert(ret == 2);

    let transfer_amount = 100 as u128;
    env.call_private(
        issuer,
        Token::at(token_contract_address).transfer_private_to_private(
            issuer,
            user,
            transfer_amount,
            0,
        ),
    );
}

#[test]
unconstrained fn transfer_when_whitelisted() {
    let (env, token_contract_address, issuer, user, mint_amount) =
        utils::setup_and_mint(/* with_account_contracts */ false);

    env.call_public(issuer, Token::at(token_contract_address).grant_role(VALIDATION_ROLE, issuer));
    env.call_public(
        issuer,
        Token::at(token_contract_address).grant_role(ADDRESS_LIST_ADD_ROLE, issuer),
    );

    let operations = SetFlag { operate_blacklist: false, operate_whitelist: true };
    env.call_public(issuer, Token::at(token_contract_address).set_operations(operations));
    utils::advance_past_delay(env, CHANGE_ROLES_DELAY_SECONDS);

    let ret = env.view_public(Token::at(token_contract_address).get_operations());
    assert(ret == 2);

    let userFlag = UserFlags { is_blacklisted: false, is_whitelisted: true };
    env.call_public(issuer, Token::at(token_contract_address).add_to_list(issuer, userFlag));
    env.call_public(issuer, Token::at(token_contract_address).add_to_list(user, userFlag));
    utils::advance_past_delay(env, CHANGE_ROLES_DELAY_SECONDS);

    let transfer_amount = 100 as u128;
    env.call_private(
        issuer,
        Token::at(token_contract_address).transfer_private_to_private(
            issuer,
            user,
            transfer_amount,
            0,
        ),
    );

    utils::check_private_balance(
        env,
        token_contract_address,
        issuer,
        mint_amount - transfer_amount,
    );
    utils::check_private_balance(env, token_contract_address, user, transfer_amount);
}

#[test]
unconstrained fn transfer_when_no_operations() {
    let (env, token_contract_address, issuer, user, _) =
        utils::setup_and_mint(/* with_account_contracts */ false);

    let ret = env.view_public(Token::at(token_contract_address).get_operations());
    assert(ret == 0);

    let transfer_amount = 100 as u128;
    env.call_private(
        issuer,
        Token::at(token_contract_address).transfer_private_to_private(
            issuer,
            user,
            transfer_amount,
            0,
        ),
    );
}

#[test(should_fail_with = "The recipient is not in the whitelist")]
unconstrained fn can_remove_from_list_when_role() {
    let (env, token_contract_address, issuer, user, _) =
        utils::setup_and_mint(/* with_account_contracts */ false);

    env.call_public(issuer, Token::at(token_contract_address).grant_role(VALIDATION_ROLE, issuer));

    let operations = SetFlag { operate_blacklist: false, operate_whitelist: true };
    env.call_public(issuer, Token::at(token_contract_address).set_operations(operations));
    utils::advance_past_delay(env, CHANGE_ROLES_DELAY_SECONDS);

    let ret = env.view_public(Token::at(token_contract_address).get_operations());
    assert(ret == 2);

    env.call_public(
        issuer,
        Token::at(token_contract_address).grant_role(ADDRESS_LIST_ADD_ROLE, issuer),
    );
    env.call_public(
        issuer,
        Token::at(token_contract_address).grant_role(ADDRESS_LIST_REMOVE_ROLE, issuer),
    );

    let whitelisted = UserFlags { is_blacklisted: false, is_whitelisted: true };
    env.call_public(issuer, Token::at(token_contract_address).add_to_list(issuer, whitelisted));
    env.call_public(issuer, Token::at(token_contract_address).add_to_list(user, whitelisted));
    utils::advance_past_delay(env, CHANGE_ROLES_DELAY_SECONDS);

    let cleared = UserFlags { is_blacklisted: false, is_whitelisted: false };
    env.call_public(issuer, Token::at(token_contract_address).remove_from_list(user, cleared));
    utils::advance_past_delay(env, CHANGE_ROLES_DELAY_SECONDS);

    let transfer_amount = 100 as u128;
    env.call_private(
        issuer,
        Token::at(token_contract_address).transfer_private_to_private(
            issuer,
            user,
            transfer_amount,
            0,
        ),
    );
}

/// Enables one list mode and lists `target` with the given flags, waiting out both delays.
unconstrained fn enable_and_list(
    env: aztec::test::helpers::test_environment::TestEnvironment,
    token: aztec::protocol::address::AztecAddress,
    issuer: aztec::protocol::address::AztecAddress,
    operations: SetFlag,
    target: aztec::protocol::address::AztecAddress,
    flags: UserFlags,
) {
    env.call_public(issuer, Token::at(token).grant_role(VALIDATION_ROLE, issuer));
    env.call_public(issuer, Token::at(token).grant_role(ADDRESS_LIST_ADD_ROLE, issuer));
    env.call_public(issuer, Token::at(token).set_operations(operations));
    env.call_public(issuer, Token::at(token).add_to_list(target, flags));
    utils::advance_past_delay(env, CHANGE_ROLES_DELAY_SECONDS);
}

// As in CMTAT Solidity (`ValidationModuleAllowlist._canMintBurnByModule`), the list applies to the
// target of a mint and of a burn - the recipient and the debited account respectively - not only to
// the two parties of a transfer.

#[test(should_fail_with = "The recipient is in the blacklist")]
unconstrained fn mint_to_blacklisted_fails() {
    let (env, token, issuer, user) = utils::setup(/* with_account_contracts */ false);
    env.call_public(issuer, Token::at(token).grant_role(MINTER_ROLE, issuer));
    enable_and_list(
        env,
        token,
        issuer,
        SetFlag { operate_blacklist: true, operate_whitelist: false },
        user,
        UserFlags { is_blacklisted: true, is_whitelisted: false },
    );

    env.call_private(issuer, Token::at(token).mint_to_private(user, 100 as u128));
}

#[test(should_fail_with = "The recipient is not in the whitelist")]
unconstrained fn mint_to_non_whitelisted_fails() {
    let (env, token, issuer, user) = utils::setup(/* with_account_contracts */ false);
    env.call_public(issuer, Token::at(token).grant_role(MINTER_ROLE, issuer));
    // Whitelist mode on; only the issuer is listed, so `user` may not receive.
    enable_and_list(
        env,
        token,
        issuer,
        SetFlag { operate_blacklist: false, operate_whitelist: true },
        issuer,
        UserFlags { is_blacklisted: false, is_whitelisted: true },
    );

    env.call_private(issuer, Token::at(token).mint_to_private(user, 100 as u128));
}

#[test(should_fail_with = "The sender is in the blacklist")]
unconstrained fn burn_from_blacklisted_fails() {
    let (env, token, issuer, _, _) = utils::setup_and_mint(/* with_account_contracts */ false);
    env.call_public(issuer, Token::at(token).grant_role(BURNER_ROLE, issuer));
    // The issuer already holds tokens; blacklisting it must stop its own redemption too.
    enable_and_list(
        env,
        token,
        issuer,
        SetFlag { operate_blacklist: true, operate_whitelist: false },
        issuer,
        UserFlags { is_blacklisted: true, is_whitelisted: false },
    );

    env.call_private(issuer, Token::at(token).burn(issuer, 100 as u128, 0));
}
