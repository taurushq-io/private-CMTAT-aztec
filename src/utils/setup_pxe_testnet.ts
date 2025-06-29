
import { createPXEService, getPXEServiceConfig } from '@aztec/pxe/server';
import { createStore } from "@aztec/kv-store/lmdb"
import { createAztecNodeClient, createLogger, waitForPXE } from '@aztec/aztec.js';
import * as dotenv from 'dotenv';

dotenv.config();

const { NODE_URL = process.env.NODE_URL} = process.env;
const node = createAztecNodeClient(NODE_URL as string)
const l1Contracts = await node.getL1ContractAddresses();
const config = getPXEServiceConfig()
const fullConfig = { ...config, l1Contracts }
fullConfig.proverEnabled = true;

const store = await createStore('pxe', {
    dataDirectory: 'store',
    dataStoreMapSizeKB: 1e6,
});

export const setupPXETestnet = async () => {
    const pxeLogger = createLogger('aztec:pxe');
    const proverLogger = createLogger('aztec:prover');
    const storeLogger = createLogger('aztec:store');

    const creationOptions = {
    loggers: {
        store: storeLogger,
        pxe: pxeLogger,
        prover: proverLogger
    },
    store
    }
    
    const pxe = await createPXEService(node, fullConfig, creationOptions);
    await waitForPXE(pxe);
    return pxe;
};