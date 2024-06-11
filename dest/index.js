import { getDeployedTestAccountsWallets } from '@aztec/accounts/testing';
import { ExtendedNote, Fr, Note, computeSecretHash, createDebugLogger, createPXEClient, waitForPXE, } from '@aztec/aztec.js';
import { TokenContract } from './artifacts/Token.js';
import { format } from 'util';
const { PXE_URL = 'http://localhost:8080' } = process.env;
async function main() {
    ////////////// CREATE THE CLIENT INTERFACE AND CONTACT THE SANDBOX //////////////
    const logger = createDebugLogger('token');
    // We create PXE client connected to the sandbox URL
    const pxe = createPXEClient(PXE_URL);
    // Wait for sandbox to be ready
    await waitForPXE(pxe, logger);
    const nodeInfo = await pxe.getNodeInfo();
    logger.info(format('Aztec Sandbox Info ', nodeInfo));
    ////////////// LOAD SOME ACCOUNTS FROM THE SANDBOX //////////////
    // The sandbox comes with a set of created accounts. Load them
    const accounts = await getDeployedTestAccountsWallets(pxe);
    const aliceWallet = accounts[0];
    const bobWallet = accounts[1];
    const alice = aliceWallet.getAddress();
    const bob = bobWallet.getAddress();
    logger.info(`Loaded alice's account at ${alice.toShortString()}`);
    logger.info(`Loaded bob's account at ${bob.toShortString()}`);
    ////////////// DEPLOY OUR TOKEN CONTRACT //////////////
    const initialSupply = 1000000n;
    logger.info(`Deploying token contract...`);
    const tokenName = "TOKEN";
    const tokenSymbol = "TKN";
    const tokenDecimals = 18n;
    const deployArgs = [alice, tokenName, tokenSymbol, tokenDecimals];
    // Deploy the contract and set Alice as the admin while doing so
    const contract = await TokenContract.deploy(aliceWallet, alice).send().deployed();
    logger.info(`Contract successfully deployed at address ${contract.address.toShortString()}`);
    // Create the contract abstraction and link it to Alice's wallet for future signing
    const tokenContractAlice = await TokenContract.at(contract.address, aliceWallet);
    // Create a secret and a corresponding hash that will be used to mint funds privately
    const aliceSecret = Fr.random();
    const aliceSecretHash = computeSecretHash(aliceSecret);
    logger.info(`Minting tokens to Alice...`);
    // Mint the initial supply privately "to secret hash"
    const receipt = await tokenContractAlice.methods.mint_private(initialSupply, aliceSecretHash).send().wait();
    // Add the newly created "pending shield" note to PXE
    const note = new Note([new Fr(initialSupply), aliceSecretHash]);
    await pxe.addNote(new ExtendedNote(note, alice, contract.address, TokenContract.storage.pending_shields.slot, TokenContract.notes.TransparentNote.id, receipt.txHash));
    // Make the tokens spendable by redeeming them using the secret (converts the "pending shield note" created above
    // to a "token note")
    await tokenContractAlice.methods.redeem_shield(alice, initialSupply, aliceSecret).send().wait();
    logger.info(`${initialSupply} tokens were successfully minted and redeemed by Alice`);
    ////////////// QUERYING THE TOKEN BALANCE FOR EACH ACCOUNT //////////////
    // Bob wants to mint some funds, the contract is already deployed, create an abstraction and link it his wallet
    // Since we already have a token link, we can simply create a new instance of the contract linked to Bob's wallet
    const tokenContractBob = tokenContractAlice.withWallet(bobWallet);
    let aliceBalance = await tokenContractAlice.methods.balance_of_private(alice).simulate();
    logger.info(`Alice's balance ${aliceBalance}`);
    let bobBalance = await tokenContractBob.methods.balance_of_private(bob).simulate();
    logger.info(`Bob's balance ${bobBalance}`);
    ////////////// TRANSFER FUNDS FROM ALICE TO BOB //////////////
    // We will now transfer tokens from ALice to Bob
    const transferQuantity = 543n;
    logger.info(`Transferring ${transferQuantity} tokens from Alice to Bob...`);
    await tokenContractAlice.methods.transfer(alice, bob, transferQuantity, 0).send().wait();
    // Check the new balances
    aliceBalance = await tokenContractAlice.methods.balance_of_private(alice).simulate();
    logger.info(`Alice's balance ${aliceBalance}`);
    bobBalance = await tokenContractBob.methods.balance_of_private(bob).simulate();
    logger.info(`Bob's balance ${bobBalance}`);
    ////////////// MINT SOME MORE TOKENS TO BOB'S ACCOUNT //////////////
    // Now mint some further funds for Bob
    // Alice is nice and she adds Bob as a minter
    await tokenContractAlice.methods.set_minter(bob, true).send().wait();
    const bobSecret = Fr.random();
    const bobSecretHash = computeSecretHash(bobSecret);
    // Bob now has a secret 🥷
    const mintQuantity = 10000n;
    logger.info(`Minting ${mintQuantity} tokens to Bob...`);
    const mintPrivateReceipt = await tokenContractBob.methods.mint_private(mintQuantity, bobSecretHash).send().wait();
    const bobPendingShield = new Note([new Fr(mintQuantity), bobSecretHash]);
    await pxe.addNote(new ExtendedNote(bobPendingShield, bob, contract.address, TokenContract.storage.pending_shields.slot, TokenContract.notes.TransparentNote.id, mintPrivateReceipt.txHash));
    await tokenContractBob.methods.redeem_shield(bob, mintQuantity, bobSecret).send().wait();
    // Check the new balances
    aliceBalance = await tokenContractAlice.methods.balance_of_private(alice).simulate();
    logger.info(`Alice's balance ${aliceBalance}`);
    bobBalance = await tokenContractBob.methods.balance_of_private(bob).simulate();
    logger.info(`Bob's balance ${bobBalance}`);
}
main();
//# sourceMappingURL=data:application/json;base64,eyJ2ZXJzaW9uIjozLCJmaWxlIjoiaW5kZXguanMiLCJzb3VyY2VSb290IjoiIiwic291cmNlcyI6WyIuLi9zcmMvaW5kZXgudHMiXSwibmFtZXMiOltdLCJtYXBwaW5ncyI6IkFBQ0EsT0FBTyxFQUFFLDhCQUE4QixFQUFFLE1BQU0seUJBQXlCLENBQUM7QUFDekUsT0FBTyxFQUNMLFlBQVksRUFDWixFQUFFLEVBRUYsSUFBSSxFQUVKLGlCQUFpQixFQUNqQixpQkFBaUIsRUFDakIsZUFBZSxFQUNmLFVBQVUsR0FDWCxNQUFNLGlCQUFpQixDQUFDO0FBQ3pCLE9BQU8sRUFBRSxhQUFhLEVBQUUsTUFBTSxzQkFBc0IsQ0FBQztBQUVyRCxPQUFPLEVBQUUsTUFBTSxFQUFFLE1BQU0sTUFBTSxDQUFDO0FBRTlCLE1BQU0sRUFBRSxPQUFPLEdBQUcsdUJBQXVCLEVBQUUsR0FBRyxPQUFPLENBQUMsR0FBRyxDQUFDO0FBRTFELEtBQUssVUFBVSxJQUFJO0lBQ25CLGlGQUFpRjtJQUNqRixNQUFNLE1BQU0sR0FBRyxpQkFBaUIsQ0FBQyxPQUFPLENBQUMsQ0FBQztJQUUxQyxvREFBb0Q7SUFDcEQsTUFBTSxHQUFHLEdBQUcsZUFBZSxDQUFDLE9BQU8sQ0FBQyxDQUFDO0lBQ3JDLCtCQUErQjtJQUMvQixNQUFNLFVBQVUsQ0FBQyxHQUFHLEVBQUUsTUFBTSxDQUFDLENBQUM7SUFFOUIsTUFBTSxRQUFRLEdBQUcsTUFBTSxHQUFHLENBQUMsV0FBVyxFQUFFLENBQUM7SUFFekMsTUFBTSxDQUFDLElBQUksQ0FBQyxNQUFNLENBQUMscUJBQXFCLEVBQUUsUUFBUSxDQUFDLENBQUMsQ0FBQztJQUVyRCxpRUFBaUU7SUFDakUsOERBQThEO0lBQzlELE1BQU0sUUFBUSxHQUFHLE1BQU0sOEJBQThCLENBQUMsR0FBRyxDQUFDLENBQUM7SUFDM0QsTUFBTSxXQUFXLEdBQUcsUUFBUSxDQUFDLENBQUMsQ0FBQyxDQUFDO0lBQ2hDLE1BQU0sU0FBUyxHQUFHLFFBQVEsQ0FBQyxDQUFDLENBQUMsQ0FBQztJQUM5QixNQUFN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