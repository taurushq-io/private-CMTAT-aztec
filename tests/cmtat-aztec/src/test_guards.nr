//! Negative tests for the guards that had none (0.4.0 review, K-2), plus the edge cases the review
//! listed as mechanical: a zero amount, a freeze before its delay, a listed commitment party, the
//! views nothing called. Each `should_fail_with` names the assert it is meant to reach, and the
//! setup grants every role the path needs before it, so no earlier check can fire first.
use crate::utils;
use aztec::test::helpers::test_environment::TestEnvironment;
use cmtat_aztec::CMTATAztec::CHANGE_ROLES_DELAY_SECONDS;
use cmtat_aztec::CMTATAztec as Token;
use cmtat_aztec_lib::modules::access_controlModule::{
    ADDRESS_LIST_ADD_ROLE, ENFORCEMENT_ROLE, MINTER_ROLE, PAUSE_ROLE,
};
use cmtat_aztec_lib::modules::enforcementModule::FreezableFlag;
use cmtat_aztec_lib::modules::validationModule::{SetFlag, UserFlags};
use compressed_string::FieldCompressedString;

// --- constructor ---------------------------------------------------------------------------------

#[test(should_fail_with = "invalid admin")]
unconstrained fn constructor_rejects_the_zero_admin() {
    let mut env = TestEnvironment::new();
    let deployer = env.create_light_account();
    let initializer = Token::interface().constructor(
        aztec::protocol::address::AztecAddress::zero(),
        "TestToken0000000000000000000000",
        "TT00000000000000000000000000000",
        18,
        false,
    );
    let _ = env.deploy("@cmtat_aztec/CMTATAztec").with_public_initializer(deployer, initializer);
}

// --- access control --------------------------------------------------------------------------------

#[test(should_fail_with = "Revoke Role: Cannot revoke role from self")]
unconstrained fn admin_cannot_revoke_its_own_role() {
    let (env, token, issuer, _) = utils::setup(false);
    env.call_public(issuer, Token::at(token).grant_role(PAUSE_ROLE, issuer));
    env.call_public(issuer, Token::at(token).revoke_role(PAUSE_ROLE, issuer));
}

#[test]
unconstrained fn admin_can_revoke_another_accounts_role() {
    let (env, token, issuer, user) = utils::setup(false);
    env.call_public(issuer, Token::at(token).grant_role(PAUSE_ROLE, user));
    assert(env.view_public(Token::at(token).has_role(PAUSE_ROLE, user)) == 1);
    env.call_public(issuer, Token::at(token).revoke_role(PAUSE_ROLE, user));
    assert(env.view_public(Token::at(token).has_role(PAUSE_ROLE, user)) == 0);
}

#[test(should_fail_with = "Renounce Role: Addresses do not match")]
unconstrained fn renounce_requires_the_callers_own_address_as_confirmation() {
    let (env, token, issuer, user) = utils::setup(false);
    env.call_public(issuer, Token::at(token).grant_role(PAUSE_ROLE, user));
    env.call_public(user, Token::at(token).renounce_role(PAUSE_ROLE, issuer));
}

#[test]
unconstrained fn renounce_with_the_right_confirmation_drops_the_role() {
    let (env, token, issuer, user) = utils::setup(false);
    env.call_public(issuer, Token::at(token).grant_role(PAUSE_ROLE, user));
    env.call_public(user, Token::at(token).renounce_role(PAUSE_ROLE, user));
    assert(env.view_public(Token::at(token).has_role(PAUSE_ROLE, user)) == 0);
}

// --- freeze guards and delay ----------------------------------------------------------------------

#[test(should_fail_with = "error: address already freezed")]
unconstrained fn freezing_twice_reverts() {
    let (env, token, issuer, user) = utils::setup(false);
    env.call_public(issuer, Token::at(token).grant_role(ENFORCEMENT_ROLE, issuer));
    env.call_public(issuer, Token::at(token).freeze(user, FreezableFlag { is_freezed: true }));
    utils::advance_past_delay(env, CHANGE_ROLES_DELAY_SECONDS);
    env.call_public(issuer, Token::at(token).freeze(user, FreezableFlag { is_freezed: true }));
}

#[test(should_fail_with = "error: address already unfreezed")]
unconstrained fn unfreezing_an_unfrozen_address_reverts() {
    let (env, token, issuer, user) = utils::setup(false);
    env.call_public(issuer, Token::at(token).grant_role(ENFORCEMENT_ROLE, issuer));
    env.call_public(issuer, Token::at(token).unfreeze(user, FreezableFlag { is_freezed: false }));
}

/// The freeze flag is a DelayedPublicMutable: scheduled now, current after CHANGE_ROLES_DELAY_SECONDS.
/// The twin of `transfer_restricted_when_freezed`: before the delay the transfer still passes.
#[test]
unconstrained fn a_freeze_is_not_effective_before_its_delay() {
    let (env, token, issuer, user, _) = utils::setup_and_mint(false);
    env.call_public(issuer, Token::at(token).grant_role(ENFORCEMENT_ROLE, issuer));
    env.call_public(issuer, Token::at(token).freeze(user, FreezableFlag { is_freezed: true }));
    env.call_private(issuer, Token::at(token).transfer_private_to_private(issuer, user, 100, 0));
    utils::check_private_balance(env, token, user, 100);
}

// --- zero amount -----------------------------------------------------------------------------------

/// A zero-amount transfer is accepted: it spends nothing, creates a zero-value note for `to` and a
/// change note for `from`, and leaves both balances unchanged. Recorded as the current behaviour so
/// that a future decision to refuse it (CMTAT Solidity accepts it too) is a visible change.
#[test]
unconstrained fn zero_amount_transfer_is_accepted_and_changes_nothing() {
    let (env, token, issuer, user, mint_amount) = utils::setup_and_mint(false);
    env.call_private(issuer, Token::at(token).transfer_private_to_private(issuer, user, 0, 0));
    utils::check_private_balance(env, token, issuer, mint_amount);
    utils::check_private_balance(env, token, user, 0);
}

// --- commitments and the lists ---------------------------------------------------------------------

unconstrained fn enable_blacklist_with(
    env: TestEnvironment,
    token: aztec::protocol::address::AztecAddress,
    issuer: aztec::protocol::address::AztecAddress,
    listed: aztec::protocol::address::AztecAddress,
) {
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
            listed,
            UserFlags { is_blacklisted: true, is_whitelisted: false },
        ),
    );
    utils::advance_past_delay(env, CHANGE_ROLES_DELAY_SECONDS);
}

#[test(should_fail_with = "The recipient is in the blacklist")]
unconstrained fn a_blacklisted_recipient_cannot_open_a_commitment() {
    let (env, token, issuer, user) = utils::setup_with_public_side(false, true);
    enable_blacklist_with(env, token, issuer, user);
    let _ = env.call_private(user, Token::at(token).initialize_transfer_commitment(user, issuer));
}

#[test(should_fail_with = "The sender is in the blacklist")]
unconstrained fn a_blacklisted_payer_cannot_complete_a_commitment() {
    let (env, token, issuer, user) = utils::setup_with_public_side(false, true);
    env.call_public(issuer, Token::at(token).grant_role(MINTER_ROLE, issuer));
    env.call_private(issuer, Token::at(token).mint_to_private(issuer, 1_000));
    let commitment =
        env.call_private(user, Token::at(token).initialize_transfer_commitment(user, issuer));
    env.mine_block();
    // the payer is listed after the commitment was opened; the payer-side check catches it at completion
    enable_blacklist_with(env, token, issuer, issuer);
    env.call_private(
        issuer,
        Token::at(token).transfer_private_to_commitment(issuer, commitment, 100, 0),
    );
}

// --- views nothing called ----------------------------------------------------------------------------

#[test]
unconstrained fn private_getters_match_the_public_ones() {
    let (env, token, issuer, _) = utils::setup(false);
    let name_pub = env.view_public(Token::at(token).name());
    let name_priv = env.view_private(issuer, Token::at(token).private_get_name());
    assert(name_pub == name_priv);
    assert(name_pub == FieldCompressedString::from_string("TestToken0000000000000000000000"));
    let symbol_pub = env.view_public(Token::at(token).symbol());
    let symbol_priv = env.view_private(issuer, Token::at(token).private_get_symbol());
    assert(symbol_pub == symbol_priv);
}
