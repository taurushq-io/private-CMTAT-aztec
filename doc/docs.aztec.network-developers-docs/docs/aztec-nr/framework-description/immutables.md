# Immutables via Salt

> Source: https://docs.aztec.network/developers/docs/aztec-nr/framework-description/immutables

---

- [![Home](https://docs.aztec.network/img/Aztec_Symbol_Dark.png)![Home](https://docs.aztec.network/img/Aztec%20Symbol_Light.png)](https://docs.aztec.network/)
- [Aztec.nr](https://docs.aztec.network/developers/docs/aztec-nr)
- Framework Description
- Immutables via Salt

On this page
# Immutables via Salt

Aztec contracts can commit immutable values directly into the contract's address by encoding them into the deployment salt, removing the need for a separate initialization transaction.

## Overview[​](#overview)

Rather than storing immutables in private storage (which requires an initializer function and an extra transaction), the [aztec-immutables-macro](https://github.com/defi-wonderland/aztec-immutables-macro/tree/dev) library encodes them into the contract's salt:

```
salt = poseidon2_hash([actual_salt, constant_0, constant_1, ...])
```

Since the salt is part of the address derivation, the immutable values become cryptographically bound to the contract's address itself.

## Key benefits[​](#key-benefits)

- **No initialization transaction** — immutables are committed at deployment time, not in a separate setup call
- **Runtime verification** — at execution time, capsule data is loaded and verified against the stored salt, ensuring data integrity
- **Persistent storage** — immutables are persisted to the PXE's [CapsuleStore](https://docs.aztec.network/developers/docs/aztec-nr/framework-description/advanced/how_to_use_capsules) after deployment, so capsules don't need to be attached to every transaction
- **Compatible with standard storage** — works alongside `#[storage]` and initializers when needed

## Performance[​](#performance)

Initialization cost is completely eliminated (no constructor transaction). The per-transaction overhead is approximately 1,098 gates (+0.2%) in the account entrypoint.

## Getting started[​](#getting-started)

For installation instructions, usage examples, and a reference implementation of an initializerless Schnorr account contract, see the [aztec-immutables-macro README](https://github.com/defi-wonderland/aztec-immutables-macro/tree/dev).

**Tags:**
- [contracts](https://docs.aztec.network/developers/tags/contracts)
- [storage](https://docs.aztec.network/developers/tags/storage)
- [immutables](https://docs.aztec.network/developers/tags/immutables)
- [optimization](https://docs.aztec.network/developers/tags/optimization)

[Edit this page](https://github.com/AztecProtocol/aztec-packages/edit/next/docs/docs-developers/docs/aztec-nr/framework-description/immutables.md)