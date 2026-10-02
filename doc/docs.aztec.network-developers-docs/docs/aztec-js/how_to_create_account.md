# Creating Accounts

> Source: https://docs.aztec.network/developers/docs/aztec-js/how_to_create_account

---

- [![Home](https://docs.aztec.network/img/Aztec_Symbol_Dark.png)![Home](https://docs.aztec.network/img/Aztec%20Symbol_Light.png)](https://docs.aztec.network/)
- [Aztec.js](https://docs.aztec.network/developers/docs/aztec-js)
- Creating Accounts

On this page
# Creating Accounts

This guide shows you how to create and deploy a new account on Aztec.

## Prerequisites[​](#prerequisites)

- [Connected to a network](https://docs.aztec.network/developers/docs/aztec-js/how_to_connect_to_local_network) with a `EmbeddedWallet` instance
- Understanding of [account concepts](https://docs.aztec.network/developers/docs/foundational-topics/accounts)

## Install dependencies[​](#install-dependencies)

```
yarn add @aztec/aztec.js@5.2.0 @aztec/wallets@5.2.0 @aztec/noir-contracts.js@5.2.0
```

## Create a new account[​](#create-a-new-account)

Using the [`wallet` from the connection guide](https://docs.aztec.network/developers/docs/aztec-js/how_to_connect_to_local_network), call `createSchnorrAccount` to create a new account with a random secret, salt, and signing key:

create_account
```
import { Fr, GrumpkinScalar } from "@aztec/aztec.js/fields";const secret = Fr.random();const salt = Fr.random();const signingKey = GrumpkinScalar.random();const newAccount = await wallet.createSchnorrAccount(secret, salt, signingKey);console.log("New account address:", newAccount.address.toString());
```

> [Source code: docs/examples/ts/aztecjs_connection/index.ts#L47-L55](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/ts/aztecjs_connection/index.ts#L47-L55)

The secret derives the account's encryption keys, the signing key authenticates its transactions, and the salt ensures address uniqueness. The signing key is provided independently and is not derived from the secret: it is an ownership key, so keep it separate from the encryption secret that your PXE holds.

Store your secret, salt, and signing keySave the `secret`, `salt`, and `signingKey` values securely. You need all three to recover access to your account. If you lose them, you will permanently lose access to the account and any assets it holds.

## Deploy the account[​](#deploy-the-account)

New accounts must be deployed before they can send transactions. Deployment requires paying fees.

### Using the Sponsored FPC[​](#using-the-sponsored-fpc)

If your account doesn't have Fee Juice, use the [Sponsored FPC](https://docs.aztec.network/developers/docs/aztec-js/how_to_pay_fees#sponsored-fpc):

deploy_account_sponsored_fpc
```
// Additional imports needed for account deployment examplesimport { NO_FROM } from "@aztec/aztec.js/account";import { SponsoredFeePaymentMethod } from "@aztec/aztec.js/fee/testing";import { SponsoredFPCContract } from "@aztec/noir-contracts.js/SponsoredFPC";import { getContractInstanceFromInstantiationParams } from "@aztec/stdlib/contract";// Set up the Sponsored FPC payment method (see fees guide for details)const sponsoredFPCInstance = await getContractInstanceFromInstantiationParams(  SponsoredFPCContract.artifact,  { salt: new Fr(0) },);await wallet.registerContract(  sponsoredFPCInstance,  SponsoredFPCContract.artifact,);const sponsoredPaymentMethod = new SponsoredFeePaymentMethod(  sponsoredFPCInstance.address,);// newAccount is the account created in the previous sectionconst deployMethod = await newAccount.getDeployMethod();await deployMethod.send({  from: NO_FROM,  fee: { paymentMethod: sponsoredPaymentMethod },});
```

> [Source code: docs/examples/ts/aztecjs_connection/index.ts#L57-L83](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/ts/aztecjs_connection/index.ts#L57-L83)

infoSee the [guide on fees](https://docs.aztec.network/developers/docs/aztec-js/how_to_pay_fees#sponsored-fpc) for more details on the Sponsored FPC and what this snippet means.

### Using Fee Juice[​](#using-fee-juice)

If your account has Fee Juice from a [bridge from L1](https://docs.aztec.network/developers/docs/aztec-js/how_to_pay_fees#bridge-fee-juice-from-l1), you can claim it and deploy in one step using `FeeJuicePaymentMethodWithClaim`.

Create a new Schnorr account for this path:

create_fee_juice_account
```
// `feeJuiceAccount` is just another Schnorr account, the same kind as// `newAccount` above. It gets its own name here so both deploy paths// can coexist in one example; in your own code, pick whichever name fits.const feeJuiceSecret = Fr.random();const feeJuiceSalt = Fr.random();const feeJuiceSigningKey = GrumpkinScalar.random();const feeJuiceAccount = await wallet.createSchnorrAccount(  feeJuiceSecret,  feeJuiceSalt,  feeJuiceSigningKey,);
```

> [Source code: docs/examples/ts/aztecjs_connection/index.ts#L85-L97](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/ts/aztecjs_connection/index.ts#L85-L97)

Claim the bridged Fee Juice and deploy in one step:

bridge_fee_juice_claim
```
import { FeeJuicePaymentMethodWithClaim } from "@aztec/aztec.js/fee";// claim is from the bridgeTokensPublic step above// Create a payment method that claims the bridged Fee Juice and uses it to payconst bridgePaymentMethod = new FeeJuicePaymentMethodWithClaim(  feeJuiceAccount.address,  claim,);// Use it to pay for any transaction; here we deploy the account in one stepconst deployMethodBridged = await feeJuiceAccount.getDeployMethod();await deployMethodBridged.send({  from: NO_FROM,  fee: { paymentMethod: bridgePaymentMethod },});
```

> [Source code: docs/examples/ts/aztecjs_connection/index.ts#L166-L182](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/ts/aztecjs_connection/index.ts#L166-L182)

If the account already has Fee Juice on L2 (for example, from a faucet or a previously claimed bridge), no special payment method is needed — just call `send({ from: NO_FROM })` and Fee Juice is used automatically.

The `from: NO_FROM` signals that this transaction should be executed without account contract mediation. The wallet will directly execute it via a default entrypoint with no authorization.

## Verify deployment[​](#verify-deployment)

Confirm the account was deployed successfully. Substitute the account variable for whichever path you used above (`newAccount` for the Sponsored FPC path, `feeJuiceAccount` for the Fee Juice path):

verify_account_deployment
```
// `newAccount` refers to whichever account you just deployed,// either the Sponsored FPC account or `feeJuiceAccount` from the Fee Juice path.const metadata = await wallet.getContractMetadata(newAccount.address);console.log("Account deployed:", metadata.initializationStatus);
```

> [Source code: docs/examples/ts/aztecjs_connection/index.ts#L184-L189](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/ts/aztecjs_connection/index.ts#L184-L189)

## Next steps[​](#next-steps)

- [Deploy contracts](https://docs.aztec.network/developers/docs/aztec-js/how_to_deploy_contract) with your new account
- [Send transactions](https://docs.aztec.network/developers/docs/aztec-js/how_to_send_transaction) from an account
- Learn about [account abstraction](https://docs.aztec.network/developers/docs/foundational-topics/accounts)
- Implement [authentication witnesses](https://docs.aztec.network/developers/docs/aztec-js/how_to_use_authwit)

**Tags:**
- [accounts](https://docs.aztec.network/developers/tags/accounts)

[Edit this page](https://github.com/AztecProtocol/aztec-packages/edit/next/docs/docs-developers/docs/aztec-js/how_to_create_account.md)