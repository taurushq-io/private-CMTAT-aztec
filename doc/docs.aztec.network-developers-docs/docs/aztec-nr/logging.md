# Logging from Contracts

> Source: https://docs.aztec.network/developers/docs/aztec-nr/logging

---

- [![Home](https://docs.aztec.network/img/Aztec_Symbol_Dark.png)![Home](https://docs.aztec.network/img/Aztec%20Symbol_Light.png)](https://docs.aztec.network/)
- [Aztec.nr](https://docs.aztec.network/developers/docs/aztec-nr)
- Logging from Contracts

On this page
# Logging from Contracts

Aztec contracts can emit log messages at seven severity levels. Private function logs appear immediately during local simulation in the Private eXecution Environment (PXE), while public function logs are collected and displayed in test mode.

## Prerequisites[​](#prerequisites)

- An Aztec contract project set up with the `aztec-nr` dependency
- Basic understanding of [private, public, and utility functions](https://docs.aztec.network/developers/docs/aztec-nr/framework-description/functions/visibility)

## Import the logging functions[​](#import-the-logging-functions)

Logging functions live under `aztec::oracle::logging`. Import the specific functions you need:

logging_imports
```
use aztec::oracle::logging::{    debug_log, debug_log_format, error_log, error_log_format, fatal_log, fatal_log_format,    info_log, info_log_format, trace_log, trace_log_format, verbose_log, verbose_log_format,    warn_log, warn_log_format,};
```

> [Source code: docs/examples/contracts/logging_example/src/main.nr#L5-L11](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/contracts/logging_example/src/main.nr#L5-L11)

Or import only what you need:

```
use aztec::oracle::logging::{info_log, debug_log, debug_log_format};
```

Old import path removedThe previous import path `dep::aztec::oracle::debug_log` has been removed. Update your imports to use `aztec::oracle::logging` instead.

## Log levels[​](#log-levels)

Aztec supports seven log levels, ordered from least to most verbose:

| Level | Value | When to use |
| --- | --- | --- |
| `fatal` | 1 | Unrecoverable errors that should always be visible |
| `error` | 2 | Recoverable errors or unexpected conditions |
| `warn` | 3 | Potential issues worth investigating |
| `info` | 4 | General operational information |
| `verbose` | 5 | Detailed information for troubleshooting |
| `debug` | 6 | Development-time debugging output |
| `trace` | 7 | Fine-grained tracing of execution flow |

When you set `LOG_LEVEL=info`, you see `fatal`, `error`, `warn`, and `info` messages, but `verbose`, `debug`, and `trace` are hidden.

Here is an example using all seven levels:

log_all_levels
```
#[external("private")]fn log_all_levels(value: Field) {    fatal_log("fatal level message");    fatal_log_format("fatal: {0}", [value]);    error_log("error level message");    error_log_format("error: {0}", [value]);    warn_log("warn level message");    warn_log_format("warn: {0}", [value]);    info_log("info level message");    info_log_format("info: {0}", [value]);    verbose_log("verbose level message");    verbose_log_format("verbose: {0}", [value]);    debug_log("debug level message");    debug_log_format("debug: {0}", [value]);    trace_log("trace level message");    trace_log_format("trace: {0}", [value]);}
```

> [Source code: docs/examples/contracts/logging_example/src/main.nr#L48-L66](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/contracts/logging_example/src/main.nr#L48-L66)

## Simple log messages[​](#simple-log-messages)

Each level has a function that accepts a plain string with no format arguments:

log_simple
```
// Simple messages (no arguments)info_log("Private function called");debug_log("Checkpoint reached in private function");
```

> [Source code: docs/examples/contracts/logging_example/src/main.nr#L23-L27](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/contracts/logging_example/src/main.nr#L23-L27)

## Log messages with format arguments[​](#log-messages-with-format-arguments)

Each level also has a `_format` variant that accepts a format string and an array of `Field` values. Use `{0}`, `{1}`, etc. to insert individual arguments by index, or `{}` to print the entire array:

log_format_patterns
```
#[external("private")]fn log_format_patterns(a: Field, b: Field, c: Field) {    // Single indexed argument    debug_log_format("First value: {0}", [a]);    // Multiple indexed arguments    info_log_format("Values: {0}, {1}, {2}", [a, b, c]);    // Whole array dump    debug_log_format("All values: {}", [a, b, c]);}
```

> [Source code: docs/examples/contracts/logging_example/src/main.nr#L68-L80](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/contracts/logging_example/src/main.nr#L68-L80)

noteFormat arguments must be `Field` values. Use `.to_field()` to convert addresses and other types:

log_address
```
#[external("private")]fn log_with_address(sender: AztecAddress) {    info_log_format("Sender: {0}", [sender.to_field()]);}
```

> [Source code: docs/examples/contracts/logging_example/src/main.nr#L33-L38](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/contracts/logging_example/src/main.nr#L33-L38)

## Viewing logs[​](#viewing-logs)

### In `aztec test` (Noir tests)[​](#in-aztec-test-noir-tests)

To see contract logs, set `LOG_LEVEL` to include the `debug_log` module:

```
LOG_LEVEL="error;trace:debug_log" aztec test
```

tipUse different log levels strategically: add `info_log` calls for key state transitions you always want to see, and `debug_log` or `trace_log` calls for detailed inspection.

### In TypeScript tests (jest, vitest)[​](#in-typescript-tests-jest-vitest)

TypeScript test environments do not enable contract logs by default. Set the `LOG_LEVEL` environment variable to include the `contract_log` module:

```
# Show contract logs at debug level and aboveLOG_LEVEL="info;debug:contract_log" yarn test# Show all contract log levels (most verbose)LOG_LEVEL="error;trace:contract_log" yarn test
```

### With a local network[​](#with-a-local-network)

Contract logs appear in the process that runs the PXE — your test process, not the network process. The network window only shows system-level infrastructure logs (archiver, world-state, etc.), which are generally not useful for contract debugging.

When running TypeScript tests against a local network, set `LOG_LEVEL` on the **test command**:

```
# Your test process sees contract logsLOG_LEVEL="error;trace:contract_log" yarn test
```

You do not need to change the `LOG_LEVEL` on `aztec start --local-network` to see contract logs.

## `LOG_LEVEL` syntax reference[​](#log_level-syntax-reference)

The `LOG_LEVEL` environment variable uses a semicolon-delimited format:

```
<default_level>;<level>:<module1>,<module2>;<level>:<module3>
```

- **First segment (required)**: the default log level for all modules. A bare `level:module` with no preceding default (e.g. `LOG_LEVEL="warn:simulator"`) is invalid and throws `Invalid log level` — the parser always reads the segment before the first `;` as the default level. To filter only specific modules, start with `silent` (e.g. `LOG_LEVEL="silent;debug:simulator"`)
- **Remaining segments**: `level:module` pairs that override the default for specific modules
- Modules are comma-separated within a segment
- The `aztec:` prefix is automatically stripped from module names
- Module names support regex or prefix matching

### Common configurations[​](#common-configurations)

| Scenario | `LOG_LEVEL` value |
| --- | --- |
| Contract logs in `aztec test` (TXE) | `error;trace:debug_log` |
| Contract logs in TypeScript tests (PXE) | `error;trace:contract_log` |
| Contract debug+ logs with system info | `info;debug:contract_log` |
| Only contract warnings and errors | `warn;warn:contract_log` |
| Everything verbose | `verbose` |
| Debug a specific system module | `info;debug:sequencer` |
| Multiple module overrides | `warn;debug:sequencer,archiver;trace:contract_log` |

## How contract logs are displayed[​](#how-contract-logs-are-displayed)

### In `aztec test` (TXE)[​](#in-aztec-test-txe)

Contract logs appear under the `debug_log` module:

```
[07:40:29.947] DEBUG: txe:top_level_context:debug_log your message here
```

### In TypeScript tests (PXE)[​](#in-typescript-tests-pxe)

When running through the PXE, the output includes the contract name with an abbreviated address:

```
[07:40:29.937] INFO: contract_log::Counter(0x1234abcd) 164f9c87bca0cf8c Transfer completed[07:40:29.947] DEBUG: contract_log::Counter(0x1234abcd) 164f9c87bca0cf8c Processing value: 0x2a
```

The hex value after the address (`164f9c87bca0cf8c`) is an internal request identifier. If the contract name cannot be resolved, you see `Unknown` in its place.

## Logging in public functions[​](#logging-in-public-functions)

Private and public functions handle logging differently:

- **Private functions** execute locally in the PXE. You see logs immediately during simulation.
- **Public functions** execute on the sequencer. You see logs during `.simulate()` calls and after `.send().wait()` completes in test mode.

The logging API is the same in public functions:

log_public
```
#[external("public")]fn log_public(value: Field) {    info_log("Public function called");    debug_log_format("Public value: {0}", [value]);}
```

> [Source code: docs/examples/contracts/logging_example/src/main.nr#L40-L46](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/contracts/logging_example/src/main.nr#L40-L46)

### Accessing logs programmatically[​](#accessing-logs-programmatically)

In test mode (when not using real proofs), you can access public function debug logs on the `TxReceipt`:

```
import { applyStringFormatting } from '@aztec/foundation/log';const { receipt } = await contract.methods.myPublicFunction(args).send({  from: address,  fee: { paymentMethod },  wait: { timeout: 600 },});// Logs are automatically printed to your console.// You can also access them programmatically:if (receipt.debugLogs) {  for (const log of receipt.debugLogs) {    console.log(`[${log.level}] ${applyStringFormatting(log.message, log.fields)}`);  }}
```

Each entry contains:

- `contractAddress` - the contract that emitted the log
- `level` - the log level (`info`, `debug`, etc.)
- `message` - the unformatted message string
- `fields` - the raw `Field` values passed as arguments

warning`receipt.debugLogs` is only available in test mode (when not using real proofs). In production, debug log collection is disabled.

## Verify logging works[​](#verify-logging-works)

Add a `debug_log` call to any contract function, then run with logging enabled:

```
LOG_LEVEL="error;trace:debug_log" aztec test
```

You should see output like:

```
[07:40:29.947] DEBUG: txe:top_level_context:debug_log your message here
```

If no output appears, check the troubleshooting section below.

## Troubleshooting[​](#troubleshooting)

| Problem | Solution |
| --- | --- |
| No contract logs appear in `aztec test` | Set `LOG_LEVEL` to include `debug_log`, e.g., `LOG_LEVEL="error;trace:debug_log" aztec test`. Also verify you are calling a log function inside the contract function being tested. |
| No contract logs in TypeScript tests | Set `LOG_LEVEL` to include `contract_log`, e.g., `LOG_LEVEL="error;trace:contract_log" yarn test`. |
| Import error on `dep::aztec::oracle::debug_log` | This path was removed. Update to `use aztec::oracle::logging::{debug_log, debug_log_format};`. |
| `receipt.debugLogs` is `undefined` | Debug logs are only collected in test mode (non-real-proofs). They are not available in production. |
| Too much noise in log output | Narrow the default level and use module filters, e.g., `LOG_LEVEL="error;debug:contract_log"`. |

## Quick reference[​](#quick-reference)

| Task | Code or command |
| --- | --- |
| Import logging | `use aztec::oracle::logging::{debug_log, debug_log_format};` |
| Simple log | `debug_log("message");` |
| Log with values | `debug_log_format("val: {0}", [my_field]);` |
| Run Noir tests with logs | `LOG_LEVEL="error;trace:debug_log" aztec test` |
| JS tests with contract logs | `LOG_LEVEL="error;trace:contract_log" yarn test` |

## Next steps[​](#next-steps)

- [Debugging Aztec Code](https://docs.aztec.network/developers/docs/aztec-nr/debugging) for error codes, profiling, and common issues
- [Events and Logs](https://docs.aztec.network/developers/docs/aztec-nr/framework-description/events_and_logs) for emitting events that offchain applications can consume
- [Testing Contracts](https://docs.aztec.network/developers/docs/aztec-nr/testing_contracts) for writing and running contract tests

**Tags:**
- [contracts](https://docs.aztec.network/developers/tags/contracts)
- [logging](https://docs.aztec.network/developers/tags/logging)
- [debugging](https://docs.aztec.network/developers/tags/debugging)
- [aztec.nr](https://docs.aztec.network/developers/tags/aztec-nr)

[Edit this page](https://github.com/AztecProtocol/aztec-packages/edit/next/docs/docs-developers/docs/aztec-nr/logging.md)