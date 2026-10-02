use crate::utils::{self, SOME_TRANSFER_SELECTOR};
use cmtat_aztec_auth::CMTATAztecAuth as Auth;
use cmtat_aztec_lib::modules::access_controlModule::ENFORCEMENT_ROLE;
use cmtat_aztec_lib::modules::authorizationHookModule::{
    AIP20_BURN_PRIVATE_SELECTOR, AIP20_BURN_PUBLIC_SELECTOR, ARC1155_BURN_PRIVATE_SELECTOR,
    ARC1155_BURN_PUBLIC_SELECTOR,
};
use cmtat_aztec_lib::modules::enforcementModule::{CHANGE_ROLES_DELAY_SECONDS, FreezableFlag};

// --- selectors ----------------------------------------------------------------------------------

/// Pins the selectors to the values the reference contracts in `submodules/aztec-standards` expose
/// through `Token::interface()` / `MultiToken::interface()` at commit 5433e9c. A change here means
/// the fork renamed or re-typed a burn entry point and the hook would misclassify it as a transfer.
#[test]
unconstrained fn burn_selectors_match_the_reference_contracts() {
    // Values read from `Token::at(..).burn_private(..).selector` / `MultiToken::at(..)` in a test
    // compiled against the fork (see doc/auth/README.md, "How it was verified").
    assert_eq(AIP20_BURN_PRIVATE_SELECTOR, 0xc282ed79);
    assert_eq(AIP20_BURN_PUBLIC_SELECTOR, 0xc611b0c5);
    assert_eq(ARC1155_BURN_PRIVATE_SELECTOR, 0x3198d2a7);
    assert_eq(ARC1155_BURN_PUBLIC_SELECTOR, 0x1d8b2815);
}

// --- default state ------------------------------------------------------------------------------

#[test]
unconstrained fn transfer_and_burn_pass_by_default() {
    let (env, auth, _, user) = utils::setup();
    env.call_private(user, Auth::at(auth).authorize_private(user, 10, SOME_TRANSFER_SELECTOR));
    env.call_private(user, Auth::at(auth).authorize_private(user, 10, AIP20_BURN_PRIVATE_SELECTOR));
    env.call_public(user, Auth::at(auth).authorize_public(user, 10, SOME_TRANSFER_SELECTOR));
    env.call_public(user, Auth::at(auth).authorize_public(user, 10, AIP20_BURN_PUBLIC_SELECTOR));
}

// --- pause: stops transfers, not burns ----------------------------------------------------------

#[test(should_fail_with = "Error: contract is paused")]
unconstrained fn private_transfer_reverts_when_paused() {
    let (env, auth, admin, user) = utils::setup();
    utils::pause(env, auth, admin);
    env.call_private(user, Auth::at(auth).authorize_private(user, 10, SOME_TRANSFER_SELECTOR));
}

#[test(should_fail_with = "Error: contract is paused")]
unconstrained fn public_transfer_reverts_when_paused() {
    let (env, auth, admin, user) = utils::setup();
    utils::pause(env, auth, admin);
    env.call_public(user, Auth::at(auth).authorize_public(user, 10, SOME_TRANSFER_SELECTOR));
}

/// As in CMTAT Solidity, a pause does not stop redemption: `_canMintBurnByModule` checks
/// deactivation and freeze, not `paused()`.
#[test]
unconstrained fn burn_passes_when_paused() {
    let (env, auth, admin, user) = utils::setup();
    utils::pause(env, auth, admin);
    env.call_private(user, Auth::at(auth).authorize_private(user, 10, AIP20_BURN_PRIVATE_SELECTOR));
    env.call_public(user, Auth::at(auth).authorize_public(user, 10, AIP20_BURN_PUBLIC_SELECTOR));
}

#[test]
unconstrained fn transfer_passes_again_after_unpause() {
    let (env, auth, admin, user) = utils::setup();
    utils::pause(env, auth, admin);
    env.call_public(admin, Auth::at(auth).unpause_contract());
    env.call_private(user, Auth::at(auth).authorize_private(user, 10, SOME_TRANSFER_SELECTOR));
}

// --- deactivation: stops everything, forever ----------------------------------------------------

#[test(should_fail_with = "Error: contract is deactivated")]
unconstrained fn private_burn_reverts_when_deactivated() {
    let (env, auth, admin, user) = utils::setup();
    utils::deactivate(env, auth, admin);
    env.call_private(user, Auth::at(auth).authorize_private(user, 10, AIP20_BURN_PRIVATE_SELECTOR));
}

#[test(should_fail_with = "Error: contract is deactivated")]
unconstrained fn public_burn_reverts_when_deactivated() {
    let (env, auth, admin, user) = utils::setup();
    utils::deactivate(env, auth, admin);
    env.call_public(user, Auth::at(auth).authorize_public(user, 10, AIP20_BURN_PUBLIC_SELECTOR));
}

/// A deactivated contract is a paused one that can never be unpaused, so transfers fail on the
/// pause check - the same shortcut CMTAT Solidity takes.
#[test(should_fail_with = "Error: contract is paused")]
unconstrained fn transfer_reverts_when_deactivated() {
    let (env, auth, admin, user) = utils::setup();
    utils::deactivate(env, auth, admin);
    env.call_private(user, Auth::at(auth).authorize_private(user, 10, SOME_TRANSFER_SELECTOR));
}

#[test(should_fail_with = "error: contract is deactivated")]
unconstrained fn unpause_reverts_when_deactivated() {
    let (env, auth, admin, _) = utils::setup();
    utils::deactivate(env, auth, admin);
    env.call_public(admin, Auth::at(auth).unpause_contract());
}

// --- freeze: stops the frozen `from`, after the delay ------------------------------------------

#[test(should_fail_with = "Frozen: from address")]
unconstrained fn private_transfer_reverts_for_frozen_from() {
    let (env, auth, admin, user) = utils::setup();
    utils::freeze(env, auth, admin, user, /* wait */ true);
    env.call_private(user, Auth::at(auth).authorize_private(user, 10, SOME_TRANSFER_SELECTOR));
}

#[test(should_fail_with = "Frozen: from address")]
unconstrained fn private_burn_reverts_for_frozen_from() {
    let (env, auth, admin, user) = utils::setup();
    utils::freeze(env, auth, admin, user, /* wait */ true);
    env.call_private(user, Auth::at(auth).authorize_private(user, 10, AIP20_BURN_PRIVATE_SELECTOR));
}

#[test(should_fail_with = "Frozen: from address")]
unconstrained fn public_transfer_reverts_for_frozen_from() {
    let (env, auth, admin, user) = utils::setup();
    utils::freeze(env, auth, admin, user, /* wait */ true);
    env.call_public(user, Auth::at(auth).authorize_public(user, 10, SOME_TRANSFER_SELECTOR));
}

/// The freeze flag is a DelayedPublicMutable: scheduled at `freeze`, current only after the delay.
/// Until then the address can still send - the window documented in doc/auth/README.md.
#[test]
unconstrained fn freeze_is_not_effective_before_the_delay() {
    let (env, auth, admin, user) = utils::setup();
    utils::freeze(env, auth, admin, user, /* wait */ false);
    env.call_private(user, Auth::at(auth).authorize_private(user, 10, SOME_TRANSFER_SELECTOR));
}

#[test]
unconstrained fn other_addresses_are_unaffected_by_a_freeze() {
    let (mut env, auth, admin, user) = utils::setup();
    utils::freeze(env, auth, admin, user, /* wait */ true);
    let other = env.create_light_account();
    env.call_private(other, Auth::at(auth).authorize_private(other, 10, SOME_TRANSFER_SELECTOR));
}

// --- unfreeze ------------------------------------------------------------------------------------

/// An unfreeze is scheduled like a freeze: the address stays blocked for one more delay, then sends.
#[test]
unconstrained fn an_unfrozen_address_sends_again_after_the_delay() {
    let (env, auth, admin, user) = utils::setup();
    utils::freeze(env, auth, admin, user, /* wait */ true);
    env.call_public(admin, Auth::at(auth).unfreeze(user, FreezableFlag { is_freezed: false }));
    utils::advance_past_delay(env, CHANGE_ROLES_DELAY_SECONDS);
    env.call_private(user, Auth::at(auth).authorize_private(user, 10, SOME_TRANSFER_SELECTOR));
}

#[test(should_fail_with = "Frozen: from address")]
unconstrained fn an_unfreeze_is_not_effective_before_the_delay() {
    let (env, auth, admin, user) = utils::setup();
    utils::freeze(env, auth, admin, user, /* wait */ true);
    env.call_public(admin, Auth::at(auth).unfreeze(user, FreezableFlag { is_freezed: false }));
    env.call_private(user, Auth::at(auth).authorize_private(user, 10, SOME_TRANSFER_SELECTOR));
}

#[test(should_fail_with = "error: address already unfreezed")]
unconstrained fn unfreezing_an_address_that_is_not_frozen_is_refused() {
    let (env, auth, admin, user) = utils::setup();
    env.call_public(admin, Auth::at(auth).grant_role(ENFORCEMENT_ROLE, admin));
    env.call_public(admin, Auth::at(auth).unfreeze(user, FreezableFlag { is_freezed: false }));
}
