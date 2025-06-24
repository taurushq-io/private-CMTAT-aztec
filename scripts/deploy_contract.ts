import { FiatCMTATokenContract } from "../src/artifacts/FiatCMTAToken.js"
import { createLogger, PXE, Logger, SponsoredFeePaymentMethod, Fr } from "@aztec/aztec.js";
//import { TokenContract } from "@aztec/noir-contracts.js/Token"
import { setupPXETestnet } from "../src/utils/setup_pxe_testnet.js";
import { getSponsoredFPCInstance } from "../src/utils/sponsored_fpc.js";
import { SponsoredFPCContract } from "@aztec/noir-contracts.js/SponsoredFPC";
import { deploySchnorrAccount } from "../src/utils/deploy_account.js";

async function main() {

    let pxe: PXE;
    let logger: Logger;

    logger = createLogger('aztec:aztec-starter');

    pxe = await setupPXETestnet();

    const sponsoredFPC = await getSponsoredFPCInstance();
    await pxe.registerContract({ instance: sponsoredFPC, artifact: SponsoredFPCContract.artifact });
    const sponsoredPaymentMethod = new SponsoredFeePaymentMethod(sponsoredFPC.address);

    let accountManager = await deploySchnorrAccount(pxe);
    const wallet = await accountManager.getWallet();
    const address = await accountManager.getAddress();

    const tokenName = 'FiatCMTAToken'
    const tokenSymbol = 'FCMTAT'
    const tokenCurrency = 'USD'
    const tokenDecimals = 18n


    const tokenContract = await FiatCMTATokenContract.deploy(wallet,tokenName, tokenSymbol, tokenCurrency, tokenDecimals, address).send({ fee: { paymentMethod: sponsoredPaymentMethod } }).deployed({timeout: 120000});
    logger.info(`CMTAT Token Contract deployed at: ${tokenContract.address}`);
}

main();