use crate::test::utils;
use dep::aztec::test::helpers::cheatcodes;
use crate::FiatCMTAToken as Token;
use dep::compressed_string::FieldCompressedString;


// It is not possible to deserialize strings in Noir ATM, so name and symbol cannot be checked yet.

#[test]
unconstrained fn check_decimals_private() {
    // Setup without account contracts. We are not using authwits here, so dummy accounts are enough
    let (env, token_contract_address, _, _) = utils::setup(/* with_account_contracts */ false);

    // Check decimals
    let result = Token::at(token_contract_address).private_get_decimals().view(&mut env.private());

    assert(result == 18);
}

#[test]
unconstrained fn check_decimals_public() {
    // Setup without account contracts. We are not using authwits here, so dummy accounts are enough
    let (env, token_contract_address, _, _) = utils::setup(/* with_account_contracts */ false);

    // Check decimals
    let result = Token::at(token_contract_address).public_get_decimals().view(&mut env.public());
    

    assert(result == 18 as u8);
}

#[test]
unconstrained fn check_issuer_addr_public() {
    let (env, token_contract_address, issuer, _) = utils::setup(/* with_account_contracts */ false);

    let issuer_addr = Token::at(token_contract_address).public_get_issuer().view(&mut env.public());

    assert(issuer == issuer_addr);
}

#[test]
unconstrained fn check_issuer_addr_private() {
    let (env, token_contract_address, issuer, _) = utils::setup(/* with_account_contracts */ false);

    let issuer_addr_priv = Token::at(token_contract_address).private_get_issuer().view(&mut env.private());

    assert(issuer == issuer_addr_priv);
}

#[test]
unconstrained fn check_name_public() {
    // Setup without account contracts. We are not using authwits here, so dummy accounts are enough
    let (env, token_contract_address, _, _) = utils::setup(/* with_account_contracts */ false);

    // Check name
    let result = Token::at(token_contract_address).public_get_name().view(&mut env.public());
    let tokenName = "FiatCMTAToken000000000000000000";
    let expect = FieldCompressedString::from_string(tokenName);
    assert(result == expect);
}

#[test]
unconstrained fn check_name_private() {
    // Setup without account contracts. We are not using authwits here, so dummy accounts are enough
    let (env, token_contract_address, _, _) = utils::setup(/* with_account_contracts */ false);

    // Check name
    let result = Token::at(token_contract_address).private_get_name().view(&mut env.private());
    let tokenName = "FiatCMTAToken000000000000000000";
    let expect = FieldCompressedString::from_string(tokenName);
    assert(result == expect);
}

#[test]
unconstrained fn check_symbol_public() {
    // Setup without account contracts. We are not using authwits here, so dummy accounts are enough
    let (env, token_contract_address, _, _) = utils::setup(/* with_account_contracts */ false);

    // Check symbol
    let result = Token::at(token_contract_address).public_get_symbol().view(&mut env.public());
    let symbol = "FCMTA00000000000000000000000000";
    let expect = FieldCompressedString::from_string(symbol);
    assert(result == expect);
}

#[test]
unconstrained fn check_symbol_private() {
    // Setup without account contracts. We are not using authwits here, so dummy accounts are enough
    let (env, token_contract_address, _, _) = utils::setup(/* with_account_contracts */ false);

    // Check symbol
    let result = Token::at(token_contract_address).private_get_symbol().view(&mut env.private());
    let symbol = "FCMTA00000000000000000000000000";
    let expect = FieldCompressedString::from_string(symbol);
    assert(result == expect);
}

#[test]
unconstrained fn check_currency() {
    // Setup without account contracts. We are not using authwits here, so dummy accounts are enough
    let (env, token_contract_address, _, _) = utils::setup(/* with_account_contracts */ false);

    // Check currency
    let result = Token::at(token_contract_address).public_get_currency().view(&mut env.public());
    let currency = "USD0000000000000000000000000000";
    let expect = FieldCompressedString::from_string(currency);
    assert(result == expect);
}


#[test]
unconstrained fn check_currency_private() {
    // Setup without account contracts. We are not using authwits here, so dummy accounts are enough
    let (env, token_contract_address, _, _) = utils::setup(/* with_account_contracts */ false);

    // Check currency
    let result = Token::at(token_contract_address).private_get_currency().view(&mut env.private());
    let currency = "USD0000000000000000000000000000";
    let expect = FieldCompressedString::from_string(currency);
    assert(result == expect);
}

