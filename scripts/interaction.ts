import { createLogger, Logger, SponsoredFeePaymentMethod, Fr, AztecAddress, TxStatus, sleep, PXE } from "@aztec/aztec.js";
import { CMTATokenContractArtifact as TokenContractArtifact, CMTATokenContract as TokenContract} from "../src/artifacts/CMTAToken.js"
import { SponsoredFPCContract } from "@aztec/noir-contracts.js/SponsoredFPC";
import { setupPXE } from "../src/utils/setup_pxe.js";
import { getSponsoredFPCInstance } from "../src/utils/sponsored_fpc.js";
import { getAccountFromEnv } from "../src/utils/create_account_from_env.js";
import { setupPXETestnet } from "../src/utils/setup_pxe_testnet.js";
import * as dotenv from 'dotenv';

dotenv.config();

async function sleepForBlocks(pxe: PXE, numBlocks) {
  const startBlock = await pxe.getBlockNumber();
  let currentBlock = startBlock;
  while (currentBlock < startBlock + numBlocks) {
    sleep(1000); // Sleep for 1 second
    currentBlock = await pxe.getBlockNumber();
  }
}

async function main() {
    let logger: Logger;
    logger = createLogger('aztec:CMTATokenInteraction');

    // Setup PXE
    const pxe = await setupPXETestnet();

    // Setup sponsored fee payment
    const sponsoredFPC = await getSponsoredFPCInstance();
    await pxe.registerContract({ instance: sponsoredFPC, artifact: SponsoredFPCContract.artifact });
    const sponsoredPaymentMethod = new SponsoredFeePaymentMethod(sponsoredFPC.address);

    // Get account from environment variables
    const accounts = await getAccountFromEnv(pxe,2);
    const issuer = accounts[0];
    const user1 = accounts[1];
    const issuerWallet = await issuer.getWallet();
    const user1Wallet = await user1.getWallet();
    const contractAddress = process.env.CMTA_TOKEN_CONTRACT_ADDRESS;

    if (!contractAddress) {
        logger.error("Please set CMTA_TOKEN_CONTRACT_ADDRESS environment variable with your deployed contract address");
        return;
    }

    logger.info(`Connecting to CMTA Token contract at: ${contractAddress}`);
    logger.info(`Issuer address: ${issuerWallet.getAddress()}`);
    logger.info(`User1 address: ${user1Wallet.getAddress()}`);
    const tokenContractIssuer = await TokenContract.at(
        AztecAddress.fromString(contractAddress),
        issuerWallet,
    );

    const tokenContractAlice = await TokenContract.at(
        AztecAddress.fromString(contractAddress),
        user1Wallet,
    );

    const initialSupply = 1_000_000n * 10n ** 18n; // 1 million tokens with 18 decimals

    console.log(`Issuer gets minter role ...`);
    const minterRole = 7n;
    let receipt = await tokenContractIssuer.methods.grant_role(minterRole, issuerWallet.getAddress()).send({ fee: { paymentMethod: sponsoredPaymentMethod } }).wait({timeout: 120000});
    const DELAY = 2;
    console.log(`Waiting ${DELAY} blocks for the minter role to be granted...`);
    sleepForBlocks(pxe, DELAY);
    console.log(`Minter role granted to issuer: ${issuerWallet.getAddress()}`);
    const isMinter = await tokenContractIssuer.methods.has_role(minterRole, issuerWallet.getAddress()).simulate();

    console.log(`Minting tokens to Alice ...`);

    receipt = await tokenContractIssuer.methods.mint(user1Wallet.getAddress(),initialSupply).send({ fee: { paymentMethod: sponsoredPaymentMethod } }).wait({timeout: 120000});

    const balanceAlice = await tokenContractAlice.methods.balance_of_private(user1Wallet.getAddress()).simulate();
    console.log(`Alice's balance after minting: ${balanceAlice} tokens`);
    const supplyAfter = await tokenContractIssuer.methods.total_supply().simulate();
    console.log(`${supplyAfter} tokens as initial supply minted by issuer`);
    console.log("End of CMTA Token interaction script");
}

main().catch((error) => {
    console.error("Error:", error);
    process.exit(1);
}); 