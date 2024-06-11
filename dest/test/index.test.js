import { TokenContractArtifact, TokenContract } from "../artifacts/Token.js";
import { ContractDeployer, Fr, Note, ExtendedNote, waitForPXE, TxStatus, createPXEClient, getContractInstanceFromDeployParams, createDebugLogger, computeSecretHash } from "@aztec/aztec.js";
import { getDeployedTestAccountsWallets } from "@aztec/accounts/testing";
import { format } from 'util';
const setupSandbox = async () => {
    const { PXE_URL = 'http://localhost:8080' } = process.env;
    const pxe = createPXEClient(PXE_URL);
    const logger = createDebugLogger('token');
    await waitForPXE(pxe, logger);
    return { pxe, logger };
};
describe("Token", () => {
    let pxe;
    let logger;
    let wallets = [];
    let accounts = [];
    let alice;
    let aliceWallet;
    let bob;
    let bobWallet;
    let contractAddress;
    //what is a tokenContract?
    let tokenContractAlice;
    let tokenContractBob;
    beforeAll(async () => {
        const sandbox = await setupSandbox();
        ({ pxe, logger } = sandbox);
        wallets = await getDeployedTestAccountsWallets(pxe);
        accounts = wallets.map(w => w.getCompleteAddress());
    });
    it("Deploys the contract", async () => {
        const salt = Fr.random();
        aliceWallet = wallets[0];
        alice = aliceWallet.getCompleteAddress().address;
        bobWallet = wallets[1];
        bob = bobWallet.getCompleteAddress().address;
        const nodeInfo = await pxe.getNodeInfo();
        console.log(format('Aztec Sandbox Info ', nodeInfo));
        console.log(`Loaded alice's account at ${alice.toShortString()}`);
        console.log(`Loaded bob's account at ${bob.toShortString()}`);
        // const tokenName = "TOKEN"
        // const tokenSymbol = "TKN"
        // const tokenDecimals = "6"
        // const deployArgs = [alice, tokenName, tokenSymbol, tokenDecimals]
        const deployArgs = alice;
        // Deploy the contract and set Alice as the admin while doing so
        const deploymentData = getContractInstanceFromDeployParams(TokenContractArtifact, {
            constructorArgs: [deployArgs],
            salt: salt,
            deployer: alice
        });
        const deployer = new ContractDeployer(TokenContractArtifact, aliceWallet);
        const tx = deployer.deploy(deployArgs).send({ contractAddressSalt: salt });
        const receipt = await tx.getReceipt();
        expect(receipt).toEqual(expect.objectContaining({
            status: TxStatus.PENDING,
            error: ''
        }));
        const receiptAfterMined = await tx.wait({ wallet: wallets[0] });
        expect(await pxe.getContractInstance(deploymentData.address)).toBeDefined();
        expect(await pxe.isContractPubliclyDeployed(deploymentData.address)).toBeDefined();
        expect(receiptAfterMined).toEqual(expect.objectContaining({
            status: TxStatus.MINED,
        }));
        expect(receiptAfterMined.contract.instance.address).toEqual(deploymentData.address);
        contractAddress = receiptAfterMined.contract.address;
    }, 300000);
    it("Mints initial token supply to Alice", async () => {
        // Create the contract abstraction and link it to Alice's wallet for future signing
        //TODO understand what this does
        const initialSupply = 1000000n;
        console.log(`Contract successfully deployed at address ${contractAddress.toShortString()}`);
        tokenContractAlice = await TokenContract.at(contractAddress, aliceWallet);
        // Create a secret and a corresponding hash that will be used to mint funds privately
        const aliceSecret = Fr.random();
        const aliceSecretHash = computeSecretHash(aliceSecret);
        console.log(`Minting tokens to Alice...`);
        // Mint the initial supply privately "to secret hash"
        const receipt = await tokenContractAlice.methods.mint_private(initialSupply, aliceSecretHash).send().wait();
        // Add the newly created "pending shield" note to PXE
        const note = new Note([new Fr(initialSupply), aliceSecretHash]);
        await pxe.addNote(new ExtendedNote(note, alice, contractAddress, TokenContract.storage.pending_shields.slot, TokenContract.notes.TransparentNote.id, receipt.txHash));
        // Make the tokens spendable by redeeming them using the secret (converts the "pending shield note" created above
        // to a "token note")
        await tokenContractAlice.methods.redeem_shield(alice, initialSupply, aliceSecret).send().wait();
        console.log(`${initialSupply} tokens were successfully minted and redeemed by Alice`);
    });
    it("queries the token balance for each account", async () => {
        // Bob wants to mint some funds, the contract is already deployed, create an abstraction and link it his wallet
        // Since we already have a token link, we can simply create a new instance of the contract linked to Bob's wallet
        tokenContractBob = tokenContractAlice.withWallet(bobWallet);
        let aliceBalance = await tokenContractAlice.methods.balance_of_private(alice).simulate();
        console.log(`Alice's balance ${aliceBalance}`);
        let bobBalance = await tokenContractBob.methods.balance_of_private(bob).simulate();
        console.log(`Bob's balance ${bobBalance}`);
    });
    it("transfers funds from Alice to Bob", async () => {
        // We will now transfer tokens from ALice to Bob
        tokenContractBob = tokenContractAlice.withWallet(bobWallet);
        const transferQuantity = 543n;
        console.log(`Transferring ${transferQuantity} tokens from Alice to Bob...`);
        await tokenContractAlice.methods.transfer(alice, bob, transferQuantity, 0).send().wait();
        // Check the new balances
        const aliceBalance = await tokenContractAlice.methods.balance_of_private(alice).simulate();
        console.log(`Alice's balance ${aliceBalance}`);
        const bobBalance = await tokenContractBob.methods.balance_of_private(bob).simulate();
        console.log(`Bob's balance ${bobBalance}`);
    });
    it("mint more tokens to Bob and check final balances", async () => {
        // Now mint some further funds for Bob
        // Alice is nice and she adds Bob as a minter
        await tokenContractAlice.methods.set_minter(bob, true).send().wait();
        const bobSecret = Fr.random();
        const bobSecretHash = computeSecretHash(bobSecret);
        // Bob now has a secret 🥷
        const mintQuantity = 10000n;
        console.log(`Minting ${mintQuantity} tokens to Bob...`);
        const mintPrivateReceipt = await tokenContractBob.methods.mint_private(mintQuantity, bobSecretHash).send().wait();
        const bobPendingShield = new Note([new Fr(mintQuantity), bobSecretHash]);
        await pxe.addNote(new ExtendedNote(bobPendingShield, bob, contractAddress, TokenContract.storage.pending_shields.slot, TokenContract.notes.TransparentNote.id, mintPrivateReceipt.txHash));
        await tokenContractBob.methods.redeem_shield(bob, mintQuantity, bobSecret).send().wait();
        // Check the new balances
        const aliceBalance = await tokenContractAlice.methods.balance_of_private(alice).simulate();
        console.log(`Alice's balance ${aliceBalance}`);
        const bobBalance = await tokenContractBob.methods.balance_of_private(bob).simulate();
        console.log(`Bob's balance ${bobBalance}`);
    });
});
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiaW5kZXgudGVzdC5qcyIsInNvdXJjZVJvb3QiOiIiLCJzb3VyY2VzIjpbIi4uLy4uL3NyYy90ZXN0L2luZGV4LnRlc3QudHMiXSwibmFtZXMiOltdLCJtYXBwaW5ncyI6IkFBQUEsT0FBTyxFQUFFLHFCQUFxQixFQUFFLGFBQWEsRUFBRSxNQUFNLHVCQUF1QixDQUFBO0FBQzVFLE9BQU8sRUFBa0MsZ0JBQWdCLEVBQUUsRUFBRSxFQUFFLElBQUksRUFBQyxZQUFZLEVBQU8sVUFBVSxFQUFFLFFBQVEsRUFBRSxlQUFlLEVBQUUsbUNBQW1DLEVBQXdELGlCQUFpQixFQUFlLGlCQUFpQixFQUFFLE1BQU0saUJBQWlCLENBQUM7QUFDcFMsT0FBTyxFQUFpQyw4QkFBOEIsRUFBRSxNQUFNLHlCQUF5QixDQUFBO0FBQ3ZHLE9BQU8sRUFBRSxNQUFNLEVBQUUsTUFBTSxNQUFNLENBQUM7QUFFOUIsTUFBTSxZQUFZLEdBQUcsS0FBSyxJQUFJLEVBQUU7SUFDNUIsTUFBTSxFQUFFLE9BQU8sR0FBRyx1QkFBdUIsRUFBRSxHQUFHLE9BQU8sQ0FBQyxHQUFHLENBQUM7SUFDMUQsTUFBTSxHQUFHLEdBQUcsZUFBZSxDQUFDLE9BQU8sQ0FBQyxDQUFDO0lBQ3JDLE1BQU0sTUFBTSxHQUFHLGlCQUFpQixDQUFDLE9BQU8sQ0FBQyxDQUFDO0lBQzFDLE1BQU0sVUFBVSxDQUFDLEdBQUcsRUFBRSxNQUFNLENBQUMsQ0FBQztJQUM5QixPQUFPLEVBQUMsR0FBRyxFQUFDLE1BQU0sRUFBQyxDQUFDO0FBQ3hCLENBQUMsQ0FBQztBQUVGLFFBQVEsQ0FBQyxPQUFPLEVBQUUsR0FBRyxFQUFFO0lBQ25CLElBQUksR0FBUSxDQUFDO0lBQ2IsSUFBSSxNQUFtQixDQUFDO0lBQ3hCLElBQUksT0FBTyxHQUFpQyxFQUFFLENBQUM7SUFDL0MsSUFBSSxRQUFRLEdBQXNCLEVBQUUsQ0FBQztJQUNyQyxJQUFJLEtBQW1CLENBQUM7SUFDeEIsSUFBSSxXQUF1QyxDQUFDO0lBQzVDLElBQUksR0FBaUIs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