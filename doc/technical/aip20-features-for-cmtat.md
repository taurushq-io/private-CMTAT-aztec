# AIP-20 features that CMTATAztec could adopt while staying CMTAT-equivalent

The third step of a three-step plan. Step one brings the [`aztec-standards`](https://github.com/defi-wonderland/aztec-standards) fork to Aztec 5.2.0 ([`upgrading-aztec-standards.md`](./upgrading-aztec-standards.md)); step two packages the compliance modules as an ARC-403 authorization contract for a stock AIP-20 token, with its known limits on mint and burn (built: [`doc/auth/README.md`](../auth/README.md)). This document is step three: **which AIP-20 features can be brought into the CMTAT token itself without breaking its equivalence to CMTAT, and in what order.**

> **Status (2026-09-22): four of the seven features are in the code, and the two-product map below is retired.** 0.4.0 did not build the fourth variant this note recommends. It put the AIP-20 features into the **three existing variants** behind the constructor flag `public_side_enabled`, so what the note calls CMTAT-private and CMTAT-private-AIP20 is one product with a deployment switch: with the flag `false` the token is exactly the unqualified private product, and with it `true` the AIP-20 bridges and the public balance exist. The per-feature state is the last column of the summary table and a status block on each section; the reconciliation that drove it is finding **F-1** of the [0.4.0 review](../audits/tools/v0.4.0/CLAUDE_ANALYSIS.md), which carries the same seven rows. What still stands as written — and is the reason to keep this document — is the four-question test, the scoring of each feature against the 61 criteria and the nine-row privacy table, the measured costs, and the two rejections with their grounds.
>
> **One consequence has not been carried through.** Test 2 below says a feature that moves a privacy-table row must be disclosed in the assessment. F2 and the narrow form of F6 both moved rows, and the privacy table in [`doc/cmtat-assessment/README.md`](../cmtat-assessment/README.md) still answers *balance of an address* and *transfer amount* as plain `private`, with no mention of `public_side_enabled`, the bridges or `balance_of_public`. That is an open gap in the assessment, not in this note.

## Table of contents

- [The test each feature has to pass](#the-test-each-feature-has-to-pass)
- [A correction that changes the answer](#a-correction-that-changes-the-answer)
- [Summary table](#summary-table)
- [F1 — Note budget with recursive subtraction](#f1--note-budget-with-recursive-subtraction)
- [F2 — Commitment transfers, screened at initialization](#f2--commitment-transfers-screened-at-initialization)
- [F3 — A rule-engine hook, in the ARC-403 shape but complete](#f3--a-rule-engine-hook-in-the-arc-403-shape-but-complete)
- [F4 — AIP-20 entry-point names](#f4--aip-20-entry-point-names)
- [F5 — The private-party marker in public events](#f5--the-private-party-marker-in-public-events)
- [F6 — Public balances](#f6--public-balances)
- [F7 — Named constructors](#f7--named-constructors)
- [Rejected — features that are not CMTAT-compatible](#rejected--features-that-are-not-cmtat-compatible)
- [Recommended order — superseded by what 0.4.0 did](#recommended-order--superseded-by-what-040-did)
- [What each feature changes in the equivalency assessment](#what-each-feature-changes-in-the-equivalency-assessment)

## The test each feature has to pass

Four questions, asked of every feature:

1. **CMTA equivalency.** Does any of the 61 criteria in [`doc/cmtat-assessment/README.md`](../cmtat-assessment/README.md) regress — in particular any of the 19 mandatory ones? Does any improve? The standard is the *Solidity* CMTAT and the criteria mapped from it; nothing in it names a function or forbids an extra capability, so most features pass this test trivially. The ones that fail are the ones that change *who may do what*.
2. **The CMTA privacy table.** The equivalency assessment carries a *Privacy and Confidentiality* section — outside the count, but the section that makes this a **private** CMTAT rather than merely a CMTAT. It tabulates nine data items and, for each, its visibility in the implementation and whether the issuer can still see it: balance of an address, transfer amount, transfer participants, total supply, decimals, frozen/blacklisted addresses, allowlisted addresses, roles, pause status. Today the first three are `private` and everything else `public`, and the issuer sees all nine. **A feature that moves any row from `private` toward `public`, or takes a row away from the issuer, changes the privacy table and must be disclosed there.** That is the test this section applies.
3. **Which product it belongs in.** Two products are in scope:
   - **CMTAT-private** — the three variants that exist today (`CMTATAztec`, `CMTATAztecDebt`, `CMTATAztecLight`), keeping CMTAT's own names and surface, no AIP-20 entry points.
   - **CMTAT-private-AIP20** — a variant that integrates AIP-20: its entry-point names, its commitment flow, and whatever else from the standard survives the first two tests. Still private by construction; still CMTAT-equivalent.
   A feature can belong in both, in one, or in neither. **This third test is the one the release retired:** there is one product, and the AIP-20 surface is a constructor flag on it, so where a feature scored "AIP20 variant only" the question became "on which side of `public_side_enabled`". Tests 1, 2 and 4 are unaffected.
4. **Cost and prerequisites.** Gates, measured where they could be; ABI or storage breaks; what must be true before starting.

Everything measured below was measured on Aztec 5.2.0, on this repository's `CMTATAztec` and on the `aztec-standards` token forked to the same version.

## A correction that changes the answer

The comparison document originally said that commitment transfers cannot be screened because "the recipient is not yet determined when funds are locked". **That is what the Aztec documentation's prose says, and it is wrong about the contract.** The source is:

```noir
fn initialize_transfer_commitment(to: AztecAddress, completer: AztecAddress) -> Field
// → UintNote::partial(to, self.context, to, completer)
```

The recipient is a parameter of initialization and the partial note is bound to it. What the contract does not know until later is the **sender** and the **amount**, which arrive in `transfer_private_to_commitment(from, commitment, amount)`. `PRIVATE_ADDRESS_MAGIC_VALUE` is not a "recipient unknown" sentinel; it appears only in the token's *public* events, standing in for whichever party holds a private balance.

The consequence for this document: **the commitment path is not excluded** — it is a screening-at-initialization design with a timing gap that has to be bounded. That moves F2 from "rejected" to "second priority", and it is the single largest change from the earlier analysis. The comparison document's Conflict 2 has been corrected to match.

## Summary table

The last column is the state of the code; the *Verdict* column is the recommendation this note made on 2026-09-14 and is kept so the divergence is visible.

| # | Feature | CMTA equivalency (61 criteria) | CMTA privacy table (9 rows) | Cost | Verdict (2026-09-14) | **State (2026-09-22)** |
|---|---|---|---|---|---|---|
| F1 | Note budget with recursive subtraction | Neutral | **Unchanged** | **−43,046 gates** per transfer, common case (measured); a recursive kernel iteration when fragmented | Do first, in both | **Done** — A-5: a two-note budget with `_recurse_debit` at eight per call, −42,203 measured |
| F2 | Commitment transfers, screened at initialization | Neutral; enables delivery-versus-payment | **Changes two rows** — *transfer amount* becomes visible-but-unlinked on the commitment path; *issuer availability* holds only with an added delivery | New entry points, one storage field | Second, AIP20 variant only | **Done in all three variants**, behind `public_side_enabled`; additions 2 and 3 met, **addition 1 (the expiry) is not**; plus a single-payment guard the standard does not have (K-6) |
| F3 | Rule-engine hook passing recipient and caller | **Improves** — CMTAT's `RuleEngine`, criteria 26–28 | Unchanged **if the engine runs private**; an engine that enqueues public leaks *transfer participants* | ~101,000 gates per transfer when set, ~0 unset (docs figure) | Third, in both | **Not done** — the *receiving* side was built twice as the [authorization contracts](../auth/README.md); the token still has no settable hook |
| F4 | AIP-20 entry-point names | Neutral | Unchanged | ABI break, five renames; `burn` excluded | AIP20 variant, bundled with F2 | **Done in the three variants themselves**, not in a fourth; `burn` excluded as the trap requires; selectors pinned per variant since K-4 |
| F5 | Private-party marker in public events | Neutral | Unchanged — it is what *keeps* participants private if public events are ever emitted | Trivial | With public events, if ever | **Done** — the bridges' two public `Transfer` emissions carry `PRIVATE_ADDRESS_MAGIC_VALUE`, which is the "if ever" arriving with F2 |
| F6 | Public balances | Neutral — CMTAT Solidity *is* public | **Changes three rows** — *balance*, *transfer amount* and *participants* become `public` on the public side | Every path re-guarded | A fifth, hybrid variant at most | **Partly done, in a narrower form than the one refused** — a public balance as the bridges' endpoint, plus `balance_of_public`, issuer-enabled; `transfer_public_to_public`, `mint_to_public` and `burn_public` stay refused |
| F7 | Named constructors | Neutral | Unchanged | Trivial | AIP20 variant, optional | **Not done** — the single constructor gained `public_side_enabled` instead |
| — | Holder self-burn | **Regresses criterion 11** | — | — | Rejected | **Still rejected** — `burn` keeps `BURNER_ROLE` and its own selector |
| — | Single immutable minter | **Regresses 29–31** | — | — | Rejected | **Still rejected** — minting keeps `MINTER_ROLE` |

The product map this table originally carried — *CMTAT-private gains only F1 and F3; CMTAT-private-AIP20 is CMTAT-private plus F2, F4, F5 and F7* — is **retired**. The release found a third shape the note did not consider: one product in which the AIP-20 surface is a deployment flag rather than a separate contract, and in which F6 appears only as the endpoint of a holder-initiated bridge rather than as a second, transparent ledger. The reasoning that produced the map is still sound; what it missed is that "public balances" is not one feature but two, and only the larger one contradicts the token's premise.

## F1 — Note budget with recursive subtraction

> **Status (2026-09-18): done** in 0.4.0 under review finding A-5 ([`doc/audits/tools/v0.4.0/CLAUDE_ANALYSIS.md`](../audits/tools/v0.4.0/CLAUDE_ANALYSIS.md)): `tokenModule::debit_private` tries 2 notes and the contract recurses through `_recurse_debit` at 8 per call, with AIP-20's constants and scheme credited in the code. `transfer_private_to_private` 161,493 → 119,290 gates, `transfer_private_to_public` 95,941 → 53,737 (AIP-20: 38,277; the rest is the compliance screening).

**What AIP-20 does.** A transfer first tries to settle with at most `INITIAL_TRANSFER_CALL_MAX_NOTES = 2` notes. If the sender's balance is more fragmented than that, the contract recurses into itself through an `#[only_self]` function at `RECURSIVE_TRANSFER_CALL_MAX_NOTES = 8` per level until the amount is covered.

**What this token does.** `BalanceSet::sub` hardcodes its budget to `MAX_NOTE_HASH_READ_REQUESTS_PER_CALL` (16), so every transfer and burn sizes its circuit for sixteen notes regardless of how many the sender holds.

**Equivalency.** Neutral. No criterion mentions note handling. The comparison document's suggestion C-1 proposes that CMTAT *require* the bound be documented — adopting F1 would make this repository the worked example.

**Privacy table.** Unchanged. No data item's visibility moves and the issuer still receives the change note.

**Premise.** Fully compatible. The compliance checks (freeze, lists, issuer read) run once at the entry point before any note is touched; the recursion only consumes notes and neither reads compliance state nor delivers messages. The change note is still produced once, at the end, and delivered to the sender and the issuer exactly as today. The invariant chain is untouched.

**Cost, measured.** Replacing the sixteen-note `sub` in the transfer chain (now `tokenModule::debit_private`) with a two-note budget moved `transfer` from **120,824 to 77,778 gates — 43,046 saved, 36%**, on the proof the sender's device produces. That is the common-case figure. A sender whose balance needs three to eight notes pays a recursive call instead — one extra private kernel iteration, roughly 101,000 gates by the framework's figure — and is worse off than today. So the feature wins if most transfers settle in one or two notes and loses otherwise.

**Prerequisites.**

- **Measure the note-count distribution of realistic holders before choosing the budget.** That number is unknown and it is the whole decision. Two is AIP-20's choice for a DeFi token; a security token with infrequent, large transfers may justify two, or may justify four.
- **Re-measure the batch cap.** `MAX_ADDR_PER_CALL = 4` was established with no nested private calls in a batch. Recursion *is* a nested private call, and the protocol allows eight per call; four recipients each recursing once is four, plus whatever the recursion itself nests. The cap may hold or may need to drop, and only a run at each value will say.
- **Interaction with the issuer copy.** The recursive step subtracts and returns change; the delivery of the final change note must remain at the top level, where the issuer address has already been read. Structure the recursion so it never delivers.

**Verdict: do first, in both products.** It is the only feature that pays for itself with no design trade, and its prerequisite is a measurement, not an architecture decision.

## F2 — Commitment transfers, screened at initialization

> **Status (2026-09-22): done in the three token variants, not in a fourth, and with one of the three additions still missing.** Behind `public_side_enabled`, all three carry `initialize_transfer_commitment`, `transfer_private_to_commitment` and `transfer_private_to_public_with_commitment`.
>
> - **Addition 1, the expiry — not done.** A recipient frozen or delisted after opening a commitment can still be paid into it, with no bound on how long the commitment lives. This is the gap the note calls mandatory; it is recorded as a limitation in `doc/README.md`, pinned by the test `a_recipient_frozen_after_opening_a_commitment_is_still_paid`, and carried as one of the two open items of the review's F-1.
> - **Addition 2, the issuer's delivery — met, in event form.** `initialize_transfer_commitment` emits `CommitmentInitialized { to, completer, commitment }` to the issuer with `onchain_constrained` delivery, rather than a second copy of the partial note; that is half the 39,820 gates the entry point costs (review row A-6). The completed note itself has no issuer copy, which is review row C-8: the issuer's record is the event plus the commitment-tagged completion log.
> - **Addition 3, the unencrypted amount — met as a disclosure.** `doc/README.md`'s bridge table states it per entry point, and the review carries it as H-9.
> - **One thing the note did not ask for and the code has:** `pay_commitment` pushes `commitment_paid_nullifier(C)`, so a commitment can be paid **exactly once** — a deliberate divergence from AIP-20, whose `complete` is not single-use. The reasoning is in [`commitment-reuse.md`](./commitment-reuse.md); it cost +52 gates.

**What AIP-20 does.** Three entry points:

| | Knows | Screens (in this design) |
|---|---|---|
| `initialize_transfer_commitment(to, completer)` | the recipient, the permitted completer | **`to`** — freeze and lists |
| `transfer_private_to_commitment(from, commitment, amount, nonce)` | the sender, the amount | **`from`** — freeze and lists; the authwit |
| `mint_to_commitment(commitment, amount)` | the amount | **`MINTER_ROLE`** on the caller |

The commitment is bound to a *completer* — the address permitted to finalize it, checked at completion via a validity commitment in the nullifier tree — which is a control point CMTAT can use.

**What it enables.** Delivery-versus-payment and primary subscription: an investor initializes a commitment (and is screened doing so), the counterparty or the issuer pays into it when the other leg settles. The comparison document's suggestion C-3 records that CMTAT has no criterion for this because account-model ledgers never needed one. It is the capability that would let a CMTAT token trade on-chain.

**Equivalency.** Neutral: no criterion regresses, because every screening the criteria require still runs — on `to` at initialization, on `from` at completion. Criteria 26–27 (conditional transfer) do not become `y`; a commitment is not an approval mechanism.

**Privacy table — two rows change, and this is the reason F2 is confined to the AIP20 variant.**

| Row | Today | On the commitment path |
|---|---|---|
| Transfer amount | `private` — inside an encrypted note | **visible, unlinked** — the completion log carries the value unencrypted; an observer who cannot compute the tag cannot attach it to a recipient, but the number is there |
| Transfer participants | `private` | `private` — the commitment reveals neither party |
| Available to the issuer | `y` | `y` **only with addition 2 below**; without it the issuer never learns of the partial note |

The other seven rows are unchanged. Because the assessment answers *transfer amount* as `private` today, a token that ships F2 must answer it `private on the direct path; visible but unlinked on the commitment path`, and say so in the note. That is a disclosure, not a disqualification — but it is why CMTAT-private, whose value is the unqualified answer, does not get F2.

**Premise — compatible, with three additions that are each mandatory.**

1. **An expiry on the commitment.** The recipient is screened at initialization and cannot be re-screened at completion, because at that point the contract holds only the commitment. If `to` is frozen or delisted in between, the transfer still completes. This token already accepts a bounded window of that kind — `CHANGE_ROLES_DELAY_SECONDS`, documented under *Enforcement* in the assessment — but AIP-20 puts **no bound** on the life of a commitment. A commitment initialized in January and completed in June carries January's screening. The addition is a timestamp in the partial note's public data and an `assert(now < expiry)` at completion. Without it, F2 fails the premise.
2. **A second delivery to the issuer at initialization.** The library's `UintNote::partial` delivers its private log to exactly one `recipient` (`do_private_message_delivery(..., recipient, onchain_unconstrained())`) and returns no message the caller can re-deliver. The token's "issuer receives a copy of every note" rule therefore cannot be met with the library call as it stands. Either the token sends a second, explicit message to the issuer carrying the commitment's preimage, or `partial` is forked to accept a second recipient. Both are small; one of them is required.
3. **Accepting that the completion amount is not encrypted.** `complete_from_private` emits the completion as an *unencrypted* private log — `emit_private_log_unsafe(log_tag, [storage_slot, value])`, per the library's own comment — tagged by the commitment so the recipient can find it. An observer who cannot compute the tag cannot link the log to a recipient, but the **value is visible**. On the direct transfer path the amount is inside an encrypted note; on the commitment path it is not. The README's per-operation privacy requirement — "only the issuer and the receiving address should know the amount" — would have to carve out the commitment path explicitly, and an issuer deciding whether to enable F2 must know this.

**Cost.** New entry points and one storage field for the expiry — an ABI change and a storage-layout change, so it belongs in the same release as any other break. Gates were not measured; the library's `transfer_private_to_commitment` profiles at 41,527 on the fork, and this token would add its compliance reads to that.

**Verdict as written: second, after F1, in CMTAT-private-AIP20 only, and only with all three additions** — the one feature that gives the token something it structurally cannot have, and the one that qualifies a privacy-table answer, which is why the unqualified product was not to carry it. **Overtaken in part:** the feature shipped in the three variants, with the privacy qualification handled by making it opt-in at deployment rather than by a separate contract — a holder of a token deployed with `public_side_enabled = false` still has the unqualified answer. The "only with all three additions" half was **not** honoured: it shipped without the expiry.

## F3 — A rule-engine hook, in the ARC-403 shape but complete

> **Status (2026-09-22): not done, and the one feature of the seven that is still entirely open for the token.** The *receiving* side of this design was built twice in the meantime — `CMTATAztecAuth` and `CMTATAztecAuthMultiToken` are compliance contracts in the ARC-403 shape ([`doc/auth/README.md`](../auth/README.md)) — so the missing piece is only the call from the token's private chain and a `DelayedPublicMutable<AztecAddress>` to hold the engine. Those contracts also confirm the note's premise empirically: their hook runs in private and enqueues exactly one argument-less public call, so an engine that reads delayed state and enqueues nothing is achievable rather than hypothetical. Carried as the second open item of the review's F-1.

**What AIP-20 does.** An `auth_contract: PublicImmutable<AztecAddress>` called on every transfer and burn with `(from, amount, selector)`; zero address disables it.

**What CMTAT does.** `ValidationModuleRuleEngine` — a pluggable, *settable* external `RuleEngine` receiving `from`, `to`, `value` and the spender, behind which the Rules repository supplies whitelist, blacklist, sanctions, max-balance, conditional-transfer and per-minter-quota rules. This token merged the engine into the validation module; the assessment's Restriction table records "RuleEngine / transfer hook — ✘".

**The feature, then, is not AIP-20's hook but CMTAT's own extension point, in ARC-403's calling convention and with its omissions repaired:**

```noir
rule_engine: DelayedPublicMutable<AztecAddress, CHANGE_ROLES_DELAY_SECONDS, Context>,
```

```noir
// in the transfer chain (tokenModule::transfer_private), after the built-in checks
let engine = self.storage.rule_engine.get_current_value();
if !engine.is_zero() {
    self.call(RuleEngine::at(engine).validate_transfer(from, to, amount, self.msg_sender(), selector));
}
```

Passing **`to`** and the **original caller** — the two arguments ARC-403 lacks — is what makes it able to express CMTAT rules. Making it `DelayedPublicMutable` rather than `PublicImmutable` is what makes it a CMTAT rule engine rather than an AIP-20 hook: settable under `VALIDATION_ROLE`, after the delay, readable from private.

**Equivalency — improves.** Restriction table row "RuleEngine / transfer hook" becomes ✔. Criteria 26–28 (conditional transfer, whitelist assignment through an engine) become answerable through an external rule, and the Restriction table's `n` rows for max balance, aggregated whitelists, receiver-only whitelist and per-minter quota become reachable without touching the token.

**Privacy table.** Unchanged provided the engine runs privately. An engine that enqueues a public call to read a `PublicMutable` publishes the sender on every transfer — the *transfer participants* row moves to `public` for the sender — so the extension point must state that an engine MUST NOT enqueue, and the assessment note must say what the deployed engine does.

**Premise.** Compatible provided the engine itself runs privately — reads `DelayedPublicMutable` state and enqueues nothing — which the [authorization contracts](../auth/README.md) demonstrates is achievable. An engine that enqueues a public call publishes the caller; that is the engine author's responsibility and must be documented at the extension point.

**Cost.** When no engine is set: one delayed read and a branch, on the order of the 4,000 gates the first `DelayedPublicMutable` read of a transaction measured at in the code-quality review (about 1,920 for each further read of a different variable, which is what an engine set next to the existing screening reads would cost). When set: a cross-contract private call, roughly **101,000 gates per transfer** by the framework's figure — not measured here — plus the engine's own circuit. That is the price CMTAT Solidity does not pay for its `RuleEngine`, and it should be stated next to the setter.

**Verdict: third, in both products.** It is how CMTAT's own extension model looks on Aztec, and this repository's module library already provides everything an engine needs.

## F4 — AIP-20 entry-point names

> **Done in 0.4.0**, in CMTAT-private itself (it needs no AIP-20 architecture): the five renames are applied, the assessment's implementation-details cells updated, and the selectors pinned by a test.

Covered in detail in [`building-on-aip20.md`](./building-on-aip20.md#interface-alignment--an-aip-20-private-profile). Renaming `transfer`, `mint`, `public_get_name`, `public_get_symbol` and `public_get_decimals` to AIP-20's names makes them answer AIP-20's selectors exactly — verified by computing selectors on both artifacts; parameter names are not part of the selector, so `authwit_nonce` stays. `balance_of_private` and `total_supply` already match.

**Equivalency.** Neutral; no criterion names a function. The assessment's implementation-details cells that name them must be updated.

**Premise.** Compatible.

**Exclusion.** `burn` must not be renamed to `burn_private`: AIP-20's is holder-authorised, CMTAT's requires `BURNER_ROLE`, and an identical selector with different authorisation is a trap.

**Verdict as written: CMTAT-private-AIP20 only, bundled with F2** — on the reasoning that keeping CMTAT's names is part of what makes CMTAT-private the reference product. **Overtaken:** the renames went into the three variants in 0.4.0, before the bridges, because a selector match costs nothing and needs no AIP-20 architecture. What the verdict got right is the packaging: it was one ABI break in one release, with a migration note, alongside F2.

## F5 — The private-party marker in public events

> **Status (2026-09-22): done.** The condition the verdict set — "adopt when public events are added" — arrived with F2's bridges: `transfer_private_to_public` and `transfer_public_to_private` emit a public `Transfer` in which the private side is `PRIVATE_ADDRESS_MAGIC_VALUE` (`main.nr`, the two `HYBRID` emissions), imported from `hybridModule` so the value is the fork's own constant rather than a local re-definition. It is used only as "the private side of this move", never as a zero-address stand-in — checked in review row F-2.

`PRIVATE_ADDRESS_MAGIC_VALUE` in a *public* log wherever one party's balance is private, distinct from the zero address. This token emits its `Transfer` event privately to the recipient, so today nothing needs it. If the open event-coverage items from the code-quality review (C-6) are ever answered with public events, the marker is the right idiom and costs nothing.

**Verdict: adopt when public events are added, not before.**

## F6 — Public balances

**Equivalency — neutral, and worth being precise about why.** CMTAT Solidity's balances are entirely public. Nothing in the criteria requires privacy; the Privacy and Confidentiality section of the assessment sits outside the count. A hybrid token would remain CMTAT-equivalent.

**Privacy table — three rows change.** *Balance of an address* moves from `private` to `private or public, at the holder's choice`; *transfer amount* and *transfer participants* become `public` on every public-side path. That is the largest privacy-table change of any feature here, and it is the reason F6 is excluded from **both** products: each is named *private*, and F6 is the one feature that makes a balance public.

**Premise — contradicts it.** The assumptions in `doc/README.md` are that balances and transfers are private and only supply is public. Adding `public_balances` and the hybrid paths adds a transparent second ledger, and every public path then needs the full invariant chain — freeze, lists, role, pause — re-implemented in public context, doubling the compliance surface to test and audit.

**A narrow form that might be legitimate:** a single issuer-owned public balance — a treasury — rather than public balances for everyone. Even that adds the hybrid paths.

**Verdict as written: in neither product.** If an issuer needs it, it is a separate *hybrid* variant with its own assessment and its own privacy table, not a change to CMTAT-private or CMTAT-private-AIP20 — both of which are named for the property F6 removes. **Overtaken for the narrow form only** — see the refinement below, which shipped; the transparent second ledger this paragraph refuses did not, and is still refused.

> **Refinement (2026-09-14), shipped in 0.4.0.** The four private↔public *bridges* (`transfer_private_to_public`, `transfer_public_to_private` and the two commitment forms) are a narrower thing than a public ledger: per-transfer, initiated by the party whose side becomes visible, and enable-able by the issuer with one deployment flag. [`building-on-aip20.md`](./building-on-aip20.md#the-cross-domain-paths-what-they-are-for-and-offering-them-as-a-holders-choice) works through what each is for and what following them with the compliance chain costs; under an issuer flag they fit the CMTAT-private-AIP20 variant without changing a deployment that leaves the flag off. **Implemented in 0.4.0** in the three variants themselves, behind `public_side_enabled`.

## F7 — Named constructors

> **Status (2026-09-22): not done, and cheaper to leave alone than when the note was written.** The single constructor gained a parameter instead — `public_side_enabled` — so a second named constructor would now have to carry it too. Still optional, still neutral on every axis.

`constructor_with_initial_supply` and `constructor_with_minter` are conveniences. Neutral on every axis; a matter of deployment ergonomics. Optional.

## Rejected — features that are not CMTAT-compatible

Two AIP-20 behaviours fail the first test outright and are recorded so they are not proposed again:

- **Holder self-burn.** AIP-20's `burn_private` is holder-authorised only. CMTAT's criterion 11, *Cancel tokens*, is an issuer act under `BURNER_ROLE`; allowing any holder to redeem unilaterally regresses it. This is also why F4 excludes the rename.
- **A single immutable minter.** AIP-20's `minter: PublicImmutable<AztecAddress>` cannot be granted, revoked or shared. Criteria 29–31 require administered roles; the token already has them.

## Recommended order — superseded by what 0.4.0 did

> **Superseded (2026-09-22).** The order below assumed two products. One was built, with the AIP-20 surface behind `public_side_enabled`, and the sequencing came out differently: F4 shipped **first**, before F1 and before the bridges, because a selector match costs nothing and needs none of the architecture the note bundled it with. What remains open is the list under *What is left*, not the list below.

The order as written:

**CMTAT-private** (the three existing variants):

1. **F1** — measure the note-count distribution, then implement the budget and recursion, then re-measure the batch cap. No ABI or storage change; can ship alone.
2. **F3** — the rule engine, `DelayedPublicMutable`, unset by default, with the "an engine MUST NOT enqueue" rule at the extension point.

That is the whole list. CMTAT-private keeps its names, its single transfer path and its unqualified privacy table.

**CMTAT-private-AIP20** (a fourth variant, `CMTATAztecAIP20` or similar):

1. **F1** — inherited.
2. **F2 + F4 + F7** together — commitment entry points with expiry, issuer delivery and the documented amount exposure; the five renames; the named constructors. One ABI break, one storage break, one migration note, one privacy-table disclosure.
3. **F3** — inherited; and once F2 exists, a conditional-transfer rule gating settlement is the first engine anyone will want.
4. **F5** — when public events are added.

**Neither:** F6. A hybrid variant, or never.

### What is left

Three items, each a separate decision rather than "adopt AIP-20":

1. **F2's expiry** — the one mandatory addition that did not ship. A commitment carries the screening it had at initialization for as long as it lives; the fix is a timestamp in the partial note's public data and an assertion at completion, or carrying `to` to completion so it can be re-screened.
2. **F3, the rule engine** — the whole feature, with the receiving side already built twice on the authorization-contract side.
3. **F7** — optional, and now slightly more expensive than when it was scored.

Everything else on this list is either in the code or refused; the refusals (holder self-burn, a single immutable minter, `transfer_public_to_public`, `mint_to_public`, `burn_public`) are decided and should not be re-opened without new evidence.

## What each feature changes in the equivalency assessment

| Feature | Assessment change | Carried out? |
|---|---|---|
| F1 | None to answers. Add the note bound and its behaviour to the *Transfer* note, per suggestion C-1 | **No** — the assessment does not mention the two-note budget or the recursion |
| F2 | No criterion answers change. **Privacy table:** *transfer amount* becomes `private on the direct path; visible but unlinked on the commitment path`, and *available to the issuer* is `y` only because of the added delivery — both stated in the note. New Supplementary-features entry; the Enforcement note records the commitment expiry as a second bounded window | **No** — and since F2 shipped in the three variants rather than a separate one, this is no longer "the AIP20 variant's assessment only": it is the assessment |
| F3 | Restriction table: "RuleEngine / transfer hook" ✘ → ✔; criteria 26–28 re-examined; the per-transfer cost recorded next to the setter. **Privacy table:** unchanged, with a note that the deployed engine runs private and enqueues nothing | n/a — F3 is not implemented |
| F4 | Implementation-details cells that name `transfer`, `mint`, `public_get_*` updated; a note that the private profile matches AIP-20 selectors and that `burn` deliberately does not | **Yes** |
| F6 | A separate assessment for the separate variant, whose privacy table would answer *balance*, *transfer amount* and *participants* as `public` on the public side | **Superseded, and not carried out.** There is no separate variant: the narrow form lives in all three behind a flag, so the existing privacy table needs the conditional answers rather than a second document — see the note at the top |

The three **No** rows are one open task on the assessment, not on the code.
