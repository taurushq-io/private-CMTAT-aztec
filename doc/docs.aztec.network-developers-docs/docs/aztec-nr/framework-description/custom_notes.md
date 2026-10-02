# Custom notes

> Source: https://docs.aztec.network/developers/docs/aztec-nr/framework-description/custom_notes

---

- [![Home](https://docs.aztec.network/img/Aztec_Symbol_Dark.png)![Home](https://docs.aztec.network/img/Aztec%20Symbol_Light.png)](https://docs.aztec.network/)
- [Aztec.nr](https://docs.aztec.network/developers/docs/aztec-nr)
- Framework Description
- Custom notes

On this page
# Custom notes

This guide shows you how to create custom note types for storing specialized private data in your Aztec contracts.

## Prerequisites[​](#prerequisites)

- Basic understanding of [Aztec private state and notes](https://docs.aztec.network/developers/docs/foundational-topics/state_management)
- Aztec development environment set up

## When to create custom notes[​](#when-to-create-custom-notes)

You may want to create your own note type if you need to:

- Store specific data types not provided by built-in note libraries
- Combine multiple fields into a single note (e.g., game cards with multiple attributes)
- Implement custom nullifier schemes for advanced use cases

Built-in Note TypesAztec.nr provides pre-built note types for common use cases:

**UintNote** - For numeric values like token balances (supports partial notes):

```
# In Nargo.tomluint_note = { git="https://github.com/AztecProtocol/aztec-nr", tag="v5.2.0", directory="uint-note" }
```

**FieldNote** - For storing single Field values:

```
# In Nargo.tomlfield_note = { git="https://github.com/AztecProtocol/aztec-nr", tag="v5.2.0", directory="field-note" }
```

**AddressNote** - For storing Aztec addresses:

```
# In Nargo.tomladdress_note = { git="https://github.com/AztecProtocol/aztec-nr", tag="v5.2.0", directory="address-note" }
```

## Creating a custom note[​](#creating-a-custom-note)

Define your custom note with the `#[note]` macro:

nft_note_struct
```
use aztec::{macros::notes::note, protocol::traits::Packable};#[derive(Eq, Packable)]#[note]pub struct NFTNote {    pub token_id: Field,}
```

> [Source code: docs/examples/contracts/nft/src/nft.nr#L1-L9](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/contracts/nft/src/nft.nr#L1-L9)

The `#[note]` macro generates the following for your struct:

- `NoteType` trait - Provides a unique type ID for the note
- `NoteHash` trait - Handles note hash and nullifier computation
- `NoteProperties` - Enables field selection when querying notes

### Required traits[​](#required-traits)

Your note struct must derive:

- `Packable` - Required by the `#[note]` macro for note hash computation. You can manually implement this for tighter packing — see [Data Packing and Serialization](https://docs.aztec.network/developers/docs/aztec-nr/framework-description/data_packing).
- `Eq` - Required by storage types like `PrivateSet` for note comparisons

The `#[note]` macro handles the `NoteType`, `NoteHash`, and `NoteProperties` traits automatically.

### How note hashing works[​](#how-note-hashing-works)

When a note is inserted, the `#[note]` macro generates code that computes the note hash by combining:

1. **Your packed note data** - The fields you define in your struct
2. **Owner address** - Provided by the storage variable
3. **Storage slot** - Determined by the storage layout
4. **Randomness** - Generated automatically to prevent brute-force attacks

This happens automatically - you don't need to include owner or randomness fields in your struct.

## Using notes in storage[​](#using-notes-in-storage)

Notes are stored using `Owned<PrivateSet<...>>` which manages note ownership:

```
use aztec::{    macros::storage::storage,    state_vars::{Owned, PrivateSet},};#[storage]struct Storage<Context> {    // Collection of notes, indexed by owner    nfts: Owned<PrivateSet<NFTNote, Context>, Context>,}
```

### Inserting notes[​](#inserting-notes)

mint
```
#[external("private")]fn mint(to: AztecAddress, token_id: Field) {    assert(        self.storage.minter.read().eq(self.msg_sender()),        "caller is not the authorized minter",    );    // we create an NFT note and insert it to the PrivateSet - a collection of notes meant to be read in private    let new_nft = NFTNote { token_id };    self.storage.owners.at(to).insert(new_nft).deliver(MessageDelivery::onchain_constrained());    // calling the internal public function above to indicate that the NFT is taken    self.enqueue_self._mark_nft_exists(token_id, true);}
```

> [Source code: docs/examples/contracts/nft/src/main.nr#L50-L65](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/contracts/nft/src/main.nr#L50-L65)

### Reading and removing notes[​](#reading-and-removing-notes)

Use `pop_notes` to read and nullify notes atomically. This is the recommended pattern for most use cases:

burn
```
#[external("private")]fn burn(from: AztecAddress, token_id: Field) {    assert(        self.storage.minter.read().eq(self.msg_sender()),        "caller is not the authorized minter",    );    // from the NFTNote properties, selects token_id and compares it against the token_id to be burned    let options = NoteGetterOptions::new()        .select(NFTNote::properties().token_id, Comparator.EQ, token_id)        .set_limit(1);    let notes = self.storage.owners.at(from).pop_notes(options);    assert(notes.len() == 1, "NFT not found");    self.enqueue_self._mark_nft_exists(token_id, false);}
```

> [Source code: docs/examples/contracts/nft/src/main.nr#L75-L92](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/contracts/nft/src/main.nr#L75-L92)

warningThere's also a `get_notes` function that reads without nullifying, but use it with caution - the returned notes may have already been spent in another transaction.

## Custom note hashing[​](#custom-note-hashing)

Most notes should use the standard `#[note]` macro. Use `#[custom_note]` only when you need:

- Custom nullifier schemes (e.g., notes spendable by anyone with a secret, not tied to an owner)
- Partial notes that can be completed in public execution
- Non-standard hash computation for specific security requirements

With `#[custom_note]`, you must implement the `NoteHash` trait yourself:

```
use aztec::{    context::PrivateContext,    keys::getters::{get_nhk_app, get_public_keys, try_get_public_keys},    macros::notes::custom_note,    note::note_interface::NoteHash,    protocol::{        address::AztecAddress,        constants::{DOM_SEP__NOTE_HASH, DOM_SEP__NOTE_NULLIFIER},        hash::poseidon2_hash_with_separator,        traits::Packable,    },};#[derive(Eq, Packable)]#[custom_note]pub struct CustomHashNote {    pub data: Field,}impl NoteHash for CustomHashNote {    fn compute_note_hash(        self,        owner: AztecAddress,        storage_slot: Field,        randomness: Field,    ) -> Field {        // Custom hash computation        poseidon2_hash_with_separator(            [self.data, owner.to_field(), storage_slot, randomness],            DOM_SEP__NOTE_HASH,        )    }    fn compute_nullifier(        self,        context: &mut PrivateContext,        owner: AztecAddress,        note_hash_for_nullification: Field,    ) -> Field {        // Standard nullifier using owner's nullifier hiding key        let owner_npk_m_hash = get_public_keys(owner).npk_m_hash;        let secret = context.request_nhk_app(owner_npk_m_hash);        poseidon2_hash_with_separator(            [note_hash_for_nullification, secret],            DOM_SEP__NOTE_NULLIFIER,        )    }    unconstrained fn compute_nullifier_unconstrained(        self,        owner: AztecAddress,        note_hash_for_nullification: Field,    ) -> Option<Field> {        try_get_public_keys(owner).map(|public_keys| {            let secret = get_nhk_app(public_keys.npk_m_hash);            poseidon2_hash_with_separator(                [note_hash_for_nullification, secret],                DOM_SEP__NOTE_NULLIFIER,            )        })    }}
```

Naming noteThe secret returned by `request_nhk_app` is the **nullifier hiding key** (abbreviated `nhk`). Older docs and code comments may call it the "nullifier secret key" (`nsk`) — these refer to the same key. Always use `request_nhk_app()` rather than computing this key yourself.

## Viewing notes (unconstrained)[​](#viewing-notes-unconstrained)

For read-only queries without constraints:

view_notes
```
#[external("utility")]unconstrained fn get_private_nfts(owner: AztecAddress, page_index: u32) -> ([Field; MAX_NOTES_PER_PAGE], bool) {    let offset = page_index * MAX_NOTES_PER_PAGE;    let options = NoteViewerOptions::new().set_offset(offset);    let notes = self.storage.private_nfts.at(owner).view_notes(options);    let mut owned_nft_ids = [0; MAX_NOTES_PER_PAGE];    for i in 0..options.limit {        if i < notes.len() {            owned_nft_ids[i] = notes.get_unchecked(i).token_id;        }    }    let page_limit_reached = notes.len() == options.limit;    (owned_nft_ids, page_limit_reached)}
```

> [Source code: noir-projects/noir-contracts/contracts/app/nft_contract/src/main.nr#L255-L272](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/noir-projects/noir-contracts/contracts/app/nft_contract/src/main.nr#L255-L272)

## Further reading[​](#further-reading)

- [What the `#[note]` macro does](https://docs.aztec.network/developers/docs/aztec-nr/framework-description/functions/attributes#implementing-notes)
- [Note getter options](https://docs.aztec.network/developers/docs/aztec-nr/framework-description/advanced/how_to_retrieve_filter_notes)
- [Storage types](https://docs.aztec.network/developers/docs/foundational-topics/state_management)
- [Macros reference](https://docs.aztec.network/developers/docs/aztec-nr/framework-description/macros)

**Tags:**
- [smart contracts](https://docs.aztec.network/developers/tags/smart-contracts)
- [notes](https://docs.aztec.network/developers/tags/notes)
- [privacy](https://docs.aztec.network/developers/tags/privacy)

[Edit this page](https://github.com/AztecProtocol/aztec-packages/edit/next/docs/docs-developers/docs/aztec-nr/framework-description/custom_notes.md)