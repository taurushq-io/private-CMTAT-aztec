# Global Variables

> Source: https://docs.aztec.network/developers/docs/aztec-nr/framework-description/globals

---

- [![Home](https://docs.aztec.network/img/Aztec_Symbol_Dark.png)![Home](https://docs.aztec.network/img/Aztec%20Symbol_Light.png)](https://docs.aztec.network/)
- [Aztec.nr](https://docs.aztec.network/developers/docs/aztec-nr)
- Framework Description
- Global Variables

On this page
# Global Variables

Similar to Solidity's global `block` variable, Aztec exposes contextual values within each function via the `context` object.

Aztec has two execution environments—Private and Public—each with different available globals.

## Private Global Variables[​](#private-global-variables)

Private functions access transaction context via `TxContext`:

tx-context
```
#[derive(Deserialize, Eq, Serialize)]pub struct TxContext {    // The chain ID on which this transaction is executed.    pub chain_id: Field,    // The version of the L1 Rollup contract.    pub version: Field,    // The gas settings for the transaction.    pub gas_settings: GasSettings,}
```

> [Source code: noir-projects/noir-protocol-circuits/crates/types/src/abis/transaction/tx_context.nr#L8-L18](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/noir-projects/noir-protocol-circuits/crates/types/src/abis/transaction/tx_context.nr#L8-L18)

The following fields are accessible via `context` methods:

### Chain Id[​](#chain-id)

The unique identifier for the Aztec network instance (not the Ethereum chain the rollup settles to).

```
self.context.chain_id();
```

### Version[​](#version)

The Aztec protocol version number. The genesis block has version 1.

```
self.context.version();
```

### Gas Settings[​](#gas-settings)

The gas limits, max fees per gas, and inclusion fee set by the user for the transaction.

```
self.context.gas_settings();
```

## Public Global Variables[​](#public-global-variables)

Public functions access block-level context via `GlobalVariables`:

global-variables
```
#[derive(Deserialize, Eq, Serialize)]pub struct GlobalVariables {    pub chain_id: Field,    pub version: Field,    pub block_number: u32,    pub slot_number: Field,    pub timestamp: u64,    // Remember to call `EthAddress::validate()` to ensure an EthAddress fits within 20 bytes.    pub coinbase: EthAddress,    pub fee_recipient: AztecAddress,    pub gas_fees: GasFees,}
```

> [Source code: noir-projects/noir-protocol-circuits/crates/types/src/abis/global_variables.nr#L7-L20](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/noir-projects/noir-protocol-circuits/crates/types/src/abis/global_variables.nr#L7-L20)

noteNot all fields in `GlobalVariables` are exposed via context methods. The `coinbase`, `fee_recipient`, and `slot_number` fields are used internally by the protocol.

Public functions have access to `chain_id()` and `version()` (same syntax as private), plus the following block-level values:

### Timestamp[​](#timestamp)

The unix timestamp when the block is executed. Provided by the block proposer, so it may have slight variance. Always increases monotonically.

```
self.context.timestamp();
```

### Block Number[​](#block-number)

The sequential block identifier. Genesis block is 1, incrementing by 1 for each subsequent block.

```
self.context.block_number();
```

### Gas Fees[​](#gas-fees)

The current L2 and DA gas prices for the block. You can access gas-related information via:

```
self.context.l2_gas_left();       // Remaining L2 gasself.context.da_gas_left();       // Remaining DA gasself.context.min_fee_per_l2_gas(); // L2 gas priceself.context.min_fee_per_da_gas(); // DA gas priceself.context.transaction_fee();   // Final tx fee (only available in teardown phase)
```

Why do available globals differ between environments?Private functions execute on the user's device before the transaction is submitted, so they cannot know which block will include the transaction. Therefore, `timestamp` and `block_number` are unavailable in private context.

Public functions execute on a sequencer who knows the current block's timestamp and number, making these values accessible.

[Edit this page](https://github.com/AztecProtocol/aztec-packages/edit/next/docs/docs-developers/docs/aztec-nr/framework-description/globals.md)