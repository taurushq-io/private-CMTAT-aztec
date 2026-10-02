# A second payment into the same commitment (K-6)

> **Status (2026-09-17): option 2 applied.** Finding `K-6` of the [0.4.0 review](../audits/tools/v0.4.0/CLAUDE_ANALYSIS.md). `pay_commitment` in `lib/src/modules/tokenModule.nr` now pushes `commitment_paid_nullifier(C) = H(C, DOM_SEP__CMTAT_COMMITMENT_PAID)` after the completion, in all three variants; a second payment into the same commitment is a duplicate nullifier and never lands. Verified: `a_second_payment_into_the_same_commitment_is_refused` and `a_sender_opened_commitment_cannot_be_paid_twice_either` (`Nullifier collision`), `the_first_payment_into_a_commitment_is_received` (balances unchanged for the happy path); both refusal tests fail when the `push_nullifier_unsafe` line is removed; gates +52 on `transfer_private_to_commitment` (93,011 → 93,063 base and Debt, 86,812 → 86,864 Light); suite 218/218. The text below is the analysis as it stood before the change, kept as the record of the decision; the measured "lost" behaviour it describes is what the contract did **before** this commit and what AIP-20 still does.

A design note on one property of the commitment flow that the private/public bridges inherited from AIP-20: a commitment can be paid into more than once, and the recipient's wallet sees only the first payment. What happens, exactly, in CMTAT-Aztec and in the AIP-20 reference; what the earlier assessment got right and what it did not; and the ways the project could respond, from doing nothing to a one-line contract change.

## Table of contents

- [The commitment flow in one page](#the-commitment-flow-in-one-page)
- [What happens on a second payment](#what-happens-on-a-second-payment)
- [CMTAT-Aztec and AIP-20 side by side](#cmtat-aztec-and-aip-20-side-by-side)
- [Consequences specific to a security token](#consequences-specific-to-a-security-token)
- [Checking the earlier assessment](#checking-the-earlier-assessment)
- [Upstream status](#upstream-status)
- [Options](#options)
- [Comparison](#comparison)
- [Recommendation](#recommendation)
- [Verification plan](#verification-plan)
- [FAQ](#faq)

## The commitment flow in one page

A **partial note** is a `UintNote` whose private part — owner and randomness — is fixed first, and whose value is filled in later by someone else. `UintNote::partial(owner, context, recipient, completer)` (aztec-nr v5.2.0, `uint_note.nr`) does three things:

1. computes the **commitment** `C = H(owner, randomness)` — the only thing the payer ever sees;
2. sends the recipient a private message so its PXE registers the partial note as *pending*, keyed by `C`;
3. pushes a **validity commitment** `V = H(C, completer)` to the nullifier tree — a proof, readable by anyone, that *this contract* created *this* partial note for *this* completer.

Completion — `PartialUintNote::complete` in public or `complete_from_private` in private — checks that `V` **exists** (it does not consume it), emits a log tagged `T = H(C, DOM_SEP__NOTE_COMPLETION_LOG_TAG)` whose payload is `[storage_slot, value]` in clear, and pushes the note hash `H(slot, [C, value])`. The recipient's PXE finds the log by the tag `T`, pairs it with the pending partial note, and now holds a spendable `UintNote`.

In this repository the flow is reached through three entry points, present in all three token variants behind the `public_side_enabled` flag:

| Entry point | Who calls | What it does with the commitment |
|---|---|---|
| `initialize_transfer_commitment(to, completer) -> C` | the recipient, or anyone on its behalf | opens the partial note for `to`, completable by `completer`; screens `to` (`Screening::recipient`); emits `CommitmentInitialized { to, completer, C }` constrained to the issuer |
| `transfer_private_to_commitment(from, C, amount, nonce)` | the completer | screens `from`, spends its notes (issuer gets the change-note copy), completes `C` with `amount` **from private** (`complete_from_private`), enqueues the argument-less `_transfer` pause check |
| `transfer_private_to_public_with_commitment(from, to, amount, nonce) -> C` | the sender | a private→public transfer to `to` **plus** a fresh commitment for `to` that the sender may later complete |

The shared code is `open_commitment` / `pay_commitment` in `lib/src/modules/tokenModule.nr` and `initialize_commitment` / `complete_commitment` in `lib/src/modules/hybridModule.nr` (MIT-only, derived from AIP-20).

## What happens on a second payment

Nothing in the library or in either contract records that a commitment has been completed. The completion check is *existence* of `V`, and `V` stays in the nullifier tree forever. So a second `transfer_private_to_commitment(from, C, amount', nonce')` by the same completer is a perfectly valid transaction:

- `from` is debited `amount'` a second time — other notes than the first payment's, so no note is spent twice (see the FAQ);
- a second completion log with the **same tag** `T` is emitted, payload `[slot, amount']`;
- a second note hash `H(slot, [C, amount'])` is inserted — a distinct leaf even for `amount' = amount`, because the protocol makes leaves unique with a per-transaction nonce;
- `total_supply` does not move — it is a transfer, not a mint or burn.

On the recipient's side the aztec docs are explicit (`partial_notes.md`, *Single-use semantics*): the PXE "treats the partial note as pending until the first matching completion log is found. After the first match, the pending entry is removed. A second completion against the same commitment may not be discovered". The TXE behaves the same way. Measured in `test_edge_cases.nr`:

| | Before | After two payments of 100 |
|---|---:|---:|
| Sender's private balance | 1,000 | **800** |
| Recipient's private balance | 0 | **100** |
| `total_supply` | 1,000 | 1,000 |

One hundred units are in the note tree, owned by the recipient, and visible to no wallet.

Two things the library documents alongside the discovery loss:

- **Linkability.** Both completion logs carry the same tag `T`; anyone watching the log stream learns that two payments went to the same partial note, hence the same recipient. `UintNote::partial` says so: "Each partial note should only be used once, since otherwise multiple notes would be linked together and known to belong to the same owner."
- **Recoverability, in principle.** The lost note's preimage is fully known to the recipient: owner and randomness from its own partial note, slot and value from the public log, the nonce from the transaction. A PXE that re-adds the note by hand would make it spendable. No wallet flow does this today, and the docs' own wording is "most likely lost". Operationally: lost.

## CMTAT-Aztec and AIP-20 side by side

The AIP-20 `Token` of the [CMTA fork of `aztec-standards`](https://github.com/CMTA/aztec-standards) (`5433e9c`, `src/token_contract/src/main.nr`) has the same three entry points plus two public ones, `transfer_public_to_commitment` and `mint_to_commitment`, which complete in public through `_increase_commitment_balance` → `PartialUintNote::complete`. None of the five records a completion; the check is the library's existence check in every case. Its test suite (79 tests) has no reuse case — the behaviour is documented in aztec-nr and in the Aztec docs, not asserted by the standard.

| | CMTAT-Aztec 0.4.0 | AIP-20 `Token` (fork) |
|---|---|---|
| Completion context | private only (`complete_from_private`) | private (`transfer_private_to_commitment`) and public (`transfer_public_to_commitment`, `mint_to_commitment`) |
| Reuse guard | none — **now: `commitment_paid_nullifier(C)` pushed at completion** | none |
| Second payment: sender | debited | debited |
| Second payment: recipient | first payment only (PXE) — **now: the second payment is refused (option 2)** | first payment only (PXE) |
| Second payment: supply | unchanged | unchanged for transfers; **`mint_to_commitment` twice inflates `total_supply` by an amount no one can spend** |
| Log tag | `T = H(C, …)`, identical on both completions | same |
| Who knows `C` | recipient, completer, and the **issuer** (`CommitmentInitialized`) | recipient and completer |
| Recipient screened | at opening (`initialize_transfer_commitment`) | not applicable (the hook screens `from`) |
| What a wallet is told | README: one commitment per expected payment | Aztec docs: "treat each partial note as a one-shot object" |

The behaviours are identical on the transfer paths because the code is: `pay_commitment` is a screened `debit_private` followed by the same `complete_from_private` call the reference makes. CMTAT-Aztec did not import AIP-20's public completion paths, so the supply-inflating variant (`mint_to_commitment` twice) does not exist here.

## Consequences specific to a security token

For a payment token the loss is the payer's problem and the docs' one-shot rule is the answer. CMTAT is a security token with an issuer that audits every movement, and two further things go wrong:

1. **The audit trail and the holder's wallet disagree.** The issuer knows `C` from `CommitmentInitialized`, derives `T`, and reads *both* completion logs — it books 200 for the recipient. The recipient's wallet holds 100. `total_supply` says 1,000; the sum of what every wallet can spend is 900. Nothing on chain is inconsistent — the second note exists — but every off-chain view is, and an issuer reconciling positions (a register of holders, a corporate action, a redemption) has a discrepancy it cannot resolve from chain data alone.
2. **The loss is not the payer's alone.** With `transfer_private_to_public_with_commitment` the *sender* opens the commitment and is its completer: a sender that later pays into it twice is out of pocket for a payment no wallet received — its own mistake, its own loss (how that happens: see the FAQ). With `initialize_transfer_commitment` the *recipient* opens the commitment and hands `C` to a payer; a careless or malicious payer who pays twice hurts the recipient's reconciliation (and the second amount is still the payer's loss). A frozen or blacklisted recipient cannot be reached this way — the recipient was screened at opening, and a second completion changes nothing about who owns the note — so this is an operational hazard, not a compliance bypass.

There is also a small privacy point: a security-token issuer that publishes nothing about its holders still leaks, on a reuse, that two payments went to one holder (shared tag `T`). The first payment already leaks that *a* completion happened; the reuse adds the link.

## Checking the earlier assessment

The review recorded K-6 with three claims. Checked against the library and the fork:

| Claim in the review | Verdict |
|---|---|
| "Inherited from `PartialUintNote::complete`" — the behaviour is the library's | **Correct**, with a precision: CMTAT-Aztec completes through `complete_from_private`, whose validity check is `assert_nullifier_exists(for_settled(V))`; the public `complete` uses `nullifier_exists_unsafe`. Both are existence checks; neither consumes `V`. |
| "AIP-20 has the same behaviour" | **Correct by code reading** — same library call, no guard in any of its five completion paths. Not demonstrated by a test in the fork; the fork cannot be built in place (see `doc/technical/upgrading-aztec-standards.md`, trap 3), and the Aztec docs make the same statement about AIP-20 directly. |
| "The contract could refuse it — the public half pushes a nullifier of the commitment" | **Wrong place.** The completion is in the *private* half; the enqueued `_transfer` deliberately takes no arguments, and passing `C` to it would publish the commitment in the public call's arguments. The nullifier belongs in the private chain (`pay_commitment`), where `UintNote::partial` itself pushes `V`. Corrected in the README and the review. |
| "100 units are no one's, yet still counted in supply" | **Imprecise.** They are the recipient's — owner and randomness are the recipient's — and unknown to its wallet. Supply is right; the wallets are wrong. This matters for the options below: the funds are recoverable in principle, not burned. |

One thing the review did not say and should have: `initialize_transfer_commitment` lets *anyone* open a commitment for any `to` (the recipient is screened, the caller is not, exactly as in AIP-20). Combined with reuse this does not create a new attack — the opener chooses the completer, and only the completer can pay — but it is why option 5 below (letting the recipient close a commitment) has to be authorised by `to`, not by the opener.

## Upstream status

Checked on 2026-09-17 against the public repositories, to answer whether AIP-20 or the library has since closed the gap. Neither has, and the library's tracker says why.

| Where | What was found |
|---|---|
| `aztec-nr`, default branch (`ac66bffc6e47a97843b0a2d854294b8560d8c1a7`) | `PartialUintNote::complete` and `complete_from_private` still push no nullifier at completion. The docstring still reads: "WARNING: completion is not single-use. Nothing prevents the completer from completing the same partial note multiple times, inserting a new note hash each time." Same behaviour as the v5.2.0 this repository pins. |
| `aztec-packages` issue [#14363](https://github.com/AztecProtocol/aztec-packages/issues/14363), *Restrict sender that can complete partial note* | **Closed.** This is the validity commitment `H(C, completer)`: only the designated completer can complete. It bounds *who*, not *how many times*. |
| `aztec-packages` issue [#14364](https://github.com/AztecProtocol/aztec-packages/issues/14364), *Assume partial notes will get a single completion log* | **Open** since 2025-05-16, milestone "Fairies Q2", no linked PR. The proposal is the opposite of a library fix: rely on #14363 *plus* "senders enforc[ing] logic that prevents ever doing multiple completion", so that the PXE can stop tracking a partial note after its first completion log **and the library never has to emit a completion nullifier** ("if the combination of #14363 and proper contract logic prevent multi-completion, then we don't need to emit a note completion nullifier (saving DA)"). |
| `defi-wonderland/aztec-standards`, `main` (`token_contract/src/main.nr` last changed 2026-07-06, commit `08fe2371ea6ee518f9b9680ba8727c89965366bf`, the ARC-403 work) | `transfer_private_to_commitment`, `transfer_public_to_commitment` and `mint_to_commitment` complete through the same two library calls with no nullifier, no map and no comment on single use. The CMTA fork this repository builds against is the same token code, so nothing was missed by pinning it. |

Two conclusions for the options below:

- **Option 4 is not going to happen in the library, by design.** The framework's position, on record in #14364, is that the PXE will assume one completion per partial note and that *the contract* is responsible for making that true; the DA saved by not emitting a completion nullifier is the stated reason. An upstream issue asking for `complete_once` would be asking the maintainers to reverse that decision.
- **Option 2 is what upstream expects a contract to do.** "Contract logic that prevents multi-completion" is exactly one nullifier derived from the commitment, pushed where the completion happens. AIP-20 has not written it; a token that does is ahead of the standard, not at odds with it, and stays compatible with whatever the PXE does once #14364 lands (a wallet that stops watching after the first completion loses nothing if a second one cannot exist).

## Options

### 1. Keep the behaviour; state the rule

What the repository does today. The README's bridge section carries the wallet rule (one commitment per expected payment; never republish a consumed commitment), the test pins the behaviour so it cannot change silently, and the review carries K-6 as an open decision.

- **Cost:** none in gates or code.
- **Fits:** exactly AIP-20's semantics — a wallet written for the standard sees no difference.
- **Leaves:** the reconciliation discrepancy in the issuer's hands; the loss depends on every wallet following a rule the contract does not enforce.

### 2. Nullify the commitment at completion, in private

In `pay_commitment`, after `complete_commitment`, push one nullifier derived from the commitment under a CMTAT-specific domain separator: `context.push_nullifier_unsafe(H(C, DOM_SEP_CMTAT_COMMITMENT_COMPLETED))`. A second completion emits the same nullifier and the transaction is **invalid**, refused by the node before inclusion — the payer's funds never move.

- **Cost:** one nullifier per completion (`MAX_NULLIFIERS_PER_CALL = 16`, and the review's K-7 shows the side-effect budget is what binds a transfer — the ceiling of `transfer_private_to_commitment` may drop by one note; to be measured). No storage change, no ABI change, no public argument.
- **Privacy:** the nullifier is `H(C, sep)`; without `C` it is unlinkable to the tag `T = H(C, sep')`. Nothing new is published.
- **Failure mode:** a duplicate nullifier is not a revert with a message. The payer's PXE simulation passes (it does not check the nullifier tree for the *new* nullifier) and the node drops the transaction; in the TXE this surfaces as `Nullifier collision`, the same signature as an authwit replay. A wallet gets "transaction rejected" rather than "commitment already paid". A `#[utility] fn is_commitment_paid(C) -> bool` reading the nullifier through the PXE oracle would let a wallet pre-check.
- **Departure from AIP-20:** a second payment fails instead of vanishing. `transfer_private_to_commitment` keeps AIP-20's name and parameter types (the bridges are outside the *pinned* private profile, but the selector is the same by construction), so a caller written for the standard meets a stricter contract, never a laxer one. It is also the behaviour the framework asks contracts for (#14364), so the departure is from the standard's *code*, not from the protocol's intent.
- **Does not fix:** a completion that already happened twice on an existing deployment — there is none; the bridges are new in 0.4.0.

### 3. Record completed commitments in public state

Give the enqueued half the commitment — `_transfer_commitment(C)` — and keep a `Map<Field, bool>` of completed commitments; assert not set, then set. A second payment reverts in public with a message a wallet can show.

- **Cost:** one public storage read and write per completion; a new public entry point; a new storage variable (slot layout of every variant changes — a MAJOR bump under the project's own semver policy unless placed last).
- **Privacy:** **publishes `C`** in the arguments of a public call, per completion. Anyone who has seen `C` — a payer, a lookup channel — can link the payment to it; anyone else learns nothing about the parties but sees one more field than today. This is the leak option 2 avoids, and it is why the review's "public half" phrasing was wrong.
- **Failure mode:** the best of the four — a named revert (`"Commitment already paid"`).

### 4. Ask upstream for a single-use completion

`PartialUintNote::complete` / `complete_from_private` could push the completion nullifier themselves — a `complete_once` pair, or a flag — so every AIP-20 token gets the guard. aztec-nr already pushes `V` at creation; pushing `H(C, sep)` at completion is the symmetric operation.

- **Cost to this repository:** nothing until it lands; then option 2 collapses into a library call.
- **Status:** declined in advance. Issue #14364 (see [Upstream status](#upstream-status)) places the single-completion guarantee on contract logic precisely so the library does not spend a nullifier per completion. An issue would be a request to reverse that, with the DA cost as the counter-argument.
- **What remains useful upstream:** a request to AIP-20 (`aztec-standards`), not to the library, to add the guard in the token; and, once #14364 is implemented, a PXE that stops tracking after the first completion will make the second payment *silently* lost rather than merely undiscovered, which raises the stakes for tokens that have not added it.

### 5. Let the recipient close a commitment

An entry point `close_commitment(C)` callable by `to` (the owner encoded in `C`) that pushes the same nullifier as option 2 without paying. Useful on its own for a recipient that has published a commitment and wants it retired — the *expiry* discussed under F-1 by another route — and as the recovery for a lookup channel that cannot be pruned in time.

- **Cost:** one nullifier, one private entry point per variant, and the authorisation problem: the contract cannot check that the caller is `to` without the recipient proving knowledge of `randomness` (the preimage of `C`) — a small circuit, but new code that AIP-20 does not have.
- **Fits:** only together with option 2 (the same nullifier), as a complement, not an alternative.

### 6. Fix it in the wallet layer

The loss is a PXE property. A PXE that kept the partial note pending after the first match, or that let a user re-add a note from its known preimage, would recover the funds. The linkability leak would remain.

- **Cost to this repository:** none; **control:** none. Worth knowing because it changes how "lost" the funds are — recoverable by a determined recipient with a custom PXE — and because it is the only route that recovers a payment already made.

### 7. Issuer-side monitoring, today

Independent of the above: the issuer already holds every `C` through `CommitmentInitialized`, so it can derive every `T` and watch the log stream for a tag that appears twice. That flags a reuse on the day it happens, names the holder concerned, and costs nothing on chain. It does not prevent the loss, but it closes the reconciliation gap of consequence 1 above, which is the part specific to a security token.

## Comparison

| Option | Second payment | Payer's funds | Gates / side effects | Layout / ABI | Publishes `C` | Departs from AIP-20 | Effort |
|---|---|---|---|---|---|---|---|
| 1. Document only | lost to wallets | debited | — | — | no | no | done |
| 2. Private nullifier | tx invalid | untouched | +1 nullifier | none | no | stricter | ~10 lines + tests |
| 3. Public map | named revert | untouched | +1 public read/write, new entry point | new slot, new public fn | **yes** | stricter | ~40 lines + tests, MAJOR if slot moves |
| 4. Upstream | depends | depends | as 2 | none | no | no (becomes the standard) | an issue; open-ended |
| 5. Recipient close | as 2 + retire unpaid | untouched | as 2 | new private fn | no | new surface | preimage proof; with 2 only |
| 6. Wallet layer | recovered later | debited | — | — | no | no | out of scope |
| 7. Issuer monitoring | detected, not prevented | debited | — | — | no | no | off-chain tooling |

## Recommendation

Option **2**, with **7** as the operating practice until it ships and after.

The behaviour is a loss of a holder's funds that the contract can prevent for one nullifier, without publishing anything, without touching a storage slot, and without changing the selector or the parameters of any entry point. The price is a failure that surfaces as an invalid transaction rather than a named revert — the same way a replayed authwit fails today, which wallets already handle — and a divergence from AIP-20 in the direction of refusing something the standard lets a payer lose. The K-7 note ceiling of `transfer_private_to_commitment` must be re-measured after the change, because the nullifier budget is the one that binds.

Option 3 buys a better error message with a public commitment and a storage-layout change; the trade is the wrong way round for a token whose whole design keeps the parties out of public state. Option 4 is closed by the framework's own decision (#14364); the useful upstream contribution is to AIP-20, proposing the same nullifier in the standard's token, with this repository's measurement and implementation as the reference. Option 5 is a separate feature — the expiry the F-1 discussion asks for, from the recipient's side — and should be decided with F-1, not here.

If the decision is *not* to change the contract, option 1 stays as it is now, and option 7 becomes a documented issuer duty in the operations section of the README rather than a footnote.

## Verification plan

For option 2:

1. Flip `a_second_payment_into_the_same_commitment_is_lost` into `a_second_payment_into_the_same_commitment_is_refused` with `should_fail_with = "Nullifier collision"`; keep the balances assertion in a first-payment test so the happy path still proves the recipient receives the note.
2. Add the same test for `transfer_private_to_public_with_commitment`'s commitment (the sender is its completer).
3. Re-run the gate profile for `transfer_private_to_commitment` in the three variants (0.4.0 baseline: 93,011 / 93,011 / 86,812) and re-probe its note ceiling the way K-7 was measured (`spend_n_notes`-style helper against the commitment path).
4. Break the change on purpose — remove the `push_nullifier_unsafe` — and watch test 1 fail, per the project's rule for chain changes.
5. Update the README bridge section, `doc/technical/building-on-aip20.md` (behavioural difference from the standard) and the review's K-6 row.

## FAQ

### "`from` is debited a second time" — is that a double spend? Can the completer spend the same tokens twice?

No. A double spend would be one note spent in two transactions, and the protocol excludes it: spending a note pushes its nullifier, and a nullifier can enter the tree once. What the second payment spends is *other* notes — the change note left by the first payment, or any other note `from` holds. The balances in the measured case make it visible: the sender starts with 1,000, pays 100 twice and ends with **800**; each payment took 100 real units out of its balance. Value is conserved on chain — 800 + 100 (the recipient's discovered note) + 100 (the undiscovered one) = 1,000 = `total_supply`. The completer gains nothing from the reuse; it pays twice and the recipient can spend once. The word "again" in the body means "a second time", not "the same notes again".

The one thing that *is* replayable is the call itself. When the caller is `from`, `authwit_nonce` is `0` and `#[authorize_once]` pushes no nullifier — replay protection exists for third-party authorisations, not for an account acting on its own. So nothing in the contract makes `transfer_private_to_commitment(from, C, amount, 0)` idempotent; option 2's nullifier is exactly that missing idempotency, keyed on `C`.

### "CMTAT-Aztec did not import AIP-20's public completion paths" — why not, and how could they be imported?

The two paths are `transfer_public_to_commitment(from, C, amount, nonce)` (public balance → the commitment's note) and `mint_to_commitment(C, amount)` (new supply → the commitment's note). Both are `#[external("public")]` in AIP-20 and complete the partial note **in public** through `PartialUintNote::complete`, which means `C` is an argument of a public call and the completion happens in the AVM.

They were left out in 0.4.0 for three reasons, one per path and one common:

- **Common — the bridge selection was "what a holder needs to enter and leave the public side".** The four bridges imported are the ones a holder with a private balance uses (`transfer_private_to_public`, `transfer_private_to_commitment`, `transfer_private_to_public_with_commitment`) plus the way back (`transfer_public_to_private`). `transfer_public_to_public`, `mint_to_public` and `burn_public` were rejected because a public balance is a landing and departure point, not a second ledger (README, *Private/public bridges*). `transfer_public_to_commitment` sits at the border: a departure from the public side, which the principle allows, into a recipient the sender does not know by address, which is the commitment's purpose. It was not needed for the holder journeys the release covered, and it was not decided against — it simply was not in the set.
- **`mint_to_commitment` — the mint should not be imported.** CMTAT's issuance names its recipient: `mint_to_private(to, amount)` screens `to` and the issuer's copy of the note says who was issued what. A mint into a commitment issues to an address the minter does not see at mint time (only the opening screened it, and only the `CommitmentInitialized` event tells the issuer who it was). For a security token, whose issuer knows every holder, that indirection buys nothing. And it is the path where reuse is worst: a second `mint_to_commitment` on the same `C` **inflates `total_supply`** by an amount no wallet can spend — a supply-integrity error an issuer could commit by a retried transaction. Not before a reuse guard exists, and probably not after.
- **`transfer_public_to_commitment` — could be imported, but not in AIP-20's shape.** CMTAT's `transfer_public_to_private` is already *not* a public function: it is `#[external("private")]`, screens both parties in private, and enqueues `_debit_public(from, amount)`. A CMTAT `transfer_public_to_commitment` would follow the same shape — a private entry point that screens `from` through the `Screening` value, enqueues `_debit_public(from, amount)` and completes the commitment **from private** with `complete_from_private`, exactly as `pay_commitment` does. That keeps `C` out of public arguments (the AIP-20 form publishes it), keeps the completion log private-channel, and lets option 2's nullifier be pushed in the same private context. Cost: one library function in `tokenModule.nr` (`pay_commitment_from_public`, ~10 lines: `screening.sender(from)` then `complete_commitment`), one `#[external("private")]` declaration per variant with the `enqueue_self._debit_public` call, the K-6 nullifier if option 2 is adopted, tests, and a gate profile — the private half would be small (no notes spent) since the debit is public. The only thing it does not get for free is the note-count ceiling question (none: no notes are consumed). Worth importing when a holder with a public balance needs to pay a recipient known only by commitment; until then it is a documented absence.

### "A sender that later pays into it twice" — how would a sender end up paying twice?

The flow in question is `transfer_private_to_public_with_commitment(from, to, amount, nonce) -> C`: the sender moves `amount` to `to`'s **public** balance now and, in the same transaction, opens a commitment for `to` of which the *sender* is the completer. The AIP-20 intent is "deposit now, receive the private output later": the sender interacts with something public (a contract, a venue) and, once the outcome is known, calls `transfer_private_to_commitment(from, C, result, 0)` once so that `to` receives `result` privately. In a plain CMTAT setting `to` is a holder and the second leg is the sender delivering a private amount to `to` without learning anything more about `to` than `C`.

"Twice" is not a deliberate second payment; it is the second leg being executed a second time against the same `C`. Realistic ways:

- **A retry.** The wallet or script sends the completion, does not observe inclusion (timeout, dropped connection, a node behind), and re-sends. With the caller as `from` the nonce is `0` both times, so nothing rejects the second transaction; both are included; `from` is debited twice.
- **A stored commitment reused by habit.** The sender keeps `C` as "the endpoint for `to`" and pays into it on the next occasion, the way one would reuse a bank account number. Every partial note is one-shot; a `C` is not an account.
- **Automation without a completion record.** A contract or a batch job that computes "pay the outcome to `C`" from state that can be re-evaluated (a re-run of the job, a second call to the same contract function) completes once per run.

In each case the sender's second `amount` leaves its balance and lands in a note that is the recipient's by construction (owner and randomness are the recipient's) but that the recipient's wallet never finds. From the sender's point of view it paid for nothing; from the recipient's, nothing arrived; from the issuer's, two payments were made. That is what "out of pocket for a payment no wallet received" means, and why the body treats the `initialize_transfer_commitment` variant as the harder case: there the payer is a third party and the recipient inherits a reconciliation discrepancy it did not cause.
