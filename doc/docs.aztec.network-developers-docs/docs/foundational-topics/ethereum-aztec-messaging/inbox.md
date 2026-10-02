# Inbox

> Source: https://docs.aztec.network/developers/docs/foundational-topics/ethereum-aztec-messaging/inbox

---

- [![Home](https://docs.aztec.network/img/Aztec_Symbol_Dark.png)![Home](https://docs.aztec.network/img/Aztec%20Symbol_Light.png)](https://docs.aztec.network/)
- [Foundational Topics](https://docs.aztec.network/developers/docs/foundational-topics)
- [Aztec<>Ethereum Messaging](https://docs.aztec.network/developers/docs/foundational-topics/ethereum-aztec-messaging)
- Inbox

On this page
# Inbox

The `Inbox` is a contract deployed on L1 that handles message passing from L1 to L2.

**Links**: [Interface](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/l1-contracts/src/core/interfaces/messagebridge/IInbox.sol), [Implementation](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/l1-contracts/src/core/messagebridge/Inbox.sol).

## `sendL2Message()`[​](#sendl2message)

Sends a message from L1 to L2.

send_l1_to_l2_message
```
/** * @notice Inserts a new message into the Inbox * @dev Emits `MessageSent` with data for easy access by the sequencer * @param _recipient - The recipient of the message * @param _content - The content of the message (application specific) * @param _secretHash - The secret hash of the message (make it possible to hide when a specific message is consumed * on L2) * @return The key of the message in the set and its leaf index in the tree */function sendL2Message(DataStructures.L2Actor memory _recipient, bytes32 _content, bytes32 _secretHash)  external  returns (bytes32, uint256);
```

> [Source code: l1-contracts/src/core/interfaces/messagebridge/IInbox.sol#L33-L46](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/l1-contracts/src/core/interfaces/messagebridge/IInbox.sol#L33-L46)

| Name | Type | Description |
| --- | --- | --- |
| Recipient | [`L2Actor`](https://docs.aztec.network/developers/docs/foundational-topics/ethereum-aztec-messaging/data_structures#l2actor) | The recipient of the message. The recipient's version **MUST** match the inbox version and the actor must be an Aztec contract that is **attached** to the contract making this call. If the recipient is not attached to the caller, the message cannot be consumed by it. |
| Content | `field` (~254 bits) | The content of the message. This is the data that will be passed to the recipient. The content is limited to a single field for rollup purposes. If the content is small enough it can be passed directly, otherwise it should be hashed and the hash passed along (you can use our [`Hash`](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/l1-contracts/src/core/libraries/crypto/Hash.sol) utilities with `sha256ToField` functions). |
| Secret Hash | `field` (~254 bits) | A hash of a secret used when consuming the message on L2. Keep this preimage secret to make the consumption private. To consume the message the caller must know the pre-image (the value that was hashed). Use [`computeSecretHash`](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/yarn-project/stdlib/src/hash/hash.ts) to compute it from a secret. |
| ReturnValue | `(bytes32, uint256)` | The message hash (used as an identifier) and the leaf index in the tree. |

#### Edge cases[​](#edge-cases)

- Will revert with `Inbox__ActorTooLarge(bytes32 actor)` if the recipient actor is larger than the field size (~254 bits).
- Will revert with `Inbox__VersionMismatch(uint256 expected, uint256 actual)` if the recipient version doesn't match the inbox version.
- Will revert with `Inbox__ContentTooLarge(bytes32 content)` if the content is larger than the field size (~254 bits).
- Will revert with `Inbox__SecretHashTooLarge(bytes32 secretHash)` if the secret hash is larger than the field size (~254 bits).

## View functions[​](#view-functions)

These functions allow you to query the current state of the Inbox.

| Function | Returns | Description |
| --- | --- | --- |
| `getRoot(uint256)` | `bytes32` | Returns the root of a message tree for a given checkpoint number. |
| `getState()` | `InboxState` | Returns the current inbox state (rolling hash, total messages inserted, in-progress checkpoint). |
| `getTotalMessagesInserted()` | `uint64` | Returns the total number of messages inserted into the inbox. |
| `getInProgress()` | `uint64` | Returns the checkpoint number currently being filled. |
| `getFeeAssetPortal()` | `address` | Returns the address of the Fee Juice portal. |

## Internal functions[​](#internal-functions)

noteThe following functions are only callable by the Rollup contract and are documented here for completeness.

### `consume()`[​](#consume)

Consumes a message tree for a given checkpoint number.

consume
```
/** * @notice Consumes the current tree, and starts a new one if needed * @dev Only callable by the rollup contract * @dev In the first iteration we return empty tree root because first checkpoint's messages tree is always * empty because there has to be a 1 checkpoint lag to prevent sequencer DOS attacks * * @param _toConsume - The checkpoint number to consume * * @return The root of the consumed tree */function consume(uint256 _toConsume) external returns (bytes32);
```

> [Source code: l1-contracts/src/core/interfaces/messagebridge/IInbox.sol#L48-L60](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/l1-contracts/src/core/interfaces/messagebridge/IInbox.sol#L48-L60)

| Name | Type | Description |
| --- | --- | --- |
| _toConsume | `uint256` | The checkpoint number to consume. |
| ReturnValue | `bytes32` | The root of the consumed message tree. |

#### Edge cases[​](#edge-cases-1)

- Will revert with `Inbox__Unauthorized()` if `msg.sender != ROLLUP`.
- Will revert with `Inbox__MustBuildBeforeConsume()` if trying to consume a checkpoint that hasn't been built yet.

## Related pages[​](#related-pages)

- [Outbox](https://docs.aztec.network/developers/docs/foundational-topics/ethereum-aztec-messaging/outbox) - L2 to L1 message passing
- [Data Structures](https://docs.aztec.network/developers/docs/foundational-topics/ethereum-aztec-messaging/data_structures) - Message and actor type definitions

**Tags:**
- [portals](https://docs.aztec.network/developers/tags/portals)
- [contracts](https://docs.aztec.network/developers/tags/contracts)

[Edit this page](https://github.com/AztecProtocol/aztec-packages/edit/next/docs/docs-developers/docs/foundational-topics/ethereum-aztec-messaging/inbox.md)