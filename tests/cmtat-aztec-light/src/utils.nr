use aztec::protocol::address::AztecAddress;
use aztec::test::helpers::test_environment::TestEnvironment;

use cmtat_aztec_lib::modules::access_controlModule::MINTER_ROLE;
// Contract-agnostic helpers live in the shared `cmtat_aztec_test_helpers` crate (analysis D-2); they
// are re-exported here so tests keep calling `utils::advance_past_delay` / `utils::call_private_on_behalf_of`.
pub use cmtat_aztec_test_helpers::{advance_past_delay, call_private_on_behalf_of};
use cmtat_aztec_light::CMTATAztecLight::CHANGE_ROLES_DELAY_SECONDS;
use cmtat_aztec_light::CMTATAztecLight as Token;

pub unconstrained fn setup(
    with_account_contracts: bool,
) -> (TestEnvironment, AztecAddress, AztecAddress, AztecAddress) {
    setup_with_public_side(with_account_contracts, /* public_side_enabled */ false)
}

/// `public_side_enabled` is the constructor flag that opens the four private/public bridges.
pub unconstrained fn setup_with_public_side(
    with_account_contracts: bool,
    public_side_enabled: bool,
) -> (TestEnvironment, AztecAddress, AztecAddress, AztecAddress) {
    // Setup env, generate keys
    let mut env = TestEnvironment::new();
    let (issuer, user1) = if with_account_contracts {
        let issuer = env.create_contract_account();
        let user1 = env.create_contract_account();
        (issuer, user1)
    } else {
        let issuer = env.create_light_account();
        let user1 = env.create_light_account();
        (issuer, user1)
    };

    // Deploy token contract
    let initializer_call = Token::interface().constructor(
        issuer,
        "TestToken0000000000000000000000",
        "TT00000000000000000000000000000",
        18,
        public_side_enabled,
    );
    let token_contract_address = env
        .deploy("@cmtat_aztec_light/CMTATAztecLight")
        .with_public_initializer(issuer, initializer_call);

    // The constructor only *schedules* the issuer address, because issuer_address is a
    // DelayedPublicMutable. Nothing that reads the issuer (every mint, transfer and burn does) works
    // until that delay has elapsed.
    advance_past_delay(env, CHANGE_ROLES_DELAY_SECONDS);

    (env, token_contract_address, issuer, user1)
}

pub unconstrained fn setup_and_more_addresses(
    with_account_contracts: bool,
) -> (TestEnvironment, AztecAddress, AztecAddress, AztecAddress, AztecAddress, AztecAddress) {
    // Setup
    let (mut env, token_contract_address, issuer, user1) = setup(with_account_contracts);

    let user2 = env.create_light_account();
    let user3 = env.create_light_account();

    (env, token_contract_address, issuer, user1, user2, user3)
}

pub unconstrained fn setup_and_mint(
    with_account_contracts: bool,
) -> (TestEnvironment, AztecAddress, AztecAddress, AztecAddress, u128) {
    // Setup
    let (env, token_contract_address, issuer, user1) = setup(with_account_contracts);
    let mint_amount = 10000 as u128;

    env.call_public(issuer, Token::at(token_contract_address).grant_role(MINTER_ROLE, issuer));
    env.call_private(issuer, Token::at(token_contract_address).mint_to_private(issuer, mint_amount));

    (env, token_contract_address, issuer, user1, mint_amount)
}

pub unconstrained fn check_private_balance(
    env: TestEnvironment,
    token_contract_address: AztecAddress,
    address: AztecAddress,
    address_amount: u128,
) {
    assert_eq(
        env.execute_utility(Token::at(token_contract_address).balance_of_private(address)),
        address_amount,
    );
}
