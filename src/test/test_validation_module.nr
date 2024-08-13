use crate::test::utils;
use dep::aztec::{test::helpers::cheatcodes, oracle::unsafe_rand::unsafe_rand, protocol_types::address::AztecAddress};
use dep::authwit::cheatcodes as authwit_cheatcodes;
use crate::Token;
use crate::types::validationModule::{SetFlag, UserFlags, ValidationModule};




#[test]
unconstrained fn get_operations_test(){
    let (env, token_contract_address, issuer, _) = utils::setup(/* with_account_contracts */ false);

    let get_roles_call_interface = Token::at(token_contract_address).get_operations();
    let ret = env.call_public(get_roles_call_interface);
    assert(ret == 0);
}

#[test]
unconstrained fn set_operations_test(){
    let (env, token_contract_address, issuer, user) = utils::setup(/* with_account_contracts */ false);

    let operations = SetFlag {    operate_blacklist: true,operate_whitelist: false,operate_sanctionlist: false,};
    let set_operations_call_interface = Token::at(token_contract_address).set_operations(operations);
    env.call_public(set_operations_call_interface);
    env.advance_block_by(3);

    let get_operations_call_interface = Token::at(token_contract_address).get_operations();
    let ret = env.call_public(get_operations_call_interface);
    assert(ret == 1);
}

#[test(should_fail_with="The recipient is in the blacklist")]
unconstrained fn transfer_when_blacklisted(){
    let (env, token_contract_address, issuer, user) = utils::setup_and_mint(/* with_account_contracts */ false);

    let operations = SetFlag {    operate_blacklist: true,operate_whitelist: false,operate_sanctionlist: false,};
    let set_operations_call_interface = Token::at(token_contract_address).set_operations(operations);
    env.call_public(set_operations_call_interface);
    env.advance_block_by(3);

    let get_operations_call_interface = Token::at(token_contract_address).get_operations();
    let ret = env.call_public(get_operations_call_interface);
    assert(ret == 1);

    let userFlag = UserFlags {is_blacklisted: true,is_whitelisted: false,is_in_sanction_list: false,};
    let add_toList_call = Token::at(token_contract_address).add_to_list(user, userFlag);
    env.call_public(add_toList_call);
    env.advance_block_by(3);

    let transfer_amount = 100;
    let transfer_private_call_interface = Token::at(token_contract_address).transfer(user, transfer_amount);
    env.call_private_void(transfer_private_call_interface);

}

#[test(should_fail_with="The sender is not in the whitelist")]
unconstrained fn transfer_when_not_whitelisted(){
    let (env, token_contract_address, issuer, user) = utils::setup_and_mint(/* with_account_contracts */ false);

    let operations = SetFlag {    operate_blacklist: false,operate_whitelist: true,operate_sanctionlist: false,};
    let set_operations_call_interface = Token::at(token_contract_address).set_operations(operations);
    env.call_public(set_operations_call_interface);
    env.advance_block_by(3);

    let get_operations_call_interface = Token::at(token_contract_address).get_operations();
    let ret = env.call_public(get_operations_call_interface);
    assert(ret == 2);

    let transfer_amount = 100;
    let transfer_private_call_interface = Token::at(token_contract_address).transfer(user, transfer_amount);
    env.call_private_void(transfer_private_call_interface);

}

#[test]
unconstrained fn transfer_when_no_operations(){
    let (env, token_contract_address, issuer, user) = utils::setup_and_mint(/* with_account_contracts */ false);


    let get_operations_call_interface = Token::at(token_contract_address).get_operations();
    let ret = env.call_public(get_operations_call_interface);
    assert(ret == 0);

    let transfer_amount = 100;
    let transfer_private_call_interface = Token::at(token_contract_address).transfer(user, transfer_amount);
    env.call_private_void(transfer_private_call_interface);

}
