use crate::test::utils;
use dep::aztec::{test::helpers::cheatcodes};
use dep::authwit::cheatcodes as authwit_cheatcodes;
use crate::Token;
use crate::types::access_controlModule::{DEFAULT_ADMIN_ROLE, PAUSE_ROLE, MINTER_ROLE};


#[test]
unconstrained fn get_paused(){
    let (env, token_contract_address, issuer, _) = utils::setup(/* with_account_contracts */ false);

    let ret = Token::at(token_contract_address).public_get_pause().view(&mut env.public());
    assert(ret == 0);
}

#[test]
unconstrained fn pause_test(){
    let (env, token_contract_address, issuer, user) = utils::setup(/* with_account_contracts */ false);

    //check if issuer has pause role
    let ret = Token::at(token_contract_address).has_role(PAUSE_ROLE, issuer).view(&mut env.public());

    //issuer does not have pause role
    assert(ret == 0);

    //give pause role to issuer
    Token::at(token_contract_address).grant_role(PAUSE_ROLE, issuer).call(&mut env.public());

    //checks that issuer has pause role
    let ret = Token::at(token_contract_address).has_role(PAUSE_ROLE, issuer).view(&mut env.public());

    assert(ret == 1);

    //checks if contract is paused
    let ret = Token::at(token_contract_address).public_get_pause().view(&mut env.public());
    assert(ret == 0);

    //issuer pauses the contract 
    Token::at(token_contract_address).pause_contract().call(&mut env.public());

    //checks if contract is indeed paused
    let ret = Token::at(token_contract_address).public_get_pause().view(&mut env.public());
    assert(ret == 1);

    //issuer unpauses the contract
    Token::at(token_contract_address).unpause_contract().call(&mut env.public());

    //checks that the contract has been unpaused correctly
    let ret = Token::at(token_contract_address).public_get_pause().view(&mut env.public());
    assert(ret == 0);
}


#[test(should_fail_with="Error: token contract is paused")]
unconstrained fn mint_when_paused_fails(){
    let (env, token_contract_address, issuer, user) = utils::setup(/* with_account_contracts */ false);

    let mint_amount = 10000;
    env.impersonate(issuer);

    Token::at(token_contract_address).grant_role(PAUSE_ROLE, issuer).call(&mut env.public());

    Token::at(token_contract_address).grant_role(MINTER_ROLE, issuer).call(&mut env.public());

    Token::at(token_contract_address).pause_contract().call(&mut env.public());

    let ret = Token::at(token_contract_address).public_get_pause().view(&mut env.public());
    assert(ret == 1);

    Token::at(token_contract_address).mint(issuer, mint_amount).call(&mut env.private());
}

#[test(should_fail_with="Error: token contract is paused")]
unconstrained fn transfer_when_paused_fails(){
    let (env, token_contract_address, issuer, user,_) = utils::setup_and_mint(/* with_account_contracts */ false);

    let mint_amount = 100;
    env.impersonate(issuer);

    Token::at(token_contract_address).grant_role(PAUSE_ROLE, issuer).call(&mut env.public());

    Token::at(token_contract_address).grant_role(MINTER_ROLE, issuer).call(&mut env.public());

    Token::at(token_contract_address).pause_contract().call(&mut env.public());

    let ret = Token::at(token_contract_address).public_get_pause().view(&mut env.public());
    assert(ret == 1);

    Token::at(token_contract_address).transfer(issuer, mint_amount).call(&mut env.private());
}


#[test(should_fail_with="error: contract already paused")]
unconstrained fn pause_twice_throws(){

    let (env, token_contract_address, issuer, user) = utils::setup(/* with_account_contracts */ false);
    
    Token::at(token_contract_address).grant_role(PAUSE_ROLE, issuer).call(&mut env.public());


    Token::at(token_contract_address).pause_contract().call(&mut env.public());


    Token::at(token_contract_address).pause_contract().call(&mut env.public());

}


//pause fails when caller does not have pause role
#[test(should_fail_with="AccessControlUnauthorizedAccount")]
unconstrained fn test_pause_roles(){
    let (env, token_contract_address, issuer, user) = utils::setup(/* with_account_contracts */ false);
    
    Token::at(token_contract_address).pause_contract().call(&mut env.public());
}

//owner has role when pause but not the role when unpause
#[test(should_fail_with="AccessControlUnauthorizedAccount")]
unconstrained fn test_pause_role_2(){
    let (env, token_contract_address, issuer, user) = utils::setup(/* with_account_contracts */ false);
    
    Token::at(token_contract_address).grant_role(PAUSE_ROLE, issuer).call(&mut env.public());

    Token::at(token_contract_address).pause_contract().call(&mut env.public());

    //checks if contract is indeed paused
    let ret = Token::at(token_contract_address).public_get_pause().view(&mut env.public());
    assert(ret == 1);

     Token::at(token_contract_address).revoke_role(PAUSE_ROLE, issuer).call(&mut env.public());

    Token::at(token_contract_address).unpause_contract().call(&mut env.public());
}
