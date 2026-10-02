# Rollup Circuits

> Source: https://docs.aztec.network/developers/docs/foundational-topics/advanced/circuits/rollup_circuits

---

- [![Home](https://docs.aztec.network/img/Aztec_Symbol_Dark.png)![Home](https://docs.aztec.network/img/Aztec%20Symbol_Light.png)](https://docs.aztec.network/)
- [Foundational Topics](https://docs.aztec.network/developers/docs/foundational-topics)
- Advanced Topics
- [Circuits](https://docs.aztec.network/developers/docs/foundational-topics/advanced/circuits)
- Rollup Circuits

On this page
# Rollup Circuits

The rollup circuits compress thousands of transactions into a single SNARK proof for verification on Ethereum. They aggregate proofs from private kernel and AVM execution, validate state transitions, and produce the final epoch proof submitted to L1.

noteThe rollup circuits use a "binary tree of proofs" topology. This allows proof generation to be parallelized across prover instances—each layer of the tree can be computed in parallel, or subtrees can be distributed to different provers.

## Circuit Hierarchy[​](#circuit-hierarchy)

Rollup circuits operate at four levels, each producing outputs consumed by the next:

| Level | Circuits | Input | Output |
| --- | --- | --- | --- |
| **Transaction** | TX Base (Private/Public), TX Merge | Kernel proofs | Transaction rollup data |
| **Block** | Block Root, Block Merge | Transaction rollups | Block rollup data |
| **Checkpoint** | Checkpoint Root, Checkpoint Merge | Block rollups | Checkpoint data |
| **Epoch** | Root Rollup | Checkpoint rollups | Final epoch proof |

## Transaction Level[​](#transaction-level)

### TX Base Rollups[​](#tx-base-rollups)

Process individual transactions from kernel proofs:

- **TX Base Private** - Processes transactions with only private execution. Validates the private kernel proof, updates tree snapshots (note hash, nullifier), and accumulates fees and mana usage.
- **TX Base Public** - Processes transactions that include public (AVM) execution. Validates the AVM proof, which has already performed tree updates and fee/mana accumulation during public execution.

### TX Merge Rollup[​](#tx-merge-rollup)

Merges pairs of transaction rollup proofs in binary fashion. Can chain recursively to aggregate many transactions into a single proof. Validates proof correctness and consecutive transaction ordering.

## Block Level[​](#block-level)

### Block Root Rollups[​](#block-root-rollups)

Transition from transaction-level to block-level outputs. Several variants handle different scenarios:

- **Block Root First** - First block of a checkpoint (validates parity root and L1-to-L2 tree)
- **Block Root** - Subsequent blocks in a checkpoint
- **Block Root Single TX** - Optimized variant for single-transaction blocks
- **Block Root Empty TX First** - Handles empty blocks

These circuits update the archive tree, compute block headers, and accumulate L2-to-L1 message hashes.

### Block Merge Rollup[​](#block-merge-rollup)

Merges pairs of block rollup proofs within a checkpoint. Validates archive continuity and state consistency between blocks.

## Checkpoint Level[​](#checkpoint-level)

### Checkpoint Root Rollups[​](#checkpoint-root-rollups)

Transition from block-level to checkpoint-level outputs:

- **Checkpoint Root** - Standard checkpoint containing multiple blocks
- **Checkpoint Root Single Block** - Optimized for single-block checkpoints

These circuits validate previous block headers, compute blob commitments, and accumulate fee recipients.

### Checkpoint Merge Rollup[​](#checkpoint-merge-rollup)

Merges pairs of checkpoint proofs. Validates checkpoint continuity and blob accumulator consistency.

### Checkpoint Padding[​](#checkpoint-padding)

A special circuit for epochs with only one checkpoint. Provides an empty right child for the binary tree structure.

## Epoch Level (Root Rollup)[​](#epoch-level-root-rollup)

The final circuit that completes an epoch proof. It:

- Merges two checkpoint rollup proofs
- Validates epoch-level blob batching challenges
- Produces the final `RootRollupPublicInputs` for L1 submission

The root rollup output includes:

- Previous and new archive roots
- Checkpoint header hashes
- Accumulated fees across all checkpoints
- Final blob public inputs for data availability

## Flexible Tree Topology[​](#flexible-tree-topology)

The architecture supports asymmetric "wonky trees" for efficiency:

- Transactions can be grouped variably into blocks
- Not all branches need the same depth
- Single-element optimizations reduce proof overhead
- Padding circuits handle partial epochs

This flexibility allows sequencers to optimize proving costs based on actual workload.

## Related Pages[​](#related-pages)

- [Private Kernel](https://docs.aztec.network/developers/docs/foundational-topics/advanced/circuits/private_kernel) - How private function proofs are generated
- [Public Execution](https://docs.aztec.network/developers/docs/foundational-topics/advanced/circuits/public_execution) - How the AVM produces public execution proofs

**Tags:**
- [protocol](https://docs.aztec.network/developers/tags/protocol)
- [circuits](https://docs.aztec.network/developers/tags/circuits)

[Edit this page](https://github.com/AztecProtocol/aztec-packages/edit/next/docs/docs-developers/docs/foundational-topics/advanced/circuits/rollup_circuits.md)