# dApp Integration

> Source: https://docs.aztec.network/developers/docs/tutorials/js_tutorials/webapp/wallet-sdk/dapp-integration

---

- [![Home](https://docs.aztec.network/img/Aztec_Symbol_Dark.png)![Home](https://docs.aztec.network/img/Aztec%20Symbol_Light.png)](https://docs.aztec.network/)
- Tutorials
- Full-Stack Tutorials
- [Building a Webapp](https://docs.aztec.network/developers/docs/tutorials/js_tutorials/webapp)
- [Wallet SDK](https://docs.aztec.network/developers/docs/tutorials/js_tutorials/webapp/wallet-sdk)
- 1. dApp Integration

On this page
# dApp Integration

This page covers how a dApp discovers wallet extensions, establishes an encrypted channel, requests permissions, and uses the wallet. The patterns here come from the [Pod Racing tutorial](https://docs.aztec.network/developers/docs/tutorials/js_tutorials/webapp/network-and-wallet) and [GregoSwap](https://github.com/AztecProtocol/gregoswap), a reference Aztec DEX.

## Installation[​](#installation)

Your dApp needs two packages:

```
npm install @aztec/wallet-sdk @aztec/aztec.js
```

The key imports:

```
import { WalletManager, type WalletProvider, type PendingConnection } from '@aztec/wallet-sdk/manager';import { hashToEmoji } from '@aztec/wallet-sdk/crypto';import { Fr } from '@aztec/aztec.js/fields';import type { Wallet, AppCapabilities, GrantedAccountsCapability } from '@aztec/aztec.js/wallet';
```

## Step 1: Discover Wallets[​](#step-1-discover-wallets)

Wallet discovery broadcasts a request via `window.postMessage`. Any installed Aztec wallet extension that the user has approved responds with its info.

discover-wallets
```
/** * Starts discovering available wallet extensions. * Wallet extensions broadcast their availability via window.postMessage. * Returns a cancel function and calls onUpdate with each discovered wallet. */export function discoverWallets(  chainId: number,  appId: string,  onUpdate: (providers: WalletProvider[]) => void): { cancel: () => void; done: Promise<void> } {  const manager = WalletManager.configure({    extensions: { enabled: true },  });  const providers: WalletProvider[] = [];  const discovery = manager.getAvailableWallets({    chainInfo: {      chainId: new Fr(chainId),      version: new Fr(1),    },    appId,    onWalletDiscovered: (provider) => {      // Deduplicate by wallet ID (StrictMode or remounts can cause duplicate discoveries)      if (providers.some(p => p.id === provider.id)) {        return;      }      providers.push(provider);      onUpdate([...providers]);    },  });  return {    cancel: () => discovery.cancel(),    done: discovery.done,  };}
```

> [Source code: docs/examples/webapp-tutorial/src/wallet-connection.ts#L26-L64](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/webapp-tutorial/src/wallet-connection.ts#L26-L64)

`WalletManager.configure()` accepts options to filter extensions:

```
const manager = WalletManager.configure({  extensions: {    enabled: true,    allowList: ['my-trusted-wallet-id'],  // Optional: only allow specific wallets    blockList: ['unwanted-wallet-id'],    // Optional: block specific wallets  },});
```

`getAvailableWallets()` returns a `DiscoverySession` with:

- `wallets` — an `AsyncIterable<WalletProvider>` that yields providers as they're discovered
- `cancel()` — stops discovery
- `done` — a `Promise` that resolves when the discovery timeout expires

The `onWalletDiscovered` callback fires each time a wallet extension responds. Each `WalletProvider` includes:

- `id` — unique wallet identifier
- `name` — display name (e.g., "Aztec Tutorial Wallet")
- `icon` — optional data URI or URL for the wallet icon
- `metadata` — optional version info

noteDiscovery requires user action in the wallet extension — the wallet won't reveal itself without the user clicking "Connect" in their extension popup. This is a privacy feature: websites can't silently detect which wallets you have installed.

## Step 2: Establish a Secure Channel[​](#step-2-establish-a-secure-channel)

Once the user picks a wallet, establish an encrypted channel using ECDH key exchange:

connect-wallet
```
/** * Connects to a discovered wallet provider. * This establishes a secure encrypted channel using ECDH key exchange. * The returned emojis should be shown to the user for verification. */export async function connectToProvider(  provider: WalletProvider,  appId: string): Promise<{  emojis: string;  confirm: () => Promise<Wallet>;  cancel: () => void;}> {  console.log('[wallet-connection] Calling establishSecureChannel for provider:', provider.name);  const pending = await provider.establishSecureChannel(appId);  console.log('[wallet-connection] Secure channel established, verificationHash:', pending.verificationHash);  const emojis = hashToEmoji(pending.verificationHash);  console.log('[wallet-connection] Emojis:', emojis);  return {    emojis,    confirm: () => pending.confirm(),    cancel: () => pending.cancel(),  };}
```

> [Source code: docs/examples/webapp-tutorial/src/wallet-connection.ts#L66-L92](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/webapp-tutorial/src/wallet-connection.ts#L66-L92)

`establishSecureChannel()` performs the ECDH P-256 key exchange and returns a `PendingConnection` with:

- `verificationHash` — hex string that both sides compute independently
- `confirm()` — creates the encrypted `Wallet` proxy (call after user verifies emojis)
- `cancel()` — aborts the connection

## Step 3: Emoji Verification[​](#step-3-emoji-verification)

The verification hash is converted to a 9-emoji grid using `hashToEmoji()`. Both the dApp and wallet extension compute the same emojis independently. The user visually confirms they match, defending against man-in-the-middle attacks.

```
const emojis = hashToEmoji(pending.verificationHash);// Display emojis to the user
```

Show the emojis prominently in your UI:

```
{verificationEmojis && (  <div className="emoji-verification">    <h3>Verify Connection</h3>    <p>Check that these emojis match what your wallet extension shows:</p>    <div className="emoji-grid">{verificationEmojis}</div>  </div>)}
```

After the user confirms the emojis match in the wallet extension, call `confirm()` to create the wallet instance:

```
const wallet = await confirm();
```

Trusted OriginsOn subsequent visits, the wallet extension can auto-approve discovery and skip emoji verification for trusted origins. The user only goes through the full flow once per origin.

## Step 4: Request Capabilities[​](#step-4-request-capabilities)

After connecting, your dApp should declare the permissions it needs using `requestCapabilities()`. The wallet extension shows the user an approval dialog.

The `AppCapabilities` manifest describes your dApp's identity and the permissions it requires. Each capability type maps to a set of wallet operations — for example, `accounts` lets you read account addresses, `transaction` lets you send transactions, and `simulation` lets you simulate without sending. The wallet may grant all, some, or none of the requested capabilities.

app-capabilities
```
export function getAppCapabilities(): AppCapabilities {  return {    version: '1.0',    metadata: {      name: 'Pod Racing',      version: '1.0.0',      description: 'Pod Racing game on Aztec',      url: window.location.origin,    },    capabilities: [      { type: 'accounts', canGet: true },      { type: 'contracts', contracts: '*', canRegister: true, canGetMetadata: true },      { type: 'simulation', transactions: { scope: '*' }, utilities: { scope: '*' } },      { type: 'transaction', scope: '*' },    ],  };}
```

> [Source code: docs/examples/webapp-tutorial/src/wallet-connection.ts#L94-L112](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/webapp-tutorial/src/wallet-connection.ts#L94-L112)

### Capability Types[​](#capability-types)

| Type | What it grants | Key properties |
| --- | --- | --- |
| `accounts` | Read accounts, create auth witnesses | `canGet`, `canCreateAuthWit` |
| `contracts` | Register contracts, query metadata | `contracts: '*' \| AztecAddress[]`, `canRegister`, `canGetMetadata` |
| `contractClasses` | Query contract class metadata | `classes: '*' \| Fr[]`, `canGetMetadata` |
| `simulation` | Simulate transactions and utilities | `transactions.scope`, `utilities.scope` |
| `transaction` | Send transactions | `scope: '*' \| ContractFunctionPattern[]` |
| `data` | Read address book, private events | `addressBook`, `privateEvents: { contracts }` |

### Checking Granted Capabilities[​](#checking-granted-capabilities)

The wallet may deny or reduce capabilities. Check what was actually granted:

```
const capabilities = await wallet.requestCapabilities(manifest);// Check if accounts were grantedconst accountsCap = capabilities.granted.find(  (c): c is GrantedAccountsCapability => c.type === 'accounts');if (!accountsCap?.accounts?.length) {  throw new Error('No accounts granted by wallet');}// The wallet decides which accounts to shareconst account = accountsCap.accounts[0];console.log(`Connected as: ${account.alias} (${account.item})`);
```

The `WalletCapabilities` response includes:

- `granted` — array of capabilities the wallet approved (missing = denied)
- `wallet` — wallet name and version

## Step 5: Use the Wallet[​](#step-5-use-the-wallet)

After `confirm()`, you have a standard `Wallet` instance. All method calls are encrypted transparently — you use it like any other wallet:

```
// Get accountsconst accounts = await wallet.getAccounts();// Register a contractawait wallet.registerContract(contractInstance, contractArtifact);// Send a transactionconst receipt = await wallet.sendTx(executionPayload, { from: account.item });// Simulate without sendingconst simulation = await wallet.simulateTx(executionPayload, { from: account.item });// Create an auth witnessconst authWit = await wallet.createAuthWit(account.item, messageHashOrIntent);// Batch multiple callsconst results = await wallet.batch([  { name: 'simulateTx', args: [payload1, opts1] },  { name: 'simulateTx', args: [payload2, opts2] },]);
```

## Disconnect Handling[​](#disconnect-handling)

The wallet can disconnect unexpectedly (extension unloaded, user disconnects from popup). Register a callback to handle this:

```
// Register disconnect handlerconst unsubscribe = wallet.onDisconnect(() => {  console.log('Wallet disconnected');  // Fall back to embedded wallet or show reconnect UI});// Check connection statusif (wallet.isDisconnected()) {  // Need to reconnect}// Graceful disconnectawait wallet.disconnect();
```

GregoSwap uses this pattern to fall back to an embedded wallet on disconnect:

```
function handleUnexpectedDisconnect() {  // Restore embedded wallet if available  if (embeddedWallet) {    setWallet(embeddedWallet);    setAddress(embeddedAddress);  } else {    setWallet(null);  }}const unsubscribe = provider.onDisconnect(handleUnexpectedDisconnect);
```

## Complete Flow[​](#complete-flow)

Here's the full connection flow in a React component:

remote-connect
```
/** Discover and connect to a browser extension wallet */useEffect(() => {  if (network !== 'remote') return;  setStatus('Discovering wallet extensions...');  setDiscoveryDone(false);  const { cancel, done } = discoverWallets(31337, 'pod-racing', (found) => {    setProviders(found);    setStatus(`Found ${found.length} wallet(s)`);  });  let isMounted = true;  done.then(() => {    if (isMounted) setDiscoveryDone(true);  }).catch((err) => {    if (isMounted) setStatus(`Discovery error: ${err.message}`);  });  return () => {    isMounted = false;    cancel();  };}, [network]);async function connectExtension(provider: WalletProvider) {  setLoading(true);  setStatus('Establishing secure channel...');  try {    const { emojis, confirm } = await connectToProvider(      provider,      'pod-racing'    );    // Show emojis for reference — the wallet extension is the authority    // that verifies the emojis match. confirm() is a local operation    // that creates the ExtensionWallet proxy (no message sent to extension).    setVerificationEmojis(emojis);    setStatus('Verify these emojis match in the wallet extension, then approve there.');    const wallet = await confirm();    // Request capabilities — the dApp declares all permissions it needs upfront.    // The extension shows an approval dialog; this call blocks until the user approves.    setStatus('Requesting permissions from wallet extension...');    const manifest = getAppCapabilities();    const capabilities = await wallet.requestCapabilities(manifest);    setVerificationEmojis(null);    console.log('[WalletConnect] Granted capabilities:', capabilities);    // Check if accounts were granted    const accountsCap = capabilities.granted.find(      (c): c is GrantedAccountsCapability => c.type === 'accounts'    );    if (!accountsCap?.accounts?.length) {      setStatus('No accounts granted. Please approve the capabilities request in the wallet extension.');      setLoading(false);      return;    }    setConnected(true);    setStatus('Connected!');    addLog('Connected to extension wallet', 'success');    onWalletConnected(wallet);  } catch (err: unknown) {    const msg = err instanceof Error ? err.message : String(err);    setStatus(`Error: ${msg}`);    addLog(`Connection error: ${msg}`, 'error');  } finally {    setLoading(false);  }}
```

> [Source code: docs/examples/webapp-tutorial/src/components/WalletConnect.tsx#L55-L130](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/webapp-tutorial/src/components/WalletConnect.tsx#L55-L130)

## State Types[​](#state-types)

For tracking wallet discovery state in your app:

wallet-sdk-types
```
export interface WalletDiscoveryState {  providers: WalletProvider[];  selectedProvider: WalletProvider | null;  verificationEmojis: string | null;  wallet: Wallet | null;  status: 'idle' | 'discovering' | 'verifying' | 'connected' | 'error';  error: string | null;}export const initialWalletState: WalletDiscoveryState = {  providers: [],  selectedProvider: null,  verificationEmojis: null,  wallet: null,  status: 'idle',  error: null,};
```

> [Source code: docs/examples/webapp-tutorial/src/wallet-connection.ts#L6-L24](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/webapp-tutorial/src/wallet-connection.ts#L6-L24)

## Next steps[​](#next-steps)

- [Wallet Extension Integration](https://docs.aztec.network/developers/docs/tutorials/js_tutorials/webapp/wallet-sdk/wallet-integration) — Build the other side: handle discovery, manage sessions, and extend `BaseWallet`
- [Contract Interaction](https://docs.aztec.network/developers/docs/tutorials/js_tutorials/webapp/contract-interaction) — Deploy and call contracts with the connected wallet

[Edit this page](https://github.com/AztecProtocol/aztec-packages/edit/next/docs/docs-developers/docs/tutorials/js_tutorials/webapp/wallet-sdk/01-dapp-integration.md)