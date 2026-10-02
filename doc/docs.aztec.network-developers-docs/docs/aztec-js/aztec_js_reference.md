# Reference

> Source: https://docs.aztec.network/developers/docs/aztec-js/aztec_js_reference

---

- [![Home](https://docs.aztec.network/img/Aztec_Symbol_Dark.png)![Home](https://docs.aztec.network/img/Aztec%20Symbol_Light.png)](https://docs.aztec.network/)
- [Aztec.js](https://docs.aztec.network/developers/docs/aztec-js)
- Reference

On this page
# Reference

*This documentation is auto-generated from the Aztec.js TypeScript source code.*

infoThis is an auto-generated reference. For tutorials and guides, see the [Aztec.js Guide](https://docs.aztec.network/developers/docs/aztec-js).

*Package: @aztec/aztec.js*

*Generated: 2026-08-19T11:34:32.056Z*

This document provides a comprehensive reference for all public APIs in the Aztec.js library.

Each section is organized by module, with classes, interfaces, types, and functions documented with their full signatures, parameters, and return types.

## Table of Contents[​](#table-of-contents)

- [Account](#account)

  - [AuthorizationProvider](#authorizationprovider)
  - [Account](#account-1)
  - [BaseAccount](#baseaccount)
  - [AccountContract](#accountcontract)
  - [getAccountContractAddress](#getaccountcontractaddress)
- [Authorization](#authorization)

  - [CallAuthorizationRequest](#callauthorizationrequest)
- [Contract](#contract)

  - [BaseContractInteraction](#basecontractinteraction)
  - [BatchCall](#batchcall)
  - [abiChecker](#abichecker)
  - [Contract](#contract-1)
  - [ContractMethod](#contractmethod)
  - [ContractStorageLayout](#contractstoragelayout)
  - [ContractBase](#contractbase)
  - [ContractFunctionInteraction](#contractfunctioninteraction)
  - [DeployInstantiationOptions](#deployinstantiationoptions)
  - [BoundInstantiationOptions](#boundinstantiationoptions)
  - [UniversalInstantiationOptions](#universalinstantiationoptions)
  - [PendingInstantiationOptions](#pendinginstantiationoptions)
  - [DeployMethodContract](#deploymethodcontract)
  - [DeployMethodPayload](#deploymethodpayload)
  - [RequestDeployOptions](#requestdeployoptions)
  - [DeployOptionsWithoutWait](#deployoptionswithoutwait)
  - [DeployOptions](#deployoptions)
  - [SimulateDeployOptions](#simulatedeployoptions)
  - [DeployResultMined](#deployresultmined)
  - [DeployReturn](#deployreturn)
  - [DeployMethod](#deploymethod)
  - [BoundDeployMethod](#bounddeploymethod)
  - [UniversalDeployMethod](#universaldeploymethod)
  - [PendingDeployMethod](#pendingdeploymethod)
  - [fastForwardContractUpdate](#fastforwardcontractupdate)
  - [FeePaymentMethodOption](#feepaymentmethodoption)
  - [GasSettingsOption](#gassettingsoption)
  - [InteractionFeeOptions](#interactionfeeoptions)
  - [RequestInteractionOptions](#requestinteractionoptions)
  - [NO_WAIT](#no_wait)
  - [NoWait](#nowait)
  - [NO_FROM](#no_from)
  - [NoFrom](#nofrom)
  - [InteractionWaitOptions](#interactionwaitoptions)
  - [SendInteractionOptionsWithoutWait](#sendinteractionoptionswithoutwait)
  - [SendInteractionOptions](#sendinteractionoptions)
  - [SimulateInteractionOptions](#simulateinteractionoptions)
  - [ProfileInteractionOptions](#profileinteractionoptions)
  - [OffchainMessage](#offchainmessage)
  - [OffchainOutput](#offchainoutput)
  - [extractOffchainOutput](#extractoffchainoutput)
  - [SimulationResult](#simulationresult)
  - [TxSendResultImmediate](#txsendresultimmediate)
  - [TxSendResultMined](#txsendresultmined)
  - [SendReturn](#sendreturn)
  - [toSendOptions](#tosendoptions)
  - [toSimulateOptions](#tosimulateoptions)
  - [toProfileOptions](#toprofileoptions)
  - [WaitForProvenOpts](#waitforprovenopts)
  - [DefaultWaitForProvenOpts](#defaultwaitforprovenopts)
  - [waitForProven](#waitforproven)
  - [WaitOpts](#waitopts)
  - [DefaultWaitOpts](#defaultwaitopts)
- [Deployment](#deployment)

  - [ContractDeployer](#contractdeployer)
  - [publishContractClass](#publishcontractclass)
  - [publishInstance](#publishinstance)
- [Ethereum](#ethereum)

  - [L2Claim](#l2claim)
  - [L2AmountClaim](#l2amountclaim)
  - [L2AmountClaimWithRecipient](#l2amountclaimwithrecipient)
  - [generateClaimSecret](#generateclaimsecret)
  - [L1TokenManager](#l1tokenmanager)
  - [L1FeeJuicePortalManager](#l1feejuiceportalmanager)
  - [L1ToL2TokenPortalManager](#l1tol2tokenportalmanager)
  - [L1TokenPortalManager](#l1tokenportalmanager)
- [Fee](#fee-4)

  - [FeeJuicePaymentMethodWithClaim](#feejuicepaymentmethodwithclaim)
  - [FeePaymentMethod](#feepaymentmethod)
  - [PrivateFeePaymentMethod](#privatefeepaymentmethod)
  - [PublicFeePaymentMethod](#publicfeepaymentmethod)
  - [SponsoredFeePaymentMethod](#sponsoredfeepaymentmethod)
- [Utils](#utils)

  - [FieldLike](#fieldlike)
  - [EthAddressLike](#ethaddresslike)
  - [AztecAddressLike](#aztecaddresslike)
  - [FunctionSelectorLike](#functionselectorlike)
  - [EventSelectorLike](#eventselectorlike)
  - [U128Like](#u128like)
  - [WrappedFieldLike](#wrappedfieldlike)
  - [OptionLike](#optionlike)
  - [IntentInnerHash](#intentinnerhash)
  - [CallIntent](#callintent)
  - [ContractFunctionInteractionCallIntent](#contractfunctioninteractioncallintent)
  - [isContractFunctionInteractionCallIntent](#iscontractfunctioninteractioncallintent)
  - [computeAuthWitMessageHash](#computeauthwitmessagehash)
  - [getMessageHashFromIntent](#getmessagehashfromintent)
  - [computeInnerAuthWitHashFromAction](#computeinnerauthwithashfromaction)
  - [lookupValidity](#lookupvalidity)
  - [SetPublicAuthwitContractInteraction](#setpublicauthwitcontractinteraction)
  - [waitForL1ToL2MessageReady](#waitforl1tol2messageready)
  - [isL1ToL2MessageReady](#isl1tol2messageready)
  - [getFeeJuiceBalance](#getfeejuicebalance)
  - [readFieldCompressedString](#readfieldcompressedstring)
  - [waitForNode](#waitfornode)
  - [waitForTx](#waitfortx)
  - [createAztecNodeClient](#createaztecnodeclient)
  - [AztecNode](#aztecnode)
  - [generatePublicKey](#generatepublickey)
- [Wallet](#wallet)

  - [AccountEntrypointMetaPaymentMethod](#accountentrypointmetapaymentmethod)
  - [AccountManagerCreateOptions](#accountmanagercreateoptions)
  - [AccountManager](#accountmanager)
  - [CAPABILITY_VERSION](#capability_version)
  - [ContractFunctionPattern](#contractfunctionpattern)
  - [AccountsCapability](#accountscapability)
  - [GrantedAccountsCapability](#grantedaccountscapability)
  - [ContractsCapability](#contractscapability)
  - [GrantedContractsCapability](#grantedcontractscapability)
  - [ContractClassesCapability](#contractclassescapability)
  - [GrantedContractClassesCapability](#grantedcontractclassescapability)
  - [SimulationCapability](#simulationcapability)
  - [GrantedSimulationCapability](#grantedsimulationcapability)
  - [TransactionCapability](#transactioncapability)
  - [GrantedTransactionCapability](#grantedtransactioncapability)
  - [DataCapability](#datacapability)
  - [GrantedDataCapability](#granteddatacapability)
  - [Capability](#capability)
  - [GrantedCapability](#grantedcapability)
  - [AppCapabilities](#appcapabilities)
  - [WalletCapabilities](#walletcapabilities)
  - [DeployAccountFeePaymentMethodOption](#deployaccountfeepaymentmethodoption)
  - [RequestDeployAccountOptions](#requestdeployaccountoptions)
  - [DeployAccountOptions](#deployaccountoptions)
  - [SimulateDeployAccountOptions](#simulatedeployaccountoptions)
  - [DeployAccountMethod](#deployaccountmethod)
  - [TxSimulationResultWithAppOffset](#txsimulationresultwithappoffset)
  - [Aliased](#aliased)
  - [SimulateOptions](#simulateoptions)
  - [ProfileOptions](#profileoptions)
  - [SendOptions](#sendoptions)
  - [BatchableMethods](#batchablemethods)
  - [BatchedMethod](#batchedmethod)
  - [BatchedMethodResult](#batchedmethodresult)
  - [BatchedMethodResultWrapper](#batchedmethodresultwrapper)
  - [BatchResults](#batchresults)
  - [EventFilterBase](#eventfilterbase)
  - [PrivateEventFilter](#privateeventfilter)
  - [PublicEventFilter](#publiceventfilter)
  - [Event](#event)
  - [PrivateEvent](#privateevent)
  - [PublicEvent](#publicevent)
  - [ContractMetadata](#contractmetadata)
  - [ContractClassMetadata](#contractclassmetadata)
  - [ExecuteUtilityOptions](#executeutilityoptions)
  - [Wallet](#wallet-2)
  - [ExecutionPayloadSchema](#executionpayloadschema)
  - [GasSettingsOptionSchema](#gassettingsoptionschema)
  - [WaitOptsSchema](#waitoptsschema)
  - [SendOptionsSchema](#sendoptionsschema)
  - [SimulateOptionsSchema](#simulateoptionsschema)
  - [ProfileOptionsSchema](#profileoptionsschema)
  - [MessageHashOrIntentSchema](#messagehashorintentschema)
  - [EventMetadataDefinitionSchema](#eventmetadatadefinitionschema)
  - [PrivateEventFilterSchema](#privateeventfilterschema)
  - [PublicEventFilterSchema](#publiceventfilterschema)
  - [PrivateEventSchema](#privateeventschema)
  - [PublicEventSchema](#publiceventschema)
  - [ContractMetadataSchema](#contractmetadataschema)
  - [ContractClassMetadataSchema](#contractclassmetadataschema)
  - [ContractFunctionPatternSchema](#contractfunctionpatternschema)
  - [AccountsCapabilitySchema](#accountscapabilityschema)
  - [GrantedAccountsCapabilitySchema](#grantedaccountscapabilityschema)
  - [ContractsCapabilitySchema](#contractscapabilityschema)
  - [GrantedContractsCapabilitySchema](#grantedcontractscapabilityschema)
  - [ContractClassesCapabilitySchema](#contractclassescapabilityschema)
  - [GrantedContractClassesCapabilitySchema](#grantedcontractclassescapabilityschema)
  - [SimulationCapabilitySchema](#simulationcapabilityschema)
  - [GrantedSimulationCapabilitySchema](#grantedsimulationcapabilityschema)
  - [TransactionCapabilitySchema](#transactioncapabilityschema)
  - [GrantedTransactionCapabilitySchema](#grantedtransactioncapabilityschema)
  - [DataCapabilitySchema](#datacapabilityschema)
  - [GrantedDataCapabilitySchema](#granteddatacapabilityschema)
  - [CapabilitySchema](#capabilityschema)
  - [GrantedCapabilitySchema](#grantedcapabilityschema)
  - [AppCapabilitiesSchema](#appcapabilitiesschema)
  - [WalletCapabilitiesSchema](#walletcapabilitiesschema)
  - [BatchedMethodSchema](#batchedmethodschema)
  - [BatchedResultSchema](#batchedresultschema)
  - [WalletSchema](#walletschema)

---

## Account[​](#account)

---

### `account/account.ts`[​](#accountaccountts)

#### AuthorizationProvider[​](#authorizationprovider)

**Type:** Interface

Provides authorization for actions via the AuthWitness mechanism.

#### Methods[​](#methods)

##### createAuthWit[​](#createauthwit)

Creates an authentication witness from an inner hash with consumer, or a call intent

**Signature:**

```
createAuthWit(  intent: IntentInnerHash | CallIntent,  chainInfo: ChainInfo): Promise<AuthWitness>
```

**Parameters:**

- `intent`: `IntentInnerHash | CallIntent`

  - The action (or inner hash) to authorize
- `chainInfo`: `ChainInfo`

  - Chain information needed for message hash computation

**Returns:**

`Promise<AuthWitness>`

#### Account[​](#account-1)

**Type:** Type Alias

Minimal interface for transaction execution and authorization.

**Signature:**

```
export type Account = EntrypointInterface & AuthorizationProvider & { getCompleteAddress(): CompleteAddress; getAddress(): AztecAddress; };
```

**Type Members:**

##### getCompleteAddress[​](#getcompleteaddress)

Returns the complete address for this account.

**Signature:**

```
getCompleteAddress(): CompleteAddress
```

**Returns:**

`CompleteAddress`

##### getAddress[​](#getaddress)

Returns the address for this account.

**Signature:**

```
getAddress(): AztecAddress
```

**Returns:**

`AztecAddress`

#### BaseAccount[​](#baseaccount)

**Type:** Class

An account implementation that uses authwits as an authentication mechanism and can assemble transaction execution requests for an entrypoint.

**Implements:** `Account`

#### Constructor[​](#constructor)

**Signature:**

```
constructor(  private entrypoint: EntrypointInterface,  private authWitnessProvider: AuthWitnessProvider,  private completeAddress: CompleteAddress)
```

**Parameters:**

- `entrypoint`: `EntrypointInterface`
- `authWitnessProvider`: `AuthWitnessProvider`
- `completeAddress`: `CompleteAddress`

#### Methods[​](#methods-1)

##### createTxExecutionRequest[​](#createtxexecutionrequest)

**Signature:**

```
createTxExecutionRequest(  exec: ExecutionPayload,  gasSettings: GasSettings,  chainInfo: ChainInfo,  options: DefaultAccountEntrypointOptions): Promise<TxExecutionRequest>
```

**Parameters:**

- `exec`: `ExecutionPayload`
- `gasSettings`: `GasSettings`
- `chainInfo`: `ChainInfo`
- `options`: `DefaultAccountEntrypointOptions`

**Returns:**

`Promise<TxExecutionRequest>`

##### wrapExecutionPayload[​](#wrapexecutionpayload)

**Signature:**

```
wrapExecutionPayload(  exec: ExecutionPayload,  chainInfo: ChainInfo,  options?: any): Promise<ExecutionPayload>
```

**Parameters:**

- `exec`: `ExecutionPayload`
- `chainInfo`: `ChainInfo`
- `options` (optional): `any`

**Returns:**

`Promise<ExecutionPayload>`

##### createAuthWit[​](#createauthwit-1)

**Signature:**

```
async createAuthWit(  messageHashOrIntent: CallIntent | IntentInnerHash,  chainInfo: ChainInfo): Promise<AuthWitness>
```

**Parameters:**

- `messageHashOrIntent`: `CallIntent | IntentInnerHash`
- `chainInfo`: `ChainInfo`

**Returns:**

`Promise<AuthWitness>`

##### getCompleteAddress[​](#getcompleteaddress-1)

**Signature:**

```
getCompleteAddress(): CompleteAddress
```

**Returns:**

`CompleteAddress`

##### getAddress[​](#getaddress-1)

**Signature:**

```
getAddress(): AztecAddress
```

**Returns:**

`AztecAddress`

---

### `account/account_contract.ts`[​](#accountaccount_contractts)

#### AccountContract[​](#accountcontract)

**Type:** Interface

An account contract instance. Knows its artifact, deployment arguments, how to create transaction execution requests out of function calls, and how to authorize actions.

#### Methods[​](#methods-2)

##### getContractArtifact[​](#getcontractartifact)

Returns the artifact of this account contract.

**Signature:**

```
getContractArtifact(): Promise<ContractArtifact>
```

**Returns:**

`Promise<ContractArtifact>`

##### getInitializationFunctionAndArgs[​](#getinitializationfunctionandargs)

Returns the initializer function name and arguments for this instance, or undefined if this contract does not require initialization.

**Signature:**

```
getInitializationFunctionAndArgs(): Promise<{      constructorName: string;      constructorArgs: any[];  } | undefined>
```

**Returns:**

```
Promise<    | {        /** The name of the function used to initialize the contract */        constructorName: string;        /** The args to the function used to initialize the contract */        constructorArgs: any[];      }    | undefined  >
```

##### getImmutablesHash[​](#getimmutableshash)

The hash of this account's immutable instantiation params, committed into its address. Returns undefined for accounts that have no immutables (these are instead deployed via an onchain initializer, which contributes to the address through its initialization hash).

**Signature:**

```
getImmutablesHash(): Promise<Fr | undefined>
```

**Returns:**

`Promise<Fr | undefined>`

##### getAccount[​](#getaccount)

Returns the account implementation for this account contract given an instance at the provided address. The account is responsible for assembling tx requests given requested function calls, and for creating signed auth witnesses given action identifiers (message hashes).

**Signature:**

```
getAccount(address: CompleteAddress): Account
```

**Parameters:**

- `address`: `CompleteAddress`

  - Address of this account contract.

**Returns:**

`Account` - An account instance for creating tx requests and authorizing actions.

##### getAuthWitnessProvider[​](#getauthwitnessprovider)

Returns the auth witness provider for the given address.

**Signature:**

```
getAuthWitnessProvider(address: CompleteAddress): AuthWitnessProvider
```

**Parameters:**

- `address`: `CompleteAddress`

  - Address for which to create auth witnesses.

**Returns:**

`AuthWitnessProvider`

#### getAccountContractAddress[​](#getaccountcontractaddress)

**Type:** Function

Compute the address of an account contract from secret, salt and optional immutables hash

**Signature:**

```
export async getAccountContractAddress(  accountContract: AccountContract,  secret: Fr,  salt: Fr,  immutablesHash?: Fr)
```

**Parameters:**

- `accountContract`: `AccountContract`
- `secret`: `Fr`
- `salt`: `Fr`
- `immutablesHash` (optional): `Fr`

**Returns:**

`Promise<any>`

## Authorization[​](#authorization)

---

### `authorization/call_authorization_request.ts`[​](#authorizationcall_authorization_requestts)

#### CallAuthorizationRequest[​](#callauthorizationrequest)

**Type:** Class

An authwit request for a function call. Includes the preimage of the data to be signed, as opposed of just the inner hash.

#### Constructor[​](#constructor-1)

**Signature:**

```
private constructor(  public selector: AuthorizationSelector,  public innerHash: Fr,  public onBehalfOf: AztecAddress,  public msgSender: AztecAddress,  public functionSelector: FunctionSelector,  public argsHash: Fr,  public args: Fr[])
```

**Parameters:**

- `selector`: `AuthorizationSelector`

  - The selector of the authwit type, used to identify it when emitted from `emit_offchain_effect`oracle. Computed as poseidon2("CallAuthwit((Field),(u32),Field)".to_bytes())
- `innerHash`: `Fr`

  - The inner hash of the authwit, computed as poseidon2([msg_sender, selector, args_hash])
- `onBehalfOf`: `AztecAddress`

  - The address on whose behalf the auth witness should be created. This is the account that must sign the authorization.
- `msgSender`: `AztecAddress`

  - The address performing the call
- `functionSelector`: `FunctionSelector`

  - The selector of the function that is to be authorized
- `argsHash`: `Fr`

  - The hash of the arguments to the function call,
- `args`: `Fr[]`

  - The arguments to the function call.

#### Methods[​](#methods-3)

##### getSelector[​](#getselector)

**Signature:**

```
static getSelector(): Promise<AuthorizationSelector>
```

**Returns:**

`Promise<AuthorizationSelector>`

##### fromFields[​](#fromfields)

**Signature:**

```
static async fromFields(fields: Fr[]): Promise<CallAuthorizationRequest>
```

**Parameters:**

- `fields`: `Fr[]`

**Returns:**

`Promise<CallAuthorizationRequest>`

## Contract[​](#contract)

---

### `contract/base_contract_interaction.ts`[​](#contractbase_contract_interactionts)

#### BaseContractInteraction[​](#basecontractinteraction)

**Type:** Class

Base class for an interaction with a contract, be it a deployment, a function call, or a batch. Implements the sequence create/simulate/send.

#### Constructor[​](#constructor-2)

**Signature:**

```
constructor(  protected wallet: Wallet,  protected authWitnesses: AuthWitness[] = [],  protected capsules: Capsule[] = [])
```

**Parameters:**

- `wallet`: `Wallet`
- `authWitnesses` (optional): `AuthWitness[]`
- `capsules` (optional): `Capsule[]`

#### Properties[​](#properties)

##### log[​](#log)

**Type:** `any`

#### Methods[​](#methods-4)

##### request[​](#request)

Returns an execution request that represents this operation. Can be used as a building block for constructing batch requests.

**Signature:**

```
public abstract request(options?: RequestInteractionOptions): Promise<ExecutionPayload>
```

**Parameters:**

- `options` (optional): `RequestInteractionOptions`

  - An optional object containing additional configuration for the transaction.

**Returns:**

`Promise<ExecutionPayload>` - An execution request wrapped in promise.

##### send[​](#send)

Sends a transaction to the contract function with the specified options. By default, waits for the transaction to be mined and returns the receipt (or custom type).

**Signature:**

```
public send<TReturn = TxReceipt>(options: SendInteractionOptionsWithoutWait): Promise<TxSendResultMined<TReturn>>
```

**Parameters:**

- `options`: `SendInteractionOptionsWithoutWait`

  - An object containing 'from' property representing the AztecAddress of the sender, optional fee configuration, and optional wait settings

**Returns:**

`Promise<TxSendResultMined<TReturn>>` - TReturn (if wait is undefined/WaitOpts) or TxHash (if wait is NO_WAIT)

##### send[​](#send-1)

**Signature:**

```
public send<TReturn = TxReceipt, W extends InteractionWaitOptions = undefined>(options: SendInteractionOptions<W>): Promise<SendReturn<W, TReturn>>
```

**Parameters:**

- `options`: `SendInteractionOptions<W>`

**Returns:**

`Promise<SendReturn<W, TReturn>>`

##### send[​](#send-2)

**Signature:**

```
public async send<TReturn = TxReceipt>(options: SendInteractionOptions<InteractionWaitOptions>): Promise<SendReturn<typeof options.wait, TReturn>>
```

**Parameters:**

- `options`: `SendInteractionOptions<InteractionWaitOptions>`

**Returns:**

`Promise<SendReturn<typeof options.wait, TReturn>>`

---

### `contract/batch_call.ts`[​](#contractbatch_callts)

#### BatchCall[​](#batchcall)

**Type:** Class

A batch of function calls to be sent as a single transaction through a wallet.

**Extends:** `BaseContractInteraction`

#### Constructor[​](#constructor-3)

**Signature:**

```
constructor(  wallet: Wallet,  protected interactions: (BaseContractInteraction | ExecutionPayload)[],  private extraHashedArgs: HashedValues[] = [])
```

**Parameters:**

- `wallet`: `Wallet`
- `interactions`: `(BaseContractInteraction | ExecutionPayload)[]`
- `extraHashedArgs` (optional): `HashedValues[]`

#### Methods[​](#methods-5)

##### request[​](#request-1)

Returns an execution request that represents this operation.

**Signature:**

```
public async request(options: RequestInteractionOptions = {}): Promise<ExecutionPayload>
```

**Parameters:**

- `options` (optional): `RequestInteractionOptions`

  - An optional object containing additional configuration for the request generation.

**Returns:**

`Promise<ExecutionPayload>` - An execution payload wrapped in promise.

##### simulate[​](#simulate)

Simulates/executes the batch, supporting private, public and utility functions. Although this is a single interaction with the wallet, private and public functions will be grouped into a single ExecutionPayload that the wallet will simulate as a single transaction. Utility function calls will be executed one by one.

**Signature:**

```
public async simulate(options: SimulateInteractionOptions): Promise<SimulationResult>
```

**Parameters:**

- `options`: `SimulateInteractionOptions`

  - An optional object containing additional configuration for the interaction.

**Returns:**

`Promise<SimulationResult>` - The results of all the interactions that make up the batch

##### getExecutionPayloads[​](#getexecutionpayloads)

**Signature:**

```
protected async getExecutionPayloads(): Promise<ExecutionPayload[]>
```

**Returns:**

`Promise<ExecutionPayload[]>`

---

### `contract/checker.ts`[​](#contractcheckerts)

#### abiChecker[​](#abichecker)

**Type:** Function

Validates the given ContractArtifact object by checking its functions and their parameters. Ensures that the ABI has at least one function, a constructor, valid bytecode, and correct parameter types. Throws an error if any inconsistency is detected during the validation process.

**Signature:**

```
export abiChecker(artifact: ContractArtifact)
```

**Parameters:**

- `artifact`: `ContractArtifact`

  - The ContractArtifact object to be validated.

**Returns:**

`boolean` - A boolean value indicating whether the artifact is valid or not.

---

### `contract/contract.ts`[​](#contractcontractts)

#### Contract[​](#contract-1)

**Type:** Class

The Contract class represents a contract and provides utility methods for interacting with it. It enables the creation of ContractFunctionInteraction instances for each function in the contract's ABI, allowing users to call or send transactions to these functions. Additionally, the Contract class can be used to attach the contract instance to a deployed contract onchain through the PXE, which facilitates interaction with Aztec's privacy protocol.

**Extends:** `ContractBase`

#### Methods[​](#methods-6)

##### at[​](#at)

Gets a contract instance.

**Signature:**

```
public static at(  address: AztecAddress,  artifact: ContractArtifact,  wallet: Wallet): Contract
```

**Parameters:**

- `address`: `AztecAddress`

  - The address of the contract instance.
- `artifact`: `ContractArtifact`

  - Build artifact of the contract.
- `wallet`: `Wallet`

  - The wallet to use when interacting with the contract.

**Returns:**

`Contract` - A promise that resolves to a new Contract instance.

##### deploy[​](#deploy)

Creates a tx to deploy (initialize and/or publish) a new instance of a contract.

**Signature:**

```
public static deploy(  wallet: Wallet,  artifact: ContractArtifact,  args: any[],  constructorName?: string,  instantiation?: DeployInstantiationOptions)
```

**Parameters:**

- `wallet`: `Wallet`

  - The wallet for executing the deployment.
- `artifact`: `ContractArtifact`

  - Build artifact of the contract to deploy
- `args`: `any[]`

  - Arguments for the constructor.
- `constructorName` (optional): `string`

  - The name of the constructor function to call.
- `instantiation` (optional): `DeployInstantiationOptions`

  - Other address-affecting parameters (salt, deployer / universalDeploy, publicKeys).

**Returns:**

`DeployMethod<Contract>`

---

### `contract/contract_base.ts`[​](#contractcontract_basets)

#### ContractMethod[​](#contractmethod)

**Type:** Type Alias

Type representing a contract method that returns a ContractFunctionInteraction instance and has a readonly 'selector' property of type Buffer. Takes any number of arguments.

**Signature:**

```
export type ContractMethod = ((...args: any[]) => ContractFunctionInteraction) & { selector: () => Promise<FunctionSelector>;};
```

**Type Members:**

##### selector[​](#selector)

The unique identifier for a contract function in bytecode.

**Type:** `() => Promise<FunctionSelector>`

#### ContractStorageLayout[​](#contractstoragelayout)

**Type:** Type Alias

Type representing the storage layout of a contract.

**Signature:**

```
export type ContractStorageLayout<T extends string> = { [K in T]: FieldLayout;};
```

**Type Members:**

##### [K in T][​](#k-in-t)

**Signature:** `[K in T]: FieldLayout`

**Key Type:** `T`

**Value Type:** `FieldLayout`

#### ContractBase[​](#contractbase)

**Type:** Class

Abstract implementation of a contract extended by the Contract class and generated contract types.

#### Constructor[​](#constructor-4)

**Signature:**

```
protected constructor(  public readonly address: AztecAddress,  public readonly artifact: ContractArtifact,  public wallet: Wallet)
```

**Parameters:**

- `address`: `AztecAddress`

  - The contract's address.
- `artifact`: `ContractArtifact`

  - The Application Binary Interface for the contract.
- `wallet`: `Wallet`

  - The wallet used for interacting with this contract.

#### Properties[​](#properties-1)

##### methods[​](#methods-7)

An object containing contract methods mapped to their respective names.

**Type:** `{ [name: string]: ContractMethod }`

#### Methods[​](#methods-8)

##### withWallet[​](#withwallet)

Creates a new instance of the contract wrapper attached to a different wallet.

**Signature:**

```
public withWallet(wallet: Wallet): this
```

**Parameters:**

- `wallet`: `Wallet`

  - Wallet to use for sending txs.

**Returns:**

`this` - A new contract instance.

---

### `contract/contract_function_interaction.ts`[​](#contractcontract_function_interactionts)

#### ContractFunctionInteraction[​](#contractfunctioninteraction)

**Type:** Class

This is the class that is returned when calling e.g. `contract.methods.myMethod(arg0, arg1)`. It contains available interactions one can call on a method, including view.

**Extends:** `BaseContractInteraction`

#### Constructor[​](#constructor-5)

**Signature:**

```
constructor(  wallet: Wallet,  protected contractAddress: AztecAddress,  protected functionDao: FunctionAbi,  protected args: any[],  authWitnesses: AuthWitness[] = [],  capsules: Capsule[] = [],  private extraHashedArgs: HashedValues[] = [])
```

**Parameters:**

- `wallet`: `Wallet`
- `contractAddress`: `AztecAddress`
- `functionDao`: `FunctionAbi`
- `args`: `any[]`
- `authWitnesses` (optional): `AuthWitness[]`
- `capsules` (optional): `Capsule[]`
- `extraHashedArgs` (optional): `HashedValues[]`

#### Methods[​](#methods-9)

##### getFunctionCall[​](#getfunctioncall)

Returns the encoded function call wrapped by this interaction Useful when generating authwits

**Signature:**

```
public async getFunctionCall()
```

**Returns:**

`Promise<any>` - An encoded function call

##### request[​](#request-2)

Returns the execution payload that allows this operation to happen on chain.

**Signature:**

```
public override async request(options: RequestInteractionOptions = {}): Promise<ExecutionPayload>
```

**Parameters:**

- `options` (optional): `RequestInteractionOptions`

  - Configuration options.

**Returns:**

`Promise<ExecutionPayload>` - The execution payload for this operation

##### simulate[​](#simulate-1)

Simulate a transaction and get information from its execution. Differs from prove in a few important ways: 1. It returns the values of the function execution, plus additional metadata if requested 2. It supports `utility`, `private` and `public` functions

**Signature:**

```
public async simulate(options: SimulateInteractionOptions = {} as SimulateInteractionOptions): Promise<SimulationResult>
```

**Parameters:**

- `options` (optional): `SimulateInteractionOptions`

  - An optional object containing additional configuration for the simulation.

**Returns:**

`Promise<SimulationResult>` - Depending on the simulation options, this method directly returns the result value of the executed function or a rich object containing extra metadata, such as estimated gas costs (if requested via options), execution statistics and emitted offchain effects

##### profile[​](#profile)

Simulate a transaction and profile the gate count for each function in the transaction.

**Signature:**

```
public async profile(options: ProfileInteractionOptions): Promise<TxProfileResult>
```

**Parameters:**

- `options`: `ProfileInteractionOptions`

  - Same options as `simulate`, plus profiling method

**Returns:**

`Promise<TxProfileResult>` - An object containing the function return value and profile result.

##### with[​](#with)

Augments this ContractFunctionInteraction with additional metadata, such as authWitnesses, capsules, and extraHashedArgs. This is useful when creating a "batteries included" interaction, such as registering a contract class with its associated capsule instead of having the user provide them externally.

**Signature:**

```
public with({ authWitnesses = [], capsules = [], extraHashedArgs = [], }: {    authWitnesses?: AuthWitness[];    capsules?: Capsule[];    extraHashedArgs?: HashedValues[];}): ContractFunctionInteraction
```

**Parameters:**

- `{ authWitnesses = [], capsules = [], extraHashedArgs = [], }`:

```
{    /** The authWitnesses to add to the interaction */    authWitnesses?: AuthWitness[];    /** The capsules to add to the interaction */    capsules?: Capsule[];    /** The extra hashed args to add to the interaction */    extraHashedArgs?: HashedValues[];  }
```

**Returns:**

`ContractFunctionInteraction` - A new ContractFunctionInteraction with the added metadata, but calling the same original function in the same manner

---

### `contract/deploy_method.ts`[​](#contractdeploy_methodts)

#### DeployInstantiationOptions[​](#deployinstantiationoptions)

**Type:** Type Alias

Inputs that determine the contract's deployment address. `salt` and `publicKeys` are optional and default to a random Fr and `PublicKeys.default()` respectively. `deployer` and `universalDeploy` are mutually exclusive and both optional: - If neither is supplied, the deployer is locked lazily on the first `send` / `simulate` / `profile` call from `options.from` (NO_FROM/undefined → universal). This preserves the ergonomics of `MyContract.deploy(wallet, ...args).send({ from: alice })`. - If `deployer` or `universalDeploy: true` is supplied, the deployer is locked at construction. Once locked, the deployer cannot change. Subsequent calls with a `from` that would imply a different deployer throw — except when locked to `AztecAddress.ZERO` (universal), which is compatible with any sender.

**Signature:**

```
export type DeployInstantiationOptions = { salt?: Fr; deployer?: AztecAddress; universalDeploy?: boolean; publicKeys?: PublicKeys; immutablesHash?: Fr;};
```

**Type Members:**

##### salt[​](#salt)

Salt used to derive the contract address. Defaults to a random Fr.

**Type:** `Fr`

##### deployer[​](#deployer)

Deployer address mixed into the address preimage. Mutually exclusive with `universalDeploy`.

**Type:** `AztecAddress`

##### universalDeploy[​](#universaldeploy)

If true, the contract is deployed universally (deployer = AztecAddress.ZERO in the address preimage). Mutually exclusive with `deployer`.

**Type:** `boolean`

##### publicKeys[​](#publickeys)

Public keys mixed into the address. Defaults to PublicKeys.default().

**Type:** `PublicKeys`

##### immutablesHash[​](#immutableshash)

Commitment to the contract's immutable storage values. Folded into the salted initialization hash, so a non-zero value affects the derived address. Defaults to `Fr.ZERO`.

**Type:** `Fr`

#### BoundInstantiationOptions[​](#boundinstantiationoptions)

**Type:** Type Alias

Narrowed `DeployInstantiationOptions` accepted by BoundDeployMethod: requires a concrete `deployer` and forbids `universalDeploy`. The runtime check that `deployer` is non-zero stays as defense in depth (it's a value-level invariant the type system can't model).

**Signature:**

```
export type BoundInstantiationOptions = SharedInstantiationOptions & { deployer: AztecAddress; universalDeploy?: never;};
```

**Type Members:**

##### deployer[​](#deployer-1)

Concrete deployer mixed into the address preimage. Required, must be non-zero.

**Type:** `AztecAddress`

##### universalDeploy[​](#universaldeploy-1)

Forbidden on `BoundDeployMethod`; use `UniversalDeployMethod` for universal deploys.

**Type:** `never`

#### UniversalInstantiationOptions[​](#universalinstantiationoptions)

**Type:** Type Alias

Narrowed `DeployInstantiationOptions` accepted by UniversalDeployMethod: forbids `deployer` and requires `universalDeploy: true` (so the call site reads as a universal deploy).

**Signature:**

```
export type UniversalInstantiationOptions = SharedInstantiationOptions & { deployer?: never; universalDeploy: true;};
```

**Type Members:**

##### deployer[​](#deployer-2)

Forbidden on `UniversalDeployMethod`; use `BoundDeployMethod` if you need a concrete deployer.

**Type:** `never`

##### universalDeploy[​](#universaldeploy-2)

Marks this as a universal deploy. Required for clarity at the call site.

**Type:** `true`

#### PendingInstantiationOptions[​](#pendinginstantiationoptions)

**Type:** Type Alias

Narrowed `DeployInstantiationOptions` accepted by PendingDeployMethod: forbids both `deployer` and `universalDeploy`. The deploy is locked from the first send-time `from` instead.

**Signature:**

```
export type PendingInstantiationOptions = SharedInstantiationOptions & { deployer?: never; universalDeploy?: never;};
```

**Type Members:**

##### deployer[​](#deployer-3)

Forbidden on `PendingDeployMethod`; use `BoundDeployMethod` for a concrete deployer.

**Type:** `never`

##### universalDeploy[​](#universaldeploy-3)

Forbidden on `PendingDeployMethod`; use `UniversalDeployMethod` for a universal deploy.

**Type:** `never`

#### DeployMethodContract[​](#deploymethodcontract)

**Type:** Type Alias

Identifies *which contract* is being deployed and *with what initializer*.

**Signature:**

```
export type DeployMethodContract<TContract extends ContractBase = ContractBase> = { artifact: ContractArtifact; postDeployCtor: (instance: ContractInstanceWithAddress, wallet: Wallet) => TContract; args?: any[]; constructorNameOrArtifact?: string | FunctionArtifact;};
```

**Type Members:**

##### artifact[​](#artifact)

Build artifact of the contract being deployed.

**Type:** `ContractArtifact`

##### postDeployCtor[​](#postdeployctor)

Factory invoked after deployment to produce the typed contract handle.

**Type:** `(instance: ContractInstanceWithAddress, wallet: Wallet) => TContract`

##### args[​](#args)

Encoded constructor arguments for the contract. Defaults to `[]`.

**Type:** `any[]`

##### constructorNameOrArtifact[​](#constructornameorartifact)

Name (or full artifact) of the initializer to call.

**Type:** `string | FunctionArtifact`

#### DeployMethodPayload[​](#deploymethodpayload)

**Type:** Type Alias

Execution-payload metadata propagated through `request` / `send` / `simulate` / `profile`.

**Signature:**

```
export type DeployMethodPayload = { authWitnesses?: AuthWitness[]; capsules?: Capsule[]; extraHashedArgs?: HashedValues[];};
```

**Type Members:**

##### authWitnesses[​](#authwitnesses)

Auth witnesses propagated to the deploy interaction.

**Type:** `AuthWitness[]`

##### capsules[​](#capsules)

Capsules propagated to the deploy interaction.

**Type:** `Capsule[]`

##### extraHashedArgs[​](#extrahashedargs)

Extra hashed args propagated to the deploy interaction.

**Type:** `HashedValues[]`

#### RequestDeployOptions[​](#requestdeployoptions)

**Type:** Type Alias

Options for deploying a contract on the Aztec network. Controls publication and registration policy for this deployment.

**Signature:**

```
export type RequestDeployOptions = RequestInteractionOptions & { skipClassPublication?: boolean; skipInstancePublication?: boolean; skipInitialization?: boolean; skipRegistration?: boolean;};
```

**Type Members:**

##### skipClassPublication[​](#skipclasspublication)

Skip contract class publication.

**Type:** `boolean`

##### skipInstancePublication[​](#skipinstancepublication)

Skip publication, instead just privately initialize the contract.

**Type:** `boolean`

##### skipInitialization[​](#skipinitialization)

Skip contract initialization.

**Type:** `boolean`

##### skipRegistration[​](#skipregistration)

Skip contract registration in the wallet

**Type:** `boolean`

#### DeployOptionsWithoutWait[​](#deployoptionswithoutwait)

**Type:** Type Alias

Base deployment options without wait parameter.

**Signature:**

```
export type DeployOptionsWithoutWait = RequestDeployOptions & Pick<SendInteractionOptionsWithoutWait, 'from' | 'fee' | 'additionalScopes'>;
```

#### DeployOptions[​](#deployoptions)

**Type:** Type Alias

Extends the deployment options with the required parameters to send the transaction.

**Signature:**

```
export type DeployOptions<W extends InteractionWaitOptions = undefined> = DeployOptionsWithoutWait & { wait?: W;};
```

**Type Members:**

##### wait[​](#wait)

Options for waiting for the transaction to be mined. - undefined (default): wait with default options and return the contract instance - WaitOpts: wait with custom options - NO_WAIT: return TxHash immediately without waiting

**Type:** `W`

#### SimulateDeployOptions[​](#simulatedeployoptions)

**Type:** Type Alias

Options for simulating the deployment of a contract Allows skipping certain validations and computing gas estimations

**Signature:**

```
export type SimulateDeployOptions = Omit<DeployOptionsWithoutWait, 'fee'> & { fee?: InteractionFeeOptions; skipTxValidation?: boolean; skipFeeEnforcement?: boolean; includeMetadata?: boolean;};
```

**Type Members:**

##### fee[​](#fee)

The fee options for the transaction.

**Type:** `InteractionFeeOptions`

##### skipTxValidation[​](#skiptxvalidation)

Simulate without checking for the validity of the resulting transaction, e.g. whether it emits any existing nullifiers.

**Type:** `boolean`

##### skipFeeEnforcement[​](#skipfeeenforcement)

Whether to ensure the fee payer is not empty and has enough balance to pay for the fee.

**Type:** `boolean`

##### includeMetadata[​](#includemetadata)

Whether to include metadata such as offchain effects and performance statistics (e.g. timing information of the different circuits and oracles) in the simulation result, instead of just the return value of the function

**Type:** `boolean`

#### DeployResultMined[​](#deployresultmined)

**Type:** Type Alias

Result of deploying a contract when waiting for mining (default case).

**Signature:**

```
export type DeployResultMined<TContract extends ContractBase> = { contract: TContract; instance: ContractInstanceWithAddress; receipt: TxReceipt;} & OffchainOutput;
```

**Type Members:**

##### contract[​](#contract-2)

The deployed contract instance.

**Type:** `TContract`

##### instance[​](#instance)

The deployed contract instance with address and metadata.

**Type:** `ContractInstanceWithAddress`

##### receipt[​](#receipt)

The deploy transaction receipt.

**Type:** `TxReceipt`

#### DeployReturn[​](#deployreturn)

**Type:** Type Alias

Conditional return type for deploy based on wait options.

**Signature:**

```
export type DeployReturn<TContract extends ContractBase, W extends InteractionWaitOptions> = W extends NoWait ? TxSendResultImmediate : DeployResultMined<TContract>;
```

#### DeployMethod[​](#deploymethod)

**Type:** Class

Umbrella type for a contract deployment interaction. `DeployMethod` is abstract: callers always interact with one of three concrete flavors — BoundDeployMethod, UniversalDeployMethod, or PendingDeployMethod — picked by DeployMethod.create based on the supplied DeployInstantiationOptions. The flavors only differ in their initial deployer-lock state; the full API (`request` / `send` / `simulate` / `profile` / `getInstance` / `getAddress` / `getPartialAddress` / `register` / `with`) lives on this base, so consumers can type variables as `DeployMethod<T>` and treat all three uniformly. The deployer (and therefore the deployed address) is locked once and never changes. Locking happens either at construction (via `deployer` or `universalDeploy: true` in the instantiation options) or lazily on the first `send` / `simulate` / `profile` call, which lock from `options.from`. Once locked: - The address is stable for the lifetime of this object. - Subsequent `send` / `simulate` / `profile` calls with a `from` that would imply a different deployer throw, to prevent silently deploying at a different address than `getAddress()` reported. - A locked universal deployer (`AztecAddress.ZERO`) is compatible with any `from`, since the address does not depend on the sender. Note that for some contracts, a tx is not required as part of its "creation": If there are no public functions, and if there are no initialization functions, then technically the contract has already been "created", and all of the contract's functions (private and utility) can be interacted-with immediately, without any "deployment tx".

**Extends:** `BaseContractInteraction`

#### Constructor[​](#constructor-6)

**Signature:**

```
protected constructor(  wallet: Wallet,  contract: DeployMethodContract<TContract>,  salt: Fr | undefined,  publicKeys: PublicKeys | undefined,  immutablesHash: Fr | undefined,  payload: DeployMethodPayload = {})
```

**Parameters:**

- `wallet`: `Wallet`
- `contract`: `DeployMethodContract<TContract>`
- `salt`: `Fr | undefined`
- `publicKeys`: `PublicKeys | undefined`
- `immutablesHash`: `Fr | undefined`
- `payload` (optional): `DeployMethodPayload`

#### Properties[​](#properties-2)

##### salt[​](#salt-1)

Salt used in the address preimage.

**Type:** `Fr`

##### publicKeys[​](#publickeys-1)

Public keys mixed into the address preimage.

**Type:** `PublicKeys`

##### immutablesHash[​](#immutableshash-1)

Immutables hash folded into the salted initialization hash.

**Type:** `Fr`

##### #instancePromise[​](#instancepromise)

Cached instance promise; resolved once the deployer is known.

**Type:** `Promise<ContractInstanceWithAddress>`

##### #resolvedInstance[​](#resolvedinstance)

Resolved value of `#instancePromise`, populated synchronously once the promise settles.

**Type:** `ContractInstanceWithAddress`

##### constructorArtifact[​](#constructorartifact)

Constructor function to call.

**Type:** `FunctionAbi | undefined`

##### artifact[​](#artifact-1)

Build artifact of the contract being deployed.

**Type:** `ContractArtifact`

##### postDeployCtor[​](#postdeployctor-1)

Factory invoked after deployment to produce the typed contract handle.

**Type:** `(instance: ContractInstanceWithAddress, wallet: Wallet) => TContract`

##### args[​](#args-1)

Encoded constructor arguments for the contract.

**Type:** `any[]`

##### extraHashedArgs[​](#extrahashedargs-1)

Extra hashed args propagated through `with(...)` and into the deploy payload.

**Type:** `HashedValues[]`

#### Methods[​](#methods-10)

##### getDeployerAddress[​](#getdeployeraddress)

The address that will be mixed into the contract's address preimage. Owned returns the concrete deployer; Universal returns `AztecAddress.ZERO`; Pending throws unless a prior `send` / `simulate` / `profile` call has already locked it.

**Signature:**

```
public abstract getDeployerAddress(): AztecAddress
```

**Returns:**

`AztecAddress`

##### lockDeployer[​](#lockdeployer)

Reconciles a send-time `from` with the deploy's deployer. Owned asserts an exact match; Universal accepts anything; Pending uses the first call to lock its deployer (transitioning into an Owned/Universal sibling), then defers to that sibling's assertion on subsequent calls. The "locks-or-asserts" name is intentional: only Pending mutates state, and only on its first invocation. Owned and Universal are pure assertions.

**Signature:**

```
public abstract lockDeployer(from: SendInteractionOptionsWithoutWait['from'] | undefined): void
```

**Parameters:**

- `from`: `SendInteractionOptionsWithoutWait['from'] | undefined`

  - The send-time `from` value (`AztecAddress`, `NO_FROM`, or `undefined`).

**Returns:**

`void`

##### cloneInstantiation[​](#cloneinstantiation)

Returns the DeployInstantiationOptions that match this flavor. Used by `with(...)` to spawn a sibling instance carrying the same lock state.

**Signature:**

```
public abstract cloneInstantiation(): DeployInstantiationOptions
```

**Returns:**

`DeployInstantiationOptions`

##### create[​](#create)

Constructs the right concrete `DeployMethod` flavor for the supplied instantiation options: - `{ deployer: <addr> }` → BoundDeployMethod - `{ universalDeploy: true }` → UniversalDeployMethod - neither set → PendingDeployMethod Mixing `deployer` and `universalDeploy` throws. Returns the umbrella `DeployMethod<T>` type so callers can use the result generically without narrowing.

**Signature:**

```
public static create<TContract extends ContractBase>(  wallet: Wallet,  contract: DeployMethodContract<TContract>,  instantiation: DeployInstantiationOptions = {},  payload: DeployMethodPayload = {}): DeployMethod<TContract>
```

**Parameters:**

- `wallet`: `Wallet`

  - Wallet used to send / simulate the deploy tx.
- `contract`: `DeployMethodContract<TContract>`

  - The contract being deployed (artifact, factory, args, initializer).
- `instantiation` (optional): `DeployInstantiationOptions`

  - Address-affecting parameters (salt, deployer / universalDeploy, publicKeys). Defaults to pending.
- `payload` (optional): `DeployMethodPayload`

  - Auth witnesses, capsules, and extra hashed args propagated to the deploy. Defaults to empty.

**Returns:**

`DeployMethod<TContract>`

##### request[​](#request-3)

Returns the execution payload that allows this operation to happen on chain. Requires the deployer to be known — call `getDeployerAddress()` first; on a `PendingDeployMethod` this throws unless a prior `send` / `simulate` / `profile` has already locked the deployer.

**Signature:**

```
public async request(options: RequestDeployOptions = {}): Promise<ExecutionPayload>
```

**Parameters:**

- `options` (optional): `RequestDeployOptions`

  - Configuration options.

**Returns:**

`Promise<ExecutionPayload>` - The execution payload for this operation

##### convertDeployOptionsToSendOptions[​](#convertdeployoptionstosendoptions)

Converts DeployOptions to SendOptions.

**Signature:**

```
protected convertDeployOptionsToSendOptions<W extends InteractionWaitOptions>(options: DeployOptions<W>): SendOptions<W>
```

**Parameters:**

- `options`: `DeployOptions<W>`

  - Deploy options with wait parameter.

**Returns:**

`SendOptions<W>`

##### convertDeployOptionsToSimulateOptions[​](#convertdeployoptionstosimulateoptions)

Converts deploy simulation options into wallet-level simulate options.

**Signature:**

```
protected convertDeployOptionsToSimulateOptions(options: SimulateDeployOptions): SimulateOptions
```

**Parameters:**

- `options`: `SimulateDeployOptions`

  - The deploy simulation options to convert.

**Returns:**

`SimulateOptions`

##### convertDeployOptionsToProfileOptions[​](#convertdeployoptionstoprofileoptions)

Converts deploy profile options into wallet-level profile options.

**Signature:**

```
protected convertDeployOptionsToProfileOptions(options: DeployOptionsWithoutWait & ProfileInteractionOptions): ProfileOptions
```

**Parameters:**

- `options`: `DeployOptionsWithoutWait & ProfileInteractionOptions`

  - The deploy profile options to convert.

**Returns:**

`ProfileOptions`

##### register[​](#register)

Adds this contract to the wallet and returns the Contract object.

**Signature:**

```
public async register(): Promise<TContract>
```

**Returns:**

`Promise<TContract>`

##### getPublicationExecutionPayload[​](#getpublicationexecutionpayload)

Returns an execution payload for: - publication of the contract class and - publication of the contract instance to enable public execution depending on the provided options.

**Signature:**

```
protected async getPublicationExecutionPayload(options?: RequestDeployOptions): Promise<ExecutionPayload>
```

**Parameters:**

- `options` (optional): `RequestDeployOptions`

  - Contract creation options.

**Returns:**

`Promise<ExecutionPayload>` - An execution payload with potentially calls (and bytecode capsule) to the class registry and instance registry.

##### getInitializationExecutionPayload[​](#getinitializationexecutionpayload)

Returns the calls necessary to initialize the contract.

**Signature:**

```
protected async getInitializationExecutionPayload(options?: RequestDeployOptions): Promise<ExecutionPayload>
```

**Parameters:**

- `options` (optional): `RequestDeployOptions`

  - Deployment options.

**Returns:**

`Promise<ExecutionPayload>` - An array of function calls.

##### send[​](#send-3)

Send a contract deployment transaction (initialize and/or publish) using the provided options. By default, waits for the transaction to be mined and returns the deployed contract instance.

**Signature:**

```
public override send(options: DeployOptionsWithoutWait): Promise<DeployResultMined<TContract>>
```

**Parameters:**

- `options`: `DeployOptionsWithoutWait`

  - An object containing various deployment options such as `from` and `fee`.

**Returns:**

`Promise<DeployResultMined<TContract>>` - TxHash (if wait is NO_WAIT), or DeployResultMined with contract, receipt, and instance (otherwise)

##### send[​](#send-4)

**Signature:**

```
public override send<W extends InteractionWaitOptions>(options: DeployOptions<W>): Promise<DeployReturn<TContract, W>>
```

**Parameters:**

- `options`: `DeployOptions<W>`

**Returns:**

`Promise<DeployReturn<TContract, W>>`

##### send[​](#send-5)

**Signature:**

```
public override async send(options: DeployOptions<InteractionWaitOptions>): Promise<any>
```

**Parameters:**

- `options`: `DeployOptions<InteractionWaitOptions>`

**Returns:**

`Promise<any>`

##### getInstance[​](#getinstance)

Builds the contract instance and returns it. The instance is computed once and cached for the lifetime of this DeployMethod; subsequent calls return the same instance. On a PendingDeployMethod this throws unless a prior `send` / `simulate` / `profile` call has already locked the deployer — otherwise the resolved address could silently differ from the eventually-deployed one.

**Signature:**

```
public getInstance(): Promise<ContractInstanceWithAddress>
```

**Returns:**

`Promise<ContractInstanceWithAddress>` - An instance object.

##### simulate[​](#simulate-2)

Simulate the deployment

**Signature:**

```
public async simulate(options: SimulateDeployOptions): Promise<SimulationResult>
```

**Parameters:**

- `options`: `SimulateDeployOptions`

  - An optional object containing additional configuration for the simulation.

**Returns:**

`Promise<SimulationResult>` - A simulation result object containing metadata of the execution, including gas estimations (if requested via options), execution statistics and emitted offchain effects

##### profile[​](#profile-1)

Simulate a deployment and profile the gate count for each function in the transaction.

**Signature:**

```
public async profile(options: DeployOptionsWithoutWait & ProfileInteractionOptions): Promise<TxProfileResult>
```

**Parameters:**

- `options`: `DeployOptionsWithoutWait & ProfileInteractionOptions`

  - Same options as `send`, plus extra profiling options.

**Returns:**

`Promise<TxProfileResult>` - An object containing the function return value and profile result.

##### getAddress[​](#getaddress-2)

Returns the deployed contract address.

**Signature:**

```
public async getAddress(): Promise<AztecAddress>
```

**Returns:**

`Promise<AztecAddress>`

##### getPartialAddress[​](#getpartialaddress)

Returns the partial address for this deployment.

**Signature:**

```
public async getPartialAddress(): Promise<Fr>
```

**Returns:**

`Promise<Fr>`

##### getCachedInstanceOrThrow[​](#getcachedinstanceorthrow)

Returns the cached resolved instance synchronously, or throws if no instance has been computed yet. Intended for subclasses that run inside a code path where `getInstance()` is guaranteed to have already been awaited (e.g. `request()` invoked it). Not part of the public API.

**Signature:**

```
protected getCachedInstanceOrThrow(): ContractInstanceWithAddress
```

**Returns:**

`ContractInstanceWithAddress`

##### with[​](#with-1)

Augments this DeployMethod with additional metadata, such as authWitnesses and capsules. The deployer lock is preserved: a Pending that has not yet been locked stays Pending; a Pending that has already locked, along with Owned and Universal, returns the matching locked flavor so the cloned method deploys at the same address as `this`.

**Signature:**

```
public with({ authWitnesses = [], capsules = [], extraHashedArgs = [], }: {    authWitnesses?: AuthWitness[];    capsules?: Capsule[];    extraHashedArgs?: HashedValues[];}): DeployMethod<TContract>
```

**Parameters:**

- `{ authWitnesses = [], capsules = [], extraHashedArgs = [], }`:

```
{    /** The authWitnesses to add to the deployment */    authWitnesses?: AuthWitness[];    /** The capsules to add to the deployment */    capsules?: Capsule[];    /** The extra hashed args to add to the deployment */    extraHashedArgs?: HashedValues[];  }
```

**Returns:**

`DeployMethod<TContract>` - A new DeployMethod with the added metadata, but calling the same original function in the same manner

#### BoundDeployMethod[​](#bounddeploymethod)

**Type:** Class

Deploy method whose deployer is fixed at construction to a concrete AztecAddress. The deployer is mixed into the address preimage, so the contract address is fully determined. Sending from a different account throws — letting it through would silently produce a deployed address different from the one `getAddress()` reported.

**Extends:** `DeployMethod`

#### Constructor[​](#constructor-7)

**Signature:**

```
public constructor(  wallet: Wallet,  contract: DeployMethodContract<TContract>,  instantiation: BoundInstantiationOptions,  payload: DeployMethodPayload = {})
```

**Parameters:**

- `wallet`: `Wallet`
- `contract`: `DeployMethodContract<TContract>`
- `instantiation`: `BoundInstantiationOptions`
- `payload` (optional): `DeployMethodPayload`

#### Properties[​](#properties-3)

##### deployer[​](#deployer-4)

The address baked into the address preimage. Read-only — set at construction.

**Type:** `AztecAddress`

#### Methods[​](#methods-11)

##### getDeployerAddress[​](#getdeployeraddress-1)

Returns the locked deployer baked into the address preimage.

**Signature:**

```
public getDeployerAddress(): AztecAddress
```

**Returns:**

`AztecAddress`

##### lockDeployer[​](#lockdeployer-1)

Throws unless `from` matches the locked deployer; the deployer is part of the address.

**Signature:**

```
public lockDeployer(from: SendInteractionOptionsWithoutWait['from'] | undefined): void
```

**Parameters:**

- `from`: `SendInteractionOptionsWithoutWait['from'] | undefined`

  - The send-time `from` value (`AztecAddress`, `NO_FROM`, or `undefined`).

**Returns:**

`void`

##### cloneInstantiation[​](#cloneinstantiation-1)

Re-emits this method's `DeployInstantiationOptions` for `with(...)` to consume.

**Signature:**

```
public cloneInstantiation(): DeployInstantiationOptions
```

**Returns:**

`DeployInstantiationOptions`

#### UniversalDeployMethod[​](#universaldeploymethod)

**Type:** Class

Deploy method whose deployer is fixed at construction to AztecAddress.ZERO (universal deploy). The address does not depend on the sender, so any account may sign the deploy tx.

**Extends:** `DeployMethod`

#### Constructor[​](#constructor-8)

**Signature:**

```
public constructor(  wallet: Wallet,  contract: DeployMethodContract<TContract>,  instantiation: UniversalInstantiationOptions,  payload: DeployMethodPayload = {})
```

**Parameters:**

- `wallet`: `Wallet`
- `contract`: `DeployMethodContract<TContract>`
- `instantiation`: `UniversalInstantiationOptions`
- `payload` (optional): `DeployMethodPayload`

#### Methods[​](#methods-12)

##### getDeployerAddress[​](#getdeployeraddress-2)

Universal deploys are anchored at `AztecAddress.ZERO`; the sender does not enter the preimage.

**Signature:**

```
public getDeployerAddress(): AztecAddress
```

**Returns:**

`AztecAddress`

##### lockDeployer[​](#lockdeployer-2)

Universal deploys accept any sender, including `NO_FROM` / `undefined`.

**Signature:**

```
public lockDeployer(_from: SendInteractionOptionsWithoutWait['from'] | undefined): void
```

**Parameters:**

- `_from`: `SendInteractionOptionsWithoutWait['from'] | undefined`

  - Ignored.

**Returns:**

`void`

##### cloneInstantiation[​](#cloneinstantiation-2)

Re-emits this method's `DeployInstantiationOptions` for `with(...)` to consume.

**Signature:**

```
public cloneInstantiation(): DeployInstantiationOptions
```

**Returns:**

`DeployInstantiationOptions`

#### PendingDeployMethod[​](#pendingdeploymethod)

**Type:** Class

Deploy method whose deployer is not yet decided. The first `send` / `simulate` / `profile` call promotes this into an BoundDeployMethod or UniversalDeployMethod (depending on whether `options.from` is an address or `NO_FROM` / `undefined`); subsequent calls reuse that promotion and reject mismatching `from` values. Reading the address (`getInstance` / `getAddress` / `getPartialAddress`) or building a payload (`request`) before the promotion happens throws — the address would otherwise be ambiguous and could differ from what `send()` ends up deploying.

**Extends:** `DeployMethod`

#### Constructor[​](#constructor-9)

**Signature:**

```
public constructor(  wallet: Wallet,  contract: DeployMethodContract<TContract>,  instantiation: PendingInstantiationOptions = {},  payload: DeployMethodPayload = {})
```

**Parameters:**

- `wallet`: `Wallet`
- `contract`: `DeployMethodContract<TContract>`
- `instantiation` (optional): `PendingInstantiationOptions`
- `payload` (optional): `DeployMethodPayload`

#### Properties[​](#properties-4)

##### #locked[​](#locked)

The locked sibling created on the first send-side call. Once set, all flavor-specific decisions (sender compatibility, address derivation, clone shape) delegate to it, so a second call with a mismatched `from` is rejected by `BoundDeployMethod.lockDeployer`.

**Type:** `BoundDeployMethod<TContract> | UniversalDeployMethod<TContract>`

#### Methods[​](#methods-13)

##### getDeployerAddress[​](#getdeployeraddress-3)

Returns the locked deployer once it has happened. Throws while still pending — the address would otherwise differ from what `send()` ends up deploying.

**Signature:**

```
public getDeployerAddress(): AztecAddress
```

**Returns:**

`AztecAddress`

##### lockDeployer[​](#lockdeployer-3)

On the first call, promotes this pending method into a locked sibling and remembers it. On subsequent calls, defers to the locked sibling — so a mismatched `from` is rejected by the sibling's own policy, not a duplicate one here.

**Signature:**

```
public lockDeployer(from: SendInteractionOptionsWithoutWait['from'] | undefined): void
```

**Parameters:**

- `from`: `SendInteractionOptionsWithoutWait['from'] | undefined`

  - The send-time `from` value (`AztecAddress`, `NO_FROM`, or `undefined`).

**Returns:**

`void`

##### cloneInstantiation[​](#cloneinstantiation-3)

Re-emits this method's `DeployInstantiationOptions` for `with(...)` to consume.

**Signature:**

```
public cloneInstantiation(): DeployInstantiationOptions
```

**Returns:**

`DeployInstantiationOptions`

##### #promoteFrom[​](#promotefrom)

Builds the locked sibling implied by a send-time `from`: an `AztecAddress` becomes BoundDeployMethod; `NO_FROM` / `undefined` becomes UniversalDeployMethod.

**Signature:**

```
#promoteFrom(from: SendInteractionOptionsWithoutWait['from'] | undefined): BoundDeployMethod<TContract> | UniversalDeployMethod<TContract>
```

**Parameters:**

- `from`: `SendInteractionOptionsWithoutWait['from'] | undefined`

  - The send-time `from` value.

**Returns:**

`BoundDeployMethod<TContract> | UniversalDeployMethod<TContract>`

---

### `contract/fastforward_contract_update.ts`[​](#contractfastforward_contract_updatets)

#### fastForwardContractUpdate[​](#fastforwardcontractupdate)

**Type:** Function

Builds `SimulationOverrides` that simulate a deployed instance as if it had already been upgraded to a new contract class. Mirrors a real onchain upgrade (scheduling the new class and waiting out the delay): - `publicStorage` rewrites the `ContractInstanceRegistry`'s delayed-public-mutable storage so the AVM's `UpdateCheck` resolves to the new class id. - `contracts` swaps the deployed instance for one whose `currentContractClassId` is bumped to the new class. The new class must already be registered on chain.

**Signature:**

```
export async fastForwardContractUpdate(args: {    instanceAddress: AztecAddress;    newClassId: Fr;    node: AztecNode;}): Promise<SimulationOverrides>
```

**Parameters:**

- `args`:

```
{  /** Address of the deployed instance to upgrade. */  instanceAddress: AztecAddress;  /** ID of the (already-registered) class to upgrade to. */  newClassId: Fr;  /** Node used to fetch the existing instance and validate the class is registered. */  node: AztecNode;}
```

**Returns:**

`Promise<SimulationOverrides>`

---

### `contract/interaction_options.ts`[​](#contractinteraction_optionsts)

#### FeePaymentMethodOption[​](#feepaymentmethodoption)

**Type:** Type Alias

Interactions allow configuring a custom fee payment method that gets bundled with the transaction before sending it to the wallet

**Signature:**

```
export type FeePaymentMethodOption = { paymentMethod?: FeePaymentMethod;};
```

**Type Members:**

##### paymentMethod[​](#paymentmethod)

Fee payment method to embed in the interaction

**Type:** `FeePaymentMethod`

#### GasSettingsOption[​](#gassettingsoption)

**Type:** Type Alias

User-defined partial gas settings for the interaction. This type is completely optional since the wallet will fill in the missing options

**Signature:**

```
export type GasSettingsOption = { gasSettings?: Partial<FieldsOf<GasSettings>>; congestionEstimate?: ManaUsageEstimate;};
```

**Type Members:**

##### gasSettings[​](#gassettings)

The gas settings

**Type:** `Partial<FieldsOf<GasSettings>>`

##### congestionEstimate[​](#congestionestimate)

Assumed network congestion level for fee prediction. Controls how aggressively the wallet estimates future fees: None assumes empty blocks, Target assumes steady-state usage, and Limit assumes blocks at maximum capacity. Higher estimates produce higher fee predictions, reducing the risk of underpriced transactions during congestion spikes. Defaults to Limit (worst case) when not specified.

**Type:** `ManaUsageEstimate`

#### InteractionFeeOptions[​](#interactionfeeoptions)

**Type:** Type Alias

Fee options as set by a user.

**Signature:**

```
export type InteractionFeeOptions = GasSettingsOption & FeePaymentMethodOption;
```

#### RequestInteractionOptions[​](#requestinteractionoptions)

**Type:** Type Alias

Represents the options to configure a request from a contract interaction. Allows specifying additional auth witnesses and capsules to use during execution

**Signature:**

```
export type RequestInteractionOptions = { authWitnesses?: AuthWitness[]; capsules?: Capsule[]; fee?: FeePaymentMethodOption;};
```

**Type Members:**

##### authWitnesses[​](#authwitnesses-1)

Extra authwits to use during execution

**Type:** `AuthWitness[]`

##### capsules[​](#capsules-1)

Extra capsules to use during execution

**Type:** `Capsule[]`

##### fee[​](#fee-1)

Fee payment method to embed in the interaction request

**Type:** `FeePaymentMethodOption`

#### NO_WAIT[​](#no_wait)

**Type:** Constant

Constant for explicitly not waiting for transaction confirmation. We use this instead of false to avoid confusion with falsy checks.

**Value Type:** `any`

#### NoWait[​](#nowait)

**Type:** Type Alias

Type for the NO_WAIT constant.

**Signature:**

```
export type NoWait = typeof NO_WAIT;
```

#### NO_FROM[​](#no_from)

**Type:** Constant

Constant for explicitly opting out of account contract mediation. When used as the `from` parameter, the wallet executes the payload directly via the DefaultEntrypoint without wrapping it in an account contract entrypoint. The app is responsible for assembling the complete execution payload, including any entrypoint wrapping (e.g. multicall) if needed. This will result in the first call of the chain receiving msg_sender as Option::none

**Value Type:** `any`

#### NoFrom[​](#nofrom)

**Type:** Type Alias

Type for the NO_FROM constant.

**Signature:**

```
export type NoFrom = typeof NO_FROM;
```

#### InteractionWaitOptions[​](#interactionwaitoptions)

**Type:** Type Alias

Type for wait options in interactions. - NO_WAIT symbol: Don't wait for confirmation, return TxHash immediately - WaitOpts object: Wait with custom options and return receipt/result - undefined: Wait with default options and return receipt/result

**Signature:**

```
export type InteractionWaitOptions = NoWait | WaitOpts | undefined;
```

#### SendInteractionOptionsWithoutWait[​](#sendinteractionoptionswithoutwait)

**Type:** Type Alias

Base options for calling a (constrained) function in a contract, without wait parameter.

**Signature:**

```
export type SendInteractionOptionsWithoutWait = RequestInteractionOptions & { from: AztecAddress | NoFrom; fee?: InteractionFeeOptions; additionalScopes?: AztecAddress[]; sendMessagesAs?: AztecAddress;};
```

**Type Members:**

##### from[​](#from)

The sender's Aztec address, or NO_FROM to execute without account contract mediation.

**Type:** `AztecAddress | NoFrom`

##### fee[​](#fee-2)

The fee options for the transaction.

**Type:** `InteractionFeeOptions`

##### additionalScopes[​](#additionalscopes)

Additional addresses whose private state and keys should be accessible during execution, beyond the sender's. Required when the transaction needs to access private state or keys belonging to an address other than `from`, e.g. withdrawing from an escrow that holds its own private notes.

**Type:** `AztecAddress[]`

##### sendMessagesAs[​](#sendmessagesas)

Overrides the sender address used to derive discovery tags for private messages (notes, events, logs). Recipients use these tags to find messages addressed to them. Defaults to `from`. Typically set when `from === NO_FROM`, since there is no account address to derive tags from.

**Type:** `AztecAddress`

#### SendInteractionOptions[​](#sendinteractionoptions)

**Type:** Type Alias

Represents options for calling a (constrained) function in a contract.

**Signature:**

```
export type SendInteractionOptions<W extends InteractionWaitOptions = undefined> = SendInteractionOptionsWithoutWait & { wait?: W;};
```

**Type Members:**

##### wait[​](#wait-1)

Whether to wait for the transaction to be mined. - undefined (default): wait with default options and return TxReceipt - WaitOpts object: wait with custom options and return TxReceipt - NO_WAIT: return txHash immediately without waiting

**Type:** `W`

#### SimulateInteractionOptions[​](#simulateinteractionoptions)

**Type:** Type Alias

Represents the options for simulating a contract function interaction. Allows specifying the address from which the method should be called. Disregarded for simulation of public functions

**Signature:**

```
export type SimulateInteractionOptions = Omit<SendInteractionOptions, 'fee'> & { fee?: InteractionFeeOptions; skipTxValidation?: boolean; skipFeeEnforcement?: boolean; includeMetadata?: boolean; overrides?: SimulationOverrides;};
```

**Type Members:**

##### fee[​](#fee-3)

The fee options for the transaction.

**Type:** `InteractionFeeOptions`

##### skipTxValidation[​](#skiptxvalidation-1)

Simulate without checking for the validity of the resulting transaction, e.g. whether it emits any existing nullifiers.

**Type:** `boolean`

##### skipFeeEnforcement[​](#skipfeeenforcement-1)

Whether to ensure the fee payer is not empty and has enough balance to pay for the fee.

**Type:** `boolean`

##### includeMetadata[​](#includemetadata-1)

Whether to include metadata such as performance statistics (e.g. timing information of the different circuits and oracles) and simulated gas usage in the simulation result, in addition to the return value and offchain effects

**Type:** `boolean`

##### overrides[​](#overrides)

Pre-simulation overrides applied to the ephemeral fork and contract DB (publicStorage writes, contract instance overrides).

**Type:** `SimulationOverrides`

#### ProfileInteractionOptions[​](#profileinteractionoptions)

**Type:** Type Alias

Represents the options for profiling an interaction.

**Signature:**

```
export type ProfileInteractionOptions = SimulateInteractionOptions & { profileMode: 'gates' | 'execution-steps' | 'full'; skipProofGeneration?: boolean;};
```

**Type Members:**

##### profileMode[​](#profilemode)

Whether to return gates information or the bytecode/witnesses.

**Type:** `'gates' | 'execution-steps' | 'full'`

##### skipProofGeneration[​](#skipproofgeneration)

Whether to generate a Chonk proof or not

**Type:** `boolean`

#### OffchainMessage[​](#offchainmessage)

**Type:** Type Alias

A message emitted during execution or proving, to be delivered offchain.

**Signature:**

```
export type OffchainMessage = { recipient: AztecAddress; payload: Fr[]; contractAddress: AztecAddress; anchorBlockTimestamp: bigint;};
```

**Type Members:**

##### recipient[​](#recipient)

The intended recipient of the message.

**Type:** `AztecAddress`

##### payload[​](#payload)

The message payload (typically encrypted).

**Type:** `Fr[]`

##### contractAddress[​](#contractaddress)

The contract that emitted the message.

**Type:** `AztecAddress`

##### anchorBlockTimestamp[​](#anchorblocktimestamp)

Anchor block timestamp at message emission.

**Type:** `bigint`

#### OffchainOutput[​](#offchainoutput)

**Type:** Type Alias

Groups all unproven outputs from private execution that are returned to the client.

**Signature:**

```
export type OffchainOutput = { offchainEffects: OffchainEffect[]; offchainMessages: OffchainMessage[];};
```

**Type Members:**

##### offchainEffects[​](#offchaineffects)

Raw offchain effects emitted during execution.

**Type:** `OffchainEffect[]`

##### offchainMessages[​](#offchainmessages)

Messages emitted during execution, to be delivered offchain.

**Type:** `OffchainMessage[]`

#### extractOffchainOutput[​](#extractoffchainoutput)

**Type:** Function

Splits an array of offchain effects into decoded offchain messages and remaining effects. Effects whose data starts with `OFFCHAIN_MESSAGE_IDENTIFIER` are parsed as messages and removed from the effects array.

**Signature:**

```
export extractOffchainOutput(  effects: OffchainEffect[],  anchorBlockTimestamp: bigint): OffchainOutput
```

**Parameters:**

- `effects`: `OffchainEffect[]`
- `anchorBlockTimestamp`: `bigint`

**Returns:**

`OffchainOutput`

#### SimulationResult[​](#simulationresult)

**Type:** Type Alias

Represents the result of a simulation. Always includes the return value and offchain output. When `includeMetadata` is set, also includes stats and the simulated gas usage.

**Signature:**

```
export type SimulationResult = { result: any; stats?: SimulationStats; gasUsed?: GasUsed;} & OffchainOutput;
```

**Type Members:**

##### result[​](#result)

Return value of the function

**Type:** `any`

##### stats[​](#stats)

Additional stats about the simulation. Present when `includeMetadata` is set.

**Type:** `SimulationStats`

##### gasUsed[​](#gasused)

Raw gas consumed by the simulated transaction. Present when `includeMetadata` is set. Apps that want to declare explicit gas limits should derive their own from this (e.g. pad `totalGas`) and pass them via the fee options; otherwise the wallet fills in the network's per-tx admission limits automatically.

**Type:** `GasUsed`

#### TxSendResultImmediate[​](#txsendresultimmediate)

**Type:** Type Alias

Result of sendTx when not waiting for mining.

**Signature:**

```
export type TxSendResultImmediate = { txHash: TxHash;} & OffchainOutput;
```

**Type Members:**

##### txHash[​](#txhash)

The hash of the sent transaction.

**Type:** `TxHash`

#### TxSendResultMined[​](#txsendresultmined)

**Type:** Type Alias

Result of sendTx when waiting for mining.

**Signature:**

```
export type TxSendResultMined<TReturn = TxReceipt> = { receipt: TReturn;} & OffchainOutput;
```

**Type Members:**

##### receipt[​](#receipt-1)

The transaction receipt.

**Type:** `TReturn`

#### SendReturn[​](#sendreturn)

**Type:** Type Alias

Represents the result type of sending a transaction. If `wait` is NO_WAIT, returns TxSendResultImmediate. Otherwise returns TxSendResultMined.

**Signature:**

```
export type SendReturn<T extends InteractionWaitOptions, TReturn = TxReceipt> = T extends NoWait ? TxSendResultImmediate : TxSendResultMined<TReturn>;
```

#### toSendOptions[​](#tosendoptions)

**Type:** Function

Transforms and cleans up the higher level SendInteractionOptions defined by the interaction into SendOptions, which are the ones that can be serialized and forwarded to the wallet

**Signature:**

```
export toSendOptions<W extends InteractionWaitOptions = undefined>(options: SendInteractionOptions<W>): SendOptions<W>
```

**Parameters:**

- `options`: `SendInteractionOptions<W>`

  - The send interaction options with optional wait parameter

**Returns:**

`SendOptions<W>` - The send options to forward to the wallet

#### toSimulateOptions[​](#tosimulateoptions)

**Type:** Function

Transforms and cleans up the higher level SimulateInteractionOptions defined by the interaction into SimulateOptions, which are the ones that can be serialized and forwarded to the wallet

**Signature:**

```
export toSimulateOptions(options: SimulateInteractionOptions): SimulateOptions
```

**Parameters:**

- `options`: `SimulateInteractionOptions`

**Returns:**

`SimulateOptions`

#### toProfileOptions[​](#toprofileoptions)

**Type:** Function

Transforms and cleans up the higher level ProfileInteractionOptions defined by the interaction into ProfileOptions, which are the ones that can be serialized and forwarded to the wallet

**Signature:**

```
export toProfileOptions(options: ProfileInteractionOptions): ProfileOptions
```

**Parameters:**

- `options`: `ProfileInteractionOptions`

**Returns:**

`ProfileOptions`

---

### `contract/wait_for_proven.ts`[​](#contractwait_for_provents)

#### WaitForProvenOpts[​](#waitforprovenopts)

**Type:** Type Alias

Options for waiting for a transaction to be proven.

**Signature:**

```
export type WaitForProvenOpts = { provenTimeout?: number; interval?: number;};
```

**Type Members:**

##### provenTimeout[​](#proventimeout)

Time to wait for the tx to be proven before timing out

**Type:** `number`

##### interval[​](#interval)

Elapsed time between polls to the node

**Type:** `number`

#### DefaultWaitForProvenOpts[​](#defaultwaitforprovenopts)

**Type:** Constant

**Value Type:** `WaitForProvenOpts`

#### waitForProven[​](#waitforproven)

**Type:** Function

Wait for a transaction to be proven by polling the node

**Signature:**

```
export async waitForProven(  node: AztecNode,  receipt: TxReceipt,  opts?: WaitForProvenOpts)
```

**Parameters:**

- `node`: `AztecNode`
- `receipt`: `TxReceipt`
- `opts` (optional): `WaitForProvenOpts`

**Returns:**

`Promise<any>`

---

### `contract/wait_opts.ts`[​](#contractwait_optsts)

#### WaitOpts[​](#waitopts)

**Type:** Type Alias

Options related to waiting for a tx.

**Signature:**

```
export type WaitOpts = { ignoreDroppedReceiptsFor?: number; timeout?: number; interval?: number; dontThrowOnRevert?: boolean; waitForStatus?: TxStatus; initialDelay?: number;};
```

**Type Members:**

##### ignoreDroppedReceiptsFor[​](#ignoredroppedreceiptsfor)

The amount of time to ignore TxStatus.DROPPED receipts (in seconds) due to the presumption that it is being propagated by the p2p network. Defaults to 5.

**Type:** `number`

##### timeout[​](#timeout)

The maximum time (in seconds) to wait for the transaction to be mined. Defaults to 300 (5 min).

**Type:** `number`

##### interval[​](#interval-1)

The time interval (in seconds) between retries to fetch the transaction receipt. Defaults to 1.

**Type:** `number`

##### dontThrowOnRevert[​](#dontthrowonrevert)

Whether to accept a revert as a status code for the tx when waiting for it. If false, will throw if the tx reverts.

**Type:** `boolean`

##### waitForStatus[​](#waitforstatus)

The minimum inclusion status to wait for. If set, waits until the receipt reaches this status or higher. Defaults to CHECKPOINTED.

**Type:** `TxStatus`

##### initialDelay[​](#initialdelay)

The time (in seconds) to wait before the first receipt poll. Defaults to 0. Used to avoid checking for a receipt right after sending a tx, when we know it cannot have been mined yet. Counts against `timeout`.

**Type:** `number`

#### DefaultWaitOpts[​](#defaultwaitopts)

**Type:** Constant

**Value Type:** `WaitOpts`

## Deployment[​](#deployment)

---

### `deployment/contract_deployer.ts`[​](#deploymentcontract_deployerts)

#### ContractDeployer[​](#contractdeployer)

**Type:** Class

A class for deploying contract.

#### Constructor[​](#constructor-10)

**Signature:**

```
constructor(  private artifact: ContractArtifact,  private wallet: Wallet,  private constructorName?: string)
```

**Parameters:**

- `artifact`: `ContractArtifact`
- `wallet`: `Wallet`
- `constructorName` (optional): `string`

#### Methods[​](#methods-14)

##### deploy[​](#deploy-1)

Deploy a contract using the provided instantiation parameters and constructor arguments. Creates a new DeployMethod instance that can be used to send the deployment transaction. The first argument is the DeployInstantiationOptions (salt, deployer) — pass `{}` to accept defaults (random salt, deployer = AztecAddress.ZERO). The remaining arguments are the constructor arguments for the contract.

**Signature:**

```
public deploy(  args?: any[],  instantiation?: DeployInstantiationOptions)
```

**Parameters:**

- `args` (optional): `any[]`

  - The constructor arguments for the contract being deployed.
- `instantiation` (optional): `DeployInstantiationOptions`

  - Salt and deployer to mix into the address derivation.

**Returns:**

`DeployMethod<Contract>` - A DeployMethod instance configured with the ABI, PXE, and constructor arguments.

---

### `deployment/publish_class.ts`[​](#deploymentpublish_classts)

#### publishContractClass[​](#publishcontractclass)

**Type:** Function

Sets up a call to publish a contract class given its artifact.

**Signature:**

```
export async publishContractClass(  wallet: Wallet,  artifact: ContractArtifact): Promise<ContractFunctionInteraction>
```

**Parameters:**

- `wallet`: `Wallet`
- `artifact`: `ContractArtifact`

**Returns:**

`Promise<ContractFunctionInteraction>`

---

### `deployment/publish_instance.ts`[​](#deploymentpublish_instancets)

#### publishInstance[​](#publishinstance)

**Type:** Function

Sets up a call to the canonical contract instance registry to publish a contract instance.

**Signature:**

```
export publishInstance(  wallet: Wallet,  instance: ContractInstanceWithAddress): ContractFunctionInteraction
```

**Parameters:**

- `wallet`: `Wallet`

  - The wallet to use for the publication (setup) tx.
- `instance`: `ContractInstanceWithAddress`

  - The instance to publish.

**Returns:**

`ContractFunctionInteraction`

## Ethereum[​](#ethereum)

---

### `ethereum/portal_manager.ts`[​](#ethereumportal_managerts)

#### L2Claim[​](#l2claim)

**Type:** Type Alias

L1 to L2 message info to claim it on L2.

**Signature:**

```
export type L2Claim = { claimSecret: Fr; claimSecretHash: Fr; messageHash: Hex; messageLeafIndex: bigint;};
```

**Type Members:**

##### claimSecret[​](#claimsecret)

Secret for claiming.

**Type:** `Fr`

##### claimSecretHash[​](#claimsecrethash)

Hash of the secret for claiming.

**Type:** `Fr`

##### messageHash[​](#messagehash)

Hash of the message.

**Type:** `Hex`

##### messageLeafIndex[​](#messageleafindex)

Leaf index in the L1 to L2 message tree.

**Type:** `bigint`

#### L2AmountClaim[​](#l2amountclaim)

**Type:** Type Alias

L1 to L2 message info that corresponds to an amount to claim.

**Signature:**

```
export type L2AmountClaim = L2Claim & { claimAmount: bigint };
```

**Type Members:**

##### claimAmount[​](#claimamount)

**Type:** `bigint`

#### L2AmountClaimWithRecipient[​](#l2amountclaimwithrecipient)

**Type:** Type Alias

L1 to L2 message info that corresponds to an amount to claim with associated recipient.

**Signature:**

```
export type L2AmountClaimWithRecipient = L2AmountClaim & { recipient: AztecAddress;};
```

**Type Members:**

##### recipient[​](#recipient-1)

Address that will receive the newly minted notes.

**Type:** `AztecAddress`

#### generateClaimSecret[​](#generateclaimsecret)

**Type:** Function

Generates a pair secret and secret hash

**Signature:**

```
export async generateClaimSecret(logger?: Logger): Promise<[      Fr,      Fr  ]>
```

**Parameters:**

- `logger` (optional): `Logger`

**Returns:**

`Promise<[Fr, Fr]>`

#### L1TokenManager[​](#l1tokenmanager)

**Type:** Class

Helper for managing an ERC20 on L1.

#### Constructor[​](#constructor-11)

**Signature:**

```
public constructor(  public readonly tokenAddress: EthAddress,  public readonly handlerAddress: EthAddress | undefined,  private readonly extendedClient: ExtendedViemWalletClient,  private logger: Logger)
```

**Parameters:**

- `tokenAddress`: `EthAddress`

  - Address of the ERC20 contract.
- `handlerAddress`: `EthAddress | undefined`

  - Address of the handler/faucet contract.
- `extendedClient`: `ExtendedViemWalletClient`
- `logger`: `Logger`

#### Methods[​](#methods-15)

##### getMintAmount[​](#getmintamount)

Returns the amount of tokens available to mint via the handler.

**Signature:**

```
public async getMintAmount()
```

**Returns:**

`Promise<any>`

##### getL1TokenBalance[​](#getl1tokenbalance)

Returns the balance of the given address.

**Signature:**

```
public async getL1TokenBalance(address: Hex)
```

**Parameters:**

- `address`: `Hex`

  - Address to get the balance of.

**Returns:**

`Promise<any>`

##### mint[​](#mint)

Mints a fixed amount of tokens for the given address. Returns once the tx has been mined.

**Signature:**

```
public async mint(  address: Hex,  addressName?: string)
```

**Parameters:**

- `address`: `Hex`

  - Address to mint the tokens for.
- `addressName` (optional): `string`

  - Optional name of the address for logging.

**Returns:**

`Promise<void>`

##### approve[​](#approve)

Approves tokens for the given address. Returns once the tx has been mined.

**Signature:**

```
public async approve(  amount: bigint,  address: Hex,  addressName = '')
```

**Parameters:**

- `amount`: `bigint`

  - Amount to approve.
- `address`: `Hex`

  - Address to approve the tokens for.
- `addressName` (optional): `any`

  - Optional name of the address for logging.

**Returns:**

`Promise<void>`

#### L1FeeJuicePortalManager[​](#l1feejuiceportalmanager)

**Type:** Class

Helper for interacting with the FeeJuicePortal on L1.

#### Constructor[​](#constructor-12)

**Signature:**

```
constructor(  portalAddress: EthAddress,  tokenAddress: EthAddress,  handlerAddress: EthAddress | undefined,  private readonly extendedClient: ExtendedViemWalletClient,  private readonly logger: Logger)
```

**Parameters:**

- `portalAddress`: `EthAddress`
- `tokenAddress`: `EthAddress`
- `handlerAddress`: `EthAddress | undefined`
- `extendedClient`: `ExtendedViemWalletClient`
- `logger`: `Logger`

#### Methods[​](#methods-16)

##### getTokenManager[​](#gettokenmanager)

Returns the associated token manager for the L1 ERC20.

**Signature:**

```
public getTokenManager()
```

**Returns:**

`L1TokenManager`

##### bridgeTokensPublic[​](#bridgetokenspublic)

Bridges fee juice from L1 to L2 publicly. Handles L1 ERC20 approvals. Returns once the tx has been mined.

**Signature:**

```
public async bridgeTokensPublic(  to: AztecAddress,  amount: bigint | undefined,  mint = false): Promise<L2AmountClaim>
```

**Parameters:**

- `to`: `AztecAddress`

  - Address to send the tokens to on L2.
- `amount`: `bigint | undefined`

  - Amount of tokens to send.
- `mint` (optional): `any`

  - Whether to mint the tokens before sending (only during testing).

**Returns:**

`Promise<L2AmountClaim>`

##### new[​](#new)

Creates a new instance

**Signature:**

```
public static async new(  node: AztecNode,  extendedClient: ExtendedViemWalletClient,  logger: Logger): Promise<L1FeeJuicePortalManager>
```

**Parameters:**

- `node`: `AztecNode`

  - Aztec node client used for retrieving the L1 contract addresses.
- `extendedClient`: `ExtendedViemWalletClient`

  - Wallet client, extended with public actions.
- `logger`: `Logger`

  - Logger.

**Returns:**

`Promise<L1FeeJuicePortalManager>`

#### L1ToL2TokenPortalManager[​](#l1tol2tokenportalmanager)

**Type:** Class

Helper for interacting with a test TokenPortal on L1 for sending tokens to L2.

#### Constructor[​](#constructor-13)

**Signature:**

```
constructor(  portalAddress: EthAddress,  tokenAddress: EthAddress,  handlerAddress: EthAddress | undefined,  protected extendedClient: ExtendedViemWalletClient,  protected logger: Logger)
```

**Parameters:**

- `portalAddress`: `EthAddress`
- `tokenAddress`: `EthAddress`
- `handlerAddress`: `EthAddress | undefined`
- `extendedClient`: `ExtendedViemWalletClient`
- `logger`: `Logger`

#### Properties[​](#properties-5)

##### portal[​](#portal)

**Type:** `ViemContract<typeof TokenPortalAbi>`

##### tokenManager[​](#tokenmanager)

**Type:** `L1TokenManager`

##### l1TxUtils[​](#l1txutils)

**Type:** `L1TxUtils`

#### Methods[​](#methods-17)

##### getTokenManager[​](#gettokenmanager-1)

Returns the token manager for the underlying L1 token.

**Signature:**

```
public getTokenManager()
```

**Returns:**

`L1TokenManager`

##### bridgeTokensPublic[​](#bridgetokenspublic-1)

Bridges tokens from L1 to L2. Handles token approvals. Returns once the tx has been mined.

**Signature:**

```
public async bridgeTokensPublic(  to: AztecAddress,  amount: bigint,  mint = false): Promise<L2AmountClaim>
```

**Parameters:**

- `to`: `AztecAddress`

  - Address to send the tokens to on L2.
- `amount`: `bigint`

  - Amount of tokens to send.
- `mint` (optional): `any`

  - Whether to mint the tokens before sending (only during testing).

**Returns:**

`Promise<L2AmountClaim>`

##### bridgeTokensPrivate[​](#bridgetokensprivate)

Bridges tokens from L1 to L2 privately. Handles token approvals. Returns once the tx has been mined.

**Signature:**

```
public async bridgeTokensPrivate(  to: AztecAddress,  amount: bigint,  mint = false): Promise<L2AmountClaimWithRecipient>
```

**Parameters:**

- `to`: `AztecAddress`

  - Address to send the tokens to on L2.
- `amount`: `bigint`

  - Amount of tokens to send.
- `mint` (optional): `any`

  - Whether to mint the tokens before sending (only during testing).

**Returns:**

`Promise<L2AmountClaimWithRecipient>`

#### L1TokenPortalManager[​](#l1tokenportalmanager)

**Type:** Class

Helper for interacting with a test TokenPortal on L1 for both withdrawing from and bridging to L2.

**Extends:** `L1ToL2TokenPortalManager`

#### Constructor[​](#constructor-14)

**Signature:**

```
constructor(  portalAddress: EthAddress,  tokenAddress: EthAddress,  handlerAddress: EthAddress | undefined,  outboxAddress: EthAddress,  extendedClient: ExtendedViemWalletClient,  logger: Logger)
```

**Parameters:**

- `portalAddress`: `EthAddress`
- `tokenAddress`: `EthAddress`
- `handlerAddress`: `EthAddress | undefined`
- `outboxAddress`: `EthAddress`
- `extendedClient`: `ExtendedViemWalletClient`
- `logger`: `Logger`

#### Methods[​](#methods-18)

##### withdrawFunds[​](#withdrawfunds)

Withdraws funds from the portal by consuming an L2 to L1 message. Returns once the tx is mined on L1.

**Signature:**

```
public async withdrawFunds(  amount: bigint,  recipient: EthAddress,  epochNumber: EpochNumber,  numCheckpointsInEpoch: number,  messageIndex: bigint,  siblingPath: SiblingPath<number>)
```

**Parameters:**

- `amount`: `bigint`

  - Amount to withdraw.
- `recipient`: `EthAddress`

  - Who will receive the funds.
- `epochNumber`: `EpochNumber`

  - Epoch number of the message.
- `numCheckpointsInEpoch`: `number`

  - The partial-proof depth (1-indexed) the witness was built against.
- `messageIndex`: `bigint`

  - Index of the message.
- `siblingPath`: `SiblingPath<number>`

  - Sibling path of the message.

**Returns:**

`Promise<void>`

##### getL2ToL1MessageLeaf[​](#getl2tol1messageleaf)

Computes the L2 to L1 message leaf for the given parameters.

**Signature:**

```
public async getL2ToL1MessageLeaf(  amount: bigint,  recipient: EthAddress,  l2Bridge: AztecAddress,  callerOnL1: EthAddress = EthAddress.ZERO): Promise<Fr>
```

**Parameters:**

- `amount`: `bigint`

  - Amount to bridge.
- `recipient`: `EthAddress`

  - Recipient on L1.
- `l2Bridge`: `AztecAddress`

  - Address of the L2 bridge.
- `callerOnL1` (optional): `EthAddress`

  - Caller address on L1.

**Returns:**

`Promise<Fr>`

## Fee[​](#fee-4)

---

### `fee/fee_juice_payment_method_with_claim.ts`[​](#feefee_juice_payment_method_with_claimts)

#### FeeJuicePaymentMethodWithClaim[​](#feejuicepaymentmethodwithclaim)

**Type:** Class

Pay fee directly with Fee Juice claimed in the same tx. Claiming consumes an L1 to L2 message that "contains" the fee juice bridged from L1.

**Implements:** `FeePaymentMethod`

#### Constructor[​](#constructor-15)

**Signature:**

```
constructor(  private sender: AztecAddress,  private claim: Pick<L2AmountClaim, 'claimAmount' | 'claimSecret' | 'messageLeafIndex'>)
```

**Parameters:**

- `sender`: `AztecAddress`
- `claim`: `Pick<L2AmountClaim, 'claimAmount' | 'claimSecret' | 'messageLeafIndex'>`

#### Methods[​](#methods-19)

##### getExecutionPayload[​](#getexecutionpayload)

Creates an execution payload to pay the fee in Fee Juice.

**Signature:**

```
async getExecutionPayload(): Promise<ExecutionPayload>
```

**Returns:**

`Promise<ExecutionPayload>` - An execution payload that just contains the `claim_and_end_setup` function call.

##### getAsset[​](#getasset)

**Signature:**

```
getAsset()
```

**Returns:**

`Promise<any>`

##### getFeePayer[​](#getfeepayer)

**Signature:**

```
getFeePayer(): Promise<AztecAddress>
```

**Returns:**

`Promise<AztecAddress>`

##### getGasSettings[​](#getgassettings)

**Signature:**

```
getGasSettings(): GasSettings | undefined
```

**Returns:**

`GasSettings | undefined`

---

### `fee/fee_payment_method.ts`[​](#feefee_payment_methodts)

#### FeePaymentMethod[​](#feepaymentmethod)

**Type:** Interface

Holds information about how the fee for a transaction is to be paid.

#### Methods[​](#methods-20)

##### getAsset[​](#getasset-1)

The asset used to pay the fee.

**Signature:**

```
getAsset(): Promise<AztecAddress>
```

**Returns:**

`Promise<AztecAddress>`

##### getExecutionPayload[​](#getexecutionpayload-1)

Returns the data to be added to the final execution request to pay the fee in the given asset

**Signature:**

```
getExecutionPayload(): Promise<ExecutionPayload>
```

**Returns:**

`Promise<ExecutionPayload>` - The function calls to pay the fee.

##### getFeePayer[​](#getfeepayer-1)

The expected fee payer for this tx.

**Signature:**

```
getFeePayer(): Promise<AztecAddress>
```

**Returns:**

`Promise<AztecAddress>`

##### getGasSettings[​](#getgassettings-1)

The gas settings (if any) used to compute the execution payload of the payment method

**Signature:**

```
getGasSettings(): GasSettings | undefined
```

**Returns:**

`GasSettings | undefined`

---

### `fee/private_fee_payment_method.ts`[​](#feeprivate_fee_payment_methodts)

#### PrivateFeePaymentMethod[​](#privatefeepaymentmethod)

**Type:** Class

**Deprecated:** Is not supported on mainnet. Use FeeJuicePaymentMethodWithClaim or `SponsoredFeePaymentMethod` instead.

Holds information about how the fee for a transaction is to be paid.

**Implements:** `FeePaymentMethod`

#### Constructor[​](#constructor-16)

**Signature:**

```
constructor(  private paymentContract: AztecAddress,  private sender: AztecAddress,  private wallet: Wallet,  protected gasSettings: GasSettings,  private setMaxFeeToOne = false)
```

**Parameters:**

- `paymentContract`: `AztecAddress`

  - Address which will hold the fee payment.
- `sender`: `AztecAddress`

  - Address of the account that will pay the fee
- `wallet`: `Wallet`

  - A wallet to perform the simulation to get the accepted asset
- `gasSettings`: `GasSettings`

  - Gas settings used to compute the maximum fee the user is willing to pay
- `setMaxFeeToOne` (optional): `any`

  - If true, the max fee will be set to 1. TODO(#7694): Remove this param once the lacking feature in TXE is implemented.

#### Methods[​](#methods-21)

##### getAsset[​](#getasset-2)

The asset used to pay the fee.

**Signature:**

```
async getAsset(): Promise<AztecAddress>
```

**Returns:**

`Promise<AztecAddress>` - The asset used to pay the fee.

##### getFeePayer[​](#getfeepayer-2)

**Signature:**

```
getFeePayer(): Promise<AztecAddress>
```

**Returns:**

`Promise<AztecAddress>`

##### getExecutionPayload[​](#getexecutionpayload-2)

Creates an execution payload to pay the fee using a private function through an FPC in the desired asset

**Signature:**

```
async getExecutionPayload(): Promise<ExecutionPayload>
```

**Returns:**

`Promise<ExecutionPayload>` - An execution payload that contains the required function calls and auth witnesses.

##### getGasSettings[​](#getgassettings-2)

**Signature:**

```
getGasSettings(): GasSettings | undefined
```

**Returns:**

`GasSettings | undefined`

---

### `fee/public_fee_payment_method.ts`[​](#feepublic_fee_payment_methodts)

#### PublicFeePaymentMethod[​](#publicfeepaymentmethod)

**Type:** Class

**Deprecated:** Is not supported on mainnet. Use FeeJuicePaymentMethodWithClaim or `SponsoredFeePaymentMethod` instead.

Holds information about how the fee for a transaction is to be paid.

**Implements:** `FeePaymentMethod`

#### Constructor[​](#constructor-17)

**Signature:**

```
constructor(  protected paymentContract: AztecAddress,  protected sender: AztecAddress,  protected wallet: Wallet,  protected gasSettings: GasSettings)
```

**Parameters:**

- `paymentContract`: `AztecAddress`

  - Address which will hold the fee payment.
- `sender`: `AztecAddress`

  - An auth witness provider to authorize fee payments
- `wallet`: `Wallet`

  - A wallet to perform the simulation to get the accepted asset
- `gasSettings`: `GasSettings`

  - Gas settings used to compute the maximum fee the user is willing to pay

#### Methods[​](#methods-22)

##### getAsset[​](#getasset-3)

The asset used to pay the fee.

**Signature:**

```
async getAsset(): Promise<AztecAddress>
```

**Returns:**

`Promise<AztecAddress>` - The asset used to pay the fee.

##### getFeePayer[​](#getfeepayer-3)

**Signature:**

```
getFeePayer(): Promise<AztecAddress>
```

**Returns:**

`Promise<AztecAddress>`

##### getExecutionPayload[​](#getexecutionpayload-3)

Creates an execution payload to pay the fee using a public function through an FPC in the desired asset

**Signature:**

```
async getExecutionPayload(): Promise<ExecutionPayload>
```

**Returns:**

`Promise<ExecutionPayload>` - An execution payload that contains the required function calls.

##### getGasSettings[​](#getgassettings-3)

**Signature:**

```
getGasSettings(): GasSettings | undefined
```

**Returns:**

`GasSettings | undefined`

---

### `fee/sponsored_fee_payment.ts`[​](#feesponsored_fee_paymentts)

#### SponsoredFeePaymentMethod[​](#sponsoredfeepaymentmethod)

**Type:** Class

A fee payment method that uses a contract that blindly sponsors transactions. This contract is expected to be prefunded in testing environments.

**Implements:** `FeePaymentMethod`

#### Constructor[​](#constructor-18)

**Signature:**

```
constructor(private paymentContract: AztecAddress)
```

**Parameters:**

- `paymentContract`: `AztecAddress`

#### Methods[​](#methods-23)

##### getAsset[​](#getasset-4)

**Signature:**

```
getAsset(): Promise<AztecAddress>
```

**Returns:**

`Promise<AztecAddress>`

##### getFeePayer[​](#getfeepayer-4)

**Signature:**

```
getFeePayer()
```

**Returns:**

`Promise<any>`

##### getExecutionPayload[​](#getexecutionpayload-4)

**Signature:**

```
async getExecutionPayload(): Promise<ExecutionPayload>
```

**Returns:**

`Promise<ExecutionPayload>`

##### getGasSettings[​](#getgassettings-4)

**Signature:**

```
getGasSettings(): GasSettings | undefined
```

**Returns:**

`GasSettings | undefined`

## Utils[​](#utils)

---

### `utils/abi_types.ts`[​](#utilsabi_typests)

#### FieldLike[​](#fieldlike)

**Type:** Type Alias

Any type that can be converted into a field for a contract call.

**Signature:**

```
export type FieldLike = Fr | Buffer | bigint | number | { toField: () => Fr };
```

#### EthAddressLike[​](#ethaddresslike)

**Type:** Type Alias

Any type that can be converted into an EthAddress Aztec.nr struct.

**Signature:**

```
export type EthAddressLike = { address: FieldLike } | EthAddress;
```

#### AztecAddressLike[​](#aztecaddresslike)

**Type:** Type Alias

Any type that can be converted into an AztecAddress Aztec.nr struct.

**Signature:**

```
export type AztecAddressLike = { address: FieldLike } | AztecAddress;
```

#### FunctionSelectorLike[​](#functionselectorlike)

**Type:** Type Alias

Any type that can be converted into a FunctionSelector Aztec.nr struct.

**Signature:**

```
export type FunctionSelectorLike = FieldLike | FunctionSelector;
```

#### EventSelectorLike[​](#eventselectorlike)

**Type:** Type Alias

Any type that can be converted into an EventSelector Aztec.nr struct.

**Signature:**

```
export type EventSelectorLike = FieldLike | EventSelector;
```

#### U128Like[​](#u128like)

**Type:** Type Alias

Any type that can be converted into a U128.

**Signature:**

```
export type U128Like = bigint | number;
```

#### WrappedFieldLike[​](#wrappedfieldlike)

**Type:** Type Alias

Any type that can be converted into a struct with a single `inner` field.

**Signature:**

```
export type WrappedFieldLike = { inner: FieldLike } | FieldLike;
```

#### OptionLike[​](#optionlike)

**Type:** Type Alias

Noir `Option<T>` lowered ABI shape, plus ergonomic direct `T | null | undefined` inputs.

**Signature:**

```
export type OptionLike<T> = | T | null | undefined | { _is_some: boolean; _value: T };
```

---

### `utils/authwit.ts`[​](#utilsauthwitts)

#### IntentInnerHash[​](#intentinnerhash)

**Type:** Type Alias

Intent with an inner hash

**Signature:**

```
export type IntentInnerHash = { consumer: AztecAddress; innerHash: Fr;};
```

**Type Members:**

##### consumer[​](#consumer)

The consumer

**Type:** `AztecAddress`

##### innerHash[​](#innerhash)

The action to approve

**Type:** `Fr`

#### CallIntent[​](#callintent)

**Type:** Type Alias

Intent with a call

**Signature:**

```
export type CallIntent = { caller: AztecAddress; call: FunctionCall;};
```

**Type Members:**

##### caller[​](#caller)

The caller to approve

**Type:** `AztecAddress`

##### call[​](#call)

The call to approve

**Type:** `FunctionCall`

#### ContractFunctionInteractionCallIntent[​](#contractfunctioninteractioncallintent)

**Type:** Type Alias

Intent with a ContractFunctionInteraction

**Signature:**

```
export type ContractFunctionInteractionCallIntent = { caller: AztecAddress; action: ContractFunctionInteraction;};
```

**Type Members:**

##### caller[​](#caller-1)

The caller to approve

**Type:** `AztecAddress`

##### action[​](#action)

The action to approve

**Type:** `ContractFunctionInteraction`

#### isContractFunctionInteractionCallIntent[​](#iscontractfunctioninteractioncallintent)

**Type:** Function

Identifies ContractFunctionInteractionCallIntents

**Signature:**

```
export isContractFunctionInteractionCallIntent(messageHashOrIntent: Fr | IntentInnerHash | CallIntent | ContractFunctionInteractionCallIntent): messageHashOrIntent is ContractFunctionInteractionCallIntent
```

**Parameters:**

- `messageHashOrIntent`: `Fr | IntentInnerHash | CallIntent | ContractFunctionInteractionCallIntent`

**Returns:**

`messageHashOrIntent is ContractFunctionInteractionCallIntent`

#### computeAuthWitMessageHash[​](#computeauthwitmessagehash)

**Type:** Constant

Compute an authentication witness message hash from an intent and metadata If using the `IntentInnerHash`, the consumer is the address that can "consume" the authwit, for token approvals it is the token contract itself. The `innerHash` itself will be the message that a contract is allowed to execute. At the point of "approval checking", the validating contract (account for private and registry for public) will be computing the message hash (`H(consumer, chainid, version, inner_hash)`) where the all but the `inner_hash` is injected from the context (consumer = msg_sender), and use it for the authentication check. Therefore, any allowed `innerHash` will therefore also have information around where it can be spent (version, chainId) and who can spend it (consumer). If using the `CallIntent`, the caller is the address that is making the call, for a token approval from Alice to Bob, this would be Bob. The action is then used along with the `caller` to compute the `innerHash` and the consumer.

**Value Type:** `any`

#### getMessageHashFromIntent[​](#getmessagehashfromintent)

**Type:** Function

Compute an authentication witness message hash from an intent and metadata. This is just a wrapper around computeAuthwitMessageHash that allows receiving an already computed messageHash as input

**Signature:**

```
export async getMessageHashFromIntent(  messageHashOrIntent: Fr | IntentInnerHash | CallIntent | ContractFunctionInteractionCallIntent,  chainInfo: ChainInfo)
```

**Parameters:**

- `messageHashOrIntent`: `Fr | IntentInnerHash | CallIntent | ContractFunctionInteractionCallIntent`

  - The precomputed messageHash or intent to approve (consumer and innerHash or caller and call/action)
- `chainInfo`: `ChainInfo`

**Returns:**

`Promise<Fr>` - The message hash for the intent

#### computeInnerAuthWitHashFromAction[​](#computeinnerauthwithashfromaction)

**Type:** Constant

Computes the inner authwitness hash for either a function call or an action, for it to later be combined with the metadata required for the outer hash and eventually the full AuthWitness.

**Value Type:** `any`

#### lookupValidity[​](#lookupvalidity)

**Type:** Function

Lookup the validity of an authwit in private and public contexts. Uses the chain id and version of the wallet.

**Signature:**

```
export async lookupValidity(  wallet: Wallet,  onBehalfOf: AztecAddress,  intent: IntentInnerHash | CallIntent | ContractFunctionInteractionCallIntent,  witness: AuthWitness): Promise<{      isValidInPrivate: boolean;      isValidInPublic: boolean;  }>
```

**Parameters:**

- `wallet`: `Wallet`

  - The wallet use to simulate and read the public data
- `onBehalfOf`: `AztecAddress`

  - The address of the "approver"
- `intent`: `IntentInnerHash | CallIntent | ContractFunctionInteractionCallIntent`

  - The consumer and inner hash or the caller and action to lookup
- `witness`: `AuthWitness`

  - The computed authentication witness to check

**Returns:**

```
Promise<{  /** boolean flag indicating if the authwit is valid in private context */  isValidInPrivate: boolean;  /** boolean flag indicating if the authwit is valid in public context */  isValidInPublic: boolean;}>
```

A struct containing the validity of the authwit in private and public contexts.

#### SetPublicAuthwitContractInteraction[​](#setpublicauthwitcontractinteraction)

**Type:** Class

Convenience class designed to wrap the very common interaction of setting a public authwit in the AuthRegistry contract

**Extends:** `ContractFunctionInteraction`

#### Constructor[​](#constructor-19)

**Signature:**

```
private constructor(  wallet: Wallet,  private from: AztecAddress,  messageHash: Fr,  authorized: boolean)
```

**Parameters:**

- `wallet`: `Wallet`
- `from`: `AztecAddress`
- `messageHash`: `Fr`
- `authorized`: `boolean`

#### Methods[​](#methods-24)

##### create[​](#create-1)

**Signature:**

```
static async create(  wallet: Wallet,  from: AztecAddress,  messageHashOrIntent: Fr | IntentInnerHash | CallIntent | ContractFunctionInteractionCallIntent,  authorized: boolean)
```

**Parameters:**

- `wallet`: `Wallet`
- `from`: `AztecAddress`
- `messageHashOrIntent`: `Fr | IntentInnerHash | CallIntent | ContractFunctionInteractionCallIntent`
- `authorized`: `boolean`

**Returns:**

`Promise<SetPublicAuthwitContractInteraction>`

##### simulate[​](#simulate-3)

Overrides the simulate method, adding the sender of the authwit (authorizer) as from and preventing misuse

**Signature:**

```
public override simulate(options: Omit<SimulateInteractionOptions, 'from'> = {} as Omit<SimulateInteractionOptions, 'from'>): Promise<SimulationResult>
```

**Parameters:**

- `options` (optional): `Omit<SimulateInteractionOptions, 'from'>`

  - An optional object containing additional configuration for the transaction.

**Returns:**

`Promise<SimulationResult>` - The result of the transaction as returned by the contract function.

##### profile[​](#profile-2)

Overrides the profile method, adding the sender of the authwit (authorizer) as from and preventing misuse

**Signature:**

```
public override profile(options: Omit<ProfileInteractionOptions, 'from'> = { profileMode: 'gates' }): Promise<TxProfileResult>
```

**Parameters:**

- `options` (optional): `Omit<ProfileInteractionOptions, 'from'>`

  - Same options as `simulate`, plus profiling method

**Returns:**

`Promise<TxProfileResult>` - An object containing the function return value and profile result.

##### send[​](#send-6)

Overrides the send method, adding the sender of the authwit (authorizer) as from and preventing misuse

**Signature:**

```
public override send(options?: Omit<SendInteractionOptionsWithoutWait, 'from'>): Promise<TxSendResultMined>
```

**Parameters:**

- `options` (optional): `Omit<SendInteractionOptionsWithoutWait, 'from'>`

  - An optional object containing 'fee' options information

**Returns:**

`Promise<TxSendResultMined>` - A TxReceipt (if wait is true/undefined) or TxHash (if wait is false)

##### send[​](#send-7)

**Signature:**

```
public override send<W extends InteractionWaitOptions>(options?: Omit<SendInteractionOptions<W>, 'from'>): Promise<SendReturn<W>>
```

**Parameters:**

- `options` (optional): `Omit<SendInteractionOptions<W>, 'from'>`

**Returns:**

`Promise<SendReturn<W>>`

##### send[​](#send-8)

**Signature:**

```
public override send(options?: Omit<SendInteractionOptions<InteractionWaitOptions>, 'from'>): Promise<SendReturn<InteractionWaitOptions>>
```

**Parameters:**

- `options` (optional): `Omit<SendInteractionOptions<InteractionWaitOptions>, 'from'>`

**Returns:**

`Promise<SendReturn<InteractionWaitOptions>>`

---

### `utils/cross_chain.ts`[​](#utilscross_chaints)

#### waitForL1ToL2MessageReady[​](#waitforl1tol2messageready)

**Type:** Function

Waits for the L1 to L2 message to be ready to be consumed.

**Signature:**

```
export waitForL1ToL2MessageReady(  node: Pick<AztecNode, 'getBlockData' | 'getL1ToL2MessageCheckpoint'>,  l1ToL2MessageHash: Fr,  opts: {    timeoutSeconds: number;    chainTip?: BlockTag;})
```

**Parameters:**

- `node`: `Pick<AztecNode, 'getBlockData' | 'getL1ToL2MessageCheckpoint'>`

  - Aztec node instance used to obtain the information about the message
- `l1ToL2MessageHash`: `Fr`

  - Hash of the L1 to L2 message
- `opts`:

  - Options

```
{    /** Timeout for the operation in seconds */ timeoutSeconds: number;    /**     * Chain tip to evaluate readiness against. Defaults to `'latest'`. Set this to the tip the consuming PXE syncs to     * (e.g. `'proven'`) so readiness answers whether the message is present at the same block the transaction     * simulation will anchor to, not at a newer tip.     */    chainTip?: BlockTag;  }
```

**Returns:**

`any`

#### isL1ToL2MessageReady[​](#isl1tol2messageready)

**Type:** Function

Returns whether the L1 to L2 message is ready to be consumed.

**Signature:**

```
export async isL1ToL2MessageReady(  node: Pick<AztecNode, 'getBlockData' | 'getL1ToL2MessageCheckpoint'>,  l1ToL2MessageHash: Fr,  chainTip: BlockTag = 'latest'): Promise<boolean>
```

**Parameters:**

- `node`: `Pick<AztecNode, 'getBlockData' | 'getL1ToL2MessageCheckpoint'>`

  - Aztec node instance used to obtain the information about the message
- `l1ToL2MessageHash`: `Fr`

  - Hash of the L1 to L2 message
- `chainTip` (optional): `BlockTag`

  - Chain tip to evaluate readiness against. Defaults to `'latest'`. Pass the tip the consuming PXE syncs to (e.g. `'proven'`) so readiness is checked at the block the transaction simulation will anchor to.

**Returns:**

`Promise<boolean>` - True if the message is ready to be consumed, false otherwise

---

### `utils/fee_juice.ts`[​](#utilsfee_juicets)

#### getFeeJuiceBalance[​](#getfeejuicebalance)

**Type:** Function

Returns the owner's fee juice balance. Note: This is used only e2e_local_network_example test. TODO: Consider nuking.

**Signature:**

```
export async getFeeJuiceBalance(  owner: AztecAddress,  node: AztecNode): Promise<bigint>
```

**Parameters:**

- `owner`: `AztecAddress`
- `node`: `AztecNode`

**Returns:**

`Promise<bigint>`

---

### `utils/field_compressed_string.ts`[​](#utilsfield_compressed_stringts)

#### readFieldCompressedString[​](#readfieldcompressedstring)

**Type:** Constant

This turns

**Value Type:** `any`

---

### `utils/node.ts`[​](#utilsnodets)

#### waitForNode[​](#waitfornode)

**Type:** Constant

Waits for an Aztec node to become reachable, polling AztecNode.getNodeInfo until it succeeds.

**Value Type:** `any`

#### waitForTx[​](#waitfortx)

**Type:** Function

Waits for a transaction to be mined and returns its receipt.

**Signature:**

```
export async waitForTx(  node: AztecNode,  txHash: TxHash,  opts?: WaitOpts): Promise<TxReceipt>
```

**Parameters:**

- `node`: `AztecNode`

  - The Aztec node to query for transaction status
- `txHash`: `TxHash`

  - The hash of the transaction to wait for
- `opts` (optional): `WaitOpts`

  - Optional configuration for waiting behavior

**Returns:**

`Promise<TxReceipt>` - The transaction receipt

#### createAztecNodeClient[​](#createaztecnodeclient)

**Type:** Constant

This is re-exported from `@aztec/stdlib/interfaces/client`. See the source module for full documentation.

**Value Type:** `Re-export`

#### AztecNode[​](#aztecnode)

**Type:** Type Alias

This is a type re-exported from `@aztec/stdlib/interfaces/client`. See the source module for full type definition and documentation.

**Signature:**

```
export type { AztecNode } from '@aztec/stdlib/interfaces/client'
```

---

### `utils/pub_key.ts`[​](#utilspub_keyts)

#### generatePublicKey[​](#generatepublickey)

**Type:** Function

Method for generating a public grumpkin key from a private key.

**Signature:**

```
export generatePublicKey(privateKey: GrumpkinScalar): Promise<PublicKey>
```

**Parameters:**

- `privateKey`: `GrumpkinScalar`

  - The private key.

**Returns:**

`Promise<PublicKey>` - The generated public key.

## Wallet[​](#wallet)

---

### `wallet/account_entrypoint_meta_payment_method.ts`[​](#walletaccount_entrypoint_meta_payment_methodts)

#### AccountEntrypointMetaPaymentMethod[​](#accountentrypointmetapaymentmethod)

**Type:** Class

Fee payment method that allows an account contract to pay for its own deployment It works by rerouting the provided fee payment method through the account's entrypoint, which sets itself as fee payer. If no payment method is provided, it is assumed the account will pay with its own fee juice balance. Usually, in order to pay fees it is necessary to obtain an ExecutionPayload that encodes the necessary information that is sent to the user's account entrypoint, that has plumbing to handle it. If there's no account contract yet (it's being deployed) a MultiCallContract is used, which doesn't have a concept of fees or how to handle this payload. HOWEVER, the account contract's entrypoint does, so this method reshapes that fee payload into a call to the account contract entrypoint being deployed with the original fee payload. This class can be seen in action in DeployAccountMethod.ts#getSelfPaymentMethod

**Implements:** `FeePaymentMethod`

#### Constructor[​](#constructor-20)

**Signature:**

```
constructor(  private account: Account,  private chainInfo: ChainInfo,  private paymentMethod?: FeePaymentMethod,  private feeEntrypointOptions?: any)
```

**Parameters:**

- `account`: `Account`
- `chainInfo`: `ChainInfo`
- `paymentMethod` (optional): `FeePaymentMethod`
- `feeEntrypointOptions` (optional): `any`

#### Methods[​](#methods-25)

##### getAsset[​](#getasset-5)

**Signature:**

```
getAsset(): Promise<AztecAddress>
```

**Returns:**

`Promise<AztecAddress>`

##### getExecutionPayload[​](#getexecutionpayload-5)

**Signature:**

```
async getExecutionPayload(): Promise<ExecutionPayload>
```

**Returns:**

`Promise<ExecutionPayload>`

##### getFeePayer[​](#getfeepayer-5)

**Signature:**

```
getFeePayer(): Promise<AztecAddress>
```

**Returns:**

`Promise<AztecAddress>`

##### getGasSettings[​](#getgassettings-5)

**Signature:**

```
getGasSettings(): GasSettings | undefined
```

**Returns:**

`GasSettings | undefined`

---

### `wallet/account_manager.ts`[​](#walletaccount_managerts)

#### AccountManagerCreateOptions[​](#accountmanagercreateoptions)

**Type:** Interface

Optional overrides passed to AccountManager.create.

#### Properties[​](#properties-6)

##### salt[​](#salt-2)

Contract instantiation salt. Defaults to a random `Fr`.

**Type:** `Salt`

##### immutablesHash[​](#immutableshash-2)

Commitment to the contract's immutable storage values. Folded into the salted initialization hash, so a non-zero value affects the derived address. Defaults to `Fr.ZERO`.

**Type:** `Fr`

##### deployer[​](#deployer-5)

Address recorded as the instance deployer. Defaults to `AztecAddress.ZERO`.

**Type:** `AztecAddress`

#### AccountManager[​](#accountmanager)

**Type:** Class

Manages a user account. Provides methods for calculating the account's address and other related data, plus a helper to return a preconfigured deploy method.

#### Constructor[​](#constructor-21)

**Signature:**

```
private constructor(  private wallet: Wallet,  private secretKey: Fr,  private accountContract: AccountContract,  private instance: ContractInstanceWithAddress)
```

**Parameters:**

- `wallet`: `Wallet`
- `secretKey`: `Fr`
- `accountContract`: `AccountContract`
- `instance`: `ContractInstanceWithAddress`

#### Methods[​](#methods-26)

##### create[​](#create-2)

**Signature:**

```
static async create(  wallet: Wallet,  secretKey: Fr,  accountContract: AccountContract,  opts?: AccountManagerCreateOptions)
```

**Parameters:**

- `wallet`: `Wallet`
- `secretKey`: `Fr`
- `accountContract`: `AccountContract`
- `opts` (optional): `AccountManagerCreateOptions`

**Returns:**

`Promise<AccountManager>`

##### getPublicKeys[​](#getpublickeys)

**Signature:**

```
protected getPublicKeys()
```

**Returns:**

`any`

##### getPublicKeysHash[​](#getpublickeyshash)

**Signature:**

```
protected getPublicKeysHash()
```

**Returns:**

`any`

##### getCompleteAddress[​](#getcompleteaddress-2)

Gets the calculated complete address associated with this account. Does not require the account to have been published for public execution.

**Signature:**

```
public getCompleteAddress(): Promise<CompleteAddress>
```

**Returns:**

`Promise<CompleteAddress>` - The address, partial address, and encryption public key.

##### getSecretKey[​](#getsecretkey)

Returns the secret key used to derive the rest of the privacy keys for this contract

**Signature:**

```
public getSecretKey()
```

**Returns:**

`Fr`

##### getInstance[​](#getinstance-1)

Returns the contract instance definition associated with this account. Does not require the account to have been published for public execution.

**Signature:**

```
public getInstance(): ContractInstanceWithAddress
```

**Returns:**

`ContractInstanceWithAddress` - ContractInstance instance.

##### getAccount[​](#getaccount-1)

Returns the account (the transaction signer) backed by this account contract. Use it to build and authorize transactions from this account.

**Signature:**

```
public async getAccount(): Promise<Account>
```

**Returns:**

`Promise<Account>`

##### getAccountContract[​](#getaccountcontract)

Returns the account contract that backs this account.

**Signature:**

```
getAccountContract(): AccountContract
```

**Returns:**

`AccountContract` - The account contract

##### getDeployMethod[​](#getdeploymethod)

Returns a preconfigured deploy method that contains all the necessary function calls to deploy the account contract.

**Signature:**

```
public async getDeployMethod(): Promise<DeployAccountMethod>
```

**Returns:**

`Promise<DeployAccountMethod>`

##### hasInitializer[​](#hasinitializer)

Returns whether this account contract has an initializer function.

**Signature:**

```
public async hasInitializer()
```

**Returns:**

`Promise<boolean>`

#### Getters[​](#getters)

##### address (getter)[​](#address-getter)

**Signature:**

```
get address() {
```

**Returns:**

`any`

---

### `wallet/capabilities.ts`[​](#walletcapabilitiests)

#### CAPABILITY_VERSION[​](#capability_version)

**Type:** Constant

Current capability manifest version.

**Value Type:** `any`

#### ContractFunctionPattern[​](#contractfunctionpattern)

**Type:** Interface

Pattern for matching contract functions with wildcards. Used in simulation and transaction capabilities to specify which contract functions are allowed.

#### Properties[​](#properties-7)

##### contract[​](#contract-3)

Contract address or '*' for any contract

**Type:** `AztecAddress | '*'`

##### function[​](#function)

Function name or '*' for any function

**Type:** `string`

##### additionalScopes[​](#additionalscopes-1)

Additional addresses whose private state and keys are accessible when calling this function, beyond the sender's. - undefined: No additional scopes allowed - AztecAddress[]: Only these specific addresses allowed as additional scopes - '*': All known address allowed as an additional scope

**Type:** `AztecAddress[] | '*'`

#### AccountsCapability[​](#accountscapability)

**Type:** Interface

Account access capability - grants access to user accounts. Maps to wallet methods: - getAccounts (when canGet: true) - createAuthWit (when canCreateAuthWit: true) The wallet decides which accounts to reveal to the app. Apps don't specify which accounts they want - they just request the capability and the wallet shows them the available accounts.

#### Properties[​](#properties-8)

##### type[​](#type)

Discriminator for capability type

**Type:** `'accounts'`

##### canGet[​](#canget)

Can get accounts from wallet. Maps to: getAccounts

**Type:** `boolean`

##### canCreateAuthWit[​](#cancreateauthwit)

Can create auth witnesses for accounts. Maps to: createAuthWit

**Type:** `boolean`

#### GrantedAccountsCapability[​](#grantedaccountscapability)

**Type:** Interface

Granted account access capability. Extends the request with specific accounts that were granted by the wallet.

**Extends:** `AccountsCapability`

#### Properties[​](#properties-9)

##### accounts[​](#accounts)

Specific accounts granted by the wallet with their aliases. The wallet adds this when granting the capability.

**Type:** `Aliased<AztecAddress>[]`

#### ContractsCapability[​](#contractscapability)

**Type:** Interface

Contract interaction capability - for registering and querying contracts. Maps to wallet methods: - registerContract (when canRegister: true) - getContractMetadata (when canGetMetadata: true) Matching is done by contract address, not class ID. This allows updating existing contracts with new artifacts (e.g., when contract is upgraded to a new contractClassId onchain). Note: For querying contract class metadata, use ContractClassesCapability instead.

#### Properties[​](#properties-10)

##### type[​](#type-1)

Discriminator for capability type

**Type:** `'contracts'`

##### contracts[​](#contracts)

Which contracts this applies to: - '*': Any contract address - AztecAddress[]: Specific contract addresses

**Type:** `'*' | AztecAddress[]`

##### canRegister[​](#canregister)

Can register contracts and update existing registrations. Maps to: registerContract When true, allows: - Registering new contract instances at specified addresses - Re-registering existing contracts with updated artifacts (e.g., after upgrade)

**Type:** `boolean`

##### canGetMetadata[​](#cangetmetadata)

Can query contract metadata. Maps to: getContractMetadata

**Type:** `boolean`

#### GrantedContractsCapability[​](#grantedcontractscapability)

**Type:** Interface

Granted contract interaction capability. The wallet may reduce the scope (e.g., from '*' to specific addresses).

**Extends:** `ContractsCapability`

#### ContractClassesCapability[​](#contractclassescapability)

**Type:** Interface

Contract class capability - for querying contract class metadata and registering contract classes. Maps to wallet methods: - getContractClassMetadata (when canGetMetadata: true) - registerContractClass (when canRegister: true) Contract classes are identified by their class ID (Fr), not by contract address. Multiple contract instances can share the same class. This capability grants permission to query metadata for, and register, specific contract classes. Apps typically acquire this permission automatically when registering a contract with an artifact (the wallet auto-grants permission for that contract's class ID).

#### Properties[​](#properties-11)

##### type[​](#type-2)

Discriminator for capability type

**Type:** `'contractClasses'`

##### classes[​](#classes)

Which contract classes this applies to: - '*': Any contract class ID - Fr[]: Specific contract class IDs

**Type:** `'*' | Fr[]`

##### canRegister[​](#canregister-1)

Can register a contract class artifact in the local PXE. Maps to: registerContractClass

**Type:** `boolean`

##### canGetMetadata[​](#cangetmetadata-1)

Can query contract class metadata. Maps to: getContractClassMetadata

**Type:** `boolean`

#### GrantedContractClassesCapability[​](#grantedcontractclassescapability)

**Type:** Interface

Granted contract class capability. The wallet may reduce the scope (e.g., from '*' to specific class IDs).

**Extends:** `ContractClassesCapability`

#### SimulationCapability[​](#simulationcapability)

**Type:** Interface

Transaction simulation capability - for simulating transactions and executing utilities. Maps to wallet methods: - simulateTx (when transactions scope specified) - executeUtility (when utilities scope specified) - profileTx (when transactions scope specified)

#### Properties[​](#properties-12)

##### type[​](#type-3)

Discriminator for capability type

**Type:** `'simulation'`

##### transactions[​](#transactions)

Transaction simulation scope. Maps to: simulateTx, profileTx

**Type:**

```
{    /**     * Which contracts/functions to allow:     * - '*': Any transaction     * - ContractFunctionPattern[]: Specific contract functions     */    scope: '*' | ContractFunctionPattern[];  }
```

##### utilities[​](#utilities)

Utility execution scope (unconstrained calls). Maps to: executeUtility

**Type:**

```
{    /**     * Which contracts/functions to allow:     * - '*': Any utility call     * - ContractFunctionPattern[]: Specific contract functions     */    scope: '*' | ContractFunctionPattern[];  }
```

#### GrantedSimulationCapability[​](#grantedsimulationcapability)

**Type:** Interface

Granted transaction simulation capability. The wallet may reduce the scope (e.g., from '*' to specific patterns).

**Extends:** `SimulationCapability`

#### TransactionCapability[​](#transactioncapability)

**Type:** Interface

Transaction execution capability - for sending transactions. Maps to wallet methods: - sendTx Policy enforcement (rate limits, spending limits) should be handled at the contract level in Aztec, not at the wallet level.

#### Properties[​](#properties-13)

##### type[​](#type-4)

Discriminator for capability type

**Type:** `'transaction'`

##### scope[​](#scope)

Which contracts/functions to allow: - '*': Any transaction - ContractFunctionPattern[]: Specific patterns

**Type:** `'*' | ContractFunctionPattern[]`

#### GrantedTransactionCapability[​](#grantedtransactioncapability)

**Type:** Interface

Granted transaction execution capability. The wallet may reduce the scope (e.g., from '*' to specific patterns).

**Extends:** `TransactionCapability`

#### DataCapability[​](#datacapability)

**Type:** Interface

Data access capability - for querying private data. Maps to wallet methods: - getAddressBook (when addressBook: true) - getPrivateEvents (when privateEvents specified)

#### Properties[​](#properties-14)

##### type[​](#type-5)

Discriminator for capability type

**Type:** `'data'`

##### addressBook[​](#addressbook)

Access to address book. Maps to: getAddressBook

**Type:** `boolean`

##### privateEvents[​](#privateevents)

Access to private events. Maps to: getPrivateEvents

**Type:**

```
{    /**     * Which contracts to allow event queries from:     * - '*': Any contract     * - AztecAddress[]: Specific contracts     */    contracts: '*' | AztecAddress[];  }
```

#### GrantedDataCapability[​](#granteddatacapability)

**Type:** Interface

Granted data access capability. The wallet may reduce the scope (e.g., from '*' to specific contracts).

**Extends:** `DataCapability`

#### Capability[​](#capability)

**Type:** Type Alias

Union type of all capability scopes (app request). Capabilities group wallet operations by their security sensitivity and functional cohesion, making permission requests understandable to users.

**Signature:**

```
export type Capability = | AccountsCapability | ContractsCapability | ContractClassesCapability | SimulationCapability | TransactionCapability | DataCapability;
```

#### GrantedCapability[​](#grantedcapability)

**Type:** Type Alias

Union type of all granted capabilities (wallet response). The wallet may augment capabilities with additional information: - AccountsCapability: adds specific accounts granted - Other capabilities: may reduce scope (e.g., '*' to specific addresses)

**Signature:**

```
export type GrantedCapability = | GrantedAccountsCapability | GrantedContractsCapability | GrantedContractClassesCapability | GrantedSimulationCapability | GrantedTransactionCapability | GrantedDataCapability;
```

#### AppCapabilities[​](#appcapabilities)

**Type:** Interface

Application capability manifest. Sent by dApp to declare all operations it needs. This reduces authorization friction from multiple dialogs to a single comprehensive permission request.

#### Properties[​](#properties-15)

##### version[​](#version)

Manifest version for forward compatibility. Currently only '1.0' is supported.

**Type:** `typeof CAPABILITY_VERSION`

##### metadata[​](#metadata)

Application metadata for display in authorization dialogs.

**Type:**

```
{    /** Human-readable app name */    name: string;    /** App version */    version: string;    /** Optional description of what the app does */    description?: string;    /** Optional website URL */    url?: string;    /** Optional icon URL or data URI */    icon?: string;  }
```

##### capabilities[​](#capabilities)

Requested capabilities grouped by scope.

**Type:** `Capability[]`

#### WalletCapabilities[​](#walletcapabilities)

**Type:** Interface

Wallet capability response. Returned by wallet after user reviews and approves/denies the capability request. The wallet can modify requested capabilities: - Reduce scope (e.g., restrict to specific contracts instead of '*') - Add information (e.g., specify which accounts are granted) - Deny capabilities (by omitting them from the `granted` array)

#### Properties[​](#properties-16)

##### version[​](#version-1)

Response version for forward compatibility.

**Type:** `typeof CAPABILITY_VERSION`

##### granted[​](#granted)

Capabilities granted by the wallet. Capabilities not in this array were implicitly denied. Empty array means the user denied all capabilities.

**Type:** `GrantedCapability[]`

##### wallet[​](#wallet-1)

Wallet implementation details.

**Type:**

```
{    /** Wallet name/implementation */    name: string;    /** Wallet version */    version: string;  }
```

---

### `wallet/deploy_account_method.ts`[​](#walletdeploy_account_methodts)

#### DeployAccountFeePaymentMethodOption[​](#deployaccountfeepaymentmethodoption)

**Type:** Type Alias

Extended fee payment method option for account deployments that includes entrypoint wrapping options

**Signature:**

```
export type DeployAccountFeePaymentMethodOption = FeePaymentMethodOption & { feeEntrypointOptions?: unknown;};
```

**Type Members:**

##### feeEntrypointOptions[​](#feeentrypointoptions)

Optional entrypoint-specific options for wrapping execution payloads

**Type:** `unknown`

#### RequestDeployAccountOptions[​](#requestdeployaccountoptions)

**Type:** Type Alias

The configuration options for the request method.

**Signature:**

```
export type RequestDeployAccountOptions = Omit<RequestDeployOptions, 'fee'> & { fee?: DeployAccountFeePaymentMethodOption; from?: AztecAddress | NoFrom;};
```

**Type Members:**

##### fee[​](#fee-5)

Fee options specific to account deployment

**Type:** `DeployAccountFeePaymentMethodOption`

##### from[​](#from-1)

Sender of the request. When NO_FROM, the to-be-deployed account pays for its own deployment (self-paid deploy) and the payload is wrapped through the multicall entrypoint.

**Type:** `AztecAddress | NoFrom`

#### DeployAccountOptions[​](#deployaccountoptions)

**Type:** Type Alias

The configuration options for the send/prove methods.

**Signature:**

```
export type DeployAccountOptions<W extends InteractionWaitOptions = undefined> = DeployOptionsWithoutWait & { wait?: W;};
```

**Type Members:**

##### wait[​](#wait-2)

Whether to wait for the transaction to be mined. - undefined (default): wait with default options and return TxReceipt - WaitOpts object: wait with custom options and return TxReceipt - false: return txHash immediately without waiting

**Type:** `W`

#### SimulateDeployAccountOptions[​](#simulatedeployaccountoptions)

**Type:** Type Alias

The configuration options for the simulate method.

**Signature:**

```
export type SimulateDeployAccountOptions = SimulateDeployOptions;
```

#### DeployAccountMethod[​](#deployaccountmethod)

**Type:** Class

Modified version of the DeployMethod used to deploy account contracts. Supports deploying contracts that can pay for their own fee, plus some preconfigured options to avoid errors.

**Extends:** `UniversalDeployMethod`

#### Constructor[​](#constructor-22)

**Signature:**

```
constructor(  publicKeys: PublicKeys,  wallet: Wallet,  artifact: ContractArtifact,  postDeployCtor: (instance: ContractInstanceWithAddress, wallet: Wallet) => TContract,  salt: Fr,  immutablesHash: Fr,  private account: Account,  args: any[] = [],  constructorNameOrArtifact?: string | FunctionArtifact,  authWitnesses: AuthWitness[] = [],  capsules: Capsule[] = [],  extraHashedArgs: HashedValues[] = [])
```

**Parameters:**

- `publicKeys`: `PublicKeys`
- `wallet`: `Wallet`
- `artifact`: `ContractArtifact`
- `postDeployCtor`: `(instance: ContractInstanceWithAddress, wallet: Wallet) => TContract`
- `salt`: `Fr`
- `immutablesHash`: `Fr`
- `account`: `Account`
- `args` (optional): `any[]`
- `constructorNameOrArtifact` (optional): `string | FunctionArtifact`
- `authWitnesses` (optional): `AuthWitness[]`
- `capsules` (optional): `Capsule[]`
- `extraHashedArgs` (optional): `HashedValues[]`

#### Methods[​](#methods-27)

##### request[​](#request-4)

Returns the execution payload that allows this operation to happen on chain. For self-deployments (from === NO_FROM), the payload is wrapped through the multicall entrypoint on the app side so the wallet can execute it directly.

**Signature:**

```
public override async request(opts?: RequestDeployAccountOptions): Promise<ExecutionPayload>
```

**Parameters:**

- `opts` (optional): `RequestDeployAccountOptions`

  - Configuration options.

**Returns:**

`Promise<ExecutionPayload>` - The execution payload for this operation

##### convertDeployOptionsToSendOptions[​](#convertdeployoptionstosendoptions-1)

**Signature:**

```
protected override convertDeployOptionsToSendOptions<W extends InteractionWaitOptions>(options: DeployOptions<W>): SendOptions<W>
```

**Parameters:**

- `options`: `DeployOptions<W>`

**Returns:**

`SendOptions<W>`

##### convertDeployOptionsToSimulateOptions[​](#convertdeployoptionstosimulateoptions-1)

**Signature:**

```
protected override convertDeployOptionsToSimulateOptions(options: SimulateDeployOptions): SimulateOptions
```

**Parameters:**

- `options`: `SimulateDeployOptions`

**Returns:**

`SimulateOptions`

##### convertDeployOptionsToProfileOptions[​](#convertdeployoptionstoprofileoptions-1)

**Signature:**

```
protected override convertDeployOptionsToProfileOptions(options: DeployOptionsWithoutWait & ProfileInteractionOptions): ProfileOptions
```

**Parameters:**

- `options`: `DeployOptionsWithoutWait & ProfileInteractionOptions`

**Returns:**

`ProfileOptions`

##### with[​](#with-2)

Augments this DeployAccountMethod with additional metadata, such as authWitnesses and capsules.

**Signature:**

```
public override with({ authWitnesses = [], capsules = [], extraHashedArgs = [], }: {    authWitnesses?: AuthWitness[];    capsules?: Capsule[];    extraHashedArgs?: HashedValues[];}): DeployAccountMethod<TContract>
```

**Parameters:**

- `{ authWitnesses = [], capsules = [], extraHashedArgs = [], }`:

```
{    /** The authWitnesses to add to the deployment */    authWitnesses?: AuthWitness[];    /** The capsules to add to the deployment */    capsules?: Capsule[];    /** The extra hashed args to add to the deployment */    extraHashedArgs?: HashedValues[];  }
```

**Returns:**

`DeployAccountMethod<TContract>` - A new DeployAccountMethod with the added metadata

---

### `wallet/tx_simulation_result_with_app_offset.ts`[​](#wallettx_simulation_result_with_app_offsetts)

#### TxSimulationResultWithAppOffset[​](#txsimulationresultwithappoffset)

**Type:** Class

Extends TxSimulationResult with the app call offset, which tracks where the app's calls begin in the flattened array of calls. Tracking of app call offset is a wallet-level concern: the wallet may wrap the app payload in an entrypoint or may prepend calls (this is typically done for fee payments).

**Extends:** `TxSimulationResult`

#### Constructor[​](#constructor-23)

**Signature:**

```
constructor(  privateExecutionResult: PrivateExecutionResult,  publicInputs: PrivateKernelTailCircuitPublicInputs,  publicOutput?: PublicSimulationOutput,  stats?: SimulationStats,  public readonly appCallOffset: number | undefined = undefined)
```

**Parameters:**

- `privateExecutionResult`: `PrivateExecutionResult`
- `publicInputs`: `PrivateKernelTailCircuitPublicInputs`
- `publicOutput` (optional): `PublicSimulationOutput`
- `stats` (optional): `SimulationStats`
- `appCallOffset` (optional): `number | undefined`

  - Index of the app's first call in a flattened array of calls. 0 = app call is the root execution itself (DefaultEntrypoint / NO_FROM). 1..N = wallet prepended calls before the app call. undefined = wallet did not send the field; use heuristic fallback.

#### Methods[​](#methods-28)

##### getPrivateReturnValuesOfAppCall[​](#getprivatereturnvaluesofappcall)

Returns the private return values that correspond to the provided app call.

**Signature:**

```
getPrivateReturnValuesOfAppCall(appCallIndex: number = 0): NestedProcessReturnValues | undefined
```

**Parameters:**

- `appCallIndex` (optional): `number`

  - Index of the app call within the app calls.

**Returns:**

`NestedProcessReturnValues | undefined`

##### fromResultAndOffset[​](#fromresultandoffset)

Creates a TxSimulationResultWithAppOffset from an existing TxSimulationResult, attaching the app call offset computed by the wallet (i.e. how many calls precede the first app call in the flattened execution tree).

**Signature:**

```
static fromResultAndOffset(  result: TxSimulationResult,  appCallOffset: number): TxSimulationResultWithAppOffset
```

**Parameters:**

- `result`: `TxSimulationResult`

  - The simulation result to wrap.
- `appCallOffset`: `number`

  - The index of the app's first call in the flattened execution tree.

**Returns:**

`TxSimulationResultWithAppOffset`

##### random[​](#random)

**Signature:**

```
static override async random()
```

**Returns:**

`Promise<TxSimulationResultWithAppOffset>`

#### Getters[​](#getters-1)

##### schema (getter)[​](#schema-getter)

**Signature:**

```
static override get schema(): ZodFor<TxSimulationResultWithAppOffset> {
```

**Returns:**

`ZodFor<TxSimulationResultWithAppOffset>`

---

### `wallet/wallet.ts`[​](#walletwalletts)

#### Aliased[​](#aliased)

**Type:** Type Alias

A wrapper type that allows any item to be associated with an alias.

**Signature:**

```
export type Aliased<T> = { alias: string; item: T;};
```

**Type Members:**

##### alias[​](#alias)

The alias

**Type:** `string`

##### item[​](#item)

The item being aliased.

**Type:** `T`

#### SimulateOptions[​](#simulateoptions)

**Type:** Type Alias

Options for simulating interactions with the wallet. Overrides the fee settings of an interaction with a simplified version that only hints at the wallet whether the interaction contains a fee payment method or not

**Signature:**

```
export type SimulateOptions = Omit<SimulateInteractionOptions, 'fee'> & { fee?: GasSettingsOption;};
```

**Type Members:**

##### fee[​](#fee-6)

The fee options

**Type:** `GasSettingsOption`

#### ProfileOptions[​](#profileoptions)

**Type:** Type Alias

Options for profiling interactions with the wallet. Overrides the fee settings of an interaction with a simplified version that only hints at the wallet whether the interaction contains a fee payment method or not

**Signature:**

```
export type ProfileOptions = Omit<ProfileInteractionOptions, 'fee'> & { fee?: GasSettingsOption;};
```

**Type Members:**

##### fee[​](#fee-7)

The fee options

**Type:** `GasSettingsOption`

#### SendOptions[​](#sendoptions)

**Type:** Type Alias

Options for sending/proving interactions with the wallet. Overrides the fee settings of an interaction with a simplified version that only hints at the wallet whether the interaction contains a fee payment method or not

**Signature:**

```
export type SendOptions<W extends InteractionWaitOptions = undefined> = Omit< SendInteractionOptionsWithoutWait, 'fee'> & { fee?: GasSettingsOption; wait?: W;};
```

**Type Members:**

##### fee[​](#fee-8)

The fee options

**Type:** `GasSettingsOption`

##### wait[​](#wait-3)

Whether to wait for the transaction to be mined

**Type:** `W`

#### BatchableMethods[​](#batchablemethods)

**Type:** Type Alias

Helper type that represents all methods that can be batched (all methods except batch itself).

**Signature:**

```
export type BatchableMethods = Omit<Wallet, 'batch'>;
```

#### BatchedMethod[​](#batchedmethod)

**Type:** Type Alias

Union of all possible batched method calls. This ensures type safety: the `args` must match the specific `name`.

**Signature:**

```
export type BatchedMethod = { [K in keyof BatchableMethods]: BatchedMethodInternal<K>;}[keyof BatchableMethods];
```

#### BatchedMethodResult[​](#batchedmethodresult)

**Type:** Type Alias

Helper type to extract the return type of a batched method

**Signature:**

```
export type BatchedMethodResult<T> = T extends BatchedMethodInternal<infer K> ? Awaited<ReturnType<BatchableMethods[K]>> : never;
```

#### BatchedMethodResultWrapper[​](#batchedmethodresultwrapper)

**Type:** Type Alias

Wrapper type for batch results that includes the method name for discriminated union deserialization. Each result is wrapped as { name: 'methodName', result: ActualResult } to allow proper deserialization when AztecAddress and TxHash would otherwise be ambiguous (both are hex strings).

**Signature:**

```
export type BatchedMethodResultWrapper<T extends BatchedMethod> = { name: T['name']; result: BatchedMethodResult<T>;};
```

**Type Members:**

##### name[​](#name)

The method name

**Type:** `T['name']`

##### result[​](#result-1)

The method result

**Type:** `BatchedMethodResult<T>`

#### BatchResults[​](#batchresults)

**Type:** Type Alias

Maps a tuple of BatchedMethod to a tuple of their wrapped return types

**Signature:**

```
export type BatchResults<T extends readonly BatchedMethod[]> = { [K in keyof T]: BatchedMethodResultWrapper<T[K]>;};
```

**Type Members:**

##### [K in keyof T][​](#k-in-keyof-t)

**Signature:** `[K in keyof T]: BatchedMethodResultWrapper<T[K]>`

**Key Type:** `keyof T`

**Value Type:** `BatchedMethodResultWrapper<T[K]>`

#### EventFilterBase[​](#eventfilterbase)

**Type:** Type Alias

Base filter options for event queries.

**Signature:**

```
export type EventFilterBase = { txHash?: TxHash; fromBlock?: BlockNumber; toBlock?: BlockNumber;};
```

**Type Members:**

##### txHash[​](#txhash-1)

Transaction in which the events were emitted.

**Type:** `TxHash`

##### fromBlock[​](#fromblock)

The block number from which to start fetching events (inclusive). Optional. If provided, it must be greater or equal than 1. Defaults to the initial L2 block number (INITIAL_L2_BLOCK_NUM).

**Type:** `BlockNumber`

##### toBlock[​](#toblock)

The block number until which to fetch logs (not inclusive). Optional. If provided, it must be greater than fromBlock.

**Type:** `BlockNumber`

#### PrivateEventFilter[​](#privateeventfilter)

**Type:** Type Alias

Filter options when querying private events.

**Signature:**

```
export type PrivateEventFilter = EventFilterBase & { contractAddress: AztecAddress; scopes: AztecAddress[];};
```

**Type Members:**

##### contractAddress[​](#contractaddress-1)

The address of the contract that emitted the events.

**Type:** `AztecAddress`

##### scopes[​](#scopes)

Addresses of accounts that are in scope for this filter.

**Type:** `AztecAddress[]`

#### PublicEventFilter[​](#publiceventfilter)

**Type:** Type Alias

Filter options when querying public events. The contract address is required because the public log index is keyed on `(contract, tag)`; tag-only queries are not supported.

**Signature:**

```
export type PublicEventFilter = EventFilterBase & { contractAddress: AztecAddress; afterEvent?: EventCursor;};
```

**Type Members:**

##### contractAddress[​](#contractaddress-2)

The address of the contract that emitted the events. Required.

**Type:** `AztecAddress`

##### afterEvent[​](#afterevent)

Cursor to resume strictly after, for pagination. Pass GetPublicEventsResult.nextCursor from a previous page here to fetch the next one. Omit to start from the beginning of the range.

**Type:** `EventCursor`

#### Event[​](#event)

**Type:** Type Alias

An ABI decoded event with associated metadata.

**Signature:**

```
export type Event<T, M extends object = object> = { event: T; metadata: InTx & M;};
```

**Type Members:**

##### event[​](#event-1)

The ABI decoded event

**Type:** `T`

##### metadata[​](#metadata-1)

Metadata describing event context information such as tx and block

**Type:** `InTx & M`

#### PrivateEvent[​](#privateevent)

**Type:** Type Alias

An ABI decoded private event with associated metadata.

**Signature:**

```
export type PrivateEvent<T> = Event<T>;
```

#### PublicEvent[​](#publicevent)

**Type:** Type Alias

An ABI decoded public event with associated metadata (includes contract address).

**Signature:**

```
export type PublicEvent<T> = Event< T, { contractAddress: AztecAddress; }>;
```

#### ContractMetadata[​](#contractmetadata)

**Type:** Type Alias

Contract metadata including deployment and registration status.

**Signature:**

```
export type ContractMetadata = { instance?: ContractInstancePreimageWithAddress; initializationStatus: ContractInitializationStatus; isContractPublished: boolean; isContractUpdated: boolean; updatedContractClassId?: Fr | undefined;};
```

**Type Members:**

##### instance[​](#instance-1)

The contract instance preimage and address.

**Type:** `ContractInstancePreimageWithAddress`

##### initializationStatus[​](#initializationstatus)

Whether the contract has been initialized.

**Type:** `ContractInitializationStatus`

##### isContractPublished[​](#iscontractpublished)

Whether the contract instance is publicly deployed onchain

**Type:** `boolean`

##### isContractUpdated[​](#iscontractupdated)

Whether the contract has been updated to a different class

**Type:** `boolean`

##### updatedContractClassId[​](#updatedcontractclassid)

The updated contract class ID if the contract has been updated

**Type:** `Fr | undefined`

#### ContractClassMetadata[​](#contractclassmetadata)

**Type:** Type Alias

Contract class metadata.

**Signature:**

```
export type ContractClassMetadata = { isArtifactRegistered: boolean; isContractClassPubliclyRegistered: boolean;};
```

**Type Members:**

##### isArtifactRegistered[​](#isartifactregistered)

Whether the artifact is registered in the wallet

**Type:** `boolean`

##### isContractClassPubliclyRegistered[​](#iscontractclasspubliclyregistered)

Whether the contract class is publicly registered onchain

**Type:** `boolean`

#### ExecuteUtilityOptions[​](#executeutilityoptions)

**Type:** Type Alias

Options for executing a utility function call.

**Signature:**

```
export type ExecuteUtilityOptions = { scopes: AztecAddress[]; authWitnesses?: AuthWitness[];};
```

**Type Members:**

##### scopes[​](#scopes-1)

The scopes for the utility execution (determines which notes and keys are visible).

**Type:** `AztecAddress[]`

##### authWitnesses[​](#authwitnesses-2)

Optional auth witnesses to use during execution.

**Type:** `AuthWitness[]`

#### Wallet[​](#wallet-2)

**Type:** Type Alias

The wallet interface.

**Signature:**

```
export type Wallet = { getPrivateEvents<T>( eventMetadata: EventMetadataDefinition, eventFilter: PrivateEventFilter, ): Promise<PrivateEvent<T>[]>; getChainInfo(): Promise<ChainInfo>; getContractMetadata(address: AztecAddress): Promise<ContractMetadata>; getContractClassMetadata(id: Fr): Promise<ContractClassMetadata>; registerSender(address: AztecAddress, alias?: string): Promise<AztecAddress>; getAddressBook(): Promise<Aliased<AztecAddress>[]>; getAccounts(): Promise<Aliased<AztecAddress>[]>; registerContract( instance: ContractInstancePreimage, artifact?: ContractArtifact, secretKeyOrKeys?: Fr | MasterSecretKeys, ): Promise<void>; registerContractClass(artifact: ContractArtifact): Promise<void>; simulateTx(exec: ExecutionPayload, opts: SimulateOptions): Promise<TxSimulationResultWithAppOffset>; executeUtility(call: FunctionCall, opts: ExecuteUtilityOptions): Promise<UtilityExecutionResult>; profileTx(exec: ExecutionPayload, opts: ProfileOptions): Promise<TxProfileResult>; sendTx<W extends InteractionWaitOptions = undefined>( exec: ExecutionPayload, opts: SendOptions<W>, ): Promise<SendReturn<W>>; createAuthWit(from: AztecAddress, messageHashOrIntent: IntentInnerHash | CallIntent): Promise<AuthWitness>; requestCapabilities(manifest: AppCapabilities): Promise<WalletCapabilities>; batch<const T extends readonly BatchedMethod[]>(methods: T): Promise<BatchResults<T>>;};
```

**Type Members:**

##### getPrivateEvents[​](#getprivateevents)

**Signature:**

```
getPrivateEvents<T>(  eventMetadata: EventMetadataDefinition,  eventFilter: PrivateEventFilter): Promise<PrivateEvent<T>[]>
```

**Parameters:**

- `eventMetadata`: `EventMetadataDefinition`
- `eventFilter`: `PrivateEventFilter`

**Returns:**

`Promise<PrivateEvent<T>[]>`

##### getChainInfo[​](#getchaininfo)

**Signature:**

```
getChainInfo(): Promise<ChainInfo>
```

**Returns:**

`Promise<ChainInfo>`

##### getContractMetadata[​](#getcontractmetadata)

**Signature:**

```
getContractMetadata(address: AztecAddress): Promise<ContractMetadata>
```

**Parameters:**

- `address`: `AztecAddress`

**Returns:**

`Promise<ContractMetadata>`

##### getContractClassMetadata[​](#getcontractclassmetadata)

**Signature:**

```
getContractClassMetadata(id: Fr): Promise<ContractClassMetadata>
```

**Parameters:**

- `id`: `Fr`

**Returns:**

`Promise<ContractClassMetadata>`

##### registerSender[​](#registersender)

**Signature:**

```
registerSender(  address: AztecAddress,  alias?: string): Promise<AztecAddress>
```

**Parameters:**

- `address`: `AztecAddress`
- `alias` (optional): `string`

**Returns:**

`Promise<AztecAddress>`

##### getAddressBook[​](#getaddressbook)

**Signature:**

```
getAddressBook(): Promise<Aliased<AztecAddress>[]>
```

**Returns:**

`Promise<Aliased<AztecAddress>[]>`

##### getAccounts[​](#getaccounts)

**Signature:**

```
getAccounts(): Promise<Aliased<AztecAddress>[]>
```

**Returns:**

`Promise<Aliased<AztecAddress>[]>`

##### registerContract[​](#registercontract)

**Signature:**

```
registerContract(  instance: ContractInstancePreimage,  artifact?: ContractArtifact,  secretKeyOrKeys?: Fr | MasterSecretKeys): Promise<void>
```

**Parameters:**

- `instance`: `ContractInstancePreimage`
- `artifact` (optional): `ContractArtifact`
- `secretKeyOrKeys` (optional): `Fr | MasterSecretKeys`

**Returns:**

`Promise<void>`

##### registerContractClass[​](#registercontractclass)

Registers a contract class artifact in the local PXE without binding it to any instance. Useful for simulation flows that need the artifact available locally before any onchain upgrade has taken effect. No chain check.

**Signature:**

```
registerContractClass(artifact: ContractArtifact): Promise<void>
```

**Parameters:**

- `artifact`: `ContractArtifact`

**Returns:**

`Promise<void>`

##### simulateTx[​](#simulatetx)

**Signature:**

```
simulateTx(  exec: ExecutionPayload,  opts: SimulateOptions): Promise<TxSimulationResultWithAppOffset>
```

**Parameters:**

- `exec`: `ExecutionPayload`
- `opts`: `SimulateOptions`

**Returns:**

`Promise<TxSimulationResultWithAppOffset>`

##### executeUtility[​](#executeutility)

**Signature:**

```
executeUtility(  call: FunctionCall,  opts: ExecuteUtilityOptions): Promise<UtilityExecutionResult>
```

**Parameters:**

- `call`: `FunctionCall`
- `opts`: `ExecuteUtilityOptions`

**Returns:**

`Promise<UtilityExecutionResult>`

##### profileTx[​](#profiletx)

**Signature:**

```
profileTx(  exec: ExecutionPayload,  opts: ProfileOptions): Promise<TxProfileResult>
```

**Parameters:**

- `exec`: `ExecutionPayload`
- `opts`: `ProfileOptions`

**Returns:**

`Promise<TxProfileResult>`

##### sendTx[​](#sendtx)

**Signature:**

```
sendTx<W extends InteractionWaitOptions = undefined>(  exec: ExecutionPayload,  opts: SendOptions<W>): Promise<SendReturn<W>>
```

**Parameters:**

- `exec`: `ExecutionPayload`
- `opts`: `SendOptions<W>`

**Returns:**

`Promise<SendReturn<W>>`

##### createAuthWit[​](#createauthwit-2)

**Signature:**

```
createAuthWit(  from: AztecAddress,  messageHashOrIntent: IntentInnerHash | CallIntent): Promise<AuthWitness>
```

**Parameters:**

- `from`: `AztecAddress`
- `messageHashOrIntent`: `IntentInnerHash | CallIntent`

**Returns:**

`Promise<AuthWitness>`

##### requestCapabilities[​](#requestcapabilities)

**Signature:**

```
requestCapabilities(manifest: AppCapabilities): Promise<WalletCapabilities>
```

**Parameters:**

- `manifest`: `AppCapabilities`

**Returns:**

`Promise<WalletCapabilities>`

##### batch[​](#batch)

**Signature:**

```
batch<const T extends readonly BatchedMethod[]>(methods: T): Promise<BatchResults<T>>
```

**Parameters:**

- `methods`: `T`

**Returns:**

`Promise<BatchResults<T>>`

#### ExecutionPayloadSchema[​](#executionpayloadschema)

**Type:** Constant

**Value Type:** `any`

#### GasSettingsOptionSchema[​](#gassettingsoptionschema)

**Type:** Constant

**Value Type:** `any`

#### WaitOptsSchema[​](#waitoptsschema)

**Type:** Constant

**Value Type:** `any`

#### SendOptionsSchema[​](#sendoptionsschema)

**Type:** Constant

**Value Type:** `any`

#### SimulateOptionsSchema[​](#simulateoptionsschema)

**Type:** Constant

**Value Type:** `any`

#### ProfileOptionsSchema[​](#profileoptionsschema)

**Type:** Constant

**Value Type:** `any`

#### MessageHashOrIntentSchema[​](#messagehashorintentschema)

**Type:** Constant

**Value Type:** `any`

#### EventMetadataDefinitionSchema[​](#eventmetadatadefinitionschema)

**Type:** Constant

**Value Type:** `any`

#### PrivateEventFilterSchema[​](#privateeventfilterschema)

**Type:** Constant

**Value Type:** `any`

#### PublicEventFilterSchema[​](#publiceventfilterschema)

**Type:** Constant

**Value Type:** `any`

#### PrivateEventSchema[​](#privateeventschema)

**Type:** Constant

**Value Type:** `z.ZodType<any>`

#### PublicEventSchema[​](#publiceventschema)

**Type:** Constant

**Value Type:** `z.ZodType<PublicEvent<AbiDecoded>>`

#### ContractMetadataSchema[​](#contractmetadataschema)

**Type:** Constant

**Value Type:** `any`

#### ContractClassMetadataSchema[​](#contractclassmetadataschema)

**Type:** Constant

**Value Type:** `any`

#### ContractFunctionPatternSchema[​](#contractfunctionpatternschema)

**Type:** Constant

**Value Type:** `any`

#### AccountsCapabilitySchema[​](#accountscapabilityschema)

**Type:** Constant

**Value Type:** `any`

#### GrantedAccountsCapabilitySchema[​](#grantedaccountscapabilityschema)

**Type:** Constant

**Value Type:** `any`

#### ContractsCapabilitySchema[​](#contractscapabilityschema)

**Type:** Constant

**Value Type:** `any`

#### GrantedContractsCapabilitySchema[​](#grantedcontractscapabilityschema)

**Type:** Constant

**Value Type:** `any`

#### ContractClassesCapabilitySchema[​](#contractclassescapabilityschema)

**Type:** Constant

**Value Type:** `any`

#### GrantedContractClassesCapabilitySchema[​](#grantedcontractclassescapabilityschema)

**Type:** Constant

**Value Type:** `any`

#### SimulationCapabilitySchema[​](#simulationcapabilityschema)

**Type:** Constant

**Value Type:** `any`

#### GrantedSimulationCapabilitySchema[​](#grantedsimulationcapabilityschema)

**Type:** Constant

**Value Type:** `any`

#### TransactionCapabilitySchema[​](#transactioncapabilityschema)

**Type:** Constant

**Value Type:** `any`

#### GrantedTransactionCapabilitySchema[​](#grantedtransactioncapabilityschema)

**Type:** Constant

**Value Type:** `any`

#### DataCapabilitySchema[​](#datacapabilityschema)

**Type:** Constant

**Value Type:** `any`

#### GrantedDataCapabilitySchema[​](#granteddatacapabilityschema)

**Type:** Constant

**Value Type:** `any`

#### CapabilitySchema[​](#capabilityschema)

**Type:** Constant

**Value Type:** `any`

#### GrantedCapabilitySchema[​](#grantedcapabilityschema)

**Type:** Constant

**Value Type:** `any`

#### AppCapabilitiesSchema[​](#appcapabilitiesschema)

**Type:** Constant

**Value Type:** `any`

#### WalletCapabilitiesSchema[​](#walletcapabilitiesschema)

**Type:** Constant

**Value Type:** `any`

#### BatchedMethodSchema[​](#batchedmethodschema)

**Type:** Constant

#### BatchedResultSchema[​](#batchedresultschema)

**Type:** Constant

#### WalletSchema[​](#walletschema)

**Type:** Constant

**Value Type:** `ApiSchemaFor<Wallet>`

**Tags:**
- [api](https://docs.aztec.network/developers/tags/api)
- [reference](https://docs.aztec.network/developers/tags/reference)
- [autogenerated](https://docs.aztec.network/developers/tags/autogenerated)
- [aztec.js](https://docs.aztec.network/developers/tags/aztec-js)
- [typescript](https://docs.aztec.network/developers/tags/typescript)

[Edit this page](https://github.com/AztecProtocol/aztec-packages/edit/next/docs/docs-developers/docs/aztec-js/aztec_js_reference.md)