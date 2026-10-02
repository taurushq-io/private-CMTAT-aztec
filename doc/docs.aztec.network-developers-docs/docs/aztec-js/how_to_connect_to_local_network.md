# Connect to Local Network

> Source: https://docs.aztec.network/developers/docs/aztec-js/how_to_connect_to_local_network

---

- [![Home](https://docs.aztec.network/img/Aztec_Symbol_Dark.png)![Home](https://docs.aztec.network/img/Aztec%20Symbol_Light.png)](https://docs.aztec.network/)
- [Aztec.js](https://docs.aztec.network/developers/docs/aztec-js)
- Connect to Local Network

On this page
# Connect to Local Network

This guide shows you how to connect your application to the Aztec local network and interact with the network.

## Prerequisites[​](#prerequisites)

- Running Aztec local network (see [Quickstart](https://docs.aztec.network/developers/getting_started_on_local_network)) on port 8080
- Node.js installed
- TypeScript project set up

## Install dependencies[​](#install-dependencies)

```
yarn add @aztec/aztec.js@5.2.0 @aztec/wallets@5.2.0
```

## Connect to the network[​](#connect-to-the-network)

Create a node client and EmbeddedWallet to interact with the local network:

connect_to_network
```
import { createAztecNodeClient, waitForNode } from "@aztec/aztec.js/node";import { EmbeddedWallet } from "@aztec/wallets/embedded";import { getInitialTestAccountsData } from "@aztec/accounts/testing";const nodeUrl = process.env.AZTEC_NODE_URL ?? "http://localhost:8080";const node = createAztecNodeClient(nodeUrl);// Wait for the network to be readyawait waitForNode(node);// Create an EmbeddedWallet connected to the nodeconst wallet = await EmbeddedWallet.create(node, { ephemeral: true });
```

> [Source code: docs/examples/ts/aztecjs_connection/index.ts#L1-L14](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/ts/aztecjs_connection/index.ts#L1-L14)

About EmbeddedWallet`EmbeddedWallet` is a simplified wallet for local development that implements the same `Wallet` interface used in production. It handles key management, transaction signing, and proof generation in-process without external dependencies.

**Why use it for testing?** It starts instantly, requires no setup, and provides deterministic behavior—ideal for automated tests and rapid iteration.

**Production wallets** (like browser extensions or mobile apps) implement the same interface but store keys securely, may require user confirmation for transactions, and typically run in a separate process. Code written against `EmbeddedWallet` works with any `Wallet` implementation, so your application logic transfers directly to production.

### Verify the connection[​](#verify-the-connection)

Get node information to confirm your connection:

verify_connection
```
const nodeInfo = await node.getNodeInfo();console.log("Connected to local network version:", nodeInfo.nodeVersion);console.log("Chain ID:", nodeInfo.l1ChainId);
```

> [Source code: docs/examples/ts/aztecjs_connection/index.ts#L16-L20](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/ts/aztecjs_connection/index.ts#L16-L20)

### Load pre-funded accounts[​](#load-pre-funded-accounts)

The local network has accounts pre-funded with fee juice to pay for gas. Register them in your wallet:

load_accounts
```
const testAccounts = await getInitialTestAccountsData();const [aliceAddress, bobAddress] = await Promise.all(  testAccounts.slice(0, 2).map(async (account) => {    return (      await wallet.createSchnorrInitializerlessAccount(        account.secret,        account.salt,        account.signingKey,      )    ).address;  }),);console.log(`Alice's address: ${aliceAddress.toString()}`);console.log(`Bob's address: ${bobAddress.toString()}`);
```

> [Source code: docs/examples/ts/aztecjs_connection/index.ts#L22-L38](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/ts/aztecjs_connection/index.ts#L22-L38)

These accounts are pre-funded with fee juice (the native gas token) at genesis, so you can immediately send transactions without needing to bridge funds from L1.

### Check fee juice balance[​](#check-fee-juice-balance)

Verify that an account has fee juice for transactions:

check_fee_juice
```
import { getFeeJuiceBalance } from "@aztec/aztec.js/utils";const aliceBalance = await getFeeJuiceBalance(aliceAddress, node);console.log(`Alice's fee juice balance: ${aliceBalance}`);
```

> [Source code: docs/examples/ts/aztecjs_connection/index.ts#L40-L45](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/ts/aztecjs_connection/index.ts#L40-L45)

## Next steps[​](#next-steps)

- [Create an account](https://docs.aztec.network/developers/docs/aztec-js/how_to_create_account) - Deploy new accounts on the network
- [Deploy a contract](https://docs.aztec.network/developers/docs/aztec-js/how_to_deploy_contract) - Deploy your smart contracts
- [Send transactions](https://docs.aztec.network/developers/docs/aztec-js/how_to_send_transaction) - Execute contract functions

**Tags:**
- [local_network](https://docs.aztec.network/developers/tags/local-network)
- [connection](https://docs.aztec.network/developers/tags/connection)
- [wallet](https://docs.aztec.network/developers/tags/wallet)

[Edit this page](https://github.com/AztecProtocol/aztec-packages/edit/next/docs/docs-developers/docs/aztec-js/how_to_connect_to_local_network.md)