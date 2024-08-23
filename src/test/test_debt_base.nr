use crate::test::utils;
use dep::aztec::{test::helpers::cheatcodes};
use dep::authwit::cheatcodes as authwit_cheatcodes;
use crate::Token;
use crate::types::extensions::debtBaseModule::{DebtBaseStruct};
use crate::types::access_controlModule::{DEFAULT_ADMIN_ROLE, DEBT_ROLE};
use dep::compressed_string::FieldCompressedString;


#[test]
unconstrained fn set_and_get_debt_test(){
    let (env, token_contract_address, issuer, user) = utils::setup(/* with_account_contracts */ false);

    let grant_pause_roles_call_interface = Token::at(token_contract_address).grant_role(DEBT_ROLE, issuer);
    env.call_public(grant_pause_roles_call_interface);

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
    env.call_public(credit_call_interface);
    env.advance_block_by(3);

    let credit_call_interface = Token::at(token_contract_address).get_debt_base();
    let ret : [Field; 12] = env.call_public(credit_call_interface);

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