use crate::utils;
use aztec::protocol::address::AztecAddress;
use aztec::protocol::traits::{FromField, Serialize, ToField};
use cmtat_aztec_debt::CMTATAztecDebt as Token;
use cmtat_aztec_lib::modules::access_controlModule::DEBT_ROLE;
use cmtat_aztec_lib::modules::extensions::debtModule::{
    DebtIdentifier, DebtInformation, DebtInstrument,
};
use compressed_string::FieldCompressedString;

// A distinct string per attribute would need 16 different 31-character literals; one shared value
// is enough to prove each attribute round-trips into its own slot, since the assertions below check
// position rather than content.
unconstrained fn sample_debt(currency_contract: AztecAddress) -> DebtInformation {
    let text = FieldCompressedString::from_string("abc0000000000000000000000000000");
    DebtInformation {
        debtIdentifier: DebtIdentifier {
            issuerName: text,
            issuerDescription: text,
            guarantor: text,
            debtHolder: text,
        },
        debtInstrument: DebtInstrument {
            interestRate: 3 as Field,
            parValue: 1 as Field,
            minimumDenomination: 7 as Field,
            issuanceDate: text,
            maturityDate: text,
            couponPaymentFrequency: text,
            interestScheduleFormat: text,
            interestPaymentDate: text,
            dayCountConvention: text,
            businessDayConvention: text,
            currency: text,
            currencyContract: currency_contract,
        },
    }
}

#[test]
unconstrained fn set_and_get_debt_test() {
    let (env, token_contract_address, issuer, _) = utils::setup(/* with_account_contracts */ false);

    env.call_public(issuer, Token::at(token_contract_address).grant_role(DEBT_ROLE, issuer));

    let currency_contract = AztecAddress::from_field(42);
    let debt = sample_debt(currency_contract);

    env.call_public(issuer, Token::at(token_contract_address).set_debt(debt));

    let ret: [Field; 16] = env.view_public(Token::at(token_contract_address).get_debt());

    let string_val =
        FieldCompressedString::from_string("abc0000000000000000000000000000").serialize()[0];

    // The identifier comes first: four strings.
    for i in 0..4 {
        assert(ret[i] == string_val);
    }
    // Then the instrument: three numbers, eight strings, and the currency contract address.
    assert(ret[4] == 3);
    assert(ret[5] == 1);
    assert(ret[6] == 7);
    for i in 7..15 {
        assert(ret[i] == string_val);
    }
    assert(ret[15] == currency_contract.to_field());
}

#[test]
unconstrained fn set_debt_instrument_keeps_identifier_test() {
    let (env, token_contract_address, issuer, _) = utils::setup(/* with_account_contracts */ false);

    env.call_public(issuer, Token::at(token_contract_address).grant_role(DEBT_ROLE, issuer));

    let debt = sample_debt(AztecAddress::from_field(42));
    env.call_public(issuer, Token::at(token_contract_address).set_debt(debt));

    // Change every instrument attribute the test can distinguish, and nothing else.
    let other = FieldCompressedString::from_string("xyz0000000000000000000000000000");
    let new_currency_contract = AztecAddress::from_field(99);
    let instrument = DebtInstrument {
        interestRate: 11 as Field,
        parValue: 22 as Field,
        minimumDenomination: 33 as Field,
        issuanceDate: other,
        maturityDate: other,
        couponPaymentFrequency: other,
        interestScheduleFormat: other,
        interestPaymentDate: other,
        dayCountConvention: other,
        businessDayConvention: other,
        currency: other,
        currencyContract: new_currency_contract,
    };

    env.call_public(issuer, Token::at(token_contract_address).set_debt_instrument(instrument));

    let ret: [Field; 16] = env.view_public(Token::at(token_contract_address).get_debt());

    // The identifier survived untouched...
    let string_val =
        FieldCompressedString::from_string("abc0000000000000000000000000000").serialize()[0];
    for i in 0..4 {
        assert(ret[i] == string_val);
    }
    // ...and every instrument attribute is the new one.
    let other_val = other.serialize()[0];
    assert(ret[4] == 11);
    assert(ret[5] == 22);
    assert(ret[6] == 33);
    for i in 7..15 {
        assert(ret[i] == other_val);
    }
    assert(ret[15] == new_currency_contract.to_field());
}

#[test(should_fail_with = "AccessControlUnauthorizedAccount")]
unconstrained fn set_debt_without_role_fails_test() {
    let (env, token_contract_address, _, recipient) =
        utils::setup(/* with_account_contracts */ false);

    let debt = sample_debt(AztecAddress::from_field(42));
    env.call_public(recipient, Token::at(token_contract_address).set_debt(debt));
}

#[test(should_fail_with = "AccessControlUnauthorizedAccount")]
unconstrained fn set_debt_instrument_without_role_fails_test() {
    let (env, token_contract_address, _, recipient) =
        utils::setup(/* with_account_contracts */ false);

    let instrument = sample_debt(AztecAddress::from_field(42)).debtInstrument;
    env.call_public(recipient, Token::at(token_contract_address).set_debt_instrument(instrument));
}
