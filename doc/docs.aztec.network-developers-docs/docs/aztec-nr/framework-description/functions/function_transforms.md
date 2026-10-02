# Inner Workings of Functions

> Source: https://docs.aztec.network/developers/docs/aztec-nr/framework-description/functions/function_transforms

---

- [![Home](https://docs.aztec.network/img/Aztec_Symbol_Dark.png)![Home](https://docs.aztec.network/img/Aztec%20Symbol_Light.png)](https://docs.aztec.network/)
- [Aztec.nr](https://docs.aztec.network/developers/docs/aztec-nr)
- Framework Description
- [Defining Functions](https://docs.aztec.network/developers/docs/aztec-nr/framework-description/functions)
- Inner Workings of Functions

On this page
# Inner Workings of Functions

This page explains what happens under the hood when you create a function in an Aztec contract. The [next page](https://docs.aztec.network/developers/docs/aztec-nr/framework-description/functions/attributes) covers what the function attributes do.

## Overview[​](#overview)

Private functions in Aztec compile to standalone circuits that must conform to the protocol's kernel circuit interface. Public functions compile to AVM bytecode. The transformations described below bridge the gap between developer-friendly Aztec.nr syntax and these underlying requirements.

Utility functions (marked with `#[external("utility")]`) do not undergo these transformations—they remain as regular Noir functions.

## Function transformation[​](#function-transformation)

When you define a private or public function in an Aztec contract, it undergoes several transformations during compilation:

- [Creating a context for the function](#context-creation)
- [Handling function inputs](#private-and-public-input-injection)
- [Processing return values](#return-value-handling)

## Context creation[​](#context-creation)

Every function in an Aztec contract operates within a specific context that provides execution information and functionality. This is either a `PrivateContext` or `PublicContext` object, depending on whether it is a private or public function.

### Private functions[​](#private-functions)

For private functions, context creation involves serializing and hashing all input parameters:

```
// Parameters are serialized into an arraylet serialized_args: [Field; N] = /* serialized parameters */;// Hash the arguments using poseidon2let args_hash = aztec::hash::hash_args(serialized_args);// Create the context with the inputs and args hashlet mut context = PrivateContext::new(inputs, args_hash);
```

This hashing is important because the kernel circuit uses it to verify the function received the correct parameters without exposing the input data.

### Public functions[​](#public-functions)

For public functions, context creation uses a lazy evaluation pattern:

```
let mut context = PublicContext::new(|| {    // compute args hash when needed    hash_args(serialized_args)});
```

### Using the context[​](#using-the-context)

The context object provides methods for interacting with the blockchain. Storage access and contract calls are handled through a `ContractSelf` wrapper that the macros generate automatically.

## Private and public input injection[​](#private-and-public-input-injection)

An additional parameter is automatically added to every private function.

The injected input is always the first parameter of the transformed function and is of type `PrivateContextInputs` for private functions.

Original function definition:

```
fn my_function(param1: Type1, param2: Type2) { ... }
```

Transformed function with injected input:

```
fn my_function(inputs: PrivateContextInputs, param1: Type1, param2: Type2) { ... }
```

The `PrivateContextInputs` struct contains:

- `call_context` - information about how the function was called (msg_sender, contract_address, function_selector, is_static_call)
- `anchor_block_header` - the historical block header used during private execution
- `tx_context` - transaction-level data (chain_id, version, gas_settings)
- `start_side_effect_counter` - the side effect counter at function entry

These inputs are made available through the `PrivateContext` object within your function.

Public functions run in the AVM and access their context data through AVM opcodes rather than injected inputs.

## Return value handling[​](#return-value-handling)

Return values in Aztec contracts are processed differently from traditional smart contracts.

### Private functions[​](#private-functions-1)

For private functions, the return value is serialized, hashed, and stored in the context:

```
// The original return value is capturedlet macro__returned__values = original_return_expression;// The return value is serialized and hashedlet serialized_return: [Field; N] = /* serialized return value */;self.context.set_return_hash(serialized_return);
```

The function's return type is changed to `PrivateCircuitPublicInputs`, which is returned by calling `context.finish()` at the end of the function.

This process allows the return values to be included in the function's computation result while maintaining privacy. The actual return values are stored in the execution cache and can be retrieved by the caller using the hash.

### Public functions[​](#public-functions-1)

In public functions, the return value is handled directly by the AVM and the function's return type remains as specified by the developer.

## Function signature generation[​](#function-signature-generation)

Each contract function has a unique 4-byte function selector. The selector is computed by hashing the function's signature string using Poseidon2:

```
impl FunctionSelector {    pub fn from_signature<let N: u32>(signature: str<N>) -> Self {        let bytes = signature.as_bytes();        let hash = poseidon2_hash_bytes(bytes);        // hash is truncated to fit within 32 bits (4 bytes)        FunctionSelector::from_field(hash)    }}
```

The signature string follows the format `function_name(param_types)`. For example, `transfer(Field,Field)`.

This approach is inspired by Solidity's function selector mechanism, but uses Poseidon2 instead of Keccak-256 for compatibility with Aztec's circuit-friendly hash functions.

## Contract artifacts[​](#contract-artifacts)

Contract artifacts are automatically generated structures that describe the contract's interface. They preserve the original function signatures (parameters and return types) before macro transformations are applied.

For each function in the contract, an ABI export is generated with:

1. A parameters struct containing all function parameters
2. An ABI struct marked with `#[abi(functions)]` containing the parameters and return type

For example, given a function:

```
fn increment(owner: AztecAddress) -> Field { ... }
```

The following structs are generated:

```
pub struct increment_parameters {    pub owner: AztecAddress}#[abi(functions)]pub struct increment_abi {    parameters: increment_parameters,    return_type: Field}
```

The `#[abi(functions)]` attribute marks the struct for inclusion in the contract ABI's `outputs.functions` array. This is important because macro processing changes the actual return type of private functions to `PrivateCircuitPublicInputs`, but the toolchain needs access to the original signatures.

Contract artifacts enable:

- Machine-readable contract interface descriptions
- TypeScript binding generation (see [how to compile contracts](https://docs.aztec.network/developers/docs/aztec-nr/compiling_contracts))
- Function return value decoding in the simulator

## Further reading[​](#further-reading)

- [Function attributes and macros](https://docs.aztec.network/developers/docs/aztec-nr/framework-description/functions/attributes)
- [Aztec.nr macro source code](https://github.com/AztecProtocol/aztec-packages/tree/v5.2.0/noir-projects/aztec-nr/aztec/src/macros) - for those who want to see the actual transformation implementation

**Tags:**
- [functions](https://docs.aztec.network/developers/tags/functions)

[Edit this page](https://github.com/AztecProtocol/aztec-packages/edit/next/docs/docs-developers/docs/aztec-nr/framework-description/functions/function_transforms.md)