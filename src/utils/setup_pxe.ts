// Wallet setup for a local sandbox.
//
// Aztec v4 replaced the "create a PXE service and hand it around" pattern with a Wallet that owns its
// own PXE; `EmbeddedWallet` is the in-process implementation. The file keeps its old name so imports
// stay put, but it no longer builds a PXE directly.
import { createAztecNodeClient, waitForNode } from '@aztec/aztec.js/node';
import type { AztecNode } from '@aztec/aztec.js/node';
import { createStore } from '@aztec/kv-store/lmdb';
import { EmbeddedWallet } from '@aztec/wallets/embedded';

const { NODE_URL = 'http://localhost:8080' } = process.env;

export type WalletSetup = {
    node: AztecNode;
    wallet: EmbeddedWallet;
};

export const setupWallet = async (): Promise<WalletSetup> => {
    const node = createAztecNodeClient(NODE_URL);
    await waitForNode(node);

    const store = await createStore('pxe', {
        dataDirectory: 'store',
        dataStoreMapSizeKb: 1e6,
    });

    const wallet = await EmbeddedWallet.create(node, {
        pxe: { proverEnabled: false, store },
    });

    return { node, wallet };
};
