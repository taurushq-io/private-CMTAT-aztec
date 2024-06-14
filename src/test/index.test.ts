import { TokenContractArtifact, TokenContract } from "../artifacts/Token.js"
import { AccountWallet, CompleteAddress, ContractDeployer, Fr, Note,ExtendedNote, PXE, waitForPXE, TxStatus, createPXEClient, getContractInstanceFromDeployParams, deriveKeys, AztecAddress, AccountWalletWithSecretKey, createDebugLogger, DebugLogger, computeSecretHash } from "@aztec/aztec.js";
import { getInitialTestAccountsWallets, getDeployedTestAccountsWallets } from "@aztec/accounts/testing"
import { format } from 'util';

const setupSandbox = async () => {
    const { PXE_URL = 'http://localhost:8080' } = process.env;
    const pxe = createPXEClient(PXE_URL);
    const logger = createDebugLogger('token');
    await waitForPXE(pxe, logger);
    return {pxe,logger};
};

describe("Token", () => {
    let pxe: PXE;
    let logger: DebugLogger;
    let wallets: AccountWalletWithSecretKey[] = [];
    let accounts: CompleteAddress[] = [];
    let alice: AztecAddress;
    let aliceWallet: AccountWalletWithSecretKey;
    let bob: AztecAddress;
    let bobWallet: AccountWalletWithSecretKey;
    let contractAddress: AztecAddress;
    //what is a tokenContract?
    let tokenContractAlice: TokenContract;
    let tokenContractBob: TokenContract;

    beforeAll(async () => {
        const sandbox = await setupSandbox();
        ({ pxe, logger } = sandbox);
        wallets = await getDeployedTestAccountsWallets(pxe);
        accounts = wallets.map(w => w.getCompleteAddress())

    })

    it("Deploys the contract", async () => {
        const salt = Fr.random();

        aliceWallet = wallets[0]
        alice = aliceWallet.getCompleteAddress().address

        bobWallet = wallets[1]
        bob = bobWallet.getCompleteAddress().address

        const nodeInfo = await pxe.getNodeInfo();
        console.log(format('Aztec Sandbox Info ', nodeInfo));
        console.log(`Loaded alice's account at ${alice.toShortString()}`);
        console.log(`Loaded bob's account at ${bob.toShortString()}`);

        // const tokenName = "TOKEN"
        // const tokenSymbol = "TKN"
        // const tokenDecimals = "6"

        // const deployArgs = [alice, tokenName, tokenSymbol, tokenDecimals]
        const deployArgs = alice

        // Deploy the contract and set Alice as the admin while doing so
        const deploymentData = getContractInstanceFromDeployParams(TokenContractArtifact,
            {
                constructorArgs: [deployArgs],
                salt: salt,
                deployer: alice
            });

        const deployer = new ContractDeployer(TokenContractArtifact, aliceWallet);
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
                status: TxStatus.MINED,
            }),
        );

        expect(receiptAfterMined.contract.instance.address).toEqual(deploymentData.address)
        contractAddress = receiptAfterMined.contract.address

    }, 300_000)


    it("Mints initial token supply to Alice", async () => {
        // Create the contract abstraction and link it to Alice's wallet for future signing
        //TODO understand what this does
        const initialSupply = 1_000_000n;
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
        await pxe.addNote(
        new ExtendedNote(
            note,
            alice,
            contractAddress,
            TokenContract.storage.pending_shields.slot,
            TokenContract.notes.TransparentNote.id,
            receipt.txHash,
        ),
        );

        // Make the tokens spendable by redeeming them using the secret (converts the "pending shield note" created above
        // to a "token note")
        await tokenContractAlice.methods.redeem_shield(alice, initialSupply, aliceSecret).send().wait();
        console.log(`${initialSupply} tokens were successfully minted and redeemed by Alice`);
    })

    //TODO: both need the secret, we need a way to share it between them
    it("Alice mints tokens on behalf of Bob, so that Bob stays private", async () => {
        tokenContractAlice = await TokenContract.at(contractAddress, aliceWallet);
        tokenContractBob = tokenContractAlice.withWallet(bobWallet);

        const bobSecret = Fr.random()
        const bobSecretHash = computeSecretHash(bobSecret)
        const bobTokens = 1000;

        console.log(`Alice minting tokens to Bob...`);

        const receipt = await tokenContractAlice.methods.mint_private(bobTokens, bobSecretHash).send().wait();


        // Add the newly created "pending shield" note to PXE
        const note = new Note([new Fr(bobTokens), bobSecretHash]);
        await pxe.addNote(
        new ExtendedNote(
            note,
            bob,
            contractAddress,
            TokenContract.storage.pending_shields.slot,
            TokenContract.notes.TransparentNote.id,
            receipt.txHash,
        ),
        );
        
        await tokenContractBob.methods.redeem_shield(bob, bobTokens, bobSecret).send().wait();
        console.log(`${bobTokens} tokens were successfully minted and redeemed by Bob`);
    })

    it("Bob privately mints his tokens", async () => {
        const bobTokens = 1000;
        const receipt = await tokenContractBob.methods.privately_mint_private_note(bobTokens)



    })


    it("queries the token balance for each account", async () => {
        // Bob wants to mint some funds, the contract is already deployed, create an abstraction and link it his wallet
        // Since we already have a token link, we can simply create a new instance of the contract linked to Bob's wallet
        tokenContractBob = tokenContractAlice.withWallet(bobWallet);

        let aliceBalance = await tokenContractAlice.methods.balance_of_private(alice).simulate();
        console.log(`Alice's balance ${aliceBalance}`);

        let bobBalance = await tokenContractBob.methods.balance_of_private(bob).simulate();
        console.log(`Bob's balance ${bobBalance}`);
    })

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
    })


    it("mint more tokens to Bob and check final balances", async () => {
        // Now mint some further funds for Bob

        // Alice is nice and she adds Bob as a minter
        await tokenContractAlice.methods.set_minter(bob, true).send().wait();

        const bobSecret = Fr.random();
        const bobSecretHash = computeSecretHash(bobSecret);
        // Bob now has a secret 🥷

        const mintQuantity = 10_000n;
        console.log(`Minting ${mintQuantity} tokens to Bob...`);
        const mintPrivateReceipt = await tokenContractBob.methods.mint_private(mintQuantity, bobSecretHash).send().wait();

        const bobPendingShield = new Note([new Fr(mintQuantity), bobSecretHash]);
        await pxe.addNote(
        new ExtendedNote(
            bobPendingShield,
            bob,
            contractAddress,
            TokenContract.storage.pending_shields.slot,
            TokenContract.notes.TransparentNote.id,
            mintPrivateReceipt.txHash,
        ),
        );

        await tokenContractBob.methods.redeem_shield(bob, mintQuantity, bobSecret).send().wait();

        // Check the new balances
        const aliceBalance = await tokenContractAlice.methods.balance_of_private(alice).simulate();
        console.log(`Alice's balance ${aliceBalance}`);

        const bobBalance = await tokenContractBob.methods.balance_of_private(bob).simulate();
        console.log(`Bob's balance ${bobBalance}`);
    })


});