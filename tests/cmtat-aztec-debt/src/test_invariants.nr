//! The supply invariant on this variant: `total_supply` equals the sum of every balance, private
//! and public, after a sequence that exercises every operation which moves supply.
//!
//! This variant shares the token module with the base variant byte for byte, so the arithmetic under test is the same code. The twin is here because supply was asserted nowhere in this crate at all, and because the debt and credit-event modules add state alongside it.
//! The full invariant suite lives in `cmtat-aztec`; this is the variant twin (0.5.0 review, K-1).
use crate::utils;
use cmtat_aztec_debt::CMTATAztecDebt as Token;
use cmtat_aztec_lib::modules::access_controlModule::{BURNER_ROLE, MINTER_ROLE};

global MINT: u128 = 10_000;

#[test]
unconstrained fn supply_equals_the_sum_of_every_balance_after_a_mixed_sequence() {
    let (mut env, token, issuer, user1) =
        utils::setup_with_public_side(false, /* public_side_enabled */ true);
    let user2 = env.create_light_account();
    env.call_public(issuer, Token::at(token).grant_role(MINTER_ROLE, issuer));
    env.call_public(issuer, Token::at(token).grant_role(BURNER_ROLE, issuer));

    // Supply in, to two holders.
    env.call_private(issuer, Token::at(token).mint_to_private(issuer, MINT));
    env.call_private(issuer, Token::at(token).mint_to_private(user1, 2_500));

    // Private movement, then out to the public side and part of it back to a third holder.
    env.call_private(issuer, Token::at(token).transfer_private_to_private(issuer, user1, 1_500, 0));
    env.call_private(issuer, Token::at(token).transfer_private_to_public(issuer, user2, 2_000, 0));
    env.call_private(user2, Token::at(token).transfer_public_to_private(user2, user2, 750, 0));

    // Supply out.
    env.call_private(issuer, Token::at(token).burn(issuer, 1_000, 0));

    let expected_supply = MINT + 2_500 - 1_000;
    assert_eq(
        env.view_public(Token::at(token).total_supply()),
        expected_supply,
        "the mints less the burn",
    );

    let private_total = env.execute_utility(Token::at(token).balance_of_private(issuer))
        + env.execute_utility(Token::at(token).balance_of_private(user1))
        + env.execute_utility(Token::at(token).balance_of_private(user2));
    let public_total = env.view_public(Token::at(token).balance_of_public(issuer))
        + env.view_public(Token::at(token).balance_of_public(user1))
        + env.view_public(Token::at(token).balance_of_public(user2));

    assert_eq(
        private_total + public_total,
        expected_supply,
        "every token is in exactly one balance, private or public",
    );
}
