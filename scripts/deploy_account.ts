import { createLogger, Logger } from "@aztec/aztec.js";
import { setupPXETestnet } from "../src/utils/setup_pxe_testnet.js";
import { deploySchnorrAccount } from "../src/utils/deploy_account.js";

export async function deployAccount() {
    let logger: Logger;
    logger = createLogger('aztec:CMTAToken');
    const pxe = await setupPXETestnet()
    await deploySchnorrAccount(pxe);
}

deployAccount();