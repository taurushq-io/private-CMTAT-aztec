import { CMTATokenContractArtifact as TokenContractArtifact, CMTATokenContract as TokenContract } from "../../artifacts/CMTAToken.js"
import { AccountManager, AccountWallet, AccountWalletWithSecretKey, CompleteAddress, ContractDeployer, createLogger, Fr, PXE, TxStatus, getContractInstanceFromDeployParams, Logger, ContractInstanceWithAddress } from "@aztec/aztec.js";
import { getInitialTestAccountsWallets, getDeployedTestAccountsWallets } from "@aztec/accounts/testing"
import { format } from 'util';
import { generateSchnorrAccounts } from "@aztec/accounts/testing"
import { getSchnorrAccount } from '@aztec/accounts/schnorr';
import { spawn } from 'child_process';
import { SponsoredFeePaymentMethod } from '@aztec/aztec.js/fee/testing'
import { L1FeeJuicePortalManager, AztecAddress } from "@aztec/aztec.js";
import { createEthereumChain, createExtendedL1Client } from '@aztec/ethereum';
import { getSponsoredFPCInstance } from "../../utils/sponsored_fpc.js";
import { setupPXE } from "../../utils/setup_pxe.js";
import { SponsoredFPCContract } from "@aztec/noir-contracts.js/SponsoredFPC";
import { deriveSigningKey } from "@aztec/stdlib/keys";



const advanceBlocks = async (contract: TokenContract, sponsoredPaymentMethod: SponsoredFeePaymentMethod) : Promise<boolean> => {
    const DELAY = 2;
    for (let i = 0; i < DELAY; ++i) {
        await contract.methods.get_operations().send({ fee: { paymentMethod: sponsoredPaymentMethod } }).wait();
      }

    return true
}

const sleep = (ms: number) => new Promise(resolve => setTimeout(resolve, ms));


describe("Token", () => {
    let pxe: PXE;
    let issuer: AztecAddress;
    let issuerWallet: AccountWallet;
    let alice: AztecAddress;
    let aliceWallet: AccountWallet;
    let bob: AztecAddress;
    let bobWallet: AccountWallet;
    let contractAddress: AztecAddress;
    //what is a tokenContract?
    let tokenContractIssuer: TokenContract;
    let tokenContractBob: TokenContract;
    let tokenContractAlice: TokenContract;
    let sponsoredFPC: ContractInstanceWithAddress;
    let sponsoredPaymentMethod: SponsoredFeePaymentMethod;


    let randomWallets: AccountWallet[] = [];
    let randomAddresses: AztecAddress[] = [];
    let randomAccountManagers: AccountManager[] = [];

    let l1PortalManager: L1FeeJuicePortalManager;
    let logger: Logger;
    let sandboxInstance;
    let skipSandbox: boolean;


    beforeAll(async () => {
        skipSandbox = process.env.SKIP_SANDBOX === 'true';
        if (!skipSandbox) {
            sandboxInstance = spawn("aztec", ["start", "--sandbox"], {
                detached: true,
                stdio: 'ignore'
            })
            await sleep(15000);
        }

        logger = createLogger('aztec:aztec-starter:voting');
        logger.info("Aztec-Starter tests running.")

        pxe = await setupPXE();

        sponsoredFPC = await getSponsoredFPCInstance();
        await pxe.registerContract({ instance: sponsoredFPC, artifact: SponsoredFPCContract.artifact });
        sponsoredPaymentMethod = new SponsoredFeePaymentMethod(sponsoredFPC.address);

        // generate random accounts
        randomAccountManagers = await Promise.all(
            (await generateSchnorrAccounts(5)).map(
                a => getSchnorrAccount(pxe, a.secret, a.signingKey, a.salt)
            )
        );
        // get corresponding wallets
        randomWallets = await Promise.all(randomAccountManagers.map(am => am.getWallet()));
        // get corresponding addresses
        randomAddresses = await Promise.all(randomWallets.map(async w => (await w.getCompleteAddress()).address));

        // create default ethereum clients
        const nodeInfo = await pxe.getNodeInfo();
        const chain = createEthereumChain(['http://localhost:8545'], nodeInfo.l1ChainId);
        const DefaultMnemonic = 'test test test test test test test test test test test junk';
        const l1Client = createExtendedL1Client(chain.rpcUrls, DefaultMnemonic, chain.chainInfo);

        // create portal manager
        l1PortalManager = await L1FeeJuicePortalManager.new(
            pxe,
            l1Client,
            logger
        );

        // Set up issuer wallet
        let issuerSecretKey = Fr.random();
        let issuerSalt = Fr.random();
        let issuerSchnorrAccount = await getSchnorrAccount(pxe, issuerSecretKey, deriveSigningKey(issuerSecretKey), issuerSalt);
        await issuerSchnorrAccount.deploy({ fee: { paymentMethod: sponsoredPaymentMethod } }).wait();
        issuerWallet = await issuerSchnorrAccount.getWallet();
        issuer = (await issuerWallet.getCompleteAddress()).address;

        // Set up alice wallet
        let aliceSecretKey = Fr.random();
        let aliceSalt = Fr.random();
        let aliceSchnorrAccount = await getSchnorrAccount(pxe, aliceSecretKey, deriveSigningKey(aliceSecretKey), aliceSalt);
        await aliceSchnorrAccount.deploy({ fee: { paymentMethod: sponsoredPaymentMethod } }).wait();
        aliceWallet = await aliceSchnorrAccount.getWallet();
        alice = (await aliceWallet.getCompleteAddress()).address;

        // Set up bob wallet
        let bobSecretKey = Fr.random();
        let bobSalt = Fr.random();
        let bobSchnorrAccount = await getSchnorrAccount(pxe, bobSecretKey, deriveSigningKey(bobSecretKey), bobSalt);
        await bobSchnorrAccount.deploy({ fee: { paymentMethod: sponsoredPaymentMethod } }).wait();
        bobWallet = await bobSchnorrAccount.getWallet();
        bob = (await bobWallet.getCompleteAddress()).address;

    })

     afterAll(async () => {
        if (!skipSandbox) {
            sandboxInstance!.kill('SIGINT');
        }
    })

    it("Deploys the contract", async () => {        

        const salt = Fr.random();
        const accounts = await Promise.all(
            (await generateSchnorrAccounts(2)).map(
                async a => await getSchnorrAccount(pxe, a.secret, a.signingKey, a.salt)
            )
        );
        await Promise.all(accounts.map(a => a.deploy({ fee: { paymentMethod: sponsoredPaymentMethod } }).wait()));
        const daWallets = await Promise.all(accounts.map(a => a.getWallet()));
        const [deployerWallet, adminWallet] = daWallets;
        const [deployerAddress, adminAddress] = daWallets.map(w => w.getAddress());


        const tokenName = 'TEST'
        const tokenSymbol = 'TT'
        const tokenDecimals = 18n

        const CMTATContractArtifact = TokenContractArtifact
        const deploymentData = await getContractInstanceFromDeployParams(CMTATContractArtifact,
            {
                constructorArgs: [issuer, tokenName, tokenSymbol, tokenDecimals],
                salt,
                deployer: deployerWallet.getAddress()
            });

                const deployer = new ContractDeployer(CMTATContractArtifact, deployerWallet);
        const tx = deployer.deploy(issuer,  tokenName, tokenSymbol, tokenDecimals).send({
            contractAddressSalt: salt,
            fee: { paymentMethod: sponsoredPaymentMethod } // without the sponsoredFPC the deployment fails, thus confirming it works
        })
        const receipt = await tx.getReceipt();

        expect(receipt).toEqual(
            expect.objectContaining({
                status: TxStatus.PENDING,
                error: ''
            }),
        );

        const receiptAfterMined = await tx.wait({ wallet: deployerWallet });
        expect(await pxe.getContractMetadata(deploymentData.address)).toBeDefined();
        expect((await pxe.getContractMetadata(deploymentData.address)).contractInstance).toBeTruthy();
        expect(receiptAfterMined).toEqual(
            expect.objectContaining({
                status: TxStatus.SUCCESS,
            }),
        );
        
        contractAddress = deploymentData.address;
        expect(receiptAfterMined.contract.instance.address).toEqual(deploymentData.address)


        console.log(`Contract successfully deployed at address ${contractAddress.toString()}`);
        tokenContractIssuer = await TokenContract.at(contractAddress, issuerWallet);
        tokenContractAlice = await TokenContract.at(contractAddress, aliceWallet);
        tokenContractBob = await TokenContract.at(contractAddress, bobWallet);


        expect(await advanceBlocks(tokenContractIssuer, sponsoredPaymentMethod)).toBeTruthy();

    }, 300_000)

    describe("Normal user flow", () => {


    it("Issuer privately mints initial token supply to Alice", async () => {
  
        const initialSupply = 1_000_000n;

        console.log(`Issuer gets minter role ...`);
        const minterRole = 7n;
        let receipt = await tokenContractIssuer.methods.grant_role(minterRole, issuer).send({ fee: { paymentMethod: sponsoredPaymentMethod } }).wait();
        expect(receipt).toEqual(
            expect.objectContaining({
                status: TxStatus.SUCCESS,
            }),
        );
        expect(await advanceBlocks(tokenContractIssuer, sponsoredPaymentMethod)).toBeTruthy();
        const isMinter = await tokenContractIssuer.methods.has_role(minterRole, issuer).simulate();
        expect(isMinter).toEqual(1n);

        console.log(`Minting tokens to Alice ...`);

        receipt = await tokenContractIssuer.methods.mint(alice,initialSupply).send({ fee: { paymentMethod: sponsoredPaymentMethod } }).wait();
        expect(receipt).toEqual(
            expect.objectContaining({
                status: TxStatus.SUCCESS,
            }),
        );
        const balanceAlice = await tokenContractAlice.methods.balance_of_private(alice).simulate();
        expect(balanceAlice).toEqual(initialSupply)

        const supplyAfter = await tokenContractIssuer.methods.total_supply().simulate();
        expect(supplyAfter).toEqual(initialSupply)
        console.log(`${supplyAfter} tokens as initial supply minted by issuer`);
    }, 300_000)

    it("Issuer privately mints tokens to Bob", async () => {

        const bobTokens = 1000n;

        console.log("issuer minting tokens to Bob...")

        const receipt = await tokenContractIssuer.methods.mint(bob, bobTokens).send({ fee: { paymentMethod: sponsoredPaymentMethod } }).wait()
        expect(receipt).toEqual(
            expect.objectContaining({
                status: TxStatus.SUCCESS,
            }),
        );

        const balanceAlice = await tokenContractBob.methods.balance_of_private(bob).simulate();
        expect(balanceAlice).toEqual(bobTokens)

        console.log(`issuer successfuly privately minted ${bobTokens} tokens to Bob`)
        const supplyAfter = await tokenContractIssuer.methods.total_supply().simulate()
        console.log(`Supply after mint: ${supplyAfter}`)
        expect(supplyAfter).toEqual(1_001_000n)

    }, 300_000)

    it("queries the token balance for each account", async () => {
        
        let aliceBalance = await tokenContractAlice.methods.balance_of_private(alice).simulate();
        expect(aliceBalance).toEqual(1_000_000n);
        console.log(`Alice's balance ${aliceBalance}`);

        let bobBalance = await tokenContractBob.methods.balance_of_private(bob).simulate();
        expect(bobBalance).toEqual(1000n);
        console.log(`Bob's balance ${bobBalance}`);
    })

    it("transfers funds from Alice to Bob", async () => {


        const transferQuantity = 543n;
        console.log(`Transferring ${transferQuantity} tokens from Alice to Bob...`);
        const receipt = await tokenContractAlice.methods.transfer(alice, bob, transferQuantity, 0).send({ fee: { paymentMethod: sponsoredPaymentMethod } }).wait();
        expect(receipt).toEqual(
            expect.objectContaining({
                status: TxStatus.SUCCESS,
            }),
        );
        // Check the new balances
        const aliceBalance = await tokenContractAlice.methods.balance_of_private(alice).simulate();
        expect(aliceBalance).toEqual(1_000_000n - transferQuantity);
        console.log(`Alice's balance ${aliceBalance}`);

        const bobBalance = await tokenContractBob.methods.balance_of_private(bob).simulate();
        expect(bobBalance).toEqual(1000n + transferQuantity);
        console.log(`Bob's balance ${bobBalance}`);
    })

    it("transfers funds from Bob to issuer", async () => {

        const transferQuantity = 1000n;
        console.log(`Transferring ${transferQuantity} tokens from Bob to Issuer...`);
        await tokenContractBob.methods.transfer(bob, issuer, transferQuantity, 0).send({ fee: { paymentMethod: sponsoredPaymentMethod } }).wait();

        // Check the new balances
        const issuerBalance = await tokenContractIssuer.methods.balance_of_private(alice).simulate();
        console.log(`Alice's balance ${issuerBalance}`);

        const bobBalance = await tokenContractBob.methods.balance_of_private(bob).simulate();
        console.log(`Bob's balance ${bobBalance}`);

    })


    it("Issuer is able to burn tokens of Bob", async () => {

        console.log(`Issuer gets burner role ...`);
        const burnerRole = 8n;
        let receipt = await tokenContractIssuer.methods.grant_role(burnerRole, issuer).send({ fee: { paymentMethod: sponsoredPaymentMethod } }).wait();
        expect(receipt).toEqual(
            expect.objectContaining({
                status: TxStatus.SUCCESS,
            }),
        );
        expect(await advanceBlocks(tokenContractIssuer, sponsoredPaymentMethod)).toBeTruthy();
        const isBurner = await tokenContractIssuer.methods.has_role(burnerRole, issuer).simulate();
        expect(isBurner).toEqual(1n);
        console.log(`Issuer successfully granted burner role`);


        console.log(`Bob creates Authentication Witness for burning tokens...`);
        const nonce = Fr.random();
        const burnTokens = 43n;

        const action = tokenContractIssuer.methods.burn(bob, burnTokens, nonce);
        const witness = await bobWallet.createAuthWit({ caller: issuer, action });


        console.log(`Bob successfully created Authentication Witness for burning tokens`);
        console.log(`issuer burning ${burnTokens} tokens from Bob...`);
        await action.send({ authWitnesses: [witness], fee: { paymentMethod: sponsoredPaymentMethod } }).wait();

        console.log(`Issuer successfully burned ${burnTokens} tokens from Bob`);

        // Check the new balances
        const aliceBalance = await tokenContractAlice.methods.balance_of_private(alice).simulate();
        console.log(`Alice's balance ${aliceBalance}`);

        const bobBalance = await tokenContractBob.methods.balance_of_private(bob).simulate();
        console.log(`Bob's balance ${bobBalance}`);
    })

    })

    describe("Failure Cases", () => {

        it("Users try to access other's private pxe storage to get their private balance", async () => {
            //Note: Bob should not be able to know the private balance of alice. This works because we are using the same PxE for both, and thus the PxE is able to decrypt the other user's note. In production,
            // there will be one PxE per user. 
            const bobTriesToAccessAliceBalance = await tokenContractBob.methods.balance_of_private(alice).simulate();
            console.log(`Alice's balance from Bob PoW ${bobTriesToAccessAliceBalance}`);

            //Note: issuer should not be able to know the private balance of bob. Same as above
            const aliceTriesToAccessBobBalance = await tokenContractAlice.methods.balance_of_private(bob).simulate()
            console.log(`Bob's balance from Alice's PoW ${aliceTriesToAccessBobBalance}`);
        })


        it("bob tries to mint some tokens", async () => {
            const mintQuantity = 1000n;
            let tx = tokenContractBob.methods.mint(bob, mintQuantity).send({ fee: { paymentMethod: sponsoredPaymentMethod } }).wait();
            await (expect(tx)).rejects.toThrow();

        })

        it("bob tries to burn some tokens", async () => {
            const burnQuantity = 1000n;
            await (expect(tokenContractBob.methods.mint(bob, burnQuantity).send({ fee: { paymentMethod: sponsoredPaymentMethod } }).wait())).rejects.toThrow();
        })

    })


    describe("Access Control Cases", () => {
        it("Bob tries to set itself as a new admin", async () => {
            const adminRole = 1;
            await expect(tokenContractBob.methods.grant_role(adminRole,bob).send({ fee: { paymentMethod: sponsoredPaymentMethod } }).wait()).rejects.toThrow()
        })

        it("Admin sets Bob as new admin", async () => {
            const adminRole = 1n;
            await tokenContractIssuer.methods.grant_role(adminRole, bob).send({ fee: { paymentMethod: sponsoredPaymentMethod } }).wait()
            expect(await advanceBlocks(tokenContractIssuer, sponsoredPaymentMethod)).toBeTruthy();
            let bob_role = await tokenContractIssuer.methods.has_role(adminRole, bob).simulate();
            console.log(`Bob role ${bob_role}`);
            expect(bob_role).toEqual(1n);


        }, 300_000)

        it("Admin removes Bob as admin", async () => {
            const adminRole = 1n;
            await tokenContractIssuer.methods.revoke_role(adminRole, bob).send({ fee: { paymentMethod: sponsoredPaymentMethod } }).wait()
            expect(await advanceBlocks(tokenContractIssuer, sponsoredPaymentMethod)).toBeTruthy();
            let bob_role = await tokenContractIssuer.methods.has_role(adminRole, bob).simulate();
            console.log(`Bob role ${bob_role}`);
            expect(bob_role).toEqual(0n);
        }, 300_000)

    })

    describe("Pause Module tests", () => {
        it("Admin can pause the contract - no transactions can be done", async () => {
            console.log("Admin gets pauser role ...");
            const pauserRole = 2n;
            let receipt = await tokenContractIssuer.methods.grant_role(pauserRole, issuer).send({ fee: { paymentMethod: sponsoredPaymentMethod } }).wait();
            expect(receipt).toEqual(
                expect.objectContaining({
                    status: TxStatus.SUCCESS,
                }),
            );
            expect(await advanceBlocks(tokenContractIssuer, sponsoredPaymentMethod)).toBeTruthy();
            const isPauser = await tokenContractIssuer.methods.has_role(pauserRole, issuer).simulate();
            expect(isPauser).toEqual(1n);
            console.log(`Issuer successfully granted pauser role`);
            await tokenContractIssuer.methods.pause_contract().send({ fee: { paymentMethod: sponsoredPaymentMethod } }).wait();
            expect(await tokenContractIssuer.methods.public_get_pause().simulate()).toEqual(1n);
            await expect(tokenContractBob.methods.transfer(bob, alice,10, 0).send({ fee: { paymentMethod: sponsoredPaymentMethod } }).wait()).rejects.toThrow();
        })

        it("Admin can unpause the contract", async () => {
            await tokenContractIssuer.methods.unpause_contract().send({ fee: { paymentMethod: sponsoredPaymentMethod } }).wait();
            expect(await tokenContractIssuer.methods.public_get_pause().simulate()).toEqual(0n);
            const receipt = await tokenContractBob.methods.transfer(bob, alice,10, 0).send({ fee: { paymentMethod: sponsoredPaymentMethod } }).wait();
            expect(receipt).toEqual(
                expect.objectContaining({
                    status: TxStatus.SUCCESS,
                }),
            );
        })
    })

})

