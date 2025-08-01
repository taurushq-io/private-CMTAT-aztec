use dep::aztec::{ prelude::AztecAddress,
    test::helpers::{cheatcodes, test_environment::TestEnvironment},
    oracle::execution::get_contract_address
};

use crate::{modules::{ access_controlModule::MINTER_ROLE}, CMTAToken as Token};

pub unconstrained fn setup(with_account_contracts: bool) -> (&mut TestEnvironment, AztecAddress, AztecAddress, AztecAddress) {
    // Setup env, generate keys
    let mut env = TestEnvironment::new();
    let (issuer, user1) = if with_account_contracts {
        let issuer = env.create_account_contract(1);
        let user1 = env.create_account_contract(2);        
        (issuer, user1)
    } else {
        let issuer = env.create_account(1);
        let user1 = env.create_account(2);
        (issuer, user1)
    };

    // Start the test in the account contract address
    env.impersonate(issuer);

    // Deploy token contract
    let initializer_call_interface = Token::interface().constructor(
        issuer,
        "TestToken0000000000000000000000",
        "TT00000000000000000000000000000",
        18
    );
    let token_contract = env.deploy_self("CMTAToken").with_public_void_initializer(issuer, initializer_call_interface);
    let token_contract_address = token_contract.to_address();
    env.advance_block_by(3);
    (&mut env, token_contract_address, issuer, user1)
}

pub unconstrained fn setup_and_more_addresses(with_account_contracts: bool) -> (&mut TestEnvironment, AztecAddress, AztecAddress, AztecAddress,AztecAddress,AztecAddress) {
    // Setup
    let (env, token_contract_address, issuer, user1) = setup(with_account_contracts);

        let user2 = env.create_account_contract(3);
        let user3 = env.create_account_contract(4); 

    (env, token_contract_address, issuer, user1,user2,user3)
}

pub unconstrained fn setup_and_mint(with_account_contracts: bool) -> (&mut TestEnvironment, AztecAddress, AztecAddress, AztecAddress, u128) {
    // Setup
    let (env, token_contract_address, issuer, user1) = setup(with_account_contracts);
    let mint_amount = 10000;

    Token::at(token_contract_address).grant_role(MINTER_ROLE, issuer).call(&mut env.public());

    Token::at(token_contract_address).mint(issuer, mint_amount).call(&mut env.private());

    (env, token_contract_address, issuer, user1, mint_amount)
}

// docs:start:txe_test_call_unconstrained
pub unconstrained fn check_private_balance(token_contract_address: AztecAddress, address: AztecAddress, address_amount: u128) {
    let current_contract_address = get_contract_address();
    cheatcodes::set_contract_address(token_contract_address);
    // Direct call to unconstrained
    let balance_of_private = Token::balance_of_private(address);
    assert(balance_of_private == address_amount, "Private balance is not correct");
    cheatcodes::set_contract_address(current_contract_address);
}
// docs:end:txe_test_call_unconstrained
