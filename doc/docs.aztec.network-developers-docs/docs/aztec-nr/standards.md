# Aztec Contract Standards

> Source: https://docs.aztec.network/developers/docs/aztec-nr/standards

---

- [![Home](https://docs.aztec.network/img/Aztec_Symbol_Dark.png)![Home](https://docs.aztec.network/img/Aztec%20Symbol_Light.png)](https://docs.aztec.network/)
- [Aztec.nr](https://docs.aztec.network/developers/docs/aztec-nr)
- Standards

On this page
# Aztec Contract Standards

Aztec contract standards define shared interfaces and behaviors for common onchain primitives. They serve the same role that ERC standards play on Ethereum: establishing conventions that allow contracts, wallets, and tooling to interoperate without prior coordination.

The standards described in this section are maintained by [DeFi Wonderland](https://github.com/defi-wonderland/aztec-standards) in the `aztec-standards` repository. Each standard is identified by an **Aztec Improvement Proposal (AIP)** number that mirrors its Ethereum counterpart where applicable (AIP-20 corresponds to ERC-20, AIP-721 to ERC-721, AIP-4626 to ERC-4626).

Because Aztec contracts have both private and public execution contexts, the standards are more involved than their Ethereum equivalents. Transfers can move value between private notes and public balances, and many operations require coordination between encrypted state and transparent state within a single transaction.

noteThe code examples in this section are taken from the [aztec-standards repository](https://github.com/defi-wonderland/aztec-standards) maintained by DeFi Wonderland. They will differ from the reference contract implementations shipped in the [aztec-packages repo](https://github.com/AztecProtocol/aztec-packages) under `noir-projects/noir-contracts/contracts/`. When in doubt, consult the aztec-standards github repo for the canonical standard interfaces.

## Standards[​](#standards)

- [AIP-20: Fungible Token](https://docs.aztec.network/developers/docs/aztec-nr/standards/aip-20) — private and public balances, partial-note transfers, recursive note consumption
- [AIP-721: Non-Fungible Token](https://docs.aztec.network/developers/docs/aztec-nr/standards/aip-721) — private NFT ownership, partial-note support, commitment-based transfers
- [AIP-4626: Tokenized Vault](https://docs.aztec.network/developers/docs/aztec-nr/standards/aip-4626) — yield-bearing vaults with share conversion across private and public contexts
- [Escrow](https://docs.aztec.network/developers/docs/aztec-nr/standards/escrow) — minimal token/NFT custody with salt-based authorization
- [Generic Proxy](https://docs.aztec.network/developers/docs/aztec-nr/standards/generic-proxy) — forwarding layer for account abstraction patterns
- [Dripper](https://docs.aztec.network/developers/docs/aztec-nr/standards/dripper) — development faucet for testing

## Related tutorials[​](#related-tutorials)

- [Private Token Contract](https://docs.aztec.network/developers/docs/tutorials/contract_tutorials/token_contract) — build a privacy-preserving fungible token that closely parallels AIP-20
- [NFT Bridge](https://docs.aztec.network/developers/docs/tutorials/js_tutorials/token_bridge) — build a private NFT with custom `NFTNote` and `PrivateSet`, covering patterns extended by AIP-721
- [Deploying a Token Contract](https://docs.aztec.network/developers/docs/tutorials/js_tutorials/aztecjs-getting-started) — deploy and interact with the reference token contract using Aztec.js
- [Counter Contract](https://docs.aztec.network/developers/docs/tutorials/contract_tutorials/counter_contract) — introduces private state, notes, and balance management

For the canonical implementations and latest interface specifications, refer to the [aztec-standards repository](https://github.com/defi-wonderland/aztec-standards) maintained by DeFi Wonderland.

[Edit this page](https://github.com/AztecProtocol/aztec-packages/edit/next/docs/docs-developers/docs/aztec-nr/standards/index.md)