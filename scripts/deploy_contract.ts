import { CMTATokenContract as TokenContract} from "../src/artifacts/CMTAToken.js"
import { createLogger, PXE, Logger, SponsoredFeePaymentMethod, Fr, AztecAddress, TxStatus } from "@aztec/aztec.js";
//import { TokenContract } from "@aztec/noir-contracts.js/Token"
import { setupPXETestnet } from "../src/utils/setup_pxe_testnet.js";
import { getSponsoredFPCInstance } from "../src/utils/sponsored_fpc.js";
import { SponsoredFPCContract } from "@aztec/noir-contracts.js/SponsoredFPC";
import { deploySchnorrAccount } from "../src/utils/deploy_account.js";

async function main() {

    let pxe: PXE;
    let logger: Logger;

    logger = createLogger('aztec:CMTAToken');
    logger.info('Starting CMTA Token deployment script...');

    pxe = await setupPXETestnet();

    const sponsoredFPC = await getSponsoredFPCInstance();
    await pxe.registerContract({ instance: sponsoredFPC, artifact: SponsoredFPCContract.artifact });
    const sponsoredPaymentMethod = new SponsoredFeePaymentMethod(sponsoredFPC.address);

    let accountManager = await deploySchnorrAccount(pxe);
    const wallet = await accountManager.getWallet();
    const address = await accountManager.getAddress();

    const tokenName = 'CMTAToken'
    const tokenSymbol = 'CMTAT'
    const tokenDecimals = 18n


    const tokenContract = await TokenContract.deploy(wallet, address, tokenName, tokenSymbol, tokenDecimals).send({ fee: { paymentMethod: sponsoredPaymentMethod } }).deployed({timeout: 120000});
    logger.info(`CMTA Token Contract deployed at: ${tokenContract.address}`);
    const tokenContractAddress = tokenContract.address.toString();

    const tokenContractIssuer = await TokenContract.at(
            AztecAddress.fromString(tokenContractAddress),
            wallet,
        );

    const initialSupply = 1_000_000n * 10n ** 18n; // 1 million tokens with 18 decimals
    console.log(`Issuer gets minter role ...`);
    const minterRole = 7n;
    let receipt = await tokenContractIssuer.methods.grant_role(minterRole, wallet.getAddress()).send({ fee: { paymentMethod: sponsoredPaymentMethod } }).wait({timeout: 120000});

}

main();