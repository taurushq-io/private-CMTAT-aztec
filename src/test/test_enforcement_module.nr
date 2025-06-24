use crate::test::utils;
use dep::aztec::{test::helpers::cheatcodes};
use dep::authwit::cheatcodes as authwit_cheatcodes;
use crate::FiatCMTAToken as Token;
use crate::types::enforcementModule::{FreezableFlag};
use crate::types::access_controlModule::{DEFAULT_ADMIN_ROLE, ENFORCEMENT_ROLE};

#[test]
unconstrained fn get_frozen(){
    let (env, token_contract_address, issuer, _) = utils::setup(/* with_account_contracts */ false);

    let ret = Token::at(token_contract_address).get_frozen(issuer).view(&mut env.public());
    assert(ret == 0);
}

#[test]
unconstrained fn can_freeze(){
    let (env, token_contract_address, issuer, user) = utils::setup(/* with_account_contracts */ false);

     Token::at(token_contract_address).grant_role(ENFORCEMENT_ROLE, issuer).call(&mut env.public());

    let freezable_flag = FreezableFlag {is_freezed: true};
    let get_roles_call_interface = Token::at(token_contract_address).freeze(user,freezable_flag );
    get_roles_call_interface.call(&mut env.public());
    env.advance_block_by(3);

    let get_roles_call_interface = Token::at(token_contract_address).get_frozen(user);
    let ret = get_roles_call_interface.view(&mut env.public());

    assert(ret == 1);
}


#[test]
unconstrained fn can_unfreeze(){
    let (env, token_contract_address, issuer, user) = utils::setup(/* with_account_contracts */ false);

    Token::at(token_contract_address).grant_role(ENFORCEMENT_ROLE, issuer).call(&mut env.public());

    let freezable_flag = FreezableFlag {is_freezed: true};
    Token::at(token_contract_address).freeze(user,freezable_flag ).call(&mut env.public());
    env.advance_block_by(3);

    let ret = Token::at(token_contract_address).get_frozen(user).view(&mut env.public());

    assert(ret == 1);

    let unfreezable_flag = FreezableFlag {is_freezed: false};
    Token::at(token_contract_address).unfreeze(user,unfreezable_flag ).call(&mut env.public());
    env.advance_block_by(3);

    let ret = Token::at(token_contract_address).get_frozen(user).view(&mut env.public());

    assert(ret == 0);
}

#[test(should_fail_with="Frozen: Recipient")]
unconstrained fn mint_restricted_when_freezed(){
    let (env, token_contract_address, issuer, user) = utils::setup(/* with_account_contracts */ false);

     Token::at(token_contract_address).grant_role(ENFORCEMENT_ROLE, issuer).call(&mut env.public());

    let freezable_flag = FreezableFlag {is_freezed: true};
    Token::at(token_contract_address).freeze(user,freezable_flag ).call(&mut env.public());
    env.advance_block_by(3);

    let ret = Token::at(token_contract_address).get_frozen(user).view(&mut env.public());

    assert(ret == 1);
    let mint_amount = 10000;
     Token::at(token_contract_address).mint(user, mint_amount).call(&mut env.private());
}

#[test(should_fail_with="Frozen: Recipient")]
unconstrained fn transfer_restricted_when_freezed(){
    let (env, token_contract_address, issuer, user, _) = utils::setup_and_mint(/* with_account_contracts */ false);

    Token::at(token_contract_address).grant_role(ENFORCEMENT_ROLE, issuer).call(&mut env.public());

    let freezable_flag = FreezableFlag {is_freezed: true};
    Token::at(token_contract_address).freeze(user,freezable_flag ).call(&mut env.public());
    env.advance_block_by(3);

    let ret = Token::at(token_contract_address).get_frozen(user).view(&mut env.public());

    assert(ret == 1);
    let transfer_amount = 10000;
    Token::at(token_contract_address).transfer(user, transfer_amount).call(&mut env.private());
}

#[test(should_fail_with="Frozen: Sender")]
unconstrained fn burn_restricted_when_freezed(){
    let (env, token_contract_address, issuer, user, _) = utils::setup_and_mint(/* with_account_contracts */ false);

    Token::at(token_contract_address).grant_role(ENFORCEMENT_ROLE, issuer).call(&mut env.public());
    
    let transfer_amount = 10000;
    Token::at(token_contract_address).transfer(user, transfer_amount).call(&mut env.private());

    let freezable_flag = FreezableFlag {is_freezed: true};
    Token::at(token_contract_address).freeze(user,freezable_flag ).call(&mut env.public());
    env.advance_block_by(3);

    let ret = Token::at(token_contract_address).get_frozen(user).view(&mut env.public());
    assert(ret == 1);

    let burn_amount = 10000;
    let mint_private_call_interface = Token::at(token_contract_address).burn(user, burn_amount, 1);
    env.impersonate(issuer);
    mint_private_call_interface.call(&mut env.private());

}

