# Defining Functions

> Source: https://docs.aztec.network/developers/docs/aztec-nr/framework-description/functions

---

- [![Home](https://docs.aztec.network/img/Aztec_Symbol_Dark.png)![Home](https://docs.aztec.network/img/Aztec%20Symbol_Light.png)](https://docs.aztec.network/)
- [Aztec.nr](https://docs.aztec.network/developers/docs/aztec-nr)
- Framework Description
- Defining Functions

On this page
# Defining Functions

Functions serve as the building blocks of smart contracts. Functions can be either **public**, ie they are publicly available for anyone to see and can directly interact with public state, or **private**, meaning they are executed completely client-side in the [PXE](https://docs.aztec.network/developers/docs/foundational-topics/pxe). Read more about how private functions work [here](https://docs.aztec.network/developers/docs/aztec-nr/framework-description/functions/attributes#private-functions-externalprivate).

Currently, any function is "mutable" in the sense that it might alter state. However, we also support static calls, similarly to EVM. A static call is essentially a call that does not alter state (it keeps state static).

## Initializer functions[​](#initializer-functions)

Smart contracts may have one, or many, initializer functions which are called when the contract is deployed.

Initializers are regular functions that set an "initialized" flag (a nullifier) for the contract. A contract can only be initialized once, and contract functions can only be called after the contract has been initialized, much like a constructor. However, if a contract defines no initializers, it can be called at any time. Additionally, you can define as many initializer functions in a contract as you want, both private and public.

## Oracles[​](#oracles)

There are also special oracle functions, which can get data from outside of the smart contract. In the context of Aztec, oracles are often used to get user-provided inputs.

## Learn more about functions[​](#learn-more-about-functions)

- [How function visibility works in Aztec](https://docs.aztec.network/developers/docs/aztec-nr/framework-description/functions/visibility)
- How to write an [initializer function](https://docs.aztec.network/developers/docs/aztec-nr/framework-description/functions/how_to_define_functions#define-initializer-functions)
- [Oracles](https://docs.aztec.network/developers/docs/aztec-nr/framework-description/advanced/protocol_oracles) and how Aztec smart contracts might use them
- [How functions work under the hood](https://docs.aztec.network/developers/docs/aztec-nr/framework-description/functions/attributes)

Find a function macros reference [here](https://docs.aztec.network/developers/docs/aztec-nr/framework-description/macros)

**Tags:**
- [functions](https://docs.aztec.network/developers/tags/functions)

[Edit this page](https://github.com/AztecProtocol/aztec-packages/edit/next/docs/docs-developers/docs/aztec-nr/framework-description/functions/index.md)