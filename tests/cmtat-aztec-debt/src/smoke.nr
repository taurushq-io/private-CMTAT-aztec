use crate::utils;
use cmtat_aztec_debt::CMTATAztecDebt as Token;
use cmtat_aztec_lib::modules::access_controlModule::{
    BURNER_ROLE, ENFORCEMENT_ROLE, EXTRA_INFORMATION_ROLE, PAUSE_ROLE,
};
use cmtat_aztec_lib::modules::enforcementModule::{CHANGE_ROLES_DELAY_SECONDS, FreezableFlag};
use compressed_string::FieldCompressedString;

/// The variants share their value-moving code with the base contract, which carries the detailed
/// suite. These cover the paths that composing a different set of modules could plausibly break.

#[test]
unconstrained fn mint_transfer_burn() {
    let (env, token, issuer, user1, mint_amount) =
        utils::setup_and_mint(/* with_account_contracts */ false);

    let amount = 100 as u128;
    env.call_private(issuer, Token::at(token).transfer_private_to_private(issuer, user1, amount, 0));
    utils::check_private_balance(env, token, issuer, mint_amount - amount);
    utils::check_private_balance(env, token, user1, amount);

    env.call_public(issuer, Token::at(token).grant_role(BURNER_ROLE, user1));
    env.call_private(user1, Token::at(token).burn(user1, amount, 0));
    utils::check_private_balance(env, token, user1, 0 as u128);
}

#[test(should_fail_with = "Error: token contract is paused")]
unconstrained fn transfer_blocked_when_paused() {
    let (env, token, issuer, user1, _) = utils::setup_and_mint(/* with_account_contracts */ false);

    env.call_public(issuer, Token::at(token).grant_role(PAUSE_ROLE, issuer));
    env.call_public(issuer, Token::at(token).pause_contract());
    env.call_private(
        issuer,
        Token::at(token).transfer_private_to_private(issuer, user1, 100 as u128, 0),
    );
}

#[test(should_fail_with = "Frozen: Recipient")]
unconstrained fn transfer_blocked_when_frozen() {
    let (env, token, issuer, user1, _) = utils::setup_and_mint(/* with_account_contracts */ false);

    env.call_public(issuer, Token::at(token).grant_role(ENFORCEMENT_ROLE, issuer));
    env.call_public(issuer, Token::at(token).freeze(user1, FreezableFlag { is_freezed: true }));
    utils::advance_past_delay(env, CHANGE_ROLES_DELAY_SECONDS);

    env.call_private(
        issuer,
        Token::at(token).transfer_private_to_private(issuer, user1, 100 as u128, 0),
    );
}

#[test]
unconstrained fn token_id_available() {
    let (env, token, issuer, _, _) = utils::setup_and_mint(/* with_account_contracts */ false);

    env.call_public(issuer, Token::at(token).grant_role(EXTRA_INFORMATION_ROLE, issuer));
    let token_id = FieldCompressedString::from_string("ISIN CH0000000000 0000000000000");
    env.call_public(issuer, Token::at(token).set_token_id(token_id));
    assert(env.view_public(Token::at(token).token_id()) == token_id);
}
