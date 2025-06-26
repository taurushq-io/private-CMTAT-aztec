import { TokenContract } from "../src/artifacts/Token.js"
import { createLogger, PXE, Logger, SponsoredFeePaymentMethod, Fr } from "@aztec/aztec.js";
import { setupPXE } from "../src/utils/setup_pxe.js";
import { getSponsoredFPCInstance } from "../src/utils/sponsored_fpc.js";
import { SponsoredFPCContract } from "@aztec/noir-contracts.js/SponsoredFPC";
import { deploySchnorrAccount } from "../src/utils/deploy_account.js";

async function main() {

    let pxe: PXE;
    let logger: Logger;

    logger = createLogger('aztec:CMTA-Token');

    pxe = await setupPXE();

    const sponsoredFPC = await getSponsoredFPCInstance();
    await pxe.registerContract({ instance: sponsoredFPC, artifact: SponsoredFPCContract.artifact });

    let accountManager = await deploySchnorrAccount(pxe);
    const wallet = await accountManager.getWallet();
    const address = accountManager.getAddress();

    const tokenName = 'CMTA-Token'
    const tokenSymbol = 'CMTAT'
    const tokenDecimals = 18n

    const profileTx = await TokenContract.deploy(wallet, address, tokenName, tokenSymbol, tokenDecimals).profile({ profileMode: "full"});
    console.dir(profileTx, { depth: 2 });
}

main();