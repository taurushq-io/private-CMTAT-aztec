# Testing Contracts

> Source: https://docs.aztec.network/developers/docs/aztec-nr/testing_contracts

---

- [![Home](https://docs.aztec.network/img/Aztec_Symbol_Dark.png)![Home](https://docs.aztec.network/img/Aztec%20Symbol_Light.png)](https://docs.aztec.network/)
- [Aztec.nr](https://docs.aztec.network/developers/docs/aztec-nr)
- Testing Contracts

On this page
# Testing Contracts

This guide shows you how to test your Aztec smart contracts using Noir's `TestEnvironment` for fast, lightweight testing.

## Prerequisites[​](#prerequisites)

- An Aztec contract project with functions to test
- Basic understanding of Noir syntax

tipFor complex cross-chain or integration testing, see the [TypeScript testing guide](https://docs.aztec.network/developers/docs/aztec-js/how_to_test).

## Write Aztec contract tests[​](#write-aztec-contract-tests)

Use `TestEnvironment` from `aztec-nr` for contract unit testing:

- **Fast**: Lightweight environment with mocked components
- **Convenient**: Similar to Foundry for simple contract tests
- **Limited**: No rollup circuits or cross-chain messaging

For complex end-to-end tests, use [TypeScript testing](https://docs.aztec.network/developers/docs/aztec-js/how_to_test) with `aztec.js`.

## Run your tests[​](#run-your-tests)

Execute Aztec Noir tests using:

```
aztec test
```

### Test execution process[​](#test-execution-process)

1. Compile contracts
2. Run `aztec test`

warningAlways use `aztec test` instead of `nargo test`. The `TestEnvironment` requires the test environment oracle resolver provided by the `aztec` CLI.

## Keep tests in the test crate[​](#keep-tests-in-the-test-crate)

`aztec new` and `aztec init` scaffold a workspace with two crates: a contract crate and a separate test crate. For `aztec new my_project`, these are `my_project_contract` and `my_project_test`. Keep all `#[test]` functions in the test crate, not in the contract crate.

If tests end up inside a contract crate, `aztec compile` emits a warning:

```
WARNING: Found tests in contract crate(s):  my_project_contract::test_somethingTests should be in a dedicated test crate, not in the contract crate.
```

The reason is **unnecessary recompilation**: a contract's compiled artifact depends on everything in its crate, so a test-only edit forces the contract to recompile even though its logic has not changed. Keeping tests in the separate test crate lets `aztec test` skip contract recompilation when only test code changed.

## Basic test structure[​](#basic-test-structure)

`aztec new my_project` scaffolds a workspace with two crates: a `contract` crate that holds the contract code, and a separate `test` crate that holds your `#[test]` functions:

```
my_project/├── Nargo.toml                 # [workspace] members = ["my_project_contract", "my_project_test"]├── my_project_contract/│   ├── Nargo.toml             # type = "contract"│   └── src/main.nr└── my_project_test/    ├── Nargo.toml             # type = "lib", depends on my_project_contract    └── src/lib.nr             # #[test] functions go here
```

The motivation for the split of contract and tests into its own crates is **faster iteration**: editing a test does not invalidate the contract's compiled artifact, so `aztec test` skips contract recompilation when only test code changed.

`aztec compile` warns if it finds `#[test]` functions inside a contract crate.

The generated test crate template imports the contract by package name and then initializes it:

```
// my_project_test/src/lib.nruse aztec::test::helpers::test_environment::TestEnvironment;use my_project_contract::Main;#[test]unconstrained fn test_constructor() {    let mut env = TestEnvironment::new();    let deployer = env.create_light_account();    let _contract_address = env.deploy("@my_project_contract/Main")        .with_private_initializer(deployer, Main::interface().constructor());}
```

Because tests live in their own crate, we refer to the contract via its crate name using the `@crate_name/ContractName` syntax.

Test execution notes
- Tests run in parallel by default
- Use `unconstrained` functions for faster execution
- See all `TestEnvironment` methods [here](https://docs.aztec.network/aztec-nr-api/mainnet/noir_aztec/test/helpers/test_environment/struct.TestEnvironment)
- It is always necessary to deploy a contract in order to test it

If you'll add arguments to your contract's constructor you pass them directly to the constructor function in the test:

```
let initializer = MyContract::interface().constructor(param1, param2);
```

Since Aztec contracts can be initialized both in private and public or they can be interacted with without any kind of initialization (see [Contract creation](https://docs.aztec.network/developers/docs/foundational-topics/contract_creation) for how Aztec's deployment model differs from Ethereum's) there are 3 options on the deployer:

```
let contract_address = deployer.with_private_initializer(owner, initializer);let contract_address = deployer.with_public_initializer(owner, initializer);let contract_address = deployer.without_initializer();
```

Reusable setup functionsCreate a setup function to avoid repeating initialization code:

```
pub unconstrained fn setup(initial_value: Field) -> (TestEnvironment, AztecAddress, AztecAddress) {    let mut env = TestEnvironment::new();    let owner = env.create_light_account();    let initializer = MyContract::interface().constructor(initial_value, owner);    let contract_address = env.deploy("@my_project_contract/MyContract").with_private_initializer(owner, initializer);    (env, contract_address, owner)}#[test]unconstrained fn test_something() {    let (env, contract_address, owner) = setup(42);    // Your test logic here}
```

## Calling contract functions[​](#calling-contract-functions)

TestEnvironment provides methods for different function types:

### Private functions[​](#private-functions)

```
// Call private functionenv.call_private(caller, Token::at(token_address).transfer(recipient, 100));// Returns the resultlet result = env.call_private(owner, Contract::at(address).get_private_data());
```

### Public functions[​](#public-functions)

```
// Call public functionenv.call_public(caller, Token::at(token_address).mint_to_public(recipient, 100));// View public state (read-only)let balance = env.view_public(Token::at(token_address).balance_of_public(owner));
```

### Utility/Unconstrained functions[​](#utilityunconstrained-functions)

```
// Simulate utility/view functions (unconstrained)let total = env.execute_utility(Token::at(token_address).balance_of_private(owner));// To set the `msg_sender` the utility function observes, use the `_opts` variantlet secret = env.execute_utility_opts(    ExecuteUtilityOptions::new().with_from(caller),    Registry::at(registry_address).get_app_siloed_secret(sender, recipient),).map(|secrets| secrets.shared);
```

Helper function patternCreate helper functions for common assertions:

```
pub unconstrained fn check_balance(    env: TestEnvironment,    token_address: AztecAddress,    owner: AztecAddress,    expected: u128,) {    assert_eq(        env.execute_utility(Token::at(token_address).balance_of_private(owner)),        expected    );}
```

## Creating accounts[​](#creating-accounts)

Two types of accounts are available:

```
// Light account - fast, limited featureslet owner = env.create_light_account();// Contract account - full features, slowerlet owner = env.create_contract_account();
```

Account type comparison**Light accounts:**

- Fast to create
- Work for simple transfers and tests
- Cannot process authwits
- No account contract deployed

**Contract accounts:**

- Required for authwit testing
- Support account abstraction features
- Slower to create (deploys account contract)
- Needed for cross-contract authorization

Choosing account types
```
pub unconstrained fn setup(with_authwits: bool) -> (TestEnvironment, AztecAddress, AztecAddress) {    let mut env = TestEnvironment::new();    let (owner, recipient) = if with_authwits {        (env.create_contract_account(), env.create_contract_account())    } else {        (env.create_light_account(), env.create_light_account())    };    // ... deploy contracts ...    (env, owner, recipient)}
```

## Testing with authwits[​](#testing-with-authwits)

[Authwits](https://docs.aztec.network/developers/docs/aztec-nr/framework-description/authentication_witnesses) allow one account to authorize another to act on its behalf.

warningAuthwits require **contract accounts**, not light accounts.

### Import authwit helpers[​](#import-authwit-helpers)

```
use aztec::test::helpers::authwit::{    add_private_authwit_from_call,    add_public_authwit_from_call,};
```

### Private authwits[​](#private-authwits)

```
#[test]unconstrained fn test_private_authwit() {    // Setup with contract accounts (required for authwits)    let (env, token_address, owner, spender) = setup(true);    // Create the call that needs authorization    let amount = 100;    let nonce = 7; // Non-zero nonce for authwit    let burn_call = Token::at(token_address).burn_private(owner, amount, nonce);    // Grant authorization from owner to spender    add_private_authwit_from_call(env, owner, spender, burn_call);    // Spender can now execute the authorized action    env.call_private(spender, burn_call);}
```

### Public authwits[​](#public-authwits)

```
#[test]unconstrained fn test_public_authwit() {    let (env, token_address, owner, spender) = setup(true);    // Create public action that needs authorization    let transfer_call = Token::at(token_address).transfer_in_public(owner, recipient, 100, nonce);    // Grant public authorization    add_public_authwit_from_call(env, owner, spender, transfer_call);    // Execute with authorization    env.call_public(spender, transfer_call);}
```

## Time traveling[​](#time-traveling)

Contract calls do not advance the timestamp by default, despite each of them resulting in a block with a single transaction. Block timestamp can instead be manually manipulated by any of the following methods:

```
// Sets the timestamp of the next block to be mined, i.e. of the next public execution. Does not affect private execution.env.set_next_block_timestamp(block_timestamp);// Same as `set_next_block_timestamp`, but moving time forward by `duration` instead of advancing to a target timestamp.env.advance_next_block_timestamp_by(duration);// Mines an empty block at a given timestamp, causing the next public execution to occur at this time (like `set_next_block_timestamp`), but also allowing for private execution to happen using this empty block as the anchor block.env.mine_block_at(block_timestamp);
```

## Testing failure cases[​](#testing-failure-cases)

Test functions that should fail using annotations:

### Generic failure[​](#generic-failure)

```
#[test(should_fail)]unconstrained fn test_unauthorized_access() {    let (env, contract, owner) = setup(false);    let attacker = env.create_light_account();    // This should fail because attacker is not authorized    env.call_private(attacker, Contract::at(contract).owner_only_function());}
```

### Specific error message[​](#specific-error-message)

```
#[test(should_fail_with = "Balance too low")]unconstrained fn test_insufficient_balance() {    let (env, token, owner, recipient) = setup(false);    // Try to transfer more than available    let balance = 100;    let transfer_amount = 101;    env.call_private(owner, Token::at(token).transfer(recipient, transfer_amount));}
```

### Testing authwit failures[​](#testing-authwit-failures)

```
#[test(should_fail_with = "Unknown auth witness for message hash")]unconstrained fn test_missing_authwit() {    let (env, token, owner, spender) = setup(true);    // Try to burn without authorization    let burn_call = Token::at(token).burn_private(owner, 100, 1);    // No authwit granted - this should fail    env.call_private(spender, burn_call);}
```

## Test environment oracle versioning[​](#test-environment-oracle-versioning)

The test environment uses an oracle interface to communicate between your Noir test code and the `aztec test` CLI. This interface is versioned so that mismatches between the Aztec.nr dependency used to compile the test and the CLI version are detected automatically.

The version uses two components, `major.minor`, with the same compatibility rules as [PXE oracle versioning](https://docs.aztec.network/developers/docs/foundational-topics/pxe#oracle-versioning):

- **`major`** must match exactly. A major bump means oracles were removed or had their signatures changed, and a test environment on a different major cannot safely run the test.
- **`minor`** indicates additive changes (new oracles). The test environment uses a best-effort approach: a test compiled against a higher `minor` is still allowed to run, and an error is only thrown if the test actually invokes an oracle the test environment does not know about.

### Resolving a version mismatch[​](#resolving-a-version-mismatch)

If you see an error like *"Incompatible test environment version: The test was compiled with a newer version of Aztec.nr than your test environment supports"*, the test uses oracles from a newer Aztec.nr than your `aztec test` CLI supports.

To fix it, make sure your `aztec` CLI version and the `aztec` dependency in the test crate's `Nargo.toml` are on the same release. Note that the test crate's Aztec.nr version can differ from the contract crate's version, depending on your project configuration. For example, if your CLI is on `v5.2.0`, the test crate's `Nargo.toml` should reference the matching tag:

```
[dependencies]aztec = { git="https://github.com/AztecProtocol/aztec-nr", tag="v5.2.0", directory="aztec" }
```

If the test environment reports a version that *should* include every oracle the test needs but an oracle is still missing, this is likely a bug rather than a version problem.

**Tags:**
- [contracts](https://docs.aztec.network/developers/tags/contracts)
- [tests](https://docs.aztec.network/developers/tags/tests)
- [testing](https://docs.aztec.network/developers/tags/testing)
- [noir](https://docs.aztec.network/developers/tags/noir)

[Edit this page](https://github.com/AztecProtocol/aztec-packages/edit/next/docs/docs-developers/docs/aztec-nr/testing_contracts.md)