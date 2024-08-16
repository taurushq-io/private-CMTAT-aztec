use crate::test::utils;
use dep::aztec::{test::helpers::cheatcodes};
use dep::authwit::cheatcodes as authwit_cheatcodes;
use crate::Token;
use crate::types::access_control::{DEFAULT_ADMIN_ROLE, PAUSE_ROLE};


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
    let get_is_pause_roles_call_interface = Token::at(token_contract_address).has_role(PAUSE_ROLE, issuer);
    let ret = env.call_public(get_is_pause_roles_call_interface);

    //issuer does not have pause role
    assert(ret == 0);

    //give pause role to issuer
    let grant_pause_roles_call_interface = Token::at(token_contract_address).grant_role(PAUSE_ROLE, issuer);
    env.call_public(grant_pause_roles_call_interface);

    //checks that issuer has pause role
    let get_is_pause_roles_call_interface = Token::at(token_contract_address).has_role(PAUSE_ROLE, issuer);
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

#[test(should_fail_with="Private balance is not correct")]
unconstrained fn mint_when_paused_fails(){
    let (env, token_contract_address, issuer, user) = utils::setup(/* with_account_contracts */ false);

    let mint_amount = 10000;
    env.impersonate(issuer);

    let grant_pause_roles_call_interface = Token::at(token_contract_address).grant_role(PAUSE_ROLE, issuer);
    env.call_public(grant_pause_roles_call_interface);

    let set_pause_call_interface = Token::at(token_contract_address).pause_contract();
    env.call_public(set_pause_call_interface);

    let get_pause_call_interface = Token::at(token_contract_address).public_get_pause();
    let ret = env.call_public(get_pause_call_interface);
    assert(ret == 1);

    //there is no revert because of paused contract, which is weird
    let mint_private_call_interface = Token::at(token_contract_address).mint(issuer, mint_amount);
    env.call_private_void(mint_private_call_interface);

    let total_supply_call_interface = Token::at(token_contract_address).total_supply();
    let total_supply = env.call_public(total_supply_call_interface);

    assert(total_supply == 0);

    utils::check_private_balance(token_contract_address, issuer, mint_amount);

}
#[test(should_fail_with="error: contract already paused")]
unconstrained fn pause_twice_throws(){

    let (env, token_contract_address, issuer, user) = utils::setup(/* with_account_contracts */ false);
    
    let grant_pause_roles_call_interface = Token::at(token_contract_address).grant_role(PAUSE_ROLE, issuer);
    env.call_public(grant_pause_roles_call_interface);


    let set_pause_call_interface = Token::at(token_contract_address).pause_contract();
    env.call_public(set_pause_call_interface);

    let set_pause_call_interface = Token::at(token_contract_address).pause_contract();
    env.call_public(set_pause_call_interface);
}


//pause fails when caller does not have pause role
#[test(should_fail_with="AccessControlUnauthorizedAccount")]
unconstrained fn test_pause_roles(){
    let (env, token_contract_address, issuer, user) = utils::setup(/* with_account_contracts */ false);
    
    let set_pause_call_interface = Token::at(token_contract_address).pause_contract();
    env.call_public(set_pause_call_interface);
}

//owner has role when pause but not the role when unpause
#[test(should_fail_with="AccessControlUnauthorizedAccount")]
unconstrained fn test_pause_role_2(){
    let (env, token_contract_address, issuer, user) = utils::setup(/* with_account_contracts */ false);
    
    let grant_pause_roles_call_interface = Token::at(token_contract_address).grant_role(PAUSE_ROLE, issuer);
    env.call_public(grant_pause_roles_call_interface);


    let set_pause_call_interface = Token::at(token_contract_address).pause_contract();
    env.call_public(set_pause_call_interface);

    //checks if contract is indeed paused
    let get_pause_call_interface = Token::at(token_contract_address).public_get_pause();
    let ret = env.call_public(get_pause_call_interface);
    assert(ret == 1);

    let grant_pause_roles_call_interface = Token::at(token_contract_address).revoke_role(PAUSE_ROLE, issuer);
    env.call_public(grant_pause_roles_call_interface);

    let set_pause_call_interface = Token::at(token_contract_address).unpause_contract();
    env.call_public(set_pause_call_interface);
}
