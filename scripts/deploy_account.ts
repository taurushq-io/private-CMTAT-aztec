import { createLogger } from "@aztec/aztec.js/log";

import { setupWalletTestnet } from "../src/utils/setup_pxe_testnet.js";
import { deploySchnorrAccount } from "../src/utils/deploy_account.js";

export async function deployAccount() {
    const logger = createLogger('aztec:CMTAToken');
    const { wallet } = await setupWalletTestnet();
    const address = await deploySchnorrAccount(wallet);
    logger.info(`Deployed account: ${address}`);
}

deployAccount().catch((error) => {
    console.error("Error:", error);
    process.exit(1);
});
