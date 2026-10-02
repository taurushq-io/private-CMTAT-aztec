# State Management

> Source: https://docs.aztec.network/developers/docs/foundational-topics/state_management

---

- [![Home](https://docs.aztec.network/img/Aztec_Symbol_Dark.png)![Home](https://docs.aztec.network/img/Aztec%20Symbol_Light.png)](https://docs.aztec.network/)
- [Foundational Topics](https://docs.aztec.network/developers/docs/foundational-topics)
- State Management

On this page
# State Management

Aztec has a hybrid public/private state model. Contract developers can specify which data is public and which is private, as well as the functions that operate on that data.

Private and public data are stored in two separate trees: a **public data tree** and a **note hashes tree**. Both trees store state for all accounts on the network directly as leaves, unlike Ethereum where a state trie contains smaller tries for individual accounts.

This means storage must be carefully allocated to prevent collisions. Storage is *siloed* to each contract, though the exact siloing mechanism differs slightly between public and private storage.

## Public State[​](#public-state)

Public state in Aztec works similarly to other blockchains. It is transparent and managed by smart contract logic.

The sequencer stores and updates public state. It executes state transitions, generates proofs of correct execution (or delegates to the prover network), and publishes data to Ethereum.

## Private State[​](#private-state)

Private state is encrypted and owned by users who hold the decryption keys. It uses an append-only data structure since updating records directly would leak information about the transaction graph.

To "delete" private state, you add an associated nullifier to a nullifier set. The nullifier is computed such that observers cannot link a state record to its nullifier without the owner's keys.

Modifying state is accomplished by nullifying the existing record and creating a new one. This gives private state an intrinsic UTXO (unspent transaction output) structure.

## Notes[​](#notes)

Private state uses UTXOs, commonly called **notes**. Notes are encrypted pieces of data that only their owner can decrypt.

### How Notes Work[​](#how-notes-work)

In Ethereum's account-based model, each account maps to a specific storage location. In Aztec's UTXO model, notes specify their owner and have no fixed relationship between accounts and data locations.

Rather than storing entire notes, the protocol stores **note commitments** (hashes) in a Merkle tree called the note hash tree. Users prove they know the note preimage when updating private state.

When a note is consumed, Aztec creates a nullifier from the note data and may create new notes with updated information. This decouples the actions of creating, updating, and deleting private state.

![image](https://docs.aztec.network/assets/ideal-img/public-and-private-state-diagram.8ac73af.640.png)
Notes work like cash. To spend a 5 dollar note on a $3.50 purchase, you nullify the $5 note and create two new notes: $1.50 for yourself and $3.50 for the recipient. Only you and the recipient know about the $3.50 transfer.

### Sending Notes[​](#sending-notes)

When creating notes for a recipient, you need a way to deliver them:

**Onchain (encrypted logs):** The standard method. Emit an encrypted log as part of your transaction. The encrypted note data is posted onchain, allowing recipients to find notes through [note discovery](https://docs.aztec.network/developers/docs/foundational-topics/advanced/storage/note_discovery).

**Offchain:** If you know the recipient directly, share the note data with them. They store it in their PXE and can spend it later.

**Self-created notes:** Notes you create for yourself don't need broadcasting. Store them in your PXE to prove ownership and spend them later.

### Abstracting Notes[​](#abstracting-notes)

Users don't need to think about individual notes. The Aztec.nr library abstracts notes by letting developers define custom note types that specify how notes are created, nullified, transferred, and displayed. Aztec.nr also handles [note discovery](https://docs.aztec.network/developers/docs/foundational-topics/advanced/storage/note_discovery) for notes encrypted to a user's account.

## Technical Details[​](#technical-details)

### Storage Slots[​](#storage-slots)

Public storage uses literal storage slots. Private storage uses logical storage slots that associate multiple notes together. See [storage slots](https://docs.aztec.network/developers/docs/foundational-topics/advanced/storage/storage_slots) for details.

### Contract Address Siloing[​](#contract-address-siloing)

The contract address is included when computing note hashes to ensure different contracts don't produce identical hashes. The protocol handles this automatically.

### Note Types[​](#note-types)

Aztec.nr provides several note types:

- **`PrivateSet`** - A collection of notes, useful for balances represented as multiple value notes
- **`PrivateMutable`** - A single note representing one value that can be replaced
- **`PrivateImmutable`** - A single note that cannot be changed after initialization

These state variables must be wrapped in an `Owned<>` type that specifies the note owner. The `Owned<>` wrapper binds a note collection to a specific owner address, ensuring notes are correctly associated with their owner for nullifier computation and access control.

```
#[storage]struct Storage<Context> {    balance: Owned<PrivateSet<UintNote, Context>, Context>,}
```

Notes can also be custom types storing any values your application needs. Use the `#[note]` macro for standard notes or `#[custom_note]` for notes requiring custom hash or nullifier computation.

### Built-in Note Types[​](#built-in-note-types)

**`UintNote`** - Stores a numeric value (`u128`). Supports partial notes for scenarios where the value is determined in public execution.

uint_note_def
```
#[derive(Deserialize, Eq, Serialize, Packable)]#[custom_note]pub struct UintNote {    /// The number stored in the note.    pub value: u128,}
```

> [Source code: noir-projects/aztec-nr/uint-note/src/uint_note.nr#L29-L36](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/noir-projects/aztec-nr/uint-note/src/uint_note.nr#L29-L36)

**`FieldNote`** - Stores a single `Field` value.

### Creating and Destroying Notes[​](#creating-and-destroying-notes)

The [lifecycle module](https://github.com/AztecProtocol/aztec-packages/tree/v5.2.0/noir-projects/aztec-nr/aztec/src/note/lifecycle.nr) contains functions for note management:

- `create_note` - Creates a new note, computing its hash and pushing it to the context
- `destroy_note` - Nullifies a note by computing and emitting its nullifier

Notes created and nullified within the same transaction are called **transient notes**. The kernel circuits automatically squash these, avoiding unnecessary tree insertions and improving efficiency.

### Note Interface[​](#note-interface)

Notes must implement the `NoteHash` trait from [note_interface.nr](https://github.com/AztecProtocol/aztec-packages/tree/v5.2.0/noir-projects/aztec-nr/aztec/src/note/note_interface.nr):

- `compute_note_hash(self, owner, storage_slot, randomness)` - Computes the note's commitment
- `compute_nullifier(self, context, owner, note_hash_for_nullification)` - Computes the nullifier for consumption
- `compute_nullifier_unconstrained(self, owner, note_hash_for_nullification)` - Unconstrained nullifier computation

The `#[note]` macro generates default implementations using `poseidon2_hash_with_separator`.

### Reading Notes[​](#reading-notes)

Only users with appropriate keys can read private values they have permission to access. Notes can be read offchain without modifying onchain state.

When reading a note in a transaction, subsequent reads of the same note would reveal a link between transactions. To preserve privacy, notes read in transactions are typically "consumed" (nullified) and new notes created.

With `PrivateSet`, a private variable's value can be interpreted as the sum of all notes at that storage slot. Nullifying is done by inserting a nullifier into the nullifier tree, not by deleting the note hash.

### Updating Notes[​](#updating-notes)

To update a value, nullify the existing note hash(es) and insert a new note hash for the updated value. The PXE tracks note state locally while the note hash tree records the cryptographic commitments.

## Further Reading[​](#further-reading)

- [High level network architecture](https://docs.aztec.network/developers/docs/foundational-topics)
- [Transaction lifecycle](https://docs.aztec.network/developers/docs/foundational-topics/transactions#simple-example-of-the-private-transaction-lifecycle)
- [Storage slots](https://docs.aztec.network/developers/docs/foundational-topics/advanced/storage/storage_slots)
- [Note discovery](https://docs.aztec.network/developers/docs/foundational-topics/advanced/storage/note_discovery)

**Tags:**
- [protocol](https://docs.aztec.network/developers/tags/protocol)
- [storage](https://docs.aztec.network/developers/tags/storage)

[Edit this page](https://github.com/AztecProtocol/aztec-packages/edit/next/docs/docs-developers/docs/foundational-topics/state_management.md)