use crate::test::utils;
use dep::aztec::test::helpers::cheatcodes;
use crate::Token;

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