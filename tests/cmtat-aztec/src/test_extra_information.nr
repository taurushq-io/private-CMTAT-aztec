use crate::utils;
use aztec::protocol::traits::Serialize;
use cmtat_aztec::CMTATAztec as Token;
use cmtat_aztec_lib::modules::access_controlModule::EXTRA_INFORMATION_ROLE;
use cmtat_aztec_lib::modules::extraInformationModule::DocumentInfo;
use compressed_string::FieldCompressedString;

global DOC_NAME: str<31> = "Terms and conditions 0000000000";
global DOC_URI: str<31> = "ipfs://QmTerms00000000000000000";
// The two halves of a bytes32 document hash.
global HASH_HIGH: u128 = 0x0123456789abcdef0123456789abcdef;
global HASH_LOW: u128 = 0xfedcba9876543210fedcba9876543210;

unconstrained fn sample_terms() -> DocumentInfo {
    DocumentInfo {
        name: FieldCompressedString::from_string(DOC_NAME),
        uri: FieldCompressedString::from_string(DOC_URI),
        documentHashHigh: HASH_HIGH,
        documentHashLow: HASH_LOW,
    }
}

#[test]
unconstrained fn terms_empty_by_default() {
    let (env, token_contract_address, _, _) = utils::setup(/* with_account_contracts */ false);

    let ret: [Field; 5] = env.view_public(Token::at(token_contract_address).terms());
    for i in 0..5 {
        assert(ret[i] == 0);
    }
}

#[test]
unconstrained fn set_and_get_terms() {
    let (env, token_contract_address, issuer, _) = utils::setup(/* with_account_contracts */ false);

    env.call_public(
        issuer,
        Token::at(token_contract_address).grant_role(EXTRA_INFORMATION_ROLE, issuer),
    );

    env.call_public(issuer, Token::at(token_contract_address).set_terms(sample_terms()));

    let ret: [Field; 5] = env.view_public(Token::at(token_contract_address).terms());

    assert(ret[0] == FieldCompressedString::from_string(DOC_NAME).serialize()[0]);
    assert(ret[1] == FieldCompressedString::from_string(DOC_URI).serialize()[0]);
    assert(ret[2] == HASH_HIGH as Field);
    assert(ret[3] == HASH_LOW as Field);
    // lastModified is stamped by the contract, so it is non-zero once the terms are set.
    assert(ret[4] != 0);
}

#[test(should_fail_with = "AccessControlUnauthorizedAccount")]
unconstrained fn set_terms_requires_role() {
    let (env, token_contract_address, _, user) = utils::setup(/* with_account_contracts */ false);

    // `user` does not hold EXTRA_INFORMATION_ROLE.
    env.call_public(user, Token::at(token_contract_address).set_terms(sample_terms()));
}

#[test]
unconstrained fn set_terms_replaces_every_field() {
    let (env, token_contract_address, issuer, _) = utils::setup(/* with_account_contracts */ false);

    env.call_public(
        issuer,
        Token::at(token_contract_address).grant_role(EXTRA_INFORMATION_ROLE, issuer),
    );
    env.call_public(issuer, Token::at(token_contract_address).set_terms(sample_terms()));

    // A second call with a different document overwrites all of it, as in CMTAT Solidity.
    let updated = DocumentInfo {
        name: FieldCompressedString::from_string("Updated terms 00000000000000000"),
        uri: FieldCompressedString::from_string("https://example.com/terms000000"),
        documentHashHigh: 1 as u128,
        documentHashLow: 2 as u128,
    };
    env.call_public(issuer, Token::at(token_contract_address).set_terms(updated));

    let ret: [Field; 5] = env.view_public(Token::at(token_contract_address).terms());
    assert(ret[2] == 1);
    assert(ret[3] == 2);
}

global TOKEN_ID: str<31> = "ISIN CH0000000000 0000000000000";

#[test]
unconstrained fn token_id_empty_by_default() {
    let (env, token_contract_address, _, _) = utils::setup(/* with_account_contracts */ false);

    // An unwritten PublicMutable reads as zero, which is not the same as a string of spaces.
    let ret = env.view_public(Token::at(token_contract_address).token_id());
    assert(ret.serialize()[0] == 0);
}

#[test]
unconstrained fn set_and_get_token_id() {
    let (env, token_contract_address, issuer, _) = utils::setup(/* with_account_contracts */ false);

    env.call_public(
        issuer,
        Token::at(token_contract_address).grant_role(EXTRA_INFORMATION_ROLE, issuer),
    );

    let token_id = FieldCompressedString::from_string(TOKEN_ID);
    env.call_public(issuer, Token::at(token_contract_address).set_token_id(token_id));

    let ret = env.view_public(Token::at(token_contract_address).token_id());
    assert(ret == token_id);
}

#[test(should_fail_with = "AccessControlUnauthorizedAccount")]
unconstrained fn set_token_id_requires_role() {
    let (env, token_contract_address, _, user) = utils::setup(/* with_account_contracts */ false);

    env.call_public(
        user,
        Token::at(token_contract_address).set_token_id(FieldCompressedString::from_string(TOKEN_ID)),
    );
}

#[test]
unconstrained fn token_id_is_independent_of_terms() {
    let (env, token_contract_address, issuer, _) = utils::setup(/* with_account_contracts */ false);

    env.call_public(
        issuer,
        Token::at(token_contract_address).grant_role(EXTRA_INFORMATION_ROLE, issuer),
    );

    // The two share a module but not a storage slot: writing one must not disturb the other.
    let token_id = FieldCompressedString::from_string(TOKEN_ID);
    env.call_public(issuer, Token::at(token_contract_address).set_token_id(token_id));
    env.call_public(issuer, Token::at(token_contract_address).set_terms(sample_terms()));

    assert(env.view_public(Token::at(token_contract_address).token_id()) == token_id);
    let terms: [Field; 5] = env.view_public(Token::at(token_contract_address).terms());
    assert(terms[2] == HASH_HIGH as Field);
}
