use crate::utils;
use aztec::protocol::traits::Serialize;
use cmtat_aztec::CMTATAztec as Token;
use compressed_string::FieldCompressedString;

// It is not possible to deserialize strings in Noir ATM, so name and symbol cannot be checked yet.

#[test]
unconstrained fn check_decimals_private() {
    // Setup without account contracts. We are not using authwits here, so dummy accounts are enough
    let (env, token_contract_address, issuer, _) = utils::setup(/* with_account_contracts */ false);

    // Check decimals
    let result = env.view_private(issuer, Token::at(token_contract_address).private_get_decimals());

    assert(result == 18);
}

#[test]
unconstrained fn check_decimals_public() {
    // Setup without account contracts. We are not using authwits here, so dummy accounts are enough
    let (env, token_contract_address, _, _) = utils::setup(/* with_account_contracts */ false);

    // Check decimals
    let result = env.view_public(Token::at(token_contract_address).decimals());

    assert(result == 18 as u8);
}

#[test]
unconstrained fn check_issuer_addr_public() {
    let (env, token_contract_address, issuer, _) = utils::setup(/* with_account_contracts */ false);

    let issuer_addr = env.view_public(Token::at(token_contract_address).public_get_issuer());

    assert(issuer == issuer_addr);
}

#[test]
unconstrained fn check_issuer_addr_private() {
    let (env, token_contract_address, issuer, _) = utils::setup(/* with_account_contracts */ false);

    let issuer_addr_priv =
        env.view_private(issuer, Token::at(token_contract_address).private_get_issuer());

    assert(issuer == issuer_addr_priv);
}

#[test]
unconstrained fn check_version() {
    let (env, token_contract_address, _, _) = utils::setup(/* with_account_contracts */ false);

    let result = env.view_public(Token::at(token_contract_address).version());

    // A compile-time constant, so it must equal VERSION exactly - including the padding that
    // `FieldCompressedString` requires.
    assert(result == FieldCompressedString::from_string(cmtat_aztec::CMTATAztec::VERSION));
    // and it must not be empty, which is what a forgotten bump would look like: an unset
    // FieldCompressedString reads as zero, not as a string of spaces
    assert(result.serialize()[0] != 0);
}
