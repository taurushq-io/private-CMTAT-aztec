# Private CMTA token
This project implements a private version of the CMTAT security token,
using [Aztec](https://aztec.network/).
This allows banks and financial institutions to benefits from
tokenization while maintaining privacy and compliance.

[Aztec](https://aztec.network/) is a privacy-focused Layer 2 solution on
Ethereum that enables confidential transactions using zero-knowledge
proofs (ZKPs). 

[CMTAT](https://github.com/CMTA/CMTAT?tab=readme-ov-file) is a framework
for the tokenization of securities in compliance with local regulations.
This project integrates Aztec with CMTAT, allowing financial
institutions to adopt the standard while preserving transaction
confidentiality.

This repository contains a functional private CMTAT prototype, where
transactions remain private for users, while issuers retain the ability
to audit and monitor activity to ensure compliance. This marks a
significant step forward, enabling institutions to participate in
tokenized markets without exposing confidential data—overcoming one of
the key limitations of public blockchains.

**Disclaimer:** Aztec is under heavy developpment, and this repository
may be subject to rapid changes. Significant updates will needed once
Aztec reaches testnet. Additionally, unlike CMTAT, this code has not
been audited and may not be fully compliant with the Swiss law. 


## Table of contents
- [Functionalities Overview](#functionalities-overview)
- [Private Token Implementation](#private-token-implementation)
  - [Assumptions and Requirements](#assumptions-and-requirements)
  - [Storage](#storage)
  - [Mint Private Specifications](#mint-private-specifications)
  - [Transfer Private Specifications](#transfer-private-specifications)
  - [Burn Private Specifications](#burn-private-specifications)
  - [Security and Confidentiality Properties](#security-and-confidentiality-properties)
  - [Modules](#modules)
  - [Issuer's View of Transactions and Notes](#issuers-view-of-transactions-and-notes)
- [Deployment](#deployment)
- [Comparison with Solidity CMTAT](#comparison-with-solidity-cmtat)
- [Limitations](#limitations)
- [Miscellaneous](#miscellaneous)
- [Intellectual Property](#intellectual-property)
- [Security](#security)


## Functionalities overview
The private CMTAT supports the following core features:

 - **Private** mint, burn, and transfer operations
 - **Public** pause of the contract and public freeze of specific accounts
 - **Auditability** of users private transactions by a central issuer
 - **Transfer restriction** via address blacklisting/whitelisting

Unlike the reference [Solidity CMTAT](https://github.com/CMTA/CMTAT), it
does not support:
 - Upgradeability
 - Gasless transactions

This reference implementation aims to fulfill the criteria required to
tokenize financial instruments such as bonds, equity shares, and private
credit notes.

You may modify the token code by adding, removing, or modifying
features, at your own risk.


## Private token implementation
### Assumptions and requirements
- **Assumptions**:
  - **Total Supply Visibility**: The `totalSupply` should remain public and be updated according to mint and burn operations.
  - **Issuer and Admin Addresses**: The addresses of the issuer and admin can be publicly known.
  - **Third-Party Transactions**: We want to allow third parties to execute transactions on behalf of our users, so we use **authentication witnesses** when transferring.
  - **Mint and Burn Restrictions**: There is no authentication witness in the `mint` and `burn` functions, as a third party is not allowed to mint or burn; only the issuer can perform these actions.
  - **Admin Role**: The admin cannot be changed. Issuers can be added or removed by the admin.

- **Functionalities**:
  - **TotalSupply - Public**: For a particular CMTAT token, anyone may know the total number of tokens in circulation at any point in time.
  - **BalanceOf - Private**: For a particular CMTAT token and a particular user, no one apart from the issuer should know the number of tokens currently recorded on the user's ledger address.

  - **Transfer - Private** Users may transfer some or all of their tokens to another ledger address (which the transferor does not necessarily control). According to the above functionality, a transfer must be private, such that no one apart from the parties involved and the issuer knows that a transfer has occurred, the participants, or the amount transferred.

  > NOTE: The issuer cannot do a force transfer on behalf of the user, as he would do in the CMTAT. The solution is that in the case where we want to have the same behaviour as a force transfer, we freeze the account.

  - **Mint - Private** Issue a given number of tokens to a given ledger address. The issuer and the recipient should be the only ones who know that a transaction is happening. Only the issuer and the receiving address should know the amount minted.

  > **Note - Public**: According to the assumption, the total supply will increase accordingly in a public function, and thus the new total supply will be visible to everyone. The supply change amount will be traceable to that particular private proof.

  - **Burn - Private** The issuer burns (destroys) a given number of tokens from a given ledger address. The issuer and the given address should be the only ones who know that a transaction is happening.

  > **Note - Public**: According to the assumption, the total supply will decrease accordingly in a public function, and thus the new total supply will be visible to everyone. The supply change amount will be traceable to that particular private proof.

### Storage
- **issuer_address**: `SharedMutable<AztecAddress>` - The address of the issuer, which serves as a base reference to encrypt users' notes. As it is a `SharedMutable`, it can be changed if compromised.
- **balances**: `BalanceMap<TokenNote>` - Token balance of every user inside their PXE. Mapping of `Address` → `PrivateSet<TokenNote>`. The balance of a user is the sum of the amounts of all their private `TokenNote`.

### Mint private specifications
**Issuer**:

- The new notes of the recipient are encoded and broadcasted to the issuer.

**Failure Cases**:

- **Enforcement Module**: If the "to" address is frozen, the mint will fail.
- **Authorisation Module**: If the caller doesn’t have the minter role, the mint will fail.
- **Pause Module**: If the contract is paused, the mint will fail.

**Limitations**:

- According to protocol limitations, only **4 encrypted logs** can be emitted in a function call and only **4 private functions** can be called from a function call. As we have 2 encrypted logs emitted in the mint function, our bottleneck is the encrypted logs, which means we can only batch **2 mint functions** at the same time.

### Transfer private specifications
**Issuer**:

- The added notes from sender and recipient are encoded and broadcasted to the issuer.

**Failure Cases**:

- **Enforcement Module**: If the "to" or "from" address is frozen, the transfer will fail.
- **Validation Module**: If operations are enabled, the module checks if "from" or "to" should be restricted.
- **Pause Module**: If the contract is paused, the transfer will fail.

**Limitations**:

- According to protocol limitations, only **4 encrypted logs** can be emitted in a function call. As the mint already emits 4 (2 for the user, 2 for the issuer), we can only have **1 transfer** in the transfer batch.

### Burn private specifications
**Issuer**:

- The new notes of the recipient (if any remaining) are encoded and broadcasted to the issuer.

**Failure Cases**:

- **Enforcement Module**: If the "from" address is frozen, the burn will fail.
- **Authorisation Module**: If the caller doesn’t have the burner role, the burn will fail.
- **Pause Module**: If the contract is paused, the burn will fail.

**Limitations**:

- According to protocol limitations, only **4 encrypted logs** can be emitted in a function call and only **4 private functions** can be called from a function call. As we have 2 encrypted logs emitted in the burn function, our bottleneck is the encrypted logs, which means we can only batch **2 burn functions** at the same time.

### Security and confidentiality properties
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

#### Authorisation module (access control) - public
- This module is used by other modules and by the `mint` and `burn` functions.
- Modules only need to call the `only_role` function, which publicly verifies if an address has sufficient roles for the action; otherwise, it reverts.
- The default role is the `DEFAULT_ADMIN_ROLE`, which can grant other roles.
- **Implementation Note**: This module's implementation is quite cumbersome, as in the main contract, an instance of this module is passed to each function call. This is because the object is unique, and we cannot pass it as a context (at least until a working implementation is found).

#### Validation module - shared
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

#### Pause module - public
- The pause module is a `PublicMutable`.
- The functions to set and unset the pausable flag are protected under Access Control.
- The pause check is done in public state for mint/transfer/burn operations.

#### Enforcement module - shared
- This module is called in `mint`, `transfer`, and `burn` to check if an address has been frozen.
- Unlike the validation module, this module is mandatory.
- Changing an address to frozen has a delay, as the value is a `SharedMutable`.

> **"Freeze Address" Note**: The enforcement has a delay, similar to the validation module. One approach is to pause the contract before freezing some accounts for the delay time, then unpause it. This requires manual pause/unpause.

### Issuer's view of transactions and notes
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

## Deployment
- Download the sandbox (version should match [Nargo.toml](https://github.com/taurusgroup/private-tokens/blob/master/Nargo.toml) dependency versions). Instructions [here](https://docs.aztec.network/guides/getting_started)
- downgrade to the version specified in the dependencies section of [this file](https://github.com/taurushq-io/private-CMTAT-aztec/blob/master/Nargo.toml) or specified in the latest release by running `VERSION=X.XX.X aztec-up`
- clone the repo 
- In the main directory, run: `aztec-nargo compile`
- Then, run:  `aztec test` 
- The contract is deployed on the sandbox, by the [setup function](https://github.com/taurushq-io/private-CMTAT-aztec/blob/master/src/test/utils.nr), and all the tests are run


## Comparison with solidity CMTAT
### What can we actually do with private cmtat?
- **Mint/Transfer**: Behave the same way as in CMTAT. 
- **Burn**: We can perform `burn_from` with allowance.
- **Validation Module**: Whitelisting and blacklisting are enabled on demand. The rule engine has been merged into the validation module, providing one interface that manages both and is always deployed along the main contract. The functionalities are private; storage can be read in public.
- **Pause Module**: Same functionalities as CMTAT. Pause is public and instantaneous.
- **Enforcement Module**: Freeze and unfreeze are supported. Functionalities are private; storage can be read in public.
- **Access Control Module**: Same functionalities as CMTAT. Admin has the default role, which can be used to grant roles to themselves or others.
- **Credit Events and Debt Base Modules**: Same functionalities as CMTAT.

### What will we be able to do in the future?
- **Batched Mint/Transfer/Burn**:
  - Protocol limitations currently restrict us to 4 private calls and 4 encrypted events per function call.
  - In the long run, these limitations will be lifted, enabling batched transactions. The logic is already implemented in the contracts.

> These functions are not separated into their own “abstract contract” as it does not exist in Aztec. We could put them in a library but this would mean much more boilerplate code. Following Aztec improvements, we may improve composition/abstraction in the future. 

- **Validation Module Enhancements**:
  - The limitation regarding `SharedMutable` delay means changes to the whitelist/blacklist have a delay (minutes to hours) before reflecting on the blockchain.
  - Sanction lists are not yet enabled due to the lack of on-chain lists like Chainalysis on Ethereum.

- **Enforcement Module**:
  - The delay in modifying frozen accounts due to `SharedMutable`.

- **Audit Capabilities**:
  - Users may, in the future, be able to share a shareable key for audit purposes.

- **Event Management**:
  - Events are not yet enabled because they are cumbersome; they can only be in the main contract for now and make the code lengthy.

### What will we never be able to do by design?
- **Force Burning Without Consent**:
  - We will never be able to burn someone else’s tokens without their approval.
  > This could be possible if the token is implemented at the account contract level, and the issuer has shared keys with the user for that specific account that holds notes for this token

- **Immediate Shared State Changes**:
  - We cannot have a shared state (public and private) that has no delay when changed due to the protocol's construction.

## Limitations
- **Issuer's View of User Balances**: [SEE](#issuers-view-of-transactions-and-notes)

- **Force Transfer Requirement**: [SEE](#transfer---private)
  - According to Swiss law, the issuer should be able to force the transfer of notes.
  - **Current Limitation**: This is not possible in Aztec as it would require the issuer to nullify a user's notes without consent.
  - **Workaround**:
    - Freeze the account.
    - If the account is frozen indefinitely, decrease the circulating supply. As a central issuer, I know the number of tokens the user has, so I can decrease supply accordingly. 
> Note: account freeze could reveal how much tokens a user had. 

- **SharedMutable Delay**: [SEE](#validation-module---shared)
  - Freezing and blacklisting addresses take a certain number of blocks due to the `SharedMutable` type.
  - **Options**:
    - Accept the delay.
    - Encrypt the blacklist with a key (implementation unclear).

- **Protocol Limitations**: 
  - Only **4 private calls** can be made from a private function, limiting batch functions.
  - Only **4 encrypted notes** can be emitted in a function call, further limiting batching.

- **Function Exposure**:
  - We may need to expose the `schedule_delay_change` function for every `SharedMutable`, which is cumbersome.


## Miscellaneous
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

- **Replay Attacks**:
  - The transaction hash is always emitted during local execution as the first nullifier of the transaction to prevent replay attacks. This is enforced by the private kernel circuit.

- **External References**:
  - Aztec Development Notes: [Engineering Designs](https://github.com/AztecProtocol/engineering-designs)
  - Protocol Limitations: [Aztec Protocol Circuits](https://github.com/AztecProtocol/aztec-packages/blob/aztec-packages-v0.49.1/noir-projects/noir-protocol-circuits/crates/types/src/constants.nr)

## Intellectual property
This code is copyright (c) 2025 Taurus SA and is dual-licensed under the
MIT and MPL-2.0 licenses.  You may choose either license.

See [LICENSE-MIT.md](./LICENSE-MIT.md) and [LICENSE-MPL.md](./LICENSE-MPL.md) for details.

We are not aware of any patent or patent application covering the
techniques implemented.

## Security policy
Please see [SECURITY.md](./SECURITY.md).




