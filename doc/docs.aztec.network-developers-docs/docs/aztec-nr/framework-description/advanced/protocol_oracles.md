# Oracle Functions

> Source: https://docs.aztec.network/developers/docs/aztec-nr/framework-description/advanced/protocol_oracles

---

- [![Home](https://docs.aztec.network/img/Aztec_Symbol_Dark.png)![Home](https://docs.aztec.network/img/Aztec%20Symbol_Light.png)](https://docs.aztec.network/)
- [Aztec.nr](https://docs.aztec.network/developers/docs/aztec-nr)
- Framework Description
- Advanced Topics
- Oracle Functions

On this page
# Oracle Functions

This page goes over what oracles are in Aztec and how they work.

Looking for a hands-on guide? You can learn how to use oracles in a smart contract [here](https://docs.aztec.network/developers/docs/aztec-nr/framework-description/advanced/how_to_use_capsules).

An oracle is something that allows us to get data from the outside world into our contracts. The most widely-known types of oracles in blockchain systems are probably Chainlink price feeds, which allow us to get the price of an asset in USD taking non-blockchain data into account.

While this is one type of oracle, the more general oracle, allows us to get any data into the contract. In the context of oracle functions or oracle calls in Aztec, it can essentially be seen as user-provided arguments, that can be fetched at any point in the circuit, and don't need to be an input parameter.

**Why is this useful? Why don't just pass them as input parameters?**
In the world of EVM, you would just read the values directly from storage and call it a day. However, when we are working with circuits for private execution, this becomes more tricky as you cannot just read the storage directly from your state tree, because there are only commitments (e.g. hashes) there. The pre-images (content) of your commitments need to be provided to the function to prove that you actually allowed to modify them.

If we fetch the notes using an oracle call, we can keep the function signature independent of the underlying data and make it easier to use. A similar idea, applied to the authentication mechanism is used for the Authentication Witnesses that allow us to have a single function signature for any wallet implementation, see [AuthWit](https://docs.aztec.network/developers/docs/aztec-nr/framework-description/authentication_witnesses) for more information on this.

Oracles introduce **non-determinism** into a circuit, and thus are `unconstrained`. It is important that any information that is injected into a circuit through an oracle is later constrained for correctness. Otherwise, the circuit will be **under-constrained** and potentially insecure!

`Aztec.nr` has a [module dedicated to its oracles](https://docs.aztec.network/aztec-nr-api/mainnet/noir_aztec/oracle/) where you can browse the full list.

## Inbuilt oracles[​](#inbuilt-oracles)

- [`debug_log`](https://docs.aztec.network/aztec-nr-api/mainnet/noir_aztec/protocol/logging/fn.debug_log) - Provides debug functions that can be used to log information to the console. Read more about debugging [here](https://docs.aztec.network/developers/docs/aztec-nr/debugging).
- [`auth_witness`](https://docs.aztec.network/aztec-nr-api/mainnet/noir_aztec/oracle/auth_witness/) - Provides a way to fetch the authentication witness for a given address. This is useful when building account contracts to support approve-like functionality.
- [`get_l1_to_l2_membership_witness`](https://docs.aztec.network/aztec-nr-api/mainnet/noir_aztec/oracle/get_l1_to_l2_membership_witness/) - Returns the leaf index and sibling path for an L1 to L2 message, used to prove message existence in cross-chain applications like token bridges.
- [`notes`](https://docs.aztec.network/aztec-nr-api/mainnet/noir_aztec/oracle/notes/) - Provides functions related to notes, such as fetching notes from storage, used behind the scenes for value notes and other pre-built note implementations.
- [`logs`](https://docs.aztec.network/aztec-nr-api/mainnet/noir_aztec/oracle/logs/) - Provides functions to log encrypted and unencrypted data.

Find a full list [on GitHub](https://github.com/AztecProtocol/aztec-packages/tree/v5.2.0/noir-projects/aztec-nr/aztec/src/oracle).

Please note that it is **not** possible to write a custom oracle for your dapp. Oracles are implemented in the PXE, so all users of your dapp would have to use a PXE with your custom oracle included. If you want to inject some arbitrary data that does not have a dedicated oracle, you can use [capsules](https://docs.aztec.network/developers/docs/aztec-nr/framework-description/advanced/how_to_use_capsules).

**Tags:**
- [functions](https://docs.aztec.network/developers/tags/functions)
- [oracles](https://docs.aztec.network/developers/tags/oracles)

[Edit this page](https://github.com/AztecProtocol/aztec-packages/edit/next/docs/docs-developers/docs/aztec-nr/framework-description/advanced/protocol_oracles.md)