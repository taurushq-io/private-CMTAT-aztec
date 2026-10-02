# Outbox

> Source: https://docs.aztec.network/developers/docs/foundational-topics/ethereum-aztec-messaging/outbox

---

- [![Home](https://docs.aztec.network/img/Aztec_Symbol_Dark.png)![Home](https://docs.aztec.network/img/Aztec%20Symbol_Light.png)](https://docs.aztec.network/)
- [Foundational Topics](https://docs.aztec.network/developers/docs/foundational-topics)
- [Aztec<>Ethereum Messaging](https://docs.aztec.network/developers/docs/foundational-topics/ethereum-aztec-messaging)
- Outbox

On this page
# Outbox

The `Outbox` is a contract deployed on L1 that handles message passing from L2 to L1. Portal contracts call `consume()` to receive and process messages that were sent from L2 contracts. The Rollup contract inserts message roots via `insert()` as proofs land. A proof can cover a prefix of an epoch's checkpoints (a partial proof), so an epoch can have several roots, one per number of checkpoints covered.

**Links**: [Interface](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/l1-contracts/src/core/interfaces/messagebridge/IOutbox.sol), [Implementation](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/l1-contracts/src/core/messagebridge/Outbox.sol).

## `insert()`[​](#insert)

Inserts the root of a merkle tree containing all of the L2 to L1 messages in an epoch, after a proof covering the first `_numCheckpointsInEpoch` checkpoints of that epoch lands. This function is only callable by the Rollup contract.

outbox_insert
```
/** * @notice Inserts the root of a merkle tree containing all of the L2 to L1 messages in an epoch *         after a proof covering the first `_numCheckpointsInEpoch` checkpoints of that epoch lands. * @dev Only callable by the rollup contract * @dev Emits `RootAdded` upon inserting the root successfully * @dev Successive inserts for the same epoch with larger `_numCheckpointsInEpoch` values do not * disturb earlier entries, so users with witnesses built against an earlier partial proof can still * consume them. * @param _epoch - The epoch in which the L2 to L1 messages reside * @param _numCheckpointsInEpoch - The number of checkpoints the inserting proof covered in this * epoch. Must be in [1, MAX_CHECKPOINTS_PER_EPOCH]. * @param _root - The merkle root of the tree where all the L2 to L1 messages are leaves */function insert(Epoch _epoch, uint256 _numCheckpointsInEpoch, bytes32 _root) external;
```

> [Source code: l1-contracts/src/core/interfaces/messagebridge/IOutbox.sol#L28-L43](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/l1-contracts/src/core/interfaces/messagebridge/IOutbox.sol#L28-L43)

| Name | Type | Description |
| --- | --- | --- |
| `_epoch` | `Epoch` | The epoch in which the L2 to L1 messages reside |
| `_numCheckpointsInEpoch` | `uint256` | The number of checkpoints the inserting proof covered in this epoch (in `[1, MAX_CHECKPOINTS_PER_EPOCH]`) |
| `_root` | `bytes32` | The merkle root of the tree where all the L2 to L1 messages are leaves |

### Edge cases[​](#edge-cases)

- Will revert with `Outbox__Unauthorized()` if `msg.sender != ROLLUP_CONTRACT`.

## `consume()`[​](#consume)

Allows a recipient to consume a message from the `Outbox`.

outbox_consume
```
/** * @notice Consumes an entry from the Outbox * @dev Only useable by portals / recipients of messages * @dev Emits `MessageConsumed` when consuming messages * @param _message - The L2 to L1 message * @param _epoch - The epoch that contains the message we want to consume * @param _numCheckpointsInEpoch - The number of checkpoints in the partial proof whose root this * consume verifies against. The caller's witness path must have been built against the epoch tree * padded to that number of real checkpoints. * @param _leafIndex - The index at the level in the epoch message tree where the message is located * @param _path - The sibling path used to prove inclusion of the message, the _path length depends * on the location of the L2 to L1 message in the epoch message tree. */function consume(  DataStructures.L2ToL1Msg calldata _message,  Epoch _epoch,  uint256 _numCheckpointsInEpoch,  uint256 _leafIndex,  bytes32[] calldata _path) external;
```

> [Source code: l1-contracts/src/core/interfaces/messagebridge/IOutbox.sol#L45-L66](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/l1-contracts/src/core/interfaces/messagebridge/IOutbox.sol#L45-L66)

| Name | Type | Description |
| --- | --- | --- |
| `_message` | `L2ToL1Msg` | The L2 to L1 message to consume |
| `_epoch` | `Epoch` | The epoch that contains the message to consume |
| `_numCheckpointsInEpoch` | `uint256` | The number of checkpoints in the partial proof whose root this consume verifies against |
| `_leafIndex` | `uint256` | The index inside the merkle tree where the message is located |
| `_path` | `bytes32[]` | The sibling path used to prove inclusion of the message (built against the tree for that proof depth) |

### Edge cases[​](#edge-cases-1)

- Will revert with `Outbox__PathTooLong()` if the path length is >= 256.
- Will revert with `Outbox__LeafIndexOutOfBounds(uint256 leafIndex, uint256 pathLength)` if the leaf index exceeds the tree capacity for the given path length.
- Will revert with `Outbox__VersionMismatch(uint256 expected, uint256 actual)` if the message version does not match the Outbox version.
- Will revert with `Outbox__InvalidRecipient(address expected, address actual)` if `msg.sender != _message.recipient.actor`.
- Will revert with `Outbox__InvalidChainId()` if `block.chainid != _message.recipient.chainId`.
- Will revert with `Outbox__NothingToConsumeAtEpoch(Epoch epoch)` if the root for the epoch has not been set.
- Will revert with `Outbox__AlreadyNullified(Epoch epoch, uint256 leafIndex)` if the message has already been consumed.
- Will revert with `MerkleLib__InvalidIndexForPathLength()` if the leaf index has bits set beyond the tree height.
- Will revert with `MerkleLib__InvalidRoot(bytes32 expected, bytes32 actual, bytes32 leaf, uint256 leafIndex)` if the merkle proof verification fails.

## `hasMessageBeenConsumedAtEpoch()`[​](#hasmessagebeenconsumedatepoch)

Checks if an L2 to L1 message in a specific epoch has been consumed.

outbox_has_message_been_consumed_at_epoch_and_index
```
/** * @notice Checks to see if an L2 to L1 message in a specific epoch has been consumed * @dev - This function does not throw. Out-of-bounds access is considered valid, but will always return false * @param _epoch - The epoch that contains the message we want to check * @param _leafId - The unique id of the message leaf */function hasMessageBeenConsumedAtEpoch(Epoch _epoch, uint256 _leafId) external view returns (bool);
```

> [Source code: l1-contracts/src/core/interfaces/messagebridge/IOutbox.sol#L68-L76](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/l1-contracts/src/core/interfaces/messagebridge/IOutbox.sol#L68-L76)

| Name | Type | Description |
| --- | --- | --- |
| `_epoch` | `Epoch` | The epoch that contains the message to check |
| `_leafId` | `uint256` | The unique id of the message leaf |

### Edge cases[​](#edge-cases-2)

- This function does not throw. Out-of-bounds access is considered valid, but will always return false.

## `getRootData()`[​](#getrootdata)

Returns the merkle root for a given epoch and partial-proof depth. Returns `bytes32(0)` if no proof covering that number of checkpoints has been inserted.

```
function getRootData(Epoch _epoch, uint256 _numCheckpointsInEpoch) external view returns (bytes32);
```

| Name | Type | Description |
| --- | --- | --- |
| `_epoch` | `Epoch` | The epoch to fetch the root data for |
| `_numCheckpointsInEpoch` | `uint256` | The number of checkpoints in the partial proof whose root to fetch |

**Returns**: The merkle root of the L2 to L1 message tree for that epoch and proof depth, or `bytes32(0)` if not proven.

There is also `getRoots(Epoch _epoch)`, which returns every root stored for an epoch: slot `i` of the returned array holds the root for `numCheckpointsInEpoch = i + 1`.

## Related pages[​](#related-pages)

- [Inbox](https://docs.aztec.network/developers/docs/foundational-topics/ethereum-aztec-messaging/inbox) - L1 to L2 message passing
- [Data Structures](https://docs.aztec.network/developers/docs/foundational-topics/ethereum-aztec-messaging/data_structures) - Message struct definitions
- [L1-L2 Communication (Portals)](https://docs.aztec.network/developers/docs/foundational-topics/ethereum-aztec-messaging) - Overview of cross-chain messaging

**Tags:**
- [portals](https://docs.aztec.network/developers/tags/portals)
- [contracts](https://docs.aztec.network/developers/tags/contracts)

[Edit this page](https://github.com/AztecProtocol/aztec-packages/edit/next/docs/docs-developers/docs/foundational-topics/ethereum-aztec-messaging/outbox.md)