//! The AIP-20 private profile: the seven entry points whose names and parameter types match the
//! `aztec-standards` Token, so a caller addressing the standard by selector reaches this contract.
//! Values read from `Token::at(..).<fn>(..).selector` compiled against the fork at 5433e9c.
//! `burn` is deliberately NOT aligned (`burn_private` there is holder-authorised; here it needs
//! BURNER_ROLE) - see "Interface alignment" in doc/technical/building-on-aip20.md.
use crate::utils;
use aztec::protocol::traits::ToField;
use cmtat_aztec::CMTATAztec as Token;

#[test]
unconstrained fn private_profile_selectors_match_aip20() {
    let (_, token, issuer, user) = utils::setup(/* with_account_contracts */ false);
    assert_eq(
        Token::at(token).transfer_private_to_private(issuer, user, 1, 0).selector.to_field(),
        0xedc09d49,
    );
    assert_eq(Token::at(token).mint_to_private(user, 1).selector.to_field(), 0xf8f84119);
    assert_eq(Token::at(token).name().selector.to_field(), 0x5c5c9c42);
    assert_eq(Token::at(token).symbol().selector.to_field(), 0x62cc9647);
    assert_eq(Token::at(token).decimals().selector.to_field(), 0x6bff8f59);
    assert_eq(Token::at(token).balance_of_private(user).selector.to_field(), 0x4375727c);
    assert_eq(Token::at(token).total_supply().selector.to_field(), 0x8dd382ec);
}

/// The burn trap: this selector must stay different from AIP-20's `burn_private` (0xc282ed79),
/// because the authorisation differs.
#[test]
unconstrained fn burn_selector_is_not_aip20s() {
    let (_, token, issuer, _) = utils::setup(/* with_account_contracts */ false);
    assert(Token::at(token).burn(issuer, 1, 0).selector.to_field() != 0xc282ed79);
}
