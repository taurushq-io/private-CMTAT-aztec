# Note Discovery

> Source: https://docs.aztec.network/developers/docs/foundational-topics/advanced/storage/note_discovery

---

- [![Home](https://docs.aztec.network/img/Aztec_Symbol_Dark.png)![Home](https://docs.aztec.network/img/Aztec%20Symbol_Light.png)](https://docs.aztec.network/)
- [Foundational Topics](https://docs.aztec.network/developers/docs/foundational-topics)
- Advanced Topics
- Advanced Storage Concepts
- Note Discovery

On this page
# Note Discovery

Note discovery refers to the process of a user identifying and decrypting [notes](https://docs.aztec.network/developers/docs/foundational-topics/state_management#notes) that belong to them.

## Alternative approaches[​](#alternative-approaches)

Other protocols have explored different note discovery mechanisms. **Brute force** approaches download all notes and trial-decrypt each one, but this becomes prohibitively expensive as networks grow. **Offchain communication** has the sender share note content directly with recipients, avoiding onchain costs but introducing reliance on side channels. Aztec apps can use offchain communication if they wish, but the default mechanism is note tagging.

## Note tagging[​](#note-tagging)

Aztec uses note tagging as its default discovery mechanism. When creating a note, the sender *tags* the log with a value that only the sender and recipient can identify. This allows recipients to efficiently query for relevant logs without downloading and attempting to decrypt everything.

### How it works[​](#how-it-works)

#### Every log has a tag[​](#every-log-has-a-tag)

In Aztec, each emitted log is an array of fields, e.g. `[tag, x, y, z]`. The first field is a *tag* used to index and identify logs. The Aztec node indexes logs by their tag and exposes an API (`getPrivateLogsByTags()`) that retrieves logs matching specific tags.

#### Tag derivation[​](#tag-derivation)

Every tag is derived the same way: `poseidon2(secret, index)`.

What varies is how the sender and recipient come to share `secret`. This is the [tagging secret strategy](https://docs.aztec.network/developers/docs/aztec-nr/framework-description/note_delivery#tagging-secret-strategy), chosen by the wallet by default, though a contract can [override it at delivery](https://docs.aztec.network/developers/docs/aztec-nr/framework-description/note_delivery#overriding-the-strategy-from-the-contract).

There are four strategies, described below. They differ only in how `secret` is established. Once `secret` exists, the tag is derived from it the same way for all four.

##### Arbitrary secret[​](#arbitrary-secret)

Two parties that already share a secret point out of band can use it directly. PXE app-siloes the point to the contract (`poseidon2(point.x, point.y, contract)`) and then folds in the recipient (`poseidon2(appSecret, recipient)`) to make the secret directional, so tags from Alice to Bob differ from tags from Bob to Alice. The recipient registers the secret point with their PXE so it can scan for the resulting tags. This leaves no onchain trace, but nothing onchain backs the secret, so it cannot be used for [constrained delivery](https://docs.aztec.network/developers/docs/aztec-nr/framework-description/note_delivery#tagging-secret-strategy).

##### Address-derived secret[​](#address-derived-secret)

An address-derived secret is the same, except the shared secret point is computed instead of supplied. The sender and recipient each derive it via Diffie-Hellman on the Grumpkin curve from their own [incoming viewing secret key](https://docs.aztec.network/developers/docs/foundational-topics/accounts/keys#incoming-viewing-keys) (`ivsk`) and the other party's address point: `S = (preaddress + ivsk) × AddressPoint`. The app-siloing and directional fold are then identical. Because the point comes from the parties' addresses, the recipient registers the sender's address with their PXE (rather than a secret point) so it can compute the tags. Like an arbitrary secret, it cannot back [constrained delivery](https://docs.aztec.network/developers/docs/aztec-nr/framework-description/note_delivery#tagging-secret-strategy).

##### Non-interactive handshake[​](#non-interactive-handshake)

To establish a handshake, the sender publishes an ephemeral public key onchain, encrypted to the recipient, under a log tagged with the recipient's address. During sync the recipient scans for handshakes addressed to them, decrypts the ephemeral key, and derives the shared secret via Diffie-Hellman against their own `ivsk`. Because that secret is already derived against the recipient, it is app-siloed to the contract but left bare, with no directional fold.

This lets the recipient discover messages from a sender they never registered, at the cost of publishing onchain that a handshake was made with them. It is the default for reaching a new external recipient, and unlike an address-derived or arbitrary secret it can back [constrained delivery](https://docs.aztec.network/developers/docs/aztec-nr/framework-description/note_delivery#tagging-secret-strategy).

##### Interactive handshake[​](#interactive-handshake)

An interactive handshake derives the same kind of shared secret from an ephemeral key, but the ephemeral key is never published: instead of announcing it onchain, the recipient must be reachable at send time to sign it. The registry requests that signature through the custom request oracle and verifies it in-circuit, so the send fails if the recipient does not answer. The recipient learns the ephemeral key while signing and registers the resulting secret with their PXE so it can scan for the tags. As with a non-interactive handshake, the secret is app-siloed to the contract but left bare, with no directional fold.

This reveals nothing onchain about the recipient, and like a non-interactive handshake it can back [constrained delivery](https://docs.aztec.network/developers/docs/aztec-nr/framework-description/note_delivery#tagging-secret-strategy). Because it requires the recipient's cooperation at send time, it is never the default: a wallet or contract opts in explicitly.

##### Deriving the tag from the secret[​](#deriving-the-tag-from-the-secret)

Whichever strategy produced it, the resulting app-siloed tagging secret is turned into a tag the same way:

The tagging secret is hashed with an index, a counter that increments for each log the sender emits to this recipient in this contract: `poseidon2(secret, index)`. When the log is emitted, the protocol kernel **siloes** the resulting tag with the contract address before it appears onchain. This siloed tag is what the node stores and indexes. Both the sender and recipient can independently compute the siloed tags and use them to query the node.

#### The sender in note tagging[​](#the-sender-in-note-tagging)

The "sender" in note tagging is **not necessarily the transaction sender**. It's the **sender for tags**, which the wallet supplies as a default (typically the originating account address). Contracts can override this at message delivery by using `with_sender`, for both constrained and unconstrained delivery, e.g. `MessageDelivery::onchain_constrained().with_sender(address)`.

#### Registering known senders[​](#registering-known-senders)

To discover notes from a particular sender via an [address-derived secret](#address-derived-secret), the recipient's PXE must know the sender's address in advance so it can compute the shared tagging secret. Register senders using the wallet API:

```
// Register a sender so your PXE can discover notes from themawait wallet.registerSender(senderAddress);
```

Notes sent to yourself are always discoverable — the PXE automatically adds all local accounts as implicit senders.

### The sync process[​](#the-sync-process)

The `#[aztec]` macro automatically injects an unconstrained `sync_state` utility function into every contract. This function is invoked by the PXE during note syncing to orchestrate discovery via oracles; manual execution is forbidden by the PXE to prevent inconsistencies. The process works as follows:

1. **Fetch tagged logs**: The contract calls the `fetchTaggedLogs` oracle. The PXE computes tags for every secret it can use for this recipient, queries the node for matching logs, and returns them to the contract.
2. **Decrypt**: For each log, the contract strips the tag and attempts AES-128 decryption using a symmetric key derived from the recipient's private key (via ECDH). Logs that don't decrypt are silently discarded (they were not intended for this recipient).
3. **Parse message type**: Successfully decrypted messages are dispatched by type — private notes, partial notes, or private events.
4. **Nonce discovery** (for notes): To confirm a decrypted note is valid, the system must match it against the unique note hashes emitted in the same transaction. It iterates the note hashes in the transaction, computes candidate nonces using `compute_note_hash_nonce(first_nullifier, note_index)` (a domain-separated Poseidon2 hash), and checks whether recomputing the unique note hash with each candidate nonce produces a match. A match confirms the note was emitted in this transaction and provides the nonce needed to later nullify it. (Note hash tree inclusion is validated separately.)
5. **Store**: Validated notes are added to the PXE database, making them available for use in future transactions.

Developers don't need to implement any of this manually — the `#[aztec]` macro handles it. However, since the discovery logic lives in contract code (called via oracles to the PXE), users can customize or replace the discovery mechanism to suit their needs.

#### The sliding window algorithm[​](#the-sliding-window-algorithm)

The PXE doesn't scan all possible tag indexes — it uses a window-based approach to efficiently find new logs:

- It tracks the **highest aged index**: the highest tag index seen in a block at least 24 hours old (`MAX_TX_LIFETIME`). Once a block is this old, no new transactions can reference it as an anchor, so no new logs can appear at or below that index.
- It tracks the **highest finalized index**: the highest tag index seen in any finalized block.
- It scans from the aged index to 20 indexes beyond the finalized index, covering both recent and in-flight logs.

This means there's a practical limit on how many logs a single sender can emit to the same recipient in the same contract within a short time period. For most applications this limit is not a concern.

### Limitations and solutions[​](#limitations-and-solutions)

#### You cannot receive address-derived tagged notes from an unknown sender[​](#you-cannot-receive-address-derived-tagged-notes-from-an-unknown-sender)

When the tag's secret is [address-derived](#address-derived-secret), you cannot compute it without knowing the sender's address, so you cannot discover those notes from a sender you haven't registered. This is a limitation of address-derived tagging, not of tagging in general.

There are three broad families of solutions to this problem:

**a) Brute force search** - Scan every single log and test if it decrypts. This has obvious performance issues as the network grows and becomes prohibitively expensive.

**b) Tagging with known sender** - You know who will send you messages and search for those specifically. This is very fast and allows you to remove senders who spam you. However, it cannot be constrained, i.e., it cannot guarantee that the recipient will find the message. It also requires registering each sender's address in advance with `wallet.registerSender(address)`, so you must learn that address first.

**c) Tagging with a handshake** - The sender and recipient establish a handshake to agree on a tagging secret, after which regular tagging works: the recipient can discover messages without having registered the sender in advance. A non-interactive handshake is published onchain, so it needs nothing from the recipient, but it reveals that someone did a handshake with them. An interactive handshake reveals nothing onchain; in exchange, the recipient must sign it at send time. By default the wallet determines the type of handshake to use, though a contract can override the choice at delivery (see [tagging secret strategy](https://docs.aztec.network/developers/docs/aztec-nr/framework-description/note_delivery#tagging-secret-strategy)).

See the [Note Delivery](https://docs.aztec.network/developers/docs/aztec-nr/framework-description/note_delivery) documentation for more details on how the sender is used when delivering notes.

## Advanced cryptography techniques[​](#advanced-cryptography-techniques)

Beyond the tagging system described above, there are more advanced cryptographic techniques for note discovery:

- **Oblivious message retrieval (OMR)**: Allows retrieving messages without the server knowing which messages were accessed
- **Private information retrieval (PIR)**: Enables querying a database without revealing which records you're interested in

These techniques would solve a privacy leak that exists with the current tagging system: when your PXE queries an Aztec node for logs with specific tags, the node can observe your IP address and correlate it with which tags (and therefore which transactions) you're interested in. Even though the logs are encrypted, this network-level metadata can leak information about your activity.

OMR and PIR would eliminate this issue by allowing you to retrieve your logs without the node knowing which ones you requested. However, these methods are currently impractical in production due to computational costs. They represent a long-term goal for achieving stronger privacy guarantees.

**Tags:**
- [storage](https://docs.aztec.network/developers/tags/storage)
- [concepts](https://docs.aztec.network/developers/tags/concepts)
- [advanced](https://docs.aztec.network/developers/tags/advanced)
- [notes](https://docs.aztec.network/developers/tags/notes)

[Edit this page](https://github.com/AztecProtocol/aztec-packages/edit/next/docs/docs-developers/docs/foundational-topics/advanced/storage/note_discovery.md)