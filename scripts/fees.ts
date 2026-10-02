// Walks through the fee payment methods this project can use on a local network.
//
// Two of the modes the pre-v3 version of this script demonstrated are gone: `FeeJuicePaymentMethod`
// no longer exists (an account that holds Fee Juice now pays with it automatically when no payment
// method is given), and the reference FPC's `PrivateFeePaymentMethod` / `PublicFeePaymentMethod` are
// deprecated and do not work beyond a local network. Paying in another token now goes through a
// third-party FPC's own SDK, which is out of scope here.
import { NO_FROM } from "@aztec/aztec.js/account";
import { createExtendedL1Client } from "@aztec/ethereum/client";
import { L1FeeJuicePortalManager } from "@aztec/aztec.js/ethereum";
import { FeeJuicePaymentMethodWithClaim } from "@aztec/aztec.js/fee";
import { Fr, GrumpkinScalar } from "@aztec/aztec.js/fields";
import { createLogger } from "@aztec/aztec.js/log";
import * as dotenv from 'dotenv';
import { l1Mnemonic } from '../src/utils/l1_dev_account.js';

import { CMTATAztecContract as TokenContract } from "../src/artifacts/CMTATAztec.js";
import { deploySchnorrAccount } from "../src/utils/deploy_account.js";
import { getSponsoredPaymentMethod } from "../src/utils/sponsored_fpc.js";
import { setupWallet } from "../src/utils/setup_pxe.js";

dotenv.config();


const MNEMONIC = l1Mnemonic();
const FEE_FUNDING_FOR_TESTER_ACCOUNT = 1000000000000000000n;

async function main() {
    const logger = createLogger('aztec:CMTAToken');
    logger.info('Starting Fee Juice script...');

    if (!process.env.L1_URL) {
        throw new Error('L1_URL is not set. Copy .env.example to .env and point it at an L1 RPC.');
    }

    const { node, wallet } = await setupWallet();

    // 1. Sponsored FPC: pays unconditionally, so a fresh account can transact with no funding.
    const sponsoredPaymentMethod = await getSponsoredPaymentMethod(wallet);
    const funder = await deploySchnorrAccount(wallet);

    const tokenName = 'CMTAToken';
    const tokenSymbol = 'CMTAT';
    const { contract: token } = await TokenContract.deploy(
        wallet,
        funder,
        tokenName,
        tokenSymbol,
        18,
    ).send({ from: funder, fee: { paymentMethod: sponsoredPaymentMethod } });
    logger.info(`Token deployed at ${token.address}, fees paid by the sponsored FPC.`);

    // 2. Bridge Fee Juice from L1 and claim it while deploying the account that will use it.
    const l1Client = createExtendedL1Client([process.env.L1_URL], MNEMONIC);
    const feeJuicePortalManager = await L1FeeJuicePortalManager.new(node, l1Client, logger);

    const feeJuiceAccount = await wallet.createSchnorrAccount(
        Fr.random(),
        Fr.random(),
        GrumpkinScalar.random(),
    );
    const claim = await feeJuicePortalManager.bridgeTokensPublic(
        feeJuiceAccount.address,
        FEE_FUNDING_FOR_TESTER_ACCOUNT,
        true,
    );
    logger.info(`Fee Juice bridged to ${feeJuiceAccount.address}.`);

    // Two arbitrary txs so the L1 message becomes available on L2.
    for (let i = 0; i < 2; i++) {
        await token.methods
            .grant_role(7n, funder)
            .send({ from: funder, fee: { paymentMethod: sponsoredPaymentMethod } });
    }

    const claimAndPay = new FeeJuicePaymentMethodWithClaim(feeJuiceAccount.address, claim);
    const deployMethod = await feeJuiceAccount.getDeployMethod();
    await deployMethod.send({ from: NO_FROM, fee: { paymentMethod: claimAndPay } });
    logger.info(`Account ${feeJuiceAccount.address} deployed using claimed Fee Juice for fees.`);

    // 3. Fee Juice directly: the account now holds Fee Juice, so no payment method is needed.
    const { receipt } = await token.methods
        .grant_role(7n, feeJuiceAccount.address)
        .send({ from: feeJuiceAccount.address });
    logger.info(`Transaction paid from the account's own Fee Juice, fee: ${receipt.transactionFee}`);
}

main().catch((error) => {
    console.error("Error:", error);
    process.exit(1);
});
