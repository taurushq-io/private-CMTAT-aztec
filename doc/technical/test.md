# The end-to-end suite

`yarn test:js` runs the TypeScript suite against a local Aztec network. This note records what it covers, and the two defects that kept `Accounts › Creates accounts with fee juice` red — both in the test rather than in the token, both found by measurement, both fixed.

> **State (2026-09-23).** `yarn test:js` against a local network: **17 passed, 0 failed, 172 s**. `yarn test:nr`: **239/239**.

## Table of contents

- [What the suite covers](#what-the-suite-covers)
- [Defect 1: the claim was one block early](#defect-1-the-claim-was-one-block-early)
- [Defect 2: the fee bound had gone stale](#defect-2-the-fee-bound-had-gone-stale)
- [The delay, and why the suite does not wait for it](#the-delay-and-why-the-suite-does-not-wait-for-it)
- [Reproducing](#reproducing)

## What the suite covers

Two files, seventeen tests:

- `src/test/e2e/index.test.ts` — the token itself through the TypeScript artifacts: deployment, roles, mint, private transfer, burn, pause, freeze, the issuer's view of the notes it receives.
- `src/test/e2e/accounts.test.ts` — the account and fee machinery the deployment story depends on: funding a fresh account by bridging Fee Juice from L1, deploying an unfunded account from a funded one, and a contract deployment paid through the sponsored FPC.

Only the second file touches L1. Nothing in the token needs bridged Fee Juice — every other test and every script in `scripts/` pays through the sponsored FPC — but the test exists because bridging is a route an operator may want.

## Defect 1: the claim was one block early

### The symptom

```
● Accounts › Creates accounts with fee juice

  Simulation error: No L1 to L2 message found for message hash 0x00c56cf9…

    at FeeJuice.claim_and_end_setup
    at SchnorrAccount.entrypoint
    at MultiCallEntrypoint.entrypoint
```

The error is raised client-side, in `@aztec/stdlib`:

```ts
const l1ToL2Response = await node.getL1ToL2MessageMembershipWitness(referenceBlock, messageHash);
if (!l1ToL2Response) {
    throw new Error(`No L1 to L2 message found for message hash ${messageHash.toString()}`);
}
```

The message the test was trying to consume was not yet in the L1-to-L2 message tree of the block it asked about, so no membership witness existed and the claim could not be proved.

### The cause, measured

An L1-to-L2 message is not available on L2 as soon as the deposit lands: the proposer batches messages from the `Inbox` and includes them in a later L2 block, and only from that block does a witness exist. The test forced **two** blocks — with the comment *"arbitrary transactions to progress 2 blocks"* — because the Aztec documentation puts the lag at "about two L2 blocks". The word doing the work is *about*.

Measured against the running network by bridging, then adding one block at a time and asking for the witness after each:

| Blocks produced after the deposit | Tip | Membership witness |
|---:|---:|---|
| 0 | 87 | absent |
| 1 | 88 | absent |
| 2 | 89 | **absent** — where the test claimed |
| 3 | 90 | found |

One block short, deterministically. Run in isolation, with nothing else touching the network, it failed every time.

A second detail made this easy to misread: **a local network produces no blocks while idle**. Waiting does not help, because nothing advances until a transaction arrives. The two deploys were there precisely to force blocks, and the count they forced was the whole margin the test had.

### The fix

Three is what this network needed that day; it is not a protocol guarantee. The lag is however long the proposer takes to pick the `Inbox` batch up, which depends on where in the slot the deposit landed, on the archiver's L1 sync, and on how the network is configured. Hard-coding three would have replaced an off-by-one with a flakier off-by-one.

So the test asks the node instead of counting. `src/utils/l1_to_l2_message.ts` produces blocks until every deposited message is in the tree at the chain tip:

```ts
export async function waitForL1ToL2Messages(node, messageHashes, forceBlock, logger?) {
    const hashes = messageHashes.map(h => Fr.fromHexString(h));
    const available = async () =>
        (await Promise.all(hashes.map(h => node.getL1ToL2MessageMembershipWitness('latest', h))))
            .every(w => w !== undefined);

    for (let blocks = 0; blocks <= MAX_BLOCKS; blocks++) {
        if (await available()) return blocks;
        await forceBlock();
    }
    throw new Error(/* … */);
}
```

`forceBlock` submits a throwaway contract deployment; it is what makes the loop progress, since time alone produces no block. `'latest'` is the same reference block the claim itself defaults to. The bound is ten blocks, so a network that never delivers the message fails with a message that says so rather than hanging.

## Defect 2: the fee bound had gone stale

With the claim working, the test failed one line later:

```
expect(received).toBeGreaterThanOrEqual(expected)

Expected: >= 999999999990000000000n
Received:    999999992426520400000n
```

The test asserted that the account's Fee Juice balance after paying for its own deployment was at least `claimAmount - approxMaxDeployCost`, with

```ts
const approxMaxDeployCost = 10n ** 10n; // Need to manually update this if fees increase significantly
```

Fees had increased significantly. The deployment cost about 7.6 × 10¹² against a bound of 10¹⁰ — a factor of 757 — so the assertion failed although nothing was wrong.

The comment admitted the design flaw: a constant that has to be revised by hand whenever the protocol's fee schedule moves will be wrong the next time it moves, and it will be wrong silently until a test run says otherwise. The receipt carries the exact figure, so the test takes it from there:

```ts
const { receipt } = await deployMethod.send({ from: NO_FROM, fee: { paymentMethod } });
expect(receipt.transactionFee).toBeGreaterThan(0n);
fees.push(receipt.transactionFee!);
…
balances.forEach((b, i) => expect(b).toBe(claimAmount - fees[i]));
```

This is a stronger assertion than the one it replaces — exact equality rather than a lower bound — and it never goes stale. The separate `toBeGreaterThan(0n)` keeps the property the bound was there for: that the account really did pay, rather than the fee being zero and the equality holding trivially.

## The delay, and why the suite does not wait for it

`issuer_address` is a `DelayedPublicMutable` with an initial delay of `CHANGE_ROLES_DELAY_SECONDS = 3600`, and every mint, transfer and burn reads it. A freshly deployed token is therefore unusable for an hour of chain time.

The suite does not sleep for that hour. `src/utils/time_travel.ts` warps L1 past the delay and then forces one L2 block, because a warp alone leaves the L2 tip — and so the timestamp a private function is proved against — where it was. The comments in that file record why each step is needed; the short version is that anvil's clock does not follow wall time while idle, and that a private read and a public simulation disagree about the current value until a block exists past `effective_at`. Setting `E2E_REAL_CLOCK=true` falls back to actually waiting, which is useful only to check that the warp is faithful.

This is why a full run takes under three minutes rather than the hour the delay would otherwise cost.

## Reproducing

```bash
cp .env.example .env                 # supplies L1_MNEMONIC; the example carries the anvil default
aztec start --local-network          # in another terminal; not `--sandbox`, which was removed at 3.0
yarn compile && yarn codegen
SKIP_SANDBOX=true yarn test:js       # the suite, against the already-running network

# just the fee juice test
SKIP_SANDBOX=true NODE_NO_WARNINGS=1 node --experimental-vm-modules $(yarn bin jest) \
    --runInBand --config jest.integration.config.json -t "Creates accounts with fee juice"
```

`SKIP_SANDBOX=true` stops the suite spawning its own network. Without it the suite starts one itself, which is what CI does.
