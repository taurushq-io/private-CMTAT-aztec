// Moving the chain's clock instead of waiting on it.
//
// Several values in the token are `DelayedPublicMutable`: a write becomes current only after
// `CHANGE_ROLES_DELAY_SECONDS`. Two facts about a local network make the obvious approach - sleep
// for that long - not merely slow but useless, and both were established by measurement:
//
//  1. The network's L1 is anvil, whose clock does not track wall clock while idle. After an hour
//     of real time the chain tip was still 4.9 hours behind `Date.now()`, so sleeping advances
//     nothing that a contract can observe.
//  2. Warping L1 does not by itself produce an L2 block, and a private function is proved against
//     the newest block. Until a block exists whose timestamp is past `effective_at`, a private
//     read still returns the pre-delay value - while a *public* simulation, evaluated at the
//     current time, already returns the new one. That disagreement is what made every mint fail
//     with "Cannot resolve a constrained tagging secret for an invalid recipient": the issuer
//     address read as the default zero, which is not a point on the Grumpkin curve, and a
//     constrained delivery to it cannot be served.
//
// So: warp, then force one block, then check the tip actually moved.
import { EthCheatCodes, RollupCheatCodes } from '@aztec/ethereum/test';
import { SlotNumber } from '@aztec/foundation/branded-types';
import { DateProvider } from '@aztec/foundation/timer';
import type { AztecNode } from '@aztec/aztec.js/node';
import type { Logger } from '@aztec/aztec.js/log';

const { L1_URL = 'http://localhost:8545' } = process.env;

const sleep = (ms: number) => new Promise(resolve => setTimeout(resolve, ms));

/** Timestamp of the chain tip, which is what a private function is proved against. */
async function tipTimestamp(node: AztecNode): Promise<number> {
    const tip = await node.getBlockNumber();
    const block = await node.getBlock(tip);
    return Number(block?.header.globalVariables.timestamp ?? 0);
}

/**
 * Advances the chain past `seconds` so that a scheduled `DelayedPublicMutable` write becomes
 * readable from a private function.
 *
 * `mineBlock` must submit any transaction that does not itself depend on the delayed value; an
 * account deployment does. It is required because a warp alone leaves the L2 tip where it was.
 */
export async function advancePastDelay(
    node: AztecNode,
    seconds: number,
    mineBlock: () => Promise<unknown>,
    logger?: Logger,
): Promise<'warped' | 'waited'> {
    const margin = 12;
    const before = await tipTimestamp(node);

    let how: 'warped' | 'waited' = 'warped';
    if (process.env.E2E_REAL_CLOCK === 'true') {
        logger?.info(`E2E_REAL_CLOCK is set: waiting ${seconds}s for the delay to elapse`);
        await sleep((seconds + margin) * 1000);
        how = 'waited';
    } else {
        const { l1ContractAddresses } = await node.getNodeInfo();
        // Built by hand rather than through RollupCheatCodes.create, because the factory keeps the
        // EthCheatCodes private and the date provider has to be synced afterwards.
        const eth = new EthCheatCodes([L1_URL], new DateProvider());
        const rollup = new RollupCheatCodes(eth, l1ContractAddresses);

        const { slotDuration } = await rollup.getConfig();
        const slots = Math.ceil((seconds + margin) / Number(slotDuration));
        const current = await rollup.getSlot();
        const target = SlotNumber(Number(current) + slots);

        logger?.info(`Warping ${slots} slots of ${slotDuration}s (slot ${current} -> ${target})`);
        // advanceToSlot rather than advanceSlots: the latter is relative to the L1 timestamp at
        // call time and races with real-time progression between the query and the warp.
        await rollup.advanceToSlot(target);
        // The client computes a transaction's expiry from its own clock, so it has to follow the
        // chain it just warped; otherwise every later transaction looks already expired.
        await eth.syncDateProvider();
    }

    // The warp moved L1. Only a transaction moves L2, and only an L2 block carries the timestamp
    // a private read is anchored to.
    await mineBlock();

    const after = await tipTimestamp(node);
    if (after - before < seconds) {
        throw new Error(
            `The chain advanced ${after - before}s, less than the ${seconds}s delay ` +
                `(tip timestamp ${before} -> ${after}). A private read would still see the ` +
                `pre-delay value, so the test would fail somewhere less obvious than here.`,
        );
    }
    logger?.info(`Chain advanced ${after - before}s (${how}); tip timestamp ${before} -> ${after}`);
    return how;
}
