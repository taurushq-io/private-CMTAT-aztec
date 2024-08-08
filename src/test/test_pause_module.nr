use crate::test::utils;
use dep::aztec::{test::helpers::cheatcodes, oracle::unsafe_rand::unsafe_rand, protocol_types::address::AztecAddress};
use dep::authwit::cheatcodes as authwit_cheatcodes;
use crate::Token;




#[test]
unconstrained fn get_paused(){
    let (env, token_contract_address, issuer, _) = utils::setup(/* with_account_contracts */ false);

    let get_roles_call_interface = Token::at(token_contract_address).public_get_pause();
    let ret = env.call_public(get_roles_call_interface);
    assert(ret == 0);
}

#[test]
unconstrained fn pause_test(){
    let (env, token_contract_address, issuer, user) = utils::setup(/* with_account_contracts */ false);

    let get_roles_call_interface = Token::at(token_contract_address).public_get_pause();
    let ret = env.call_public(get_roles_call_interface);
    assert(ret == 0);

    let set_roles_call_interface = Token::at(token_contract_address).pause_contract();
    env.call_public(set_roles_call_interface);

    let get_roles_call_interface = Token::at(token_contract_address).public_get_pause();
    let ret = env.call_public(get_roles_call_interface);
    assert(ret == 1);

    let get_roles_call_interface = Token::at(token_contract_address).unpause_contract();
    env.call_public(get_roles_call_interface);

    let get_roles_call_interface = Token::at(token_contract_address).public_get_pause();
    let ret = env.call_public(get_roles_call_interface);
    assert(ret == 0);
}