# How to Define Functions

> Source: https://docs.aztec.network/developers/docs/aztec-nr/framework-description/functions/how_to_define_functions

---

- [![Home](https://docs.aztec.network/img/Aztec_Symbol_Dark.png)![Home](https://docs.aztec.network/img/Aztec%20Symbol_Light.png)](https://docs.aztec.network/)
- [Aztec.nr](https://docs.aztec.network/developers/docs/aztec-nr)
- Framework Description
- [Defining Functions](https://docs.aztec.network/developers/docs/aztec-nr/framework-description/functions)
- How to Define Functions

On this page
# How to Define Functions

## Overview[​](#overview)

This guide shows you how to define different types of functions in your Aztec contracts, each serving specific purposes and execution environments.

## Quick reference[​](#quick-reference)

| Annotation | Execution | State access |
| --- | --- | --- |
| `#[external("private")]` | User device | Private state (and selected public values via storage types) |
| `#[external("public")]` | Sequencer | Public state |
| `#[external("utility")]` | Offchain client | Public + private (unconstrained) |
| `#[internal("private")]` | N/A | Inlined private helper (non-entrypoint) |
| `#[internal("public")]` | N/A | Inlined public helper (non-entrypoint) |
| `#[view]` | Private or public | Read-only (no state mutation) |
| `#[only_self]` | Private or public | Callable only by the same contract |
| `#[initializer]` | Private or public | One-time initialization |

## Prerequisites[​](#prerequisites)

- An Aztec contract project set up with the `aztec-nr` dependency
- Basic understanding of [Noir programming language](https://noir-lang.org/docs)
- Familiarity with Aztec Protocol's [call types](https://docs.aztec.network/developers/docs/foundational-topics/call_types) (private vs public)

## Define private functions[​](#define-private-functions)

Use `#[external("private")]` to create functions that execute privately on user devices. For example:

increment
```
#[external("private")]fn increment(owner: AztecAddress) {    debug_log_format("Incrementing counter for owner {0}", [owner.to_field()]);    self.storage.counters.at(owner).add(1).deliver(MessageDelivery::onchain_constrained());}
```

> [Source code: docs/examples/contracts/counter_contract/src/main.nr#L36-L42](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/contracts/counter_contract/src/main.nr#L36-L42)

Private functions run in a private context, can access private state, and can read certain public values through storage types like [`DelayedPublicMutable`](https://docs.aztec.network/developers/docs/aztec-nr/framework-description/state_variables#delayedpublicmutable).

## Define public functions[​](#define-public-functions)

Use `#[external("public")]` to create functions that execute on the sequencer:

mint_public
```
#[external("public")]fn mint_public(employee: AztecAddress, amount: u64) {    // Only Giggle can mint tokens    assert_eq(self.msg_sender(), self.storage.owner.read(), "Only Giggle can mint BOB tokens");    // Add tokens to employee's public balance    let current_balance = self.storage.public_balances.at(employee).read();    self.storage.public_balances.at(employee).write(current_balance + amount);}
```

> [Source code: docs/examples/contracts/bob_token_contract/src/main.nr#L41-L51](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/contracts/bob_token_contract/src/main.nr#L41-L51)

Public functions operate on public state, similar to EVM contracts. They can write to private storage, but any data written from a public function is publicly visible.

## Define utility functions[​](#define-utility-functions)

Create offchain query functions using the `#[external("utility")]` annotation with `unconstrained`.

Utility functions are unconstrained functions that applications call to perform auxiliary tasks, like querying contract state or processing offchain messages. Their execution is never proven, so no guarantees are made on the correctness of their results. They can also be called from other utility functions and from private functions. See [utility calls](https://docs.aztec.network/developers/docs/aztec-nr/framework-description/calling_contracts#utility-calls). Public functions cannot call them. Example:

get_counter
```
#[external("utility")]unconstrained fn get_counter(owner: AztecAddress) -> pub u128 {    self.storage.counters.at(owner).balance_of()}
```

> [Source code: docs/examples/contracts/counter_contract/src/main.nr#L44-L49](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/contracts/counter_contract/src/main.nr#L44-L49)

Use `aztec.js` `simulate` to execute utility functions and read their return values. For details, see [Call Types](https://docs.aztec.network/developers/docs/foundational-topics/call_types#simulate).

## Define view functions[​](#define-view-functions)

Create read-only functions using the `#[view]` annotation combined with `#[external("private")]` or `#[external("public")]`:

```
#[external("public")]#[view]fn get_config_value() -> Field {    // logic}
```

View functions cannot modify contract state. They're akin to Ethereum's `view` functions.
`#[view]` only applies to `#[external("private")]` and `#[external("public")]` functions.

## Define only-self functions[​](#define-only-self-functions)

Create contract-only functions using the `#[only_self]` annotation:

_assert_is_owner
```
#[external("public")]#[only_self]fn _assert_is_owner(address: AztecAddress) {    assert_eq(address, self.storage.owner.read(), "Only Giggle can mint BOB tokens");}
```

> [Source code: docs/examples/contracts/bob_token_contract/src/main.nr#L131-L137](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/contracts/bob_token_contract/src/main.nr#L131-L137)

Only-self functions are only callable by the same contract, which is useful when a private function enqueues a public call that should only be callable internally.

## Define initializer functions[​](#define-initializer-functions)

Create constructor-like functions using the `#[initializer]` annotation:

constructor
```
#[initializer]#[external("private")]// We can name our initializer anything we want as long as it's marked as #[initializer]fn constructor(initial_value: u128, owner: AztecAddress) {    self.storage.counters.at(owner).add(initial_value).deliver(        MessageDelivery::onchain_constrained(),    );}
```

> [Source code: docs/examples/contracts/counter_contract/src/main.nr#L25-L34](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/contracts/counter_contract/src/main.nr#L25-L34)

### Use multiple initializers[​](#use-multiple-initializers)

Define multiple initialization options:

1. Mark each function with `#[initializer]`
2. Choose which one to call during deployment
3. Any initializer marks the contract as initialized

## Define internal functions[​](#define-internal-functions)

Create helper functions using `#[internal("private")]` or `#[internal("public")]`. Internal functions are inlined at call sites and do not create separate entrypoints:

```
#[internal("private")]fn _prepare_transfer(to: AztecAddress, amount: u128) -> Field {    // helper logic for private functions}#[internal("public")]fn _update_balance(owner: AztecAddress, amount: u128) {    // helper logic for public functions}
```

Call internal functions via `self.internal`:

```
let result = self.internal._prepare_transfer(recipient, amount);
```

Key constraints:

- Private internal functions can only be called from private external or internal functions
- Public internal functions can only be called from public external or internal functions

## Next steps[​](#next-steps)

- [Attributes and Macros](https://docs.aztec.network/developers/docs/aztec-nr/framework-description/functions/attributes)
- [Call Types](https://docs.aztec.network/developers/docs/foundational-topics/call_types)

**Tags:**
- [functions](https://docs.aztec.network/developers/tags/functions)
- [smart-contracts](https://docs.aztec.network/developers/tags/smart-contracts)

[Edit this page](https://github.com/AztecProtocol/aztec-packages/edit/next/docs/docs-developers/docs/aztec-nr/framework-description/functions/how_to_define_functions.md)