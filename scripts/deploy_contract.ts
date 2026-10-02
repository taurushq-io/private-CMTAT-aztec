import { AztecAddress } from "@aztec/aztec.js/addresses";
import { createLogger } from "@aztec/aztec.js/log";

import { CMTATAztecContract as TokenContract } from "../src/artifacts/CMTATAztec.js";
import { deploySchnorrAccount } from "../src/utils/deploy_account.js";
import { getSponsoredPaymentMethod } from "../src/utils/sponsored_fpc.js";
import { setupWalletTestnet } from "../src/utils/setup_pxe_testnet.js";

async function main() {
    const logger = createLogger('aztec:CMTAToken');
    logger.info('Starting CMTA Token deployment script...');

    const { wallet } = await setupWalletTestnet();

    const sponsoredPaymentMethod = await getSponsoredPaymentMethod(wallet);
    const address = await deploySchnorrAccount(wallet);

    const tokenName = 'CMTAToken';
    const tokenSymbol = 'CMTAT';
    const tokenDecimals = 18;

    const { contract: tokenContract } = await TokenContract.deploy(
        wallet,
        address,
        tokenName,
        tokenSymbol,
        tokenDecimals,
        false, // public_side_enabled: keep the fully private token
    ).send({ from: address, fee: { paymentMethod: sponsoredPaymentMethod } });

    logger.info(`CMTA Token Contract deployed at: ${tokenContract.address}`);

    const tokenContractIssuer = await TokenContract.at(
        AztecAddress.fromString(tokenContract.address.toString()),
        wallet,
    );

    logger.info('Issuer gets minter role ...');
    const minterRole = 7n;
    await tokenContractIssuer.methods
        .grant_role(minterRole, address)
        .send({ from: address, fee: { paymentMethod: sponsoredPaymentMethod } });
    logger.info(`Minter role granted to ${address}`);
}

main().catch((error) => {
    console.error("Error:", error);
    process.exit(1);
});
