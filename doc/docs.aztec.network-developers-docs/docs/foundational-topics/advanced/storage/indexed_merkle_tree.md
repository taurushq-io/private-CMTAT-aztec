# Indexed Merkle Tree (Nullifier Tree)

> Source: https://docs.aztec.network/developers/docs/foundational-topics/advanced/storage/indexed_merkle_tree

---

- [![Home](https://docs.aztec.network/img/Aztec_Symbol_Dark.png)![Home](https://docs.aztec.network/img/Aztec%20Symbol_Light.png)](https://docs.aztec.network/)
- [Foundational Topics](https://docs.aztec.network/developers/docs/foundational-topics)
- Advanced Topics
- Advanced Storage Concepts
- Indexed Merkle Tree (Nullifier Tree)

On this page
# Indexed Merkle Tree (Nullifier Tree)

## Prerequisites[​](#prerequisites)

This page assumes familiarity with:

- Merkle trees and membership proofs
- The UTXO model for private state
- Zero-knowledge proof concepts (circuits, constraints)

## Overview[​](#overview)

This page covers indexed merkle trees and how they improve nullifier tree performance in circuits, including:

- Why nullifier trees are necessary
- How indexed merkle trees work
- Membership exclusion proofs
- Batch insertions
- Tradeoffs

This content was presented to the [Privacy + Scaling Explorations team at the Ethereum Foundation](https://pse.dev/).

## Primer on Nullifier Trees[​](#primer-on-nullifier-trees)

Privacy in public blockchains requires a UTXO model. State is stored in encrypted UTXOs in merkle trees. Since updating state directly leaks information, we simulate updates by "destroying" old UTXOs and creating new ones, resulting in an append-only merkle tree.

A classic merkle tree:

![Classic merkle tree structure showing leaf nodes hashed up to a root](https://docs.aztec.network/assets/ideal-img/normal-merkle-tree.568bc10.640.png)
To destroy state, a "nullifier" tree stores deterministic values linked to notes in the append-only tree. This is typically implemented as a sparse Merkle Tree.

A sparse merkle tree (not every leaf stores a value):

![Sparse merkle tree with empty leaves represented as zeros](https://docs.aztec.network/assets/ideal-img/sparse-merkle-tree.59ba475.640.png)
To spend or modify a note in the private state tree, you must create a nullifier and prove it does not already exist in the nullifier tree. Since nullifier trees are modeled as sparse merkle trees, non-membership checks are conceptually trivial.

Data is stored at the leaf index corresponding to its value. For example, in a sparse tree containing 22562^{256}2256 values, to prove non-membership of value 21282^{128}2128:

- Prove tree_values[2128]=0tree\_values[2^{128}] = 0tree_values[2128]=0 via a merkle membership proof (value does not exist)
- Conversely, prove tree_values[2128]==1tree\_values[2^{128}] == 1tree_values[2128]==1 to show the item exists

## Problems introduced by using Sparse Merkle Trees for Nullifier Trees[​](#problems-introduced-by-using-sparse-merkle-trees-for-nullifier-trees)

While sparse Merkle Trees offer a simple solution, they have significant drawbacks. A sparse nullifier tree must have an index for e∈Fpe \in \mathbb{F}_pe∈Fp​, which for the bn254 curve requires a depth of 254.

A tree of depth 254 means 254 hashes per membership proof. Each nullifier insertion requires a non-membership check followed by an insertion—two trips from leaf to root. This results in 254×2254 \times 2254×2 hashes per insertion. Since the tree is sparse, insertions are random and must be sequential, so hash count scales linearly with nullifier count. This causes constraint counts in rollup circuits to grow rapidly, leading to long proving times.

## Indexed Merkle Tree Constructions[​](#indexed-merkle-tree-constructions)

[This paper](https://eprint.iacr.org/2021/1263.pdf) (page 6) introduces indexed merkle trees, which enable efficient non-membership proofs. Each node stores a value v∈Fpv \in \mathbb{F}_pv∈Fp​ and pointers to the leaf with the next higher value:

leaf={v,inext,vnext}.\textsf{leaf} = \{v, i_{\textsf{next}}, v_{\textsf{next}}\}.leaf={v,inext​,vnext​}.
Based on the tree's insertion rules, no leaves exist between the range (v,vnext)(v, v_{\textsf{next}})(v,vnext​).

The merkle tree forms a linked list of increasing values. Once inserted, a leaf's pointers can change but its nullifier value cannot.

Since leaves are no longer positioned at (index==value)(index == value)(index==value), a deep tree is unnecessary—32 levels suffice. This improves insertions by approximately 8x (256/32)(256 / 32)(256/32).

*The node that provides the non-membership check is called a "low nullifier".*

The insertion protocol:

1. Look for a nullifier's corresponding low_nullifier where:

low_nullifiernext_value>new_nullifierlow\_nullifier_{\textsf{next\_value}} > new\_nullifierlow_nullifiernext_value​>new_nullifier

> if new_nullifiernew\_nullifiernew_nullifier is the largest use the leaf:

low_nullifiernext_value==0low\_nullifier_{\textsf{next\_value}} == 0low_nullifiernext_value​==0
2. Perform membership check of the low nullifier.
3. Perform a range check on the low nullifier's value and next_value fields:

new_nullifier>low_nullifiervalue &&(new_nullifier<low_nullifiernext_value ∣∣ low_nullifiernext_value==0)\begin{aligned}
new\_nullifier &> low\_nullifier_{\textsf{value}} \: \&\& \\
&( new\_nullifier < low\_nullifier_{\textsf{next\_value}} \: || \:  low\_nullifier_{\textsf{next\_value}} == 0 )
\end{aligned}new_nullifier​>low_nullifiervalue​&&(new_nullifier<low_nullifiernext_value​∣∣low_nullifiernext_value​==0)​

1. Update the low nullifier pointers

low_nullifiernext_index=new_insertion_indexlow\_nullifier_{\textsf{next\_index}} = new\_insertion\_indexlow_nullifiernext_index​=new_insertion_index
low_nullifiernext_value=new_nullifierlow\_nullifier_{\textsf{next\_value}} = new\_nullifierlow_nullifiernext_value​=new_nullifier
2. Perform insertion of new updated low nullifier (yields new root)
3. Update pointers on new leaf. Note: low_nullifier is from before update in step 4

new_nullifier_leafvalue=new_nullifiernew\_nullifier\_leaf_{\textsf{value}} = new\_nullifiernew_nullifier_leafvalue​=new_nullifier
new_nullifier_leafnext_value=low_nullifiernext_valuenew\_nullifier\_leaf_{\textsf{next\_value}} = low\_nullifier_{\textsf{next\_value}}new_nullifier_leafnext_value​=low_nullifiernext_value​
new_nullifier_leafnext_index=low_nullifiernext_indexnew\_nullifier\_leaf_{\textsf{next\_index}} = low\_nullifier_{\textsf{next\_index}}new_nullifier_leafnext_index​=low_nullifiernext_index​

1. Perform insertion of new leaf (yields new root)

### Insertion constraints[​](#insertion-constraints)

- `3n` hashes of 2 field elements (where `n` is the height of the tree)
- `3` hashes of 3 field elements
- `2` range checks
- A handful of equality constraints

### Special cases[​](#special-cases)

At step 3, low_nullifiernext_valuelow\_nullifier_{\textsf{next\_value}}low_nullifiernext_value​ can be 0. When a value is the maximum, it points to zero instead of a larger value (which does not exist). This closes the loop so insertions always occur within a ring, preventing splits.

### Insertion example[​](#insertion-example)

1. Initial state

![Indexed merkle tree initial state with single zero node](https://docs.aztec.network/assets/ideal-img/index-merkle-tree-1.37958ac.640.png)

1. Add a new value v=30v=30v=30

![Indexed merkle tree after inserting value 30](https://docs.aztec.network/assets/ideal-img/index-merkle-tree-2.163e5a0.640.png)

1. Add a new value v=10v=10v=10

![Indexed merkle tree after inserting value 10](https://docs.aztec.network/assets/ideal-img/index-merkle-tree-3.1b3a664.640.png)

1. Add a new value v=20v=20v=20

![Indexed merkle tree after inserting value 20](https://docs.aztec.network/assets/ideal-img/index-merkle-tree-4.4a71048.640.png)

1. Add a new value v=50v=50v=50

![Indexed merkle tree after inserting value 50](https://docs.aztec.network/assets/ideal-img/index-merkle-tree-5.29c1da5.640.png)
The diagrams show how pointers update between each insertion.

Note: The first node (value 0) is pre-populated, so the first insertion goes into the second index.

### Non-membership proof[​](#non-membership-proof)

To prove value `20` does not exist, reveal the leaf that "steps over" `20`—the leaf whose value is less than `20` and whose next value is greater than `20`. This is the `low_nullifier`.

- Hash the low nullifier: low_nullifier=h(10,1,30)low\_nullifier = h(10, 1, 30)low_nullifier=h(10,1,30)
- Prove the low leaf exists in the tree: `n` hashes
- Check the new value would have belonged in the range given by the low leaf: `2` range checks

  - If (low_nullifiernext_index==0low\_nullifier_{\textsf{next\_index}} == 0low_nullifiernext_index​==0):

    - Special case, the low leaf is at the very end, so the new_value must be higher than all values in the tree:
    - assert(low_nullifiervalue<new_valuevalue)assert(low\_nullifier_{\textsf{value}} < new\_value_{\textsf{value}})assert(low_nullifiervalue​<new_valuevalue​)
  - Else:

    - assert(low_nullifiervalue<new_valuevalue)assert(low\_nullifier_{\textsf{value}} < new\_value_{\textsf{value}})assert(low_nullifiervalue​<new_valuevalue​)
    - assert(low_nullifiernext_value>new_valuevalue)assert(low\_nullifier_{\textsf{next\_value}} > new\_value_{\textsf{value}})assert(low_nullifiernext_value​>new_valuevalue​)

This provides significant performance improvement, but since the tree is not sparse, we can also perform batch insertions.

## Batch insertions[​](#batch-insertions)

Since nullifiers are inserted deterministically (append-only), we can insert entire subtrees rather than appending nodes individually. However, for every node inserted, low nullifier pointers must be updated. This adds complexity when the low nullifier exists within the subtree being inserted. All impacted low nullifiers must be updated before the subtree insertion.

Batch insertion in an append-only merkle tree:

1. Prove the target subtree consists of all empty values
2. Calculate the root of an empty subtree and perform an inclusion proof for this empty root
3. Recreate the subtree within the circuit
4. Use the same sibling path to get the new root after subtree insertion

In the following example, a subtree of size 4 is inserted. The subtree is greyed out as "pending".

**Legend**:

- Green: New Inserted Value
- Orange: Low Nullifier

**Example**

1. Prepare to insert subtree [35,50,60,15][35,50,60,15][35,50,60,15]

![Preparing to insert subtree with values 35, 50, 60, 15](https://docs.aztec.network/assets/ideal-img/subtree-insert-1.04d9287.640.png)

1. Update low nullifier for new nullifier 353535

![Updating low nullifier for value 35](https://docs.aztec.network/assets/ideal-img/subtree-insert-2.92b8e75.640.png)

1. Update low nullifier for new nullifier 505050 (the low nullifier exists within the pending insertion subtree)

![Updating low nullifier for value 50 from pending subtree](https://docs.aztec.network/assets/ideal-img/subtree-insert-3.e86f005.640.png)

1. Update low nullifier for new nullifier 606060

![Updating low nullifier for value 60](https://docs.aztec.network/assets/ideal-img/subtree-insert-4.9375e53.640.png)

1. Update low nullifier for new nullifier 151515

![Updating low nullifier for value 15](https://docs.aztec.network/assets/ideal-img/subtree-insert-5.0bc9b9a.640.png)

1. Update pointers for new nullifier 151515

![Updating pointers for value 15](https://docs.aztec.network/assets/ideal-img/subtree-insert-6.169ec0e.640.png)

1. Insert subtree

![Final state after subtree insertion](https://docs.aztec.network/assets/ideal-img/subtree-insert-7.740d73d.640.png)

### Performance gains from subtree insertion[​](#performance-gains-from-subtree-insertion)

Sparse nullifier tree insertions require 1 non-membership check (254 hashes) and 1 insertion (254 hashes). For 4 values: 2032 hashes.

In a depth-32 indexed tree, each subtree insertion costs 1 non-membership check (32 hashes) and 1 pointer update (32 hashes) per value, plus subtree construction (~67 hashes). Total: 327 hashes—a significant efficiency gain.

*Range check constraint costs are negligible compared to hash costs.*

## Performing subtree insertions in a circuit context[​](#performing-subtree-insertions-in-a-circuit-context)

A challenge arises when the low nullifier for a value exists within the subtree being inserted. In this case, you cannot perform a non-membership check against the tree root because the leaf needed for non-membership has not yet been inserted. These are called "pending" insertions.

**Circuit Inputs**

- `new_nullifiers`: `fr[]`
- `low_nullifier_leaf_preimages`: `tuple of {value: fr, next_index: fr, next_value: fr}`
- `low_nullifier_membership_witnesses`: A sibling path and a leaf index of low nullifier
- `current_nullifier_tree_root`: Current root of the nullifier tree
- `next_insertion_index`: `fr`, the tip of the nullifier tree
- `subtree_insertion_sibling_path`: A sibling path to check the subtree against the root

If the low nullifier does not yet exist in the tree, membership checks fail and no non-membership proof can be produced. To handle this, the circuit must track all values pending insertion:

- If `low_nullifier_membership_witness` is invalid (all zeros or leaf index of -1), this indicates a pending low nullifier read request
- Loop through all pending insertions to find one with value lower than the nullifier being inserted
- If no matching pending insertion is found, the circuit is invalid

Pseudocode with pending insertion handling:

```
auto empty_subtree_hash = SOME_CONSTANT_EMPTY_SUBTREE;auto pending_insertion_subtree = [];auto insertion_index = inputs.next_insertion_index;auto root = inputs.current_nullifier_tree_root;// Check nothing exists where we would insert our subtreeassert(membership_check(root, empty_subtree_hash, insertion_index >> subtree_depth, inputs.subtree_insertion_sibling_path));for (i in len(new_nullifiers)) {    auto new_nullifier = inputs.new_nullifiers[i];    auto low_nullifier_leaf_preimage = inputs.low_nullifier_leaf_preimages[i];    auto low_nullifier_membership_witness = inputs.low_nullifier_membership_witnesses[i];    if (low_nullifier_membership_witness is garbage) {        bool matched = false;        // Search for the low nullifier within our pending insertion subtree        for (j in range(0, i)) {            auto pending_nullifier = pending_insertion_subtree[j];            if (pending_nullifier.is_garbage()) continue;            if (pending_nullifier[j].value < new_nullifier && (pending_nullifier[j].next_value > new_nullifier || pending_nullifier[j].next_value == 0)) {                // Found matching low nullifier                matched = true;                // Update pointers                auto new_nullifier_leaf = {                    .value = new_nullifier,                    .next_index = pending_nullifier.next_index,                    .next_value = pending_nullifier.next_value                }                // Update pending subtree                pending_nullifier.next_index = insertion_index;                pending_nullifier.next_value = new_nullifier;                pending_insertion_subtree.push(new_nullifier_leaf);                break;            }        }        // could not find a matching low nullifier in the pending insertion subtree        assert(matched);    } else {        // Membership check for low nullifier        assert(perform_membership_check(root, hash(low_nullifier_leaf_preimage), low_nullifier_membership_witness));        // Range check low nullifier against new nullifier        assert(new_nullifier < low_nullifier_leaf_preimage.next_value || low_nullifier_leaf.next_value == 0);        assert(new_nullifier > low_nullifier_leaf_preimage.value);        // Update new nullifier pointers        auto new_nullifier_leaf = {            .value = new_nullifier,            .next_index = low_nullifier_preimage.next_index,            .next_value = low_nullifier_preimage.next_value        };        // Update low nullifier pointers        low_nullifier_preimage.next_index = next_insertion_index;        low_nullifier_preimage.next_value = new_nullifier;        // Update state vals for next iteration        root = update_low_nullifier(low_nullifier, low_nullifier_membership_witness);        pending_insertion_subtree.push(new_nullifier_leaf);    }    next_insertion_index += 1;}// insert subtreeroot = insert_subtree(root, inputs.next_insertion_index >> subtree_depth, pending_insertion_subtree);
```

## Drawbacks[​](#drawbacks)

While indexed merkle trees provide significant circuit performance improvements, they increase computation and storage requirements for nodes. Finding the "low nullifier" for a non-membership proof requires searching existing nodes—a naive implementation uses brute force. Performance improves if nodes maintain a sorted data structure of existing nullifiers, though this increases storage footprint.

## Related resources[​](#related-resources)

- [State Management](https://docs.aztec.network/developers/docs/foundational-topics/state_management) - How public and private state work, including nullifiers
- [Circuits](https://docs.aztec.network/developers/docs/foundational-topics/advanced/circuits) - Core protocol circuits where indexed merkle trees are used
- [Note Discovery](https://docs.aztec.network/developers/docs/foundational-topics/advanced/storage/note_discovery) - How private notes are discovered and managed
- [Original paper](https://eprint.iacr.org/2021/1263.pdf) - Academic reference for indexed merkle trees

**Tags:**
- [storage](https://docs.aztec.network/developers/tags/storage)
- [concepts](https://docs.aztec.network/developers/tags/concepts)
- [advanced](https://docs.aztec.network/developers/tags/advanced)

[Edit this page](https://github.com/AztecProtocol/aztec-packages/edit/next/docs/docs-developers/docs/foundational-topics/advanced/storage/indexed_merkle_tree.mdx)