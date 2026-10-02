# Aztec.nr API Reference

> Source: https://docs.aztec.network/developers/docs/aztec-nr/api

---

- [![Home](https://docs.aztec.network/img/Aztec_Symbol_Dark.png)![Home](https://docs.aztec.network/img/Aztec%20Symbol_Light.png)](https://docs.aztec.network/)
- [Aztec.nr](https://docs.aztec.network/developers/docs/aztec-nr)
- Aztec.nr API Reference

On this page
# Aztec.nr API Reference

The Aztec.nr API reference documentation is auto-generated from the source code using `nargo doc`.

## View the API Documentation[​](#view-the-api-documentation)

[**Aztec.nr**](https://docs.aztec.network/aztec-nr-api/mainnet/noir_aztec/)
The API reference includes documentation for all public modules, functions, structs, and types in the aztec-nr workspace:

### Core Crates[​](#core-crates)

- [**noir_aztec**](https://docs.aztec.network/aztec-nr-api/mainnet/noir_aztec/) - Core Aztec contract framework including:

  - [`context`](https://docs.aztec.network/aztec-nr-api/mainnet/noir_aztec/context/) - Private and public execution contexts
  - [`state_vars`](https://docs.aztec.network/aztec-nr-api/mainnet/noir_aztec/state_vars/) - State variable types (PrivateMutable, PublicMutable, Map, etc.)
  - [`note`](https://docs.aztec.network/aztec-nr-api/mainnet/noir_aztec/note/) - Note interfaces and utilities
  - [`authwit`](https://docs.aztec.network/aztec-nr-api/mainnet/noir_aztec/authwit/) - Authentication witness support
  - [`history`](https://docs.aztec.network/aztec-nr-api/mainnet/noir_aztec/history/) - Historical state proofs
  - [`messages`](https://docs.aztec.network/aztec-nr-api/mainnet/noir_aztec/messages/) - Cross-chain messaging
  - [`oracle`](https://docs.aztec.network/aztec-nr-api/mainnet/noir_aztec/oracle/) - Oracle interfaces
  - [`macros`](https://docs.aztec.network/aztec-nr-api/mainnet/noir_aztec/macros/) - Contract macros and attributes
  - [`hash`](https://docs.aztec.network/aztec-nr-api/mainnet/noir_aztec/hash/) - Hash functions and utilities
  - [`keys`](https://docs.aztec.network/aztec-nr-api/mainnet/noir_aztec/keys/) - Key management utilities
  - [`event`](https://docs.aztec.network/aztec-nr-api/mainnet/noir_aztec/event/) - Event emission and interfaces
  - [`test`](https://docs.aztec.network/aztec-nr-api/mainnet/noir_aztec/test/) - Testing utilities
  - [`utils`](https://docs.aztec.network/aztec-nr-api/mainnet/noir_aztec/utils/) - General utilities

### Note Types[​](#note-types)

- [**address_note**](https://docs.aztec.network/aztec-nr-api/mainnet/address_note/) - Note type for storing
Aztec addresses
- [**field_note**](https://docs.aztec.network/aztec-nr-api/mainnet/field_note/) - Note type for storing
a single Field value
- [**uint_note**](https://docs.aztec.network/aztec-nr-api/mainnet/uint_note/) - Note type for storing
unsigned integers

### State Variables[​](#state-variables)

- [**balance_set**](https://docs.aztec.network/aztec-nr-api/mainnet/balance_set/) - State variable for
managing private balances

### Utilities[​](#utilities)

- [**compressed_string**](https://docs.aztec.network/aztec-nr-api/mainnet/compressed_string/) - Compressed
string utilities for efficient storage

[Edit this page](https://github.com/AztecProtocol/aztec-packages/edit/next/docs/docs-developers/docs/aztec-nr/api.mdx)