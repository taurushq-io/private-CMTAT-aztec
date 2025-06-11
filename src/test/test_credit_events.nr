use crate::test::utils;
use dep::aztec::{test::helpers::cheatcodes};
use dep::authwit::cheatcodes as authwit_cheatcodes;
use crate::Token;
use crate::types::extensions::creditEventsModule::{CreditEventsStruct};
use crate::types::access_controlModule::{DEFAULT_ADMIN_ROLE, DEBT_CREDIT_EVENT_ROLE};
use dep::compressed_string::FieldCompressedString;
use dep::aztec::protocol_types::traits::{Packable, Serialize, Deserialize};



#[test]
unconstrained fn set_and_get_credit_test(){
    let (env, token_contract_address, issuer, user) = utils::setup(/* with_account_contracts */ false);

    Token::at(token_contract_address).grant_role(DEBT_CREDIT_EVENT_ROLE, issuer).call(&mut env.public());

    let credit_events = CreditEventsStruct {flagDefault: true,flagRedeemed: false, rating: FieldCompressedString::from_string("abc0000000000000000000000000000")};
    let credit_call_interface = Token::at(token_contract_address).set_credit_events(credit_events);
    credit_call_interface.call(&mut env.public());
    env.advance_block_by(3);

    let credit_call_interface = Token::at(token_contract_address).get_credit_events();
    let ret : [Field; 3] = credit_call_interface.call(&mut env.public());

    assert(ret[0] == 1);
    assert(ret[1] == 0);
    assert(ret[2] == FieldCompressedString::from_string("abc0000000000000000000000000000").serialize()[0]);

}