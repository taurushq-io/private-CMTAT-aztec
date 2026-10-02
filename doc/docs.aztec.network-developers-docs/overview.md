# Aztec Overview

> Source: https://docs.aztec.network/developers/overview

---

- [![Home](https://docs.aztec.network/img/Aztec_Symbol_Dark.png)![Home](https://docs.aztec.network/img/Aztec%20Symbol_Light.png)](https://docs.aztec.network/)
- Aztec Overview

On this page
# Aztec Overview

This page outlines Aztec's fundamental technical concepts. It is recommended to read this before diving into building on Aztec.

## What is Aztec?[​](#what-is-aztec)

Aztec is a privacy-first Layer 2 on Ethereum. It supports smart contracts with both private & public state and private & public execution.

![image](https://docs.aztec.network/assets/ideal-img/Aztec_overview.4d3e9fb.640.png)

## Getting started[​](#getting-started)

Learn about Aztec, what it is, how it works and how to get start writing smart contracts on Aztec with programmable privacy by watching this video course:

## High level view[​](#high-level-view)

![image](https://docs.aztec.network/assets/ideal-img/aztec-high-level.4ac0d53.640.png)

1. A user interacts with Aztec through Aztec.js (like web3js or ethersjs)
2. Private functions are executed in the PXE, which is client-side
3. Proofs and tree updates are sent to the Public VM (running on an Aztec node)
4. Public functions are executed in the Public VM
5. The Public VM rolls up the transactions that include private and public state updates into blocks
6. The block data and proof of a correct state transition are submitted to Ethereum for verification

## Private and public execution[​](#private-and-public-execution)

Private functions are executed client side, on user devices to maintain maximum privacy. Public functions are executed by a remote network of nodes, similar to other blockchains. These distinct execution environments create a directional execution flow for a single transaction--a transaction begins in the private context on the user's device then moves to the public network. This means that private functions executed by a transaction can enqueue public functions to be executed later in the transaction life cycle, but public functions cannot call private functions.

### Private Execution Environment (PXE)[​](#private-execution-environment-pxe)

Private functions are executed on the user's device in the Private Execution Environment (PXE, pronounced 'pixie'), then it generates proofs for onchain verification. It is a client-side library for execution and proof-generation of private operations. It holds keys, notes, and generates proofs. It is included in aztec.js, a TypeScript library, and can be run within Node or the browser.

Note: It is easy for private functions to be written in a detrimentally unoptimized way, because many intuitions of regular program execution do not apply to proving. For more about writing performant private functions in Noir, see [this page](https://noir-lang.org/docs/explainers/explainer-writing-noir) of the Noir documentation.

### Aztec Virtual Machine (AVM)[​](#aztec-virtual-machine-avm)

Public functions are executed by the Aztec Virtual Machine (AVM), which is conceptually similar to the Ethereum Virtual Machine (EVM). As such, writing efficient public functions follow the same intuition as gas-efficient solidity contracts.

The PXE is unaware of the Public VM. And the Public VM is unaware of the PXE. They are completely separate execution environments. This means:

- The PXE and the Public VM cannot directly communicate with each other
- Private transactions in the PXE are executed first, followed by public transactions

## Private and public state[​](#private-and-public-state)

Private state works with UTXOs, which are chunks of data that we call notes. To keep things private, notes are stored in an [append-only UTXO tree](https://docs.aztec.network/developers/docs/foundational-topics/advanced/storage/indexed_merkle_tree), and a nullifier is created when notes are invalidated (aka deleted). Nullifiers are stored in their own [nullifier tree](https://docs.aztec.network/developers/docs/foundational-topics/advanced/storage/indexed_merkle_tree).

Public state works similarly to other chains like Ethereum, behaving like a public ledger. Public data is stored in a public data tree.

![Public vs private state](https://docs.aztec.network/assets/images/public-and-private-state-diagram-ff88262b40b259d4fe4c8b7d667924aa.png)

Aztec [smart contract](https://docs.aztec.network/developers/docs/aztec-nr/framework-description/contract_structure) developers should keep in mind that different data types are used when manipulating private or public state. Working with private state is creating commitments and nullifiers to state, whereas working with public state is directly updating state.

## Accounts and keys[​](#accounts-and-keys)

### Account abstraction[​](#account-abstraction)

Every account in Aztec is a smart contract (account abstraction). This allows implementing different schemes for authorizing transactions, nonce management, and fee payments.

Developers can write their own account contract to define the rules by which user transactions are authorized and paid for, as well as how user keys are managed.

Learn more about account contracts [here](https://docs.aztec.network/developers/docs/foundational-topics/accounts).

### Key pairs[​](#key-pairs)

Each account in Aztec is backed by 3 key pairs:

- A **nullifier key pair** used for note nullifier computation
- A **incoming viewing key pair** used to encrypt a note for the recipient
- A **outgoing viewing key pair** used to encrypt a note for the sender

As Aztec has native account abstraction, accounts do not automatically have a signing key pair to authenticate transactions. This is up to the account contract developer to implement.

## Noir[​](#noir)

Noir is a zero-knowledge domain specific language used for writing smart contracts for the Aztec network. It is also possible to write circuits with Noir that can be verified on or offchain. For more in-depth docs into the features of Noir, go to the [Noir website](https://noir-lang.org/).

Need help?If something does not work, or you are not sure where to ask, see the [support guide](https://docs.aztec.network/developers/support). It explains the right channel for questions, bug reports, feature requests, and security disclosures.

**Tags:**
- [protocol](https://docs.aztec.network/developers/tags/protocol)

[Edit this page](https://github.com/AztecProtocol/aztec-packages/edit/next/docs/docs-developers/overview.md)