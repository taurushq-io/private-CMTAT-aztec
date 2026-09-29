import { AztecAddress } from "@aztec/aztec.js/addresses";
import { Fr, GrumpkinScalar } from "@aztec/aztec.js/fields";
import { createLogger } from "@aztec/aztec.js/log";
import type { Logger } from "@aztec/aztec.js/log";
import { NO_FROM } from "@aztec/aztec.js/account";
import type { SponsoredFeePaymentMethod } from "@aztec/aztec.js/fee/testing";
import type { EmbeddedWallet } from "@aztec/wallets/embedded";
import { spawn } from "child_process";

import { CMTATAztecContract as TokenContract } from "../../artifacts/CMTATAztec.js";
import { getSponsoredPaymentMethod } from "../../utils/sponsored_fpc.js";
import { setupWallet } from "../../utils/setup_pxe.js";
import { advancePastDelay } from "../../utils/time_travel.js";

const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

// The issuer address is a DelayedPublicMutable, so the value the constructor schedules only becomes
// current after this many seconds - and every mint, transfer and burn reads it. Keep in sync with
// CHANGE_ROLES_DELAY_SECONDS in src/main.nr.
const CHANGE_ROLES_DELAY_SECONDS = 3600;
const DELAY_MS = (CHANGE_ROLES_DELAY_SECONDS + 12) * 1000;

// `advancePastDelay` warps the chain's clock on a local network and only falls back to sleeping
// when it cannot (a real network, or E2E_REAL_CLOCK=true). The timeout therefore has to cover the
// slow path, and it is DERIVED from the delay rather than hard-coded: a test that may sleep
// DELAY_MS under a smaller timeout can never pass, which is what happened when
// CHANGE_ROLES_DELAY_SECONDS went from 360 to 3600 and this constant stayed at 900_000.
const LONG_TEST_TIMEOUT = DELAY_MS + 600_000;

describe("Token", () => {
    let node: Awaited<ReturnType<typeof setupWallet>>['node'];
    let wallet: EmbeddedWallet;
    let issuer: AztecAddress;
    let alice: AztecAddress;
    let bob: AztecAddress;
    let contractAddress: AztecAddress;
    let token: TokenContract;
    let sponsoredPaymentMethod: SponsoredFeePaymentMethod;

    let logger: Logger;
    let sandboxInstance: ReturnType<typeof spawn> | undefined;
    let skipSandbox: boolean;

    // Creates and deploys a Schnorr account, paying with the sponsored FPC.
    const newAccount = async (): Promise<AztecAddress> => {
        const account = await wallet.createSchnorrAccount(
            Fr.random(),
            Fr.random(),
            GrumpkinScalar.random(),
        );
        const deployMethod = await account.getDeployMethod();
        await deployMethod.send({ from: NO_FROM, fee: { paymentMethod: sponsoredPaymentMethod } });
        return account.address;
    };

    beforeAll(async () => {
        skipSandbox = process.env.SKIP_SANDBOX === 'true';
        if (!skipSandbox) {
            sandboxInstance = spawn("aztec", ["start", "--local-network"], {
                detached: true,
                stdio: 'ignore',
            });
            await sleep(15000);
        }

        logger = createLogger('aztec:cmtat:e2e');
        logger.info("private-CMTAT-aztec tests running.");

        ({ node, wallet } = await setupWallet());
        sponsoredPaymentMethod = await getSponsoredPaymentMethod(wallet);

        // All three accounts live in the same wallet, which is what lets this suite read every
        // balance. A production deployment gives each holder their own wallet.
        issuer = await newAccount();
        alice = await newAccount();
        bob = await newAccount();
    }, LONG_TEST_TIMEOUT);

    afterAll(async () => {
        if (!skipSandbox) {
            sandboxInstance?.kill('SIGINT');
        }
    });

    it("Deploys the contract", async () => {
        const tokenName = 'TEST';
        const tokenSymbol = 'TT';
        const tokenDecimals = 18;

        const deployer = await newAccount();

        const { contract, receipt } = await TokenContract.deploy(
            wallet,
            issuer,
            tokenName,
            tokenSymbol,
            tokenDecimals,
            false, // public_side_enabled: keep the fully private token
        ).send({ from: deployer, fee: { paymentMethod: sponsoredPaymentMethod } });

        expect(receipt.hasExecutionSucceeded()).toBe(true);

        contractAddress = contract.address;
        const metadata = await wallet.getContractMetadata(contractAddress);
        expect(metadata.instance).toBeTruthy();

        logger.info(`Contract successfully deployed at address ${contractAddress.toString()}`);
        token = await TokenContract.at(contractAddress, wallet);

        // The constructor only schedules the issuer address; nothing that reads it works until the
        // delay has elapsed AND a block exists past that point, because a private function is
        // proved against the chain tip. advancePastDelay does both and verifies the tip moved.
        // newAccount() is the block the warp needs: a transaction that does not read the
        // delayed issuer address, so it can be built against the pre-delay anchor.
        await advancePastDelay(node, CHANGE_ROLES_DELAY_SECONDS, newAccount, logger);

        const { result: onChainIssuer } = await token.methods
            .public_get_issuer()
            .simulate({ from: issuer });
        expect(onChainIssuer.toString()).toEqual(issuer.toString());
    }, LONG_TEST_TIMEOUT);

    describe("Normal user flow", () => {
        it("Issuer privately mints initial token supply to Alice", async () => {
            const initialSupply = 1_000_000n;

            logger.info(`Issuer gets minter role ...`);
            const minterRole = 7n;
            const { receipt } = await token.methods
                .grant_role(minterRole, issuer)
                .send({ from: issuer, fee: { paymentMethod: sponsoredPaymentMethod } });
            expect(receipt.hasExecutionSucceeded()).toBe(true);

            const { result: isMinter } = await token.methods
                .has_role(minterRole, issuer)
                .simulate({ from: issuer });
            expect(isMinter).toEqual(1n);

            logger.info(`Minting tokens to Alice ...`);
            const { receipt: mintReceipt } = await token.methods
                .mint_to_private(alice, initialSupply)
                .send({ from: issuer, fee: { paymentMethod: sponsoredPaymentMethod } });
            expect(mintReceipt.hasExecutionSucceeded()).toBe(true);

            const { result: balanceAlice } = await token.methods
                .balance_of_private(alice)
                .simulate({ from: alice });
            expect(balanceAlice).toEqual(initialSupply);

            const { result: supplyAfter } = await token.methods.total_supply().simulate({ from: issuer });
            expect(supplyAfter).toEqual(initialSupply);
            logger.info(`${supplyAfter} tokens as initial supply minted by issuer`);
        }, LONG_TEST_TIMEOUT);

        it("Issuer privately mints tokens to Bob", async () => {
            const bobTokens = 1000n;

            const { receipt } = await token.methods
                .mint_to_private(bob, bobTokens)
                .send({ from: issuer, fee: { paymentMethod: sponsoredPaymentMethod } });
            expect(receipt.hasExecutionSucceeded()).toBe(true);

            const { result: balanceBob } = await token.methods
                .balance_of_private(bob)
                .simulate({ from: bob });
            expect(balanceBob).toEqual(bobTokens);

            const { result: supplyAfter } = await token.methods.total_supply().simulate({ from: issuer });
            expect(supplyAfter).toEqual(1_001_000n);
        }, LONG_TEST_TIMEOUT);

        it("queries the token balance for each account", async () => {
            const { result: aliceBalance } = await token.methods
                .balance_of_private(alice)
                .simulate({ from: alice });
            expect(aliceBalance).toEqual(1_000_000n);

            const { result: bobBalance } = await token.methods
                .balance_of_private(bob)
                .simulate({ from: bob });
            expect(bobBalance).toEqual(1000n);
        }, LONG_TEST_TIMEOUT);

        it("transfers funds from Alice to Bob", async () => {
            const transferQuantity = 543n;
            const { receipt } = await token.methods
                .transfer_private_to_private(alice, bob, transferQuantity, 0)
                .send({ from: alice, fee: { paymentMethod: sponsoredPaymentMethod } });
            expect(receipt.hasExecutionSucceeded()).toBe(true);

            const { result: aliceBalance } = await token.methods
                .balance_of_private(alice)
                .simulate({ from: alice });
            expect(aliceBalance).toEqual(1_000_000n - transferQuantity);

            const { result: bobBalance } = await token.methods
                .balance_of_private(bob)
                .simulate({ from: bob });
            expect(bobBalance).toEqual(1000n + transferQuantity);
        }, LONG_TEST_TIMEOUT);

        it("transfers funds from Bob to issuer", async () => {
            const transferQuantity = 1000n;
            const { receipt } = await token.methods
                .transfer_private_to_private(bob, issuer, transferQuantity, 0)
                .send({ from: bob, fee: { paymentMethod: sponsoredPaymentMethod } });
            expect(receipt.hasExecutionSucceeded()).toBe(true);

            const { result: issuerBalance } = await token.methods
                .balance_of_private(issuer)
                .simulate({ from: issuer });
            expect(issuerBalance).toEqual(transferQuantity);
        }, LONG_TEST_TIMEOUT);

        it("Issuer is able to burn tokens of Bob", async () => {
            logger.info(`Issuer gets burner role ...`);
            const burnerRole = 8n;
            const { receipt } = await token.methods
                .grant_role(burnerRole, issuer)
                .send({ from: issuer, fee: { paymentMethod: sponsoredPaymentMethod } });
            expect(receipt.hasExecutionSucceeded()).toBe(true);

            const { result: isBurner } = await token.methods
                .has_role(burnerRole, issuer)
                .simulate({ from: issuer });
            expect(isBurner).toEqual(1n);

            const { result: bobBalanceBefore } = await token.methods
                .balance_of_private(bob)
                .simulate({ from: bob });

            // The issuer burns on Bob's behalf: a non-zero authwit nonce is required, and the wallet
            // produces Bob's authwit during the simulation that precedes the send.
            const burnTokens = 43n;
            const authwitNonce = Fr.random();
            await token.methods
                .burn(bob, burnTokens, authwitNonce)
                .send({
                    from: issuer,
                    additionalScopes: [bob],
                    fee: { paymentMethod: sponsoredPaymentMethod },
                });

            const { result: bobBalanceAfter } = await token.methods
                .balance_of_private(bob)
                .simulate({ from: bob });
            expect(bobBalanceAfter).toEqual(bobBalanceBefore - burnTokens);
        }, LONG_TEST_TIMEOUT);
    });

    describe("Failure Cases", () => {
        it("bob tries to mint some tokens", async () => {
            const mintQuantity = 1000n;
            await expect(
                token.methods
                    .mint_to_private(bob, mintQuantity)
                    .send({ from: bob, fee: { paymentMethod: sponsoredPaymentMethod } }),
            ).rejects.toThrow();
        }, LONG_TEST_TIMEOUT);

        it("bob tries to burn some tokens", async () => {
            const burnQuantity = 1000n;
            await expect(
                token.methods
                    .burn(bob, burnQuantity, 0)
                    .send({ from: bob, fee: { paymentMethod: sponsoredPaymentMethod } }),
            ).rejects.toThrow();
        }, LONG_TEST_TIMEOUT);
    });

    describe("Access Control Cases", () => {
        it("Bob tries to set itself as a new admin", async () => {
            const adminRole = 1n;
            await expect(
                token.methods
                    .grant_role(adminRole, bob)
                    .send({ from: bob, fee: { paymentMethod: sponsoredPaymentMethod } }),
            ).rejects.toThrow();
        }, LONG_TEST_TIMEOUT);

        it("Admin sets Bob as new admin", async () => {
            const adminRole = 1n;
            await token.methods
                .grant_role(adminRole, bob)
                .send({ from: issuer, fee: { paymentMethod: sponsoredPaymentMethod } });

            const { result: bobRole } = await token.methods
                .has_role(adminRole, bob)
                .simulate({ from: issuer });
            expect(bobRole).toEqual(1n);
        }, LONG_TEST_TIMEOUT);

        it("Admin removes Bob as admin", async () => {
            const adminRole = 1n;
            await token.methods
                .revoke_role(adminRole, bob)
                .send({ from: issuer, fee: { paymentMethod: sponsoredPaymentMethod } });

            const { result: bobRole } = await token.methods
                .has_role(adminRole, bob)
                .simulate({ from: issuer });
            expect(bobRole).toEqual(0n);
        }, LONG_TEST_TIMEOUT);
    });

    describe("Pause Module tests", () => {
        it("Admin can pause the contract - no transactions can be done", async () => {
            const pauserRole = 2n;
            const { receipt } = await token.methods
                .grant_role(pauserRole, issuer)
                .send({ from: issuer, fee: { paymentMethod: sponsoredPaymentMethod } });
            expect(receipt.hasExecutionSucceeded()).toBe(true);

            const { result: isPauser } = await token.methods
                .has_role(pauserRole, issuer)
                .simulate({ from: issuer });
            expect(isPauser).toEqual(1n);

            await token.methods
                .pause_contract()
                .send({ from: issuer, fee: { paymentMethod: sponsoredPaymentMethod } });

            const { result: paused } = await token.methods
                .public_get_pause()
                .simulate({ from: issuer });
            expect(paused).toEqual(1n);

            await expect(
                token.methods
                    .transfer_private_to_private(bob, alice, 10, 0)
                    .send({ from: bob, fee: { paymentMethod: sponsoredPaymentMethod } }),
            ).rejects.toThrow();
        }, LONG_TEST_TIMEOUT);

        it("Admin can unpause the contract", async () => {
            await token.methods
                .unpause_contract()
                .send({ from: issuer, fee: { paymentMethod: sponsoredPaymentMethod } });

            const { result: paused } = await token.methods
                .public_get_pause()
                .simulate({ from: issuer });
            expect(paused).toEqual(0n);

            const { receipt } = await token.methods
                .transfer_private_to_private(bob, alice, 10, 0)
                .send({ from: bob, fee: { paymentMethod: sponsoredPaymentMethod } });
            expect(receipt.hasExecutionSucceeded()).toBe(true);
        }, LONG_TEST_TIMEOUT);
    });
});
