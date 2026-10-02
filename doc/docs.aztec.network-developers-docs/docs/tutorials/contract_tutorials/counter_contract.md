# Counter contract

> Source: https://docs.aztec.network/developers/docs/tutorials/contract_tutorials/counter_contract

---

- [![Home](https://docs.aztec.network/img/Aztec_Symbol_Dark.png)![Home](https://docs.aztec.network/img/Aztec%20Symbol_Light.png)](https://docs.aztec.network/)
- Tutorials
- Contract Tutorials
- Counter contract

On this page
# Counter contract

In this guide, we will create our first Aztec.nr smart contract. We will build a simple private counter, where each account keeps its own counter as encrypted private state, so the count stays known only to you. This contract will get you started with the basic setup and syntax of Aztec.nr, but doesn't showcase all of the awesome stuff Aztec is capable of.

This tutorial is compatible with the Aztec version `v5.2.0`. Install the correct version with `VERSION=5.2.0 bash -i <(curl -sL https://install.aztec.network/5.2.0)`. Or if you'd like to use a different version, you can find the relevant tutorial by clicking the version dropdown at the top of the page.

## Prerequisites[​](#prerequisites)

- You have followed the [quickstart](https://docs.aztec.network/developers/getting_started_on_local_network)
- Running Aztec local network
- Installed [Noir LSP](https://docs.aztec.network/developers/docs/aztec-nr/installation) (optional)

## Set up a project[​](#set-up-a-project)

Run this to create a new contract project:

```
aztec new counter
```

Your structure should look like this:

```
.|-counter| |-Nargo.toml              <-- workspace root| |-counter_contract| | |-src| | | |-main.nr| | |-Nargo.toml            <-- contract package config| |-counter_test| | |-src| | | |-lib.nr| | |-Nargo.toml            <-- test package config
```

The `aztec new` command creates a two-crate workspace: a `counter_contract` crate for your contract and a `counter_test` crate for tests. The file `counter_contract/src/main.nr` will soon turn into our smart contract!

Add the following dependency to `counter_contract/Nargo.toml` under the existing `aztec` dependency:

```
[dependencies]aztec = { git="https://github.com/AztecProtocol/aztec-nr/", tag="v5.2.0", directory="aztec" }balance_set = { git="https://github.com/AztecProtocol/aztec-nr/", tag="v5.2.0", directory="balance-set" }
```

## Define the functions[​](#define-the-functions)

Go to `counter_contract/src/main.nr`, and replace the boilerplate code with this contract initialization:

```
use aztec::macros::aztec;#[aztec]pub contract Counter {}
```

This defines a contract called `Counter`.

Clear the scaffold's placeholder testThe scaffolded `counter_test/src/lib.nr` imports the default contract name (`Main`) we just renamed to `Counter`, so it now fails to compile. Tests aren't used in this tutorial, so replace its contents with a single-line stub to keep `aztec compile` clean:

```
// Tests are out of scope for this tutorial. See https://docs.aztec.network/aztec-nr/testing_contracts for examples.
```

## Imports[​](#imports)

We need to define some imports.

Write this inside your contract, ie inside these brackets:

```
pub contract Counter {    // imports go here!}
```

imports
```
use aztec::{    macros::{functions::{external, initializer}, storage::storage},    messages::delivery::MessageDelivery,    oracle::logging::debug_log_format,    protocol::{address::AztecAddress, traits::ToField},    state_vars::Owned,};use balance_set::BalanceSet;
```

> [Source code: docs/examples/contracts/counter_contract/src/main.nr#L7-L16](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/contracts/counter_contract/src/main.nr#L7-L16)

- `macros::{functions::{external, initializer}, storage::storage}`
Imports the macros needed to define function types (`external`, `initializer`) and the `storage` macro for declaring contract storage structures.
- `messages::delivery::MessageDelivery`
Imports `MessageDelivery` for specifying how note delivery should be handled (e.g., constrained onchain delivery).
- `oracle::logging::debug_log_format`
Imports a debug logging utility for printing formatted messages during contract execution.
- `protocol::{address::AztecAddress, traits::ToField}`
Brings in `AztecAddress` (used to identify accounts/contracts) and traits for converting values to field elements, necessary for serialization and formatting inside Aztec.
- `state_vars::Owned`
Brings in `Owned`, a wrapper for state variables that have a single owner.
- `use balance_set::BalanceSet`
Imports `BalanceSet` from the `balance_set` dependency, which provides functionality for managing private balances (used for our counter).

## Declare storage[​](#declare-storage)

Add this below the imports. It declares the storage variables for our contract. We use an `Owned` state variable wrapping a `BalanceSet` to manage private balances for each owner.

storage_struct
```
#[storage]struct Storage<Context> {    counters: Owned<BalanceSet<Context>, Context>,}
```

> [Source code: docs/examples/contracts/counter_contract/src/main.nr#L18-L23](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/contracts/counter_contract/src/main.nr#L18-L23)

## Keep the counter private[​](#keep-the-counter-private)

Now we’ve got a mechanism for storing our private state, we can start using it to ensure the privacy of balances.

Let’s create a constructor method to run on deployment that assigns an initial count to a specified owner. We name it `constructor` here, but the name is arbitrary; it is the `#[initializer]` decorator that marks it to run once when the contract is deployed. Write this:

constructor
```
#[initializer]#[external("private")]// We can name our initializer anything we want as long as it's marked as #[initializer]fn constructor(initial_value: u128, owner: AztecAddress) {    self.storage.counters.at(owner).add(initial_value).deliver(        MessageDelivery::onchain_constrained(),    );}
```

> [Source code: docs/examples/contracts/counter_contract/src/main.nr#L25-L34](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/contracts/counter_contract/src/main.nr#L25-L34)

This function accesses the counters from storage. It adds the `initial_value` to the `owner`'s counter using `at().add()`, then calls `.deliver(MessageDelivery::onchain_constrained())` to ensure the note is delivered onchain.

We have annotated this and other functions with `#[external("private")]` which are ABI macros so the compiler understands it will handle private inputs.

## Incrementing our counter[​](#incrementing-our-counter)

Now let's implement an `increment` function to increase the counter.

increment
```
#[external("private")]fn increment(owner: AztecAddress) {    debug_log_format("Incrementing counter for owner {0}", [owner.to_field()]);    self.storage.counters.at(owner).add(1).deliver(MessageDelivery::onchain_constrained());}
```

> [Source code: docs/examples/contracts/counter_contract/src/main.nr#L36-L42](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/contracts/counter_contract/src/main.nr#L36-L42)

The `increment` function works similarly to the `constructor`. It logs a debug message, then adds 1 to the `owner`'s counter and delivers the note onchain.

## Getting a counter[​](#getting-a-counter)

The last thing we need to implement is a function to retrieve a counter value.

get_counter
```
#[external("utility")]unconstrained fn get_counter(owner: AztecAddress) -> pub u128 {    self.storage.counters.at(owner).balance_of()}
```

> [Source code: docs/examples/contracts/counter_contract/src/main.nr#L44-L49](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/contracts/counter_contract/src/main.nr#L44-L49)

This is a `utility` function used to obtain the counter value outside of a transaction. We access the `owner`'s balance from the `counters` storage variable using `at(owner)`, then call `balance_of()` to retrieve the current count. This yields a private counter that only the owner can decrypt.

## Compile[​](#compile)

Now we've written a simple Aztec.nr smart contract, we can compile it.

### Compile the smart contract[​](#compile-the-smart-contract)

In the `./counter/` directory, run:

```
aztec compile
```

This command compiles your Noir contract and creates a `target` folder with a `.json` artifact inside.

After compiling, you can generate a TypeScript class using the `aztec codegen` command.

In the same directory, run this:

```
aztec codegen -o src/artifacts target
```

You can now use the artifact and/or the TS class in your Aztec.js!

## Next steps[​](#next-steps)

### Optional: learn more about concepts mentioned here[​](#optional-learn-more-about-concepts-mentioned-here)

- [Functions and annotations like `#[external("private")]`](https://docs.aztec.network/developers/docs/aztec-nr/framework-description/functions/function_transforms#private-functions)

[Edit this page](https://github.com/AztecProtocol/aztec-packages/edit/next/docs/docs-developers/docs/tutorials/contract_tutorials/counter_contract.md)