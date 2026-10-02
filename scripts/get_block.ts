import { setupWallet } from "../src/utils/setup_pxe.js";

async function main() {
    const { node } = await setupWallet();

    const block = await node.getBlock(1);
    console.log(block);
    console.log(await block?.hash());
}

main().catch((error) => {
    console.error("Error:", error);
    process.exit(1);
});
