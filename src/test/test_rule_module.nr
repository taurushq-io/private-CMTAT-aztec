use crate::test::utils;
use dep::aztec::{test::helpers::cheatcodes, oracle::unsafe_rand::unsafe_rand, protocol_types::address::AztecAddress};
use dep::authwit::cheatcodes as authwit_cheatcodes;
use crate::Token;
use crate::types::ruleModule::{UserFlags, Rules};




#[test]
unconstrained fn get_roles_test(){
    let (env, token_contract_address, issuer, _) = utils::setup(/* with_account_contracts */ false);

    let get_roles_call_interface = Token::at(token_contract_address).get_roles(issuer);
    let ret = env.call_public(get_roles_call_interface);
    assert(ret == 3);
}

#[test]
unconstrained fn set_roles_test(){
    let (env, token_contract_address, issuer, user) = utils::setup(/* with_account_contracts */ false);

    let get_roles_call_interface = Token::at(token_contract_address).get_roles(issuer);
    let ret = env.call_public(get_roles_call_interface);
    assert(ret == 3);

    let test_roles = UserFlags { is_admin: false, is_issuer: false, is_blacklisted: true };
    let set_roles_call_interface = Token::at(token_contract_address).grant_roles(user,test_roles );
    env.call_public(set_roles_call_interface);
    env.advance_block_by(3);

    let get_roles_call_interface = Token::at(token_contract_address).get_roles(user);
    let ret = env.call_public(get_roles_call_interface);
    assert(ret == 4);


}