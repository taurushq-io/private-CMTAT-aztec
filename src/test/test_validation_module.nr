use crate::test::utils;
use dep::aztec::{test::helpers::cheatcodes, oracle::{execution::{get_block_number, get_contract_address}}};
use dep::authwit::cheatcodes as authwit_cheatcodes;
use crate::Token;
use crate::types::validationModule::{SetFlag, UserFlags, ValidationModule};
use crate::types::access_controlModule::{DEFAULT_ADMIN_ROLE, VALIDATION_ROLE, ADDRESS_LIST_ADD_ROLE, ADDRESS_LIST_REMOVE_ROLE, MINTER_ROLE};



#[test]
unconstrained fn get_operations_test(){
    let (env, token_contract_address, issuer, _) = utils::setup(/* with_account_contracts */ false);

    let ret = Token::at(token_contract_address).get_operations().view(&mut env.public());
    assert(ret == 0);
}

#[test]
unconstrained fn set_operations_test(){
    let (env, token_contract_address, issuer, user) = utils::setup(/* with_account_contracts */ false);

    Token::at(token_contract_address).grant_role(VALIDATION_ROLE, issuer).call(&mut env.public());

    let operations = SetFlag {    operate_blacklist: true,operate_whitelist: false,operate_sanctionlist: false,};
    Token::at(token_contract_address).set_operations(operations).call(&mut env.public());
    env.advance_block_by(3);

    let ret = Token::at(token_contract_address).get_operations().view(&mut env.public());
    assert(ret == 1);
}

#[test(should_fail_with="The recipient is in the blacklist")]
unconstrained fn transfer_when_blacklisted(){
    let (env, token_contract_address, issuer, user, _) = utils::setup_and_mint(/* with_account_contracts */ false);

    Token::at(token_contract_address).grant_role(VALIDATION_ROLE, issuer).call(&mut env.public());

    let operations = SetFlag {    operate_blacklist: true,operate_whitelist: false,operate_sanctionlist: false,};
    Token::at(token_contract_address).set_operations(operations).call(&mut env.public());
    env.advance_block_by(3);

    let ret = Token::at(token_contract_address).get_operations().view(&mut env.public());
    assert(ret == 1);

    Token::at(token_contract_address).grant_role(ADDRESS_LIST_ADD_ROLE, issuer).call(&mut env.public());

    let userFlag = UserFlags {is_blacklisted: true,is_whitelisted: false,is_in_sanction_list: false,};
    Token::at(token_contract_address).add_to_list(user, userFlag).call(&mut env.public());
    env.advance_block_by(3);

    let transfer_amount = 100;
    Token::at(token_contract_address).transfer(user, transfer_amount).call(&mut env.private());

}

#[test(should_fail_with="The sender is not in the whitelist")]
unconstrained fn transfer_when_not_whitelisted(){
    let (env, token_contract_address, issuer, user, _) = utils::setup_and_mint(/* with_account_contracts */ false);

    Token::at(token_contract_address).grant_role(VALIDATION_ROLE, issuer).call(&mut env.public());

    let operations = SetFlag {    operate_blacklist: false,operate_whitelist: true,operate_sanctionlist: false,};
    Token::at(token_contract_address).set_operations(operations).call(&mut env.public());
    env.advance_block_by(3);

    let ret = Token::at(token_contract_address).get_operations().view(&mut env.public());
    assert(ret == 2);

    let transfer_amount = 100;
    Token::at(token_contract_address).transfer(user, transfer_amount).call(&mut env.private());

}

#[test]
unconstrained fn transfer_when_no_operations(){
    let (env, token_contract_address, issuer, user, _) = utils::setup_and_mint(/* with_account_contracts */ false);


    let ret = Token::at(token_contract_address).get_operations().view(&mut env.public());
    assert(ret == 0);

    let transfer_amount = 100;
    Token::at(token_contract_address).transfer(user, transfer_amount).call(&mut env.private());

}

#[test(should_fail_with="The recipient is not in the whitelist")]
unconstrained fn can_remove_from_list_when_role(){
    let (env, token_contract_address, issuer, user, _) = utils::setup_and_mint(/* with_account_contracts */ false);

    Token::at(token_contract_address).grant_role(VALIDATION_ROLE, issuer).call(&mut env.public());

    let operations = SetFlag {operate_blacklist: false,operate_whitelist: true,operate_sanctionlist: false,};
    Token::at(token_contract_address).set_operations(operations).call(&mut env.public());
    env.advance_block_by(3);

    let ret = Token::at(token_contract_address).get_operations().view(&mut env.public());
    assert(ret == 2);

    Token::at(token_contract_address).grant_role(ADDRESS_LIST_ADD_ROLE, issuer).call(&mut env.public());

    Token::at(token_contract_address).grant_role(ADDRESS_LIST_REMOVE_ROLE, issuer).call(&mut env.public());

    let userFlag = UserFlags {is_blacklisted: false,is_whitelisted: true,is_in_sanction_list: false,};
    Token::at(token_contract_address).add_to_list(issuer, userFlag).call(&mut env.public());
    env.advance_block_by(3);

    let userFlag = UserFlags {is_blacklisted: false,is_whitelisted: true,is_in_sanction_list: false,};
    Token::at(token_contract_address).add_to_list(user, userFlag).call(&mut env.public());
    env.advance_block_by(3);

    let userFlag = UserFlags {is_blacklisted: false,is_whitelisted: false,is_in_sanction_list: false,};
    Token::at(token_contract_address).remove_from_list(user, userFlag).call(&mut env.public());
    env.advance_block_by(3);

    let transfer_amount = 100;
     Token::at(token_contract_address).transfer(user, transfer_amount).call(&mut env.private());
}
