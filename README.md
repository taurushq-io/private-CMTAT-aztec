# Private CMTAT security token

A private version of the [CMTAT](https://github.com/CMTA/CMTAT) security token, written in Noir / [Aztec.nr](https://docs.aztec.network/) for the [Aztec](https://aztec.network/) privacy Layer 2 on Ethereum.

Balances and transfers are **private**: a holder's balance is a set of encrypted notes in their own client, and a transfer publishes neither the parties nor the amount. Compliance state stays **public**: total supply, the pause and deactivation flags, the role table, the freeze flags and the transfer-restriction lists. The **issuer** receives a copy of every note and a constrained `Transfer` event, so it can reconstruct every balance and audit activity without any user's cooperation.

> **Repository.** Since **v0.3.0** the project is maintained and released by the [Capital Market and Technology Association](https://cmta.ch/) at [github.com/CMTA/private-CMTAT-aztec](https://github.com/CMTA/private-CMTAT-aztec). Releases 0.1.0 to 0.2.0 were published by Taurus SA at [github.com/taurushq-io/private-CMTAT-aztec](https://github.com/taurushq-io/private-CMTAT-aztec), whose history this repository carries.

> **Disclaimer.** This project has not undergone an audit and is provided as-is without any warranties.

## Table of contents

- [Deployment variants](#deployment-variants)
- [Features](#features)
- [Quick start](#quick-start)
- [Repository layout](#repository-layout)
- [Documentation](#documentation)
- [Intellectual property](#intellectual-property)
- [Security policy](#security-policy)

## Deployment variants

Noir has no inheritance and allows one contract per package, so the variants are separate contract packages composing modules from one shared library (`lib/`), built together as a Nargo workspace.

| Variant | Contents |
|---|---|
| `CMTATAztecLight` | Private token, pause, deactivation, freeze, access control, terms, version — no transfer-restriction lists |
| `CMTATAztec` | The above plus the validation module (blacklist / whitelist) |
| `CMTATAztecDebt` | The above plus credit events and debt, for bond-like instruments |

Two further contracts are not tokens but **ARC-403 authorization contracts**: they apply CMTAT's pause, deactivation, freeze and sender-side blacklist / whitelist to the stock tokens of the [CMTA fork of `aztec-standards`](https://github.com/CMTA/aztec-standards), which call them as a hook before every transfer and burn. See [`doc/auth/README.md`](./doc/auth/README.md).

| Contract | Restricts |
|---|---|
| `CMTATAztecAuth` | AIP-20 `Token` |
| `CMTATAztecAuthMultiToken` | ARC-1155 `MultiToken` |

## Features

- **Private** mint, transfer and burn, in single and batched form, with [authwits](https://docs.aztec.network/developers/docs/foundational-topics/advanced/authwit) in place of ERC-20 allowances.
- **Public** pause (immediate) and permanent deactivation, following the CMTAT Solidity semantics: a pause stops transfers only; deactivation stops everything, forever.
- **Freeze** of individual accounts and **transfer restriction** by blacklist or whitelist, screening both parties of a transfer, the recipient of a mint and the account of a burn.
- **Issuer auditability**: an audit copy of every note and a constrained, unforgeable `Transfer` event to the issuer; the issuer address can be rotated with `set_issuer`.
- **Role-based access control** with the CMTAT role set, plus CMTAT terms / token ID, and, on the debt variant, credit events and the `ICMTATDebt` record.
- **Events** for every state change, public where the state is public and private (encrypted to the parties) for transfers.
- **Private/public bridges, at the issuer's option**: deployed with `public_side_enabled = true`, holders may move value between their private notes and a public balance through the four AIP-20 bridges (`transfer_private_to_public`, `transfer_public_to_private`, `transfer_private_to_commitment`, `transfer_private_to_public_with_commitment`), each publishing only the mover's own side; deployed with `false`, the token is fully private. See [Private/public bridges](./doc/README.md#privatepublic-bridges).
- **AIP-20 private profile**: `transfer_private_to_private`, `mint_to_private`, `name`, `symbol`, `decimals`, `balance_of_private` and `total_supply` have the names and types of the [Aztec token standard](https://github.com/CMTA/aztec-standards), so tooling that uses its private paths reaches this token by selector. Not full conformance — no public balances, no commitment transfers, and `burn` is role-gated under its own name; see [Comparison with AIP-20](./doc/README.md#aip-20-private-profile).
- **Gas sponsorship is native, so no meta-transaction module is needed**: the fee payer is chosen per transaction, not configured in the token, so a holder needs no Fee Juice — a sponsored or third-party fee-paying contract can pay instead. This repository's own scripts deploy accounts that way. See [Gas sponsorship](./doc/README.md#gas-sponsorship).

Not supported, unlike Solidity CMTAT: upgradeability, an ERC-2771 meta-transaction module, and forced transfer (the issuer cannot move a holder's notes; the compliance lever is freezing the account).


## Quick start

Install the Aztec toolchain at the version pinned in `Nargo.toml` and `package.json`:

```bash
bash -i <(curl -s https://install.aztec.network)
aztec-up install 5.2.0
```

Start a sandbox in one terminal, then build and run every test in another:

```bash
aztec start --local-network
```

```bash
yarn install
yarn compile      # aztec compile --workspace: all three variants
yarn codegen      # TypeScript artifacts for the e2e suite and the scripts
yarn test         # Noir suite (aztec test --workspace) then the Jest e2e suite
```

`yarn test:nr` runs the Noir suite alone and needs no sandbox. For the testnet scripts (`yarn deploy`, `yarn interaction`, …) copy `.env.example` to `.env` first; see [Deployment](./doc/README.md#deployment) in the technical documentation.

## Repository layout

```
lib/                 cmtat_aztec_lib — every CMTAT module (access control, pause, enforcement,
                     validation, extra information, credit events, debt)
test-helpers/        cmtat_aztec_test_helpers — test scaffolding shared by the Noir suites
contracts/
  cmtat-aztec/       CMTATAztec, with the full Noir test suite
  cmtat-aztec-debt/  CMTATAztecDebt
  cmtat-aztec-light/ CMTATAztecLight
  cmtat-aztec-auth/  CMTATAztecAuth — ARC-403 hook for the AIP-20 token of aztec-standards
  cmtat-aztec-auth-multitoken/  CMTATAztecAuthMultiToken — the same for ARC-1155
src/                 TypeScript: generated artifacts, e2e tests, PXE / account helpers
scripts/             Testnet scripts (deploy, interact, fees, profiling)
doc/                 Technical documentation, diagrams, standards analyses, assessment, audits
submodules/          Pinned reference repositories: CMTAT, CMTAT-Confidential, the equivalency
                     assessment template, and the CMTA fork of aztec-standards on Aztec 5.2.0
```

## Documentation

- [**Technical documentation**](./doc/README.md) — the full specification: assumptions and privacy requirements, the private/public split of each operation with sequence diagrams, batching limits, the event list, what each operation publishes, the module design, deployment, the comparisons with Solidity CMTAT and with CMTAT-Confidential (Zama FHE), known limitations and a glossary.
- [`CHANGELOG.md`](./CHANGELOG.md) — release history, semver policy and the pre-release checklist.
- [`doc/technical/`](./doc/technical/) — the standards comparisons and the design notes. How this token relates to Aztec's AIP-20 token standard: a [detailed comparison](./doc/technical/cmtat-vs-aip20.md), whether it could be [built on the `aztec-standards` library](./doc/technical/building-on-aip20.md), which [AIP-20 features fit CMTAT](./doc/technical/aip20-features-for-cmtat.md), and how the [`aztec-standards` fork](https://github.com/CMTA/aztec-standards) checked out under `submodules/` was [brought to Aztec 5.2.0](./doc/technical/upgrading-aztec-standards.md). And why two applied changes were made the way they were: the [token module](./doc/technical/token-module.md) that holds the value-moving chains once for the three variants, and the [commitment-reuse guard](./doc/technical/commitment-reuse.md) that makes a commitment payable exactly once. It also records why [`zod` is pinned](./doc/technical/zod-pin.md) in `package.json`.
- [`doc/auth/README.md`](./doc/auth/README.md) — the two authorization contracts: how the ARC-403 hook works, what they enforce and cannot (lists and freeze on the sender only, no recipient or initiator screening, mints unhooked, AIP-721 without a hook), how to deploy and operate them, and how they were verified against the real tokens.
- [`doc/cmtat-assessment/`](./doc/cmtat-assessment/README.md) — the CMTAT equivalency assessment of this implementation, criterion by criterion.
- [`doc/audits/tools/v0.4.0/CLAUDE_ANALYSIS.md`](./doc/audits/tools/v0.4.0/CLAUDE_ANALYSIS.md) — tool-assisted code-quality review of 0.4.0: measured gate baseline for every private function, the token-module refactor verified gate-neutral, and a review of the tests themselves (mutation checks, coverage inventory, edge cases). The [0.3.0 review](./doc/audits/tools/v0.3.0/CLAUDE_ANALYSIS.md) is kept for its history.
- [`doc/audits/tools/v0.5.0/CLAUDE_ANALYSIS.md`](./doc/audits/tools/v0.5.0/CLAUDE_ANALYSIS.md) — code-quality review of 0.5.0. A delta review: no contract logic changed since 0.4.0, the version bump is measured gate-neutral across all 40 circuits, and the findings are about the new tests rather than the contracts.
- [`doc/audits/tools/v0.4.0/CLAUDE_AUDIT.md`](./doc/audits/tools/v0.4.0/CLAUDE_AUDIT.md) — tool-assisted **security** review of 0.4.0, separate from the code-quality one below: the threat model, what was verified (eight invariants, every privileged entry point, what each operation publishes), one Info finding, and the open hardening backlog. It records the hypotheses that were probed and did not hold, which is as much of the result as the findings are. Neither review replaces a third-party audit.
- [`LEARN-AZTEC.md`](./LEARN-AZTEC.md) — condensed Aztec / Noir notes written while building, brought up to date with Aztec 5.2.0: background reading, not part of the specification.
- [`CLAUDE.md`](./CLAUDE.md) — the agent and contributor guide: key concepts, conventions and commands.

## Intellectual property

The code is copyright (c) Capital Market and Technology Association, 2026, and is released under the [Mozilla Public License 2.0](./LICENSE-MPL.md) and the [MIT license](./LICENSE-MIT.md). You may choose either license.

**Third-party code.** `lib/src/modules/hybridModule.nr` contains code derived from the AIP-20 `Token` of [`aztec-standards`](https://github.com/defi-wonderland/aztec-standards), Copyright (c) 2024 Wonderland, MIT License; that file is MIT-only and carries the notice.

The history up to and including commit [`61f4220d5565840fd4fcdd2b723c9f55eb824c60`](https://github.com/taurushq-io/private-CMTAT-aztec/commit/61f4220d5565840fd4fcdd2b723c9f55eb824c60) (the 0.2.0 release, and so the 0.1.0, 0.1.1 and 0.2.0 releases) is copyright (c) 2025 Taurus SA, under the same two licenses. Later commits are copyright CMTA.

We are not aware of any patent or patent application covering the techniques implemented.

## Security policy

Please see [SECURITY.md](./SECURITY.md).
