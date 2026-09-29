//! Smoke test of the private/public bridges on this variant; the full suite lives in cmtat-aztec.
use crate::utils;
use cmtat_aztec_debt::CMTATAztecDebt as Token;
use cmtat_aztec_lib::modules::access_controlModule::MINTER_ROLE;

#[test]
unconstrained fn private_to_public_and_back() {
    let (env, token, issuer, user) =
        utils::setup_with_public_side(false, /* public_side_enabled */ true);
    env.call_public(issuer, Token::at(token).grant_role(MINTER_ROLE, issuer));
    env.call_private(issuer, Token::at(token).mint_to_private(issuer, 10_000));
    env.call_private(issuer, Token::at(token).transfer_private_to_public(issuer, user, 1_000, 0));
    assert_eq(env.view_public(Token::at(token).balance_of_public(user)), 1_000);
    env.call_private(user, Token::at(token).transfer_public_to_private(user, user, 400, 0));
    assert_eq(env.view_public(Token::at(token).balance_of_public(user)), 600);
    utils::check_private_balance(env, token, user, 400);
}

#[test(should_fail_with = "Error: public side disabled at deploy")]
unconstrained fn bridges_are_off_by_default() {
    let (env, token, issuer, user) = utils::setup(false);
    env.call_private(issuer, Token::at(token).transfer_private_to_public(issuer, user, 1, 0));
}
