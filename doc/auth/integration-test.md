# Integration test of the authorization contracts against the `aztec-standards` tokens

The fork under `submodules/aztec-standards` cannot be compiled in place (Trap 3 in [`upgrading-aztec-standards.md`](../technical/upgrading-aztec-standards.md): `nargo` resolves the outermost workspace, which is this repository's). The integration tests are therefore run in a copy of the fork with this repository's crates added to it. This file records how, and the test sources, so the run can be repeated after a fork or Aztec bump. Last run: fork `5433e9c`, Aztec 5.2.0, **10/10** (7 token, 3 multitoken).

## Set up the copy

```bash
repo=$(pwd)                                   # this repository's root
tmp=$(mktemp -d)
git -C submodules/aztec-standards archive HEAD | tar -x -C "$tmp"
mkdir -p "$tmp/cmtat/contracts"
cp -r lib test-helpers "$tmp/cmtat/"
cp -r contracts/cmtat-aztec-auth contracts/cmtat-aztec-auth-multitoken "$tmp/cmtat/contracts/"
cd "$tmp"
```

Add the two crates to the fork's workspace and make the tokens depend on them:

```bash
python3 - <<'PY'
s=open('Nargo.toml').read()
s=s.replace('"src/generic_proxy",\n]','"src/generic_proxy",\n"cmtat/contracts/cmtat-aztec-auth",\n"cmtat/contracts/cmtat-aztec-auth-multitoken",\n]')
open('Nargo.toml','w').write(s)
add={'src/token_contract':['cmtat_aztec_auth = { path = "../../cmtat/contracts/cmtat-aztec-auth" }'],
     'src/multitoken_contract':['cmtat_aztec_auth_multitoken = { path = "../../cmtat/contracts/cmtat-aztec-auth-multitoken" }']}
for pkg,deps in add.items():
    p=pkg+'/Nargo.toml'; t=open(p).read().rstrip('\n')
    for d in deps+['cmtat_aztec_lib = { path = "../../cmtat/lib" }']: t+='\n'+d
    open(p,'w').write(t+'\n')
    p=pkg+'/src/test.nr'; t=open(p).read().replace('mod authorization;','mod authorization;\nmod cmtat_auth;',1); open(p,'w').write(t)
PY
```

Then write the two test files below, and run:

```bash
aztec compile --workspace
aztec test --package token_contract cmtat_auth
aztec test --package multitoken_contract cmtat_auth
```

## `src/token_contract/src/test/cmtat_auth.nr`

```noir
use crate::test::utils::{self, mint_amount};
use crate::Token;
use aztec::protocol::address::AztecAddress;
use aztec::protocol::traits::ToField;
use aztec::test::helpers::test_environment::TestEnvironment;
use cmtat_aztec_auth::CMTATAztecAuth as Auth;
use cmtat_aztec_lib::modules::access_controlModule::{ADDRESS_LIST_ADD_ROLE, ENFORCEMENT_ROLE, PAUSE_ROLE};
use cmtat_aztec_lib::modules::validationModule::{SetFlag, UserFlags};
use cmtat_aztec_lib::modules::authorizationHookModule::{AIP20_BURN_PRIVATE_SELECTOR, AIP20_BURN_PUBLIC_SELECTOR};
use cmtat_aztec_lib::modules::enforcementModule::{CHANGE_ROLES_DELAY_SECONDS, FreezableFlag};

/// Deploys CMTATAztecAuth (admin = owner), then the token with it as auth_contract, minter = owner, and
/// mints `mint_amount` privately to owner.
unconstrained fn setup() -> (TestEnvironment, AztecAddress, AztecAddress, AztecAddress, AztecAddress) {
    let mut env = TestEnvironment::new();
    let owner = env.create_light_account();
    let recipient = env.create_light_account();
    let auth = env.deploy("@cmtat_aztec_auth/CMTATAztecAuth").with_public_initializer(owner, Auth::interface().constructor(owner));
    let token = utils::deploy_token_with_minter(&mut env, owner, owner, auth);
    utils::mint_to_private(env, token, owner, mint_amount, owner);
    (env, token, auth, owner, recipient)
}

#[test]
unconstrained fn selectors_match_the_token_interface() {
    let (_, token, _, owner, _) = setup();
    assert_eq(Token::at(token).burn_private(owner, 1, 0).selector.to_field(), AIP20_BURN_PRIVATE_SELECTOR);
    assert_eq(Token::at(token).burn_public(owner, 1, 0).selector.to_field(), AIP20_BURN_PUBLIC_SELECTOR);
}

#[test]
unconstrained fn private_transfer_passes_then_pause_blocks_it_and_burn_still_works() {
    let (env, token, auth, owner, recipient) = setup();
    env.call_private(owner, Token::at(token).transfer_private_to_private(owner, recipient, 1000, 0));
    utils::check_private_balance(env, token, recipient, 1000);

    env.call_public(owner, Auth::at(auth).grant_role(PAUSE_ROLE, owner));
    env.call_public(owner, Auth::at(auth).pause_contract());
    // burn still allowed while paused (CMTAT semantics)
    env.call_private(owner, Token::at(token).burn_private(owner, 500, 0));
    utils::check_private_balance(env, token, owner, mint_amount - 1500);
}

#[test(should_fail_with = "Error: contract is paused")]
unconstrained fn private_transfer_reverts_when_auth_paused() {
    let (env, token, auth, owner, recipient) = setup();
    env.call_public(owner, Auth::at(auth).grant_role(PAUSE_ROLE, owner));
    env.call_public(owner, Auth::at(auth).pause_contract());
    env.call_private(owner, Token::at(token).transfer_private_to_private(owner, recipient, 1000, 0));
}

#[test(should_fail_with = "Error: contract is deactivated")]
unconstrained fn private_burn_reverts_when_auth_deactivated() {
    let (env, token, auth, owner, _) = setup();
    env.call_public(owner, Auth::at(auth).grant_role(PAUSE_ROLE, owner));
    env.call_public(owner, Auth::at(auth).pause_contract());
    env.call_public(owner, Auth::at(auth).deactivate_contract());
    env.call_private(owner, Token::at(token).burn_private(owner, 500, 0));
}

#[test(should_fail_with = "Frozen: from address")]
unconstrained fn private_transfer_reverts_for_frozen_sender() {
    let (env, token, auth, owner, recipient) = setup();
    env.call_public(owner, Auth::at(auth).grant_role(ENFORCEMENT_ROLE, owner));
    env.call_public(owner, Auth::at(auth).freeze(owner, FreezableFlag { is_freezed: true }));
    env.advance_next_block_timestamp_by(CHANGE_ROLES_DELAY_SECONDS + 1);
    env.mine_block();
    env.call_private(owner, Token::at(token).transfer_private_to_private(owner, recipient, 1000, 0));
}

#[test(should_fail_with = "Error: contract is paused")]
unconstrained fn public_transfer_reverts_when_auth_paused() {
    let (env, token, auth, owner, recipient) = setup();
    env.call_private(owner, Token::at(token).transfer_private_to_public(owner, owner, 2000, 0));
    env.call_public(owner, Auth::at(auth).grant_role(PAUSE_ROLE, owner));
    env.call_public(owner, Auth::at(auth).pause_contract());
    env.call_public(owner, Token::at(token).transfer_public_to_public(owner, recipient, 1000, 0));
}

#[test(should_fail_with = "The sender is in the blacklist")]
unconstrained fn private_transfer_reverts_for_blacklisted_sender() {
    let (env, token, auth, owner, recipient) = setup();
    env.call_public(owner, Auth::at(auth).grant_role(ADDRESS_LIST_ADD_ROLE, owner));
    env.call_public(owner, Auth::at(auth).set_operations(SetFlag { operate_blacklist: true, operate_whitelist: false }));
    env.call_public(owner, Auth::at(auth).add_to_list(owner, UserFlags { is_blacklisted: true, is_whitelisted: false }));
    env.advance_next_block_timestamp_by(CHANGE_ROLES_DELAY_SECONDS + 1);
    env.mine_block();
    env.call_private(owner, Token::at(token).transfer_private_to_private(owner, recipient, 1000, 0));
}
```

## `src/multitoken_contract/src/test/cmtat_auth.nr`

```noir
use crate::test::utils;
use crate::MultiToken;
use aztec::protocol::address::AztecAddress;
use aztec::protocol::traits::ToField;
use aztec::test::helpers::test_environment::TestEnvironment;
use cmtat_aztec_auth_multitoken::CMTATAztecAuthMultiToken as Auth;
use cmtat_aztec_lib::modules::access_controlModule::PAUSE_ROLE;
use cmtat_aztec_lib::modules::authorizationHookModule::{ARC1155_BURN_PRIVATE_SELECTOR, ARC1155_BURN_PUBLIC_SELECTOR};

global ID: Field = 42;

unconstrained fn setup() -> (TestEnvironment, AztecAddress, AztecAddress, AztecAddress, AztecAddress) {
    let mut env = TestEnvironment::new();
    let owner = env.create_light_account();
    let recipient = env.create_light_account();
    let auth = env.deploy("@cmtat_aztec_auth_multitoken/CMTATAztecAuthMultiToken").with_public_initializer(owner, Auth::interface().constructor(owner));
    let token = utils::deploy_multitoken_with_minter(&mut env, owner, owner, auth);
    utils::mint_to_private(env, token, owner, ID, 10_000, owner);
    (env, token, auth, owner, recipient)
}

#[test]
unconstrained fn selectors_match_the_multitoken_interface() {
    let (_, token, _, owner, _) = setup();
    assert_eq(MultiToken::at(token).burn_private(owner, ID, 1, 0).selector.to_field(), ARC1155_BURN_PRIVATE_SELECTOR);
    assert_eq(MultiToken::at(token).burn_public(owner, ID, 1, 0).selector.to_field(), ARC1155_BURN_PUBLIC_SELECTOR);
}

#[test]
unconstrained fn transfer_passes_then_pause_blocks_it_and_burn_still_works() {
    let (env, token, auth, owner, recipient) = setup();
    env.call_private(owner, MultiToken::at(token).transfer_private_to_private(owner, recipient, ID, 1000, 0));
    env.call_public(owner, Auth::at(auth).grant_role(PAUSE_ROLE, owner));
    env.call_public(owner, Auth::at(auth).pause_contract());
    env.call_private(owner, MultiToken::at(token).burn_private(owner, ID, 500, 0));
}

#[test(should_fail_with = "Error: contract is paused")]
unconstrained fn private_transfer_reverts_when_auth_paused() {
    let (env, token, auth, owner, recipient) = setup();
    env.call_public(owner, Auth::at(auth).grant_role(PAUSE_ROLE, owner));
    env.call_public(owner, Auth::at(auth).pause_contract());
    env.call_private(owner, MultiToken::at(token).transfer_private_to_private(owner, recipient, ID, 1000, 0));
}
```
