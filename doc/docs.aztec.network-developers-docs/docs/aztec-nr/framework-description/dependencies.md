# Aztec.nr Dependencies

> Source: https://docs.aztec.network/developers/docs/aztec-nr/framework-description/dependencies

---

- [![Home](https://docs.aztec.network/img/Aztec_Symbol_Dark.png)![Home](https://docs.aztec.network/img/Aztec%20Symbol_Light.png)](https://docs.aztec.network/)
- [Aztec.nr](https://docs.aztec.network/developers/docs/aztec-nr)
- Framework Description
- Aztec.nr Dependencies

On this page
# Aztec.nr Dependencies

This page lists the available Aztec.nr libraries. Add dependencies to the `[dependencies]` section of your `Nargo.toml`:

```
[dependencies]aztec = { git="https://github.com/AztecProtocol/aztec-nr/", tag="v5.2.0", directory="aztec" }# Add other libraries as needed
```

## Core[​](#core)

### Aztec (required)[​](#aztec-required)

```
aztec = { git="https://github.com/AztecProtocol/aztec-nr/", tag="v5.2.0", directory="aztec" }
```

The core Aztec library required for every Aztec.nr smart contract.

## Note Types[​](#note-types)

### Address Note[​](#address-note)

```
address_note = { git="https://github.com/AztecProtocol/aztec-nr/", tag="v5.2.0", directory="address-note" }
```

Provides `AddressNote`, a note type for storing `AztecAddress` values.

### Field Note[​](#field-note)

```
field_note = { git="https://github.com/AztecProtocol/aztec-nr/", tag="v5.2.0", directory="field-note" }
```

Provides `FieldNote`, a note type for storing a single `Field` value.

### Uint Note[​](#uint-note)

```
uint_note = { git="https://github.com/AztecProtocol/aztec-nr/", tag="v5.2.0", directory="uint-note" }
```

Provides `UintNote`, a note type for storing `u128` values. Also includes `PartialUintNote` for partial note workflows where the value is completed in public execution.

## State Variables[​](#state-variables)

### Balance Set[​](#balance-set)

```
balance_set = { git="https://github.com/AztecProtocol/aztec-nr/", tag="v5.2.0", directory="balance-set" }
```

Provides `BalanceSet`, a state variable for managing private balances. Includes helper functions for adding, subtracting, and querying balances.

## Utilities[​](#utilities)

### Compressed String[​](#compressed-string)

```
compressed_string = { git="https://github.com/AztecProtocol/aztec-nr/", tag="v5.2.0", directory="compressed-string" }
```

Provides `CompressedString` and `FieldCompressedString` utilities for working with compressed string data.

## Updating your aztec dependencies[​](#updating-your-aztec-dependencies)

When `aztec compile` warns that your aztec dependency tag does not match the CLI version, update
the `tag` field in every Aztec.nr entry in your `Nargo.toml` to match the CLI version you are
running.

For example, if your CLI is `vv5.2.0`, change:

```
aztec = { git="https://github.com/AztecProtocol/aztec-nr/", tag="v<old-version>", directory="aztec" }
```

to:

```
aztec = { git="https://github.com/AztecProtocol/aztec-nr/", tag="vv5.2.0", directory="aztec" }
```

Repeat for every other Aztec.nr dependency in your `Nargo.toml` (e.g. `address_note`,
`balance_set`, etc.). You can check your current CLI version with `aztec --version`.

**Tags:**
- [contracts](https://docs.aztec.network/developers/tags/contracts)

[Edit this page](https://github.com/AztecProtocol/aztec-packages/edit/next/docs/docs-developers/docs/aztec-nr/framework-description/dependencies.md)