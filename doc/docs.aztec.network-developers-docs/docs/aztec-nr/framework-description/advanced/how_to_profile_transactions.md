# Profiling Transactions

> Source: https://docs.aztec.network/developers/docs/aztec-nr/framework-description/advanced/how_to_profile_transactions

---

- [![Home](https://docs.aztec.network/img/Aztec_Symbol_Dark.png)![Home](https://docs.aztec.network/img/Aztec%20Symbol_Light.png)](https://docs.aztec.network/)
- [Aztec.nr](https://docs.aztec.network/developers/docs/aztec-nr)
- Framework Description
- Advanced Topics
- Profiling Transactions

On this page
# Profiling Transactions

This guide shows you how to profile Aztec transactions to understand gate counts and identify optimization opportunities.

## Prerequisites[​](#prerequisites)

- `aztec` command installed ([see installation](https://docs.aztec.network/developers/getting_started_on_local_network))
- Aztec contract compiled (`aztec compile`)
- Basic understanding of proving and gate counts

## Choosing a profiling tool[​](#choosing-a-profiling-tool)

Aztec provides three ways to profile. Each serves a different purpose:

| Tool | What it measures | Needs deployment? | When to use |
| --- | --- | --- | --- |
| `aztec profile gates` | Per-function gate counts | No | Quick check of individual function costs after compiling |
| `aztec profile flamegraph` | Per-function flamegraph SVG | No | Deep-dive into where gates come from inside a function |
| `aztec-wallet profile` / `.profile()` in aztec.js | Full transaction gate count including all kernel circuits | Yes* | Understanding the true cost of a transaction end-to-end |

* `aztec-wallet profile` and `ContractFunctionInteraction.profile()` require a deployed contract. However, `DeployMethod.profile()` in aztec.js can profile deployment transactions before the contract exists.

In most cases, start with `aztec profile gates` for a quick overview, then use the full transaction profiling tools when you need to understand kernel overhead.

## Quick profiling with `aztec profile`[​](#quick-profiling-with-aztec-profile)

These commands work on compiled artifacts directly — no deployment or running network required.

### Gate counts[​](#gate-counts)

```
# Compile your contractaztec compile# Get gate counts for all functionsaztec profile gates ./target
```

Example output:

```
Gate counts:────────────────────────────────────────────────────────────────────my_contract-MyContract::constructor                          5,200my_contract-MyContract::my_function                         14,832my_contract-MyContract::transfer                            31,559────────────────────────────────────────────────────────────────────Total: 3 circuit(s)
```

These are the gate counts for your contract functions alone, **without** kernel circuit overhead. See [Understanding kernel overhead](#understanding-kernel-overhead) for how this translates to total transaction cost.

BB binary`aztec profile` needs the Barretenberg (`bb`) backend binary. It is auto-detected from the `@aztec/bb.js` package. If auto-detection fails, set the `BB` environment variable:

```
BB=/path/to/bb aztec profile gates ./target
```

Machine-readable outputFor build automation, use `--json` to emit gate counts as a JSON array. Each entry has `name`, `type` (`contract-function` or `program`), and `gates`:

```
aztec profile gates --json ./target
```

### Flamegraphs[​](#flamegraphs)

To generate an interactive flamegraph SVG for a specific function:

```
aztec profile flamegraph ./target/my_contract-MyContract.json my_function
```

This outputs a file like `my_contract-MyContract-my_function-flamegraph.svg` in the same directory. Open it in a browser for an interactive view where:

- **Width** represents gate count
- **Height** represents call stack depth
- **Wide sections** indicate optimization targets

tipIf `noir-profiler` is not on your PATH, set the `PROFILER_PATH` environment variable:

```
PROFILER_PATH=/path/to/noir-profiler aztec profile flamegraph ./target/my_contract-MyContract.json my_function
```

## Full transaction profiling[​](#full-transaction-profiling)

The tools above measure individual function gate counts. To understand the **total** proving cost of a transaction — including account entrypoints and kernel circuits — use `aztec-wallet profile` or `.profile()` in aztec.js. These require a running network and, in most cases, a deployed contract. The exception is `DeployMethod.profile()` in aztec.js, which can profile deployment transactions before the contract exists.

### Profile with aztec-wallet[​](#profile-with-aztec-wallet)

Use the `profile` command instead of `send` to get detailed gate counts:

```
# Import test accountsaztec-wallet import-test-accounts# Deploy your contractaztec-wallet deploy MyContractArtifact \  --from accounts:test0 \  --args [CONSTRUCTOR_ARGS] \  -a mycontract# Profile a function callaztec-wallet profile my_function \  -ca mycontract \  --args [FUNCTION_ARGS] \  -f accounts:test0
```

#### Reading the output[​](#reading-the-output)

The profile command outputs a per-circuit breakdown:

```
Per circuit breakdown:  Function name                          Time           Gates         Subtotal-------------------------------------------------------------------------------- - SchnorrAccount:entrypoint            12.34ms         21,724         21,724 - private_kernel_init                  23.45ms         45,351         67,075 - MyContract:my_function               15.67ms         31,559         98,634 - private_kernel_inner                 34.56ms         78,452        177,086Total gates: 177,086 (Biggest circuit: private_kernel_inner -> 78,452)
```

Key metrics:

- **Gates**: Circuit complexity for each step
- **Subtotal**: Accumulated gate count
- **Time**: Execution time per circuit

Notice that the kernel circuits (`private_kernel_init`, `private_kernel_inner`) appear alongside your contract functions. These are protocol overhead — see [Understanding kernel overhead](#understanding-kernel-overhead).

### Profile with aztec.js[​](#profile-with-aztecjs)

```
const result = await contract.methods.my_function(args).profile({  from: walletAddress,  profileMode: "full",  skipProofGeneration: true,});// Access gate counts from execution stepsfor (const step of result.executionSteps) {  console.log(`${step.functionName}: ${step.gateCount} gates`);}// Access timing informationconsole.log("Total time:", result.stats.timings.total, "ms");
```

#### Profile modes[​](#profile-modes)

- `gates`: Gate counts per circuit
- `execution-steps`: Detailed execution trace with bytecode and witnesses
- `full`: Complete profiling information (gates + execution steps)

Set `skipProofGeneration: true` for faster iteration when you only need gate counts.

## Generate flamegraphs with noir-profiler[​](#generate-flamegraphs-with-noir-profiler)

For deeper analysis of individual contract functions beyond what `aztec profile flamegraph` provides, you can use the Noir profiler directly. The profiler is installed automatically with Nargo (starting noirup v0.1.4).

```
# Compile your contract firstaztec compile# Generate a gates flamegraph (requires bb backend)noir-profiler gates \  --artifact-path ./target/my_contract-MyContract.json \  --backend-path bb \  --output ./target# Generate an ACIR opcodes flamegraphnoir-profiler opcodes \  --artifact-path ./target/my_contract-MyContract.json \  --output ./target
```

For detailed usage, see the [Noir profiler documentation](https://noir-lang.org/docs/tooling/profiler).

## Understanding kernel overhead[​](#understanding-kernel-overhead)

When you profile a full transaction, you'll see kernel circuits alongside your contract functions. These are protocol overhead — the private kernel runs once per private function call in the transaction. Even a typical transaction calling a single contract function involves two private calls (the account entrypoint + your function), totaling ~427k gates of which only ~14k are your function.

For a detailed breakdown of kernel phases and their gate costs, see [Private Kernel Circuit - Performance Impact](https://docs.aztec.network/developers/docs/foundational-topics/advanced/circuits/private_kernel#performance-impact).

## Gate count guidelines[​](#gate-count-guidelines)

These are rough guidelines for a **single contract function's** gate count (i.e. what `aztec profile gates` reports). A typical transaction (e.g. a token transfer) totals ~500,000 gates across all circuits including kernel overhead, so use that as a reference point.

| Gate Count | Assessment |
| --- | --- |
| < 50,000 | Excellent |
| 50,000 - 200,000 | Good |
| 200,000 - 500,000 | Consider optimizing |
| > 500,000 | Worth optimizing if possible |

Note that a high gate count does **not** prevent transaction inclusion — it only affects client-side proving time. See [Private Kernel Circuit - Performance Impact](https://docs.aztec.network/developers/docs/foundational-topics/advanced/circuits/private_kernel#performance-impact) for details.

## Next steps[​](#next-steps)

- [Writing efficient contracts](https://docs.aztec.network/developers/docs/aztec-nr/framework-description/advanced/writing_efficient_contracts) - optimization strategies and examples
- [Transaction lifecycle](https://docs.aztec.network/developers/docs/foundational-topics/transactions)
- [Testing contracts](https://docs.aztec.network/developers/docs/aztec-nr/testing_contracts)

**Tags:**
- [contracts](https://docs.aztec.network/developers/tags/contracts)
- [profiling](https://docs.aztec.network/developers/tags/profiling)

[Edit this page](https://github.com/AztecProtocol/aztec-packages/edit/next/docs/docs-developers/docs/aztec-nr/framework-description/advanced/how_to_profile_transactions.md)