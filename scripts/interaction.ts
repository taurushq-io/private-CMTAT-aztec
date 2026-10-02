import { AztecAddress } from "@aztec/aztec.js/addresses";
import { createLogger } from "@aztec/aztec.js/log";
import * as dotenv from 'dotenv';

import { CMTATAztecContract as TokenContract } from "../src/artifacts/CMTATAztec.js";
import { getAccountFromEnv } from "../src/utils/create_account_from_env.js";
import { getSponsoredPaymentMethod } from "../src/utils/sponsored_fpc.js";
import { setupWalletTestnet } from "../src/utils/setup_pxe_testnet.js";

dotenv.config();

async function main() {
    const logger = createLogger('aztec:CMTATokenInteraction');

    const { wallet } = await setupWalletTestnet();
    const sponsoredPaymentMethod = await getSponsoredPaymentMethod(wallet);

    // Both accounts live in the same wallet, so the contract handle is shared and each call names its
    // sender through `from`.
    const [issuer, user1] = await getAccountFromEnv(wallet, 2);
    const contractAddress = process.env.CMTA_TOKEN_CONTRACT_ADDRESS;

    if (!contractAddress) {
        logger.error("Please set CMTA_TOKEN_CONTRACT_ADDRESS environment variable with your deployed contract address");
        return;
    }

    logger.info(`Connecting to CMTA Token contract at: ${contractAddress}`);
    logger.info(`Issuer address: ${issuer}`);
    logger.info(`User1 address: ${user1}`);

    const token = await TokenContract.at(AztecAddress.fromString(contractAddress), wallet);

    const initialSupply = 1_000_000n * 10n ** 18n; // 1 million tokens with 18 decimals

    logger.info('Issuer gets minter role ...');
    const minterRole = 7n;
    await token.methods
        .grant_role(minterRole, issuer)
        .send({ from: issuer, fee: { paymentMethod: sponsoredPaymentMethod } });
    logger.info(`Minter role granted to issuer: ${issuer}`);

    const { result: isMinter } = await token.methods.has_role(minterRole, issuer).simulate({ from: issuer });
    logger.info(`Issuer has minter role: ${isMinter}`);

    logger.info('Minting tokens to Alice ...');
    await token.methods
        .mint_to_private(user1, initialSupply)
        .send({ from: issuer, fee: { paymentMethod: sponsoredPaymentMethod } });

    const { result: balanceAlice } = await token.methods.balance_of_private(user1).simulate({ from: user1 });
    logger.info(`Alice's balance after minting: ${balanceAlice} tokens`);

    const { result: supplyAfter } = await token.methods.total_supply().simulate({ from: issuer });
    logger.info(`${supplyAfter} tokens as initial supply minted by issuer`);
    logger.info("End of CMTA Token interaction script");
}

main().catch((error) => {
    console.error("Error:", error);
    process.exit(1);
});
