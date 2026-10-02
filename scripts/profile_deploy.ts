import { createLogger } from "@aztec/aztec.js/log";

import { CMTATAztecContract as TokenContract } from "../src/artifacts/CMTATAztec.js";
import { deploySchnorrAccount } from "../src/utils/deploy_account.js";
import { getSponsoredPaymentMethod } from "../src/utils/sponsored_fpc.js";
import { setupWallet } from "../src/utils/setup_pxe.js";

async function main() {
    const logger = createLogger('aztec:CMTA-Token');

    const { wallet } = await setupWallet();
    const sponsoredPaymentMethod = await getSponsoredPaymentMethod(wallet);
    const address = await deploySchnorrAccount(wallet);

    const tokenName = 'CMTA-Token';
    const tokenSymbol = 'CMTAT';
    const tokenDecimals = 18;

    const profileTx = await TokenContract.deploy(
        wallet,
        address,
        tokenName,
        tokenSymbol,
        tokenDecimals,
    ).profile({ from: address, profileMode: "full", fee: { paymentMethod: sponsoredPaymentMethod } });

    logger.info('Deployment profile:');
    console.dir(profileTx, { depth: 2 });
}

main().catch((error) => {
    console.error("Error:", error);
    process.exit(1);
});
