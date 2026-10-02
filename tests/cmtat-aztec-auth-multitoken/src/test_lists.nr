use crate::utils::{self, SOME_ID, SOME_TRANSFER_SELECTOR};
use aztec::protocol::address::AztecAddress;
use aztec::test::helpers::test_environment::TestEnvironment;
use cmtat_aztec_auth_multitoken::CMTATAztecAuthMultiToken as Auth;
use cmtat_aztec_lib::modules::access_controlModule::{
    ADDRESS_LIST_ADD_ROLE, ADDRESS_LIST_REMOVE_ROLE, VALIDATION_ROLE,
};
use cmtat_aztec_lib::modules::authorizationHookModule::ARC1155_BURN_PRIVATE_SELECTOR;
use cmtat_aztec_lib::modules::validationModule::{CHANGE_ROLES_DELAY_SECONDS, SetFlag, UserFlags};

/// Enables one list mode and flags `user`; the admin holds VALIDATION_ROLE from the constructor.
unconstrained fn enable_and_list(
    env: TestEnvironment,
    auth: AztecAddress,
    admin: AztecAddress,
    user: AztecAddress,
    blacklist: bool,
    flags: UserFlags,
) {
    assert(env.view_public(Auth::at(auth).has_role(VALIDATION_ROLE, admin)) == 1);
    env.call_public(admin, Auth::at(auth).grant_role(ADDRESS_LIST_ADD_ROLE, admin));
    env.call_public(
        admin,
        Auth::at(auth).set_operations(
            SetFlag { operate_blacklist: blacklist, operate_whitelist: !blacklist },
        ),
    );
    env.call_public(admin, Auth::at(auth).add_to_list(user, flags));
    utils::advance_past_delay(env, CHANGE_ROLES_DELAY_SECONDS);
}

// --- blacklist -----------------------------------------------------------------------------------

#[test(should_fail_with = "The sender is in the blacklist")]
unconstrained fn blacklisted_sender_cannot_transfer_in_private() {
    let (env, auth, admin, user) = utils::setup();
    enable_and_list(
        env,
        auth,
        admin,
        user,
        true,
        UserFlags { is_blacklisted: true, is_whitelisted: false },
    );
    env.call_private(
        user,
        Auth::at(auth).authorize_private(user, SOME_ID, 10, SOME_TRANSFER_SELECTOR),
    );
}

#[test(should_fail_with = "The sender is in the blacklist")]
unconstrained fn blacklisted_sender_cannot_burn() {
    let (env, auth, admin, user) = utils::setup();
    enable_and_list(
        env,
        auth,
        admin,
        user,
        true,
        UserFlags { is_blacklisted: true, is_whitelisted: false },
    );
    env.call_private(
        user,
        Auth::at(auth).authorize_private(user, SOME_ID, 10, ARC1155_BURN_PRIVATE_SELECTOR),
    );
}

#[test(should_fail_with = "The sender is in the blacklist")]
unconstrained fn blacklisted_sender_cannot_transfer_in_public() {
    let (env, auth, admin, user) = utils::setup();
    enable_and_list(
        env,
        auth,
        admin,
        user,
        true,
        UserFlags { is_blacklisted: true, is_whitelisted: false },
    );
    env.call_public(user, Auth::at(auth).authorize_public(user, SOME_ID, 10, SOME_TRANSFER_SELECTOR));
}

#[test]
unconstrained fn unlisted_sender_passes_under_blacklist_mode() {
    let (mut env, auth, admin, user) = utils::setup();
    enable_and_list(
        env,
        auth,
        admin,
        user,
        true,
        UserFlags { is_blacklisted: true, is_whitelisted: false },
    );
    let other = env.create_light_account();
    env.call_private(
        other,
        Auth::at(auth).authorize_private(other, SOME_ID, 10, SOME_TRANSFER_SELECTOR),
    );
}

/// The one thing a sender-only list cannot do: the hook is not told `to`, so a blacklisted address
/// receiving is invisible to it. Recorded as a test so the limitation is explicit.
#[test]
unconstrained fn blacklisted_recipient_is_not_screened() {
    let (mut env, auth, admin, user) = utils::setup();
    enable_and_list(
        env,
        auth,
        admin,
        user,
        true,
        UserFlags { is_blacklisted: true, is_whitelisted: false },
    );
    let sender = env.create_light_account();
    // `user` would be the recipient of this transfer; the hook only ever sees `sender`.
    env.call_private(
        sender,
        Auth::at(auth).authorize_private(sender, SOME_ID, 10, SOME_TRANSFER_SELECTOR),
    );
}

// --- whitelist -----------------------------------------------------------------------------------

#[test(should_fail_with = "The sender is not in the whitelist")]
unconstrained fn unlisted_sender_cannot_transfer_under_whitelist_mode() {
    let (mut env, auth, admin, user) = utils::setup();
    enable_and_list(
        env,
        auth,
        admin,
        user,
        false,
        UserFlags { is_blacklisted: false, is_whitelisted: true },
    );
    let other = env.create_light_account();
    env.call_private(
        other,
        Auth::at(auth).authorize_private(other, SOME_ID, 10, SOME_TRANSFER_SELECTOR),
    );
}

#[test]
unconstrained fn whitelisted_sender_passes_under_whitelist_mode() {
    let (env, auth, admin, user) = utils::setup();
    enable_and_list(
        env,
        auth,
        admin,
        user,
        false,
        UserFlags { is_blacklisted: false, is_whitelisted: true },
    );
    env.call_private(
        user,
        Auth::at(auth).authorize_private(user, SOME_ID, 10, SOME_TRANSFER_SELECTOR),
    );
    env.call_public(user, Auth::at(auth).authorize_public(user, SOME_ID, 10, SOME_TRANSFER_SELECTOR));
}

// --- no mode enabled, and the delay ------------------------------------------------------------

#[test]
unconstrained fn lists_are_inert_until_a_mode_is_enabled() {
    let (env, auth, admin, user) = utils::setup();
    env.call_public(admin, Auth::at(auth).grant_role(ADDRESS_LIST_ADD_ROLE, admin));
    env.call_public(
        admin,
        Auth::at(auth).add_to_list(user, UserFlags { is_blacklisted: true, is_whitelisted: false }),
    );
    utils::advance_past_delay(env, CHANGE_ROLES_DELAY_SECONDS);
    env.call_private(
        user,
        Auth::at(auth).authorize_private(user, SOME_ID, 10, SOME_TRANSFER_SELECTOR),
    );
}

#[test]
unconstrained fn listing_is_not_effective_before_the_delay() {
    let (env, auth, admin, user) = utils::setup();
    env.call_public(admin, Auth::at(auth).grant_role(ADDRESS_LIST_ADD_ROLE, admin));
    env.call_public(
        admin,
        Auth::at(auth).set_operations(SetFlag { operate_blacklist: true, operate_whitelist: false }),
    );
    env.call_public(
        admin,
        Auth::at(auth).add_to_list(user, UserFlags { is_blacklisted: true, is_whitelisted: false }),
    );
    env.call_private(
        user,
        Auth::at(auth).authorize_private(user, SOME_ID, 10, SOME_TRANSFER_SELECTOR),
    );
}

// --- removal -------------------------------------------------------------------------------------

/// `remove_from_list` is itself a scheduled change: the address stays blocked until the delay has
/// elapsed again, then sends normally.
#[test]
unconstrained fn a_removed_sender_passes_again_after_the_delay() {
    let (env, auth, admin, user) = utils::setup();
    enable_and_list(
        env,
        auth,
        admin,
        user,
        true,
        UserFlags { is_blacklisted: true, is_whitelisted: false },
    );
    env.call_public(admin, Auth::at(auth).grant_role(ADDRESS_LIST_REMOVE_ROLE, admin));
    env.call_public(
        admin,
        Auth::at(auth).remove_from_list(
            user,
            UserFlags { is_blacklisted: false, is_whitelisted: false },
        ),
    );
    utils::advance_past_delay(env, CHANGE_ROLES_DELAY_SECONDS);
    env.call_private(
        user,
        Auth::at(auth).authorize_private(user, SOME_ID, 10, SOME_TRANSFER_SELECTOR),
    );
}

#[test(should_fail_with = "The sender is in the blacklist")]
unconstrained fn a_removal_is_not_effective_before_the_delay() {
    let (env, auth, admin, user) = utils::setup();
    enable_and_list(
        env,
        auth,
        admin,
        user,
        true,
        UserFlags { is_blacklisted: true, is_whitelisted: false },
    );
    env.call_public(admin, Auth::at(auth).grant_role(ADDRESS_LIST_REMOVE_ROLE, admin));
    env.call_public(
        admin,
        Auth::at(auth).remove_from_list(
            user,
            UserFlags { is_blacklisted: false, is_whitelisted: false },
        ),
    );
    env.call_private(
        user,
        Auth::at(auth).authorize_private(user, SOME_ID, 10, SOME_TRANSFER_SELECTOR),
    );
}

#[test(should_fail_with = "AccessControlUnauthorizedAccount")]
unconstrained fn remove_from_list_requires_the_remove_role() {
    let (env, auth, admin, user) = utils::setup();
    enable_and_list(
        env,
        auth,
        admin,
        user,
        true,
        UserFlags { is_blacklisted: true, is_whitelisted: false },
    );
    env.call_public(
        admin,
        Auth::at(auth).remove_from_list(
            user,
            UserFlags { is_blacklisted: false, is_whitelisted: false },
        ),
    );
}
