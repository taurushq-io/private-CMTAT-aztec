//! H-6: the delay of the delayed values is one hour initially and adjustable at runtime with
//! `set_roles_delay`. The library makes an increase immediate and a decrease effective only after the
//! difference, so nothing scheduled under the old delay can land earlier than it promised; a `Map`
//! entry carries its own delay and adopts the setting when it is next written.
use crate::utils;
use cmtat_aztec::CMTATAztec::{CHANGE_ROLES_DELAY_SECONDS, MAX_ROLES_DELAY_SECONDS};
use cmtat_aztec::CMTATAztec as Token;
use cmtat_aztec_lib::modules::access_controlModule::ENFORCEMENT_ROLE;
use cmtat_aztec_lib::modules::enforcementModule::FreezableFlag;

#[test]
unconstrained fn the_initial_delay_is_one_hour_and_readable() {
    let (env, token, _, _) = utils::setup(false);
    assert_eq(CHANGE_ROLES_DELAY_SECONDS, 3600);
    assert_eq(env.view_public(Token::at(token).roles_delay()), 3600);
}

/// An increase governs the issuer address at once: a rotation scheduled right after it is not current
/// after the old delay, and is after the new one.
#[test]
unconstrained fn a_longer_delay_applies_at_once_to_the_issuer() {
    let (mut env, token, issuer, _) = utils::setup(false);
    let next = env.create_light_account();
    env.call_public(issuer, Token::at(token).set_roles_delay(7200));
    env.call_public(issuer, Token::at(token).set_issuer(next));
    utils::advance_past_delay(env, 3600);
    assert_eq(
        env.view_public(Token::at(token).public_get_issuer()),
        issuer,
        "old delay must not suffice",
    );
    utils::advance_past_delay(env, 3600);
    assert_eq(env.view_public(Token::at(token).public_get_issuer()), next);
}

/// A freeze written after the setting changed adopts the new delay for that address.
#[test]
unconstrained fn a_freeze_adopts_the_current_setting() {
    let (env, token, issuer, user) = utils::setup(false);
    env.call_public(issuer, Token::at(token).grant_role(ENFORCEMENT_ROLE, issuer));
    env.call_public(issuer, Token::at(token).set_roles_delay(7200));
    env.call_public(issuer, Token::at(token).freeze(user, FreezableFlag { is_freezed: true }));
    utils::advance_past_delay(env, 3600);
    assert_eq(
        env.view_public(Token::at(token).get_frozen(user)),
        0,
        "not frozen after the old delay",
    );
    utils::advance_past_delay(env, 3600);
    assert_eq(env.view_public(Token::at(token).get_frozen(user)), 1);
}

/// A shorter delay is not immediate: it takes effect after the difference, so a freeze scheduled right
/// after the decrease still waits the previous hour.
#[test]
unconstrained fn a_shorter_delay_takes_effect_after_the_difference() {
    let (env, token, issuer, user) = utils::setup(false);
    env.call_public(issuer, Token::at(token).grant_role(ENFORCEMENT_ROLE, issuer));
    env.call_public(issuer, Token::at(token).set_roles_delay(600));
    env.call_public(issuer, Token::at(token).freeze(user, FreezableFlag { is_freezed: true }));
    utils::advance_past_delay(env, 600);
    assert_eq(
        env.view_public(Token::at(token).get_frozen(user)),
        0,
        "the previous hour still governs",
    );
    utils::advance_past_delay(env, 3000);
    assert_eq(env.view_public(Token::at(token).get_frozen(user)), 1);
}

/// Once the shorter delay is current for an entry, the next write on it uses the shorter delay.
#[test]
unconstrained fn once_current_the_shorter_delay_governs_the_next_write() {
    let (env, token, issuer, user) = utils::setup(false);
    env.call_public(issuer, Token::at(token).grant_role(ENFORCEMENT_ROLE, issuer));
    env.call_public(issuer, Token::at(token).set_roles_delay(600));
    env.call_public(issuer, Token::at(token).freeze(user, FreezableFlag { is_freezed: true }));
    utils::advance_past_delay(env, 3600);
    env.call_public(issuer, Token::at(token).unfreeze(user, FreezableFlag { is_freezed: false }));
    utils::advance_past_delay(env, 600);
    assert_eq(
        env.view_public(Token::at(token).get_frozen(user)),
        0,
        "unfrozen after the new 600 s delay",
    );
}

#[test(should_fail_with = "AccessControlUnauthorizedAccount")]
unconstrained fn set_roles_delay_requires_the_admin_role() {
    let (env, token, _, user) = utils::setup(false);
    env.call_public(user, Token::at(token).set_roles_delay(7200));
}

#[test(should_fail_with = "delay above the transaction lifetime")]
unconstrained fn set_roles_delay_is_bounded_by_the_transaction_lifetime() {
    let (env, token, issuer, _) = utils::setup(false);
    env.call_public(issuer, Token::at(token).set_roles_delay(MAX_ROLES_DELAY_SECONDS + 1));
}

#[test(should_fail_with = "invalid delay")]
unconstrained fn set_roles_delay_refuses_zero() {
    let (env, token, issuer, _) = utils::setup(false);
    env.call_public(issuer, Token::at(token).set_roles_delay(0));
}
