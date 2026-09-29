# CMTAT and AIP-20 — a detailed comparison

A comparison of the **CMTAT** security-token standard with **AIP-20**, the Aztec fungible-token standard, written while building [private-CMTAT-aztec](../../README.md): a CMTAT implementation on Aztec that deliberately does **not** conform to AIP-20.

The purpose is to explain *why* those two things do not fit together, in enough detail that the reader can judge the argument rather than take it on trust — and then to ask what each standard could take from the other.

## Table of contents

- [What this is based on](#what-this-is-based-on)
- [Summary](#summary)
- [The two standards solve different problems](#the-two-standards-solve-different-problems)
- [Side-by-side comparison](#side-by-side-comparison)
  - [Balance model](#balance-model)
  - [Transfer surface](#transfer-surface)
  - [Access control and supply](#access-control-and-supply)
  - [Compliance and restriction](#compliance-and-restriction)
  - [Metadata](#metadata)
  - [Lifecycle and upgradeability](#lifecycle-and-upgradeability)
  - [Composability](#composability)
- [The two irreducible conflicts](#the-two-irreducible-conflicts)
  - [Conflict 1 — public balances](#conflict-1--public-balances)
  - [Conflict 2 — partial notes and recipient screening](#conflict-2--partial-notes-and-recipient-screening)
- [Where they agree](#where-they-agree)
- [Suggestions to improve AIP-20](#suggestions-to-improve-aip-20)
- [Suggestions to improve CMTAT](#suggestions-to-improve-cmtat)
- [How a project should choose](#how-a-project-should-choose)
- [References](#references)

## What this is based on

| Source | Version | Notes |
|---|---|---|
| CMTAT Solidity | `v3.3.0-rc3`, commit `658672f` | The pinned submodule at `submodules/CMTAT` |
| CMTAT Equivalency Assessment Criteria | template `v0.3.0` | `submodules/CMTAT-equivalency-assessment`; 61 criteria, 19 mandatory |
| AIP-20 | as documented for Aztec `5.2.0` | `aztec-nr/standards/aip-20` |
| AIP-721, AIP-4626 | same | consulted for context on the shared partial-note pattern |
| private-CMTAT-aztec | this repository, `0.3` development branch | the worked example |

> **A caveat on the AIP-20 side.** The canonical AIP-20 implementation is the [`aztec-standards`](https://github.com/defi-wonderland/aztec-standards) repository maintained by DeFi Wonderland, and the Aztec documentation says explicitly that it differs from the reference contracts shipped in `aztec-packages`. This document is written against the **published Aztec documentation** for AIP-20, not against a checkout of that repository. Storage layout, the partial-note flow, the note-count constants and the recursion pattern are quoted from it directly. Where the full function list matters, treat the repository as authoritative.
>
> **Updated after reading the source.** The library has since been checked out at `submodules/aztec-standards` (commit `a3859e5`) and read directly. That reading **corrected one claim in this document** — AIP-20 does have a transfer-authorization hook, ARC-403, which an earlier revision said it lacked. The correction is applied below and explained in [`building-on-aip20.md`](./building-on-aip20.md).

## Summary

**AIP-20 is a fungible-token standard for composable private DeFi. CMTAT is a security-token standard for regulated financial instruments. They are not competing designs of the same thing, and a token cannot fully be both.**

The overlap is small and shallow: name, symbol, decimals, a total supply, and private balances held as notes. Everything that makes each standard *worth having* is absent from the other. AIP-20 contributes partial notes, a public/private balance split and a note-consumption strategy; CMTAT contributes transfer restriction, freezing, pausing, role-based issuance, and the metadata a real-world instrument needs.

Two of the differences are not gaps to be closed by work — they are conflicts, set out in [The two irreducible conflicts](#the-two-irreducible-conflicts). The second turned out, on reading the source, to be a timing problem with an addition that fixes it rather than an impossibility; the heading is kept so the correction is visible.

## The two standards solve different problems

**CMTAT** is published by the [Capital Markets and Technology Association](https://www.cmta.ch/), a Swiss body of banks, law firms and technology companies. It exists so that a tokenised security can satisfy the obligations of an *issuer*: know who holds the instrument, be able to stop a transfer, be able to freeze an account, be able to point at the legal documentation, be able to redeem. Its structure follows from those obligations, and the CMTA equivalency criteria make them explicit — 19 of the 61 criteria are mandatory, and they are dominated by issuer controls (pause, freeze, transfer restriction, forced transfer, role administration).

**AIP-20** is maintained by DeFi Wonderland as part of the `aztec-standards` family, and its stated purpose is interoperability: "establishing conventions that allow contracts, wallets, and tooling to interoperate without prior coordination". Its structure follows from Aztec's execution model rather than from any regulatory requirement. Partial notes exist because a private function runs on the user's device and cannot read public state; recursive note consumption exists because proving time is paid by the user.

The result is that each standard is nearly silent where the other is detailed.

## Side-by-side comparison

### Balance model

| | CMTAT (Solidity) | AIP-20 | private-CMTAT-aztec |
|---|---|---|---|
| Holder balance | Public `mapping(address => uint256)` | **Both**: `private_balances: Owned<BalanceSet>` and `public_balances: Map<AztecAddress, PublicMutable<u128>>` | Private only, `Owned<BalanceSet>` |
| Total supply | Public | Public `PublicMutable<u128>` | Public `PublicMutable<u128>` |
| Who can read a balance | Anyone | Anyone, for the public side; only the owner for the private side | Only the owner, plus the issuer through delivered note copies |
| Holder enumeration | Possible off-chain from events; `HolderListModule` on-chain | Not possible for private balances | Not possible; the issuer reconstructs from its note copies |

The three-way split matters. CMTAT assumes a transparent ledger and builds issuer control on top of it. AIP-20 offers a *choice* per balance. This implementation removes the choice in the other direction: everything private, because the CMTA privacy requirement was the point of the exercise.

### Transfer surface

| | CMTAT | AIP-20 |
|---|---|---|
| Basic transfer | `transfer`, `transferFrom` (ERC-20) | Private↔private, private↔public, public↔public paths |
| Delegated spend | ERC-20 allowance, standing until changed | Authwit-style validation per call |
| Deferred/undetermined recipient | — | **`initialize_transfer_commitment`** → `transfer_private_to_commitment` → `complete_from_private` |
| "This party is private" marker in public events | — | `PRIVATE_ADDRESS_MAGIC_VALUE`, explicitly distinct from the zero address |
| Note consumption strategy | n/a (account model) | `INITIAL_TRANSFER_CALL_MAX_NOTES = 2`, then `#[only_self]` recursion at `RECURSIVE_TRANSFER_CALL_MAX_NOTES = 8` |
| Forced transfer | `forcedTransfer` — mandatory-adjacent for regulatory recovery | — |

**Partial notes are the heart of AIP-20** and have no CMTAT counterpart, because on an account-model chain the problem does not exist: a public function can read state and move a balance in the same call.

**Forced transfer is the heart of CMTAT's recovery story** and has no AIP-20 counterpart. On Aztec it is not merely absent from the standard but cryptographically impossible for private balances: spending a note requires the owner's nullifier key.

### Access control and supply

| | CMTAT | AIP-20 |
|---|---|---|
| Model | OpenZeppelin `AccessControl`, `bytes32` roles, administered, grantable and revocable | `minter: PublicImmutable<AztecAddress>` |
| Distinct authorities | **15** role constants across the modules — `MINTER_ROLE`, `BURNER_ROLE`, `BURNER_FROM_ROLE`, `BURNER_SELF_ROLE`, `PAUSER_ROLE`, `ENFORCER_ROLE`, `ALLOWLIST_ROLE`, `DEBT_ROLE`, `DEBT_ENGINE_ROLE`, `DOCUMENT_ROLE`, `DOCUMENT_ENGINE_ROLE`, `EXTRA_INFORMATION_ROLE`, `SNAPSHOOTER_ROLE`, `CROSS_CHAIN_ROLE`, `PROXY_UPGRADE_ROLE` | One minter |
| Rotation after key compromise | `revokeRole` + `grantRole` | Not possible — the field is immutable |
| Burn | `burn(account, value)` under `BURNER_ROLE`; `forcedBurn` works on frozen accounts | Holder-authorised |

This is the most easily fixable difference and the one with the clearest answer: an immutable single minter is not adequate for any issuance operation with more than one operator or any key-rotation policy.

### Compliance and restriction

| Capability | CMTAT | AIP-20 |
|---|---|---|
| Pause the whole token | `PauseModule`, plus permanent `deactivate` | — |
| Freeze an address | `EnforcementModule` — blocks send and receive | — |
| Partial freeze of a balance | `ERC20EnforcementModule` | — |
| Transfer restriction | `ValidationModule` + external `RuleEngine`: blacklist, whitelist, sanctions oracle, max balance, max supply, conditional transfer, per-minter quota | — |
| Non-reverting restriction query | ERC-1404 `detectTransferRestriction` | — |
| Allowlist as a first-class deployment | `CMTATStandaloneAllowlist` | — |
| **Extension point for all of the above** | `ValidationModule` + pluggable `RuleEngine`, settable after deployment | **ARC-403 authorization hook** — `auth_contract`, called on every transfer and burn, `PublicImmutable` so fixed at deployment |

**AIP-20 ships no compliance features**, but — unlike what an earlier revision of this document said — it does provide an extension point for them: the ARC-403 hook calls an external contract on every transfer and burn, and that contract may revert.

The hook's limit is its signature: `authorize_private(from, amount, selector)`. **It is not given the recipient.** A hook can therefore refuse a transfer based on the sender, the amount or the operation, but cannot screen who is being paid — and CMTAT's freeze blocks receiving as well as sending, while its whitelist requires both parties to be listed. Mint is not hooked at all.

So the divergence is narrower than "no compliance surface" and sharper than it first appears: the mechanism exists, and one missing argument is what keeps a CMTAT from using it. See [`building-on-aip20.md`](./building-on-aip20.md) for the full analysis.

### Metadata

| | CMTAT | AIP-20 |
|---|---|---|
| Name, symbol, decimals | ✔ | ✔ (`PublicImmutable`) |
| Token identifier (ISIN and similar) | `tokenId` | — |
| Legal terms (name + URI + document hash) | `terms`, ERC-1643 documents | — |
| Free-text information | `information` | — |
| Implementation version | `VersionModule` | — |
| Debt attributes | 16 fields across `DebtIdentifier` and `DebtInstrument` | — |
| Credit events | default, redeemed, rating | — |

For a real-world asset, the metadata is not decoration — the document hash is what ties the token to the instrument it represents. AIP-20 stops at the ERC-20 three.

### Lifecycle and upgradeability

| | CMTAT | AIP-20 |
|---|---|---|
| Upgradeability | Proxy-upgradeable variants (`CMTATUpgradeable*`) alongside standalone ones | `upgrade_authority: PublicImmutable<AztecAddress>` declared in storage |
| Permanent termination | `deactivate` — irreversible, blocks unpause forever | — |
| Deployment variants | Many: Light, Allowlist, Debt, DebtEngine, Snapshot, ERC-7551, Permit, ERC-1363, HolderList | One token contract |

CMTAT's variant catalogue is a direct consequence of its module design: an issuer deploys only what the instrument needs. This repository mirrors that with three Aztec variants.

### Composability

| | CMTAT | AIP-20 |
|---|---|---|
| Designed for DeFi integration | Not a goal; transfer restriction is antithetical to permissionless composition | The central goal |
| Vault pattern | — | AIP-4626 extends AIP-20 with `asset` and `vault_offset` |
| NFT sibling | — | AIP-721, sharing the partial-note pattern |
| Cross-chain | `ERC20CrossChainModule`, `CCIPModule`, LayerZero adapter | — |

## The two irreducible conflicts

Everything above is a difference. These two are conflicts: adopting AIP-20's design would break something CMTAT requires, and no amount of implementation work resolves it.

### Conflict 1 — public balances

AIP-20 defines `public_balances` and hybrid transfer paths between the public and private sides. A CMTAT deployment whose premise is confidentiality cannot expose them.

The tempting answer — "declare them, never use them" — does not survive contact with the ecosystem argument that motivates AIP-20 in the first place. The point of conforming is that wallets and tooling recognise the surface *without prior coordination*. A wallet that recognises AIP-20 will offer a public-transfer action. That means:

- every public transfer path must independently enforce freeze, blacklist and whitelist, duplicating checks that currently live in one private function; and
- the token acquires a second, transparent balance ledger, which is the thing the design exists to avoid.

A compliance surface that is only correct if half of it goes unused is worse than not publishing it.

### Conflict 2 — partial notes and recipient screening

⚠️ **Corrected after reading the source.** An earlier revision of this section said the recipient is "not yet determined" when funds are locked, and concluded that screening it was impossible. That is what the Aztec documentation's prose says, and it is wrong as a statement about the contract. The code is:

```noir
fn initialize_transfer_commitment(to: AztecAddress, completer: AztecAddress) -> Field {
    let commitment = self.internal._initialize_transfer_commitment(to, completer);
    ...
}
// which does:  UintNote::partial(to, self.context, to, completer)
```

**The contract knows the recipient at initialization** and binds the partial note to it. What it does not know at initialization is the *sender* and the *amount*; those arrive later in `transfer_private_to_commitment(from, commitment, amount)`. `PRIVATE_ADDRESS_MAGIC_VALUE` is not a "recipient unknown" sentinel at all — it appears only in the token's **public events**, standing in for whichever party is private so that a public log does not name them.

So the conflict is narrower than first stated, and it is a *timing* conflict rather than an impossibility:

- **Recipient screening can run at initialization.** `initialize_transfer_commitment` is the token's own function; it can refuse to create a commitment for a frozen or unlisted `to`. Every commitment that exists is then one whose recipient passed screening when it was made.
- **Sender screening runs at completion**, in `transfer_private_to_commitment`, exactly as on the direct path.
- **What cannot happen is re-screening the recipient at completion**, because at that point the contract holds only the commitment. If `to` is frozen or delisted *between* initialization and completion, the transfer still completes.

That residual gap is the real conflict, and it has a shape: this implementation already accepts a window between a freeze being scheduled and its taking effect (`CHANGE_ROLES_DELAY_SECONDS`, 360 seconds, documented under *Enforcement* in the assessment). A commitment opens a window of the same kind — but **unbounded**, because nothing in AIP-20 expires a commitment. A commitment initialized in January and completed in June carries January's screening. Closing that needs an expiry on the commitment, or a policy that only a completer the issuer controls may complete — both are additions, not contradictions.

The general statement survives in a weaker form: **restriction wants the counterparty at authorisation time; composability wants to defer the counterparty's *involvement*, not its identity.** AIP-20's design turns out to be compatible with screening as long as the screening is done where the identity is known and the gap between that moment and settlement is bounded. The standard does not bound it today; it could.

## Where they agree

Worth recording, because the disagreements are easier to see:

- **Private balances as note sets.** Both use `Owned<BalanceSet>` over `UintNote` on Aztec — AIP-20 by definition, this implementation by adopting the same aztec-nr library.
- **Public total supply.** Both make it public, and both accept that supply movements are therefore traceable to a transaction.
- **Immutable name, symbol and decimals** as `PublicImmutable`.
- **Holder-authorised spending rather than standing allowances.** AIP-20's per-call validation and CMTAT-on-Aztec's authwits are the same idea, and both differ from the ERC-20 allowance CMTAT Solidity inherits.
- **Deployment-time configuration over runtime discovery.** Neither standard has an interface-detection mechanism.

## Suggestions to improve AIP-20

Framed as extension points rather than features. AIP-20 should not become CMTAT; it should stop making a compliant token impossible to write in a standard way.

### A-1. Pass the recipient to the ARC-403 authorization hook

⚠️ **This suggestion replaces an earlier one.** A previous revision asked AIP-20 to *define* a transfer-restriction extension point. It already has one — the ARC-403 hook — and the earlier text was written from the documentation, which does not mention it. The real gap is narrower and much cheaper to close.

**The gap.** The hook signature is:

```noir
fn authorize_private(from: AztecAddress, amount: u128, selector: Field)
```

There is no `to`. A hook can refuse a transfer based on who is sending, how much, and which operation — but not based on **who is receiving**.

**Why that matters beyond CMTAT.** Checking both parties is not a Swiss peculiarity. ERC-3643, ERC-1404 and CMTAT all screen sender *and* recipient, because the population of addresses permitted to *hold* a regulated instrument is the thing a whitelist exists to define. With sender-only screening, a frozen account can still be paid into, and a whitelist does not constrain who ends up holding the token.

**The suggestion.** Add the recipient to the hook signature, using the placeholder address on the one path where the contract holds only a commitment:

```noir
fn authorize_private(from: AztecAddress, to: AztecAddress, amount: u128, selector: Field)
```

On `transfer_private_to_commitment` the contract holds only the commitment, so `to` would be passed as `PRIVATE_ADDRESS_MAGIC_VALUE` — reusing the standard's own "private party" marker — and a restrictive hook can refuse that path or rely on the screening done at `initialize_transfer_commitment`, which does know `to` and should call the hook too. That single change is the difference between a compliant token being able to *use* AIP-20 and having to fork it.

**Two smaller companions.** Hook `mint_to_*` as well — issuance to a screened population is exactly when screening matters — and make `auth_contract` mutable under an admin rather than `PublicImmutable`, since a compliance policy that can never be corrected without redeploying the token and migrating every holder is not one an issuer can adopt.

### A-2. Settle where screening happens on the partial-note path

**The gap.** Conflict 2 above has no standard answer, so each implementation will pick a different one.

**The suggestion.** State the options and their consequences in the standard, and define at minimum a **completer authorisation** convention: how a token declares which completers it accepts, and whether screening is expected at initialisation, at completion, or both. Even without mandating restriction, naming the decision point would let restricted tokens participate in the ecosystem instead of forking away from it.

### A-3. Replace the immutable single minter with an administered role

**The gap.** `minter: PublicImmutable<AztecAddress>` cannot be rotated, revoked or shared. A compromised minter key means redeploying the token.

**The suggestion.** Specify the minter as an administered authority — at minimum mutable under a declared admin, ideally a small role table. CMTAT's numeric-role approach on Aztec (`role: Field -> AztecAddress -> bool` in public state) is a working precedent and costs one storage map.

**Note the Aztec-specific difficulty**, which is a reason to standardise rather than leave it to implementers: a public role table cannot be read from a private function, so either the role check moves to an enqueued public call — publishing the caller — or the table becomes a delayed value, which makes revocation take effect only after the delay. That trade-off should be decided once, in the standard, not repeatedly and inconsistently.

### A-4. Define an optional pause

**The gap.** AIP-20 has no emergency stop. This is unusual even outside regulated contexts.

**The suggestion.** An optional pause profile. As with A-3, the Aztec-specific difficulty is the reason to standardise it: a `PublicMutable<bool>` pause flag cannot be read privately, so a private transfer must either enqueue a public call to check it — which publishes that a transfer occurred — or read a delayed flag, which means pausing is not immediate. Both are defensible; leaving each implementation to discover the trade-off independently is not.

### A-5. Define an optional metadata extension

**The gap.** Name, symbol and decimals are not enough to identify a real-world instrument.

**The suggestion.** An optional extension covering a token identifier, a terms reference (name, URI, content hash) and an implementation version — the CMTAT `tokenId` / `terms` / `version` triple. Standardising the *shape* means an explorer can display them uniformly instead of special-casing each issuer.

### A-6. Say something about auditability

**The gap.** AIP-20 is silent on how any third party — issuer, auditor, regulator — observes private balances. For a fungible token that is a legitimate omission; for the ecosystem it is a missing conversation, because it determines whether an AIP-20 token can be used in a regulated context at all.

**The suggestion.** Document the available patterns and their guarantees rather than mandating one: additional note delivery to an observer (what this repository does, with the caveat that offchain delivery has no data-availability guarantee), or an on-chain access-control list (what CMTAT-Confidential does under FHE). Naming the trade-off is enough.

## Suggestions to improve CMTAT

CMTAT's assumptions are drawn from account-model, transparent ledgers. AIP-20 is a well-worked example of what changes on a UTXO-style private chain, and several of its ideas generalise.

### C-1. Adopt a note-consumption budget with recursion — this one is measured

**What AIP-20 does.** It caps the notes consumed by a transfer at `INITIAL_TRANSFER_CALL_MAX_NOTES = 2`, and when that is not enough it recurses into itself through `#[only_self]` at up to `RECURSIVE_TRANSFER_CALL_MAX_NOTES = 8`. The rationale given is proving time paid on the user's device.

**What this implementation does instead.** It calls `BalanceSet::sub`, which hardcodes the budget to the whole per-call allowance:

```noir
pub fn sub(self: Self, amount: u128) -> MaybeNoteMessage<UintNote> {
    let subtracted = self.try_sub(amount, MAX_NOTE_HASH_READ_REQUESTS_PER_CALL);  // 16
    ...
}
```

Every transfer therefore sizes its circuit for sixteen notes whether the sender holds one note or sixteen.

**Measured on this repository** (`aztec profile gates`, Aztec 5.2.0), replacing that call with a two-note budget:

| transfer-chain note budget (`tokenModule::debit_private`) | `transfer` gates |
|---|---:|
| 16 (current) | 120,824 |
| 2 (AIP-20's initial budget) | **77,778** |

**43,046 gates — 36% of a transfer.** That is the size of the prize, not the net gain: at a budget of two, a holder whose balance is spread over three or more notes cannot transfer at all, which is why AIP-20 pays for the recursion. Each recursive level is a fresh kernel iteration, on the order of 101,000 gates. So the pattern wins when most transfers settle in one or two notes and loses otherwise — plausible for a security token with infrequent, large transfers, but it should be decided on a measured note-count distribution.

**The suggestion for CMTAT.** Any CMTAT implementation on a UTXO-style ledger faces this, and the guidance should say so: *the number of unspent outputs a transfer consumes is a cost paid by the sender, and an implementation MUST document its bound and its behaviour when the bound is exceeded.* An implementation that silently fails a transfer for a holder with a fragmented balance has a usability defect the criteria currently do not ask about.

### C-2. Name the "this party is private" case in public events

**What AIP-20 does.** `PRIVATE_ADDRESS_MAGIC_VALUE` is a dedicated sentinel that appears in the token's public `Transfer` events wherever one party holds a private balance — `transfer_public_to_private` logs `{ from, to: MAGIC, amount }`, a private mint logs `{ from: zero, to: MAGIC, amount }`. It is explicitly distinct from the zero address, and the documentation notes it lets an indexer recognise a private leg without decrypting anything.

**Why CMTAT should care.** CMTAT Solidity inherits ERC-20's overloading of `address(0)` — "mint source", "burn destination" and "no such account" depending on context. That is tolerable while every party is public; on a ledger with private balances, a public log needs a way to say "there is a counterparty and it is private" that is not the same as "there is no counterparty".

**The suggestion.** Distinct named sentinels for distinct meanings in any public log, and a statement that an implementation MUST NOT reuse the zero address to mean "private party".

### C-3. Treat delivery-versus-payment as a first-class requirement

**The gap.** The CMTA equivalency criteria assume transfers between two known parties. They contain nothing about settling a transfer whose counterparty is determined by an auction, an order book, or any other asynchronous process — which is what an on-chain secondary market is.

**What AIP-20 offers.** The commitment pattern is precisely a delivery-versus-payment primitive: lock, then settle against a result computed elsewhere.

**The suggestion.** Add an optional criterion for deferred settlement, and — because of [Conflict 2](#conflict-2--partial-notes-and-recipient-screening) — require an implementation that supports it to state where transfer restriction is enforced on that path. Without such a criterion, an assessment cannot distinguish a token that cannot be traded on-chain from one that can be traded but does not screen the counterparty. Those are very different instruments and today they receive the same answers.

### C-4. Make the public/private split of each balance an explicit dimension

**What AIP-20 does.** A holder's balance can live publicly or privately, and there are transfer paths between the two.

**Why CMTAT should care.** CMTAT Solidity is entirely public; CMTAT-Confidential and this Aztec implementation are entirely private. AIP-20's per-balance choice is a third position that the criteria do not contemplate, and it is not obviously wrong for a security token — an issuer's own treasury holding might reasonably be public while retail holdings are not.

**The suggestion.** The Privacy and Confidentiality section of the assessment criteria asks *whether* balances are confidential. It could usefully ask *at whose choice, and at what granularity* — issuer-wide, per holder, or per balance.

### C-5. Require batch limits to be documented

**The gap.** CMTAT's `batchMint`, `batchBurn` and `batchTransfer` are bounded only by gas in Solidity. On other ledgers there are hard per-call limits on state effects, so a batch has a maximum size that is a property of the platform rather than of the fee paid.

**Measured example.** In this repository the cap is four addresses per call, established by testing each value rather than derived from the protocol constants: everything passes at 4; at 6 and above a batched transfer aborts with `push out of bounds`. See [Batching limits](../../README.md#batching-limits).

**The suggestion.** Where an implementation offers batch operations, it MUST document the maximum batch size and how it was determined. An integrator sizing a payment run needs the number, and "it depends on gas" is not the answer on every ledger.

## How a project should choose

| If you are building… | Use |
|---|---|
| A fungible token intended for private DeFi on Aztec | AIP-20, unmodified |
| A yield-bearing vault over one | AIP-4626 |
| A tokenised security with transfer restrictions, freezing and an issuer | CMTAT — and accept that it will not be composable with AIP-20 DeFi |
| A tokenised security that must also trade on-chain | Neither, yet. Resolve [Conflict 2](#conflict-2--partial-notes-and-recipient-screening) first, and expect to publish the counterparty or trust a settlement contract |

The middle ground people usually hope for — a CMTAT that is also an AIP-20 token — is not available, and it is better to know that at the design stage than to discover it when the first restriction has to be enforced against a commitment.

## References

- CMTAT — <https://github.com/CMTA/CMTAT> (pinned here at `v3.3.0-rc3`)
- CMTAT Equivalency Assessment Criteria — <https://github.com/CMTA/CMTAT-equivalency-assessment> (template `v0.3.0`); this repository's filled assessment is at [`doc/cmtat-assessment/README.md`](../cmtat-assessment/README.md)
- AIP-20 — <https://docs.aztec.network/developers/docs/aztec-nr/standards/aip-20>
- AIP-721, AIP-4626 — same section of the Aztec documentation
- `aztec-standards` (canonical AIP implementations) — <https://github.com/defi-wonderland/aztec-standards>
- CMTAT-Confidential (the FHE variant compared in `doc/README.md`) — <https://github.com/CMTA/CMTAT-Confidential>
- The gate measurements quoted here are reproduced in [`doc/audits/tools/v0.3.0/CLAUDE_ANALYSIS.md`](../audits/tools/v0.3.0/CLAUDE_ANALYSIS.md), finding `F-1`
