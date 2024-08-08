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

    //check if issuer has pause role
    let get_is_pause_roles_call_interface = Token::at(token_contract_address).get_is_pause_role(issuer);
    let ret = env.call_public(get_is_pause_roles_call_interface);


    //issuer does not have pause role
    assert(ret == 0);

    //give pause role to issuer
    let grant_pause_roles_call_interface = Token::at(token_contract_address).grant_pause_role(issuer);
    env.call_public(grant_pause_roles_call_interface);

    //checks that issuer has pause role
    let get_is_pause_roles_call_interface = Token::at(token_contract_address).get_is_pause_role(issuer);
    let ret = env.call_public(get_is_pause_roles_call_interface);

    assert(ret == 1);

    //checks if contract is paused
    let get_pause_call_interface = Token::at(token_contract_address).public_get_pause();
    let ret = env.call_public(get_pause_call_interface);
    assert(ret == 0);

    //issuer pauses the contract 
    let set_pause_call_interface = Token::at(token_contract_address).pause_contract();
    env.call_public(set_pause_call_interface);

    //checks if contract is indeed paused
    let get_pause_call_interface = Token::at(token_contract_address).public_get_pause();
    let ret = env.call_public(get_pause_call_interface);
    assert(ret == 1);

    //issuer unpauses the contract
    let set_unpause_call_interface = Token::at(token_contract_address).unpause_contract();
    env.call_public(set_unpause_call_interface);

    //checks that the contract has been unpaused correctly
    let get_pause_call_interface = Token::at(token_contract_address).public_get_pause();
    let ret = env.call_public(get_pause_call_interface);
    assert(ret == 0);
}

//pause fails when caller does not have pause role
#[test(should_fail)]
unconstrained fn pause_test_should_fail(){
    let (env, token_contract_address, issuer, user) = utils::setup(/* with_account_contracts */ false);
    
    let set_pause_call_interface = Token::at(token_contract_address).pause_contract();
    env.call_public(set_pause_call_interface);
}
