# Aztec.js

> Source: https://docs.aztec.network/developers/docs/aztec-js

---

- [![Home](https://docs.aztec.network/img/Aztec_Symbol_Dark.png)![Home](https://docs.aztec.network/img/Aztec%20Symbol_Light.png)](https://docs.aztec.network/)
- Aztec.js

On this page
# Aztec.js

Aztec.js is a library that provides APIs for managing accounts and interacting with contracts on the Aztec network. It communicates with the [Private eXecution Environment (PXE)](https://docs.aztec.network/developers/docs/foundational-topics/pxe) through a `PXE` implementation, allowing developers to easily register new accounts, deploy contracts, view functions, and send transactions.

## Installing[​](#installing)

```
npm install @aztec/aztec.js@5.2.0
```

## Common Dependencies[​](#common-dependencies)

Most applications will need additional packages alongside `@aztec/aztec.js`, e.g.:

```
npm install @aztec/aztec.js@5.2.0 \  @aztec/accounts@5.2.0 \  @aztec/wallets@5.2.0 \  @aztec/noir-contracts.js@5.2.0
```

| Package | Description |
| --- | --- |
| `@aztec/aztec.js` | Core SDK for contracts, transactions, and network interaction |
| `@aztec/accounts` | Account contract implementations (Schnorr, ECDSA) |
| `@aztec/wallets` | Simplified wallets for local development and scripting |
| `@aztec/noir-contracts.js` | Pre-compiled contract interfaces (Token, NFT, etc.) |

## Package Structure[​](#package-structure)

`@aztec/aztec.js` uses subpath exports. You must import from specific subpaths rather than the package root:

```
import { createAztecNodeClient, waitForNode } from "@aztec/aztec.js/node";import { Fr } from "@aztec/aztec.js/fields";import { AztecAddress } from "@aztec/aztec.js/addresses";
```

## AI-Friendly Reference[​](#ai-friendly-reference)

The [TypeScript API reference](https://docs.aztec.network/developers/docs/aztec-js/typescript_api_reference) links to markdown interface files for common packages for easy use with AI coding assistants. Copy relevant sections to give your AI tool accurate context about Aztec.js APIs.

## Guides[​](#guides)

[
## 📄️Connect to Local Network

Connect your application to the Aztec local network and interact with accounts.

](https://docs.aztec.network/developers/docs/aztec-js/how_to_connect_to_local_network)[
## 📄️Creating Accounts

Step-by-step guide to creating and deploying new user accounts in Aztec.js applications.

](https://docs.aztec.network/developers/docs/aztec-js/how_to_create_account)[
## 📄️Deploying Contracts

Deploy smart contracts to Aztec using generated TypeScript classes.

](https://docs.aztec.network/developers/docs/aztec-js/how_to_deploy_contract)[
## 📄️Sending Transactions

Send transactions to Aztec contracts using Aztec.js with various options and error handling

](https://docs.aztec.network/developers/docs/aztec-js/how_to_send_transaction)[
## 📄️Reading Contract Data

How to read data from contracts including simulating functions, reading logs, and retrieving events.

](https://docs.aztec.network/developers/docs/aztec-js/how_to_read_data)[
## 📄️Simulate without signing prompts

How to call .simulate() on a view function or estimate gas without prompting the user to sign authentication witnesses.

](https://docs.aztec.network/developers/docs/aztec-js/how_to_simulate_without_signing)[
## 📄️Using Authentication Witnesses

Step-by-step guide to implementing authentication witnesses in Aztec.js for delegated transactions.

](https://docs.aztec.network/developers/docs/aztec-js/how_to_use_authwit)[
## 📄️Paying Fees

Pay transaction fees on Aztec, understand mana costs, estimate gas, and retrieve fees from receipts.

](https://docs.aztec.network/developers/docs/aztec-js/how_to_pay_fees)[
## 📄️Testing Smart Contracts

Learn how to write and run tests for your Aztec smart contracts using Aztec.js and a local network.

](https://docs.aztec.network/developers/docs/aztec-js/how_to_test)[
## 📄️Pay Fees Privately

Learn how private fee payment works on Aztec and walk through an example using a community-built fully private Fee Payment Contract.

](https://docs.aztec.network/developers/docs/aztec-js/how_to_use_private_fee_juice)[
## 📄️Reference

Comprehensive auto-generated reference for the Aztec.js TypeScript library with all classes, interfaces, types, and functions.

](https://docs.aztec.network/developers/docs/aztec-js/aztec_js_reference)[
## 📄️TypeScript API Reference

API reference documentation for Aztec TypeScript packages including aztec.js, accounts, PXE, and core libraries.

](https://docs.aztec.network/developers/docs/aztec-js/typescript_api_reference)**Tags:**
- [aztec.js](https://docs.aztec.network/developers/tags/aztec-js)
- [javascript](https://docs.aztec.network/developers/tags/javascript)
- [typescript](https://docs.aztec.network/developers/tags/typescript)

[Edit this page](https://github.com/AztecProtocol/aztec-packages/edit/next/docs/docs-developers/docs/aztec-js/index.md)