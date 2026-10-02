use crate::utils;
use aztec::protocol::address::AztecAddress;
use aztec::protocol::traits::FromField;
use cmtat_aztec::CMTATAztec::CHANGE_ROLES_DELAY_SECONDS;
use cmtat_aztec::CMTATAztec as Token;

/// `issuer_address` is a DelayedPublicMutable, so a change is visible as scheduled at once and
/// becomes the current value only after the delay - on the public read and, what matters for the
/// audit copies, on the private read every mint, transfer and burn performs.
#[test]
unconstrained fn set_issuer_takes_effect_after_delay() {
    let (env, token, admin, new_issuer) = utils::setup(/* with_account_contracts */ false);

    env.call_public(admin, Token::at(token).set_issuer(new_issuer));

    // Before the delay: both read paths still return the deployer.
    assert(env.view_public(Token::at(token).public_get_issuer()) == admin);
    assert(env.view_private(admin, Token::at(token).private_get_issuer()) == admin);

    utils::advance_past_delay(env, CHANGE_ROLES_DELAY_SECONDS);

    // After: both return the new issuer.
    assert(env.view_public(Token::at(token).public_get_issuer()) == new_issuer);
    assert(env.view_private(admin, Token::at(token).private_get_issuer()) == new_issuer);
}

/// A rotation must not break the value-moving paths: they read the issuer to address the audit
/// copy, and must keep working before, during and after the change.
#[test]
unconstrained fn transfers_keep_working_across_an_issuer_change() {
    let (mut env, token, admin, user1, mint_amount) =
        utils::setup_and_mint(/* with_account_contracts */ false);
    let new_issuer = env.create_light_account();

    env.call_public(admin, Token::at(token).set_issuer(new_issuer));

    // During the delay the old issuer is still current; the transfer must succeed.
    env.call_private(
        admin,
        Token::at(token).transfer_private_to_private(admin, user1, 100 as u128, 0),
    );

    utils::advance_past_delay(env, CHANGE_ROLES_DELAY_SECONDS);

    // After the delay the new issuer is current; the transfer must still succeed.
    env.call_private(
        admin,
        Token::at(token).transfer_private_to_private(admin, user1, 100 as u128, 0),
    );

    utils::check_private_balance(env, token, admin, mint_amount - 200 as u128);
    utils::check_private_balance(env, token, user1, 200 as u128);
}

#[test(should_fail_with = "AccessControlUnauthorizedAccount")]
unconstrained fn set_issuer_by_non_admin_fails() {
    let (env, token, _, user1) = utils::setup(/* with_account_contracts */ false);

    env.call_public(user1, Token::at(token).set_issuer(user1));
}

#[test(should_fail_with = "invalid issuer")]
unconstrained fn set_issuer_to_zero_fails() {
    let (env, token, admin, _) = utils::setup(/* with_account_contracts */ false);

    env.call_public(admin, Token::at(token).set_issuer(AztecAddress::from_field(0)));
}
