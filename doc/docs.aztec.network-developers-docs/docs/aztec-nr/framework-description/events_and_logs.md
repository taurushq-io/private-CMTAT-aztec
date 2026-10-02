# Events and Logs

> Source: https://docs.aztec.network/developers/docs/aztec-nr/framework-description/events_and_logs

---

- [![Home](https://docs.aztec.network/img/Aztec_Symbol_Dark.png)![Home](https://docs.aztec.network/img/Aztec%20Symbol_Light.png)](https://docs.aztec.network/)
- [Aztec.nr](https://docs.aztec.network/developers/docs/aztec-nr)
- Framework Description
- Events and Logs

On this page
# Events and Logs

Events allow contracts to communicate with offchain applications. Private events are encrypted and delivered to specific recipients, while public events are visible to everyone.

## Prerequisites[​](#prerequisites)

- An Aztec contract project set up with `aztec-nr` dependency
- Understanding of private vs public functions in Aztec

## Define an event[​](#define-an-event)

Declare events using the `#[event]` attribute:

```
#[event]struct Transfer {    from: AztecAddress,    to: AztecAddress,    amount: u128,}
```

## Emit private events[​](#emit-private-events)

In private functions, emit events using `self.emit()` and deliver them to recipients:

```
use aztec::messages::delivery::MessageDelivery;#[external("private")]fn transfer(to: AztecAddress, amount: u128) {    let from = self.msg_sender();    // ... transfer logic ...    self.emit(Transfer { from, to, amount }).deliver_to(        to,        MessageDelivery::onchain_unconstrained(),    );}
```

warningYou **must** call `deliver_to()` on the returned `EventMessage`. If you don't, the event information is lost forever. The compiler will warn you about unused `EventMessage` values.

### Deliver to multiple recipients[​](#deliver-to-multiple-recipients)

You can deliver the same event to multiple recipients with different delivery modes:

```
let message = self.emit(Transfer { from, to, amount });message.deliver_to(from, MessageDelivery::offchain());message.deliver_to(to, MessageDelivery::onchain_constrained());
```

The `MessageDelivery` options are:

- **`onchain_constrained()`** - Constrained encryption with onchain delivery. Slowest proving but provides cryptographic guarantees that recipients can decrypt messages.
- **`onchain_unconstrained()`** - Unconstrained encryption with onchain delivery. Faster proving, but trusts the sender to encrypt correctly.
- **`offchain()`** - Unconstrained encryption with offchain delivery. Lowest cost, but requires custom infrastructure to deliver messages to recipients.

noteEmitting private events is optional. Onchain delivery publishes encrypted data to Ethereum blobs, inheriting Ethereum's data availability guarantees. You can choose to share information offchain instead.

## Emit public events[​](#emit-public-events)

In public functions, emit events using `self.emit()`:

```
#[external("public")]fn update_value(value: Field) {    // ... update logic ...    self.emit(ValueUpdated { value });}
```

Public events are emitted as plaintext logs, similar to Solidity events.

## Emit unstructured public logs[​](#emit-unstructured-public-logs)

For unstructured data, use `emit_public_log_unsafe` directly on the context. It takes a tag (placed at the first field of the emitted log, which nodes use to index logs) followed by the data:

```
self.context.emit_public_log_unsafe(0, "My message");self.context.emit_public_log_unsafe(0, [1, 2, 3]);
```

The tag should be domain-separated to prevent collisions with unrelated log types. Prefer `self.emit(event)` where possible, which handles tagging automatically.

## Query public logs[​](#query-public-logs)

Query public logs from offchain applications using the Aztec node. Raw public logs are
attached to each block's transaction effects — fetch a block with `includeTransactions: true`
and read `body.txEffects[*].publicLogs`:

```
const blockNumber = await node.getBlockNumber();const block = await node.getBlock(blockNumber, { includeTransactions: true });const publicLogs = block?.body.txEffects.flatMap(tx => tx.publicLogs) ?? [];
```

## Cost considerations[​](#cost-considerations)

Event data published onchain is stored in Ethereum blobs, which incurs costs. Consider:

- Use offchain delivery for lower costs when you have custom delivery infrastructure
- Only emit events when necessary for your application's functionality

## Next steps[​](#next-steps)

- Learn about [storage](https://docs.aztec.network/developers/docs/aztec-nr/framework-description/state_variables) to persist data in your contracts
- Explore [calling other contracts](https://docs.aztec.network/developers/docs/aztec-nr/framework-description/calling_contracts) for cross-contract interactions
- Understand [cross-chain communication](https://docs.aztec.network/developers/docs/aztec-nr/framework-description/ethereum_aztec_messaging) between Ethereum and Aztec

**Tags:**
- [contracts](https://docs.aztec.network/developers/tags/contracts)
- [events](https://docs.aztec.network/developers/tags/events)

[Edit this page](https://github.com/AztecProtocol/aztec-packages/edit/next/docs/docs-developers/docs/aztec-nr/framework-description/events_and_logs.md)