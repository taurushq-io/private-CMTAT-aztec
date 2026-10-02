import { NO_FROM } from '@aztec/aztec.js/account';
import { Fr, GrumpkinScalar } from '@aztec/aztec.js/fields';
import { createLogger } from '@aztec/aztec.js/log';
import type { AztecAddress } from '@aztec/aztec.js/addresses';
import type { EmbeddedWallet } from '@aztec/wallets/embedded';

import { getSponsoredPaymentMethod } from './sponsored_fpc.js';

/**
 * Creates a Schnorr account with a random secret, salt and signing key, and deploys it paying with the
 * sponsored FPC. Returns the deployed account's address.
 */
export async function deploySchnorrAccount(wallet: EmbeddedWallet): Promise<AztecAddress> {
    const logger = createLogger('aztec:deploySchnorrAccount');

    const sponsoredPaymentMethod = await getSponsoredPaymentMethod(wallet);

    const secret = Fr.random();
    logger.info(`Generated random secret key: ${secret.toString()}`);
    const salt = Fr.random();
    logger.info(`Generated random salt: ${salt.toString()}`);
    const signingKey = GrumpkinScalar.random();

    const account = await wallet.createSchnorrAccount(secret, salt, signingKey);

    // A brand new account cannot pay for its own deployment, so it is sent without account contract
    // mediation and the FPC picks up the fee.
    const deployMethod = await account.getDeployMethod();
    await deployMethod.send({ from: NO_FROM, fee: { paymentMethod: sponsoredPaymentMethod } });

    logger.info(`Schnorr account deployed at: ${account.address}`);

    return account.address;
}
