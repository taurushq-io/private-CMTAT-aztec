use crate::utils;
use cmtat_aztec::CMTATAztec as Token;
use cmtat_aztec_lib::modules::access_controlModule::{DEFAULT_ADMIN_ROLE, MINTER_ROLE};

/// The constructor grants the deployer the admin role, so the deployer can grant further roles.
#[test]
unconstrained fn grant_role_by_admin_succeeds() {
    let (env, token_contract_address, issuer, user1) =
        utils::setup(/* with_account_contracts */ false);

    // The constructor's own grant is observable through has_role.
    let admin =
        env.view_public(Token::at(token_contract_address).has_role(DEFAULT_ADMIN_ROLE, issuer));
    assert(admin == 1);

    env.call_public(issuer, Token::at(token_contract_address).grant_role(MINTER_ROLE, user1));

    let granted = env.view_public(Token::at(token_contract_address).has_role(MINTER_ROLE, user1));
    assert(granted == 1);
}

/// Guards the authorisation path of `grant_role`. It is checked by `only_role_admin` on the module
/// and then written by the `_grant_role_internal` helper; if a refactor ever drops the check, the
/// write would still succeed and only this test would notice.
#[test(should_fail_with = "AccessControlUnauthorizedAccount")]
unconstrained fn grant_role_by_non_admin_fails() {
    let (env, token_contract_address, _, user1) = utils::setup(/* with_account_contracts */ false);

    env.call_public(user1, Token::at(token_contract_address).grant_role(MINTER_ROLE, user1));
}

/// `only_role` is an assertion exposed as an entry point, so it reads state and never writes.
/// Calling it through `view_public` is what pins its `#[view]`: without the attribute the call
/// does not type-check (`Expected type PublicStaticCall, found PublicCall`), so this test guards
/// the attribute at compile time rather than at run time.
#[test]
unconstrained fn only_role_passes_for_a_holder() {
    let (env, token_contract_address, issuer, _) = utils::setup(/* with_account_contracts */ false);

    env.view_public(Token::at(token_contract_address).only_role(DEFAULT_ADMIN_ROLE, issuer));
}

#[test(should_fail_with = "AccessControlUnauthorizedAccount")]
unconstrained fn only_role_reverts_for_a_non_holder() {
    let (env, token_contract_address, _, user1) = utils::setup(/* with_account_contracts */ false);

    env.view_public(Token::at(token_contract_address).only_role(DEFAULT_ADMIN_ROLE, user1));
}
