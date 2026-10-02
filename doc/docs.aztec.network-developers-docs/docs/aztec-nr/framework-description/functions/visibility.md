# Visibility

> Source: https://docs.aztec.network/developers/docs/aztec-nr/framework-description/functions/visibility

---

- [![Home](https://docs.aztec.network/img/Aztec_Symbol_Dark.png)![Home](https://docs.aztec.network/img/Aztec%20Symbol_Light.png)](https://docs.aztec.network/)
- [Aztec.nr](https://docs.aztec.network/developers/docs/aztec-nr)
- Framework Description
- [Defining Functions](https://docs.aztec.network/developers/docs/aztec-nr/framework-description/functions)
- Visibility

On this page
# Visibility

In Aztec there are multiple different types of visibility that can be applied to functions. Namely we have `data visibility` and `function visibility`. This page explains these types of visibility.

## Data visibility[​](#data-visibility)

Data visibility describes whether the data (or state) used in a function is generally accessible (public) or on a need-to-know basis (private).

## Function visibility[​](#function-visibility)

Function visibility describes whether a function is callable from other contracts, or only from within the same contract. This is similar to the visibility modifiers you may be familiar with from Solidity.

### The `#[external(...)]` attribute[​](#the-external-attribute)

In Aztec.nr, the `#[external(...)]` attribute marks a function as externally callable - meaning it can be invoked via a transaction or by other contracts. The attribute takes a parameter specifying the execution context:

- `#[external("private")]` - The function executes in a private context with access to private state
- `#[external("public")]` - The function executes in a public context with access to public state

### The `#[only_self]` attribute[​](#the-only_self-attribute)

By default, all external functions are callable from other contracts, similar to Solidity's `public` visibility. To restrict a function so it can only be called by the same contract, use the `#[only_self]` attribute:

```
#[external("public")]#[only_self]fn _increase_public_balance(to: AztecAddress, amount: u128) {    // This function can only be called by this contract    let new_balance = self.storage.public_balances.at(to).read().add(amount);    self.storage.public_balances.at(to).write(new_balance);}
```

A common use case for `#[only_self]` is when a private function needs to modify public state. Since private functions cannot directly modify public state, they enqueue calls to public functions. By marking the public function with `#[only_self]`, you ensure that only your contract can call it - preventing external parties from manipulating the public state directly.

dangerNote that functions without `#[only_self]` can be used directly as an entry-point, which currently means that the `msg_sender` would be `0`. For this reason, using address `0` as a burn address is not recommended. You can learn more about this in the [Accounts concept page](https://docs.aztec.network/developers/docs/foundational-topics/accounts/keys).

### The `#[internal]` attribute[​](#the-internal-attribute)

The `#[internal]` attribute is different from `#[only_self]`. While `#[only_self]` restricts *who* can call a function (only the same contract, but still via an external call), `#[internal]` functions are **inlined** into the calling function. This is similar to how Solidity's `internal` functions use EVM's `JUMP` instruction rather than `CALL`.

Internal functions:

- Cannot be called externally (no transaction can invoke them directly)
- Are inlined at compile time into the functions that call them
- Have access to the calling function's context

To understand how visibility works under the hood, check out the [Inner Workings page](https://docs.aztec.network/developers/docs/aztec-nr/framework-description/functions/attributes).

**Tags:**
- [functions](https://docs.aztec.network/developers/tags/functions)

[Edit this page](https://github.com/AztecProtocol/aztec-packages/edit/next/docs/docs-developers/docs/aztec-nr/framework-description/functions/visibility.md)