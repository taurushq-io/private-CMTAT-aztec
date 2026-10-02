use crate::utils;
use cmtat_aztec::CMTATAztec as Token;
use cmtat_aztec_lib::modules::access_controlModule::ENFORCEMENT_ROLE;
use cmtat_aztec_lib::modules::enforcementModule::{CHANGE_ROLES_DELAY_SECONDS, FreezableFlag};

#[test]
unconstrained fn get_frozen() {
    let (env, token_contract_address, issuer, _) = utils::setup(/* with_account_contracts */ false);

    let ret = env.view_public(Token::at(token_contract_address).get_frozen(issuer));
    assert(ret == 0);
}

#[test]
unconstrained fn can_freeze() {
    let (env, token_contract_address, issuer, user) =
        utils::setup(/* with_account_contracts */ false);

    env.call_public(issuer, Token::at(token_contract_address).grant_role(ENFORCEMENT_ROLE, issuer));

    let freezable_flag = FreezableFlag { is_freezed: true };
    env.call_public(issuer, Token::at(token_contract_address).freeze(user, freezable_flag));
    utils::advance_past_delay(env, CHANGE_ROLES_DELAY_SECONDS);

    let ret = env.view_public(Token::at(token_contract_address).get_frozen(user));
    assert(ret == 1);
}

#[test]
unconstrained fn can_unfreeze() {
    let (env, token_contract_address, issuer, user) =
        utils::setup(/* with_account_contracts */ false);

    env.call_public(issuer, Token::at(token_contract_address).grant_role(ENFORCEMENT_ROLE, issuer));

    let freezable_flag = FreezableFlag { is_freezed: true };
    env.call_public(issuer, Token::at(token_contract_address).freeze(user, freezable_flag));
    utils::advance_past_delay(env, CHANGE_ROLES_DELAY_SECONDS);

    let ret = env.view_public(Token::at(token_contract_address).get_frozen(user));
    assert(ret == 1);

    let unfreezable_flag = FreezableFlag { is_freezed: false };
    env.call_public(issuer, Token::at(token_contract_address).unfreeze(user, unfreezable_flag));
    utils::advance_past_delay(env, CHANGE_ROLES_DELAY_SECONDS);

    let ret = env.view_public(Token::at(token_contract_address).get_frozen(user));
    assert(ret == 0);
}

#[test(should_fail_with = "Frozen: Recipient")]
unconstrained fn mint_restricted_when_freezed() {
    let (env, token_contract_address, issuer, user) =
        utils::setup(/* with_account_contracts */ false);

    env.call_public(issuer, Token::at(token_contract_address).grant_role(ENFORCEMENT_ROLE, issuer));

    let freezable_flag = FreezableFlag { is_freezed: true };
    env.call_public(issuer, Token::at(token_contract_address).freeze(user, freezable_flag));
    utils::advance_past_delay(env, CHANGE_ROLES_DELAY_SECONDS);

    let ret = env.view_public(Token::at(token_contract_address).get_frozen(user));
    assert(ret == 1);

    let mint_amount = 10000 as u128;
    env.call_private(issuer, Token::at(token_contract_address).mint_to_private(user, mint_amount));
}

#[test(should_fail_with = "Frozen: Recipient")]
unconstrained fn transfer_restricted_when_freezed() {
    let (env, token_contract_address, issuer, user, _) =
        utils::setup_and_mint(/* with_account_contracts */ false);

    env.call_public(issuer, Token::at(token_contract_address).grant_role(ENFORCEMENT_ROLE, issuer));

    let freezable_flag = FreezableFlag { is_freezed: true };
    env.call_public(issuer, Token::at(token_contract_address).freeze(user, freezable_flag));
    utils::advance_past_delay(env, CHANGE_ROLES_DELAY_SECONDS);

    let ret = env.view_public(Token::at(token_contract_address).get_frozen(user));
    assert(ret == 1);

    let transfer_amount = 10000 as u128;
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

#[test(should_fail_with = "Frozen: Sender")]
unconstrained fn burn_restricted_when_freezed() {
    let (env, token_contract_address, issuer, user, _) =
        utils::setup_and_mint(/* with_account_contracts */ false);

    env.call_public(issuer, Token::at(token_contract_address).grant_role(ENFORCEMENT_ROLE, issuer));

    let transfer_amount = 10000 as u128;
    env.call_private(
        issuer,
        Token::at(token_contract_address).transfer_private_to_private(
            issuer,
            user,
            transfer_amount,
            0,
        ),
    );

    let freezable_flag = FreezableFlag { is_freezed: true };
    env.call_public(issuer, Token::at(token_contract_address).freeze(user, freezable_flag));
    utils::advance_past_delay(env, CHANGE_ROLES_DELAY_SECONDS);

    let ret = env.view_public(Token::at(token_contract_address).get_frozen(user));
    assert(ret == 1);

    let burn_amount = 10000 as u128;
    env.call_private(user, Token::at(token_contract_address).burn(user, burn_amount, 0));
}

/// `burn_batch` reaches the freeze check through `_burn_internal` alone, where `burn` checks it
/// itself first. Both must name the same party: the address being debited is the sender.
#[test(should_fail_with = "Frozen: Sender")]
unconstrained fn burn_batch_restricted_when_freezed() {
    let (env, token_contract_address, issuer, user, _) =
        utils::setup_and_mint(/* with_account_contracts */ false);

    env.call_public(issuer, Token::at(token_contract_address).grant_role(ENFORCEMENT_ROLE, issuer));

    let transfer_amount = 10000 as u128;
    env.call_private(
        issuer,
        Token::at(token_contract_address).transfer_private_to_private(
            issuer,
            user,
            transfer_amount,
            0,
        ),
    );

    let freezable_flag = FreezableFlag { is_freezed: true };
    env.call_public(issuer, Token::at(token_contract_address).freeze(user, freezable_flag));
    utils::advance_past_delay(env, CHANGE_ROLES_DELAY_SECONDS);

    let burn_amount = [10000 as u128, 0 as u128, 0 as u128, 0 as u128];
    env.call_private(user, Token::at(token_contract_address).burn_batch(user, burn_amount, 0));
}
