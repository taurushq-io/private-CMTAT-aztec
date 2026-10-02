// Two wallets, each with its own PXE, sharing one node: the second wallet only learns about the
// first wallet's notes once it registers the sender.
import { AztecAddress } from "@aztec/aztec.js/addresses";
import { Fr, GrumpkinScalar } from "@aztec/aztec.js/fields";
import { NO_FROM } from "@aztec/aztec.js/account";
import { createAztecNodeClient, waitForNode } from "@aztec/aztec.js/node";
import { createStore } from "@aztec/kv-store/lmdb";
import { TokenContract } from "@aztec/noir-contracts.js/Token";
import { getContractInstanceFromInstantiationParams } from "@aztec/stdlib/contract";
import type { ContractInstanceWithAddress } from "@aztec/stdlib/contract";
import { EmbeddedWallet } from "@aztec/wallets/embedded";

import { getSponsoredPaymentMethod } from "../src/utils/sponsored_fpc.js";

const { NODE_URL = 'http://localhost:8080' } = process.env;

const L2_TOKEN_CONTRACT_SALT = Fr.random();

async function makeWallet(name: string, node: Awaited<ReturnType<typeof createAztecNodeClient>>) {
    const store = await createStore(name, {
        dataDirectory: 'store',
        dataStoreMapSizeKb: 1e6,
    });
    return await EmbeddedWallet.create(node, { pxe: { proverEnabled: false, store } });
}

export async function getL2TokenContractInstance(
    deployerAddress: AztecAddress,
    ownerAztecAddress: AztecAddress,
): Promise<ContractInstanceWithAddress> {
    return await getContractInstanceFromInstantiationParams(TokenContract.artifact, {
        salt: L2_TOKEN_CONTRACT_SALT,
        deployer: deployerAddress,
        constructorArgs: [ownerAztecAddress, 'Clean USDC', 'USDC', 6],
    });
}

async function deployAccount(wallet: EmbeddedWallet): Promise<AztecAddress> {
    const paymentMethod = await getSponsoredPaymentMethod(wallet);
    const account = await wallet.createSchnorrAccount(Fr.random(), Fr.random(), GrumpkinScalar.random());
    const deployMethod = await account.getDeployMethod();
    await deployMethod.send({ from: NO_FROM, fee: { paymentMethod } });
    return account.address;
}

async function main() {
    const node = createAztecNodeClient(NODE_URL);
    await waitForNode(node);

    const wallet1 = await makeWallet('pxe1', node);
    const wallet2 = await makeWallet('pxe2', node);

    const paymentMethod1 = await getSponsoredPaymentMethod(wallet1);
    const paymentMethod2 = await getSponsoredPaymentMethod(wallet2);

    const ownerAddress = await deployAccount(wallet1);

    const { contract: token } = await TokenContract.deploy(
        wallet1,
        ownerAddress,
        'Clean USDC',
        'USDC',
        6,
        { salt: L2_TOKEN_CONTRACT_SALT, deployer: ownerAddress },
    ).send({ from: ownerAddress, fee: { paymentMethod: paymentMethod1 } });

    // Second wallet: its own account, and the first wallet's account registered as a sender so that
    // notes it creates can be discovered here.
    const address2 = await deployAccount(wallet2);
    await wallet2.registerSender(ownerAddress, 'owner');

    await token.methods
        .mint_to_private(address2, 100n)
        .send({ from: ownerAddress, fee: { paymentMethod: paymentMethod1 } });

    // Register the token in the second wallet so it can read its own balance.
    const l2TokenContractInstance = await getL2TokenContractInstance(ownerAddress, ownerAddress);
    await wallet2.registerContract(l2TokenContractInstance, TokenContract.artifact);

    const l2TokenContract = await TokenContract.at(l2TokenContractInstance.address, wallet2);

    const { result: balance } = await l2TokenContract.methods
        .balance_of_private(address2)
        .simulate({ from: address2 });
    console.log("private balance should be 100:", balance);
}

main().catch((error) => {
    console.error("Error:", error);
    process.exit(1);
});
