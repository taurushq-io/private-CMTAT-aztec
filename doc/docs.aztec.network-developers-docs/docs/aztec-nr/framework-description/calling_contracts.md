# Calling Other Contracts

> Source: https://docs.aztec.network/developers/docs/aztec-nr/framework-description/calling_contracts

---

- [![Home](https://docs.aztec.network/img/Aztec_Symbol_Dark.png)![Home](https://docs.aztec.network/img/Aztec%20Symbol_Light.png)](https://docs.aztec.network/)
- [Aztec.nr](https://docs.aztec.network/developers/docs/aztec-nr)
- Framework Description
- Calling Other Contracts

On this page
# Calling Other Contracts

This guide shows you how to call functions in other contracts from your Aztec smart contracts.

## Add the target contract as a dependency[​](#add-the-target-contract-as-a-dependency)

Add the contract you want to call to your `Nargo.toml` dependencies:

```
[dependencies]token = { git="https://github.com/AztecProtocol/aztec-packages/", tag="v5.2.0", directory="noir-projects/noir-contracts/contracts/app/token_contract" }
```

Then import the contract interface at the top of your contract file:

```
use token::Token;
```

## Call contract functions[​](#call-contract-functions)

Use `self.call()` to call functions on other contracts:

```
self.call(Token::at(token_address).transfer(recipient, amount));
```

The pattern is:

1. Form the call: `Contract::at(address).function_name(args)`
2. Execute it: `self.call(...)` or `self.view(...)` for read-only calls

### Private-to-private calls[​](#private-to-private-calls)

private_call
```
let _ = self.call(Token::at(stable_coin).burn_private(from, amount, authwit_nonce));
```

> [Source code: noir-projects/noir-contracts/contracts/app/lending_contract/src/main.nr#L218-L220](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/noir-projects/noir-contracts/contracts/app/lending_contract/src/main.nr#L218-L220)

### Public-to-public calls[​](#public-to-public-calls)

From a public function, call other public functions directly:

```
self.call(Token::at(token_address).transfer_in_public(recipient, amount));
```

Capture return values by assigning the result:

```
let balance = self.view(Token::at(token_address).balance_of_public(account));
```

Use `self.view()` for read-only calls that cannot modify state.

### Private-to-public calls[​](#private-to-public-calls)

From a private function, enqueue public function calls for later execution:

```
self.enqueue(Token::at(token_address).mint_to_public(recipient, amount));
```

infoPublic functions execute after all private execution completes. Return values are not available in the private context. Learn more about [call types](https://docs.aztec.network/developers/docs/foundational-topics/call_types).

## Utility calls[​](#utility-calls)

Utility functions can call other utility functions. These calls run entirely offchain in PXE and are never proven, so no guarantees are made on the correctness of their results.

### Utility-to-utility calls[​](#utility-to-utility-calls)

From a utility function, use `self.call()` as with other call types:

```
let balance = self.call(Token::at(token_address).get_balance_of(owner));
```

To call a utility function of your own contract, use the `self.call_self` stubs instead:

```
self.call_self.my_utility_function(args)
```

### Private-to-utility calls[​](#private-to-utility-calls)

Private functions can also call utility functions, through `self.utility`. The call executes unconstrained code, so it must be wrapped in `unsafe`, and its result is not proven: use it to inform logic, never as an input to a constrained assertion without validating it first.

```
// Safety: result is unconstrainedlet balance = unsafe { self.utility.call(Token::at(token_address).get_balance_of(owner)) };
```

The same-contract stubs are available here as `self.utility.call_self`:

```
unsafe { self.utility.call_self.my_utility_function(args) }
```

Public functions cannot call utility functions: they run on the sequencer, which has no access to private state or PXE.

### Cross-contract authorization[​](#cross-contract-authorization)

A utility call to the calling contract itself always succeeds. A call to a *different* contract can expose that contract's private state to the caller, so PXE asks the wallet to authorize it before proceeding. If the wallet denies the call, or no `authorizeUtilityCall` hook is configured, the simulation fails with `Cross-contract utility call denied`. See [execution hooks](https://docs.aztec.network/developers/docs/foundational-topics/pxe/execution_hooks#authorizeutilitycall) for how wallets handle these requests, and for authorizing targets in Noir tests with `with_authorized_utility_call_targets`.

### `msg_sender` in nested utility calls[​](#msg_sender-in-nested-utility-calls)

A utility function called from another contract can read the calling contract's address via `self.msg_sender()`, mirroring private and public functions. A utility function invoked directly by an application has no caller: `self.msg_sender()` panics, and `self.context.maybe_msg_sender()` returns `Option::none()`. Within a simulation PXE takes this value from the actual call graph, but utility execution as a whole is unconstrained, so contracts must not rely on it as a security guarantee.

**Tags:**
- [functions](https://docs.aztec.network/developers/tags/functions)
- [contracts](https://docs.aztec.network/developers/tags/contracts)
- [composability](https://docs.aztec.network/developers/tags/composability)

[Edit this page](https://github.com/AztecProtocol/aztec-packages/edit/next/docs/docs-developers/docs/aztec-nr/framework-description/calling_contracts.md)