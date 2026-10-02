# Using Authentication Witnesses

> Source: https://docs.aztec.network/developers/docs/aztec-js/how_to_use_authwit

---

- [![Home](https://docs.aztec.network/img/Aztec_Symbol_Dark.png)![Home](https://docs.aztec.network/img/Aztec%20Symbol_Light.png)](https://docs.aztec.network/)
- [Aztec.js](https://docs.aztec.network/developers/docs/aztec-js)
- Using Authentication Witnesses

On this page
# Using Authentication Witnesses

This guide shows you how to create and use authentication witnesses (authwits) to authorize other accounts to perform actions on your behalf.

Automatic private authwits with EmbeddedWalletWhen using `EmbeddedWallet`, **private authwits are created automatically**. The wallet simulates your transaction before sending and detects which private authwits are needed, then generates them on the fly. You don't need to create them manually.

Public authwits still need to be set explicitly, as they require a separate onchain transaction before use. The manual approach described below is also relevant if you're building a custom wallet implementation.

aztec-nrUsing AuthWitnesses is always a two-part process. This guide shows how to generate and use them, but you still need to set up your contract to accept and authenticate them.

Therefore it is recommended to read the `aztec-nr` [guide on authwitnesses](https://docs.aztec.network/developers/docs/aztec-nr/framework-description/authentication_witnesses) before this one.

## Prerequisites[​](#prerequisites)

- [Connected to a network](https://docs.aztec.network/developers/docs/aztec-js/how_to_connect_to_local_network) with an `EmbeddedWallet` instance and funded accounts
- Contract with authwit validation (see [smart contract authwits](https://docs.aztec.network/developers/docs/aztec-nr/framework-description/authentication_witnesses))
- Understanding of [authwit concepts](https://docs.aztec.network/developers/docs/foundational-topics/advanced/authwit)

## Intent types[​](#intent-types)

The authwit system supports different intent types depending on your use case:

- **`CallIntent`**: Use when authorizing a specific contract function call. Contains `{ caller, call }` where `call` is a `FunctionCall`, typically obtained with `await interaction.getFunctionCall()`.
- **`ContractFunctionInteractionCallIntent`**: Convenience form that takes the interaction directly. Contains `{ caller, action }` where `action` is a `ContractFunctionInteraction`; internally resolved to a `FunctionCall` before signing.
- **`IntentInnerHash`**: Use when authorizing arbitrary data. Contains `{ consumer, innerHash }` where `consumer` is the contract that will verify the authwit.

## Create private authwits[​](#create-private-authwits)

noteIf you're using `EmbeddedWallet`, this section is handled for you automatically. See the tip above.

Private authwits authorize actions in the private domain. The authorization is included directly in the transaction that uses it.

Let's say Alice wants to allow Bob to transfer tokens from her account. Alice is the **authorizer** (she owns the tokens) and Bob is the **caller** (he will execute the transfer):

private_authwit
```
// Alice wants to allow Bob to transfer tokens from her account (private)const privateNonce = Fr.random();// Define the action Bob will executeconst privateAction = tokenContract.methods.transfer_in_private(  aliceAddress, // from  bobAddress, // to  100n, // amount  privateNonce, // authwit nonce for replay protection);// Alice creates an authwit authorizing Bob to call this functionconst privateWitness = await wallet.createAuthWit(aliceAddress, {  caller: bobAddress,  call: await privateAction.getFunctionCall(),});// Bob executes the transfer, providing the authwit// additionalScopes lets the PXE access Alice's private state// during authwit verificationawait privateAction.send({  from: bobAddress,  authWitnesses: [privateWitness],  additionalScopes: [aliceAddress],});
```

> [Source code: docs/examples/ts/aztecjs_authwit/index.ts#L45-L71](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/ts/aztecjs_authwit/index.ts#L45-L71)

tipThe nonce prevents replay attacks. When `from` and `msg_sender` are the same (self-transfer), set the nonce to `0`.

## Create public authwits[​](#create-public-authwits)

Public authwits require a transaction to store the authorization in the `AuthRegistry` contract before the authorized action can be executed:

public_authwit
```
// Alice wants to allow Bob to transfer tokens from her account (public)const publicNonce = Fr.random();// Define the action Bob will executeconst publicAction = tokenContract.methods.transfer_in_public(  aliceAddress, // from  bobAddress, // to  100n, // amount  publicNonce, // authwit nonce);// Alice sets the public authwit (this requires a transaction)const authwit = await SetPublicAuthwitContractInteraction.create(  wallet,  aliceAddress,  { caller: bobAddress, action: publicAction },  true, // authorized);await authwit.send();// Now Bob can execute the transferawait publicAction.send({ from: bobAddress });
```

> [Source code: docs/examples/ts/aztecjs_authwit/index.ts#L73-L96](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/ts/aztecjs_authwit/index.ts#L73-L96)

## Create arbitrary message authwits[​](#create-arbitrary-message-authwits)

Use this when authorizing arbitrary data rather than a specific contract function call:

arbitrary_authwit
```
import { computeInnerAuthWitHash } from "@aztec/aztec.js/authorization";// Create hash of arbitrary dataconst innerHash = await computeInnerAuthWitHash([  Fr.fromHexString("0xcafe"),  Fr.fromHexString("0xbeef"),]);// Create an intent with the consumer contract addressconst intent = {  consumer: tokenContract.address,  innerHash,};// Create the authwit for arbitrary dataconst arbitraryWitness = await wallet.createAuthWit(aliceAddress, intent);console.log("Arbitrary authwit created:", arbitraryWitness);
```

> [Source code: docs/examples/ts/aztecjs_authwit/index.ts#L98-L116](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/ts/aztecjs_authwit/index.ts#L98-L116)

The `consumer` is the contract address that will verify this authwit.

## Revoke public authwits[​](#revoke-public-authwits)

Public authwits can be revoked by setting `authorized` to `false`:

revoke_authwit
```
// Revoke a public authwit by setting authorized to falseconst revokeNonce = Fr.random();const revokeAction = tokenContract.methods.transfer_in_public(  aliceAddress,  bobAddress,  50n,  revokeNonce,);// First, set the authwitconst setAuthwit = await SetPublicAuthwitContractInteraction.create(  wallet,  aliceAddress,  { caller: bobAddress, action: revokeAction },  true,);await setAuthwit.send();// Later, revoke itconst revokeInteraction = await SetPublicAuthwitContractInteraction.create(  wallet,  aliceAddress,  { caller: bobAddress, action: revokeAction },  false, // revoke authorization);await revokeInteraction.send();
```

> [Source code: docs/examples/ts/aztecjs_authwit/index.ts#L118-L145](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/ts/aztecjs_authwit/index.ts#L118-L145)

## Next steps[​](#next-steps)

- Learn about [authwits in smart contracts](https://docs.aztec.network/developers/docs/aztec-nr/framework-description/authentication_witnesses)
- Understand [authwit concepts](https://docs.aztec.network/developers/docs/foundational-topics/advanced/authwit)
- Explore [account abstraction](https://docs.aztec.network/developers/docs/foundational-topics/accounts)

**Tags:**
- [accounts](https://docs.aztec.network/developers/tags/accounts)
- [authwit](https://docs.aztec.network/developers/tags/authwit)

[Edit this page](https://github.com/AztecProtocol/aztec-packages/edit/next/docs/docs-developers/docs/aztec-js/how_to_use_authwit.md)