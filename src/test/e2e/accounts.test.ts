import { NO_FROM } from "@aztec/aztec.js/account";
import { AztecAddress } from "@aztec/aztec.js/addresses";
import { createEthereumChain } from "@aztec/ethereum/chain";
import { createExtendedL1Client } from "@aztec/ethereum/client";
import { L1FeeJuicePortalManager } from "@aztec/aztec.js/ethereum";
import type { L2AmountClaim } from "@aztec/aztec.js/ethereum";
import { FeeJuicePaymentMethodWithClaim } from "@aztec/aztec.js/fee";
import type { SponsoredFeePaymentMethod } from "@aztec/aztec.js/fee/testing";
import { Fr, GrumpkinScalar } from "@aztec/aztec.js/fields";
import { createLogger } from "@aztec/aztec.js/log";
import type { Logger } from "@aztec/aztec.js/log";
import { getFeeJuiceBalance } from "@aztec/aztec.js/utils";
import type { AztecNode } from "@aztec/aztec.js/node";
import type { AccountManager } from "@aztec/aztec.js/wallet";
import type { EmbeddedWallet } from "@aztec/wallets/embedded";
import { spawn } from 'child_process';

import { CMTATAztecContract as TokenContract } from "../../artifacts/CMTATAztec.js";
import { getSponsoredPaymentMethod } from "../../utils/sponsored_fpc.js";
import { setupWallet } from "../../utils/setup_pxe.js";
import { waitForL1ToL2Messages } from "../../utils/l1_to_l2_message.js";
import { l1Mnemonic } from "../../utils/l1_dev_account.js";

const sleep = (ms: number) => new Promise(resolve => setTimeout(resolve, ms));

describe("Accounts", () => {
    let node: AztecNode;
    let wallet: EmbeddedWallet;
    let logger: Logger;
    let sandboxInstance: ReturnType<typeof spawn> | undefined;
    let sponsoredPaymentMethod: SponsoredFeePaymentMethod;
    let owner: AztecAddress;

    let randomAccounts: AccountManager[] = [];
    let randomAddresses: AztecAddress[] = [];

    let l1PortalManager: L1FeeJuicePortalManager;
    let skipSandbox: boolean;

    const tokenName = 'TEST';
    const tokenSymbol = 'TT';
    const tokenDecimals = 18;

    beforeAll(async () => {
        skipSandbox = process.env.SKIP_SANDBOX === 'true';
        if (!skipSandbox) {
            sandboxInstance = spawn("aztec", ["start", "--local-network"], {
                detached: true,
                stdio: 'ignore',
            });
            await sleep(15000);
        }

        logger = createLogger('aztec:cmtat:accounts');
        logger.info("private-CMTAT-aztec account tests running.");

        ({ node, wallet } = await setupWallet());
        sponsoredPaymentMethod = await getSponsoredPaymentMethod(wallet);

        // create default ethereum clients
        const nodeInfo = await node.getNodeInfo();
        const chain = createEthereumChain(['http://localhost:8545'], nodeInfo.l1ChainId);
        const l1Client = createExtendedL1Client(chain.rpcUrls, l1Mnemonic(), chain.chainInfo);

        l1PortalManager = await L1FeeJuicePortalManager.new(node, l1Client, logger);

        const ownerAccount = await wallet.createSchnorrAccount(
            Fr.random(),
            Fr.random(),
            GrumpkinScalar.random(),
        );
        const ownerDeploy = await ownerAccount.getDeployMethod();
        await ownerDeploy.send({ from: NO_FROM, fee: { paymentMethod: sponsoredPaymentMethod } });
        owner = ownerAccount.address;
    }, 300_000);

    beforeEach(async () => {
        randomAccounts = await Promise.all(
            [0, 1].map(() =>
                wallet.createSchnorrAccount(Fr.random(), Fr.random(), GrumpkinScalar.random()),
            ),
        );
        randomAddresses = randomAccounts.map(a => a.address);
    });

    afterAll(async () => {
        if (!skipSandbox) {
            sandboxInstance?.kill('SIGINT');
        }
    });

    it("Creates accounts with fee juice", async () => {
        // balance of each random account is 0 before bridge
        let balances = await Promise.all(randomAddresses.map(a => getFeeJuiceBalance(a, node)));
        balances.forEach(b => expect(b).toBe(0n));

        // bridge funds to unfunded random addresses. The amount is not ours to choose: the L1
        // portal's test handler mints a fixed quantity and rejects anything else with
        // "Minting amount must be ...", so read it rather than hard-coding one.
        const claimAmount = await l1PortalManager.getTokenManager().getMintAmount();
        const claims: L2AmountClaim[] = [];
        // bridge sequentially to avoid l1 txs (nonces) being processed out of order
        for (const address of randomAddresses) {
            claims.push(await l1PortalManager.bridgeTokensPublic(address, claimAmount, true));
        }

        // The deposits are on L1; they become claimable only once a proposer has included them in an
        // L2 block. Produce blocks until the node can serve a membership witness for each message,
        // rather than assuming a fixed number - see src/utils/l1_to_l2_message.ts.
        await waitForL1ToL2Messages(
            node,
            claims.map(c => c.messageHash),
            () =>
                TokenContract.deploy(wallet, owner, tokenName, tokenSymbol, tokenDecimals, false)
                    .send({ from: owner, fee: { paymentMethod: sponsoredPaymentMethod } }),
            logger,
        );

        // claim and pay to deploy random accounts
        const fees: bigint[] = [];
        for (let i = 0; i < randomAccounts.length; i++) {
            const paymentMethod = new FeeJuicePaymentMethodWithClaim(randomAddresses[i], claims[i]);
            const deployMethod = await randomAccounts[i].getDeployMethod();
            const { receipt } = await deployMethod.send({ from: NO_FROM, fee: { paymentMethod } });
            expect(receipt.transactionFee).toBeGreaterThan(0n);
            fees.push(receipt.transactionFee!);
        }

        // Balance after the deploy: the claim minus what the transaction actually cost. The test
        // used to compare against a hard-coded upper bound on the fee, which went stale - the real
        // cost is now roughly 7.6e12 against a bound of 1e10 - so take the figure from the receipt.
        balances = await Promise.all(randomAddresses.map(a => getFeeJuiceBalance(a, node)));
        balances.forEach((b, i) => expect(b).toBe(claimAmount - fees[i]));
    }, 600_000);

    it("Deploys first unfunded account from first funded account", async () => {
        // The owner pays, so the new account needs no funds of its own.
        const deployMethod = await randomAccounts[0].getDeployMethod();
        const { receipt } = await deployMethod.send({
            from: owner,
            fee: { paymentMethod: sponsoredPaymentMethod },
        });

        expect(receipt.hasExecutionSucceeded()).toBe(true);

        const metadata = await wallet.getContractMetadata(randomAddresses[0]);
        expect(metadata.instance).toBeTruthy();
    }, 300_000);

    it("Sponsored contract deployment", async () => {
        const salt = Fr.random();

        const { contract, receipt } = await TokenContract.deploy(
            wallet,
            owner,
            tokenName,
            tokenSymbol,
            tokenDecimals,
            false,
            { salt, deployer: owner },
        ).send({
            from: owner,
            // without the sponsoredFPC the deployment fails, thus confirming it works
            fee: { paymentMethod: sponsoredPaymentMethod },
        });

        expect(receipt.hasExecutionSucceeded()).toBe(true);

        const metadata = await wallet.getContractMetadata(contract.address);
        expect(metadata.instance).toBeTruthy();
    }, 300_000);
});
