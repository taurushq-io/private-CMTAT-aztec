# Wallet SDK

> Source: https://docs.aztec.network/developers/docs/tutorials/js_tutorials/webapp/wallet-sdk

---

- [![Home](https://docs.aztec.network/img/Aztec_Symbol_Dark.png)![Home](https://docs.aztec.network/img/Aztec%20Symbol_Light.png)](https://docs.aztec.network/)
- Tutorials
- Full-Stack Tutorials
- [Building a Webapp](https://docs.aztec.network/developers/docs/tutorials/js_tutorials/webapp)
- Wallet SDK

On this page
# Wallet SDK

The `@aztec/wallet-sdk` package defines how dApps and wallet extensions communicate on Aztec. It handles wallet discovery, establishes encrypted channels via ECDH key exchange, and provides a capability-based permission system — analogous to EIP-1193 and MetaMask's provider on Ethereum, but with built-in encryption and visual verification.

This section covers **both sides** of the integration:

1. [**dApp Integration**](https://docs.aztec.network/developers/docs/tutorials/js_tutorials/webapp/wallet-sdk/dapp-integration) — Discover wallets, establish secure channels, request capabilities, and use the wallet
2. [**Wallet Extension Integration**](https://docs.aztec.network/developers/docs/tutorials/js_tutorials/webapp/wallet-sdk/wallet-integration) — Handle discovery requests, manage sessions, route messages, and extend `BaseWallet`

## Features[​](#features)

| Feature | Description |
| --- | --- |
| **Wallet discovery** | dApps broadcast via `window.postMessage`, wallet extensions respond after user approval |
| **ECDH key exchange** | P-256 ephemeral key pairs derive a shared secret for each session |
| **AES-256-GCM encryption** | All wallet method calls and responses are encrypted after key exchange |
| **Emoji verification** | A 9-emoji grid (72-bit security) lets users visually confirm there's no man-in-the-middle |
| **Capability permissions** | dApps declare what they need (`AppCapabilities`), wallets grant or deny each capability |
| **Trusted origin reconnect** | Previously approved origins auto-reconnect without re-verification |
| **BaseWallet** | Abstract class that wallet extensions extend — provides `sendTx`, `simulateTx`, `batch`, and more |

## Architecture[​](#architecture)

```
┌──────────────┐       window.postMessage        ┌──────────────────────────────┐│              │  ←─────────────────────────────→ │  Content Script              ││    dApp      │       (discovery only)           │  ContentScriptConnectionHandler│              │                                  └──────────┬───────────────────┘│  WalletManager│      MessagePort (encrypted)               │ chrome.runtime│  ExtensionWallet ←────────────────────────────→ ┌──────────▼───────────────────┐│              │                                  │  Background Service Worker    │└──────────────┘                                  │  BackgroundConnectionHandler  │                                                  └──────────┬───────────────────┘                                                             │ persistent port                                                  ┌──────────▼───────────────────┐                                                  │  Offscreen Document           │                                                  │  OffscreenWallet (BaseWallet) │                                                  │  PXE + WASM proofs            │                                                  └──────────────────────────────┘
```

**Discovery** uses `window.postMessage` (unencrypted, public). After the user approves, a `MessagePort` is transferred and **ECDH key exchange** establishes an encrypted channel. All subsequent wallet method calls flow through this encrypted `MessagePort`.

## Package Exports[​](#package-exports)

The SDK is split into focused entry points:

| Import path | What it provides |
| --- | --- |
| `@aztec/wallet-sdk/manager` | `WalletManager`, `WalletProvider`, `PendingConnection`, `DiscoverySession` — dApp-side discovery and connection |
| `@aztec/wallet-sdk/crypto` | `hashToEmoji` — convert verification hash to emoji string |
| `@aztec/wallet-sdk/extension/handlers` | `BackgroundConnectionHandler`, `ContentScriptConnectionHandler` — wallet extension handlers |
| `@aztec/wallet-sdk/extension/provider` | `ExtensionWallet`, `ExtensionProvider` — low-level provider classes |
| `@aztec/wallet-sdk/base-wallet` | `BaseWallet` — abstract wallet class that extensions subclass |

## Security Model[​](#security-model)

The protocol has three phases with increasing trust:

1. **Discovery (public)** — The dApp broadcasts a request. Wallet extensions only respond after the user explicitly approves the connection in the extension popup. No cryptographic material is exchanged.
2. **Key exchange (authenticated)** — Both sides generate ephemeral ECDH P-256 key pairs. The shared secret is expanded via HKDF into an AES-256-GCM encryption key and an HMAC verification key. A 2-second timeout limits the window for interception.
3. **Verified channel (encrypted)** — The HMAC verification key produces a hash that both sides independently convert to a 9-emoji grid. The user visually confirms the emojis match on both the dApp and wallet extension, defending against man-in-the-middle attacks. After confirmation, all messages are encrypted with AES-256-GCM.

## Next steps[​](#next-steps)

- **Building a dApp?** Start with [dApp Integration](https://docs.aztec.network/developers/docs/tutorials/js_tutorials/webapp/wallet-sdk/dapp-integration)
- **Building a wallet?** Start with [Wallet Extension Integration](https://docs.aztec.network/developers/docs/tutorials/js_tutorials/webapp/wallet-sdk/wallet-integration)
- **New to Aztec wallets?** Read [Network & Wallet](https://docs.aztec.network/developers/docs/tutorials/js_tutorials/webapp/network-and-wallet) first for the basics

Related TutorialsThe [Wallet Extension Tutorial](https://docs.aztec.network/developers/docs/tutorials/js_tutorials/wallet-extension) walks through building a complete Chrome extension wallet step by step, covering service workers, offscreen documents, encrypted storage, and approval flows.

[Edit this page](https://github.com/AztecProtocol/aztec-packages/edit/next/docs/docs-developers/docs/tutorials/js_tutorials/webapp/wallet-sdk/index.md)