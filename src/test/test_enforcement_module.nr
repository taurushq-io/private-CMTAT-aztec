use crate::test::utils;
use dep::aztec::{test::helpers::cheatcodes, oracle::unsafe_rand::unsafe_rand, protocol_types::address::AztecAddress};
use dep::authwit::cheatcodes as authwit_cheatcodes;
use crate::Token;
use crate::types::enforcementModule::{Freezable, FreezableFlag};

#[test]
unconstrained fn get_frozen(){
    let (env, token_contract_address, issuer, _) = utils::setup(/* with_account_contracts */ false);

    let get_roles_call_interface = Token::at(token_contract_address).get_frozen(issuer);
    let ret = env.call_public(get_roles_call_interface);
    assert(ret == 0);
}

#[test]
unconstrained fn can_freeze(){
    let (env, token_contract_address, issuer, user) = utils::setup(/* with_account_contracts */ false);

    let freezable_flag = FreezableFlag {is_freezed: true};
    let get_roles_call_interface = Token::at(token_contract_address).freeze(user,freezable_flag );
    env.call_public(get_roles_call_interface);
    env.advance_block_by(3);

    let get_roles_call_interface = Token::at(token_contract_address).get_frozen(user);
    let ret = env.call_public(get_roles_call_interface);

    assert(ret == 1);
}


#[test]
unconstrained fn can_unfreeze(){
    let (env, token_contract_address, issuer, user) = utils::setup(/* with_account_contracts */ false);

    let freezable_flag = FreezableFlag {is_freezed: true};
    let get_roles_call_interface = Token::at(token_contract_address).freeze(user,freezable_flag );
    env.call_public(get_roles_call_interface);
    env.advance_block_by(3);

    let get_roles_call_interface = Token::at(token_contract_address).get_frozen(user);
    let ret = env.call_public(get_roles_call_interface);

    assert(ret == 1);

    let unfreezable_flag = FreezableFlag {is_freezed: false};
    let get_roles_call_interface = Token::at(token_contract_address).unfreeze(user,unfreezable_flag );
    env.call_public(get_roles_call_interface);
    env.advance_block_by(3);

    let get_roles_call_interface = Token::at(token_contract_address).get_frozen(user);
    let ret = env.call_public(get_roles_call_interface);

    assert(ret == 0);
}

#[test(should_fail_with="Frozen: Recipient")]
unconstrained fn mint_restricted_when_freezed(){
    let (env, token_contract_address, issuer, user) = utils::setup(/* with_account_contracts */ false);

    let freezable_flag = FreezableFlag {is_freezed: true};
    let get_roles_call_interface = Token::at(token_contract_address).freeze(user,freezable_flag );
    env.call_public(get_roles_call_interface);
    env.advance_block_by(3);

    let get_roles_call_interface = Token::at(token_contract_address).get_frozen(user);
    let ret = env.call_public(get_roles_call_interface);

    assert(ret == 1);
    let mint_amount = 10000;
    let mint_private_call_interface = Token::at(token_contract_address).mint(user, mint_amount);
    env.call_private_void(mint_private_call_interface);
}

#[test(should_fail_with="Frozen: Recipient")]
unconstrained fn transfer_restricted_when_freezed(){
    let (env, token_contract_address, issuer, user, _) = utils::setup_and_mint(/* with_account_contracts */ false);

    let freezable_flag = FreezableFlag {is_freezed: true};
    let get_roles_call_interface = Token::at(token_contract_address).freeze(user,freezable_flag );
    env.call_public(get_roles_call_interface);
    env.advance_block_by(3);

    let get_roles_call_interface = Token::at(token_contract_address).get_frozen(user);
    let ret = env.call_public(get_roles_call_interface);

    assert(ret == 1);
    let transfer_amount = 10000;
    let mint_private_call_interface = Token::at(token_contract_address).transfer(user, transfer_amount);
    env.call_private_void(mint_private_call_interface);
}

#[test(should_fail_with="Frozen: Sender")]
unconstrained fn burn_restricted_when_freezed(){
    let (env, token_contract_address, issuer, user, _) = utils::setup_and_mint(/* with_account_contracts */ false);

    let transfer_amount = 10000;
    let mint_private_call_interface = Token::at(token_contract_address).transfer(user, transfer_amount);
    env.call_private_void(mint_private_call_interface);

    let freezable_flag = FreezableFlag {is_freezed: true};
    let get_roles_call_interface = Token::at(token_contract_address).freeze(user,freezable_flag );
    env.call_public(get_roles_call_interface);
    env.advance_block_by(3);

    let get_roles_call_interface = Token::at(token_contract_address).get_frozen(user);
    let ret = env.call_public(get_roles_call_interface);
    assert(ret == 1);

    let burn_amount = 10000;
    let mint_private_call_interface = Token::at(token_contract_address).burn(user, burn_amount, 1);
    env.impersonate(issuer);
    env.call_private_void(mint_private_call_interface);

}

