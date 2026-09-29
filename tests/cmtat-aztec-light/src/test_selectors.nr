//! The entry-point declarations are the one thing the token-module refactor left per variant, so a
//! variant can drift from the base by a renamed or re-typed function without any test noticing.
//! This pins the shared surface to the same selectors the base variant pins in test_aip20_profile.nr
//! and test_hybrid.nr (0.4.0 review, K-3): a mismatch means this variant's declaration changed alone.
use crate::utils;
use aztec::protocol::traits::ToField;
use cmtat_aztec_light::CMTATAztecLight as Token;

#[test]
unconstrained fn shared_entry_points_have_the_base_variants_selectors() {
    let (_, token, issuer, user) = utils::setup(false);
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
    // CMTAT's burn keeps its own selector, deliberately different from AIP-20's burn_private
    assert(Token::at(token).burn(issuer, 1, 0).selector.to_field() != 0xc282ed79);
}
