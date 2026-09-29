// The L1 credential the end-to-end suite and the fee scripts sign with.
//
// This is deliberately NOT a literal in the source. The value for a local network is Foundry's
// published anvil default, which the Aztec CLI also uses as its own `--local-network.l1Mnemonic`
// default, so it is not a secret - but a mnemonic written into a test file is the shape someone
// copies when they point the same script at a funded account. Keeping it in `.env` means the one
// place that holds a credential is the one place that is gitignored.
//
// `.env.example` carries the anvil value, so `cp .env.example .env` is all a local run needs.
import * as dotenv from 'dotenv';

dotenv.config();

/**
 * The mnemonic used to sign L1 transactions, from `L1_MNEMONIC`.
 *
 * Throws rather than falling back, so a missing value fails at the first call with an
 * instruction instead of somewhere deeper with an unfunded-account error.
 */
export function l1Mnemonic(): string {
    const value = process.env.L1_MNEMONIC;
    if (!value) {
        throw new Error(
            'L1_MNEMONIC is not set. Copy .env.example to .env (it carries the anvil default used ' +
                'by `aztec start --local-network`), or export L1_MNEMONIC for the network you are ' +
                'targeting. It is never hard-coded here on purpose.',
        );
    }
    return value;
}
