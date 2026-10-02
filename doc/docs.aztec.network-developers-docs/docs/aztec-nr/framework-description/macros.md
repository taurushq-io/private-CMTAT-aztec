# Aztec Macros

> Source: https://docs.aztec.network/developers/docs/aztec-nr/framework-description/macros

---

- [![Home](https://docs.aztec.network/img/Aztec_Symbol_Dark.png)![Home](https://docs.aztec.network/img/Aztec%20Symbol_Light.png)](https://docs.aztec.network/)
- [Aztec.nr](https://docs.aztec.network/developers/docs/aztec-nr)
- Framework Description
- Aztec Macros

On this page
# Aztec Macros

Aztec.nr provides macros (attributes) that transform your code during compilation to handle the complexities of private execution, proof generation, and state management.

## Quick reference[​](#quick-reference)

### Contract[​](#contract)

| Attribute | Purpose |
| --- | --- |
| `#[aztec]` | Marks a module as an Aztec contract |

### Functions[​](#functions)

| Attribute | Purpose |
| --- | --- |
| `#[external("private")]` | Client-side private execution with proofs |
| `#[external("public")]` | Sequencer-side public execution |
| `#[external("utility")]` | Unconstrained queries, not included in transactions |
| `#[internal("private")]` | Private helper, only callable within the same contract |
| `#[internal("public")]` | Public helper, only callable within the same contract |
| `#[view]` | Prevents state modification |
| `#[initializer]` | Contract constructor |
| `#[noinitcheck]` | Callable before contract initialization |
| `#[allow_phase_change]` | Allows for phase change to happen during the function's execution |
| `#[only_self]` | Only callable by the same contract |
| `#[authorize_once]` | Requires authwit authorization with replay protection |

Functions can have multiple attributes (e.g., `#[external("public")]` with `#[view]` and `#[only_self]`).

### Structs[​](#structs)

| Attribute | Purpose |
| --- | --- |
| `#[note]` | Defines a private note type |
| `#[custom_note]` | Note with custom hash/nullifier logic |
| `#[storage]` | Defines contract storage layout |
| `#[storage_no_init]` | Storage with manual slot allocation |

For detailed explanations and examples, see the [Attributes and Macros reference](https://docs.aztec.network/developers/docs/aztec-nr/framework-description/functions/attributes).

## Further reading[​](#further-reading)

- [Attributes and Macros reference](https://docs.aztec.network/developers/docs/aztec-nr/framework-description/functions/attributes) - detailed documentation for each macro
- [Inner workings of functions](https://docs.aztec.network/developers/docs/aztec-nr/framework-description/functions/function_transforms) - how macros transform your code

**Tags:**
- [contracts](https://docs.aztec.network/developers/tags/contracts)
- [functions](https://docs.aztec.network/developers/tags/functions)

[Edit this page](https://github.com/AztecProtocol/aztec-packages/edit/next/docs/docs-developers/docs/aztec-nr/framework-description/macros.md)