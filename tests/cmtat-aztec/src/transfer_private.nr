use crate::utils;
use aztec::test::helpers::authwit::add_private_authwit_from_call;
use cmtat_aztec::CMTATAztec as Token;

global AUTHWIT_NONCE: Field = 7;

#[test]
unconstrained fn transfer_private() {
    // Setup without account contracts. We are not using authwits here, so dummy accounts are enough
    let (env, token_contract_address, issuer, user1, mint_amount) =
        utils::setup_and_mint(/* with_account_contracts */ false);

    // Transfer tokens
    let transfer_amount = 100 as u128;
    env.call_private(
        issuer,
        Token::at(token_contract_address).transfer_private_to_private(
            issuer,
            user1,
            transfer_amount,
            0,
        ),
    );

    // Check balances
    utils::check_private_balance(
        env,
        token_contract_address,
        issuer,
        mint_amount - transfer_amount,
    );
    utils::check_private_balance(env, token_contract_address, user1, transfer_amount);
}

#[test]
unconstrained fn transfer_private_check_issuer_view() {
    // Setup without account contracts. We are not using authwits here, so dummy accounts are enough
    let (mut env, token_contract_address, issuer, user1, mint_amount) =
        utils::setup_and_mint(/* with_account_contracts */ false);

    // Transfer tokens
    let transfer_amount = 100 as u128;
    env.call_private(
        issuer,
        Token::at(token_contract_address).transfer_private_to_private(
            issuer,
            user1,
            2 * transfer_amount,
            0,
        ),
    );
    let user2 = env.create_light_account();

    env.call_private(
        user1,
        Token::at(token_contract_address).transfer_private_to_private(
            user1,
            user2,
            transfer_amount,
            0,
        ),
    );

    // Check balances
    utils::check_private_balance(
        env,
        token_contract_address,
        issuer,
        mint_amount - 2 * transfer_amount,
    );
    utils::check_private_balance(env, token_contract_address, user1, transfer_amount);
    utils::check_private_balance(env, token_contract_address, user2, transfer_amount);
}

#[test]
unconstrained fn transfer_private_to_self() {
    // Setup without account contracts. We are not using authwits here, so dummy accounts are enough
    let (env, token_contract_address, issuer, _, mint_amount) =
        utils::setup_and_mint(/* with_account_contracts */ false);

    // Transfer tokens
    let transfer_amount = 1000 as u128;
    env.call_private(
        issuer,
        Token::at(token_contract_address).transfer_private_to_private(
            issuer,
            issuer,
            transfer_amount,
            0,
        ),
    );

    // Check balances
    utils::check_private_balance(env, token_contract_address, issuer, mint_amount);
}

#[test]
unconstrained fn transfer_private_on_behalf_of_other() {
    // Setup with account contracts. Slower since we actually deploy them, but needed for authwits.
    let (env, token_contract_address, issuer, user1, mint_amount) =
        utils::setup_and_mint(/* with_account_contracts */ true);

    // user1 spends on the issuer's behalf, so msg_sender in the token differs from `from`
    let caller = user1;
    let transfer_amount = 1000 as u128;
    let transfer_call = Token::at(token_contract_address).transfer_private_to_private(
        issuer,
        user1,
        transfer_amount,
        AUTHWIT_NONCE,
    );
    add_private_authwit_from_call(env, issuer, caller, transfer_call);

    utils::call_private_on_behalf_of(env, caller, issuer, transfer_call);

    // Check balances
    utils::check_private_balance(
        env,
        token_contract_address,
        issuer,
        mint_amount - transfer_amount,
    );
    utils::check_private_balance(env, token_contract_address, user1, transfer_amount);
}

#[test(should_fail_with = "Balance too low")]
unconstrained fn transfer_private_failure_more_than_balance() {
    // Setup without account contracts. We are not using authwits here, so dummy accounts are enough
    let (env, token_contract_address, issuer, user1, mint_amount) =
        utils::setup_and_mint(/* with_account_contracts */ false);
    // Transfer tokens
    let transfer_amount = mint_amount + 1 as u128;
    env.call_private(
        issuer,
        Token::at(token_contract_address).transfer_private_to_private(
            issuer,
            user1,
            transfer_amount,
            0,
        ),
    );
}

/*
*
* the below test is only done with an array of 1 value, as otherwise private calls would exceed protocol limitations
*/
#[test]
unconstrained fn transfer_private_batch_success() {
    // Setup without account contracts. We are not using authwits here, so dummy accounts are enough
    let (env, token_contract_address, issuer, user1, mint_amount) =
        utils::setup_and_mint(/* with_account_contracts */ false);

    let total_transfer_amount = 460 as u128;

    env.call_private(
        issuer,
        Token::at(token_contract_address).transfer_batch(
            issuer,
            [user1, user1],
            [100 as u128, 360 as u128],
            0,
        ),
    );

    utils::check_private_balance(
        env,
        token_contract_address,
        issuer,
        mint_amount - total_transfer_amount,
    );
    utils::check_private_balance(env, token_contract_address, user1, total_transfer_amount);
}

#[test(should_fail_with = "Balance too low")]
unconstrained fn transfer_private_failure_on_behalf_of_more_than_balance() {
    // Setup with account contracts. Slower since we actually deploy them, but needed for authwits.
    let (env, token_contract_address, owner, recipient, mint_amount) =
        utils::setup_and_mint(/* with_account_contracts */ true);

    let caller = recipient;
    let transfer_amount = mint_amount + 1 as u128;
    let transfer_call = Token::at(token_contract_address).transfer_private_to_private(
        owner,
        recipient,
        transfer_amount,
        AUTHWIT_NONCE,
    );
    add_private_authwit_from_call(env, owner, caller, transfer_call);

    utils::call_private_on_behalf_of(env, caller, owner, transfer_call);
}

#[test(should_fail_with = "Unknown auth witness for message hash")]
unconstrained fn transfer_private_failure_on_behalf_of_other_without_approval() {
    // Setup with account contracts. Slower since we actually deploy them, but needed for authwits.
    let (env, token_contract_address, owner, recipient, _) =
        utils::setup_and_mint(/* with_account_contracts */ true);

    let caller = recipient;
    let transfer_amount = 1000 as u128;
    let transfer_call = Token::at(token_contract_address).transfer_private_to_private(
        owner,
        recipient,
        transfer_amount,
        AUTHWIT_NONCE,
    );
    // No authwit is added

    utils::call_private_on_behalf_of(env, caller, owner, transfer_call);
}

#[test(should_fail_with = "Unknown auth witness for message hash")]
unconstrained fn transfer_private_failure_on_behalf_of_other_wrong_caller() {
    // Setup with account contracts. Slower since we actually deploy them, but needed for authwits.
    let (env, token_contract_address, owner, recipient, _) =
        utils::setup_and_mint(/* with_account_contracts */ true);

    let caller = recipient;
    let transfer_amount = 1000 as u128;
    let transfer_call = Token::at(token_contract_address).transfer_private_to_private(
        owner,
        recipient,
        transfer_amount,
        AUTHWIT_NONCE,
    );
    // The authwit designates `owner` as the caller, but `recipient` is the one that calls
    add_private_authwit_from_call(env, owner, owner, transfer_call);

    utils::call_private_on_behalf_of(env, caller, owner, transfer_call);
}

#[test]
unconstrained fn transfer_private_to_non_deployed_account() {
    // Setup with account contracts, so that the recipient below is the only party without a deployed
    // account contract - a light account is exactly that.
    let (mut env, token_contract_address, issuer, _, mint_amount) =
        utils::setup_and_mint(/* with_account_contracts */ true);
    let not_deployed = env.create_light_account();

    // Transfer tokens
    let transfer_amount = 1000 as u128;
    env.call_private(
        issuer,
        Token::at(token_contract_address).transfer_private_to_private(
            issuer,
            not_deployed,
            transfer_amount,
            0,
        ),
    );

    // Check balances
    utils::check_private_balance(
        env,
        token_contract_address,
        issuer,
        mint_amount - transfer_amount,
    );
    utils::check_private_balance(env, token_contract_address, not_deployed, transfer_amount);
}
