//! The four AIP-20 private/public bridges, behind the `public_side_enabled` deployment flag.
use crate::utils;
use aztec::protocol::address::AztecAddress;
use aztec::protocol::traits::ToField;
use aztec::test::helpers::test_environment::TestEnvironment;
use cmtat_aztec::CMTATAztec as Token;
use cmtat_aztec_lib::modules::access_controlModule::{
    ADDRESS_LIST_ADD_ROLE, ENFORCEMENT_ROLE, MINTER_ROLE, PAUSE_ROLE,
};
use cmtat_aztec_lib::modules::enforcementModule::{CHANGE_ROLES_DELAY_SECONDS, FreezableFlag};
use cmtat_aztec_lib::modules::validationModule::{SetFlag, UserFlags};

global MINT: u128 = 10_000;

/// Token deployed with the public side ON, issuer minted MINT privately.
unconstrained fn setup_enabled() -> (TestEnvironment, AztecAddress, AztecAddress, AztecAddress) {
    let (env, token, issuer, user) =
        utils::setup_with_public_side(false, /* public_side_enabled */ true);
    env.call_public(issuer, Token::at(token).grant_role(MINTER_ROLE, issuer));
    env.call_private(issuer, Token::at(token).mint_to_private(issuer, MINT));
    (env, token, issuer, user)
}

// --- the flag ------------------------------------------------------------------------------------

#[test]
unconstrained fn flag_is_readable_and_off_by_default() {
    let (env, token, _, _) = utils::setup(false);
    assert(env.view_public(Token::at(token).public_get_public_side_enabled()) == 0);
    let (env, token, _, _) = utils::setup_with_public_side(false, true);
    assert(env.view_public(Token::at(token).public_get_public_side_enabled()) == 1);
}

#[test(should_fail_with = "Error: public side disabled at deploy")]
unconstrained fn private_to_public_reverts_when_disabled() {
    let (env, token, issuer, user, _) = utils::setup_and_mint(false);
    env.call_private(issuer, Token::at(token).transfer_private_to_public(issuer, user, 100, 0));
}

#[test(should_fail_with = "Error: public side disabled at deploy")]
unconstrained fn public_to_private_reverts_when_disabled() {
    let (env, token, issuer, user, _) = utils::setup_and_mint(false);
    env.call_private(issuer, Token::at(token).transfer_public_to_private(issuer, user, 100, 0));
}

#[test(should_fail_with = "Error: public side disabled at deploy")]
unconstrained fn initialize_commitment_reverts_when_disabled() {
    let (env, token, issuer, user, _) = utils::setup_and_mint(false);
    let _ = env.call_private(user, Token::at(token).initialize_transfer_commitment(user, issuer));
}

// --- private -> public ---------------------------------------------------------------------------

#[test]
unconstrained fn private_to_public_credits_the_public_balance() {
    let (env, token, issuer, user) = setup_enabled();
    env.call_private(issuer, Token::at(token).transfer_private_to_public(issuer, user, 1_000, 0));
    utils::check_private_balance(env, token, issuer, MINT - 1_000);
    assert_eq(env.view_public(Token::at(token).balance_of_public(user)), 1_000);
    assert_eq(env.view_public(Token::at(token).total_supply()), MINT);
}

#[test(should_fail_with = "Error: token contract is paused")]
unconstrained fn private_to_public_reverts_when_paused() {
    let (env, token, issuer, user) = setup_enabled();
    env.call_public(issuer, Token::at(token).grant_role(PAUSE_ROLE, issuer));
    env.call_public(issuer, Token::at(token).pause_contract());
    env.call_private(issuer, Token::at(token).transfer_private_to_public(issuer, user, 1_000, 0));
}

#[test(should_fail_with = "Frozen: Recipient")]
unconstrained fn private_to_public_reverts_for_frozen_recipient() {
    let (env, token, issuer, user) = setup_enabled();
    env.call_public(issuer, Token::at(token).grant_role(ENFORCEMENT_ROLE, issuer));
    env.call_public(issuer, Token::at(token).freeze(user, FreezableFlag { is_freezed: true }));
    utils::advance_past_delay(env, CHANGE_ROLES_DELAY_SECONDS);
    env.call_private(issuer, Token::at(token).transfer_private_to_public(issuer, user, 1_000, 0));
}

#[test(should_fail_with = "The recipient is in the blacklist")]
unconstrained fn private_to_public_reverts_for_blacklisted_recipient() {
    let (env, token, issuer, user) = setup_enabled();
    env.call_public(issuer, Token::at(token).grant_role(ADDRESS_LIST_ADD_ROLE, issuer));
    env.call_public(
        issuer,
        Token::at(token).set_operations(
            SetFlag { operate_blacklist: true, operate_whitelist: false },
        ),
    );
    env.call_public(
        issuer,
        Token::at(token).add_to_list(
            user,
            UserFlags { is_blacklisted: true, is_whitelisted: false },
        ),
    );
    utils::advance_past_delay(env, CHANGE_ROLES_DELAY_SECONDS);
    env.call_private(issuer, Token::at(token).transfer_private_to_public(issuer, user, 1_000, 0));
}

// --- public -> private ---------------------------------------------------------------------------

#[test]
unconstrained fn public_to_private_round_trip() {
    let (env, token, issuer, user) = setup_enabled();
    env.call_private(issuer, Token::at(token).transfer_private_to_public(issuer, user, 1_000, 0));
    env.call_private(user, Token::at(token).transfer_public_to_private(user, user, 400, 0));
    assert_eq(env.view_public(Token::at(token).balance_of_public(user)), 600);
    utils::check_private_balance(env, token, user, 400);
    assert_eq(env.view_public(Token::at(token).total_supply()), MINT);
}

#[test(should_fail_with = "Error: public balance too low")]
unconstrained fn public_to_private_reverts_on_overdraft() {
    let (env, token, issuer, user) = setup_enabled();
    env.call_private(issuer, Token::at(token).transfer_private_to_public(issuer, user, 1_000, 0));
    env.call_private(user, Token::at(token).transfer_public_to_private(user, user, 1_001, 0));
}

#[test(should_fail_with = "Frozen: Sender")]
unconstrained fn public_to_private_reverts_for_frozen_sender() {
    let (env, token, issuer, user) = setup_enabled();
    env.call_private(issuer, Token::at(token).transfer_private_to_public(issuer, user, 1_000, 0));
    env.call_public(issuer, Token::at(token).grant_role(ENFORCEMENT_ROLE, issuer));
    env.call_public(issuer, Token::at(token).freeze(user, FreezableFlag { is_freezed: true }));
    utils::advance_past_delay(env, CHANGE_ROLES_DELAY_SECONDS);
    env.call_private(user, Token::at(token).transfer_public_to_private(user, issuer, 100, 0));
}

// --- commitments ---------------------------------------------------------------------------------

#[test]
unconstrained fn recipient_opens_a_commitment_and_the_sender_completes_it() {
    let (env, token, issuer, user) = setup_enabled();
    // `user` opens a commitment that only `issuer` may complete, hands the field to the issuer.
    let commitment =
        env.call_private(user, Token::at(token).initialize_transfer_commitment(user, issuer));
    env.mine_block();
    env.call_private(
        issuer,
        Token::at(token).transfer_private_to_commitment(issuer, commitment, 700, 0),
    );
    utils::check_private_balance(env, token, issuer, MINT - 700);
    utils::check_private_balance(env, token, user, 700);
}

#[test(should_fail_with = "Frozen: Recipient")]
unconstrained fn frozen_recipient_cannot_open_a_commitment() {
    let (env, token, issuer, user) = setup_enabled();
    env.call_public(issuer, Token::at(token).grant_role(ENFORCEMENT_ROLE, issuer));
    env.call_public(issuer, Token::at(token).freeze(user, FreezableFlag { is_freezed: true }));
    utils::advance_past_delay(env, CHANGE_ROLES_DELAY_SECONDS);
    let _ = env.call_private(user, Token::at(token).initialize_transfer_commitment(user, issuer));
}

#[test(should_fail_with = "The recipient is not in the whitelist")]
unconstrained fn unlisted_recipient_cannot_open_a_commitment_under_whitelist() {
    let (env, token, issuer, user) = setup_enabled();
    env.call_public(
        issuer,
        Token::at(token).set_operations(
            SetFlag { operate_blacklist: false, operate_whitelist: true },
        ),
    );
    utils::advance_past_delay(env, CHANGE_ROLES_DELAY_SECONDS);
    let _ = env.call_private(user, Token::at(token).initialize_transfer_commitment(user, issuer));
}

#[test(should_fail_with = "Error: token contract is paused")]
unconstrained fn completing_a_commitment_reverts_when_paused() {
    let (env, token, issuer, user) = setup_enabled();
    let commitment =
        env.call_private(user, Token::at(token).initialize_transfer_commitment(user, issuer));
    env.mine_block();
    env.call_public(issuer, Token::at(token).grant_role(PAUSE_ROLE, issuer));
    env.call_public(issuer, Token::at(token).pause_contract());
    env.call_private(
        issuer,
        Token::at(token).transfer_private_to_commitment(issuer, commitment, 700, 0),
    );
}

#[test]
unconstrained fn private_to_public_with_commitment_returns_a_completable_commitment() {
    let (env, token, issuer, user) = setup_enabled();
    // Sender pays `user` publicly and keeps a commitment for `user` that the sender may complete later.
    let commitment = env.call_private(
        issuer,
        Token::at(token).transfer_private_to_public_with_commitment(issuer, user, 1_000, 0),
    );
    env.mine_block();
    assert_eq(env.view_public(Token::at(token).balance_of_public(user)), 1_000);
    env.call_private(
        issuer,
        Token::at(token).transfer_private_to_commitment(issuer, commitment, 300, 0),
    );
    utils::check_private_balance(env, token, user, 300);
    utils::check_private_balance(env, token, issuer, MINT - 1_300);
}

/// The selectors are AIP-20's (read from the fork's `Token::interface()` at 5433e9c): the bridges are
/// addressable by tooling written for the standard.
#[test]
unconstrained fn bridge_selectors_match_aip20() {
    let (_, token, issuer, user) = utils::setup(false);
    assert_eq(
        Token::at(token).transfer_private_to_public(issuer, user, 1, 0).selector.to_field(),
        0xaf28c76f,
    );
    assert_eq(
        Token::at(token).transfer_public_to_private(issuer, user, 1, 0).selector.to_field(),
        0x32c5dcf8,
    );
    assert_eq(
        Token::at(token).transfer_private_to_commitment(issuer, 1, 1, 0).selector.to_field(),
        0x638d3f00,
    );
    assert_eq(
        Token::at(token)
            .transfer_private_to_public_with_commitment(issuer, user, 1, 0)
            .selector
            .to_field(),
        0x398c27b4,
    );
    assert_eq(
        Token::at(token).initialize_transfer_commitment(user, issuer).selector.to_field(),
        0xa116fff5,
    );
    assert_eq(Token::at(token).balance_of_public(user).selector.to_field(), 0xff7949f2);
}
