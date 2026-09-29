# CMTAT authorization contracts for the Aztec standards

Two ARC-403 authorization contracts that apply CMTAT's **pause**, **deactivation**, **freeze** and **sender-side blacklist / whitelist** rules to the stock token contracts of the [CMTA fork of `aztec-standards`](https://github.com/CMTA/aztec-standards) (Aztec 5.2.0):

| Contract | Package | Restricts | Hook signature it implements |
|---|---|---|---|
| `CMTATAztecAuth` | `contracts/cmtat-aztec-auth` | AIP-20 `Token` | `authorize_private / authorize_public(from, amount, selector)` |
| `CMTATAztecAuthMultiToken` | `contracts/cmtat-aztec-auth-multitoken` | ARC-1155 `MultiToken` | `authorize_private / authorize_public(from, id, amount, selector)` |

Both are built from the same `cmtat_aztec_lib` modules as the CMTAT token contracts (`AccessControlModule`, `PauseModule`, `Freezable`, `ValidationModule`), expose the same administration entry points, emit the same events and carry the same `version()`. The rules themselves live once, in `lib/src/modules/authorizationHookModule.nr`. There are two contracts rather than one because the two standards give their hook different signatures (the MultiToken hook carries the token `id`) and Noir has no function overloading.

**AIP-721 is not covered**, for a reason outside this repository: the fork's `NFT` contract has no ARC-403 hook, so there is nothing an authorization contract could attach to. See [Adding AIP-721](#adding-aip-721).

This document is both the user-facing description and the record of the design: [CMTAT equivalency of the pair](#cmtat-equivalency-of-the-pair) scores a stock token plus this contract against the mandatory criteria, and [What would close the gaps](#what-would-close-the-gaps) lists the fork changes that would.

## Table of contents

- [What it is](#what-it-is)
- [How it works](#how-it-works)
- [Differences with the CMTAT token contracts](#differences-with-the-cmtat-token-contracts)
- [How to use it](#how-to-use-it)
- [Limitations](#limitations)
- [CMTAT equivalency of the pair](#cmtat-equivalency-of-the-pair)
- [What would close the gaps](#what-would-close-the-gaps)
- [Version](#version)
- [How it was verified](#how-it-was-verified)
- [Adding AIP-721](#adding-aip-721)

## What it is

An AIP-20 `Token` (and an ARC-1155 `MultiToken`) from `aztec-standards` takes an `auth_contract` address at construction. When it is non-zero, the token calls that contract before every transfer and every burn — `authorize_private` from its private entry points, `authorize_public` from its public ones — and a revert in the hook reverts the token operation. That is the whole of ARC-403: the token stays the standard artifact, byte for byte, and the policy lives in a separate contract the issuer administers.

`CMTATAztecAuth` is that separate contract, holding the four CMTAT controls a hook can enforce with the arguments it receives:

- **Pause** (`PAUSE_ROLE`): stops every transfer of every token wired to the contract. Immediate. Burns continue, as in CMTAT Solidity.
- **Deactivation** (`DEFAULT_ADMIN_ROLE`): requires an existing pause, is permanent, and additionally stops burns. The token can never move again.
- **Freeze** (`ENFORCEMENT_ROLE`): stops a given address from sending or burning. Takes effect after the contract's delay setting (`roles_delay()`, one hour initially, adjustable by the admin with `set_roles_delay`), because the flag is a `DelayedPublicMutable` so that the private hook can read it.
- **Blacklist / whitelist** (`VALIDATION_ROLE` to pick the mode, `ADDRESS_LIST_ADD_ROLE` / `ADDRESS_LIST_REMOVE_ROLE` to edit entries): in blacklist mode a listed address cannot send or burn; in whitelist mode only listed addresses can. **Sender-side only** — the hook is never told the recipient, so a listed address can still receive. Same delay setting.

It holds no balances, moves no value, and receives no notes. It only refuses.

## How it works

The token calls the hook from inside its own private function, so the hook runs on the holder's device as part of the same proof; what it can read there is the public state at the anchor block, which is why the freeze and list flags are `DelayedPublicMutable` and the pause is checked by an enqueued public call. The diagrams follow one private transfer and one private burn through the AIP-20 token, then the ARC-1155 variant, then the public entry points. Sources are in [`img/`](./img/); edit the `.puml` and re-run `plantuml -tpng`, never the PNG.

### AIP-20 `Token` and `CMTATAztecAuth`

![Sequence of a private AIP-20 transfer or burn through CMTATAztecAuth: the token calls authorize_private with from, amount and selector; the hook reads the freeze flag and the list entry of from at the anchor block, classifies the selector as burn or transfer, enqueues a public call carrying only is_burn, and the public phase asserts not deactivated for a burn or not paused for a transfer, reverting the whole transaction on refusal](./img/auth-aip20-flow.png)

### ARC-1155 `MultiToken` and `CMTATAztecAuthMultiToken`

The MultiToken hook adds the token `id`. The authorization contract accepts it and ignores it — pause, deactivation, freeze and the lists apply to every id alike — and never forwards it to the public half, so the id stays in the private domain as the standard intends. The burn selectors differ from AIP-20's because the signatures carry the extra `Field`.

![Sequence of a private ARC-1155 transfer or burn through CMTATAztecAuthMultiToken: identical to the AIP-20 flow except that authorize_private also receives the token id, which is ignored and never published, and that the burn selectors are the id-bearing ones](./img/auth-arc1155-flow.png)

### Public entry points

`authorize_public` is called by the tokens' public transfers and burns and runs every rule synchronously against current state; nothing is enqueued.

![Sequence of a public transfer through authorize_public: the token calls the hook in the public phase, the hook reads the freeze flag, the list entry, the pause and deactivation flags from current public state, asserts all of them at once, and either reverts or lets the token move the public balances](./img/auth-public-hook.png)

### The rules, and where they come from

The hook receives `(from, amount, selector)`: the account whose balance is spent, the amount, and the selector of the token function running. It does **not** receive the recipient or the initiator (`msg_sender` of the token call). The rules are therefore the subset of CMTAT Solidity's `ValidationModule` that can be evaluated on `from` alone:

| Token operation | Rule applied | CMTAT Solidity counterpart |
|---|---|---|
| Any transfer (seven AIP-20 entry points, six ARC-1155) | not paused, `from` not frozen, `from` clear of the enabled list | `_canTransferStandardByModule`, minus the `spender` and `to` checks |
| `burn_private`, `burn_public` | not deactivated, `from` not frozen, `from` clear of the enabled list | `_canMintBurnByModule(from)`, allowlist variant |
| `mint_*` | none — the token does not call the hook for mints | `_canMintBurnByModule(to)` cannot be applied |

A deactivated contract is a paused one that can never be unpaused, so a transfer under deactivation fails on the pause check; the transfer rule does not re-check deactivation, which is the shortcut CMTAT Solidity takes in `_canTransferStandardByModuleAndRevert`.

Which rule applies is decided from the selector. Only the two burn selectors of each standard are recognised (`burn_private((Field),u128,Field)` = `0xc282ed79` and `burn_public(...)` = `0xc611b0c5` for AIP-20; `0x3198d2a7` and `0x1d8b2815` for ARC-1155, whose burns carry an `id`). Every other selector — including one from a caller that is not an `aztec-standards` token — gets the stricter transfer rule. The selectors are computed from the signatures at compile time and pinned by a test against the values the fork's `Token::interface()` exposes.

### Why the pause is checked in public

`PauseModule` keeps `is_paused` and `is_deactivated` as `PublicMutable`, which a private function cannot read. The earlier feasibility probe held the pause as a `DelayedPublicMutable` instead, so that the private hook decided everything in private and enqueued nothing. That design was rejected for the CMTAT token contracts under analysis finding `H-3` — a delayed pause takes effect only after the delay, hours by the library's guidance, which is too slow for an emergency lever — and the authorization contract follows the same decision: the pause is immediate, and the private hook pays for it with one enqueued, argument-light public call.

What that call publishes is a single boolean, `is_burn`. A burn is already public through the token's own enqueued supply update; a transfer publishes that *a transfer of a token wired to this authorization contract occurred*, which is exactly what the CMTAT token contracts' argument-less `_transfer()` publishes. `from`, `amount` and the recipient stay in the private half.

## Differences with the CMTAT token contracts

`CMTATAztec` (and its Debt and Light variants) is a token whose compliance is inside the token. `CMTATAztecAuth` is compliance bolted onto a standard token through a hook that sees less. The differences follow from that.

| | CMTAT token contracts (`CMTATAztec*`) | Authorization contracts (`CMTATAztecAuth*`) |
|---|---|---|
| Artifact the holder interacts with | This repository's contract | The unmodified `aztec-standards` token; wallets and vaults that recognise AIP-20 recognise it |
| Recipient screening | Yes — freeze and list checks on `to` for transfers, on `to` for mints | **No** — the hook is never told `to` |
| Initiator screening | `msg_sender` checked where it matters (roles) | **No** — the hook is never told who called the token |
| Mint | `MINTER_ROLE`, recipient screened, blocked by deactivation | Controlled by the token's own single `minter`; the hook is not called |
| Burn | `BURNER_ROLE` on the issuer, or the holder by authwit | Any holder, by the token's rules; the hook blocks frozen accounts and deactivation |
| Blacklist / whitelist | Yes (`ValidationModule`, base and Debt variants), both parties of a transfer, recipient of a mint, account of a burn | Same module, **sender only**: a listed address cannot send or burn but can still receive; mints are not screened at all |
| Issuer audit copies of notes | Every note also delivered to the issuer, plus a constrained `Transfer` event | **None** — the token delivers its notes to holders only; the issuer sees what the standard token publishes |
| Terms, token ID, debt, credit events | Yes | No — metadata modules were left out; the contract is a policy, not a registry |
| Pause / deactivation | Immediate, `PublicMutable`, checked in the enqueued public half | Same modules, same semantics, same enqueued check |
| Freeze | `DelayedPublicMutable`, one-hour initial delay adjustable at runtime, both parties of a transfer | Same module and delay, `from` only |
| Roles | 11 roles | The 6 it uses: `DEFAULT_ADMIN_ROLE`, `PAUSE_ROLE`, `ENFORCEMENT_ROLE`, `VALIDATION_ROLE`, `ADDRESS_LIST_ADD_ROLE`, `ADDRESS_LIST_REMOVE_ROLE` (the constants are shared, so the numbers match) |
| Events | `Transfer` (private) plus public administrative events | The same public administrative events: `NewRole`, `RoleRevoked`, `Paused`, `Unpaused`, `Deactivated`, `AddressFrozen`, `AddressListed`, `OperationsSet` |
| One deployment serves | One token | Any number of tokens: every token constructed with the same `auth_contract` shares its pause, deactivation and freeze state |
| Replaceable | Not upgradeable | Not upgradeable, and the token's `auth_contract` is `PublicImmutable`: changing policy means redeploying the token |
| Cost per private transfer | `transfer_private_to_private` 161,493 gates, one circuit | Token's `transfer_private_to_private` 63,310 + `authorize_private` 14,650 + the cross-contract kernel iteration (~101,000 by the framework's figure, not measured here) |
| `version()` | `0.4.0` | `0.4.0`, kept equal by hand — see [Version](#version) |

[CMTAT equivalency of the pair](#cmtat-equivalency-of-the-pair) scores the design against the CMTAT mandatory criteria; the partials there are the ones the *hook* cannot close.

## How to use it

### Deploy and wire

1. Deploy `CMTATAztecAuth` (artifact `target/cmtat_aztec_auth-CMTATAztecAuth.json`, TypeScript class `src/artifacts/CMTATAztecAuth.ts`) with `constructor(admin)`. `admin` receives `DEFAULT_ADMIN_ROLE` and `VALIDATION_ROLE`, as in the token contracts.
2. Grant the operational roles from `admin`: `grant_role(PAUSE_ROLE, pauser)` (`PAUSE_ROLE = 2`), `grant_role(ENFORCEMENT_ROLE, enforcer)` (`ENFORCEMENT_ROLE = 3`), `grant_role(ADDRESS_LIST_ADD_ROLE, lister)` (`5`) and `ADDRESS_LIST_REMOVE_ROLE` (`6`) if a list will be used.
3. Deploy the `aztec-standards` token with the authorization contract's address as its `auth_contract`: `Token.constructor_with_minter(name, symbol, decimals, minter, auth_contract)` or `constructor_with_initial_supply(..., auth_contract)`; `MultiToken.constructor_with_minter(name, symbol, minter, auth_contract)` for ARC-1155, wired to a `CMTATAztecAuthMultiToken`.
4. Check that the token is connected to it: `Token.get_auth_contract()` returns the address; a transfer while the authorization contract is paused reverts with `Error: contract is paused`.

The pointer is immutable. Decide the authorization contract's address before deploying the token, and keep its admin key with the same care as the token's minter key.

### Operate

| Action | Call | Role | Effect |
|---|---|---|---|
| Pause | `pause_contract()` | `PAUSE_ROLE` | Next block: every transfer of every wired token reverts; burns continue |
| Unpause | `unpause_contract()` | `PAUSE_ROLE` | Next block, unless deactivated |
| Deactivate | `deactivate_contract()` | `DEFAULT_ADMIN_ROLE`, contract already paused | Permanent; burns revert too; `unpause_contract` refuses forever |
| Freeze | `freeze(account, FreezableFlag { is_freezed: true })` | `ENFORCEMENT_ROLE` | After the delay (one hour initially): `account` can neither send nor burn. Emits `AddressFrozen` with `effective_at` |
| Unfreeze | `unfreeze(account, FreezableFlag { is_freezed: false })` | `ENFORCEMENT_ROLE` | After the delay |
| Choose the list mode | `set_operations(SetFlag { operate_blacklist, operate_whitelist })` | `VALIDATION_ROLE` | After the delay; blacklist wins if both are set; neither set means no list check |
| List an address | `add_to_list(account, UserFlags { is_blacklisted, is_whitelisted })` / `remove_from_list(...)` | `ADDRESS_LIST_ADD_ROLE` / `ADDRESS_LIST_REMOVE_ROLE` | After the delay: in blacklist mode a blacklisted `account` cannot send or burn; in whitelist mode only whitelisted accounts can. Emits `AddressListed` with `effective_at` |
| Read | `public_get_pause()`, `public_get_deactivated()`, `get_frozen(account)`, `get_operations()`, `has_role(role, account)`, `version()` | none (`#[view]`) | |

Every state change emits the corresponding public event, so an indexer built for the CMTAT token contracts reads the authorization contract unchanged.

### In the Noir test environment

```noir
let auth = env.deploy("CMTATAztecAuth").with_public_initializer(admin, CMTATAztecAuth::interface().constructor(admin));
let token = env.deploy("@token_contract/Token").with_public_initializer(owner,
    Token::interface().constructor_with_minter(name, symbol, 18, minter, auth));
env.call_public(admin, CMTATAztecAuth::at(auth).grant_role(PAUSE_ROLE, admin));
env.call_public(admin, CMTATAztecAuth::at(auth).pause_contract());
// transfer_private_to_private now fails with "Error: contract is paused"; burn_private still passes
```

The fork's token cannot be compiled from inside this repository (see Trap 3 in [`upgrading-aztec-standards.md`](../technical/upgrading-aztec-standards.md)), which is why the integration test above lives in a copy of the fork rather than in this workspace — see [How it was verified](#how-it-was-verified).

## Limitations

- **The recipient is not screened — by any rule.** A frozen or blacklisted address can still *receive*, and in whitelist mode an unlisted address can receive too. This is the ARC-403 signature, not a choice: `authorize_*` receives `from`, not `to`, and the authorization contract has no way to read the token's call arguments. The CMTAT token contracts check both parties. The fix is a fork change: pass `to` in the hook (zero for the commitment paths), which is the suggestion recorded in [`cmtat-vs-aip20.md`](../technical/cmtat-vs-aip20.md).
- **The initiator is not screened.** A transfer executed by a third party under an authwit is judged on `from` only; CMTAT Solidity also checks the `spender`.
- **Mints are unrestricted by the hook.** The `aztec-standards` mint paths do not call it. Who may mint is decided by the token's single `minter`; a frozen recipient can be minted to, and minting continues after deactivation.
- **AIP-721 cannot be covered** until the fork's `NFT` contract gains a hook — see [Adding AIP-721](#adding-aip-721).
- **Freeze and list changes take the delay to bite**, one hour initially (`roles_delay()`; the admin can change it with `set_roles_delay`, up to the protocol's 24-hour transaction lifetime). Between the scheduling call and `effective_at` the account can still send, and it can see the change coming, since the scheduled flag and the event are public. That is the `DelayedPublicMutable` trade-off the CMTAT token contracts make for the same flags, and the same one: a private hook can only read public state that is guaranteed not to change for the transaction's lifetime. It also means every private transfer of a wired token expires one delay after its anchor block (analysis finding `H-6`).
- **The list is sender-side.** In blacklist mode a listed address is stopped from sending and burning, not from receiving; in whitelist mode the recipient is not required to be listed. An assessment that reads "blacklisted addresses cannot receive" is therefore not met by these contracts, only by the token contracts. One test, `blacklisted_recipient_is_not_screened`, pins this so it is never mistaken for a bug.
- **No issuer audit trail.** The token delivers notes to holders only, and the authorization contract never sees the notes. The issuer's view is the standard token's public surface: total supply, public balances, public transfer events. This is the largest gap against the CMTAT token contracts, whose issuer receives every note.
- **One pause for every wired token.** The state is per authorization contract, not per token. Tokens that must be paused independently need separate deployments.
- **The pointer is immutable.** `auth_contract` is `PublicImmutable` in the token, and the authorization contract is not upgradeable. A policy change is a token redeployment. A router contract (a mutable pointer forwarding to the policy) would restore replaceability at the cost of a second cross-contract call per transfer.
- **Selector dependence.** Burns are recognised by selector. A fork that renames or re-types `burn_private` / `burn_public` would have its burns treated as transfers — blocked by a pause rather than only by deactivation — until the constants in `authorizationHookModule.nr` are updated. The pinned test catches the mismatch at the next test run, not at deployment.
- **The caller is not restricted.** Any contract may call `authorize_*`; the calls only assert and enqueue a check on the authorization contract's own state, so an unrelated caller can neither change state nor learn anything it could not read publicly.
- **Privacy.** The private hook enqueues one public call carrying `is_burn`. An observer learns that a transfer of a token wired to this contract happened in this transaction — the same disclosure the CMTAT token contracts make — and nothing about the parties or the amount. A design that enqueues nothing exists (delayed pause) and was rejected for the reason given above.

## CMTAT equivalency of the pair

Against the 19 mandatory criteria of the [CMTAT equivalency assessment](../cmtat-assessment/README.md), for a stock `aztec-standards` token plus `CMTATAztecAuth`, as built:

| # | Criterion | Answer | Why |
|---|---|---|---|
| 1 | Name attribute | ✔ | Token |
| 2 | Legally required documentation | **✘** | Neither the token nor the authorization contract carries terms. The authorization contract could host them (same `ExtraInformation` module as the token contracts, reached through `get_auth_contract()`); on the token itself it is a fork change |
| 3 | Decimals | ✔ | Token |
| 7 | Know total supply | ✔ | Token |
| 8 | Know balance | **partial** | Holder: `balance_of_private`. Issuer: no note copies; only what the token publishes |
| 9 | Transfer | ✔ | Token, screened on the sender |
| 10 | Create tokens | ✔ with caveat | Token's single immutable minter; not hooked, not role-based |
| 11 | Cancel tokens | **partial** | Holder self-redemption cannot be prevented; issuer-only burn is not expressible |
| 14–16 | Pause, unpause, status | ✔ | Authorization contract; immediate |
| 17–18 | Deactivate, status | ✔ | Authorization contract; permanent |
| 19 | Freeze | **partial** | Sender only; a frozen account can still receive |
| 20 | Unfreeze | ✔ | Symmetric with 19 |
| 21 | Know frozen status | ✔ | Authorization contract |
| 29–31 | Grant, revoke, role attribution | **partial** | Roles exist and administer the authorization contract, but cannot gate the token's mint or burn |

One mandatory `✘` (terms, fixable on the authorization contract without any fork change) and four `partial`s that are the same fact told four ways: the hook does not know the recipient or the initiator, and does not see the notes. An assessor should read the partials, not the count. The sender-side lists change none of these rows: criterion 19 and the list criteria (22–28) are answered on the sender only.

## What would close the gaps

Four changes to the fork's ARC-403 hook, in order of impact. Together they would turn the pair from "a weaker CMTAT" into "a CMTAT", and they are what this project should propose to `aztec-standards`:

1. **Pass the recipient.** `authorize_private(from, to, amount, selector)`, with `PRIVATE_ADDRESS_MAGIC_VALUE` (or zero) on the commitment paths. Closes criterion 19 fully and makes the whitelist meaningful.
2. **Pass the initiator.** The account the token saw as `msg_sender()`. Closes 11 and 29–31: role-gated mint and burn become expressible.
3. **Hook the mint paths.** Closes the `mint_to_public` / `mint_to_commitment` hole and lets the authorization contract gate issuance and screen the minted-to address.
4. **Make `auth_contract` mutable under an admin.** So a policy can be corrected without redeploying the token and migrating holders.

None of these is exotic: ERC-3643's compliance hook receives sender, recipient and amount; ERC-1404 checks both parties; CMTAT's own `RuleEngine` receives `from`, `to`, `value` and the spender. AIP-20's hook is the outlier, by omission rather than by decision.

The audit-trail gap (criterion 8) is the one thing no hook change fixes: only the token can copy notes to an observer. That is a separate proposal — an optional observer delivery in AIP-20 itself — and the same auditability conversation [`cmtat-vs-aip20.md`](../technical/cmtat-vs-aip20.md) already suggests for the standard.

## Version

`version()` returns the constant `VERSION` of the contract, `0.4.0` today. It is **kept equal to the CMTAT token contracts' `VERSION`** for now: the authorization contracts ship with the token release they are built and tested against, and the pre-release checklist in `CHANGELOG.md` bumps the five constants together. Should the authorization contracts start to evolve on their own cadence, give them their own line in the checklist and their own number.

## How it was verified

- **Unit tests** in each crate (`aztec test --package cmtat_aztec_auth_test`: 38; `cmtat_aztec_auth_multitoken_test`: 37 — the tests live in `tests/cmtat-aztec-auth*/`, not in the contract crates) call the hooks directly with the token's selectors: transfers and burns pass by default; a pause stops transfers, private and public, and not burns; deactivation stops burns and keeps transfers stopped; a frozen `from` is refused everywhere after the delay and not before, sends again one delay after `unfreeze`, and an unfreeze of an address that is not frozen is refused; a blacklisted sender is refused in both modes of call and a whitelist refuses unlisted senders, both only after the delay and only once a mode is enabled, and `remove_from_list` lifts the refusal one delay later and needs `ADDRESS_LIST_REMOVE_ROLE`; other addresses, and recipients, are unaffected; the administrative surface (roles, flags, version) behaves as in the CMTAT token contracts. One test pins the four burn selectors to their values.
- **Integration against the real tokens**, in a copy of the fork at `5433e9c` with the two crates and the library added to its workspace: nine tests deploy `CMTATAztecAuth` / `CMTATAztecAuthMultiToken`, construct a `Token` / `MultiToken` with it as `auth_contract`, mint privately, and check that `transfer_private_to_private`, `transfer_public_to_public` and `burn_private` react as the rules say, that a frozen or blacklisted sender is refused after the delay, and that `Token::at(..).burn_private(..).selector` equals the pinned constant. 10/10. The copy is needed because of the nested-workspace trap; the test source is reproduced in [`integration-test.md`](./integration-test.md) so it can be re-run after a fork bump.
- **Gate count**: `authorize_private` is 14,650 gates in both contracts (`aztec profile gates ./target`): 8,447 for pause, deactivation and freeze, and 6,203 more for the list check (a second `DelayedPublicMutable` read of the operations flag plus the per-address entry). The feasibility probe, which also ran the recipient list check, measured 20,715.
- The CMTAT token contracts are untouched: 89/89 tests, unchanged artifacts.

## Adding AIP-721

The fork's `NFT` contract (`src/nft_contract`) has no `auth_contract` field and no `_call_auth_*` helpers; its transfers and burns call nothing outside the contract. Restricting it therefore needs a change to the fork first, and there are two ways to make that change:

1. **Give the NFT the ARC-1155 hook signature**, `authorize_*(from, id, amount, selector)` with `id = token_id` and `amount = 1`, mirroring the MultiToken's `_call_auth_private` / `_call_auth_public` at every transfer and burn. `CMTATAztecAuthMultiToken` would then serve NFTs too, with one addition: its burn-selector list must also contain the NFT's `burn_private((Field),Field,Field)` and `burn_public((Field),Field,Field)`, otherwise an NFT burn is classified as a transfer and stopped by a pause. That is a two-line change to `BURN_SELECTORS` (from `[Field; 2]` to `[Field; 4]`).
2. **Give the NFT its own hook signature**, `authorize_*(from, token_id, selector)`, and add a third contract, `CMTATAztecAuthNFT`, generated from the same module as the other two.

Option 1 keeps one policy contract for both fungible-by-id and non-fungible tokens; option 2 keeps the NFT interface minimal. Either is a fork pull request rather than a change here, which is why it is recorded as a limitation and not done.
