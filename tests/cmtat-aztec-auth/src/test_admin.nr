use crate::utils::{self, SOME_TRANSFER_SELECTOR};
use cmtat_aztec_auth::CMTATAztecAuth as Auth;
use cmtat_aztec_lib::modules::access_controlModule::{DEFAULT_ADMIN_ROLE, PAUSE_ROLE};
use compressed_string::FieldCompressedString;

#[test]
unconstrained fn constructor_grants_the_admin_role() {
    let (env, auth, admin, user) = utils::setup();
    assert(env.view_public(Auth::at(auth).has_role(DEFAULT_ADMIN_ROLE, admin)) == 1);
    assert(env.view_public(Auth::at(auth).has_role(DEFAULT_ADMIN_ROLE, user)) == 0);
}

#[test(should_fail_with = "AccessControlUnauthorizedAccount")]
unconstrained fn non_admin_cannot_grant_roles() {
    let (env, auth, _, user) = utils::setup();
    env.call_public(user, Auth::at(auth).grant_role(PAUSE_ROLE, user));
}

#[test(should_fail_with = "AccessControlUnauthorizedAccount")]
unconstrained fn pause_requires_the_pause_role() {
    let (env, auth, admin, _) = utils::setup();
    env.call_public(admin, Auth::at(auth).pause_contract());
}

#[test]
unconstrained fn pause_and_deactivation_flags_are_readable() {
    let (env, auth, admin, _) = utils::setup();
    assert(env.view_public(Auth::at(auth).public_get_pause()) == 0);
    assert(env.view_public(Auth::at(auth).public_get_deactivated()) == 0);
    utils::deactivate(env, auth, admin);
    assert(env.view_public(Auth::at(auth).public_get_pause()) == 1);
    assert(env.view_public(Auth::at(auth).public_get_deactivated()) == 1);
}

/// The version is the CMTAT token contracts' `VERSION` for now; see the constant's comment.
#[test]
unconstrained fn version_matches_the_constant() {
    let (env, auth, _, _) = utils::setup();
    let result = env.view_public(Auth::at(auth).version());
    assert(result == FieldCompressedString::from_string(cmtat_aztec_auth::CMTATAztecAuth::VERSION));
    assert(result == FieldCompressedString::from_string("0.4.0                          "));
}

// --- delay setting (H-6) ------------------------------------------------------------------------

/// The delay is one hour initially, readable, adjustable by the admin and bounded by the protocol's
/// transaction lifetime. The library makes a longer delay effective at once: a freeze scheduled right
/// after the increase is not current after the old hour, and is after two.
#[test]
unconstrained fn the_roles_delay_is_one_hour_and_a_longer_one_applies_to_the_next_freeze() {
    let (env, auth, admin, user) = utils::setup();
    assert_eq(env.view_public(Auth::at(auth).roles_delay()), 3600);
    env.call_public(admin, Auth::at(auth).set_roles_delay(7200));
    assert_eq(env.view_public(Auth::at(auth).roles_delay()), 7200);
    utils::freeze(env, auth, admin, user, /* wait */ false);
    utils::advance_past_delay(env, 3600);
    env.call_private(user, Auth::at(auth).authorize_private(user, 10, SOME_TRANSFER_SELECTOR)); // still allowed
}

#[test(should_fail_with = "AccessControlUnauthorizedAccount")]
unconstrained fn set_roles_delay_requires_the_admin_role() {
    let (env, auth, _, user) = utils::setup();
    env.call_public(user, Auth::at(auth).set_roles_delay(7200));
}

#[test(should_fail_with = "delay above the transaction lifetime")]
unconstrained fn set_roles_delay_is_bounded() {
    let (env, auth, admin, _) = utils::setup();
    env.call_public(admin, Auth::at(auth).set_roles_delay(86401));
}
