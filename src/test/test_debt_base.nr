use crate::test::utils;
use crate::CMTAToken as Token;
use crate::modules::extensions::debtBaseModule::{DebtBaseStruct};
use crate::modules::access_controlModule::DEBT_ROLE;
use dep::compressed_string::FieldCompressedString;
use dep::aztec::protocol_types::traits::Serialize;


#[test]
unconstrained fn set_and_get_debt_test(){
    let (env, token_contract_address, issuer, _) = utils::setup(/* with_account_contracts */ false);

    Token::at(token_contract_address).grant_role(DEBT_ROLE, issuer).call(&mut env.public());

    let debt_events = DebtBaseStruct {
        interestRate: 3 as Field,
        parValue: 1 as Field,
        guarantor: FieldCompressedString::from_string("abc0000000000000000000000000000"),
        bondHolder: FieldCompressedString::from_string("abc0000000000000000000000000000"),
        maturityDate: FieldCompressedString::from_string("abc0000000000000000000000000000"),
        interestScheduleFormat: FieldCompressedString::from_string("abc0000000000000000000000000000"),
        interestPaymentDate: FieldCompressedString::from_string("abc0000000000000000000000000000"),
        dayCountConvention: FieldCompressedString::from_string("abc0000000000000000000000000000"), 
        businessDayConvention: FieldCompressedString::from_string("abc0000000000000000000000000000"), 
        publicHolidaysCalendar: FieldCompressedString::from_string("abc0000000000000000000000000000"), 
        issuanceDate: FieldCompressedString::from_string("abc0000000000000000000000000000"), 
        couponFrequency: FieldCompressedString::from_string("abc0000000000000000000000000000"),};

    let credit_call_interface = Token::at(token_contract_address).set_debt_base(debt_events);
    credit_call_interface.call(&mut env.public());
    env.advance_block_by(3);

    let credit_call_interface = Token::at(token_contract_address).get_debt_base();
    let ret : [Field; 12] = credit_call_interface.call(&mut env.public());

    let string_val = FieldCompressedString::from_string("abc0000000000000000000000000000").serialize()[0];
    assert(ret[0] == 3);
    assert(ret[1] == 1);
    assert(ret[2] == string_val);
    assert(ret[3] == string_val);
    assert(ret[4] == string_val);
    assert(ret[5] == string_val);
    assert(ret[6] == string_val);
    assert(ret[7] == string_val);
    assert(ret[8] == string_val);
    assert(ret[9] == string_val);
    assert(ret[10] == string_val);
    assert(ret[11] == string_val);

}