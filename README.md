# Private tokens

new commits correctly signed

## What we are achieving 

This project aims to implement a private version of the CMTAT standard using Aztec, enabling banks and financial institutions to leverage the benefits of tokenization while preserving privacy and compliance.

## Introduction

Aztec is a privacy-focused Layer 2 solution built on Ethereum that enables confidential transactions using Zero-Knowledge Proofs (ZKPs). By using Aztec, we can ensure that sensitive data, such as transaction details, remain private. CMTAT is an open standard security token  designed to facilitate the tokenization of digital assets, ensuring both regulatory compliance and extended functionalities. With the integration of Aztec, this project allows institutions to fully adopt the CMTAT standard while maintaining confidentiality in their transactions. In this repository, we implement a fully functional private CMTAT prototype, where transactions are private for users, while issuers retain the ability to audit and monitor the activity to ensure compliance. This represents a significant step forward, as it allows institutions to participate in tokenized markets without exposing their confidential data, addressing one of the main limitations of using public blockchains such as Ethereum.

## LEARNING 

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
- [Private Token Implementation](#private-token-implementation)
  - [Assumptions and Requirements of CMTAT Private V1](#assumptions-and-requirements-of-cmtat-private-v1)
    - [Transfer - Private](#transfer---private)
    - [Mint - Private](#mint---private)
    - [Burn - Private](#burn---private)
    - [Compliance and Audibility](#compliance-and-audibility)
  - [Storage](#storage)
  - [Mint Private](#mint-private)
  - [Transfer Private](#transfer-private)
  - [Burn Private](#burn-private)
  - [Security and Confidentiality Concerns](#security-and-confidentiality-concerns)
  - [Modules](#modules)
    - [Authorisation Module (Access Control) - Public](#authorisation-module-access-control---public)
    - [Validation Module - Shared](#validation-module---shared)
    - [Pause Module - Public](#pause-module---public)
    - [Enforcement Module - Shared](#enforcement-module---shared)
  - [Issuer's View of Transactions and Notes](#issuers-view-of-transactions-and-notes)
  - [L2 and L1 Token Interaction](#l2-and-l1-token-interaction)
    - [L1 to L2 Private Token Transfer](#l1-to-l2-private-token-transfer)
  - [Miscellaneous and Other Concerns](#miscellaneous-and-other-concerns)
  - [Issues and Solutions in Token Contract on Aztec](#issues-and-solutions-in-token-contract-on-aztec)
  - [Upgradability and Proxy](#upgradability-and-proxy)
  - [Comparison Between CMTAT and Aztec Token](#comparison-between-cmtat-and-aztec-token)
    - [What Can We Actually Do?](#what-can-we-actually-do)
    - [What Will We Be Able to Do in the Future?](#what-will-we-be-able-to-do-in-the-future)
    - [What Will We Never Be Able to Do by Design?](#what-will-we-never-be-able-to-do-by-design)
  - [Setup](#setup)
    - [Development Environment](#development-environment)
    - [Sandbox Testing](#sandbox-testing)
  - [Questions](#questions)
  - [TODO](#todo)
  - [Examples](#examples)
  - [Other Ways of Doing Encryption](#other-ways-of-doing-encryption)
- [Additional Resources](#additional-resources)

## Aztec and Noir Concepts

### Users Addresses and Keys

Keys can be pinned to a certain block so that key rotation doesn’t impact the validity of an authentication at any given time. There are **four keys** for each account in Aztec:

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

1. **Private Functions Execution**: All private functions are executed in an execution trace.
2. **Proof Generation**: A proof of correct execution is generated.
3. **Public Functions Execution**: All public functions are executed.

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


## Private Token Implementation

### Assumptions and Requirements of CMTAT Private V1

- **Assumptions**:
  - **Total Supply Visibility**: The `totalSupply` should remain public and be updated according to mint and burn operations.
  - **Issuer and Admin Addresses**: The addresses of the issuer and admin can be publicly known.
  - **Third-Party Transactions**: We want to allow third parties to execute transactions on behalf of our users, so we use **authentication witnesses** when transferring.
  - **Mint and Burn Restrictions**: There is no authentication witness in the `mint` and `burn` functions, as a third party is not allowed to mint or burn; only the issuer can perform these actions.
  - **Admin Role**: The admin cannot be changed. Issuers can be added or removed by the admin.

- **Functionalities**:
  - **TotalSupply - Public**: For a particular CMTAT token, anyone may know the total number of tokens in circulation at any point in time.
  - **BalanceOf - Private**: For a particular CMTAT token and a particular user, no one apart from the issuer should know the number of tokens currently recorded on the user's ledger address.

#### Transfer - Private

Users may transfer some or all of their tokens to another ledger address (which the transferor does not necessarily control). According to the above functionality, a transfer must be private, such that no one apart from the parties involved and the issuer knows that a transfer has occurred, the participants, or the amount transferred.

> **Discussion between JP, Ryan and Gustave** : The issuer cannot do a force transfer on behalf of the user, as he would do in the CMTAT. The solution is that in the case where we want to have the same behaviour as a force transfer, we freeze the account.

#### Mint - Private

Issue a given number of tokens to a given ledger address. The issuer and the recipient should be the only ones who know that a transaction is happening. Only the issuer and the receiving address should know the amount minted.

- **Note - Public**: According to the assumption, the total supply will increase accordingly in a public function, and thus the new total supply will be visible to everyone. The supply change amount will be traceable to that particular private proof.

#### Burn - Private

The issuer burns (destroys) a given number of tokens from a given ledger address. The issuer and the given address should be the only ones who know that a transaction is happening.

- **Note - Public**: According to the assumption, the total supply will decrease accordingly in a public function, and thus the new total supply will be visible to everyone. The supply change amount will be traceable to that particular private proof.

#### Compliance and Audibility

Provide users the option of sharing private transaction details with a trusted third party. A user can optionally share "shareable" secret keys to enable a third party to decrypt the following data:

- Outgoing data, across all apps.
- Outgoing data, siloed for a single app.
- Incoming internal data, across all apps.
- Incoming internal data, siloed for a single app.
- Incoming data, across all apps.

### Storage

- **issuer_address**: `SharedMutable<AztecAddress>` - The address of the issuer, which serves as a base reference to encrypt users' notes. As it is a `SharedMutable`, it can be changed if compromised.
- **balances**: `BalanceMap<TokenNote>` - Token balance of every user inside their PXE. Mapping of `Address` → `PrivateSet<TokenNote>`. The balance of a user is the sum of the amounts of all their private `TokenNote`.

### Mint Private

**Issuer**:

- The new notes of the recipient are encoded and broadcasted to the issuer.

**Failure Cases**:

- **Enforcement Module**: If the "to" address is frozen, the mint will fail.
- **Authorisation Module**: If the caller doesn’t have the minter role, the mint will fail.
- **Pause Module**: If the contract is paused, the mint will fail.

**Limitations**:

- According to protocol limitations, only **4 encrypted logs** can be emitted in a function call and only **4 private functions** can be called from a function call. As we have 2 encrypted logs emitted in the mint function, our bottleneck is the encrypted logs, which means we can only batch **2 mint functions** at the same time.

### Transfer Private

- Since `nsk_m` cannot be inserted in an app circuit, it is hardened to create the `nsk_app`, which is used in the app circuit as the secret for the nullifier computation.

**Issuer**:

- The added notes from sender and recipient are encoded and broadcasted to the issuer.

**Failure Cases**:

- **Enforcement Module**: If the "to" or "from" address is frozen, the transfer will fail.
- **Validation Module**: If operations are enabled, the module checks if "from" or "to" should be restricted.
- **Pause Module**: If the contract is paused, the transfer will fail.

**Limitations**:

- According to protocol limitations, only **4 encrypted logs** can be emitted in a function call. As the mint already emits 4 (2 for the user, 2 for the issuer), we can only have **1 transfer** in the transfer batch.

### Burn Private

**Issuer**:

- The new notes of the recipient (if any remaining) are encoded and broadcasted to the issuer.

**Failure Cases**:

- **Enforcement Module**: If the "from" address is frozen, the burn will fail.
- **Authorisation Module**: If the caller doesn’t have the burner role, the burn will fail.
- **Pause Module**: If the contract is paused, the burn will fail.

**Limitations**:

- According to protocol limitations, only **4 encrypted logs** can be emitted in a function call and only **4 private functions** can be called from a function call. As we have 2 encrypted logs emitted in the burn function, our bottleneck is the encrypted logs, which means we can only batch **2 burn functions** at the same time.

### Security and Confidentiality Concerns

- **Private Mint Call to Public Function**:
  - **Reveals Minter Address**: Since it is a parameter in the public function call. It is the issuer, whose address is already known, but still, private to public function calls pose a problem as they also reveal that the contract was called.
  - **Randomizing `msg.sender`**: An out-of-protocol option is to deploy a diversified account contract and route transactions through this contract. Application developers might also do something similar to randomize the `msg.sender` of their app contract's address.
  - **Leakage of Minted Amount**: The amount being minted is leaked as it is passed to the public function from the private one.
  > In the case of our token, when an issuer mints tokens, it is publicly known how much tokens he mints. This means that if the issuer mints “on-demand“ (every time a user wants to mint some tokens, the issuer mints) then there is a leak of information. This can be mitigated by the issuer minting a fixed amount of tokens at a certain point in time (= circulating supply), and then privately distributing to the users, thus revealing absolutely no information. 
  - **Traceability**: The public transaction will be traceable back to the private proof.
  - **Disclosure of Private Function Call**: It will leak that a private function (`private_mint`) has been called.
  - **Recipient Address Privacy**: It will **not** leak the address to which this amount is being sent.

- **Nullifier and Note Hash Security**:
  - **Randomness**: We must add randomness to the note hash when creating it.
  - **Nullifier Secrecy**: We must add a secret (e.g., `nsk_app`) when calculating the nullifier of a note so that no link can be made between a note and its nullifier.
  - **Key Hardening Algorithm**: The algorithm to harden `nsk_m` into `nsk_app` is optimized but not guaranteed to be secure as of now. See [Aztec Key Derivation](https://docs.aztec.network/protocol-specs/addresses-and-keys/keys#key-derivation).

- **Note Encryption Constraints**:
  - Note encryption should be **constrained**. We could make note encryption and tagging unconstrained, as this is allowed, but we don’t want to.
  - **Incentive Alignment**: Unconstrained note encryption is done when the sender has an incentive to send correct information to the receiver, as no one proves and verifies it. However, in our case, the sender is in no way incentivized to do the right thing.
  - **Optimization**: For optimization purposes, unconstrained might be acceptable in some places.

### Modules

Abstract contracts do not exist in Aztec Noir, so the modules are separated in the form of interfaces and implementations. Inheritance also does not exist, which means that every function that can or should be called by a user needs to be exposed in the main contract. Consequently, not everything can be displaced from the main contract (e.g., `mint`, `burn`, and `transfer` are all in the main contract), and most functions are exposed there. There are 34 functions in the main contract.

#### Authorisation Module (Access Control) - Public

- This module is used by other modules and by the `mint` and `burn` functions.
- Modules only need to call the `only_role` function, which publicly verifies if an address has sufficient roles for the action; otherwise, it reverts.
- The default role is the `DEFAULT_ADMIN_ROLE`, which can grant other roles.
- **Implementation Note**: This module's implementation is quite cumbersome, as in the main contract, an instance of this module is passed to each function call. This is because the object is unique, and we cannot pass it as a context (at least until a working implementation is found).

#### Validation Module - Shared

- This module is called only when performing transfers.
- The `operateOnTransfer` function, used in a private context, is called by the transfer function.
- Each user flag update will be delayed by `CHANGE_ROLES_DELAY_BLOCKS`.
- If no operations are enabled, no checks are done, but the function is still called.
- Operations can be enabled or disabled, and there is also a delay.
- Currently, no operations can be added; there is only blacklist/whitelist, and the sanction list is not implemented.

**Delay Issue**:

- The delay is caused by the fact that the roles are stored in a `SharedMutable` variable type.
- This is needed to preserve privacy when doing a private transfer between two users while maintaining the strict rule that no tokens should be transferred from/to a blacklisted address.
- **Problem**: A user who knows they are going to be blacklisted in a certain number of blocks might send their funds to an address that is not blacklisted. This problem has no solution for now.
- **Consideration**: We need to think about whether the shared state will be changed often. If not, then `SharedMutable` is an acceptable solution; otherwise, it might be problematic.

**Potential Solutions**:

- **Theoretical Solution 1**: Using a `SharedMutable` is essential because otherwise, you would use a `PublicMutable`, which means that the user calling the transfer function needs to call a public function to read the `PublicMutable` variable, leaking the sender’s address. One possible solution might be to hide the caller's address using [Diversified and Stealth Addresses](https://docs.aztec.network/protocol-specs/addresses-and-keys/diversified-and-stealth). If reading `PublicMutable` did not leak the user address, then `SharedMutable` would be unnecessary.
- **Theoretical Solution 2**: Have a counter that is set when the `SharedMutable` is changed. For the `COUNTER` amount of time, the token contract is paused to prevent any blacklisted address from retrieving funds. This solution is poor in terms of user experience and developer experience, as the issuer needs to manually unpause the contract.
- **Practical Solution 3**: If we whitelist instead of blacklist, a new whitelisted address will not be able to transfer funds directly, which is not a significant issue.

#### Pause Module - Public

- The pause module is a `PublicMutable`.
- The functions to set and unset the pausable flag are protected under Access Control.
- The pause check is done in public state for mint/transfer/burn operations.

#### Enforcement Module - Shared

- This module is called in `mint`, `transfer`, and `burn` to check if an address has been frozen.
- Unlike the validation module, this module is mandatory.
- Changing an address to frozen has a delay, as the value is a `SharedMutable`.

**"Freeze Address" Note**:

- The enforcement has a delay, similar to the validation module.
- One approach is to pause the contract before freezing some accounts for the delay time, then unpause it. This requires manual pause/unpause.

### Issuer's View of Transactions and Notes

- **Objective**: Enable the issuer to see all transactions.
- **Options**:
  - **Emit Events**: Emit events that can be viewed by a third party by inputting their `ivpk_m` (issuer's incoming viewing public key).
    - **Considerations**:
      - We may not be able to see the exact token holdings but can see all transfers.
      - We can reconstruct token holdings at a certain point in time using the history library.
  - **Duplicate Notes**: When emitting a note, emit a duplicate encrypted with the issuer's `ivpk_m`.
    - **Challenges**:
      - Doubling the notes needed.
      - Keeping track of them in our own PXE.
  - **App-Siloed Key**: Use an app-siloed key that the issuer can use for decrypting any note in the note hash tree of this app.
  - **Shared Encryption Key**: Encrypt the note once but allow two people to decrypt it.
  - **Key Rotation and Update**: Make the viewing key rotatable and updatable.


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

### Miscellaneous and Other Concerns

- **Wallet Responsibilities**:
  - The wallet should implement note discovery and tagging mechanisms, not the application.

- **Mint Function Restrictions**:
  - Should we restrict the "to" address to not be the issuer to prevent a malicious issuer from hiding the real supply of the token by minting tokens to themselves?

- **Contract Modification**:
  - Can a user modify a token contract function? No, it is not possible as each function is committed on the public state.

- **Encryption Details**:
  - Encryption of note emission is done with AES-128. It's currently unclear if the encryption with AES is constrained at the protocol circuit level.

- **Transaction Details**:
  - Notes are linked to their transaction hash because they are in the same transaction object when waiting in the mempool.
  - The transaction object cannot be modified between the point when it has been locally proven and when it reaches the sequencer because the output of the private kernel circuit is the input to the public kernel circuits, which also verify.

- **Sender Anonymity**:
  - Currently, we cannot know who sent us a private note. When receiving a note, we can link it to a certain transaction object but cannot know the sender. One solution is to include the sender's address inside a note field, but we need to consider confidentiality concerns.

- **Replay Attacks**:
  - The transaction hash is always emitted during local execution as the first nullifier of the transaction to prevent replay attacks. This is enforced by the private kernel circuit.

### Issues and Solutions in Token Contract on Aztec

- **Issuer's View of User Balances**: [SEE](#issuers-view-of-transactions-and-notes)

- **Force Transfer Requirement**: [SEE](#transfer---private)
  - According to Swiss law, the issuer should be able to force the transfer of notes.
  - **Current Limitation**: This is not possible in Aztec as it would require the issuer to nullify a user's notes without consent.
  - **Workaround**:
    - Freeze the account.
    - If the account is frozen indefinitely, decrease the circulating supply. However, we might not know the amount of tokens the user holds.

- **SharedMutable Delay**: [SEE](#validation-module---shared)
  - Freezing and blacklisting addresses take a certain number of blocks due to the `SharedMutable` type.
  - **Options**:
    - Accept the delay.
    - Encrypt the blacklist with a key (implementation unclear).

- **Protocol Limitations**: [SEE](#mint---private)
  - Only **4 private calls** can be made from a private function, limiting batch functions.
  - Only **4 encrypted notes** can be emitted in a function call, further limiting batching.

- **Function Exposure**:
  - We may need to expose the `schedule_delay_change` function for every `SharedMutable`, which is cumbersome.

### Upgradability and Proxy

Refer to contract instances and contract classes to understand this better. See [Aztec Contract Deployment](https://docs.aztec.network/protocol-specs/contract-deployment/instances).

### Comparison Between CMTAT and Aztec Token

#### What Can We Actually Do?

- **Mint/Transfer**: Behave the same way as in CMTAT. Currently, there is no knowledge of who sent you notes.
- **Burn**: We can perform `burn_from` with allowance.
- **Validation Module**: Whitelisting and blacklisting are enabled on demand. The rule engine has been merged into the validation module, providing one interface that manages both and is always deployed along the main contract. The functionalities are private; storage can be read in public.
- **Pause Module**: Same functionalities as CMTAT. Pause is public and instantaneous.
- **Enforcement Module**: Freeze and unfreeze are supported. Functionalities are private; storage can be read in public.
- **Access Control Module**: Same functionalities as CMTAT. Admin has the default role, which can be used to grant roles to themselves or others.
- **Credit Events and Debt Base Modules**: Same functionalities as CMTAT.

#### What Will We Be Able to Do in the Future?

- **Batched Mint/Transfer/Burn**:
  - Protocol limitations currently restrict us to 4 private calls and 4 encrypted events per function call.
  - In the long run, these limitations will be lifted, enabling batched transactions. The logic is already implemented in the contracts.

> These functions are not separated into their own “abstract contract” as it does not exist in Aztec. We could put them in a library but this would mean much more boilerplate code. They may improve composition/abstraction in the future. 

- **Validation Module Enhancements**:
  - The limitation regarding `SharedMutable` delay means changes to the whitelist/blacklist have a delay (minutes to hours) before reflecting on the blockchain.
  - Sanction lists are not yet enabled due to the lack of on-chain lists like Chainalysis on Ethereum.

- **Enforcement Module**:
  - The delay in modifying frozen accounts due to `SharedMutable`.

- **Accounting Improvements**:
  - Currently, we cannot know who sent us encrypted notes, which is an issue for accounting.
  - A possible solution is to create a new field in a note with the address of the account that created the note.

- **Audit Capabilities**:
  - Users may, in the future, be able to share a shareable key for audit purposes.

- **Event Management**:
  - Events are not yet enabled because they are cumbersome; they can only be in the main contract for now and make the code lengthy.

#### What Will We Never Be Able to Do by Design?

- **Force Burning Without Consent**:
  - We will never be able to burn someone else’s tokens without their approval unless there is a significant change in protocol design.

- **Immediate Shared State Changes**:
  - We cannot have a shared state (public and private) that has no delay when changed due to the protocol's construction.

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

### TODO

- **Amount Proofs**: Implement a proof for proving that you own less/more than a certain amount.
- **Overflow Testing**: Investigate and test for overflow issues.
- **Shareable Key**: Develop functionality for a shareable key.
  - This is an important focus
  -  I was thinking  you could do something like the multisig that you are working on, 
  where the encryption+nullifying key is stored in a note in the account contract, and any 
  notes created for that account are encrypted to that. You, as the platform manager and asset 
  issuer, would be on every multisig account that your customers use, so you would be able to 
  see all notes associated with every account that you set up. you could set it up so that your 
  account wouldn't be able to send transactions though, just see all data. 

as far as the requirement for minting and burning tokens, you can program that logic into the token contract itself. as the admin of the token contract, you would be able to modify anyone's balance. And since you would be able to read everyone's private notes and have the nullifying key, you would be able to delete their private notes
- **Contract Library Method Macro**: Explore the new `[contract_library_method]` macro on Aztec.
- 

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

### Other Ways of Doing Encryption

- **Zcash Shielded Assets (ZSA)**:
  - Implemented by [QEDIT](https://qed-it.com)
  - [Video Explanation](https://www.youtube.com/watch?v=L_ZtZCUvDqw)
    - **Question**: Does the ZSA issuer have any way to track assets and transactions once owners have included the ZSAs in shielded transactions?
    - **Answer**: Basically, no.
  - Their proposal has been rejected by the Zcash community.

- **Polygon Miden**:
  - Encrypted notes are not live yet on Miden.
  - Currently, only private and public notes are available.
  - Support for encrypted notes will be added later, as per their Discord server.

- **Zama**:
  - [Zama AI](https://www.zama.ai)

- **Other Platforms**:
  - [Aleo](https://aleo.org)
  - [Ergo Platform](https://ergoplatform.org/en/)
  - **Silent Data**: There is no public information, makes us think that they are not ready. 
  - [Taceo](https://taceo.io/) 

## Additional Resources

- **Aztec’s Presentations**: [Google Drive Link](https://drive.google.com/drive/folders/1bS0hZ2oVpY3okZ0XFdG7aipa0Th9rOPy)
- **Aztec Development Notes**: [Engineering Designs](https://github.com/AztecProtocol/engineering-designs)
- **Protocol Limitations**: [Aztec Protocol Circuits](https://github.com/AztecProtocol/aztec-packages/blob/aztec-packages-v0.49.1/noir-projects/noir-protocol-circuits/crates/types/src/constants.nr)
- **Testnet Information**:
  - 10 TPS on testnet.
  - Testnet coming in December/January.
  - Noir compiler audit in January 2025.
