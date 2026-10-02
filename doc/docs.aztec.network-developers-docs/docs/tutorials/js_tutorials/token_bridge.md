# Bridge Your NFT to Aztec

> Source: https://docs.aztec.network/developers/docs/tutorials/js_tutorials/token_bridge

---

- [![Home](https://docs.aztec.network/img/Aztec_Symbol_Dark.png)![Home](https://docs.aztec.network/img/Aztec%20Symbol_Light.png)](https://docs.aztec.network/)
- Tutorials
- Full-Stack Tutorials
- Bridge Your NFT to Aztec

On this page
# Bridge Your NFT to Aztec

## Why Bridge an NFT?[​](#why-bridge-an-nft)

Imagine you own a CryptoPunk NFT on Ethereum. You want to use it in games, social apps, or DeFi protocols, but gas fees on Ethereum make every interaction expensive. What if you could move your Punk to Aztec (L2), use it **privately** in dozens of applications, and then bring it back to Ethereum when you're ready to sell?

In this tutorial, you'll build a **private NFT bridge**. By the end, you'll understand how **portals** work and how **cross-chain messages** flow between L1 and L2.

Before starting, make sure you have the Aztec local network running at version v5.2.0. Check out [the local network guide](https://docs.aztec.network/developers/getting_started_on_local_network) for setup instructions.

## What You'll Build[​](#what-youll-build)

You'll create two contracts with **privacy at the core**:

- **NFTPunk (L2)** - An NFT contract with encrypted ownership using `PrivateSet`
- **NFTBridge (L2)** - A bridge that mints NFTs privately when claiming L1 messages

This tutorial focuses on the L2 side to keep things manageable. You'll learn the essential privacy patterns that apply to any asset bridge on Aztec.

## Project Setup[​](#project-setup)

Let's start simple. Since this is an Ethereum project, it's easier to just start with Hardhat:

```
git clone https://github.com/critesjosh/hardhat-aztec-example
```

You're cloning a repo here to make it easier for Aztec's `l1-contracts` to be mapped correctly. You should now have a `hardhat-aztec-example` folder with Hardhat's default starter, with a few changes in `package.json`.

We want to add a few more dependencies now before we start:

```
cd hardhat-aztec-exampleyarn add @aztec/aztec.js@5.2.0 @aztec/accounts@5.2.0 @aztec/stdlib@5.2.0 @aztec/wallets@5.2.0 @aztec/viem@2.38.2 tsx
```

Use `@aztec/l1-artifacts` for the L1 interfacesThe starter repo may still pin `@aztec/l1-contracts` as a git dependency; that repository is no longer updated. In `package.json`, replace it with the `@aztec/l1-artifacts` npm package at the version used in this tutorial, then run `yarn install` again:

```
"@aztec/l1-artifacts": "5.2.0"
```

The package ships the L1 contract sources under `@aztec/l1-artifacts/l1-contracts/src`. If the project resolves `@aztec/*` Solidity imports through remappings or aliases, point them at `node_modules/@aztec/l1-artifacts/l1-contracts/src`. The interfaces the portal imports later in this tutorial must match the contracts deployed by your running network.

Now start the local network in another terminal:

```
aztec start --local-network
```

This should start two important services on ports 8080 and 8545, respectively: Aztec and Anvil (an Ethereum development node).

## Part 1: Building the NFT Contract[​](#part-1-building-the-nft-contract)

Let's start with a basic NFT contract on Aztec. That's the representation of the NFT locked on the L2 side:

Let's create that crate in the `contracts` folder so it looks tidy:

```
aztec new contracts/aztec/nftcd contracts/aztec/nft
```

This creates a workspace with two crates: an `nft_contract` crate for the smart contract code and an `nft_test` crate for Noir tests. The `aztec` dependency is already configured in `nft_contract/Nargo.toml`.

Noir Language ServerIf you're using VS Code, install the [Noir Language Support extension](https://marketplace.visualstudio.com/items?itemName=noir-lang.vscode-noir) for syntax highlighting, error checking, and code completion while writing Noir contracts.

### Create the NFT Note[​](#create-the-nft-note)

First, let's create a custom note type for private NFT ownership. In the `nft_contract/src/` directory, create a new file called `nft.nr`:

```
touch nft_contract/src/nft.nr
```

In this file, you're going to create a **private note** that represents NFT ownership. This is a struct with macros that indicate it is a note that can be compared and packed:

nft_note_struct
```
use aztec::{macros::notes::note, protocol::traits::Packable};#[derive(Eq, Packable)]#[note]pub struct NFTNote {    pub token_id: Field,}
```

> [Source code: docs/examples/contracts/nft/src/nft.nr#L1-L9](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/contracts/nft/src/nft.nr#L1-L9)

You now have a note that represents the owner of a particular NFT. Next, move on to the contract itself.

Custom NotesNotes are powerful concepts. Learn more about how to use them in the [state management guide](https://docs.aztec.network/developers/docs/foundational-topics/state_management).

### Define Storage[​](#define-storage)

Back in `nft_contract/src/main.nr`, you can now build the contract storage. You need:

- **admin**: Who controls the contract (set once, never changes)
- **minter**: The bridge address (set once by admin)
- **nfts**: Track which NFTs exist (public, needed for bridging)
- **owners**: Private ownership using the NFTNote

One interesting aspect of this storage configuration is the use of `DelayedPublicMutable`, which allows private functions to read and use public state. You're using it to publicly track which NFTs are already minted while keeping their owners private. Read more about `DelayedPublicMutable` in [the storage guide](https://docs.aztec.network/developers/docs/aztec-nr/framework-description/state_variables).

Write the storage struct and a simple [initializer](https://docs.aztec.network/developers/docs/foundational-topics/contract_creation#initialization) to set the admin in the `nft_contract/src/main.nr` file:

```
use aztec::macros::aztec;pub mod nft;#[aztec]pub contract NFTPunk {    use crate::nft::NFTNote;    use aztec::{        macros::{functions::{external, initializer, only_self}, storage::storage},        protocol::address::AztecAddress,        state_vars::{DelayedPublicMutable, Map, Owned, PrivateSet, PublicImmutable},    };    use aztec::messages::delivery::MessageDelivery;    use aztec::note::{        note_getter_options::NoteGetterOptions, note_interface::NoteProperties,        note_viewer_options::NoteViewerOptions,    };    use aztec::utils::comparison::Comparator;    #[storage]    struct Storage<Context> {        admin: PublicImmutable<AztecAddress, Context>,        minter: PublicImmutable<AztecAddress, Context>,        nfts: Map<Field, DelayedPublicMutable<bool, 2u64, Context>, Context>,        owners: Owned<PrivateSet<NFTNote, Context>, Context>,    }    #[external("public")]    #[initializer]    fn constructor(admin: AztecAddress) {        self.storage.admin.initialize(admin);    }}
```

### Utility Functions[​](#utility-functions)

Add an internal function to handle the `DelayedPublicMutable` value change. Mark the function as public and `#[only_self]` so only the contract can call it:

mark_nft_exists
```
#[external("public")]#[only_self]fn _mark_nft_exists(token_id: Field, exists: bool) {    self.storage.nfts.at(token_id).schedule_value_change(exists);}
```

> [Source code: docs/examples/contracts/nft/src/main.nr#L42-L48](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/contracts/nft/src/main.nr#L42-L48)

This function is marked with `#[only_self]`, meaning only the contract itself can call it. It uses `schedule_value_change` to update the `nfts` storage, preventing the same NFT from being minted twice or burned when it doesn't exist. You'll call this public function from a private function later using `enqueue_self`.

Another useful function checks how many notes a caller has. You can use this later to verify the claim and exit from L2:

notes_of
```
#[external("utility")]unconstrained fn notes_of(from: AztecAddress) -> Field {    let notes = self.storage.owners.at(from).view_notes(NoteViewerOptions::new());    notes.len() as Field}
```

> [Source code: docs/examples/contracts/nft/src/main.nr#L67-L73](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/contracts/nft/src/main.nr#L67-L73)

### Add Minting and Burning[​](#add-minting-and-burning)

Before anything else, you need to set the minter. This will be the bridge contract, so only the bridge contract can mint NFTs. This value doesn't need to change after initialization. Here's how to initialize the `PublicImmutable`:

set_minter
```
#[external("public")]fn set_minter(minter: AztecAddress) {    assert(self.storage.admin.read().eq(self.msg_sender()), "caller is not admin");    self.storage.minter.initialize(minter);}
```

> [Source code: docs/examples/contracts/nft/src/main.nr#L34-L40](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/contracts/nft/src/main.nr#L34-L40)

Now for the magic - minting NFTs **privately**. The bridge will call this to mint to a user, deliver the note using [constrained message delivery](https://docs.aztec.network/developers/docs/aztec-nr/framework-description/events_and_logs) (best practice when "sending someone a
note") and then [enqueue a public call](https://docs.aztec.network/developers/docs/aztec-nr/framework-description/calling_contracts) to the `_mark_nft_exists` function:

mint
```
#[external("private")]fn mint(to: AztecAddress, token_id: Field) {    assert(        self.storage.minter.read().eq(self.msg_sender()),        "caller is not the authorized minter",    );    // we create an NFT note and insert it to the PrivateSet - a collection of notes meant to be read in private    let new_nft = NFTNote { token_id };    self.storage.owners.at(to).insert(new_nft).deliver(MessageDelivery::onchain_constrained());    // calling the internal public function above to indicate that the NFT is taken    self.enqueue_self._mark_nft_exists(token_id, true);}
```

> [Source code: docs/examples/contracts/nft/src/main.nr#L50-L65](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/contracts/nft/src/main.nr#L50-L65)

The bridge will also need to burn NFTs when users withdraw back to L1:

burn
```
#[external("private")]fn burn(from: AztecAddress, token_id: Field) {    assert(        self.storage.minter.read().eq(self.msg_sender()),        "caller is not the authorized minter",    );    // from the NFTNote properties, selects token_id and compares it against the token_id to be burned    let options = NoteGetterOptions::new()        .select(NFTNote::properties().token_id, Comparator.EQ, token_id)        .set_limit(1);    let notes = self.storage.owners.at(from).pop_notes(options);    assert(notes.len() == 1, "NFT not found");    self.enqueue_self._mark_nft_exists(token_id, false);}
```

> [Source code: docs/examples/contracts/nft/src/main.nr#L75-L92](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/contracts/nft/src/main.nr#L75-L92)

### Compiling![​](#compiling)

Let's verify it compiles:

```
aztec compile
```

🎉 You should see "Compiled successfully!" This means our private NFT contract is ready. Now let's build the bridge.

## Part 2: Building the Bridge[​](#part-2-building-the-bridge)

We have built the L2 NFT contract. This is the L2 representation of an NFT that is locked on the L1 bridge.

The L2 bridge is the contract that talks to the L1 bridge through cross-chain messaging. You can read more about this protocol [here](https://docs.aztec.network/developers/docs/foundational-topics/ethereum-aztec-messaging).

Let's create a new contract in the same tidy `contracts/aztec` folder:

```
cd ..aztec new nft_bridgecd nft_bridge
```

Now add the `NFTPunk` contract dependency to `nft_bridge_contract/Nargo.toml`. The `aztec` dependency is already there:

```
[dependencies]aztec = { git="https://github.com/AztecProtocol/aztec-nr", tag = "v5.2.0", directory = "aztec" }NFTPunk = { path = "../../nft/nft_contract" }
```

### Understanding Bridges[​](#understanding-bridges)

A bridge has two jobs:

1. **Claim**: When someone deposits an NFT on L1, mint it on L2
2. **Exit**: When someone wants to withdraw, burn on L2 and unlock on L1

This means having knowledge about the L2 NFT contract, and the bridge on the L1 side. That's what goes into our bridge's storage.

### Bridge Storage[​](#bridge-storage)

Clean up `nft_bridge_contract/src/main.nr` which is just a placeholder, and let's write the storage struct and the constructor. We'll use `PublicImmutable` since these values never change:

```
use aztec::macros::aztec;#[aztec]pub contract NFTBridge {    use aztec::{        macros::{functions::{external, initializer}, storage::storage},        protocol::{address::{AztecAddress, EthAddress}, hash::sha256_to_field},        state_vars::PublicImmutable,    };    use NFTPunk::NFTPunk;    #[storage]    struct Storage<Context> {        nft: PublicImmutable<AztecAddress, Context>,        portal: PublicImmutable<EthAddress, Context>,    }    #[external("public")]    #[initializer]    fn constructor(nft: AztecAddress) {        self.storage.nft.initialize(nft);    }    #[external("public")]    fn set_portal(portal: EthAddress) {        self.storage.portal.initialize(portal);    }}
```

You can't initialize the `portal` value in the constructor because the L1 portal hasn't been deployed yet. You'll need another function to set it up after the L1 portal is deployed.

### Adding the Bridge Functions[​](#adding-the-bridge-functions)

The Aztec network provides a way to consume messages from L1 to L2 called `consume_l1_to_l2_message`.

You need to define how to encode messages. Here's a simple approach: when an NFT is being bridged, the L1 portal sends a hash of its `token_id` through the bridge, signaling which `token_id` was locked and can be minted on L2. This approach is simple but sufficient for this tutorial.

Build the `claim` function, which consumes the message and mints the NFT on the L2 side:

claim
```
#[external("private")]fn claim(to: AztecAddress, token_id: Field, secret: Field, message_leaf_index: Field) {    // Compute the message hash that was sent from L1    let token_id_bytes: [u8; 32] = (token_id as Field).to_be_bytes();    let content_hash = sha256_to_field(token_id_bytes);    // Consume the L1 -> L2 message    self.context.consume_l1_to_l2_message(        content_hash,        [secret],        self.storage.portal.read(),        message_leaf_index,    );    // Mint the NFT on L2    let nft: AztecAddress = self.storage.nft.read();    self.call(NFTPunk::at(nft).mint(to, token_id));}
```

> [Source code: docs/examples/contracts/nft_bridge/src/main.nr#L31-L50](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/contracts/nft_bridge/src/main.nr#L31-L50)

SecretThe secret prevents front-running. Certainly you don't want anyone to claim your NFT on the L2 side by just being faster. Adding a secret acts like a "password": you can only claim it if you know it.

Similarly, exiting to L1 means burning the NFT on the L2 side and pushing a message through the protocol. To ensure only the L1 recipient can claim it, hash the `token_id` together with the `recipient`:

exit
```
#[external("private")]fn exit(token_id: Field, recipient: EthAddress) {    // Create L2->L1 message to unlock NFT on L1    let token_id_bytes: [u8; 32] = token_id.to_be_bytes();    let recipient_bytes: [u8; 20] = recipient.to_be_bytes();    let content = sha256_to_field(token_id_bytes.concat(recipient_bytes));    self.context.message_portal(self.storage.portal.read(), content);    // Burn the NFT on L2    let nft: AztecAddress = self.storage.nft.read();    self.call(NFTPunk::at(nft).burn(self.msg_sender(), token_id));}
```

> [Source code: docs/examples/contracts/nft_bridge/src/main.nr#L52-L65](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/contracts/nft_bridge/src/main.nr#L52-L65)

Cross-chain messaging on Aztec is powerful because it doesn't conform to any specific format—you can structure messages however you want.

Private FunctionsBoth `claim` and `exit` are `#[external("private")]`, which means the bridging process is private—nobody can see who's bridging which NFT by watching the chain.

### Compile the Bridge[​](#compile-the-bridge)

```
aztec compile
```

Bridge compiled successfully! Now process both contracts and generate TypeScript bindings:

```
cd ../nftaztec codegen target --outdir ../artifactscd ../nft_bridgeaztec codegen target --outdir ../artifacts
```

An `artifacts` folder should appear with TypeScript bindings for each contract. You'll use these when deploying the contracts.

## Part 3: The Ethereum Side[​](#part-3-the-ethereum-side)

Now build the L1 contracts. You need:

- A simple ERC721 NFT contract (the "CryptoPunk")
- A portal contract that locks/unlocks NFTs and communicates with Aztec

### Install Dependencies[​](#install-dependencies)

Aztec's contracts are already in your `package.json`. You just need to add the OpenZeppelin contracts that provide the default ERC721 implementation:

```
cd ../../..yarn add @openzeppelin/contracts
```

### Create a Simple NFT[​](#create-a-simple-nft)

Delete the "Counter" contracts that show up by default in `contracts` and create `contracts/SimpleNFT.sol`:

```
touch contracts/SimpleNFT.sol
```

Create a minimal NFT contract sufficient for demonstrating bridging:

simple_nft
```
pragma solidity >=0.8.27;import {ERC721} from "@oz/token/ERC721/ERC721.sol";contract SimpleNFT is ERC721 {    uint256 private _currentTokenId;    constructor() ERC721("SimplePunk", "SPUNK") {}    function mint(address to) external returns (uint256) {        uint256 tokenId = _currentTokenId++;        _mint(to, tokenId);        return tokenId;    }}
```

> [Source code: docs/examples/solidity/nft_bridge/SimpleNFT.sol#L2-L18](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/solidity/nft_bridge/SimpleNFT.sol#L2-L18)

### Create the NFT Portal[​](#create-the-nft-portal)

The NFT Portal has more code, so build it step-by-step. Create `contracts/NFTPortal.sol`:

```
touch contracts/NFTPortal.sol
```

Initialize it with Aztec's registry, which holds the canonical contracts for Aztec-related contracts, including the Inbox and Outbox. These are the message-passing contracts—Aztec sequencers read any messages on these contracts.

```
import {IERC721} from "@oz/token/ERC721/IERC721.sol";import {IRegistry} from "@aztec/governance/interfaces/IRegistry.sol";import {IInbox} from "@aztec/core/interfaces/messagebridge/IInbox.sol";import {IOutbox} from "@aztec/core/interfaces/messagebridge/IOutbox.sol";import {IRollup} from "@aztec/core/interfaces/IRollup.sol";import {DataStructures} from "@aztec/core/libraries/DataStructures.sol";import {Hash} from "@aztec/core/libraries/crypto/Hash.sol";import {Epoch} from "@aztec/core/libraries/TimeLib.sol";contract NFTPortal {    IRegistry public registry;    IERC721 public nftContract;    bytes32 public l2Bridge;    IRollup public rollup;    IOutbox public outbox;    IInbox public inbox;    uint256 public rollupVersion;    function initialize(address _registry, address _nftContract, bytes32 _l2Bridge) external {        registry = IRegistry(_registry);        nftContract = IERC721(_nftContract);        l2Bridge = _l2Bridge;        rollup = IRollup(address(registry.getCanonicalRollup()));        outbox = rollup.getOutbox();        inbox = rollup.getInbox();        rollupVersion = rollup.getVersion();    }}
```

The core logic is similar to the L2 logic. `depositToAztec` calls the `Inbox` canonical contract to send a message to Aztec, and `withdraw` calls the `Outbox` contract.

Add these two functions with explanatory comments:

portal_deposit_and_withdraw
```
// Lock NFT and send message to L2function depositToAztec(uint256 tokenId, bytes32 secretHash) external returns (bytes32, uint256) {    // Lock the NFT    nftContract.transferFrom(msg.sender, address(this), tokenId);    // Prepare L2 message - just a naive hash of our tokenId    DataStructures.L2Actor memory actor = DataStructures.L2Actor(l2Bridge, rollupVersion);    bytes32 contentHash = Hash.sha256ToField(abi.encode(tokenId));    // Send message to Aztec    (bytes32 key, uint256 index) = inbox.sendL2Message(actor, contentHash, secretHash);    return (key, index);}// Unlock NFT after L2 burnfunction withdraw(    uint256 tokenId,    Epoch epoch,    uint256 numCheckpointsInEpoch,    uint256 leafIndex,    bytes32[] calldata path) external {    // Verify message from L2    DataStructures.L2ToL1Msg memory message = DataStructures.L2ToL1Msg({        sender: DataStructures.L2Actor(l2Bridge, rollupVersion),        recipient: DataStructures.L1Actor(address(this), block.chainid),        content: Hash.sha256ToField(abi.encodePacked(tokenId, msg.sender))    });    outbox.consume(message, epoch, numCheckpointsInEpoch, leafIndex, path);    // Unlock NFT    nftContract.transferFrom(address(this), msg.sender, tokenId);}
```

> [Source code: docs/examples/solidity/nft_bridge/NFTPortal.sol#L37-L72](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/solidity/nft_bridge/NFTPortal.sol#L37-L72)

The portal handles two flows:

- **depositToAztec**: Locks NFT on L1, sends message to L2
- **withdraw**: Verifies L2 message, unlocks NFT on L1

### Compile[​](#compile)

Let's make sure everything compiles:

```
npx hardhat compile
```

You should see successful compilation of both contracts!

## Part 4: Compiling, Deploying, and Testing[​](#part-4-compiling-deploying-and-testing)

Now deploy everything and test the full flow. This will help you understand how everything fits together.

Delete the placeholders in `scripts` and create `index.ts`:

```
touch scripts/index.ts
```

This script will implement the user flow.

TestnetThis section assumes you're working locally using the local network. For the testnet, you need to account for some things:

- Your clients need to point to some Sepolia Node and to the public Aztec Full Node
- You need to [deploy your own Aztec accounts](https://docs.aztec.network/developers/docs/aztec-js/how_to_create_account)
- You need to pay fees in some other way. Learn how in the [fees guide](https://docs.aztec.network/developers/docs/aztec-js/how_to_pay_fees)

### Deploying and Initializing[​](#deploying-and-initializing)

First, initialize the clients: `aztec.js` for Aztec and `viem` for Ethereum:

setup
```
import { getInitialTestAccountsData } from "@aztec/accounts/testing";import { AztecAddress, EthAddress } from "@aztec/aztec.js/addresses";import { Fr } from "@aztec/aztec.js/fields";import { createAztecNodeClient } from "@aztec/aztec.js/node";import { createExtendedL1Client } from "@aztec/ethereum/client";import { deployL1Contract } from "@aztec/ethereum/deploy-l1-contract";import { sha256ToField } from "@aztec/foundation/crypto/sha256";import {  computeL2ToL1MessageHash,  computeSecretHash,} from "@aztec/stdlib/hash";import { EmbeddedWallet } from "@aztec/wallets/embedded";import { decodeEventLog, pad } from "@aztec/viem";import { foundry } from "@aztec/viem/chains";import NFTPortal from "../../../target/solidity/nft_bridge/NFTPortal.sol/NFTPortal.json" with { type: "json" };import SimpleNFT from "../../../target/solidity/nft_bridge/SimpleNFT.sol/SimpleNFT.json" with { type: "json" };import { NFTBridgeContract } from "./artifacts/NFTBridge.js";import { NFTPunkContract } from "./artifacts/NFTPunk.js";// Setup L1 client using anvil's default mnemonic (same as e2e tests)const MNEMONIC = "test test test test test test test test test test test junk";const l1Client = createExtendedL1Client(["http://localhost:8545"], MNEMONIC);const ownerEthAddress = l1Client.account.address;// Setup L2 using Aztec's local network and one of its initial accountsconsole.log("Setting up L2...\n");const node = createAztecNodeClient("http://localhost:8080");const aztecWallet = await EmbeddedWallet.create(node);const [accData] = await getInitialTestAccountsData();const account = await aztecWallet.createSchnorrInitializerlessAccount(  accData.secret,  accData.salt,  accData.signingKey,);console.log(`Account: ${account.address.toString()}\n`);// Get node infoconst nodeInfo = await node.getNodeInfo();const registryAddress = nodeInfo.l1ContractAddresses.registryAddress.toString();const inboxAddress = nodeInfo.l1ContractAddresses.inboxAddress.toString();
```

> [Source code: docs/examples/ts/token_bridge/index.ts#L1-L42](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/ts/token_bridge/index.ts#L1-L42)

Adjust the artifact imports for this project's layoutThe snippet above comes from the monorepo's runnable example, and its artifact imports point at that repo's layout. In the Hardhat project used in this tutorial, replace the four artifact imports with:

```
import NFTPortal from "../artifacts/contracts/NFTPortal.sol/NFTPortal.json" with { type: "json" };import SimpleNFT from "../artifacts/contracts/SimpleNFT.sol/SimpleNFT.json" with { type: "json" };import { NFTBridgeContract } from "../contracts/aztec/artifacts/NFTBridge.js";import { NFTPunkContract } from "../contracts/aztec/artifacts/NFTPunk.js";
```

`npx hardhat compile` writes the Solidity artifacts to `artifacts/contracts/`, and the `aztec codegen` commands from earlier wrote the TypeScript bindings to `contracts/aztec/artifacts/`. Hardhat artifacts also store the bytecode as a plain string, so in the deployment snippet below use `SimpleNFT.bytecode` and `NFTPortal.bytecode` instead of `.bytecode.object`.

You now have wallets for both chains, correctly connected to their respective chains. Next, deploy the L1 contracts:

deploy_l1_contracts
```
console.log("Deploying L1 contracts...\n");const { address: nftAddress } = await deployL1Contract(  l1Client,  SimpleNFT.abi,  SimpleNFT.bytecode.object as `0x${string}`,);const { address: portalAddress } = await deployL1Contract(  l1Client,  NFTPortal.abi,  NFTPortal.bytecode.object as `0x${string}`,);console.log(`SimpleNFT: ${nftAddress}`);console.log(`NFTPortal: ${portalAddress}\n`);
```

> [Source code: docs/examples/ts/token_bridge/index.ts#L44-L61](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/ts/token_bridge/index.ts#L44-L61)

Now deploy the L2 contracts. Thanks to the TypeScript bindings generated with `aztec codegen`, deployment is straightforward:

deploy_l2_contracts
```
console.log("Deploying L2 contracts...\n");const { contract: l2Nft } = await NFTPunkContract.deploy(  aztecWallet,  account.address,).send({  from: account.address,});const { contract: l2Bridge } = await NFTBridgeContract.deploy(  aztecWallet,  l2Nft.address,).send({ from: account.address });console.log(`L2 NFT: ${l2Nft.address.toString()}`);console.log(`L2 Bridge: ${l2Bridge.address.toString()}\n`);
```

> [Source code: docs/examples/ts/token_bridge/index.ts#L63-L80](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/ts/token_bridge/index.ts#L63-L80)

Now that you have the L2 bridge's contract address, initialize the L1 bridge:

initialize_portal
```
console.log("Initializing portal...");// Initialize the portal contract// @ts-expect-error - viem type inference doesn't work with JSON-imported ABIsconst initHash = await l1Client.writeContract({  address: portalAddress.toString() as `0x${string}`,  abi: NFTPortal.abi,  functionName: "initialize",  args: [registryAddress, nftAddress.toString(), l2Bridge.address.toString()],});await l1Client.waitForTransactionReceipt({ hash: initHash });console.log("Portal initialized\n");
```

> [Source code: docs/examples/ts/token_bridge/index.ts#L82-L96](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/ts/token_bridge/index.ts#L82-L96)

The L2 contracts were already initialized when you deployed them, but you still need to:

- Tell the L2 bridge about Ethereum's portal address (by calling `set_portal` on the bridge)
- Tell the L2 NFT contract who the minter is (by calling `set_minter` on the L2 NFT contract)

Complete these initialization steps:

initialize_l2_bridge
```
console.log("Setting up L2 bridge...");await l2Bridge.methods  .set_portal(EthAddress.fromString(portalAddress.toString()))  .send({ from: account.address });await l2Nft.methods  .set_minter(l2Bridge.address)  .send({ from: account.address });console.log("Bridge configured\n");
```

> [Source code: docs/examples/ts/token_bridge/index.ts#L98-L110](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/ts/token_bridge/index.ts#L98-L110)

This completes the setup. It's a lot of configuration, but you're dealing with four contracts across two chains.

### L1 → L2 Flow[​](#l1--l2-flow)

Now for the main flow. Mint a CryptoPunk on L1, deposit it to Aztec, and claim it on Aztec. Put everything in the same script. To mint, call the L1 contract with `mint`, which will mint `tokenId = 0`:

mint_nft_l1
```
console.log("Minting NFT on L1...");// @ts-expect-error - viem type inference doesn't work with JSON-imported ABIsconst mintHash = await l1Client.writeContract({  address: nftAddress.toString() as `0x${string}`,  abi: SimpleNFT.abi,  functionName: "mint",  args: [ownerEthAddress],});await l1Client.waitForTransactionReceipt({ hash: mintHash });// no need to parse logs, this will be tokenId 0 since it's a fresh contractconst tokenId = 0n;console.log(`Minted tokenId: ${tokenId}\n`);
```

> [Source code: docs/examples/ts/token_bridge/index.ts#L112-L128](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/ts/token_bridge/index.ts#L112-L128)

To bridge, first approve the portal address to transfer the NFT, then transfer it by calling `depositToAztec`:

deposit_to_aztec
```
console.log("Depositing NFT to Aztec...");const secret = Fr.random();const secretHash = await computeSecretHash(secret);// Approve portal to transfer the NFT// @ts-expect-error - viem type inference doesn't work with JSON-imported ABIsconst approveHash = await l1Client.writeContract({  address: nftAddress.toString() as `0x${string}`,  abi: SimpleNFT.abi,  functionName: "approve",  args: [portalAddress.toString(), tokenId],});await l1Client.waitForTransactionReceipt({ hash: approveHash });// Deposit to Aztec// @ts-expect-error - viem type inference doesn't work with JSON-imported ABIsconst depositHash = await l1Client.writeContract({  address: portalAddress.toString() as `0x${string}`,  abi: NFTPortal.abi,  functionName: "depositToAztec",  args: [    tokenId,    pad(secretHash.toString() as `0x${string}`, { dir: "left", size: 32 }),  ],});const depositReceipt = await l1Client.waitForTransactionReceipt({  hash: depositHash,});
```

> [Source code: docs/examples/ts/token_bridge/index.ts#L130-L160](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/ts/token_bridge/index.ts#L130-L160)

The `Inbox` contract will emit an important log: `MessageSent(inProgress, index, leaf, updatedRollingHash);`. This log provides the **leaf index** of the message in the [L1-L2 Message Tree](https://docs.aztec.network/developers/docs/foundational-topics/ethereum-aztec-messaging)—the location of the message in the tree that will appear on L2. You need this index, plus the secret, to correctly claim and decrypt the message.

Use viem to extract this information:

get_message_leaf_index
```
const INBOX_ABI = [  {    type: "event",    name: "MessageSent",    inputs: [      { name: "checkpointNumber", type: "uint256", indexed: true },      { name: "index", type: "uint256", indexed: false },      { name: "hash", type: "bytes32", indexed: true },      { name: "rollingHash", type: "bytes16", indexed: false },    ],  },] as const;// Find and decode the MessageSent event from the Inbox contractconst messageSentLogs = depositReceipt.logs  .filter((log) => log.address.toLowerCase() === inboxAddress.toLowerCase())  .map((log: any) => {    try {      const decoded = decodeEventLog({        abi: INBOX_ABI,        data: log.data,        topics: log.topics,      });      return { log, decoded };    } catch {      // Not a decodable event from this ABI      return null;    }  })  .filter(    (item): item is { log: any; decoded: any } =>      item !== null && (item.decoded as any).eventName === "MessageSent",  );const messageLeafIndex = new Fr(messageSentLogs[0].decoded.args.index);
```

> [Source code: docs/examples/ts/token_bridge/index.ts#L162-L198](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/ts/token_bridge/index.ts#L162-L198)

This extracts the logs from the deposit and retrieves the leaf index. You can now claim it on L2. However, for security reasons, at least 2 blocks must pass before a message can be claimed on L2. If you called `claim` on the L2 contract immediately, it would return "no message available".

Add a utility function to mine two blocks (it deploys a contract with a random salt):

mine_blocks
```
async function mine2Blocks(  aztecWallet: EmbeddedWallet,  accountAddress: AztecAddress,) {  await NFTPunkContract.deploy(aztecWallet, accountAddress).send({    from: accountAddress,  });  await NFTPunkContract.deploy(aztecWallet, accountAddress).send({    from: accountAddress,  });}
```

> [Source code: docs/examples/ts/token_bridge/index.ts#L200-L212](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/ts/token_bridge/index.ts#L200-L212)

Now claim the message on L2:

claim_on_l2
```
// Mine blocksawait mine2Blocks(aztecWallet, account.address);// Check notes before claiming (should be 0)console.log("Checking notes before claim...");const { result: notesBefore } = await l2Nft.methods  .notes_of(account.address)  .simulate({ from: account.address });console.log(`   Notes count: ${notesBefore}`);console.log("Claiming NFT on L2...");await l2Bridge.methods  .claim(account.address, new Fr(Number(tokenId)), secret, messageLeafIndex)  .send({ from: account.address });console.log("NFT claimed on L2\n");// Check notes after claiming (should be 1)console.log("Checking notes after claim...");const { result: notesAfterClaim } = await l2Nft.methods  .notes_of(account.address)  .simulate({ from: account.address });console.log(`   Notes count: ${notesAfterClaim}\n`);
```

> [Source code: docs/examples/ts/token_bridge/index.ts#L214-L237](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/ts/token_bridge/index.ts#L214-L237)

### L2 → L1 Flow[​](#l2--l1-flow)

Great! You can expand the L2 contract to add features like NFT transfers. For now, exit the NFT on L2 and redeem it on L1. Mine two blocks because of `DelayedMutable`:

exit_from_l2
```
// L2 -> L1 flowconsole.log("Exiting NFT from L2...");// Mine blocks, not necessary on devnet, but must wait for 2 blocksawait mine2Blocks(aztecWallet, account.address);const recipientEthAddress = EthAddress.fromString(ownerEthAddress);const { receipt: exitReceipt } = await l2Bridge.methods  .exit(new Fr(Number(tokenId)), recipientEthAddress)  .send({ from: account.address });console.log(`Exit message sent (block: ${exitReceipt.blockNumber})\n`);// Check notes after burning (should be 0 again)console.log("Checking notes after burn...");const { result: notesAfterBurn } = await l2Nft.methods  .notes_of(account.address)  .simulate({ from: account.address });console.log(`   Notes count: ${notesAfterBurn}\n`);
```

> [Source code: docs/examples/ts/token_bridge/index.ts#L239-L259](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/ts/token_bridge/index.ts#L239-L259)

Just like in the L1 → L2 flow, you need to know what to claim on L1. Where in the message tree is the message you want to claim? Use `node.getL2ToL1MembershipWitness`, which provides the leaf and the sibling path of the message:

get_withdrawal_witness
```
// Compute the message hash directly from known parameters// This matches what the portal contract expects: Hash.sha256ToField(abi.encodePacked(tokenId, recipient))const tokenIdBuffer = new Fr(Number(tokenId)).toBuffer();const recipientBuffer = Buffer.from(  recipientEthAddress.toString().slice(2),  "hex",);const content = sha256ToField([tokenIdBuffer, recipientBuffer]);// Get rollup version from the portal contract (it stores it during initialize)// @ts-expect-error - viem type inference doesn't work with JSON-imported ABIsconst version = (await l1Client.readContract({  address: portalAddress.toString() as `0x${string}`,  abi: NFTPortal.abi,  functionName: "rollupVersion",})) as bigint;// Compute the L2->L1 message hashconst msgLeaf = computeL2ToL1MessageHash({  l2Sender: l2Bridge.address,  l1Recipient: EthAddress.fromString(portalAddress.toString()),  content,  rollupVersion: new Fr(version),  chainId: new Fr(foundry.id),});// Wait for the block to be proven before withdrawing// Waiting for the block to be proven is not necessary on the local network, but it is necessary on devnetconsole.log("Waiting for block to be proven...");console.log(`   Exit block number: ${exitReceipt.blockNumber}`);let provenBlockNumber = await node.getBlockNumber("proven");console.log(`   Current proven block: ${provenBlockNumber}`);while (provenBlockNumber < exitReceipt.blockNumber!) {  console.log(    `   Waiting... (proven: ${provenBlockNumber}, needed: ${exitReceipt.blockNumber})`,  );  await new Promise((resolve) => setTimeout(resolve, 10000)); // Wait 10 seconds  provenBlockNumber = await node.getBlockNumber("proven");}console.log("Block proven!\n");// Compute the membership witness using the message hash and the L2 tx hash.// The node picks the smallest partial-proof root that covers the tx's checkpoint.const witness = await node.getL2ToL1MembershipWitness(  exitReceipt.txHash,  msgLeaf,);const epoch = witness!.epochNumber;const numCheckpointsInEpoch = witness!.numCheckpointsInEpoch;console.log(`   Epoch for block ${exitReceipt.blockNumber}: ${epoch}`);const siblingPathHex = witness!.siblingPath  .toBufferArray()  .map((buf: Buffer) => `0x${buf.toString("hex")}` as `0x${string}`);
```

> [Source code: docs/examples/ts/token_bridge/index.ts#L261-L319](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/ts/token_bridge/index.ts#L261-L319)

With this information, call the L1 contract and use the index and the sibling path to claim the L1 NFT:

withdraw_on_l1
```
console.log("Withdrawing NFT on L1...");// @ts-expect-error - viem type inference doesn't work with JSON-imported ABIsconst withdrawHash = await l1Client.writeContract({  address: portalAddress.toString() as `0x${string}`,  abi: NFTPortal.abi,  functionName: "withdraw",  args: [    tokenId,    BigInt(epoch),    BigInt(numCheckpointsInEpoch),    BigInt(witness!.leafIndex),    siblingPathHex,  ],});await l1Client.waitForTransactionReceipt({ hash: withdrawHash });console.log("NFT withdrawn to L1\n");
```

> [Source code: docs/examples/ts/token_bridge/index.ts#L321-L338](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/ts/token_bridge/index.ts#L321-L338)

You can now try the whole flow with:

```
npx tsx scripts/index.ts
```

## What You Built[​](#what-you-built)

A complete private NFT bridge with:

1. **L1 Contracts** (Solidity)

  - `SimpleNFT`: Basic ERC721 for testing
  - `NFTPortal`: Locks/unlocks NFTs and handles L1↔L2 messaging
2. **L2 Contracts** (Noir)

  - `NFTPunk`: Private NFT with encrypted ownership using `PrivateSet`
  - `NFTBridge`: Claims L1 messages and mints NFTs privately
3. **Full Flow**

  - Mint NFT on L1
  - Deploy portal and bridge
  - Lock NFT on L1 → message sent to L2
  - Claim on L2 → private NFT minted
  - Later: Burn on L2 → message to L1 → unlock

## Going Further: The AIP-721 NFT Standard[​](#going-further-the-aip-721-nft-standard)

The NFTPunk contract you built in this tutorial implements a simplified NFT with private ownership. The **AIP-721** standard formalizes these patterns and adds partial-note transfers, commitment-based handoffs, all 7 cross-domain transfer patterns, and authwit-based authorization.

Read the full [AIP-721 standard reference](https://docs.aztec.network/developers/docs/aztec-nr/standards/aip-721) for details, or explore all [Aztec Contract Standards](https://docs.aztec.network/developers/docs/aztec-nr/standards).

## Next Steps[​](#next-steps)

- Add a web frontend for easy bridging
- Implement batch bridging for multiple NFTs
- Add metadata bridging
- Write comprehensive tests
- Add proper access controls
- Explore the [AIP-721 standard](https://docs.aztec.network/developers/docs/aztec-nr/standards/aip-721) for production-grade NFT patterns

Learn More
- [State management page](https://docs.aztec.network/developers/docs/foundational-topics/state_management)
- [Cross-chain messaging](https://docs.aztec.network/developers/docs/foundational-topics/ethereum-aztec-messaging)
- [Aztec Contract Standards](https://docs.aztec.network/developers/docs/aztec-nr/standards)

[Edit this page](https://github.com/AztecProtocol/aztec-packages/edit/next/docs/docs-developers/docs/tutorials/js_tutorials/token_bridge.md)