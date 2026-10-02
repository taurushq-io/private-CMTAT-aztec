# Deploying a Token Contract

> Source: https://docs.aztec.network/developers/docs/tutorials/js_tutorials/aztecjs-getting-started

---

- [![Home](https://docs.aztec.network/img/Aztec_Symbol_Dark.png)![Home](https://docs.aztec.network/img/Aztec%20Symbol_Light.png)](https://docs.aztec.network/)
- Tutorials
- Full-Stack Tutorials
- Deploying a Token Contract

On this page
# Deploying a Token Contract

In this guide, we will retrieve the local network and deploy a pre-written token contract to it using Aztec.js. [Check out the source code](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/noir-projects/noir-contracts/contracts/app/token_contract/src/main.nr). We will then use Aztec.js to interact with this contract and transfer tokens.

Before starting, make sure to be running Aztec local network at version 5.2.0. Check out [the guide](https://docs.aztec.network/developers/getting_started_on_local_network) for info about that.

## Set up the project[​](#set-up-the-project)

First, create a new directory for your project and initialize it with yarn:

```
mkdir token-tutorialcd token-tutorialyarn init -y
```

Next, add the TypeScript dependencies:

```
yarn add "typescript@^5.3.3" @types/node tsx
```

tipNever heard of `tsx`? Well, it will just run `typescript` with reasonable defaults. Pretty cool for a small example like this one. You may want to tune in your own project's `tsconfig.json` later!

Let's also import the Aztec dependencies for this tutorial:

```
yarn add @aztec/aztec.js@5.2.0 @aztec/accounts@5.2.0 @aztec/noir-contracts.js@5.2.0 @aztec/wallets@5.2.0
```

Aztec.js assumes your project is using ESM, so make sure you add `"type": "module"` to `package.json`. You probably also want at least a `start` script. For example:

```
{  "type": "module",  "scripts": {    "start": "tsx index.ts"  }}
```

### Connecting to the local network[​](#connecting-to-the-local-network)

Now let's connect to the Aztec local network and set up test accounts.

**Step 1: Start the Aztec Local Network**

In a separate terminal, run:

```
aztec start --local-network
```

Keep this terminal running throughout the tutorial.

**Step 2: Create the index.ts file**

Create an `index.ts` file in the root of your project with the following code. This connects to the local network and imports test accounts (Alice and Bob):

setup
```
import { EmbeddedWallet } from "@aztec/wallets/embedded";import { getInitialTestAccountsData } from "@aztec/accounts/testing";const nodeUrl = process.env.AZTEC_NODE_URL ?? "http://localhost:8080";const wallet = await EmbeddedWallet.create(nodeUrl, { ephemeral: true });const [alice, bob] = await getInitialTestAccountsData();await wallet.createSchnorrInitializerlessAccount(  alice.secret,  alice.salt,  alice.signingKey,);await wallet.createSchnorrInitializerlessAccount(  bob.secret,  bob.salt,  bob.signingKey,);
```

> [Source code: docs/examples/ts/aztecjs_getting_started/index.ts#L1-L19](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/ts/aztecjs_getting_started/index.ts#L1-L19)

**Step 3: Verify the script runs**

Run the script to make sure everything is set up correctly:

```
yarn start
```

If there are no errors, you're ready to continue. For more details on connecting to the local network, see [this guide](https://docs.aztec.network/developers/docs/aztec-js/how_to_connect_to_local_network).

## Deploy the token contract[​](#deploy-the-token-contract)

Now that we have our accounts loaded, let's deploy a pre-compiled token contract from the Aztec library. You can find the full code for the contract [here (GitHub link)](https://github.com/AztecProtocol/aztec-packages/tree/v5.2.0/noir-projects/noir-contracts/contracts/app/token_contract/src).

Add the following to `index.ts` to import the contract and deploy it with Alice as the admin:

deploy
```
import { TokenContract } from "@aztec/noir-contracts.js/Token";const { contract: token } = await TokenContract.deploy(  wallet,  alice.address,  "TokenName",  "TKN",  18,).send({ from: alice.address });
```

> [Source code: docs/examples/ts/aztecjs_getting_started/index.ts#L21-L31](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/ts/aztecjs_getting_started/index.ts#L21-L31)

## Mint and transfer[​](#mint-and-transfer)

Let's go ahead and have Alice mint herself some tokens, in private:

mint
```
await token.methods  .mint_to_private(alice.address, 100)  .send({ from: alice.address });
```

> [Source code: docs/examples/ts/aztecjs_getting_started/index.ts#L33-L37](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/ts/aztecjs_getting_started/index.ts#L33-L37)

Let's check both Alice's and Bob's balances now:

check_balances
```
let { result: aliceBalance } = await token.methods  .balance_of_private(alice.address)  .simulate({ from: alice.address });console.log(`Alice's balance: ${aliceBalance}`);let { result: bobBalance } = await token.methods  .balance_of_private(bob.address)  .simulate({ from: bob.address });console.log(`Bob's balance: ${bobBalance}`);
```

> [Source code: docs/examples/ts/aztecjs_getting_started/index.ts#L39-L48](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/ts/aztecjs_getting_started/index.ts#L39-L48)

Alice should have 100 tokens, while Bob has none yet.

Great! Let's have Alice transfer some tokens to Bob, also in private:

transfer
```
await token.methods.transfer(bob.address, 10).send({ from: alice.address });({ result: bobBalance } = await token.methods  .balance_of_private(bob.address)  .simulate({ from: bob.address }));console.log(`Bob's balance: ${bobBalance}`);
```

> [Source code: docs/examples/ts/aztecjs_getting_started/index.ts#L50-L56](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/ts/aztecjs_getting_started/index.ts#L50-L56)

Bob should now see 10 tokens in his balance.

## Other cool things[​](#other-cool-things)

Say that Alice is nice and wants to set Bob as a minter. Even though it's a public function, it can be called in a similar way:

set_minter
```
await token.methods.set_minter(bob.address, true).send({ from: alice.address });
```

> [Source code: docs/examples/ts/aztecjs_getting_started/index.ts#L58-L60](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/ts/aztecjs_getting_started/index.ts#L58-L60)

Bob is now the minter, so he can mint some tokens to himself:

bob_mints
```
await token.methods  .mint_to_private(bob.address, 100)  .send({ from: bob.address });({ result: bobBalance } = await token.methods  .balance_of_private(bob.address)  .simulate({ from: bob.address }));console.log(`Bob's balance: ${bobBalance}`);
```

> [Source code: docs/examples/ts/aztecjs_getting_started/index.ts#L62-L70](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/ts/aztecjs_getting_started/index.ts#L62-L70)

infoHave a look at the [contract source](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/noir-projects/noir-contracts/contracts/app/token_contract/src/main.nr). Notice is that the `mint_to_private` function we used above actually starts a partial note. This allows the total balance to increase while keeping the recipient private! How cool is that?

## Going Further[​](#going-further)

The pre-compiled token contract used in this tutorial is Aztec's reference implementation. It covers the core operations you need to get started: minting, private transfers, and public balance management.

For production applications, consider the **AIP-20 Token Standard** maintained by [DeFi Wonderland](https://github.com/defi-wonderland/aztec-standards/tree/dev/src/token_contract). AIP-20 formalizes the same patterns used in the reference contract and adds:

- **Commitment-based transfers** for DeFi protocols where the recipient is determined asynchronously
- **Recursive note consumption** for handling large balances that span many notes
- **Tokenized vault support (AIP-4626)** for yield-bearing tokens that issue shares against an underlying asset

To learn how to write a token contract from scratch rather than deploying a pre-compiled one, see the [Private Token Contract tutorial](https://docs.aztec.network/developers/docs/tutorials/contract_tutorials/token_contract). For the full specifications of all Aztec contract standards, see the [Aztec Contract Standards](https://docs.aztec.network/developers/docs/aztec-nr/standards) reference.

[Edit this page](https://github.com/AztecProtocol/aztec-packages/edit/next/docs/docs-developers/docs/tutorials/js_tutorials/aztecjs-getting-started.md)