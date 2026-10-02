# TypeScript API Reference

> Source: https://docs.aztec.network/developers/docs/aztec-js/typescript_api_reference

---

- [![Home](https://docs.aztec.network/img/Aztec_Symbol_Dark.png)![Home](https://docs.aztec.network/img/Aztec%20Symbol_Light.png)](https://docs.aztec.network/)
- [Aztec.js](https://docs.aztec.network/developers/docs/aztec-js)
- TypeScript API Reference

On this page
# TypeScript API Reference

This section provides API reference documentation for the Aztec TypeScript packages. These packages enable developers to build applications on Aztec, from simple contract interactions to complex privacy-preserving protocols.

## Package Categories[​](#package-categories)

### Client SDKs[​](#client-sdks)

Packages for building Aztec applications:

| Package | Description |
| --- | --- |
| **@aztec/aztec.js** | Main SDK for building Aztec applications. Provides contract deployment, transaction creation, and account management. |
| **@aztec/accounts** | Sample account contract implementations including ECDSA and Schnorr accounts. |
| **@aztec/pxe** | Private eXecution Environment client library for orchestrating private transaction execution and proving. |
| **@aztec/wallet-sdk** | Wallet SDK for browser and extension integrations. |
| **@aztec/wallets** | Embedded wallet for browser and Node.js environments. |
| **@aztec/entrypoints** | Transaction entrypoint implementations for account abstraction. |

### Core Libraries[​](#core-libraries)

Foundational types and utilities used across the Aztec stack:

| Package | Description |
| --- | --- |
| **@aztec/stdlib** | Protocol-level types including transactions, blocks, proofs, and kernel circuit types. |
| **@aztec/foundation** | Low-level utilities including crypto primitives, serialization, and async helpers. |
| **@aztec/constants** | Protocol constants shared between TypeScript and Noir circuits. |

noteCommon types like `Fr`, `AztecAddress`, and `EthAddress` are re-exported through `@aztec/aztec.js` subpaths (e.g., `@aztec/aztec.js/fields`, `@aztec/aztec.js/addresses`). Most developers won't need to import from `@aztec/stdlib` directly.

## LLM-Optimized Documentation[​](#llm-optimized-documentation)

For LLM consumption, we provide machine-readable documentation in multiple formats:

- **[llms.txt](https://docs.aztec.network/llms.txt)**  - Full documentation optimized for LLM context
- [**LLM Summary**](https://docs.aztec.network/typescript-api/mainnet/llm-summary.txt)  - Human-readable API summary

### Markdown API Files[​](#markdown-api-files)

The following markdown files are available for LLM context inclusion at `/typescript-api/mainnet/`:

| File | Description |
| --- | --- |
| [`llm-summary.txt`](https://docs.aztec.network/typescript-api/mainnet/llm-summary.txt) | Human-readable summary with package overview |
| [`aztec.js.md`](https://docs.aztec.network/typescript-api/mainnet/aztec.js.md) | Main SDK - contracts, transactions, accounts |
| [`accounts.md`](https://docs.aztec.network/typescript-api/mainnet/accounts.md) | Account implementations (ECDSA, Schnorr) |
| [`pxe.md`](https://docs.aztec.network/typescript-api/mainnet/pxe.md) | Private execution environment client |
| [`wallet-sdk.md`](https://docs.aztec.network/typescript-api/mainnet/wallet-sdk.md) | Browser/extension wallet integration |
| [`wallets.md`](https://docs.aztec.network/typescript-api/mainnet/wallets.md) | Embedded wallet for browser and Node.js |
| [`entrypoints.md`](https://docs.aztec.network/typescript-api/mainnet/entrypoints.md) | Transaction entrypoints for account abstraction |
| [`stdlib.md`](https://docs.aztec.network/typescript-api/mainnet/stdlib.md) | Protocol types (transactions, blocks, proofs) |
| [`foundation.md`](https://docs.aztec.network/typescript-api/mainnet/foundation.md) | Low-level utilities (crypto, serialization) |
| [`constants.md`](https://docs.aztec.network/typescript-api/mainnet/constants.md) | Protocol constants for circuits |

## Related Resources[​](#related-resources)

- [Aztec.js Getting Started](https://docs.aztec.network/developers/docs/tutorials/js_tutorials/aztecjs-getting-started)
- [GitHub: aztec-packages](https://github.com/AztecProtocol/aztec-packages/tree/v5.2.0/yarn-project)

[Edit this page](https://github.com/AztecProtocol/aztec-packages/edit/next/docs/docs-developers/docs/aztec-js/typescript_api_reference.mdx)