
This page has been written while studying the Aztec blockchain. It is kept here as it might be useful for developpers to have a condensed documentation. However, it might not be kept up to date.

## Table of Contents

- [Aztec and Noir Concepts](#aztec-and-noir-concepts)
  - [Users Addresses and Keys](#users-addresses-and-keys)
  - [Authentication Witness](#authentication-witness)
  - [Transaction Flow and Execution Environment](#transaction-flow-and-execution-environment)
  - [Private State and Functions, Shields, Notes](#private-state-and-functions-shields-notes)
    - [Private State Storage Management](#private-state-storage-management)
    - [Private Function Execution](#private-function-execution)
    - [Capabilities of Private Functions](#capabilities-of-private-functions)
    - [Private Execution Environment](#private-execution-environment)
    - [Note](#note)
    - [Note Hash/Commitment](#note-hashcommitment)
    - [Nullifier](#nullifier)
  - [Public State and Functions](#public-state-and-functions)
    - [Public Function Execution](#public-function-execution)
  - [Unconstrained Functions](#unconstrained-functions)
  - [Fees Market, Paymaster, and Legal](#fees-market-paymaster-and-legal)
  - [Shared Mutable and Proxy](#shared-mutable-and-proxy)
  - [Aztec Limitations](#aztec-limitations)
    - [Note Encryption and Decryption Burden](#note-encryption-and-decryption-burden)
  - [Crosschain Communication](#crosschain-communication)
    - [L2 and L1 Token Interaction](#l2-and-l1-token-interaction)
      - [L1 to L2 Private Token Transfer](#l1-to-l2-private-token-transfer)
  - [Setup](#setup)
    - [Development Environment](#development-environment)
    - [Sandbox Testing](#sandbox-testing)
  - [Examples](#examples)

## Aztec and Noir Concepts

### Users Addresses and Keys

There are **four keys** for each account in Aztec:

- **Nullifier Key Pair**: Used for note nullifier computation, comprising the master nullifier secret key (`nsk_m`) and master nullifier public key (`Npk_m`).
  - Rotating nullifier keys requires the nullifier public key, or at least an identifier of it, to be stored as part of the note.
  - `nsk_m` **must not** enter an app circuit.
  - `nsk_m` **may** enter the kernel circuit.
  - `Npk_m = derive_public_key(nsk_m)`

- **Incoming Viewing Key Pair**: Used to encrypt a note for the recipient, consisting of the master incoming viewing secret key (`ivsk_m`) and master incoming viewing public key (`Ivpk_m`).
  - `ivsk_m` **must not** enter an app circuit.
  - `Ivpk_m = derive_public_key(ivsk_m)`

- **Outgoing Viewing Key Pair**: Used to encrypt a note for the sender, includes the master outgoing viewing secret key (`ovsk_m`) and master outgoing viewing public key (`Ovpk_m`).
  - `ovsk_m` **must not** enter an app circuit.
  - `ovsk_m` **may** enter the kernel circuit.
  - `Ovpk_m = derive_public_key(ovsk_m)`

- **Tagging Key Pair**: Used to compute tags in a tagging note discovery scheme, comprising the master tagging secret key (`tsk_m`) and master tagging public key (`Tpk_m`).
  - `tsk_m` **must not** enter an app circuit.
  - `Tpk_m = derive_public_key(tsk_m)`

- **Signing Key Pair**: As there is account abstraction, this will/must be implemented by the wallet provider.

### Authentication Witness

A scheme for authentication actions on Aztec allows users to permit third parties (e.g., protocols or other users) to execute an action on their behalf. It is defined for a specific action. For example, allowing an app to transfer funds on your behalf.

- **Private Context**: The authentication witness is created by the user who is making the action.
  > "I want `Defi_protocol` to send X tokens on my behalf in private."
  - The user will call `Defi_protocol`'s transfer function, which will call the transfer function of the token. The token's function will check with a private execution oracle call if the user has authorized `Defi_protocol` to send tokens on their behalf.

- **Public Context**: Account contracts will (or should) store in the account storage the third-party authorizations made by a user. When a user makes a call through a third party, it will send in a batch the signature (authentication witness) to the account contract.
  - Account contracts typically implement an entrypoint function that receives the actions to be carried out and an authentication payload.

### Transaction Flow and Execution Environment

1. **Private Functions Execution**: All private functions are executed, generating an execution trace.
2. **Private Proof Generation**: A proof of correct execution of private functions is generated.
3. **Public Functions Execution**: All public functions are executed.
4. **Public Proof Generation**: A proof of correct execution of public functions is generated.

### Private State and Functions, Shields, Notes

#### Private State Storage Management

- **PXE Database Storage** (physically stored in client): Stores encrypted data (notes). UTXO = `enc(data, owner, owner.sk)`. An entry is available if there is no nullifier linked to this entry in the Nullifier Set. Also stores authentication witnesses, deferred notes, and capsules.
- **Append-Only Hash Notes Tree** (physically stored in global state): Stores hashes of commitments (hashes of the encrypted data). Sometimes referred to as the **data tree** in Aztec documentation.
- **Append-Only Nullifier Tree** (Nullifier Set, physically stored in global state): To delete notes that have been spent, a matching nullifier is created in the nullifier tree. To create a nullifier for the specific entry, one has to have a nullifier secret key that corresponds to the owner of this specific entry. No nullifier key—no nullifier! Nullifiers are deterministically generated from UTXO inputs and can’t be forged.
  - **Nullifier**: `enc(UTXO, owner.sk (e.g., nsk_m))`
  - **Deleting a Private Value**: Emitting the corresponding nullifier.
  - **Modifying a Private Value**: Emitting a nullifier for the current state variable, generating a new private state, and appending it to the tree.
  - **Reading Private Values**: Reading data from the data tree and proving that this data is active is done by reading and creating a new nullifier, so that no one knows if data has been read or new data has been written.

#### Private Function Execution

> **Note**: Since a user's PXE doesn't have an up-to-date view of the latest public state, private functions are always executed on some historical snapshot of the network's state. Private functions do not execute on the latest up-to-date public state.

Private functions rely on historical state due to concurrency issues. Execution of private functions is done on the user’s device, away from the sequencer and the network. For example:

- **Scenario**:
  - Bob executes a private function based on public state **PS0** and ends up with a new state **PS1**.
  - In the meantime, Alice writes publicly to **PS0**, updating it to **PS1**.
  - Bob’s **PS1** cannot be proven as the new state because his **PS1** is not based on the latest state anymore, as Alice has overwritten it.
  - Bob’s transaction is thus aborted.
- **Solution**: Private functions read from historical state. Values read from historical state are checked as not nullified.

**Proof of Execution and Correctness** is generated client-side before reaching the mempool:

1. **Compilation**: Private functions are compiled down to **ACIR bytecode**.
2. **Simulation and Execution**: The PXE simulates and executes the private function on the ACVM client-side, creating a private function circuit and generating needed data, particularly the witnesses needed for proving. The proving is done after execution by the backend prover, called **Barretenberg** in Aztec’s L2.
3. **Private Kernel Circuit**: Aggregates and verifies functions from the private call stack one by one until there are none left. Builds a proof of transaction execution correctness.
4. **Transaction Submission**: Private function execution proofs, nullifiers, commitments, and logs are sent to the sequencer (the P2P pool from which transactions are picked by the sequencer) as a transaction object.
5. **Sequencer Execution**: The sequencer executes, proves, and verifies public functions with the help of a prover and the public kernel circuit, and constructs a block that it passes into the rollup circuit, which creates a final proof. The sequencer updates state trees, UTXOs, and notes/nullifiers.
6. **L1 Verification**: The proof is verified by a smart contract on L1.

### Capabilities of Private Functions

Private functions can:

- **Privately read from and insert into the private UTXO tree.**
- **Insert into the Nullifier Set.**
- **Create proofs from historical data** (coprocessor functionality).
- **Shield data** (move data from public state to private state).
- **Call public functions** (but without any return values).

### Private Execution Environment

- **PXE (Client)**: Library for private execution of functions. The client runs the **ACIR**, the **KeyStore**, and the **LMDB** (key-value store) database. The PXE generates proofs of private function execution using the private kernel circuit. **Private inputs never leave the client-side PXE.**

- **PXE Service (Server)**: API for interacting with the network from PXE.

- **ACIR**: Simulates Aztec smart contract function execution and generates the partial witness and the public inputs of the function, as well as collecting all the data (such as created notes, nullifiers, or state changes).

- **LMDB Database**: Stores the data in a key-value store.

- **KeyStore**: Secure storage for private and public keys.

- **Private Kernel Circuit**: Runs on the user’s device.

#### Note

Private variables that hold data, also known as UTXOs.

#### Note Hash/Commitment

A public commitment to some note whose value is hidden by the commitment hash property. The notes or UTXOs in Aztec need to be compressed before they are added to the trees. To do so, we need to hash all the data inside a note using a collision-resistant hash function. Currently, **Pedersen hash** is used.

- **Note Transmission**: A note that is created and nullified during the very same transaction is called **transient**. Such a note is chopped by the private kernel circuit and is never stored in any persistent data tree.
- **Encrypted Logs**: Communication channel to transmit notes.

#### Nullifier

The nullifier is generated such that, without knowing the decryption key of the owner, an observer cannot link a state record with a nullifier. There is a pattern to disassociate notes and nullifiers, which should always be used.

- **Shield Data**: Move data from public state to private state (e.g., public balance to private balance). Not necessarily the same address.
- **Unshield Data**: Move data from private state to public state (e.g., private balance to public balance). Public functions can do that if the call was initiated by a private function earlier. Not necessarily the same address.

### Public State and Functions

#### Public storage

**Data Storage Tree**: The key-value store for public contract state is an updatable merkle tree. (Public data also consists of the note hash tree and the nullifier tree). 

**Archive tree** allows us to prove statements about the state at any given block.

#### Public Function Execution

- **Compilation**: Public function code is compiled down to **AVM bytecode** (once).
- **Execution and Proving**: Two ways of executing and proving:
  - The sequencer picks up the transaction in the mempool and executes and proves public functions on the AVM. The sequencer must run the AVM.
  - The proof is done by a third-party prover.
- **Verification**: Proof is verified by the public kernel circuit.
- **Rollup**: Proof is then rolled up in the rollup circuit with other proofs and sent to L1 for verification.

**Public Functions**:

- Can read and write public state.
- Can insert into the UTXO tree for use in private functions.
- Can broadcast information to everyone (similar to `msg.data` on Ethereum).
- Can unshield data (move data from private state to public state), if the call was initiated by a private function earlier.

### Unconstrained Functions

Generally, we use unconstrained functions whenever there's something easy to verify but hard to compute within the circuit. They are not constrained by the proving circuit, so if you pass an input that should be private in an unconstrained function, you won’t know and can’t be sure that the input has not been leaked. These functions are not part of the proof; however, you can verify the computation inside a constrained function.

**Example**: Calculating the square root of a number.

```noir
fn main(in: Field) {
    out = un_sqrt(in);
    reconstructed_num = out^2;
    assert(in == reconstructed_num);
    out
}

unconstrained fn un_sqrt(in: Field) -> Field {
    out = sqrt(in);
    out
}
```

- **Execution**: Unconstrained functions are compiled down to **Brillig bytecode** and executed on the user device. The bytecode is executed by the PXE on the ACVM.
- **Usage**: Aztec.nr contracts support developer-defined unconstrained getter functions to help dApps make sense of UTXOs, e.g., `getBalance()`. These functions can be called outside of a transaction context to read private state.

### Fees Market, Paymaster, and Legal

- **Fee Payment**: Fee payment is public. Thus, if someone wants to pay fees privately, they will go through a **paymaster**.
- **Gas/Fee Token**: There will be a gas/fee token that is locked on L2 and will not be transferable. This is due to legal purposes.
- **Compliance**: Should happen at an application layer, not at the protocol layer. Aztec will provide credibly neutral infrastructure, and it’s up to the developers to build compliant applications.

### Shared Mutable and Proxy

This variable type is used when you want to create a public variable that can be privately modified and read. Private function read/write is different from public read/write because, as mentioned earlier, public functions rely on the latest public state, whereas private functions do not.

- **Challenge**: Mutable public state that can be accessed with no contention is hard.
- **Solution**: To support contract upgrades, we need a way to store what the current implementation is for a given contract such that it can be accessed from a private execution and doesn’t introduce contention between multiple transactions.
- **Usage**: If the public state is changed infrequently and it is acceptable to have delays when doing so, then shared state is a good solution to this problem.

### Aztec Limitations

#### Note Encryption and Decryption Burden

One of the functions of the PXE is constantly loading encrypted logs from the AztecNode and decrypting them. When new encrypted logs are obtained, the PXE will try to decrypt them using the private encryption key of all the accounts registered inside PXE.

- **Decryption Process**:
  - If the decryption is successful, the PXE will store the decrypted note inside a database.
  - If the decryption fails, the specific log will be discarded.
- **Note Processing**:
  - For the PXE to successfully process the decrypted note, we need to compute the note's **note hash** and **nullifier**.
  - Aztec.nr enables smart contract developers to design custom notes, meaning developers can also customize how a note's note hash and nullifier should be computed.
  - Because of this customizability, and because there will be a potentially unlimited number of smart contracts deployed to Aztec, a PXE needs to be "taught" how to compute the custom note hashes and nullifiers for a particular contract.
  - This is done by a function called `compute_note_hash_and_optionally_a_nullifier`, which is automatically injected into every contract when compiled.

### Crosschain Communication

- **L1 Bridge Contract**: Locks/unlocks funds from L1 to L2.
- **Inbox Contract**: Manages L1 → L2 pending messages.
- **Outbox Contract**: Manages L2 → L1 ready messages.
- **Portal Contracts**: Developers create portal contracts on L1 and L2 that interact with the inbox and outbox contracts.
- **L2 Structure**: Holds L1 → L2 and L2 → L1 messages.

**Message Passing**:

Since any data that is moving from one chain to another will, at some point, reside on L1, it will be public. While this is acceptable for L1 consumption (which is always public), we want to ensure that L2 consumption can be private. To support this, we use a nullifier scheme similar to what we are doing for the other notes.

- **Nullifier Scheme**: As part of the nullifier computation, we use a secret that hashes to a `secretHash`, ensuring that only actors with knowledge of the secret will be able to see when it is spent on L2.

**Message from L1 to L2**:

1. **Message Logic**: Written in the portal contract function. The message should be an Aztec function call, ABI encoded with parameters.
2. **Portal Contracts**: Send the message to the inbox.
3. **Inbox Processing**: Receives and sends the message to L2.
4. **Message Storage**: Held on the L1 → L2 append-only tree.
5. **Message Consumption**: When the message is consumed and the user has the right secret for that message, a nullifier is emitted.

**Message from L2 to L1**:

- TODO


### Questions

- **Custom Verifier Deployment**:
  - Can we have our own verifier for our proofs and deploy it on the sandbox? See [How to Solidity Verifier](https://noir-lang.org/docs/how_to/how-to-solidity-verifier/) and [Aztec Setup L1 Contracts](https://github.com/AztecProtocol/aztec-packages/blob/10048da5ce7edfe850d03ee97505ed72552c1dca/yarn-project/end-to-end/src/fixtures/setup_l1_contracts.ts).
  - This is useful for token bridges, as demonstrated in [Aztec Token Bridge Tutorial](https://docs.aztec.network/tutorials/contract_tutorials/advanced/token_bridge).

- **Fetching Public Master Keys**:
  - When fetching public master keys, is it based on historical state so we can access it from a private function?
  - What happens if the keys are not in the historical storage?
  - Do the keys fetched from other users go to my private keystore?

- **Preventing Against Key Rotation**:
  - Can we prevent against key rotation if we have the `npk_m_hash` as a value in our note instead of only `npk_m`?

- **BalanceMap Usage**:
  - Why do we have `balances: BalanceMap<TokenNote>`? Is it because we can have multiple accounts in the same PXE?
  - Is it normal that a user can see notes of another user in the PXE?
  - Answer: Yes, we can have multiple accounts in the same PXE. Notes will be encrypted in the PXE, but since the keystore has all the decryption keys of all the accounts in that PXE, it can decrypt them.

- **Nonce Utility**:
  - Investigate if the `nonce` is useful in the contracts and how to make it useful.

- **Note Encryption in PXE**:
  - When testing, private amounts seem to be accessed by external users who should not be able to.
  - Is it because notes are stored in the same PXE?
  - Answer: Notes are not yet encrypted in the user's PXE. There should be one PXE per user, which can have multiple accounts.

- **Running Multiple PXEs**:
  - Running different PXEs on the same computer is currently broken.

- **Traceability in Private to Public Calls**:
  - Public transactions will be traceable back to the private proof in private to public calls.

- **Unconstrained Functions Behavior**:
  - How do unconstrained functions behave?
  - Is `unconstrained` the same as the `view` attribute?
  - Why is the `balance_of_private` function still unconstrained in the token contract?
  - Answer: Unconstrained functions are used when we do not change the state of the network or when performing an off-chain call. `View` functions are used for reading from public state; you cannot use `unconstrained` for this.

- **Witnesses in Proof Generation**:
  - Are the witnesses the private function inputs that need to be kept private?
  - The proving backend (Barretenberg) creates the proof, and then the private kernel circuit verifies it.

- **PXE and ACVM Instances**:
  - Each PXE has an instance of the ACVM.

- **Blacklist Delay Impact**:
  - Will a user who is just blacklisted be able to make one more transaction before being publicly flagged due to the delay constant?
  - Answer: Cat from Aztec takes a look at it and gives me an answer. 

- **Proof Verification Flow**:
  - Private/public functions are executed by their respective VMs, and a proof of this execution is generated.
  - This proof is fed to the private kernel circuits, which verify it.
  - The proof is then sent to L1 for verification.

- **Block Manipulation in Aztec**:
  - How can we move the blocks of Aztec? Not implemented yet.

- **Event Emission and Key Registration**:
  - When emitting events, `ivpk_m` is used to encrypt an event to the receiver.
  - We need to ensure that this key has been registered in the PXE.
  - Is it the wallet’s job to do that?
  - Answer: Yes

- **Note Decryption and PXE Storage**:
  - Can we decrypt a note with our PXE and decide if we want that note inside our PXE or not?
  - For example, rejecting memecoins airdropped to us.
  - Will the PXE database get full at some point?

- **Note Encryption Constrained vs. Unconstrained**:
  - What's the difference between constrained and unconstrained note encryption?
  - Answer: note encryption needs to be constrained, as it is an important information that 
  someone sends you and you want it to be verified by the kernel circuits. 

- **Burn Function Authorization**:
  - Can we burn other people's tokens if our burn function doesn't have authentication witness protection?
  - Answer: No. This may occur in tests because there is only one PXE in the tests.

- **Sender Identity in Notes**:
  - When someone sends us a note, do we know the sender's address?
  - Answer: No, unless the developer includes the sender's address in a note field.

- **TokenNote Interface Changes**:
  - Ask about changes in the `TokenNote` interface from version 0.48.0.
  - What does `TokenNoteHidingPoint` mean?
  - What is the `compute_note_hiding_point` function, and where is it used?

- **Duplicate Note Emission**:
  - If we emit the same note twice, one for the user and one for the issuer, what do we use instead of the `ovpk_m` of the second encryption?
  - We don't want the user to end up with two identical notes.

- **PXE Data Portability**:
  - What happens if we change computers and our PXE is stored on our device?

### L2 and L1 Token Interaction

- **Privacy Considerations**:
  - **Address Privacy**: Addresses are private.
  - **Amount Privacy**: Amounts are private.
  - **Shield/Unshield Pattern**: Used for moving tokens between L1 and L2.

#### L1 to L2 Private Token Transfer

1. **Initiate Transfer**:
   - L1 token is sent to the inbox contract from the portal contract.
   - The portal contract computes the L2 message selector that calls the `mint_private` function on L2.
   - The portal contract transfers the token amount from the user to the portal contract.

2. **Inbox Processing**:
   - The inbox contract sends the message to the L2 append-only tree.

### Setup

#### Development Environment

- **Installation**:
  - Get the sandbox, `aztec-cli`, and other tooling:

    ```bash
    bash -i <(curl -s install.aztec.network)
    ```

- **Install Dependencies**:
  - Follow [Aztec.js Getting Started](https://docs.aztec.network/getting_started/aztecjs-getting-started):

    ```bash
    yarn init -yp
    yarn add @aztec/aztec.js @aztec/accounts @aztec/noir-contracts.js typescript @types/node
    ```

- **Node Version**:
  - Downgrade Node to version **20.14.0** until fixed with the Aztec team.

- **Compile Contracts**:

  ```bash
  aztec-nargo compile
  ```

- **Generate TypeScript Artifacts**:

  ```bash
  aztec codegen -o src/artifacts target
  ```

- **Note**:
  - Ensure that dependencies in `Nargo.toml` and `package.json` are the same version.

#### Sandbox Testing

- **Cheat Codes**:
  - Refer to the [Sandbox Reference Cheat Codes](https://docs.aztec.network/reference/sandbox_reference/cheat_codes) for testing.

### Examples

- **Aztec's Private Token Contract Example**: [Token Contract Tutorial](https://docs.aztec.network/tutorials/contract_tutorials/token_contract)
- **DEX Built on Aztec**: [Aztec DEX Build](https://github.com/porco-rosso-j/aztec-dex-build)
- **Homomorphic Encryption**:
  - [Noir ElGamal](https://github.com/jat9292/noir-elgamal/)
  - [Aztec Coin Toss PvP](https://github.com/defi-wonderland/aztec-coin-toss-pvp)
  - Note: Full Homomorphic Encryption (FHE) is not yet supported on Aztec.
- **Token Transfer Flows**: [Transferring Someone Else's Notes](https://forum.aztec.network/t/transferring-someone-elses-notes/2586)
- **Private Token Using Aztec**: [Ethereum's Privacy New Frontier](https://medium.com/@jat9292/zksnarks-homomorphic-encryption-ethereums-privacy-new-frontier-b30357236a7a)
- **Aztec Explorer**: [ShieldSwap](https://github.com/olehmisar/shieldswap)
