# Testing Smart Contracts

> Source: https://docs.aztec.network/developers/docs/aztec-js/how_to_test

---

- [![Home](https://docs.aztec.network/img/Aztec_Symbol_Dark.png)![Home](https://docs.aztec.network/img/Aztec%20Symbol_Light.png)](https://docs.aztec.network/)
- [Aztec.js](https://docs.aztec.network/developers/docs/aztec-js)
- Testing Smart Contracts

On this page
# Testing Smart Contracts

This guide covers how to test Aztec smart contracts by connecting to a local network, deploying contracts, and verifying their behavior.

## Prerequisites[​](#prerequisites)

- A running [local Aztec network](https://docs.aztec.network/developers/getting_started_on_local_network)
- A compiled contract artifact (see [How to compile a contract](https://docs.aztec.network/developers/docs/aztec-nr/compiling_contracts))
- Node.js test framework (Jest, Vitest, or similar)

## Setting up the test environment[​](#setting-up-the-test-environment)

Connect to your local Aztec network and create an embedded wallet:

connect_to_network
```
import { createAztecNodeClient, waitForNode } from "@aztec/aztec.js/node";import { EmbeddedWallet } from "@aztec/wallets/embedded";import { getInitialTestAccountsData } from "@aztec/accounts/testing";const nodeUrl = process.env.AZTEC_NODE_URL ?? "http://localhost:8080";const node = createAztecNodeClient(nodeUrl);// Wait for the network to be readyawait waitForNode(node);// Create an EmbeddedWallet connected to the nodeconst wallet = await EmbeddedWallet.create(node, { ephemeral: true });
```

> [Source code: docs/examples/ts/aztecjs_connection/index.ts#L1-L14](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/ts/aztecjs_connection/index.ts#L1-L14)

The `EmbeddedWallet` manages accounts, tracks deployed contracts, and handles transaction proving. It connects to the Aztec node which provides access to both the Private eXecution Environment (PXE) and the network.

## Loading test accounts[​](#loading-test-accounts)

The local network comes with pre-funded accounts. Load them into your wallet:

load_test_accounts
```
import { registerInitialLocalNetworkAccountsInWallet } from "@aztec/wallets/testing";// wallet is the EmbeddedWallet from the setup section aboveconst [alice, bob] = await registerInitialLocalNetworkAccountsInWallet(wallet);
```

> [Source code: docs/examples/ts/aztecjs_testing/index.ts#L117-L122](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/ts/aztecjs_testing/index.ts#L117-L122)

## Deploying contracts in tests[​](#deploying-contracts-in-tests)

Deploy contracts using the generated contract class:

deploy_test_contract
```
// wallet is from the setup section; alice is from registerInitialLocalNetworkAccountsInWalletconst { contract: testToken } = await TokenContract.deploy(  wallet,  alice, // admin  "TestToken",  "TST",  18,).send({ from: alice });
```

> [Source code: docs/examples/ts/aztecjs_testing/index.ts#L124-L133](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/ts/aztecjs_testing/index.ts#L124-L133)

## Verifying contract state[​](#verifying-contract-state)

Use `.simulate()` to read contract state without creating a transaction:

simulate_function
```
const { result: balance } = await token.methods  .balance_of_public(aliceAddress)  .simulate({ from: aliceAddress });console.log(`Alice's token balance: ${balance}`);
```

> [Source code: docs/examples/ts/aztecjs_connection/index.ts#L151-L157](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/ts/aztecjs_connection/index.ts#L151-L157)

Simulations are free (no gas cost) and return the function's result directly. Use them for:

- Checking balances and state before/after transactions
- Validating expected outcomes in assertions
- Debugging contract behavior

## Sending test transactions[​](#sending-test-transactions)

Send transactions and wait for confirmation:

send_transaction
```
const { receipt } = await token.methods  .mint_to_public(aliceAddress, 1000n)  .send({ from: aliceAddress });console.log(`Transaction mined in block ${receipt.blockNumber}`);console.log(`Transaction fee: ${receipt.transactionFee}`);
```

> [Source code: docs/examples/ts/aztecjs_connection/index.ts#L142-L149](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/ts/aztecjs_connection/index.ts#L142-L149)

The `send()` method returns when the transaction is included in a block.

## Example test structure[​](#example-test-structure)

Here's a complete test example showing the typical structure with setup, test cases, and assertions:

complete_test_example
```
import { createAztecNodeClient, waitForNode } from "@aztec/aztec.js/node";import { EmbeddedWallet } from "@aztec/wallets/embedded";import { getInitialTestAccountsData } from "@aztec/accounts/testing";import { TokenContract } from "@aztec/noir-contracts.js/Token";import { AztecAddress } from "@aztec/aztec.js/addresses";// This file demonstrates a complete Jest test structure.// In a real test file, wrap this in describe() and it() blocks.// Test setup variableslet wallet: EmbeddedWallet;let aliceAddress: AztecAddress;let bobAddress: AztecAddress;let token: TokenContract;// beforeAll equivalent - setupasync function setup() {  const node = createAztecNodeClient(    process.env.AZTEC_NODE_URL ?? "http://localhost:8080",  );  await waitForNode(node);  wallet = await EmbeddedWallet.create(node, { ephemeral: true });  const testAccounts = await getInitialTestAccountsData();  [aliceAddress, bobAddress] = await Promise.all(    testAccounts.slice(0, 2).map(async (account) => {      return (        await wallet.createSchnorrInitializerlessAccount(          account.secret,          account.salt,          account.signingKey,        )      ).address;    }),  );  ({ contract: token } = await TokenContract.deploy(    wallet,    aliceAddress,    "Test",    "TST",    18,  ).send({    from: aliceAddress,  }));}// Test: mints tokens to an accountasync function testMintTokens() {  await token.methods    .mint_to_public(aliceAddress, 1000n)    .send({ from: aliceAddress });  const { result: balance } = await token.methods    .balance_of_public(aliceAddress)    .simulate({ from: aliceAddress });  if (balance !== 1000n) {    throw new Error(`Expected balance 1000n, got ${balance}`);  }  console.log("✓ Mint tokens test passed");}// Test: transfers tokens between accountsasync function testTransferTokens() {  // First mint some tokens  await token.methods    .mint_to_public(aliceAddress, 1000n)    .send({ from: aliceAddress });  // Transfer to bob using public transfer  await token.methods    .transfer_in_public(aliceAddress, bobAddress, 100n, 0n)    .send({ from: aliceAddress });  const { result: aliceBalance } = await token.methods    .balance_of_public(aliceAddress)    .simulate({ from: aliceAddress });  const { result: bobBalance } = await token.methods    .balance_of_public(bobAddress)    .simulate({ from: bobAddress });  // Note: balances accumulate from previous test  console.log(`Alice balance: ${aliceBalance}, Bob balance: ${bobBalance}`);  console.log("✓ Transfer tokens test passed");}// Test: reverts when transferring more than balanceasync function testRevertOnOverTransfer() {  const { result: balance } = await token.methods    .balance_of_public(aliceAddress)    .simulate({ from: aliceAddress });  try {    await token.methods      .transfer_in_public(aliceAddress, bobAddress, balance + 1n, 0n)      .simulate({ from: aliceAddress });    throw new Error("Expected simulation to throw");  } catch (error) {    // Expected to throw    console.log("✓ Revert on over-transfer test passed");  }}// Run all testsasync function runTests() {  await setup();  await testMintTokens();  await testTransferTokens();  await testRevertOnOverTransfer();  console.log("\n✓ All tests passed");}await runTests();
```

> [Source code: docs/examples/ts/aztecjs_testing/index.ts#L1-L115](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/ts/aztecjs_testing/index.ts#L1-L115)

## Testing failure cases[​](#testing-failure-cases)

Test that invalid operations revert as expected:

test_revert_case
```
async function testRevertExample() {  // testToken and alice are from the deploy/load sections above  const { result: balance } = await testToken.methods    .balance_of_public(alice)    .simulate({ from: alice });  let reverted = false;  try {    await testToken.methods      .transfer_in_public(alice, bob, balance + 1n, 0n)      .simulate({ from: alice });  } catch (error) {    reverted = true;  }  if (!reverted) {    throw new Error("Expected simulation to revert for over-transfer");  }  console.log("✓ Revert on over-transfer test passed");}await testRevertExample();
```

> [Source code: docs/examples/ts/aztecjs_testing/index.ts#L135-L158](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/ts/aztecjs_testing/index.ts#L135-L158)

Use `.simulate()` to test reverts without spending gas. The simulation will throw if the transaction would fail onchain.

## Simulating with overrides[​](#simulating-with-overrides)

`.simulate()` accepts an `overrides` option that injects values into the simulator's (ephemeral) world-state fork and contract DB before the call runs. The override is scoped to that single simulation and thrown away afterwards.

Override a public-storage slot:

```
const result = await contract.methods.read_balance(account).simulate({  overrides: {    publicStorage: [{ contract: contract.address, slot: BALANCE_SLOT, value: new Fr(1_000_000n) }],  },});
```

Use this to set up state preconditions, reproduce production bugs against pinned storage, or exercise rare value branches without orchestrating the contract calls that produce them.

### Fast-forwarding a contract update[​](#fast-forwarding-a-contract-update)

`fastForwardContractUpdate` returns a `SimulationOverrides` object that simulates a deployed instance as if it had already been upgraded to a new contract class. The new class must already be registered on chain. The cheat mirrors a real onchain upgrade followed by waiting out the upgrade delay: the override instance's `currentContractClassId` is bumped, and the `ContractInstanceRegistry`'s delayed-public-mutable storage is rewritten to look like the upgrade was scheduled in the past.

```
import { fastForwardContractUpdate } from '@aztec/aztec.js';const overrides = await fastForwardContractUpdate({  instanceAddress: contract.address,  newClassId: upgradedClass.id,  node,});const result = await contract.methods.upgraded_method().simulate({ overrides });
```

Use this to test code paths that only execute after an upgrade, without orchestrating the full delayed-mutable upgrade flow.

## Further reading[​](#further-reading)

- [How to read contract data](https://docs.aztec.network/developers/docs/aztec-js/how_to_read_data)
- [How to send transactions](https://docs.aztec.network/developers/docs/aztec-js/how_to_send_transaction)
- [How to deploy a contract](https://docs.aztec.network/developers/docs/aztec-js/how_to_deploy_contract)
- [How to create an account](https://docs.aztec.network/developers/docs/aztec-js/how_to_create_account)
- [How to compile a contract](https://docs.aztec.network/developers/docs/aztec-nr/compiling_contracts)

**Tags:**
- [contracts](https://docs.aztec.network/developers/tags/contracts)
- [tests](https://docs.aztec.network/developers/tags/tests)

[Edit this page](https://github.com/AztecProtocol/aztec-packages/edit/next/docs/docs-developers/docs/aztec-js/how_to_test.md)