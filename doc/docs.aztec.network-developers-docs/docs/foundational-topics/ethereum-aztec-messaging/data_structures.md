# Data Structures

> Source: https://docs.aztec.network/developers/docs/foundational-topics/ethereum-aztec-messaging/data_structures

---

- [![Home](https://docs.aztec.network/img/Aztec_Symbol_Dark.png)![Home](https://docs.aztec.network/img/Aztec%20Symbol_Light.png)](https://docs.aztec.network/)
- [Foundational Topics](https://docs.aztec.network/developers/docs/foundational-topics)
- [Aztec<>Ethereum Messaging](https://docs.aztec.network/developers/docs/foundational-topics/ethereum-aztec-messaging)
- Data Structures

On this page
# Data Structures

This page documents the Solidity structs used for L1-L2 message passing in the Aztec protocol.

**Source**: [DataStructures.sol](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/l1-contracts/src/core/libraries/DataStructures.sol)

## `L1Actor`[​](#l1actor)

An entity on L1, specifying the address and the chainId. Used when specifying a sender or recipient on L1.

l1_actor
```
/** * @notice Actor on L1. * @param actor - The address of the actor * @param chainId - The chainId of the actor */struct L1Actor {  address actor;  uint256 chainId;}
```

> [Source code: l1-contracts/src/core/libraries/DataStructures.sol#L11-L22](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/l1-contracts/src/core/libraries/DataStructures.sol#L11-L22)

## `L2Actor`[​](#l2actor)

An entity on L2, specifying the Aztec address and the protocol version. Used when specifying a sender or recipient on L2.

l2_actor
```
/** * @notice Actor on L2. * @param actor - The aztec address of the actor * @param version - Ahe Aztec instance the actor is on */struct L2Actor {  bytes32 actor;  uint256 version;}
```

> [Source code: l1-contracts/src/core/libraries/DataStructures.sol#L24-L35](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/l1-contracts/src/core/libraries/DataStructures.sol#L24-L35)

## `L1ToL2Msg`[​](#l1tol2msg)

A message sent from L1 to L2. The `secretHash` field contains the hash of a secret pre-image that must be known to consume the message on L2. Use [`computeSecretHash`](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/yarn-project/stdlib/src/hash/hash.ts) to compute it from a secret.

l1_to_l2_msg
```
/** * @notice Struct containing a message from L1 to L2 * @param sender - The sender of the message * @param recipient - The recipient of the message * @param content - The content of the message (application specific) padded to bytes32 or hashed if larger. * @param secretHash - The secret hash of the message (make it possible to hide when a specific message is consumed on * L2). * @param index - Global leaf index on the L1 to L2 messages tree. */struct L1ToL2Msg {  L1Actor sender;  L2Actor recipient;  bytes32 content;  bytes32 secretHash;  uint256 index;}
```

> [Source code: l1-contracts/src/core/libraries/DataStructures.sol#L37-L55](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/l1-contracts/src/core/libraries/DataStructures.sol#L37-L55)

## `L2ToL1Msg`[​](#l2tol1msg)

A message sent from L2 to L1.

l2_to_l1_msg
```
/** * @notice Struct containing a message from L2 to L1 * @param sender - The sender of the message * @param recipient - The recipient of the message * @param content - The content of the message (application specific) padded to bytes32 or hashed if larger. * @dev Not to be confused with L2ToL1Message in Noir circuits */struct L2ToL1Msg {  DataStructures.L2Actor sender;  DataStructures.L1Actor recipient;  bytes32 content;}
```

> [Source code: l1-contracts/src/core/libraries/DataStructures.sol#L57-L70](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/l1-contracts/src/core/libraries/DataStructures.sol#L57-L70)

## See also[​](#see-also)

- [Inbox](https://docs.aztec.network/developers/docs/foundational-topics/ethereum-aztec-messaging/inbox) - L1 contract for sending messages to L2
- [Outbox](https://docs.aztec.network/developers/docs/foundational-topics/ethereum-aztec-messaging/outbox) - L1 contract for consuming messages from L2
- [Portal messaging overview](https://docs.aztec.network/developers/docs/foundational-topics/ethereum-aztec-messaging) - How L1-L2 messaging works

[Edit this page](https://github.com/AztecProtocol/aztec-packages/edit/next/docs/docs-developers/docs/foundational-topics/ethereum-aztec-messaging/data_structures.md)