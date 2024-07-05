import { TokenContractArtifact, TokenContract } from "../artifacts/Token.js"
import { AccountWallet, CompleteAddress, ContractDeployer, Fr, Note,ExtendedNote, PXE, CheatCodes, waitForPXE, TxStatus, createPXEClient, getContractInstanceFromDeployParams, deriveKeys, AztecAddress, AccountWalletWithSecretKey, createDebugLogger, DebugLogger, computeSecretHash } from "@aztec/aztec.js";
import { getInitialTestAccountsWallets, getDeployedTestAccountsWallets } from "@aztec/accounts/testing"
import { format } from 'util';

const setupSandbox = async () => {
    const { PXE_URL = 'http://localhost:8080' } = process.env;
    const pxe = createPXEClient(PXE_URL);
    const ethRpcUrl = "http://localhost:8545";
    const cc = await CheatCodes.create(ethRpcUrl, pxe);
    const logger = createDebugLogger('token');
    await waitForPXE(pxe, logger);
    return {pxe,logger,cc};
};

const advanceBlocks = async (contract: TokenContract, addr: AztecAddress) : Promise<boolean> => {
    const DELAY = 2;
    for (let i = 0; i < DELAY; ++i) {
        await contract.methods.get_roles(addr).send().wait();
      }

    return true
}


describe("Token", () => {
    let pxe: PXE;
    let logger: DebugLogger;
    let cc :CheatCodes;
    let wallets: AccountWalletWithSecretKey[] = [];
    let accounts: CompleteAddress[] = [];
    let issuer: AztecAddress;
    let issuerWallet: AccountWalletWithSecretKey;
    let alice: AztecAddress;
    let aliceWallet: AccountWalletWithSecretKey;
    let bob: AztecAddress;
    let bobWallet: AccountWalletWithSecretKey;
    let contractAddress: AztecAddress;
    //what is a tokenContract?
    let tokenContractIssuer: TokenContract;
    let tokenContractBob: TokenContract;
    let tokenContractAlice: TokenContract;

    beforeAll(async () => {
        const sandbox = await setupSandbox();
        ({ pxe, logger, cc } = sandbox);
        wallets = await getDeployedTestAccountsWallets(pxe);
        accounts = wallets.map(w => w.getCompleteAddress())


    })


    it("Deploys the contract", async () => {
        const salt = Fr.random();

        issuerWallet = wallets[0]
        issuer = issuerWallet.getCompleteAddress().address

        bobWallet = wallets[1]
        bob = bobWallet.getCompleteAddress().address

        aliceWallet = wallets[2]
        alice = aliceWallet.getCompleteAddress().address

        


        const nodeInfo = await pxe.getNodeInfo();
        console.log(format('Aztec Sandbox Info ', nodeInfo));
        console.log(`Loaded issuer's account at ${issuer.toShortString()}`);
        console.log(`issuer's secret key ${issuerWallet.getSecretKey()}`)
        console.log(`Loaded bob's account at ${bob.toShortString()}`);
        console.log(`Bob's secret key ${bobWallet.getSecretKey()}`)
        console.log(`Loaded Alice's account at ${alice.toShortString()}`);
        console.log(`Alice's secret key ${aliceWallet.getSecretKey()}`)

        // const tokenName = "TOKEN"
        // const tokenSymbol = "TKN"
        // const tokenDecimals = "6"

        // const deployArgs = [issuer, tokenName, tokenSymbol, tokenDecimals]
        const deployArgs = issuer

        // Deploy the contract and set issuer as the admin while doing so
        const deploymentData = getContractInstanceFromDeployParams(TokenContractArtifact,
            {
                constructorArgs: [deployArgs],
                salt: salt,
                deployer: issuer
            });

        const deployer = new ContractDeployer(TokenContractArtifact, issuerWallet);
        const tx = deployer.deploy(deployArgs).send({ contractAddressSalt: salt })
        const receipt = await tx.getReceipt();

        expect(receipt).toEqual(
            expect.objectContaining({
                status: TxStatus.PENDING,
                error: ''
            }),
        );

        const receiptAfterMined = await tx.wait({ wallet: wallets[0] });

        expect(await pxe.getContractInstance(deploymentData.address)).toBeDefined();
        expect(await pxe.isContractPubliclyDeployed(deploymentData.address)).toBeDefined();
        expect(receiptAfterMined).toEqual(
            expect.objectContaining({
                status: TxStatus.SUCCESS,
            }),
        );

        expect(receiptAfterMined.contract.instance.address).toEqual(deploymentData.address)
        contractAddress = receiptAfterMined.contract.address


        console.log(`Contract successfully deployed at address ${contractAddress.toShortString()}`);
        tokenContractIssuer = await TokenContract.at(contractAddress, issuerWallet);
        tokenContractAlice = await TokenContract.at(contractAddress, aliceWallet);
        tokenContractBob = await TokenContract.at(contractAddress, bobWallet);


        expect(await advanceBlocks(tokenContractIssuer, issuer)).toBeTruthy();

        const roles = await tokenContractIssuer.methods.get_roles(issuer).simulate();
        console.log(`ISSUER ROLES: ${roles}`)


    }, 300_000)

    describe("Normal user flow", () => {


    it("Issuer privately mints initial token supply to Alice", async () => {
  
        const initialSupply = 1_000_000n;


        console.log(`Whitelisting Alice ...`);

        const newRole =  {is_admin: false,is_issuer: false,is_blacklisted: false};
        const roles = await tokenContractIssuer.methods.update_roles(alice,newRole)
        expect(await advanceBlocks(tokenContractIssuer, issuer)).toBeTruthy();


        console.log(`Minting tokens to Alice ...`);
        // Mint the initial supply privately 


        const receipt = await tokenContractIssuer.methods.mint(alice,initialSupply).send().wait();
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

        console.log(`Whitelisting Bob ...`);

        const newRole =  {is_admin: false,is_issuer: false,is_blacklisted: false};
        const roles = await tokenContractIssuer.methods.update_roles(bob,newRole).send().wait()
        expect(await advanceBlocks(tokenContractIssuer, issuer)).toBeTruthy();

        console.log("issuer minting tokens to Bob...")

        const receipt = await tokenContractIssuer.methods.mint(bob, bobTokens).send().wait()
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
    }, 300_000)

    it("queries the token balance for each account", async () => {
        
        let aliceBalance = await tokenContractAlice.methods.balance_of_private(alice).simulate();
        console.log(`Alice's balance ${aliceBalance}`);

        let bobBalance = await tokenContractBob.methods.balance_of_private(bob).simulate();
        console.log(`Bob's balance ${bobBalance}`);
    })

    it("transfers funds from Alice to Bob", async () => {


        const transferQuantity = 543n;
        console.log(`Transferring ${transferQuantity} tokens from Alice to Bob...`);
        await tokenContractAlice.methods.transfer(alice, bob, transferQuantity, 0).send().wait();

        // Check the new balances
        const aliceBalance = await tokenContractAlice.methods.balance_of_private(alice).simulate();
        console.log(`Alice's balance ${aliceBalance}`);

        const bobBalance = await tokenContractBob.methods.balance_of_private(bob).simulate();
        console.log(`Bob's balance ${bobBalance}`);
    })

    it("transfers funds from Bob to issuer", async () => {

        const transferQuantity = 1000n;
        console.log(`Transferring ${transferQuantity} tokens from Bob to Alice...`);
        await tokenContractBob.methods.transfer(bob, alice, transferQuantity, 0).send().wait();

        // Check the new balances
        const aliceBalance = await tokenContractAlice.methods.balance_of_private(alice).simulate();
        console.log(`Alice's balance ${aliceBalance}`);

        const bobBalance = await tokenContractBob.methods.balance_of_private(bob).simulate();
        console.log(`Bob's balance ${bobBalance}`);

    })


    it("Issuer is able to burn tokens of Bob", async () => {
        const burnTokens = 43n;
    
        console.log(`issuer burning ${burnTokens} from Bob...`);
        const receipt = await tokenContractIssuer.methods.burn(bob,burnTokens).send().wait();
        expect(receipt).toEqual(
            expect.objectContaining({
                status: TxStatus.SUCCESS,
            }),
        );

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

        it("Bob tries to send funds from issuer to Bob", async () => {
            const transferQuantity = 1000n;
    
              //try to transfer funds from issuer to bob using bob contract
              console.log(`Transferring ${transferQuantity} tokens from issuer to Bob using Bob account - should fail...`);
              await expect(tokenContractBob.methods.transfer(issuer, bob, transferQuantity, 0).send().wait()).rejects.toThrow();
    
        })

        it("bob tries to mint some tokens", async () => {
            const mintQuantity = 1000n;

            await (expect(tokenContractBob.methods.mint(bob, mintQuantity).send().wait())).rejects.toThrow("(JSON-RPC PROPAGATED) Assertion failed: Caller is not issuer 'issuer_role.is_issuer'")

        })

        it("bob tries to burn some tokens", async () => {
            const burnQuantity = 1000n;
            await (expect(tokenContractBob.methods.mint(bob, burnQuantity).send().wait())).rejects.toThrow("(JSON-RPC PROPAGATED) Assertion failed: Caller is not issuer 'issuer_role.is_issuer'")

        })

    })


    describe("Access Control Cases", () => {
        it("Bob tries to set itself as a new admin", async () => {
            const newRole =  {is_admin: true,is_issuer: false,is_blacklisted: false};
            await expect(tokenContractBob.methods.update_roles(bob,newRole).send().wait()).rejects.toThrow("(JSON-RPC PROPAGATED) Assertion failed: caller is not admin 'caller_roles.is_admin'")
        })

        it("Bob tries to set a new issuer", async () => {
            const newRole =  {is_admin: false,is_issuer: true,is_blacklisted: false};
            await expect(tokenContractBob.methods.update_roles(bob,newRole).send().wait()).rejects.toThrow("(JSON-RPC PROPAGATED) Assertion failed: caller is not admin 'caller_roles.is_admin'")
        })

        it("Admin sets Bob as new issuer", async () => {
            const newRole =  {is_admin: false,is_issuer: true,is_blacklisted: false};
            await tokenContractIssuer.methods.update_roles(bob,newRole).send().wait()
            expect(await advanceBlocks(tokenContractIssuer, issuer)).toBeTruthy();
            expect(await tokenContractIssuer.methods.get_roles(bob).simulate()).toEqual(2n);


        }, 300_000)

        it("Admin removes Bob as issuer", async () => {
            const newRole =  {is_admin: false,is_issuer: false,is_blacklisted: false};
            await tokenContractIssuer.methods.update_roles(bob,newRole).send().wait()
            expect(await advanceBlocks(tokenContractIssuer, issuer)).toBeTruthy();
            expect(await tokenContractIssuer.methods.get_roles(bob).simulate()).toEqual(0n);
        }, 300_000)

    })

})

