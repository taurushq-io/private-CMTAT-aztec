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
    //Add the newly created "pending shield" note to PXE
    const note = new Note([new Fr(initialSupply), aliceSecretHash]);
    await pxe.addNote(new ExtendedNote(note, alice, contract.address, TokenContract.storage.pending_shields.slot, TokenContract.notes.TransparentNote.id, receipt.txHash));
    await pxe.addNote(new ExtendedNote(note, alice, contract.address, TokenContract.storage.pending_shields.slot, TokenContract.notes.TransparentNote.id, receipt.txHash));
    // Make the tokens spendable by redeeming them using the secret (converts the "pending shield note" created above
    // to a "token note")
    await tokenContractAlice.methods.redeem_shield(alice, initialSupply, aliceSecret).send().wait();
    logger.info(`${initialSupply} tokens were successfully minted and redeemed by Alice`);
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