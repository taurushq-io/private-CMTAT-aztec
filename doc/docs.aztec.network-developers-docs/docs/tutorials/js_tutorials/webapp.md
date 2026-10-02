# Building a Webapp on Aztec

> Source: https://docs.aztec.network/developers/docs/tutorials/js_tutorials/webapp

---

- [![Home](https://docs.aztec.network/img/Aztec_Symbol_Dark.png)![Home](https://docs.aztec.network/img/Aztec%20Symbol_Light.png)](https://docs.aztec.network/)
- Tutorials
- Full-Stack Tutorials
- Building a Webapp

On this page
# Building a Webapp on Aztec

In this tutorial you'll build a **Pod Racing** game webapp — a fully functional application where players privately allocate points across racing tracks, with their strategies hidden from opponents using Aztec's privacy features.

## What you'll build[​](#what-youll-build)

A two-player competitive game where:

- Each player distributes up to 9 points across 5 racing tracks per round (3 rounds total)
- Point allocations are **private** — stored as encrypted notes only you can read
- After all rounds, players reveal their totals and a winner is determined (best of 5 tracks)
- The app connects to a local Aztec network, optionally via browser extension wallet

### How the game works[​](#how-the-game-works)

Each round, you distribute up to 9 points across 5 tracks (think of each track as an independent race). After 3 rounds, each player's per-track totals are compared: whoever allocated more points to a track wins that track. The overall winner is the player who wins the majority of the 5 tracks (best of 5).

### Why privacy matters[​](#why-privacy-matters)

Without privacy, your opponent could see your point allocations as you play and adjust their strategy to counter yours. Aztec keeps each player's allocations encrypted as private notes — your opponent only learns that you submitted a round, not how you distributed your points. Strategies are revealed only after both players finish, making the game fair.

## What you'll learn[​](#what-youll-learn)

- Writing and compiling a Noir smart contract with private state
- Deploying and interacting with the contract from a TypeScript script
- Setting up a Vite + React project that runs Aztec's WASM modules in-browser
- Connecting to Aztec via an **embedded wallet** (local dev) or the **wallet SDK** (browser extension)
- Sending **private transactions** and reading **private state**
- Paying transaction fees with the **SponsoredFPC** contract

## Prerequisites[​](#prerequisites)

- [Node.js](https://nodejs.org/) v22 or later
- The Aztec CLI installed (`aztec` command available)
- A local Aztec network running (`aztec start --local-network`)
- Basic familiarity with React and TypeScript

## Clone the example[​](#clone-the-example)

The tutorial walks through a complete working example. Clone it first, then follow along:

```
git clone https://github.com/AztecProtocol/aztec-packages.gitcd aztec-packagesgit checkout v5.2.0cd docs/examples/webapp-tutorial./setup.sh
```

## Architecture[​](#architecture)

```
┌──────────────────────────────────────────────────┐│                     Browser                       ││                                                   ││  ┌──────────┐    ┌────────┐    ┌──────────────┐  ││  │ React UI │───▸│ Wallet │───▸│ PXE  (WASM)  │  ││  └──────────┘    └────────┘    └──────┬───────┘  ││                                       │          │└───────────────────────────────────────┼──────────┘                                        │ RPC                                 ┌──────▼───────┐                                 │  Aztec Node  │                                 │  (local or   │                                 │   remote)    │                                 └──────────────┘
```

**PXE** (Private eXecution Environment) runs in the browser as WASM. It handles private state, note discovery, and proof generation — your secrets never leave the browser.

## Tutorial sections[​](#tutorial-sections)

1. [The Contract](https://docs.aztec.network/developers/docs/tutorials/js_tutorials/webapp/the-contract) — understand the Pod Racing contract, compile it, deploy and interact via script
2. [Project Setup](https://docs.aztec.network/developers/docs/tutorials/js_tutorials/webapp/project-setup) — project structure overview, Vite config, environment
3. [Network & Wallet](https://docs.aztec.network/developers/docs/tutorials/js_tutorials/webapp/network-and-wallet) — connecting to Aztec, embedded wallet, wallet SDK
4. [Contract Interaction](https://docs.aztec.network/developers/docs/tutorials/js_tutorials/webapp/contract-interaction) — deploying and calling contracts from the webapp, game lobby and gameplay
5. [Transactions & Fees](https://docs.aztec.network/developers/docs/tutorials/js_tutorials/webapp/transactions-and-fees) — tx lifecycle, SponsoredFPC
6. [Putting It Together](https://docs.aztec.network/developers/docs/tutorials/js_tutorials/webapp/putting-it-together) — full App component, running the app
7. [Wallet SDK](https://docs.aztec.network/developers/docs/tutorials/js_tutorials/webapp/wallet-sdk) — deep dive into discovery, encrypted channels, capabilities, and integration on both dApp and wallet sides

## Completed example[​](#completed-example)

The full working example including the contract source is available at [`docs/examples/webapp-tutorial/`](https://github.com/AztecProtocol/aztec-packages/tree/v5.2.0/docs/examples/webapp-tutorial).

The example also includes a **functional wallet extension** (`test-extension/`) that can deploy accounts and send real transactions using SponsoredFPC for fee payment. See the [Network & Wallet](https://docs.aztec.network/developers/docs/tutorials/js_tutorials/webapp/network-and-wallet#testing-with-the-tutorial-wallet-extension) section for setup instructions.

Building a Wallet Extension?If you want to learn how to build a browser extension wallet for Aztec, check out the companion [Wallet Extension Tutorial](https://docs.aztec.network/developers/docs/tutorials/js_tutorials/wallet-extension). It covers service workers, offscreen documents, encrypted key storage, and transaction approval flows.

[Edit this page](https://github.com/AztecProtocol/aztec-packages/edit/next/docs/docs-developers/docs/tutorials/js_tutorials/webapp/index.md)