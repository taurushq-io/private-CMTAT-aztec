// Waiting for an L1-to-L2 message to become claimable, instead of guessing how many blocks it takes.
//
// An L1 deposit does not put its message in L2 state straight away: the proposer picks the batch up
// from the `Inbox` and includes it in a later L2 block, and only from that block does a membership
// witness exist. Until then `FeeJuicePaymentMethodWithClaim` fails at simulation with
// "No L1 to L2 message found for message hash ...".
//
// The Aztec documentation puts the lag at "about two L2 blocks", and the test used to send exactly
// two transactions to force exactly two blocks. Measured against a local network the message needed
// three, so the test failed every run. The lag is not a protocol constant - it depends on where in
// the slot the deposit landed and on the archiver's L1 sync - so raising the count to three would
// only move the off-by-one. Ask the node instead.
//
// Note that a local network produces no block while idle: `forceBlock` is what makes the loop
// progress, not the passage of time.
import { Fr } from '@aztec/aztec.js/fields';
import type { AztecNode } from '@aztec/aztec.js/node';
import type { Logger } from '@aztec/aztec.js/log';
import type { Hex } from 'viem';

/** Blocks to produce before giving up. Three sufficed when this was measured; the bound is slack. */
const MAX_BLOCKS = 10;

/**
 * Produces blocks until every one of `messageHashes` is in the L1-to-L2 message tree of the chain
 * tip, which is the block a claim is proved against.
 *
 * `forceBlock` must submit any transaction; a contract deployment does. Returns how many blocks it
 * had to produce, so a caller can log the figure rather than assume it.
 */
export async function waitForL1ToL2Messages(
    node: AztecNode,
    messageHashes: Hex[],
    forceBlock: () => Promise<unknown>,
    logger?: Logger,
): Promise<number> {
    const hashes = messageHashes.map(h => Fr.fromHexString(h));
    const available = async () =>
        (await Promise.all(hashes.map(h => node.getL1ToL2MessageMembershipWitness('latest', h)))).every(
            w => w !== undefined,
        );

    for (let blocks = 0; blocks <= MAX_BLOCKS; blocks++) {
        if (await available()) {
            logger?.info(`L1-to-L2 messages claimable after ${blocks} block(s)`);
            return blocks;
        }
        await forceBlock();
    }

    throw new Error(
        `${messageHashes.length} L1-to-L2 message(s) were still not in the message tree after ` +
            `${MAX_BLOCKS} blocks. Either the deposit never reached the Inbox, or the archiver is ` +
            `not following L1.`,
    );
}
