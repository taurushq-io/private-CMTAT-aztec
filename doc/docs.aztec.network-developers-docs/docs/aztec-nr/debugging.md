# Debugging Aztec Code

> Source: https://docs.aztec.network/developers/docs/aztec-nr/debugging

---

- [![Home](https://docs.aztec.network/img/Aztec_Symbol_Dark.png)![Home](https://docs.aztec.network/img/Aztec%20Symbol_Light.png)](https://docs.aztec.network/)
- [Aztec.nr](https://docs.aztec.network/developers/docs/aztec-nr)
- Debugging Aztec Code

On this page
# Debugging Aztec Code

This guide shows you how to debug issues in your Aztec development environment.

## Prerequisites[​](#prerequisites)

- Running Aztec local network
- Aztec.nr contract or aztec.js application
- Basic understanding of Aztec architecture

## Enable logging[​](#enable-logging)

For adding log statements to your contracts, controlling log verbosity, and understanding the `LOG_LEVEL` syntax, see the [Logging from Contracts](https://docs.aztec.network/developers/docs/aztec-nr/logging) guide.

To enable verbose system-level logging on a local network:

```
LOG_LEVEL=verbose aztec start --local-network
```

## Debugging common errors[​](#debugging-common-errors)

### Contract Errors[​](#contract-errors)

| Error | Solution |
| --- | --- |
| `Aztec dependency not found` | Add to Nargo.toml: `aztec = { git="https://github.com/AztecProtocol/aztec-packages/", tag="v5.2.0", directory="noir-projects/aztec-nr/aztec" }` |
| `Public state writes only supported in public functions` | Move state writes to public functions |
| `Unknown contract 0x0` | Call `wallet.registerContract(...)` to register contract |
| `No public key registered for address` | Call `wallet.registerSender(...)` |
| `Direct invocation of ... functions is not supported` | Use `self.call()`, `self.view()`, or `self.enqueue()` to [call contract functions](https://docs.aztec.network/developers/docs/aztec-nr/framework-description/calling_contracts) |
| `Failed to solve brillig function` | Check function parameters and note validity |
| `Cross-contract utility call denied` | Configure an `authorizeUtilityCall` [execution hook](#cross-contract-utility-call-denied) on your PXE |

#### Cross-contract utility call denied[​](#cross-contract-utility-call-denied)

Utility functions execute on the user's device and have access to private state. A cross-contract utility call made by
a malicious or compromised contract could leak private information to an untrusted contract. PXE therefore denies cross-
contract utility calls by default and requires explicit authorization via an execution hook. Calls to standard contracts
(such as the HandshakeRegistry, which is queried during every contract's sync) are always automatically authorized.

When a contract executes a utility function that calls into a different contract, PXE asks the wallet through an [execution hook](https://docs.aztec.network/developers/docs/foundational-topics/pxe/execution_hooks) whether the call should be allowed. If no hook is configured, or the wallet denies the request, you will see:

```
Cross-contract utility call denied: <reason>. <caller> attempted to call <target>:<selector> (<name>).
```

See [execution hooks](https://docs.aztec.network/developers/docs/foundational-topics/pxe/execution_hooks#authorizeutilitycall) for how to authorize calls, both in production and in Noir tests.

### Circuit Errors[​](#circuit-errors)

| Error Code | Meaning | Fix |
| --- | --- | --- |
| `2002` | Invalid contract address | Ensure contract is deployed and address is correct |
| `2005/2006` | Static call violations | Remove state modifications from static calls |
| `2017` | User intent mismatch | Verify transaction parameters match function call |
| `3001` | Unsupported operation | Check if operation is supported in current context |
| `3005` | Non-empty private call stack | Ensure private functions complete before public |
| `4007/4008` | Chain ID/version mismatch | Verify L1 chain ID and Aztec version |
| `7008` | Membership check failed | Ensure using valid historical state |
| `7009` | Array overflow | Reduce number of operations in transaction |

### Quick Fixes for Common Issues[​](#quick-fixes-for-common-issues)

```
# Archiver sync issues - force progress with dummy transactions.# Assumes you have imported the local network test accounts# (aztec-wallet import-test-accounts) and have a deployed token# aliased as `testtoken`.aztec-wallet send transfer --from test0 --contract-address testtoken --args accounts:test0 0aztec-wallet send transfer --from test0 --contract-address testtoken --args accounts:test0 0# L1 to L2 message pending - wait for inclusion# Messages need 2 blocks to be processed
```

## Debugging WASM errors[​](#debugging-wasm-errors)

### Enable debug WASM[​](#enable-debug-wasm)

```
// In vite.config.ts or similarexport default {  define: {    "process.env.BB_WASM_PATH": JSON.stringify("https://debug.wasm.url"),  },};
```

### Profile transactions[​](#profile-transactions)

```
import { serializePrivateExecutionSteps } from "@aztec/stdlib";// Profile the transactionconst profileTx = await contract.methods  .myMethod(param1, param2)  .profile({ profileMode: "execution-steps" });// Serialize for debuggingconst ivcMessagePack = serializePrivateExecutionSteps(profileTx.executionSteps);// Download debug fileconst blob = new Blob([ivcMessagePack]);const url = URL.createObjectURL(blob);const link = document.createElement("a");link.href = url;link.download = "debug-steps.msgpack";link.click();
```

⚠️ **Warning:** Debug files may contain private data. Use only in development.

## Interpret error messages[​](#interpret-error-messages)

### Circuit and protocol errors[​](#circuit-and-protocol-errors)

- **Private kernel errors (2xxx)**: Issues with private function execution
- **Public kernel errors (3xxx)**: Issues with public function execution
- **Rollup errors (4xxx)**: Block production issues
- **Generic errors (7xxx)**: Resource limits or state validation

### Transaction limits[​](#transaction-limits)

Current limits that trigger `7009 - ARRAY_OVERFLOW`:

- Max new notes per tx: Check `MAX_NOTE_HASHES_PER_TX`
- Max nullifiers per tx: Check `MAX_NULLIFIERS_PER_TX`
- Max function calls: Check call stack size limits
- Max L2→L1 messages: Check message limits

## Debugging sequencer issues[​](#debugging-sequencer-issues)

### Common sequencer errors[​](#common-sequencer-errors)

| Error | Cause | Solution |
| --- | --- | --- |
| `tree root mismatch` | State inconsistency | Restart local network or check state transitions |
| `next available leaf index mismatch` | Tree corruption | Verify tree updates are sequential |
| `Public call stack size exceeded` | Too many public calls | Reduce public function calls |
| `Failed to publish block` | L1 submission failed | Check L1 connection and gas |

## Reporting issues[​](#reporting-issues)

When debugging fails:

1. Collect error messages and codes
2. Generate transaction profile (if applicable)
3. Note your environment setup
4. Create issue at [aztec-packages](https://github.com/AztecProtocol/aztec-packages/issues/new)

## Quick reference[​](#quick-reference)

### Enable verbose logging[​](#enable-verbose-logging)

```
LOG_LEVEL=verbose aztec start --local-network
```

### Contract logging[​](#contract-logging)

See the full [Logging from Contracts](https://docs.aztec.network/developers/docs/aztec-nr/logging) guide for all available log functions and `LOG_LEVEL` configuration.

```
use aztec::oracle::logging::{debug_log, debug_log_format};
```

### Check contract registration[​](#check-contract-registration)

```
await wallet.getContractMetadata(myContractInstance.address);
```

### Decode L1 errors[​](#decode-l1-errors)

Check hex errors against [Errors.sol](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/l1-contracts/src/core/libraries/Errors.sol)

## Tips[​](#tips)

- Always check logs before diving into circuit errors
- State-related errors often indicate timing issues
- Array overflow errors mean you hit transaction limits
- Use debug WASM for detailed stack traces
- Profile transactions when errors are unclear

## Next steps[​](#next-steps)

- [Circuit Architecture](https://docs.aztec.network/developers/docs/foundational-topics/advanced/circuits)
- [Call Types](https://docs.aztec.network/developers/docs/foundational-topics/call_types)
- [Aztec.nr Dependencies](https://docs.aztec.network/developers/docs/aztec-nr/framework-description/dependencies)

**Tags:**
- [debugging](https://docs.aztec.network/developers/tags/debugging)
- [errors](https://docs.aztec.network/developers/tags/errors)
- [local_network](https://docs.aztec.network/developers/tags/local-network)
- [aztec.nr](https://docs.aztec.network/developers/tags/aztec-nr)

[Edit this page](https://github.com/AztecProtocol/aztec-packages/edit/next/docs/docs-developers/docs/aztec-nr/debugging.md)