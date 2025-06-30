use crate::test::utils;
use crate::CMTAToken as Token;
use crate::modules::access_controlModule::MINTER_ROLE;


//TODO we do not test minter role yet because we know that it won't revert according to error that we have spotted.

#[test]
unconstrained fn mint_private_success() {
    // Setup without account contracts. We are not using authwits here, so dummy accounts are enough
    let (env, token_contract_address, issuer, _) = utils::setup(/* with_account_contracts */ false);

    Token::at(token_contract_address).grant_role(MINTER_ROLE, issuer).call(&mut env.public());

    let ret = Token::at(token_contract_address).has_role(MINTER_ROLE, issuer).view(&mut env.public());

    //issuer does have minter role
    assert(ret == 1);

    let mint_amount = 10000;
    Token::at(token_contract_address).mint(issuer, mint_amount).call(&mut env.private());

    utils::check_private_balance(token_contract_address, issuer, mint_amount);

    let total_supply = Token::at(token_contract_address).total_supply().view(&mut env.public());
    assert(total_supply == mint_amount);
}

#[test]
unconstrained fn mint_private_batch_success() {
    // Setup without account contracts. We are not using authwits here, so dummy accounts are enough
    let (env, token_contract_address, issuer, user1, _ , _) = utils::setup_and_more_addresses(/* with_account_contracts */ false);
    
    Token::at(token_contract_address).grant_role(MINTER_ROLE, issuer).call(&mut env.public());

    let mint_amount = [10000];
    let addresses = [user1];

    Token::at(token_contract_address).mint_batch(addresses, mint_amount).call(&mut env.private());

    utils::check_private_balance(token_contract_address, addresses[0], mint_amount[0]);

    let total_supply = Token::at(token_contract_address).total_supply().view(&mut env.public());

    let mut total_mint_amount = 0;
    for i in 0..1 {
        total_mint_amount += mint_amount[i];
    }

    assert(total_supply == total_mint_amount);
}


#[test(should_fail_with="Assertion failed: AccessControlUnauthorizedAccount")]
unconstrained fn mint_private_failure_non_minter() {
    // Setup without account contracts. We are not using authwits here, so dummy accounts are enough
    let (env, token_contract_address, _, user1) = utils::setup(/* with_account_contracts */ false);
    let mint_amount = 10000;
    // Try to mint some tokens impersonating user1
    env.impersonate(user1);

    Token::at(token_contract_address).mint(user1, mint_amount).call(&mut env.private());
}

//TODO: this test does not fail

#[test(should_fail_with="call to assert_max_bit_size")]
unconstrained fn mint_private_failure_overflow() {
    // Setup without account contracts. We are not using authwits here, so dummy accounts are enough
    let (env, token_contract_address, issuer, _) = utils::setup(/* with_account_contracts */ false);

    Token::at(token_contract_address).grant_role(MINTER_ROLE, issuer).call(&mut env.public());

    // Overflow user1
    // We have to do this in 2 steps because we have to pass in a valid u128
    let amount_until_overflow = 1000 as u128;
    let mint_amount = (2.pow_32(128) - amount_until_overflow as Field) as u128;
    Token::at(token_contract_address).mint(issuer, mint_amount).call(&mut env.private());
}

//TODO: this test does not fail


// #[test(should_fail_with="attempt to add with overflow")]
// unconstrained fn mint_private_failure_overflow_recipient() {
//     // Setup without account contracts. We are not using authwits here, so dummy accounts are enough
//     let (env, token_contract_address, issuer, _) = utils::setup(/* with_account_contracts */ false);
//     let mint_amount = 10000;
//     // Mint some tokens
//     let mint_private_call_interface = Token::at(token_contract_address).mint(issuer, mint_amount);
//     env.call_private_void(mint_private_call_interface);

//     // TODO: understand: Time travel so we can read keys from the registry - ?? Don't understand this
//     env.advance_block_by(6);

//     utils::check_private_balance(token_contract_address, issuer, mint_amount);

//     let mint_amount = 2.pow_32(128)-mint_amount;
//     let mint_private_call_interface = Token::at(token_contract_address).mint(issuer, mint_amount);
//     env.call_private_void(mint_private_call_interface);

//     let total_supply_call_interface = Token::at(token_contract_address).total_supply();
//     let total_supply = env.call_public(total_supply_call_interface);

//     std::println(total_supply);

// }
