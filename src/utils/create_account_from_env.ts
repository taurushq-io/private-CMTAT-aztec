import { NO_FROM } from '@aztec/aztec.js/account';
import type { AztecAddress } from '@aztec/aztec.js/addresses';
import { Fr } from '@aztec/aztec.js/fields';
import { createLogger } from '@aztec/aztec.js/log';
import { deriveMasterMessageSigningSecretKey } from '@aztec/stdlib/keys';
import type { EmbeddedWallet } from '@aztec/wallets/embedded';
import * as dotenv from 'dotenv';

import { getSponsoredPaymentMethod } from './sponsored_fpc.js';

// Load environment variables
dotenv.config();

/**
 * Recreates `number` Schnorr accounts from the SECRET<i>/SALT<i> pairs in `.env`, deploying any that
 * are not on chain yet. Recreating from the same secret and salt always yields the same address, which
 * is how the testnet scripts keep talking to the same accounts across runs.
 *
 * The signing key is derived from the secret so that `.env` stays a secret/salt pair. Note that both
 * the derivation and the address computation changed with Aztec v3, so a given SECRET/SALT pair no
 * longer resolves to the address it did on 0.87 - the addresses recorded in .env.example are stale.
 */
export async function createAccountFromEnv(
    wallet: EmbeddedWallet,
    number: number,
): Promise<AztecAddress[]> {
    const logger = createLogger('aztec:create-account');

    logger.info(`Creating ${number} Schnorr account(s) from environment variables...`);

    if (number <= 0) {
        throw new Error('Number of accounts must be greater than 0');
    }

    const sponsoredPaymentMethod = await getSponsoredPaymentMethod(wallet);
    const addresses: AztecAddress[] = [];

    for (let i = 1; i <= number; i++) {
        logger.info(`Creating account ${i}/${number}...`);

        const secretEnv = process.env[`SECRET${i}`];
        const saltEnv = process.env[`SALT${i}`];

        if (!secretEnv) {
            throw new Error(`SECRET${i} environment variable is required. Please set it in your .env file.`);
        }

        if (!saltEnv) {
            throw new Error(`SALT${i} environment variable is required. Please set it in your .env file.`);
        }

        let secretKey: Fr;
        let salt: Fr;

        try {
            secretKey = Fr.fromString(secretEnv);
            salt = Fr.fromString(saltEnv);
        } catch (error) {
            logger.error(`Failed to parse SECRET${i} and SALT${i} values: ${error}`);
            throw new Error(
                `Invalid SECRET${i} or SALT${i} format. Please ensure they are valid hex strings starting with "0x".`,
            );
        }

        const account = await wallet.createSchnorrAccount(secretKey, salt, deriveMasterMessageSigningSecretKey(secretKey));
        const accountAddress = account.address;
        logger.info(`Account ${i} address: ${accountAddress}`);

        const metadata = await wallet.getContractMetadata(accountAddress);
        if (metadata.initializationStatus) {
            logger.info(`Account ${i} is already deployed`);
        } else {
            logger.info(`Account ${i} is not deployed yet. Deploying it.`);
            const deployMethod = await account.getDeployMethod();
            await deployMethod.send({ from: NO_FROM, fee: { paymentMethod: sponsoredPaymentMethod } });
            logger.info(`Schnorr account ${i} deployed at: ${accountAddress}`);
        }

        addresses.push(accountAddress);
    }

    logger.info(`All ${number} accounts created successfully`);
    return addresses;
}

export async function getAccountFromEnv(
    wallet: EmbeddedWallet,
    number: number,
): Promise<AztecAddress[]> {
    return await createAccountFromEnv(wallet, number);
}

// Helper function to get a single account (for backward compatibility)
export async function getSingleAccountFromEnv(
    wallet: EmbeddedWallet,
    accountIndex: number = 1,
): Promise<AztecAddress> {
    const accounts = await createAccountFromEnv(wallet, accountIndex);
    return accounts[accountIndex - 1];
}
