# Overview

> Source: https://docs.aztec.network/developers/docs/aztec-nr

---

- [![Home](https://docs.aztec.network/img/Aztec_Symbol_Dark.png)![Home](https://docs.aztec.network/img/Aztec%20Symbol_Light.png)](https://docs.aztec.network/)
- Aztec.nr

On this page
# Overview

Aztec.nr is a Noir framework used to develop and test Aztec smart contracts. It contains both high-level abstractions (state variables, messages) and low-level protocol primitives, providing granular control to developers if they want custom contracts.

tipIf you are already familiar with writing Aztec smart contracts and Aztec.nr, visit the [API reference](https://docs.aztec.network/aztec-nr-api/mainnet/).

## Motivation[​](#motivation)

Noir *can* be used to write circuits, but Aztec contracts are more complex than this. They include multiple external functions, each of a different type: circuits for private functions, AVM bytecode for public functions, and brillig bytecode for utility functions. The circuits for private functions also need to interact with the protocol's kernel circuits in specific ways, so manually writing them, and then combining everything into a contract artifact is involved work. Aztec.nr takes care of all of this heavy lifting and makes writing contracts as simple as marking functions with the corresponding attributes e.g. `#[external("private")]`.

It allows safe and easy implementation of well understood design patterns, such as the multiple kinds of private state variables, meaning developers don't need to understand the low-levels of how the protocol works. These features are optional, however, advanced developers are not prevented from building their own custom solutions.

## Design principles[​](#design-principles)

- Make it hard to shoot yourself in the foot by making it clear when something is unsafe.
- Dangerous actions should be easy to spot. e.g. ignoring return values or calling functions with the `_unsafe` prefix.
- This is achieved by having rails that intentionally trigger a developer's "WTF?" response, to ensure they understand what they're doing.

A good example of this is writing to private state variables. These functions return a `NoteMessage` struct, which results in a compiler error unless used. This is because writing to private state also requires sending an encrypted message with the new state to the people that need to access it - otherwise, because it is private, they will not even know the state changed.

```
storage.votes.insert(new_vote); // compiler error - unused NoteMessage return valuestorage.votes.insert(new_vote).deliver(MessageDelivery::onchain_constrained()); // deliver the note message onchain
```

## Contract Development[​](#contract-development)

### Prerequisites[​](#prerequisites)

- Install [Aztec Local Network and Tooling](https://docs.aztec.network/developers/getting_started_on_local_network)
- Install the [Noir VSCode Extension](https://docs.aztec.network/developers/docs/aztec-nr/installation) for syntax highlighting and error detection.

### Flow[​](#flow)

1. Write your contract and specify your contract dependencies. Create a new project with `aztec new my_project`, which scaffolds a workspace with two crates: a `my_project_contract` crate for your contract and a `my_project_test` crate for tests, with the `aztec` dependency already configured. If you need additional dependencies, add them to `my_project_contract/Nargo.toml`:

```
# my_project_contract/Nargo.toml[dependencies]aztec = { git="https://github.com/AztecProtocol/aztec-nr/", tag="v5.2.0", directory="aztec" }
```

Update your `my_project_contract/src/main.nr` contract file to use the Aztec.nr macros for writing contracts.

setup
```
use aztec::macros::aztec;#[aztec]pub contract Counter {
```

> [Source code: docs/examples/contracts/counter_contract/src/main.nr#L1-L6](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/contracts/counter_contract/src/main.nr#L1-L6)

and import dependencies from the Aztec.nr library.

imports
```
use aztec::{    macros::{functions::{external, initializer}, storage::storage},    messages::delivery::MessageDelivery,    oracle::logging::debug_log_format,    protocol::{address::AztecAddress, traits::ToField},    state_vars::Owned,};use balance_set::BalanceSet;
```

> [Source code: docs/examples/contracts/counter_contract/src/main.nr#L7-L16](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/contracts/counter_contract/src/main.nr#L7-L16)

infoYou can see a complete example of a simple counter contract written with Aztec.nr [here](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/contracts/counter_contract/src/main.nr).

1. [Profile](https://docs.aztec.network/developers/docs/aztec-nr/framework-description/advanced/how_to_profile_transactions) the private functions in your contract to get
a sense of how long generating client side proofs will take
2. Write unit tests [directly in Noir](https://docs.aztec.network/developers/docs/aztec-nr/testing_contracts) and end-to-end
tests [with TypeScript](https://docs.aztec.network/developers/docs/aztec-js/how_to_test)
3. [Compile](https://docs.aztec.network/developers/docs/aztec-nr/compiling_contracts) your contract
4. [Deploy](https://docs.aztec.network/developers/docs/aztec-js/how_to_deploy_contract) your contract with Aztec.js

## Section Contents[​](#section-contents)

[
## 📄️Noir VSCode Extension

Learn how to install and configure the Noir Language Server for a better development experience.

](https://docs.aztec.network/developers/docs/aztec-nr/installation)[
## 📄️Compiling Contracts

Compile your Aztec smart contracts into deployable artifacts using aztec command.

](https://docs.aztec.network/developers/docs/aztec-nr/compiling_contracts)[
## 📄️Contract Deployment Reference

A practical guide to determine which deployment steps your Aztec contract needs and when functions become callable.

](https://docs.aztec.network/developers/docs/aztec-nr/contract_readiness_states)[
## 🗃Framework Description

18 items

](https://docs.aztec.network/developers/docs/aztec-nr/framework-description/functions)[
## 📄️Logging from Contracts

Add log statements to your Aztec contracts and control log verbosity in tests and local networks.

](https://docs.aztec.network/developers/docs/aztec-nr/logging)[
## 📄️Debugging Aztec Code

This guide shows you how to debug issues in your Aztec contracts.

](https://docs.aztec.network/developers/docs/aztec-nr/debugging)[
## 📄️Testing Contracts

Write and run tests for your Aztec smart contracts using Noir's TestEnvironment.

](https://docs.aztec.network/developers/docs/aztec-nr/testing_contracts)[
## 🗃Standards

6 items

](https://docs.aztec.network/developers/docs/aztec-nr/standards)[
## 📄️Aztec.nr API Reference

Auto-generated API reference documentation for the Aztec.nr smart contract framework.

](https://docs.aztec.network/developers/docs/aztec-nr/api)**Tags:**
- [aztec.nr](https://docs.aztec.network/developers/tags/aztec-nr)
- [smart contracts](https://docs.aztec.network/developers/tags/smart-contracts)

[Edit this page](https://github.com/AztecProtocol/aztec-packages/edit/next/docs/docs-developers/docs/aztec-nr/index.md)