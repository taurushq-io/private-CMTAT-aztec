// Wallet setup for the public testnet. See setup_pxe.ts for why this no longer creates a PXE directly.
import { createLogger } from '@aztec/aztec.js/log';
import { createAztecNodeClient, waitForNode } from '@aztec/aztec.js/node';
import type { AztecNode } from '@aztec/aztec.js/node';
import { createStore } from '@aztec/kv-store/lmdb';
import { EmbeddedWallet } from '@aztec/wallets/embedded';
import * as dotenv from 'dotenv';

dotenv.config();

const { NODE_URL } = process.env;

export type WalletSetup = {
    node: AztecNode;
    wallet: EmbeddedWallet;
};

export const setupWalletTestnet = async (): Promise<WalletSetup> => {
    if (!NODE_URL) {
        throw new Error('NODE_URL is not set. Copy .env.example to .env and set it to a testnet node.');
    }

    const node = createAztecNodeClient(NODE_URL);
    await waitForNode(node);

    const store = await createStore('pxe', {
        dataDirectory: 'store',
        dataStoreMapSizeKb: 1e6,
    });

    const wallet = await EmbeddedWallet.create(node, {
        logger: createLogger('aztec:pxe'),
        // Testnet transactions are proven, unlike the sandbox ones.
        pxe: { proverEnabled: true, store },
    });

    return { node, wallet };
};
