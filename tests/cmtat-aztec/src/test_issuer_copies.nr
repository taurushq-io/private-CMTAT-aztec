//! The audit invariant: every note written for a holder is also delivered to the issuer, offchain.
//! The TXE exposes the offchain messages of the last call (`env.offchain_messages()`), each with its
//! recipient, so the invariant can be asserted mechanically: N notes moved, N messages to the issuer.
//! Before this file existed, dropping the issuer's `deliver_to` in `credit_private` left the whole
//! suite green (mutation check, 0.4.0 review, K-2).
use crate::utils;
use aztec::protocol::address::AztecAddress;
use aztec::test::helpers::test_environment::TestEnvironment;
use cmtat_aztec::CMTATAztec::CHANGE_ROLES_DELAY_SECONDS;
use cmtat_aztec::CMTATAztec as Token;
use cmtat_aztec_lib::modules::access_controlModule::{BURNER_ROLE, MINTER_ROLE};

unconstrained fn issuer_copies(env: TestEnvironment, issuer: AztecAddress) -> u32 {
    let messages = env.offchain_messages();
    let mut n = 0;
    for i in 0..messages.len() {
        if messages.get(i).recipient == issuer {
            n += 1;
        }
    }
    assert_eq(
        n,
        messages.len(),
        "an offchain message was addressed to someone other than the issuer",
    );
    n
}

#[test]
unconstrained fn mint_delivers_one_copy_to_the_issuer() {
    let (env, token, issuer, user) = utils::setup(false);
    env.call_public(issuer, Token::at(token).grant_role(MINTER_ROLE, issuer));
    env.call_private(issuer, Token::at(token).mint_to_private(user, 1_000));
    assert_eq(issuer_copies(env, issuer), 1);
}

#[test]
unconstrained fn transfer_delivers_two_copies_to_the_issuer() {
    let (env, token, issuer, user, _) = utils::setup_and_mint(false);
    env.call_private(issuer, Token::at(token).transfer_private_to_private(issuer, user, 100, 0));
    // the sender's change note and the recipient's new note
    assert_eq(issuer_copies(env, issuer), 2);
}

#[test]
unconstrained fn burn_delivers_one_copy_to_the_issuer() {
    let (env, token, issuer, _, _) = utils::setup_and_mint(false);
    env.call_public(issuer, Token::at(token).grant_role(BURNER_ROLE, issuer));
    env.call_private(issuer, Token::at(token).burn(issuer, 100, 0));
    assert_eq(issuer_copies(env, issuer), 1);
}

#[test]
unconstrained fn the_copies_follow_a_rotated_issuer() {
    let (mut env, token, issuer, user, _) = utils::setup_and_mint(false);
    let new_issuer = env.create_light_account();
    env.call_public(issuer, Token::at(token).set_issuer(new_issuer));
    utils::advance_past_delay(env, CHANGE_ROLES_DELAY_SECONDS);
    env.call_private(issuer, Token::at(token).transfer_private_to_private(issuer, user, 100, 0));
    assert_eq(issuer_copies(env, new_issuer), 2);
}
