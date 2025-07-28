import { createLogger, Fr, PXE, Logger, AccountManager } from "@aztec/aztec.js";
import { getSchnorrAccount } from '@aztec/accounts/schnorr';
import { deriveSigningKey } from '@aztec/stdlib/keys';
import * as dotenv from 'dotenv';
import { getSponsoredFPCInstance } from "./sponsored_fpc.js";
import { SponsoredFPCContract } from "@aztec/noir-contracts.js/SponsoredFPC";
import { SponsoredFeePaymentMethod } from "@aztec/aztec.js/fee/testing";


// Load environment variables
dotenv.config();

export async function createAccountFromEnv(pxe: PXE, number: number): Promise<AccountManager[]> {
    let logger: Logger;
    logger = createLogger('aztec:create-account');

    logger.info(`🔐 Creating ${number} Schnorr account(s) from environment variables...`);

    if (number <= 0) {
        throw new Error('Number of accounts must be greater than 0');
    }

    const accounts: AccountManager[] = [];

    // Process each account
    for (let i = 1; i <= number; i++) {
        logger.info(`🏗️  Creating account ${i}/${number}...`);

        // Read SECRET and SALT from environment variables
        const secretEnv = process.env[`SECRET${i}`];
        const saltEnv = process.env[`SALT${i}`];

        if (!secretEnv) {
            throw new Error(`SECRET${i} environment variable is required. Please set it in your .env file.`);
        }

        if (!saltEnv) {
            throw new Error(`SALT${i} environment variable is required. Please set it in your .env file.`);
        }

        // Convert hex strings to Fr values
        let secretKey: Fr;
        let salt: Fr;

        try {
            secretKey = Fr.fromString(secretEnv);
            salt = Fr.fromString(saltEnv);
            logger.info(`✅ Successfully parsed SECRET${i} and SALT${i} values`);
        } catch (error) {
            logger.error(`❌ Failed to parse SECRET${i} and SALT${i} values: ${error}`);
            throw new Error(`Invalid SECRET${i} or SALT${i} format. Please ensure they are valid hex strings starting with "0x".`);
        }

        // Create Schnorr account with specified values
        logger.info(`🏗️  Creating Schnorr account ${i} instance with environment values...`);
        let schnorrAccount = await getSchnorrAccount(pxe, secretKey, deriveSigningKey(secretKey), salt);
        const accountAddress = schnorrAccount.getAddress();
        logger.info(`📍 Account ${i} address: ${accountAddress}`);

        // Check if account is already deployed
        logger.info(`🔍 Checking if account ${i} is already deployed...`);
        try {
            const registeredAccounts = await pxe.getRegisteredAccounts();
            const isRegistered = registeredAccounts.some(acc => acc.address.equals(accountAddress));
            
            if (isRegistered) {
                logger.info(`✅ Account ${i} is already registered with PXE`);
            } else {
                logger.info(`ℹ️  Account ${i} is not yet registered. Deploying it.`);
                const sponsoredFPC = await getSponsoredFPCInstance();
                await pxe.registerContract({ instance: sponsoredFPC, artifact: SponsoredFPCContract.artifact });
                const sponsoredPaymentMethod = new SponsoredFeePaymentMethod(sponsoredFPC.address);

                let schnorrAccount = await getSchnorrAccount(pxe, secretKey, deriveSigningKey(secretKey), salt);
                await schnorrAccount.deploy({ fee: { paymentMethod: sponsoredPaymentMethod } }).wait({timeout: 120000});
                let wallet = await schnorrAccount.getWallet();

    logger.info(`Schnorr account deployed at: ${wallet.getAddress()}`);
            }
        } catch (error) {
            logger.warn(`⚠️  Could not check account ${i} registration: ${error}`);
        }

        logger.info(`🎉 Schnorr account ${i} instance created successfully!`);
        logger.info(`📋 Account ${i} Summary:`);
        logger.info(`   - Address: ${accountAddress}`);
        logger.info(`   - SECRET${i} (truncated): ${secretEnv.substring(0, 10)}...`);
        logger.info(`   - SALT${i} (truncated): ${saltEnv.substring(0, 10)}...`);

        accounts.push(schnorrAccount);
    }

    logger.info(`🎉 All ${number} accounts created successfully!`);
    return accounts;
}

export async function getAccountFromEnv(pxe: PXE, number: number): Promise<AccountManager[]> {
    return await createAccountFromEnv(pxe, number);
}

// Helper function to get a single account (for backward compatibility)
export async function getSingleAccountFromEnv(pxe: PXE, accountIndex: number = 1): Promise<AccountManager> {
    const accounts = await createAccountFromEnv(pxe, accountIndex);
    return accounts[accountIndex - 1];
}