use crate::utils;
use aztec::protocol::traits::Serialize;
use cmtat_aztec_debt::CMTATAztecDebt as Token;
use cmtat_aztec_lib::modules::access_controlModule::DEBT_CREDIT_EVENT_ROLE;
use cmtat_aztec_lib::modules::extensions::creditEventsModule::CreditEventsStruct;
use compressed_string::FieldCompressedString;

#[test]
unconstrained fn set_and_get_credit_test() {
    let (env, token_contract_address, issuer, _) = utils::setup(/* with_account_contracts */ false);

    env.call_public(
        issuer,
        Token::at(token_contract_address).grant_role(DEBT_CREDIT_EVENT_ROLE, issuer),
    );

    let credit_events = CreditEventsStruct {
        flagDefault: true,
        flagRedeemed: false,
        rating: FieldCompressedString::from_string("abc0000000000000000000000000000"),
    };
    env.call_public(issuer, Token::at(token_contract_address).set_credit_events(credit_events));

    let ret: [Field; 3] = env.view_public(Token::at(token_contract_address).get_credit_events());

    assert(ret[0] == 1);
    assert(ret[1] == 0);
    assert(
        ret[2]
            == FieldCompressedString::from_string("abc0000000000000000000000000000").serialize()[0],
    );
}
