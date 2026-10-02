# Learning Aztec

Condensed notes written while building this repository. They are kept here because a short, opinionated summary of the Aztec model is easier to start from than the full documentation.

> **Scope and freshness.** Rewritten against **Aztec v5.2.0** (toolchain, `aztec-nr` and `@aztec/*` packages), the version this repository pins. Aztec changes fast and breaks APIs between releases: treat everything below as correct for 5.2.0 and check the [official documentation](https://docs.aztec.network/) and the [migration notes](https://docs.aztec.network/developers/docs/resources/migration_notes) for anything newer. A [terminology section](#what-changed-since-the-early-notes) at the end maps the names used in older tutorials to the current ones.

## Table of contents

- [The model in one page](#the-model-in-one-page)
- [Accounts, addresses and keys](#accounts-addresses-and-keys)
- [Authentication witnesses](#authentication-witnesses)
- [Contract structure and function types](#contract-structure-and-function-types)
- [Calling between contexts](#calling-between-contexts)
- [Public state](#public-state)
- [Private state: notes and nullifiers](#private-state-notes-and-nullifiers)
- [Storage slots and siloing](#storage-slots-and-siloing)
- [Note delivery](#note-delivery)
- [Note discovery: tagging](#note-discovery-tagging)
- [Events and logs](#events-and-logs)
- [Transaction lifecycle](#transaction-lifecycle)
- [Fees](#fees)
- [Ethereum <-> Aztec messaging](#ethereum---aztec-messaging)
- [Limits and gotchas](#limits-and-gotchas)
- [Proving cost](#proving-cost)
- [Tooling and workflow](#tooling-and-workflow)
- [What changed since the early notes](#what-changed-since-the-early-notes)
- [Questions and answers](#questions-and-answers)
- [Further reading](#further-reading)

## The model in one page

Aztec is a privacy-focused Layer 2 on Ethereum. A contract has two halves:

- a **private** half, executed on the user's own device inside a zero-knowledge proof, operating on encrypted UTXOs called **notes**;
- a **public** half, executed by the sequencer in an EVM-like environment (the AVM), operating on a key-value public state tree.

What the network sees of the private half is commitments: note hashes, nullifiers and encrypted logs. It never sees the note contents, the parties, or the amounts — unless the contract publishes them itself.

Consequences that drive every design decision:

- **Private execution is client-side and asynchronous.** It runs against a *historical* snapshot (the transaction's *anchor block*), because the user's client cannot know what the sequencer will do next. Therefore private functions **cannot read current public state**.
- **Private state is append-only.** You never update a note; you nullify it and create a new one. Deleting a note means pushing its nullifier.
- **Private can call public, not the other way round.** A private function can *enqueue* a public call, whose result is unavailable during private execution. Public functions cannot call private ones.
- **A public revert reverts the whole transaction**, including the private side effects — but fees already committed in the setup phase are still paid.

## Accounts, addresses and keys

Aztec has **native account abstraction**: an account *is* a contract, and how it authorises transactions is up to that contract. Beside that, the protocol mandates a set of key pairs, all on the **Grumpkin** curve. Grumpkin's base field is BN254's scalar field, so its arithmetic is native inside a proof — which is why every key the framework must handle in-circuit lives there.

| Key pair | Purpose at 5.2.0 | Managed by |
|---|---|---|
| Nullifier (`Npk_m`, `nhk_m`) | Computing nullifiers, i.e. spending notes | PXE |
| Incoming viewing (`Ivpk_m`, `ivsk`) | Encrypting / decrypting notes sent to the account | PXE |
| Outgoing viewing (`Ovpk_m`) | **Reserved, unused** | PXE |
| Tagging (`Tpk_m`) | **Reserved, unused** | PXE |
| Message-signing (`Mspk_m`) | **Reserved** (future protocol-level message signing) | Wallet |
| Fallback (`Fbpk_m`) | **Reserved** (future account recovery) | Wallet |
| Signing key | Transaction authorisation | Account contract — anything: Schnorr, ECDSA, passkeys, multisig, time locks |

Points to remember:

- Only `Ivpk_m` is carried as a **curve point**; the other five appear only as hashes. That is deliberate: address derivation needs `Ivpk_m` as a point so that anyone can encrypt to an address without a key registry.
- Address derivation:
  ```
  public_keys_hash = H(npk_m_hash, ivpk_m_hash, ovpk_m_hash, tpk_m_hash, mspk_m_hash, fbpk_m_hash)
  partial_address  = H(contract_class_id, salted_initialization_hash)
  pre_address      = H(public_keys_hash, partial_address)
  address          = (pre_address * G + Ivpk_m).x
  ```
  The address is the x-coordinate of a point whose discrete log is `pre_address + ivsk` — the account's **address secret**, and the private half of every Diffie-Hellman the framework performs on the recipient's behalf.
- The nullifier key is **app-siloed**: `nhk_app = H(nhk_m, contract_address)`. A leak in one application does not spend notes in another. Never derive it by hand; use `context.request_nhk_app(owner_npk_m_hash)` in private, `get_nhk_app(...)` in unconstrained code.
- **Protocol keys cannot be rotated** — they are baked into the address. Signing keys can, if the account contract allows it.
- The terminology moved: the old "nullifier secret key" `nsk_m` is now the **nullifier hiding key** `nhk_m`.

## Authentication witnesses

An *authwit* authorises **one specific action**, not an allowance. It is the mechanism by which a contract acts on a user's behalf.

```
inner_hash   = H(caller, selector, args_hash)
message_hash = H(consumer, chain_id, version, inner_hash)
```

- **Private flow.** The consuming contract makes a *static* call to the caller's account contract, which fetches the witness through an oracle and validates it. Static, so the account cannot re-enter and mutate state during validation.
- **Public flow.** No oracles are available to the sequencer, so authorisations are written in advance to a shared `AuthRegistry` contract and consumed from it. Setting and consuming in the same transaction cancels out and costs almost nothing.
- **Replay protection** is a nullifier on the authwit nonce.
- In a contract you rarely write any of this by hand: annotate the entry point with `#[authorize_once("from", "authwit_nonce")]`, naming the parameter holding the authorising account and the parameter holding the nonce. The macro skips validation when `msg_sender()` is that account (which must then pass nonce `0`).

## Contract structure and function types

```rust
use aztec::macros::aztec;

#[aztec]
pub contract MyContract {
    use aztec::macros::storage;

    #[storage]
    struct Storage<Context> {
        admin: PublicMutable<AztecAddress, Context>,
        balances: Owned<PrivateSet<UintNote, Context>, Context>,
    }

    #[external("private")]
    fn do_something(to: AztecAddress, amount: u128) { /* ... */ }
}
```

- **One contract per Noir package**, one `#[storage]` struct per contract, holding *all* state. The `Context` generic parameter is required on every storage struct: it tells each state variable which execution mode it is in, and the compiler hides the methods that mode cannot use (a `PublicMutable::read` simply does not exist in a private function).
- Everything is reached through `self`: `self.storage`, `self.msg_sender()`, `self.address`, `self.context`, `self.call(...)`, `self.enqueue(...)`, `self.emit(...)`.

The attributes worth knowing:

| Attribute | Meaning |
|---|---|
| `#[external("private")]` | Client-side, proved, operates on notes |
| `#[external("public")]` | Sequencer-side, EVM-like, operates on public state |
| `#[external("utility")]` | Unconstrained query, **never part of a transaction**; may read both private and public state and write local PXE state |
| `#[internal("private")]` / `#[internal("public")]` | Helper, inlined at the call site — not callable from outside |
| `#[view]` | Cannot modify state (private or public) |
| `#[initializer]` / `#[noinitcheck]` | Constructor / exempt from the initialisation check |
| `#[only_self]` | Callable only by the same contract — the counterpart of an enqueued private-to-public call |
| `#[authorize_once("account", "nonce")]` | Authwit check with replay protection |
| `#[allow_phase_change]` | Skip the phase check (account entrypoints) |
| `#[note]` / `#[custom_note]` | Note type, default or hand-written hash/nullifier |
| `#[event]` | Event type |

A good mental model for a **utility** function is a Solidity `view` reachable only through `eth_call` — except it can also mutate the local PXE (that is how log processing is implemented). Because it is unconstrained and oracle-driven, nothing guarantees the result; what *is* guaranteed is that the bytecode is the contract's, since the address commits to it.

`aztec-nargo expand` prints the contract after macro expansion — the fastest way to see what the framework actually generated.

## Calling between contexts

| From | To | How | Notes |
|---|---|---|---|
| private | private | `self.call(...)`, `self.view(...)` | Proved on the user's device; a failed assertion means no transaction is produced at all, so nothing is spent |
| private | public | `self.enqueue(...)`, `self.enqueue_self._f(...)` | Asynchronous: **no return value**, no side effects visible during private execution |
| private | public, hiding the caller | `self.enqueue_incognito(...)` | The called function must use `maybe_msg_sender()` |
| public | public | `self.call(...)` / static call | As on the EVM |
| public | private | — | Impossible |
| private or utility | utility | `self.call(...)` | From private it runs as unconstrained code; crossing a contract boundary needs wallet authorisation |

Two privacy traps on the private-to-public edge:

- `enqueue` sets `msg_sender` to the private caller's address, **publicly**. Use `enqueue_incognito` when the caller must stay hidden.
- The enqueued call itself is public: the target contract, the function and the arguments are all visible, and so is the fact that *some* private function of *this* contract enqueued it. This is why reading a `DelayedPublicMutable` privately is preferable to enqueueing a public read, and why the shared `PublicChecks` contract exists — `privately_check_timestamp` / `privately_check_block_number` route a common check through one contract shared by all applications, enlarging the privacy set.

## Public state

Public state behaves like Ethereum's: a key-value tree the sequencer updates, everyone reads.

| Type | Mutable | Readable in private | Use |
|---|---|---|---|
| `PublicMutable<T>` | yes | **no** | Totals, flags, role tables |
| `PublicImmutable<T>` | no | yes | Configuration fixed at deployment |
| `DelayedPublicMutable<T, DELAY>` | yes, after `DELAY` seconds | yes | Configuration that private functions must read |

`DelayedPublicMutable` is the one that needs explaining. A private function may not read current public state, but it *may* read a value that is guaranteed not to change for a while. That is exactly what a scheduled delay buys: `schedule_value_change` makes the new value effective `DELAY` seconds later, so a value read at the anchor block is still current for at least that long.

- The delay is a **duration in seconds**, not a number of blocks.
- Reading one in private sets the transaction's `expiration_timestamp` (anchor + remaining delay). The transaction is unincludable after that, and the expiry is **public** — so a delay nobody else uses fingerprints your application. Pick a common value.
- Delays are themselves adjustable through `schedule_delay_change`: an *increase* is immediate, a *decrease* takes effect after the difference. Shortening it immediately would retroactively break the guarantee a reader had already relied on.
- A zero or near-zero delay is not usable from private: the earliest includable block is already a slot away, so the transaction would expire before it could land. The library's own example uses 360 s and calls it "5 slots"; real deployments use hours.
- Not suitable for an emergency lever, precisely because it is delayed.

## Private state: notes and nullifiers

Private state is a set of **notes** (UTXOs). The note hash tree stores only commitments; the nullifier tree records spends.

- **Create** a note: compute its hash, push it to the context, deliver the contents to the owner.
- **Destroy** a note: push its nullifier. The nullifier is derived from the note and the owner's app-siloed nullifier key, so nobody can link a note to its nullifier without that key — and nobody else can produce it.
- **Update**: nullify, create a new note. A note created and nullified in the same transaction is **transient** and is squashed by the kernel; it is never written to a tree.
- A note created for someone else is only usable by them once they can **find and decrypt** it — delivery and discovery are separate problems from note creation, and both are the contract's responsibility.

State variable types, all wrapped in `Owned<...>` and reached with `.at(owner)`:

| Type | Shape |
|---|---|
| `Owned<PrivateSet<N>>` | A collection; the value is the sum of the live notes at the slot (token balances) |
| `Owned<PrivateMutable<N>>` | One replaceable note |
| `Owned<PrivateImmutable<N>>` | One note, written once |
| `SinglePrivateMutable<N>` / `SinglePrivateImmutable<N>` | Contract-wide private singleton, no owner |

Built-in note types: `UintNote` (a `u128`, and the type that supports **partial notes**) and `FieldNote`. `#[note]` derives the hash and nullifier with `poseidon2_hash_with_separator`; `#[custom_note]` lets you write them.

The `NoteHash` trait is the interface:

```
compute_note_hash(self, owner, storage_slot, randomness)
compute_nullifier(self, context, owner, note_hash_for_nullification)
compute_nullifier_unconstrained(self, owner, note_hash_for_nullification)
```

**Partial notes** are a `UintNote` whose private part (owner, randomness) is fixed in private and whose value is filled in later, possibly by a public function — the mechanism behind private-to-public payment flows. The completion publishes the value in clear; that is the point, and the privacy cost.

## Storage slots and siloing

Public:

```
siloed_storage_slot = H(contract_address, storage_slot)
```

Private — a "slot" is only a logical grouping mixed into the commitment, so that one account's balance cannot be confused with another's:

```
note_hash        = compute_note_hash(note, owner, storage_slot, randomness)
siloed_note_hash = H(contract_address, note_hash)            // kernel
note_nonce       = compute_note_hash_nonce(first_nullifier, note_index)
unique_note_hash = H(note_nonce, siloed_note_hash)           // what the tree stores
```

Randomness is what makes the commitment hiding: without it, an observer could enumerate `(owner, value)` pairs and invert the hash. Nullifiers are siloed by contract address too.

## Note delivery

Creating the note is not enough; the recipient needs its contents. Creation methods return a `NoteMessage` / `MaybeNoteMessage` on which you **must** call `.deliver()` or `.deliver_to()` — an undelivered message is lost forever (the compiler warns about the unused value).

| Mode | Where the ciphertext goes | Proving cost | Guarantee |
|---|---|---|---|
| `MessageDelivery::onchain_constrained()` | Ethereum blob (private log) | Highest | The encryption is proved: the recipient *can* decrypt |
| `MessageDelivery::onchain_unconstrained()` | Ethereum blob | Low | None: the sender is trusted to encrypt correctly |
| `MessageDelivery::offchain()` | Nowhere onchain — emitted as an offchain effect | Lowest, no DA cost | None; you must build the delivery channel |

Offchain delivery is extracted from the send result (`offchainMessages` in aztec.js) and handed to the recipient, who feeds it to the auto-generated `offchain_receive` utility function. It is the right choice when the sender is motivated to deliver — change notes to yourself, or a payment the recipient must receive before releasing goods.

A constrained delivery is the only one that makes "the recipient will be able to spend this" a property of the proof rather than of the sender's goodwill. It is also, by a wide margin, the most expensive thing a token transfer does.

> **A note copy addressed to a non-owner does not work onchain.** Discovery computes the note's nullifier, which needs the owner's nullifier key, so a PXE cannot process an onchain note message for a note it does not own. Auditor/observer copies have to go offchain, or be sent as an **event** instead — an event has no owner and no nullifier, so any recipient's PXE can process it.

## Note discovery: tagging

This is the part that changed most since the early tutorials. The PXE **does not** download every log and trial-decrypt it. Each private log begins with a **tag**, the node indexes logs by tag, and the recipient queries only the tags it can compute.

```
tag = poseidon2(secret, index)     // then siloed with the contract address by the kernel
```

`index` is a per-(sender, recipient, contract) counter. What differs between strategies is how the two parties come to share `secret`:

| Strategy | How the secret is established | Onchain trace | Can back constrained delivery |
|---|---|---|---|
| Arbitrary secret | Shared out of band, registered with the PXE | none | no |
| Address-derived | Diffie-Hellman between `ivsk` and the other party's address point | none | no |
| Non-interactive handshake | Sender publishes an ephemeral public key, encrypted to the recipient, tagged with the recipient's address | reveals *that* a handshake happened | yes |
| Interactive handshake | Same, but the recipient signs the ephemeral key at send time; nothing is published | none | yes |

Practical consequences:

- To discover address-derived notes from a stranger you must first **register the sender**: `await wallet.registerSender(addr)`. Notes to yourself always work — local accounts are implicit senders.
- The default for a new external recipient is the non-interactive handshake, which is why the first transaction between two parties costs more than the following ones.
- The `#[aztec]` macro injects a `sync_state` utility function; the PXE drives it. It fetches tagged logs, AES-decrypts (silently discarding what is not for you), dispatches by message type, then does **nonce discovery**: iterate the transaction's note hashes, compute the candidate nonce from `(first_nullifier, note_index)`, and keep the one that reproduces the unique note hash.
- The PXE scans a **sliding window** of tag indexes, from the highest index seen in a block older than `MAX_TX_LIFETIME` (24 h) up to 20 beyond the highest finalized one. A sender emitting a huge number of logs to the same recipient in the same contract in a short window can outrun it.

## Events and logs

- `#[event] struct Transfer { ... }`, then `self.emit(Transfer { ... })`.
- In **private**, the returned `EventMessage` must be delivered: `.deliver_to(addr, MessageDelivery::...)`, with the same three modes as notes. The same event can be delivered to several recipients with different modes.
- In **public**, `self.emit(event)` writes a plaintext log, like a Solidity event. `self.context.emit_public_log_unsafe(tag, data)` writes unstructured data; prefer the typed form, which tags for you.
- Private events, unlike notes, have no owner and no nullifier, which makes them the natural channel for telling a third party (an auditor, an indexer) what happened.

## Transaction lifecycle

1. **Simulate.** The wallet asks the PXE to execute the private functions. By default this runs in *kernelless* mode: the private bytecode is executed and the kernel outputs are computed in TypeScript rather than by running the kernel circuits — much faster, and it lets the wallet collect authwit requests without prompting for signatures.
2. **Prove.** `proveTx` runs the private kernel circuits and the Barretenberg backend over the simulation's witnesses. Private inputs never leave the client.
3. **Submit.** The transaction object — proof, nullifiers, note hashes, logs, enqueued public calls — goes to the mempool.
4. **Execute publicly.** The sequencer runs the enqueued public calls on the AVM and proves them.
5. **Roll up.** Block proofs are aggregated by the rollup circuits; the epoch proof is verified by the L1 rollup contract.

Each transaction is split into up to three **phases**:

- **Setup (non-revertible).** Fee bookkeeping: the fee payer is nominated with `set_as_fee_payer()`, `end_setup()` marks the boundary. Anything committed here stands even if the rest reverts — which is why the protocol restricts which public functions may be called here (an allowlist; ordinary token functions were removed from it in 4.2.0).
- **App (revertible).** The public call stack the private execution enqueued, plus whatever those calls enqueue. A revert here discards the phase's state changes — and the private side effects — but the setup-phase fee is still charged.
- **Teardown (optional).** Runs after the app phase with the final fee available, so an FPC can refund the unused part.

Two timing values matter to contract authors: the **anchor block** (the historical state private execution read) and the **expiration timestamp**, which is the earliest deadline imposed by anything read during private execution — the kernel keeps the minimum. `MAX_TX_LIFETIME` is 24 hours.

## Fees

| Ethereum | Aztec |
|---|---|
| gas | **mana** |
| fee per gas | Fee Juice per mana |
| fee (wei) | **Fee Juice** |

- Mana has two dimensions: **DA mana** (publishing data) and **L2 mana** (execution). `fee = daMana x feePerDaMana + l2Mana x feePerL2Mana`. The SDK still calls these `daGas` / `l2Gas`.
- **Fee Juice** is the native fee asset: bridged from Ethereum through the enshrined `FeeJuicePortal`, held as a **public** balance, **non-transferable**, spendable only on fees, with no withdrawal path.
- Bridging is deposit-on-L1 then claim-on-L2 (about two L2 blocks later) against a claim secret. A brand-new account can claim and pay for that same transaction, because the claim runs in the non-revertible setup phase.
- A **fee-paying contract (FPC)** is Aztec's paymaster: it declares itself fee payer and may charge the user in another token, usually against a signed quote and an authwit, collected during setup. The **Sponsored FPC** pays unconditionally and is what local networks, devnet and testnet use for free transactions.
- Fee payment is inherently public (someone's public Fee Juice balance decreases), which is the reason to use an FPC when the payer must stay private.

## Ethereum <-> Aztec messaging

Two enshrined L1 contracts, `Inbox` (L1 to L2) and `Outbox` (L2 to L1), plus application-specific **portal** contracts on L1.

**L1 to L2**

1. The portal calls `Inbox.sendL2Message(recipient, contentHash, secretHash)`, where the content hash is computed identically on both sides (share a Noir/Solidity library for it).
2. The proposer batches Inbox messages into a later L2 block — the message is **not** immediately available.
3. On L2, `context.consume_l1_to_l2_message(content_hash, [secret], portal, leaf_index)` consumes it and pushes a nullifier, so it cannot be consumed twice. Works in both private and public contexts. The secret is what keeps the L2 consumption unlinkable to the L1 deposit.

**L2 to L1**

1. On L2, `context.message_portal(portal, content)` inserts the message. Also available in both contexts.
2. The message becomes consumable on L1 only **after the epoch proof is submitted** — potentially a long wait if it was sent early in an epoch.
3. On L1, the portal calls `Outbox.consume(message, epoch, numCheckpointsInEpoch, leafIndex, path)`. Get the witness with `aztecNode.getL2ToL1MembershipWitness(txHash, computeL2ToL1MessageHash({...}))`.

A transaction may emit at most **8** L2-to-L1 messages, and their count is publicly visible.

## Limits and gotchas

Selected protocol constants (5.2.0, `noir-protocol-circuits/crates/types/src/constants.nr`):

| Constant | Value |
|---|---|
| `MAX_NOTE_HASHES_PER_TX` / `MAX_NULLIFIERS_PER_TX` | 64 |
| `MAX_NOTE_HASHES_PER_CALL` / `MAX_NULLIFIERS_PER_CALL` | 16 |
| `MAX_PRIVATE_CALL_STACK_LENGTH_PER_TX` / `..._PER_CALL` | 16 / 8 |
| `MAX_ENQUEUED_CALLS_PER_TX` | 32 |
| `MAX_PRIVATE_LOGS_PER_TX` / `..._PER_CALL` | 64 / 16 |
| `MAX_L2_TO_L1_MSGS_PER_TX` | 8 |
| `MAX_PUBLIC_DATA_READS_PER_TX` | 64 |
| `FUNCTION_TREE_HEIGHT` | 7, so 128 private functions per contract |

Things that bite:

- **`msg_sender` leaks on private-to-public calls** unless you use `enqueue_incognito`. The initial `msg_sender` is `-1`.
- **Side-effect counts are partly public.** Note hashes, nullifiers and private logs are padded, but the number of public calls and of L2-to-L1 messages is not: a distinctive count is a fingerprint.
- **The AVM supports only a subset of Noir's cryptography.** No ECDSA (secp256k1/r1), no AES-128, no Blake2s/Blake3 in public functions — hence the `AuthRegistry` pattern for public authorisation.
- **Circuits are fixed-size.** A loop bound of 16 costs 16 iterations' worth of constraints whether or not you use them. Sizing for the common case and recursing into an `#[only_self]` private function for the rest is the standard workaround (AIP-20's note-budget scheme does exactly this).
- **The stack is unaudited and partly under-constrained.** The documentation says so explicitly, and adds: do not put real secrets on an Aztec network yet.
- **Node queries leak.** Asking a third-party node whether a nullifier exists tells that node what you are interested in. Run your own node if this matters.

## Proving cost

Gate counts decide how long a user waits, and they are dominated by a handful of items:

| Item | Order of magnitude | Source |
|---|---|---|
| Fixed private-kernel overhead per transaction (init, reset, tail) | ~290,000 gates | framework docs, *Writing efficient contracts* |
| Each **nested private call** beyond the entrypoint, i.e. one more `private_kernel_inner` (an `#[only_self]` recursion step included) | ~101,000 gates | framework docs |
| One **constrained** message delivery (note or event) | ~20,200 gates | measured in this repository |
| One `DelayedPublicMutable` read (first one in the transaction) | ~4,000 gates | measured here |
| One `PublicImmutable` / historical tree read | ~3,500 gates | measured here |
| One additional note slot in a note-reading loop | ~3,050 gates | measured here |

`aztec profile gates ./target` gives per-function circuit sizes and **excludes** the kernel overhead; `aztec-wallet profile`, against a running network, gives the whole transaction. Public functions are AVM bytecode and cost mana, not gates — never quote a gate count for one.

Rules of thumb that follow: prefer library functions (`#[contract_library_method]`, inlined) over nested calls; do not pay for a constrained delivery where the recipient is motivated to deliver to itself; size note-reading loops for the common case; and measure before and after every "optimisation" — several plausible ones in this project turned out to be neutral or negative.

## Tooling and workflow

```bash
# install the toolchain (aztec, aztec-up, aztec-wallet, aztec-nargo, aztec-bb, bundled foundry)
VERSION=5.2.0 bash -i <(curl -sL https://install.aztec.network)
aztec-up install 5.2.0        # or `aztec-up use <version>` / `aztec-up list`

aztec start --local-network   # was `aztec start --sandbox` before 3.0
aztec-wallet import-test-accounts

aztec compile --workspace     # NOT `aztec-nargo compile`: that is a bare nargo and skips the AVM transpiler
aztec codegen -o src/artifacts target
aztec test                    # runs `aztec compile` first, then the Noir tests against the TXE
aztec profile gates ./target  # per-function circuit sizes, kernel overhead excluded
```

- **Node.js 24** is required by the JS packages.
- `Nargo.toml`, `package.json` and the installed CLI must all pin the **same** Aztec version; `aztec compile` warns when the `aztec-nr` tag and the CLI disagree.
- **Tests belong in a separate crate.** `aztec new` scaffolds a contract crate plus a `<name>_test` crate; a `#[test]` inside a contract crate makes `aztec compile` warn and invalidates the contract artifact on every test edit. A test crate imports the contract by package name and deploys it with `env.deploy("@my_crate/MyContract")`.
- The `TestEnvironment` (TXE) is Foundry-like: fast, mocked, no rollup circuits and no cross-chain messaging. Use `aztec.js` and a running local network for anything crossing those boundaries. Always `aztec test`, never `nargo test` — the latter has no oracle resolver.
- Logging: `LOG_LEVEL="error;trace:debug_log" aztec test` surfaces contract `debug_log` output.

## What changed since the early notes

| Older name or claim | Current (5.2.0) |
|---|---|
| `#[aztec(private)]`, then `#[private]` / `#[public]` | `#[external("private")]`, `#[external("public")]`, `#[external("utility")]` |
| Standalone `unconstrained` getters | Utility functions, `#[external("utility")] unconstrained fn` |
| `SharedMutable` | `DelayedPublicMutable` |
| Pedersen hash for note commitments | Poseidon2 (with domain separation) |
| "The PXE trial-decrypts every log" | Tag-indexed discovery; the PXE fetches only logs whose tag it can compute |
| `compute_note_hash_and_optionally_a_nullifier` injected into every contract | Gone; discovery is contract-side `sync_state` plus nonce discovery |
| Shield / unshield | Gone as protocol vocabulary; a token exposes explicit bridge entry points instead, named as AIP-20 does (`transfer_private_to_public`, `transfer_public_to_private`) |
| Four key pairs, outgoing viewing key in use | Six protocol key pairs; outgoing-viewing and tagging keys are **reserved and unused** |
| `nsk_m` (nullifier secret key) | `nhk_m` (nullifier hiding key), app-siloed as `nhk_app` |
| `aztec start --sandbox` | `aztec start --local-network` |
| `aztec-nargo compile` | `aztec compile` (`aztec-nargo` is a plain `nargo`, no AVM transpilation) |
| `bash -i <(curl -s install.aztec.network)`, Node 20 | `VERSION=x.y.z bash -i <(curl -sL https://install.aztec.network)`, Node 24 |
| Running two PXEs on one machine is broken | Works; see `scripts/multiple_pxe.ts` in this repository |

## Questions and answers

Questions asked while learning, with the answer as it stands at 5.2.0.

- **Can a private function read current public state?** No. It reads the anchor block's state. The only public value readable in private is a `DelayedPublicMutable` (or a `PublicImmutable`), and reading it constrains the transaction's expiry.
- **Is `unconstrained` the same as `view`?** No. `#[view]` is a constrained function that may not write state. A utility function is unconstrained, never part of a transaction, and *may* write local PXE state. A private function can contain `unsafe { }` blocks calling unconstrained code, whose results must then be constrained by the caller.
- **Can a user see another user's notes in the PXE?** One PXE can hold several accounts, and its keystore can decrypt all of them, so within one PXE the isolation is a `scopes` parameter chosen by the caller, not a protocol guarantee. This is a documented limitation ("limited private data authentication"). Tests that appear to read someone else's balance are usually a single-PXE artefact.
- **When someone sends me a note, do I learn who sent it?** Not from the protocol. Only if the contract puts the sender in a note field or an event. Note that the "sender" used for *tagging* is not necessarily the transaction sender, and a contract can override it with `with_sender`.
- **Can I burn someone else's tokens if the burn entry point has no authwit check?** Only if you can also produce their notes, which needs their nullifier key — but do not rely on that: add the authwit check, and be aware that in a single-PXE test every account's keys are available.
- **If I emit the same note to two parties, what do I use for the second encryption?** Not an outgoing viewing key — those are unused. Deliver the same message twice with `deliver_to(recipient, mode)`. But a *note* copy addressed to a non-owner cannot be processed onchain by that recipient's PXE (nullifier computation needs the owner's key); send it offchain, or send an **event** instead.
- **Will a user who was just frozen/blacklisted get one more transaction through?** With a delayed flag, yes: the change takes effect after the delay, and any transaction anchored before it and included before its expiry is valid. That is the price of making the flag privately readable.
- **Can I fast-forward time on a local network?** Yes, when its L1 is anvil. `RollupCheatCodes.advanceToSlot` / `advanceSlots` warp L1 time and mine, and an L2 slot derives from the L1 timestamp, so the clock a private function reads moves with it; `EthCheatCodes.syncDateProvider` then brings the client's own clock along, or every later transaction looks expired. The TXE has its own equivalent, `env.advance_next_block_timestamp_by` followed by `env.mine_block`. A real network has neither, so there the wait is unavoidable.
- **What happens to my notes if I change computer?** The PXE database is local. Losing it loses your notes unless you exported them, or they were delivered onchain — in which case a resynced PXE with the same keys can rediscover them. Offchain-delivered notes that you did not keep are gone.
- **Can I decide which notes to keep in my PXE?** Discovery is contract-side and customisable in principle, but there is no standard "reject this airdrop" flow today. The database grows with what you sync.
- **Do public transactions link back to the private proof?** Yes. An enqueued public call is visibly part of the same transaction as the private proof, and by default carries the caller's address as `msg_sender`.
- **Can I deploy my own verifier?** Yes, for your own proofs verified inside a contract — see the recursive-verification tutorial. The rollup's own verifier is enshrined on L1.

## Further reading

- [Aztec developer documentation](https://docs.aztec.network/) — and the [migration notes](https://docs.aztec.network/developers/docs/resources/migration_notes), which are the fastest way to find out what a release broke.
- [aztec-packages](https://github.com/AztecProtocol/aztec-packages) (protocol, contracts, TypeScript) and [aztec-nr](https://github.com/AztecProtocol/aztec-nr) (the Noir framework) at tag `v5.2.0` — the source is the specification.
- [Noir documentation](https://noir-lang.org/docs/) for the language itself.
- [aztec-standards](https://github.com/defi-wonderland/aztec-standards) — AIP-20 (fungible token), AIP-721, AIP-4626, escrow, generic proxy. The [CMTA fork](https://github.com/CMTA/aztec-standards) is pinned as a submodule here.
- Token contract tutorial: [docs](https://docs.aztec.network/developers/docs/tutorials/contract_tutorials/token_contract); wallet building: [wallet extension tutorial](https://docs.aztec.network/developers/docs/tutorials/js_tutorials/wallet-extension).
- [Privacy considerations](https://docs.aztec.network/developers/docs/resources/considerations/privacy_considerations) and [limitations](https://docs.aztec.network/developers/docs/resources/considerations/limitations) — read both before designing anything private.
- In this repository: `doc/README.md` (design and privacy analysis of the token), `doc/technical/cmtat-vs-aip20.md`, `doc/technical/token-module.md`, `doc/audits/tools/` (code-quality reviews with measured gate counts).
