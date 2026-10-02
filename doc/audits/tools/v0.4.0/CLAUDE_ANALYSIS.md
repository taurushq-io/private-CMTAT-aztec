# private-CMTAT-aztec — Aztec.nr Code Quality Review, 0.4.0

| | |
|---|---|
| Scope | The three token variants (`CMTATAztec`, `CMTATAztecDebt`, `CMTATAztecLight`), the two ARC-403 authorization contracts (`CMTATAztecAuth`, `CMTATAztecAuthMultiToken`), and `cmtat_aztec_lib` — in particular the three modules new in 0.4.0: `tokenModule.nr`, `hybridModule.nr`, `authorizationHookModule.nr` |
| Commit reviewed | `1a7470c` on the 0.4.0 development branch (`version()` returns `0.4.0`); the fixes recorded below land on top of it |
| Aztec | CLI `5.2.0`; `aztec-nr` tag `v5.2.0` in every `Nargo.toml`; Noir `1.0.0-beta.25` |
| Date | 2026-09-16 |
| Produced with | Claude Code, following the same checks as the [0.3.0 review](../v0.3.0/CLAUDE_ANALYSIS.md); finding IDs continue that report's numbering within each check |

**This is a code-quality review, not a security audit.** Nothing found here lets an unauthorised party move value, spend another holder's note, bypass a restriction or brick a contract. The one place the review changed a *deployed* property is the removal of two asserts that could never fire (D-3), verified gate-for-gate.

**Privacy findings are in section H.** They are the reason the review exists; for 0.4.0 they concern what the four new private/public bridges publish, and they confirm the design intent rather than contradict it.

**What this review adds over 0.3.0.** Check **K — tests** is new and carries the largest findings of the release: a mutation check showed the project's hard audit invariant (every note copied to the issuer) had no test that could fail; the test harness compiled only the base variant, so four of five contracts were being tested against stale artifacts; and the two smaller variants had smoke suites only. All three are fixed below, with the measurements. The suite grew from 169 to 187 tests in the process.

## Disposition summary

Carried forward from 0.3.0 where still open; new IDs continue each check's sequence. ✅ fixed in this review · ⬜ open (decide / leave) · ⚠️ corrected.

| ID | Finding | Outcome |
|---|---|---|
| A-4 | The token-module refactor is gate-neutral | ✅ verified — all 48 private circuits byte-identical before and after |
| A-5 | The bridges pay the 16-note `sub` the same way `transfer` does | ✅ applied after the review — AIP-20's scheme: budget 2, then `_recurse_debit` at 8 per call; −42,203 on a transfer, −42,204 on a bridge and a burn; the 12-note ceiling and the 16-note failure are gone (50 notes measured); 6 tests; see A-5 |
| A-6 | `initialize_transfer_commitment` costs 39,820 gates, half of it the constrained issuer event | ⬜ keep — the cheaper delivery modes give up the guarantee the event exists for |
| B-3 | `CreditEventsStruct` packs two `bool`s into two Fields | ✅ fixed — 0.4.0 is the storage break the 0.3.0 verdict said to wait for; hand-packed to `N = 2` with a round-trip test |
| B-4 | `PauseModule` uses two one-`bool` slots | ⬜ leave — unchanged since 0.3.0 |
| B-5 | The hybrid fields were appended after the existing storage | ✅ verified — no slot moved; the constructor gained a trailing argument only |
| C-7 | The public `Transfer` event is emitted from two sites | ⬜ keep — `_credit_public` and `_debit_public` are two effects, each with the `PRIVATE_ADDRESS` marker on its private side |
| C-8 | A completed commitment's note has no issuer copy | ⬜ keep — the issuer's record is the constrained `CommitmentInitialized` event plus the commitment-tagged completion log; stated in `doc/README.md` |
| C-9 | Four `unused` / `mut` warnings in the base test crate | ✅ fixed — build is warning-clean apart from the framework's own macro warnings |
| D-1 | The three `main.nr` were 99–100 % identical | ✅ closed by `tokenModule.nr` — residue measured below |
| D-3 | `require_batch_shape` asserted two facts that cannot be false | ✅ fixed — removed; gate profile unchanged, confirming the asserts were constant-folded |
| E-3 | Every enqueued public half is `#[only_self]`; every getter `#[view]`; `screening` is a `#[contract_library_method]` | ✅ verified — see the table in E |
| F-1 | Should this token implement AIP-20? | ⚠️ **re-framed** — the 0.3.0 answer ("no, take three things") is overtaken: 0.4.0 took four of the seven features of `aip20-features-for-cmtat.md` and refused two; what is left is the note budget (A-5), the commitment expiry and the rule-engine hook, each a separate decision — see F |
| F-2 | The bridge selectors and the `PRIVATE_ADDRESS_MAGIC_VALUE` semantics match the fork | ✅ verified — pinned by tests against `Token::interface()` at fork commit `5433e9c` |
| G-7 | `doc/img/architecture.puml` still showed three variants and no `tokenModule` | ✅ fixed — re-drawn and re-rendered |
| G-8 | The glossary and the agent guide named the removed `_*_internal` helpers | ✅ fixed |
| G-9 | A stale `cmtat_aztec_aip20` artifact from the reverted crate sat in `target/` | ✅ fixed — removed; `yarn clean` before profiling |
| H-6 | The 360-second delay is an order of magnitude under the library's recommended minimum | ✅ decided and applied after the review — initial delay raised to **one hour** (options 1 and 3 of H-6): `CHANGE_ROLES_DELAY_SECONDS = 3600`, plus `set_roles_delay` / `roles_delay()` in the five contracts, bounded by the 24 h transaction lifetime; per-address entries adopt the setting when written; 8 + 3 + 3 tests |
| H-7 | Public-call-count fingerprint, extended to the bridges | ⬜ keep — every value-moving entry point enqueues exactly one public call; the two that enqueue none move no value |
| H-8 | What the bridges publish | ✅ verified — exactly the mover's own side, as the design states; `PRIVACY:` comments at every public half |
| H-9 | The commitment completion log carries the amount unencrypted | ⬜ keep — inherent to partial notes; disclosed in `doc/README.md` and the assessment |
| H-10 | Nothing demonstrates that the issuer's PXE can *process* the offchain copies it receives | ✅ route A applied after the review — root cause found (a stock PXE drops, or crashes on, any note it does not own, by either delivery mode); mints and burns now deliver a constrained `Transfer` event to the issuer, so the event stream is a complete, processable ledger; 4 tests, mutants killed; the two-PXE e2e test remains to be run |
| J-2 | Tests live in the contract crates | ✅ **corrected, then fixed** — `aztec compile` *does* warn at 5.2.0 (the 0.3.0 correction had run `aztec-nargo compile`, which does not); the tests moved to five `type = "lib"` crates under `tests/`, the warning is gone and a test-only edit leaves the artifacts untouched |
| J-4 | `default-member` made `aztec test` compile one contract of five | ✅ fixed — see K-1 |
| K-1 | `aztec test` ran four of five contracts against stale artifacts after any library edit | ✅ fixed — `default-member` removed from the workspace `Nargo.toml`; proven by a mutant that survived, then died |
| K-2 | The issuer-copy invariant had no test that could fail | ✅ fixed — 4 tests over `env.offchain_messages()`; the mutant that survived now dies |
| K-3 | Six guards had no negative test; no before-delay twin for the freeze; no zero-amount, listed-commitment-party or private-getter test | ✅ fixed — 12 tests in `test_guards.nr` |
| K-4 | `CMTATAztecDebt` and `CMTATAztecLight` had smoke suites only, and nothing guarded their declarations against drift | ✅ fixed — a selector-set pin per variant; the chains themselves are tested once, in the base suite, by construction |
| K-5 | Edge cases still without a test | ✅ fixed (the mechanical part) — 15 tests in `test_edge_cases.nr`, 6 in each authorization crate; two of them measured behaviour the code did not state (K-6, K-7); two design questions and two e2e-only rows remain in K.3 |
| K-6 | A second payment into the same commitment is lost to the recipient | ✅ fixed after the review — `pay_commitment` pushes `commitment_paid_nullifier(C)`; a second payment is a duplicate nullifier; +52 gates on `transfer_private_to_commitment`; 3 tests, mutant killed; options and the upstream check in `doc/technical/commitment-reuse.md` |
| K-7 | One transfer spends at most 12 notes, not the 16 `BalanceSet::sub` allows | ✅ verified and recorded, then lifted by A-5 — each recursive call has its own side-effect budget; 50 notes measured in one transfer |

**Counts:** 31 rows — 24 ✅ (6 verified, 18 fixed), 1 ⚠️ (F-1 re-framed), 6 ⬜ open (0 *decide*; 6 *keep / leave*: A-6, B-4, C-7, C-8, H-7, H-9). *Counted from the table.*

## Outstanding

| ID | Item | Why it is still open |
|---|---|---|
| F-1 | The two AIP-20 features still open after 0.4.0 | A commitment **expiry** (F2, addition 1: a recipient frozen after opening a commitment can still be paid into it) and the **rule-engine hook** with recipient and caller (F3). Both are additions, not renames; both need a design pass. The refusals — holder self-burn, a single immutable minter, public-to-public transfers — are decided and should stay refused. |
| H-6 | The 360 s delay | **Decided: one hour, adjustable.** Chosen on the freeze window and the proving budget; the privacy-set argument turned out to be moot for this token (the public pause check names the contract on every path, see the correction under H-6), so the remaining input is holders' proving times. |
| H-10 | Issuer processing of offchain copies | **Closed by route A** (constrained mint / burn events to the issuer; the `Transfer` stream is now a complete ledger). Remaining: the two-PXE e2e test that shows a real PXE dropping the note copy and processing the events (H-10 lays it out); route B (custom audit message + capsule ledger) if note-level corroboration is wanted. |
| K-6 | Commitment reuse | **Closed**: option 2 of `doc/technical/commitment-reuse.md` applied — one nullifier `H(C, DOM_SEP__CMTAT_COMMITMENT_PAID)` pushed in `pay_commitment` (private half; nothing published, no layout change), +52 gates on `transfer_private_to_commitment`, three tests, mutant killed. Upstream checked 2026-09-17: aztec-nr `main` and aztec-standards `main` unchanged; aztec-packages #14364 (open) puts single-completion on *contract logic* so the library never spends a completion nullifier, i.e. the framework expects exactly this fix from the token. The two design questions of K.3 (zero-address recipient / completer, last admin renouncing) remain open. |

## Gate-count baseline

`aztec profile gates ./target` at `1a7470c`, after a clean `aztec compile --workspace`. Per-function circuit gates only, no kernel overhead. The 0.3.0 column is that report's baseline; the three token variants' value-moving functions were re-measured before and after the token-module refactor (A-4) and after D-3, and did not move.

| Function | `CMTATAztec` 0.3.0 | `CMTATAztec` 0.4.0 | `CMTATAztecDebt` | `CMTATAztecLight` | Note |
|---|---:|---:|---:|---:|---|
| `transfer_private_to_private` (was `transfer`) | 120,824 | 161,493 → 119,290 | 161,493 → 119,290 | 151,085 → 108,882 | +40,669: the `Transfer` event now constrained to both parties (H-4, 0.3.0); then −42,203 after the review: note budget 2 + recursion (A-5) |
| `transfer_batch` | 119,145 | 312,909 → 228,274 | 312,909 → 228,274 | 292,178 → 207,543 | cap lowered 4 → 2; per-recipient cost is what grew; then A-5 |
| `mint_to_private` (was `mint`) | 30,776 | 36,976 → 61,062 | 36,976 → 61,062 | 30,776 → 54,862 | +6,200: recipient list screening (G-1, 0.3.0); Light has no lists. Then +24,086 after the review: the issuer's constrained mint event (H-10, route A) |
| `mint_batch` | 30,776 | 132,584 → 218,669 | 132,584 → 218,669 | 107,871 → 193,956 | cap raised 1 → 4; then one issuer event per recipient (H-10) |
| `burn` | 83,656 | 87,935 → 111,638 → 69,434 | same | 81,736 → 105,439 → 63,235 | +4,279: account list screening (G-1); then +23,703: the issuer's constrained burn event (H-10); then −42,204 (A-5) |
| `burn_batch` | 81,736 | 331,362 → 352,719 → 183,691 | same | 306,820 → 328,177 → 159,149 | cap raised 1 → 4; then one issuer event for the batch total (H-10); then A-5, four debits each 42k lighter |
| `transfer_private_to_public` | — | 95,941 → 53,737 | 95,941 → 53,737 | 85,534 → 43,330 | new; then A-5 (AIP-20 does it in 38,277; the rest is screening) |
| `transfer_public_to_private` | — | 46,833 | 46,833 | 36,425 | new |
| `transfer_private_to_commitment` | — | 93,011 → 93,063 → 50,857 | same | 86,812 → 86,864 → 44,658 | new; +52 after the review for the K-6 commitment-paid nullifier; then A-5 |
| `transfer_private_to_public_with_commitment` | — | 129,874 → 87,671 | 129,874 → 87,671 | 113,352 → 71,149 | new; then A-5 |
| `_recurse_debit` | — | 30,138 | 30,138 | 30,138 | new with A-5: the `#[only_self]` recursive half of a debit, 8-note budget |
| `initialize_transfer_commitment` | — | 39,820 | 39,820 | 33,621 | new; see A-6 |
| `cancel_authwit` | 6,436 | 6,436 | 6,436 | 6,436 | |
| `private_get_*` | 8,229–8,347 | 8,229–8,347 | same | same | |

| Function | `CMTATAztecAuth` | `CMTATAztecAuthMultiToken` |
|---|---:|---:|
| `authorize_private` | 14,650 | 14,651 |

Whole-transaction numbers (`aztec-wallet profile`) were not taken; nothing below depends on them.

---

## A. Circuit cost — private functions

### A-4. The token-module refactor is gate-neutral — verified

`doc/technical/token-module.md` predicted that moving the chains into library functions would not change any circuit, because library calls and `#[internal]` helpers are both inlined. The prediction was tested rather than trusted: `aztec profile gates ./target` was captured at `f437cbe^` and again after the refactor, and the 48 private circuits of the five contracts are **byte-identical** in gate count. The same check was repeated after D-3 below. **Keep, and keep the method**: the profile diff is the acceptance test for any change that claims to be a pure refactor.

### A-5. The bridges inherit the 16-note `sub` — decide (same decision as F-1)

**In one sentence.** Every function that spends notes is compiled as if it might spend sixteen of them, whatever the holder actually has, and that fixed sizing costs about 3,000 gates per unused slot; AIP-20 sizes for two and grows on demand, and this project has not decided whether to do the same.

#### What a "note budget" is, and why it is paid whether or not it is used

A private balance is a set of notes, and a debit spends some of them: `BalanceSet::sub(amount)` picks notes (largest first) until their sum covers `amount`, nullifies them, and creates one change note for the difference. That happens inside a zero-knowledge circuit, and a circuit has no loops of variable length: the number of notes a call *may* read is fixed when the contract is compiled, and every one of those slots is paid for in the proof — a note-hash read request, a membership proof, a nullifier — even when the slot goes unused because the holder's balance was one note. That fixed number is the **note budget**. The library's own comment on `try_sub` states the trade: "the gate count scales relatively linearly with `max_notes`, but a lower `max_notes` parameter increases the likelihood of `try_sub` subtracting an amount smaller than `target_amount`", i.e. of the call failing for a holder whose balance is fragmented into more notes than the budget.

`BalanceSet::sub`, which `debit_private` in `tokenModule.nr` calls for every transfer, bridge and burn, hard-codes the budget to the protocol maximum, `MAX_NOTE_HASH_READ_REQUESTS_PER_CALL = 16`:

```noir
pub fn sub(self: Self, amount: u128) -> MaybeNoteMessage<UintNote> {
    let subtracted = self.try_sub(amount, MAX_NOTE_HASH_READ_REQUESTS_PER_CALL);  // 16
    assert(subtracted >= amount, "Balance too low");
    self.add(subtracted - amount)
}
```

So a `transfer_private_to_private` of a holder who owns a single note proves sixteen note reads, fifteen of them empty. (K-7 adds a twist: the *side-effect* budget of a call runs out before the sixteen are reachable — twelve notes is the measured ceiling — so today's circuit pays for slots the call could never fill.)

#### What AIP-20 does instead

The reference `Token` never calls `sub`. It calls `try_sub(amount, 2)`: a budget of **two** notes, which covers a holder whose balance is one note plus at most one more. If two notes do not reach `amount`, it does not fail; it computes the remainder and calls **itself**, through an `#[only_self]` private entry point, with a budget of **eight** for that inner call, and again if needed:

```noir
global INITIAL_TRANSFER_CALL_MAX_NOTES: u32 = 2;
global RECURSIVE_TRANSFER_CALL_MAX_NOTES: u32 = 8;

fn _subtract_balance(account, amount, max_notes) -> u128 {
    let subtracted = self.storage.private_balances.at(account).try_sub(amount, max_notes);
    if subtracted >= amount {
        subtracted - amount                                   // done: the change
    } else {
        assert(subtracted > 0, "Balance too low");
        self.call_self.recurse_subtract_balance_internal(account, amount - subtracted)
    }
}
```

The effect is that the *common* case, a holder with one or two notes, proves a small circuit, and the *rare* case, a fragmented balance, pays for an extra private call, which is an extra kernel iteration in the proof (on the order of 101,000 gates by the framework's own figure). The circuit is sized for what usually happens rather than for what could happen.

#### Measured on this contract, 2026-09-18

`debit_private` was probed with `try_sub(amount, N)` in place of `sub` (the probe was reverted and the baseline artifact rebuilt; `transfer_private_to_private` is back at 161,493):

| Note budget `N` | `transfer_private_to_private` | `transfer_private_to_public` | `transfer_private_to_commitment` | `burn` | `transfer_batch` (2) | `burn_batch` (4) |
|---:|---:|---:|---:|---:|---:|---:|
| **16** (today, `sub`) | **161,493** | **95,941** | **93,063** | **111,638** | **312,909** | **352,719** |
| 8 (AIP-20's recursive budget) | 136,709 | 71,157 | 68,250 | 86,854 | 263,341 | 253,583 |
| 4 | 124,500 | 58,948 | 56,070 | 74,645 | 238,923 | 204,747 |
| 2 (AIP-20's initial budget) | 118,447 | 52,895 | 50,015 | 68,592 | 226,852 | 180,605 |

Three things to read off it. The cost is linear, **about 3,050 gates per note slot**, on every path (2 → 4: +6,053; 4 → 8: +12,209; 8 → 16: +24,784). The 0.3.0 measurement is reproduced exactly: budget 2 saves **43,046** gates on a transfer, 27% of today's circuit (36% of the 0.3.0 one, which had no constrained event deliveries yet). And the bridges, which were the reason this row was opened, are where the share is largest: `transfer_private_to_public` drops from 95,941 to 52,895, which puts it within 15,000 gates of AIP-20's 38,277 — the remainder being the screening reads (five `DelayedPublicMutable` reads, ~20k; the Light variant, which skips two of them, is 10,407 lower) and the `public_side_enabled` read (~3.5k), all of which are the compliance the project chose.

#### The trade-off, per holder

The saving is not free; it moves cost from the common case to the fragmented one:

| Notes the debit has to spend | Today (16, no recursion) | With 2 + recursion of 8 (AIP-20's scheme) |
|---|---|---|
| 1 or 2 | 161,493 | **118,447** |
| 3 to 10 | 161,493 | 118,447 **plus one recursive call** (~101k more) — worse than today |
| 11 or 12 | 161,493 | plus two recursive calls |
| 13 to 16 | fails (`push out of bounds`, K-7) | plus two calls; the side-effect budget per *call* resets, so this **works** |
| more than 16 | fails (`Balance too low`) | keeps recursing; the ceiling becomes the nested-call limit, not the note count |

So the scheme is a win only if most debits settle in one or two notes. For a security token that is plausible — a holder's notes are its incoming transfers and mints, and a transfer consolidates the sender's spent notes into one change note — but it is **unmeasured**: the number that decides A-5 is the note-count distribution of real holders, not a gate count, and this project has no such data yet. A budget of 4 without recursion (124,500 gates, −37k) is a middle position that would need no new entry point and would still fail above four notes, i.e. more often than today.

#### What implementing it involves

- `debit_private` in `tokenModule.nr` takes a `max_notes` parameter and returns the remainder instead of asserting; the recursion itself cannot live in the library, because calling the contract from inside itself (`self.call_self`) needs the contract context, so each variant's `main.nr` gains one `#[external("private")] #[only_self] fn _recurse_debit(account, remaining) -> u128` and the loop that AIP-20 has. Three variants, one new selector each (an ABI *addition*, not a break); no storage or note-layout change.
- Every value-moving path changes at once, which is why the report's hazards paragraph asks for the gate profile *and* the note-count edge cases of K.3 as acceptance: the 12-note ceiling test of K-7 is precisely the case whose outcome flips (from a failure to a success with two recursive calls), and `Balance too low` must still fire at every recursion depth for a balance that is short even after the recursion.
- The issuer's offchain copies and the constrained deliveries are unaffected: they are per note created, and the change note is still one.

**Applied after the review (2026-09-18).** `tokenModule.nr` gained `DEBIT_INITIAL_MAX_NOTES = 2`, `DEBIT_RECURSIVE_MAX_NOTES = 8`, `try_debit` (one attempt, returns `(covered, change-or-remaining)`), `debit_recursive`, and `debit_private` now takes the recursion as a closure so that the four chains stay in the library; each variant's `main.nr` gained `#[external("private")] #[only_self] fn _recurse_debit(account, remaining) -> u128`, which calls `debit_recursive` with itself as the closure. Scheme and constants are AIP-20's, credited in the code; the implementation is this project's. Measured:

| | before | after |
|---|---:|---:|
| `transfer_private_to_private` | 161,493 | **119,290** (−42,203) |
| `burn` | 111,638 | **69,434** |
| `transfer_private_to_public` | 95,941 | **53,737** |
| `transfer_private_to_commitment` | 93,063 | **50,857** |
| `transfer_private_to_public_with_commitment` | 129,874 | **87,671** |
| `transfer_batch` (2) / `burn_batch` (4) | 312,909 / 352,719 | **228,274 / 183,691** |
| `_recurse_debit` (new) | — | 30,138 per recursive call, plus the nested-call kernel iteration |

Light is about 10,400 lower on each, as before. Tests (`test_edge_cases.nr`): 2 notes without recursion, 3 notes through one recursive call (the case that got dearer), 12 and 17 notes in one transfer (the K-7 ceiling and the 16-note failure, both gone; 50 was measured to pass and the probe removed), `Balance too low` still firing on a fragmented balance that the recursion cannot cover, and `_recurse_debit` refused to a caller that is not the contract. The open input — how fragmented real balances are — is unchanged, and the decision taken is the standard's: optimise the one-or-two-note case and let a fragmented balance pay per eight notes rather than fail.

### A-6. `initialize_transfer_commitment` — keep

39,820 gates, against 6,685 for the fork's own `initialize_transfer_commitment`. The extra is the recipient screening (freeze + list, ~12k, absent in AIP-20 which screens nobody there) and the `CommitmentInitialized` event delivered `onchain_constrained` to the issuer (~20k, the per-delivery figure measured in 0.3.0). The event is what gives the issuer a verifiable record of *which holder* a commitment belongs to before the unencrypted completion log arrives; `offchain()` would make that record forgeable by the opener, `onchain_unconstrained()` would pay DA for the same weakness. **Keep.**

## B. Storage, packing and note reads

### B-3. `CreditEventsStruct` spent three Fields where two suffice — fixed, because 0.4.0 is the break

**The finding, restated.** `creditEventsModule.nr` declared `#[derive(Deserialize, Eq, Packable, Serialize)]` on `{ flagDefault: bool, flagRedeemed: bool, rating: FieldCompressedString }`. A derived `Packable` spends one Field per member, so the struct took three public-storage slots — one per `SLOAD` on read and `SSTORE` on write — of which two held a single bit each. CMTAT Solidity's identical `CreditEvents` struct takes **two** slots, because the Solidity storage packer puts adjacent sub-word members in one slot and the compiler does it for free; Noir has no packer, so parity means writing `pack`/`unpack` by hand. The project already does exactly that for `UserFlags` in the validation module (B-2, 0.3.0).

**Why the 0.3.0 verdict was "decide", and what changed.** The change moves every state variable declared after `credit_event_module` — in `CMTATAztecDebt`'s storage struct that is `debt_module`, `issuer_address`, `private_balances`, `total_supply` and the rest — so on a *deployed* token it is a redeployment and a holder migration, and the 0.3.0 report said: correct, but fold it into a storage break that is happening anyway rather than causing one. **0.4.0 is that break.** The release is already MAJOR under the project's own policy (five renamed entry points, a constructor with a new argument, two storage fields appended), no 0.4.0 instance is deployed, and the debt realignment of 0.3.0 — the break the earlier verdict said it "would have cost nothing" to ride — has a successor now. Waiting for the *next* break after this one would be the mistake the 0.3.0 verdict warned against.

**What was done.** `CreditEventsStruct` keeps its derived `Serialize` / `Deserialize` — the ABI is unchanged, `get_credit_events` still returns `[Field; 3]` and `set_credit_events` still takes the three-member struct — and gains a hand-written `Packable` with `N = 2`: Field 0 holds the two flags as bits (`FLAG_DEFAULT_BIT = 1`, `FLAG_REDEEMED_BIT = 2`), Field 1 holds the rating's single Field. The module's `StateVariable` impl now declares the **packed** length (`T_PACKED_LEN = 2`) instead of the serialized one, which is what allocates the slots. Two tests in the module itself keep the packing honest: `unpack(pack(x)) == x` for all four flag combinations, and the two flags land in distinct bits with the rating untouched. `cmtat_aztec_lib` therefore reports its first two tests.

**What it cost and saved.** Public functions only: one `SLOAD` fewer on `get_credit_events`, one `SSTORE` fewer on `set_credit_events`. No private circuit reads the struct, so — unlike B-1, where hand-packing `SetFlag` cost 7 gates on the private transfer path — there is no circuit penalty; the Debt variant's private gate profile is identical before and after (checked). One slot saved on one variant. The value is parity with the reference layout and a second worked example, next to `UserFlags`, of how this project packs flags.

**Hazard, stated once more.** This is a storage-layout change on `CMTATAztecDebt`. It must ship in 0.4.0 or not at all; anyone deploying from the 0.3.0 tag and then upgrading their source to 0.4.0 has a different layout, and the private-balance slot feeds every note hash. The changelog entry carries the `BREAKING CHANGE` line.

### B-4 — carried forward, unchanged

`PauseModule`'s two one-`bool` slots stay separate: `is_paused` is read on every transfer's public half, `is_deactivated` only by `unpause_contract`, its getter and the mint/burn halves; sharing a Field would make the hot read pay for unpacking the cold flag. The same Solidity comparison applies (one slot there), and the same answer: **leave**.

### B-5. The hybrid fields were appended, not inserted — verified

`public_balances: PublicBalances<Context>` (one slot, a `Map`) and `public_side_enabled: PublicImmutable<bool, Context>` are the last two fields of `Storage` in all three variants, so every pre-existing slot — including `private_balances`, which feeds every note hash — is unchanged. The constructor gained a trailing `public_side_enabled: bool`. **Verified by reading the three storage structs**; no probe needed. The 0.3.0 warning stands for the future: a field inserted anywhere else re-slots what follows.

## C. Deliveries, events and messages

### C-7. `Transfer` (public) emitted from two sites — keep

**What the check looks for.** Section C asks, for every state change, whether an event is emitted, from how many places, and whether the emissions can drift apart. An event emitted from several sites is the usual way an "every change emits" invariant erodes: one site is edited, the other is not, or a new path is added that forgets to emit. The 0.4.0 bridges introduced a second public `Transfer` emission, which is what triggered the row.

**The two sites.** Both are `#[only_self]` public halves in each variant's `main.nr`, reached only through `enqueue_self` from a private bridge:

| Site | Emits | Enqueued by | Meaning |
|---|---|---|---|
| `_credit_public(to, amount)` | `Transfer { from: PRIVATE_ADDRESS_MAGIC_VALUE, to, amount }` | `transfer_private_to_public`, `transfer_private_to_public_with_commitment` | value arrived on the public side from a private sender |
| `_debit_public(from, amount)` | `Transfer { from, to: PRIVATE_ADDRESS_MAGIC_VALUE, amount }` | `transfer_public_to_private` | value left the public side towards a private recipient |

`PRIVATE_ADDRESS_MAGIC_VALUE` is `sha224("PRIVATE_ADDRESS")`, the sentinel AIP-20 puts in the position of the party that stays private, so that an indexer can tell "the counterpart is private" from "the counterpart is the zero address" (a mint or a burn). The library defines it once in `hybridModule.nr` with the same value as the fork's token; nothing in the suite pins that value (see the last paragraph).

**Why two sites is the right number here.** The two emissions are not two copies of one effect; they are two different effects, and the difference is exactly the marker's position. A credit has no `from` to publish and a debit has no `to`, so a single shared emission would need either a flag that selects which field carries the marker, or an emit in the private half — the first buys nothing over two one-line sites, the second would publish the address the private half exists to hide. Each effect has one and only one path to it, and the emission sits in the same function as the state change it reports (`credit_public` / `debit_public` in `tokenModule.nr` update the map, the enclosing public half emits), so the invariant "a public balance never moves without a `Transfer`" holds by construction rather than by convention: there is no third way to move a public balance. That is the sense in which the row says *structural*.

**What it is not.** It is not the private `Transfer` (H-4). The same event struct is used in two contexts: `transfer_private_to_private` emits it *privately* and delivers it constrained to the recipient and to the issuer; the two sites above emit it *publicly*, as a plain log anyone can read, from a public function. The public emissions publish `to` or `from` and `amount`, which is the nature of the public side the holder chose; the private one publishes nothing. C-7 is only about the public pair.

**What a reviewer should check when the code moves.** That every path that touches `public_balances` still ends in one of the two halves (today: three enqueues, listed above); that the marker occupies the private side's slot in both; that the value still equals AIP-20's, since indexers written for the standard key on it; and that no private function emits the public event. A test that pins the constant to `sha224("PRIVATE_ADDRESS")` and one that decodes the public log of each bridge and asserts the marker's position would make the last two checks mechanical; neither exists today, and they are the one addition worth making. **Keep** the two sites.

### C-8. A completed commitment's note has no issuer copy — keep, and it is documented

`pay_commitment` completes the partial note through `complete_from_private`, which pushes the note hash directly and emits the completion log itself; there is no `NoteMessage` to `deliver_to(issuer, …)`. The issuer's record is therefore the `CommitmentInitialized { to, completer, commitment }` event (constrained, K-2's method could be extended to assert it) plus the completion log, which is tagged by the commitment and carries the amount in clear. `doc/README.md` states this under *Private/public bridges*. **Keep**; the alternative — a second note for the issuer at completion — would double the completion's cost for information the issuer already has.

### C-9. Build warnings — fixed

`aztec compile 2>&1 | grep -i unused` found one `unused variable issuer` (`test_extra_information.nr:25`) and three `variable does not need to be mutable` (`test_hybrid.nr:120/148/158`), all in tests. Fixed. The remaining warnings (`Return variable contains a constant value` ×50, from the framework's own macro expansion) are not the project's. No undelivered message: every `emit`, `add` and `sub` in the library and the contracts is followed by a delivery.

## D. Duplication

### D-1. Cross-variant drift — closed

The 0.3.0 report left D-1 open as structural: "extraction is not available". It was available for everything except the declarations. After `tokenModule.nr` the three `main.nr` have 554 / 609 / 484 *code* lines (comments excluded), of which 514 of the base's are also in Light and 553 in Debt — but those shared lines are now entry-point declarations, attributes, enqueues and events, which Noir requires in the contract module, not logic. The variants differ on the value-moving paths in exactly one line each: `fn screening(storage) -> FreezeAndLists | FreezeOnly`. K-4 adds the guard the residue needs (a selector-set pin per variant).

### D-3. Two asserts that could not fail — fixed

`tokenModule::require_batch_shape(accounts_len, amounts_len)` asserted `accounts_len != 0` and `accounts_len == amounts_len`. Both arguments were `.len()` of fixed-size arrays `[T; MAX_ADDR_PER_CALL]` — compile-time constants equal by type — and `burn_batch` passed `amount.len(), amount.len()`, comparing a value to itself. Neither assert could fire; the message `"Mint module empty"` also appeared on the transfer and burn paths. Removed, with its two message globals. `aztec profile gates` before and after: **identical for every circuit**, which confirms the compiler had already folded them to nothing. The finding is legibility, not cost: a reader took them for a runtime check.

## E. Macro and attribute convention drift

### E-3. Attribute audit of the new surface — verified

| Function | `#[external]` | `#[only_self]` | `#[view]` | Note |
|---|---|---|---|---|
| `_mint`, `_transfer`, `_burn` | public | ✓ | — | as in 0.3.0 |
| `_credit_public`, `_debit_public` | public | ✓ | — | new; arguments published by design (H-8) |
| `_require_lifecycle_allows` (auth ×2) | public | ✓ | — | new |
| `balance_of_public`, `public_get_public_side_enabled`, `get_operations` (auth) | public | — | ✓ | new getters |
| `_grant_role_internal`, `_emit_listed`, `_open_commitment` | `#[internal("public"\|"private")]` | n/a | n/a | inlined helpers |
| `screening` | `#[contract_library_method]` | n/a | n/a | returns a struct holding state variables, which an `#[internal]` may not (entry-point type rule: "vectors, references … may not be used in contract functions"); a library method is the documented shape |

No `#[noinitcheck]`, no second `#[initializer]`, no `#[allow_phase_change]` anywhere. The `#[authorize_once]` attributes name `"from"` / `"account"` and the parameters still carry those names after the AIP-20 renames — checked, since a rename there is a silent break.

## F. Standard conformance

### F-1. AIP-20 — ⚠️ re-framed: the question answered in 0.3.0 is not the question 0.4.0 faced

**What F-1 asked in 0.3.0, and what it answered.** "Should this token implement AIP-20?" The answer was *no* — two design conflicts (public balances expose holdings; partial notes cannot be screened at completion) made conformance incompatible with a restricted token — *but take three things from it*: the note budget, and two items that were then only sketched. The disposition row read "answered: no, but take its note budget".

**What 0.4.0 actually did** is wider than that row suggests, and it did not follow from "no". Between the two reviews, `doc/technical/aip20-features-for-cmtat.md` broke AIP-20 into seven features (F1–F7) and scored each against the 61 equivalency criteria and the assessment's privacy table. 0.4.0 then took the features one by one. Measured against that list:

| Feature | Decision | State in 0.4.0 |
|---|---|---|
| F1 — note budget with `#[only_self]` recursion | recommended | **done after the review** (A-5, 2026-09-18) |
| F2 — commitment transfers, screened at initialization | recommended for the AIP20 variant only, with three additions | **done in the token variants themselves**, behind `public_side_enabled`: `initialize_transfer_commitment` screens `to` (addition 3), the issuer receives a constrained `CommitmentInitialized` event (addition 2, in event form); the **expiry (addition 1) is not done** and is recorded as a limitation |
| F3 — rule-engine hook with recipient and caller | recommended | **not done**; the ARC-403-shaped hook exists on the *authorization contracts* side (`CMTATAztecAuth`) but the token has no settable hook |
| F4 — AIP-20 entry-point names | recommended | **done**: five renames; the seven-function private profile answers the standard's selectors, pinned in `test_aip20_profile.nr` and, since K-4, in every variant |
| F5 — `PRIVATE_ADDRESS_MAGIC_VALUE` in public events | recommended with F6 | **done** on the two public `Transfer` emissions of the bridges |
| F6 — public balances | "in neither product" | **done in a narrower form than the one refused**: a public balance exists as the landing and departure point of the four bridges, holder-initiated and issuer-enabled by a deployment flag; the refused part — `transfer_public_to_public`, `mint_to_public`, `burn_public`, a transparent second ledger — stays refused |
| F7 — named constructors | optional | **not done**; the one constructor gained `public_side_enabled` instead |
| holder self-burn (`burn_private`), single immutable minter | rejected in the features document | **stay rejected**: `burn` keeps `BURNER_ROLE` and its own selector, minting keeps `MINTER_ROLE`; `doc/README.md` says why (an identical selector with different authorisation misleads wallets) |

So the token is now, deliberately, **a CMTAT that speaks AIP-20's private profile and offers AIP-20's private/public bridges at the issuer's option**, without being AIP-20 — the README's "partial profile, not conformance". The 0.3.0 "no" holds for conformance and for the three refusals; it does not describe the release, which is why this row is marked re-framed rather than left as "decide".

**What remains, as three separate decisions rather than one:**

1. **F1 — the note budget** (A-5). Purely a cost decision: −43,046 gates on `transfer` measured in 0.3.0, and every bridge and burn pays the same 16-note `sub` today. No storage or note-layout change. Wants the note-count edge cases of K.3 as its acceptance tests. *Done after the review: −42,203 measured, the K.3 note-count tests rewritten as the acceptance (see A-5).*
2. **F2's expiry.** A recipient frozen or delisted after opening a commitment can still be paid into it, indefinitely; the token contracts have no bounded window here where they have one (the 360 s delay) everywhere else. A design pass: an expiry stored with the commitment, or re-screening at completion by carrying `to` — the fork's hook does not, and neither does the partial note.
3. **F3 — the rule-engine hook.** A settable hook in the ARC-403 shape but passed `(from, to, amount, caller, selector)`, so an issuer can add a rule without a redeployment. The authorization-contract work has already built the receiving side twice; the missing piece is the call from the token's private chain, and its cost (one private call, ~101k gates by the documentation's figure, to be measured).

**Verdict:** re-framed. Nothing in the 0.3.0 analysis was wrong about the conflicts; the release simply found a smaller, issuer-gated form of the features the conflicts ruled out, and the remaining three are named above so the next decision is about them and not about "AIP-20".

### F-2. Bridge semantics — verified against the fork

Checked against `submodules/aztec-standards` at `5433e9c`, not against the reference contracts in `aztec-packages`: the six bridge selectors are pinned to the values read from `Token::interface()` (`0xaf28c76f`, `0x32c5dcf8`, `0x638d3f00`, `0x398c27b4`, `0xa116fff5`, `0xff7949f2`); `PRIVATE_ADDRESS_MAGIC_VALUE` is the fork's constant and is used only as "the private side of this move", never as a zero-address stand-in; `initialize_commitment` and `complete_commitment` are the fork's `_initialize_transfer_commitment` / `complete_from_private` calls with the same `(owner = to, recipient = to, completer)` arguments and the same `private_balances.get_storage_slot()` — the point where a copy error would have made completed notes undiscoverable, and which the round-trip test `recipient_opens_a_commitment_and_the_sender_completes_it` exercises through `balance_of_private`.

## G. Code / documentation mismatch

### G-7. `architecture.puml` — fixed

The diagram showed three variants over seven modules and said the three `main.nr` are "near-identical by construction". Redrawn: five contracts, `tokenModule` / `hybridModule` / `authorizationHookModule` added with their dependency arrows, `test-helpers/` added, the note rewritten to state what a variant now carries. Alt text in `doc/README.md` updated.

### G-8. Removed helpers still named — fixed

The `#[internal]` glossary row in `doc/README.md` and the *Batching caps* sentence in `CLAUDE.md` / `AGENTS.md` still cited `_mint_internal` / `_transfer_internal` / `_burn_internal`. Both now name the library chains. (The assessment and the standards documents were repointed when the refactor landed; these two were missed.)

### G-9. Stale artifact — fixed

`target/cmtat_aztec_aip20-CMTATAztecAIP20.json` survived the revert of that crate and appeared in `aztec profile gates ./target` output. Removed. `yarn clean` before profiling; the workspace fix in K-1 does not delete orphaned artifacts.

## H. Weird behaviour and privacy leakage

### H-6. The delay — carried forward, and detailed

> **Applied after the review (2026-09-18).** The finding below describes the state it was raised against, `CHANGE_ROLES_DELAY_SECONDS = 360`. The initial delay is now **3600 seconds (one hour)** and adjustable at runtime with `set_roles_delay` (options 1 and 3), bounded by `MAX_ROLES_DELAY_SECONDS = 86400`. Read the section as the analysis that led there; every "360 s" and "six minutes" in it is the old value.

**In one sentence.** Every private read of a flag or of the issuer address is only valid for `CHANGE_ROLES_DELAY_SECONDS = 360` seconds, so every value-moving transaction of this token must be included within six minutes of its anchor block and announces that fact on chain; the library recommends hours, the framework's own blacklist token uses a day, and the value was taken from an unrelated example.

#### What the delay does, and where it is felt

A `DelayedPublicMutable` is a public value a private function is allowed to read. The trick that makes the read sound is a promise: a write is *scheduled*, and takes effect only `DELAY` seconds later, so a value read at the anchor block is guaranteed still current until `anchor_timestamp + DELAY`. The private function proves against the anchor and sets the transaction's `expiration_timestamp` to that bound; the kernel takes the **minimum** over every read in the transaction; the rollup rejects a transaction included after it. Three effects follow from one number:

| Effect | Who feels it | With 360 s |
|---|---|---|
| **Write latency.** A freeze, a listing, a list-mode change or an issuer rotation takes effect `DELAY` after it is scheduled. | The compliance officer | six minutes: the freeze window the assessment describes, and the reason the value is short |
| **Validity window.** A transaction that read the value must be proved *and* included before `anchor + DELAY`. | Every holder, on every mint, transfer, burn and bridge | six minutes from the anchor block for proving (119,290 gates for a transfer, 228,274 for a batch of two; 10 to 60 s on a laptop by the documentation, longer on a phone), mempool wait and inclusion, all together |
| **Fingerprint.** `expiration_timestamp` is public. A transaction whose expiry is `anchor + 360` reads a variable with a 360 s delay. | Every holder's privacy | the token's transactions are distinguishable from those of any contract that uses a different delay, or none |

The wallet can lower an expiration to hide it in a crowd; it cannot raise it. The contract's delay is therefore an upper bound on the privacy of every transaction that touches it.

#### Which transactions carry it

All of them that move value, because they all read `issuer_address` to deliver the issuer's copies, and most read the screening flags as well:

| Private entry point | Delayed reads |
|---|---|
| `mint_to_private`, `mint_batch` | issuer; recipient freeze flag; recipient list flags and the list mode |
| `transfer_private_to_private`, `transfer_batch`, `transfer_private_to_public`, `transfer_public_to_private`, `transfer_private_to_public_with_commitment` | issuer; both parties' freeze flags; both parties' list flags; the list mode |
| `burn`, `burn_batch`, `transfer_private_to_commitment` | issuer; one party's flags |
| `initialize_transfer_commitment` | issuer; the recipient's flags |
| `private_get_issuer` | issuer |

Nine value-moving entry points and one getter, all at 360, so the minimum is 360 everywhere. Note the consequence for any proposal to "lengthen only some": a transaction's expiry is the minimum over its reads, and every one of these reads the issuer *and* at least one flag, so the shortest delay among the variables is the delay of the token. Mixing values would not lengthen any window and would add a second fingerprint (which flags a transaction read). One value for every delayed variable is the right structure; the question is only which value.

#### Where 360 came from, and what the references use

| Source | Delay | Purpose |
|---|---:|---|
| This project, `CHANGE_ROLES_DELAY_SECONDS` | 360 s | freeze, lists, list mode, issuer |
| Framework example `auth_contract` (`CHANGE_AUTHORIZED_DELAY`) | 360 s | a single authorised address; the documentation's illustrative value ("5 slots") |
| Framework example **`token_blacklist_contract`** (`CHANGE_ROLES_DELAY`) | **86,400 s** | roles and a blacklist read privately by a token — the closest analogue of this contract, and the origin of this project's constant *name* |
| Library docstring examples | 21,600 s / 86,400 s | a pause (6 h), an authorisation (24 h) |
| Library recommendation | "at least a couple hours" | general |
| `MAX_TX_LIFETIME` | 86,400 s | the protocol's inclusion limit for every transaction; the library calls it "the optimal delay from a privacy point of view", because a contract using it "puts contracts in the same privacy set as those that do not use `DelayedPublicMutable` at all" |
| AIP-20 `Token` (aztec-standards) | — | no delayed reads; its transactions expire at the protocol's 24 h |

So the name was borrowed from the blacklist token and the value from the authorisation example, which is what the 0.3.0 report meant by "decided by the documentation's example value". Two things the table settles that the 0.3.0 report left open. The privacy-set question has a partial answer: the protocol's own reference token for this exact use case sits at 24 hours, and a token with no delayed reads, AIP-20 included, expires at 24 hours too, so a 360 s expiry is a singular value on any network where those are the neighbours. And the "optimal" value is not a matter of taste: at exactly `MAX_TX_LIFETIME` the token's transactions are indistinguishable from transactions that never read a delayed variable, the largest set there is. Any other value, long or short, is a fingerprint of some size; the only two defensible choices are 86,400 or whatever cluster the network's other compliance tokens settle on.

#### The trade, quantified

| `DELAY` | Freeze / listing bites after | Validity window for proving and inclusion | Privacy set |
|---:|---|---|---|
| **360 s** (today) | 6 min | 6 min: tight for a phone, a congested mempool, or a batch | alone, unless other contracts copy the same example |
| 3,600 s | 1 h | 1 h: comfortable | small; nothing known uses it |
| 21,600 s | 6 h | 6 h | the library's pause example |
| **86,400 s** | 24 h | 24 h, the protocol maximum | the largest: every contract with no delayed reads, plus `token_blacklist_contract` |

Compliance wants the first column short; privacy and usability want the other two long; no value serves both, and the current one sits at the compliance end without having weighed the other two. The emergency lever the token already has changes the weighing: the **pause is immediate** (`PublicMutable`, decided under H-3), so a targeted freeze that would take `DELAY` to bite can be preceded by a pause that stops all transfers at once. With a long delay the compliance playbook for a sanctioned holder becomes *pause → freeze → wait `DELAY` → unpause*, at the cost of halting every holder for `DELAY`; at 24 hours that is a full trading day for one freeze, at one hour it is tolerable. The freeze window itself, the interval in which the target can still move funds, is the same as today's problem at a different scale, and the assessment's existing note ("a user who knows they are going to be blacklisted before the delay elapses might send their funds… This problem has no solution for now") applies at every value.

#### What could be changed

Five options, from the cheapest to the most structural.

1. **Raise the constant.** One line in `enforcementModule.nr` and one in `validationModule.nr`. `DELAY` is a type parameter, not storage, so the layout does not move; it is a redeployment like any change. Every Noir test that waits `CHANGE_ROLES_DELAY_SECONDS` adapts automatically (the TXE advances time). The e2e suite was thought not to, on the belief that a sandbox clock could not be fast-forwarded, which would have made a 24-hour constant cost a day per run. That belief was wrong and was corrected on 2026-09-23: the suite warps the chain, so the constant no longer bounds the runtime. The workable answer is a test build with a short constant (a second value selected at compile time), accepting that the test artifact is a different contract class from the production one; the alternative, deploying at 360 and raising at runtime, is option 3 and only reaches one of the four variables.
2. **Keep 360 and document it as a choice.** The README currently states the value as a fact; the reasoning belongs beside it, with the three facts this section adds: the transaction expiry, the fingerprint against a 24-hour neighbourhood, and the proving budget on a phone. A wallet integrating the token should also be told that its transactions expire six minutes after the anchor, so that it re-anchors before proving rather than after.
3. **Make the delay adjustable at runtime.** The library supports it: `schedule_delay_change(new_delay)` on a `DelayedPublicMutable`, with an asymmetry the docstring explains: an *increase* takes effect at once (nothing already scheduled can land earlier than promised), a *decrease* is itself delayed by the difference. A `set_delay(new)` entry point under `DEFAULT_ADMIN_ROLE` would let the issuer lengthen the delay after deployment, and shorten it with notice. The catch is the maps. `issuer_address` and `operationsFlag` are single instances and can be adjusted in one call; the freeze and list flags are `Map<AztecAddress, DelayedPublicMutable<…>>`, and the delay is stored **per entry**, so a global change would have to visit every address that has ever been scheduled, and untouched entries keep the compile-time initial value. A variant that works: each `freeze` / `add_to_list` / `remove_from_list` first applies the contract's current delay setting to *that* entry (`schedule_delay_change`, then `schedule_value_change`), at `2N + 2` extra `SSTORE`s per write, so entries converge to the setting as they are touched; until they all have, two entries with different delays give two different expirations, a transient fingerprint the section above already argued against. Useful for `issuer_address` today, awkward for the maps, and no substitute for choosing the initial value well.
4. **Remove the issuer read from the private path.** Every value-moving function reads `issuer_address` privately to know where to send the copies. If the issuer were a `PublicImmutable`, that read would not set an expiry and would cost ~4,000 gates less; `set_issuer` would go, and a rotation would be a redeployment. It does not change the token's delay, because the flags are still read, so on its own it buys nothing for H-6; it is listed because it is the one read that could leave the delayed set, and because the rotation feature (0.3.0) is what keeps it there.
5. **Check freeze and lists in the public half instead.** The pause is checked in the enqueued `_transfer` precisely so that it can be immediate. Doing the same for the freeze and list flags would make them immediate too and remove every delayed read from transfers, at the price H-1 and H-3 already priced: the public half would need `from` and `to` as arguments, and publish them. Hashing the addresses does not help, since the set of addresses is public and a hash of one is a lookup. This is the design the token exists to avoid; it is here so that the trade is written down, not as a proposal.

**Recommendation.** Decide between two coherent positions and write the reasoning into the README:

- **Privacy-first: 86,400 s**, the protocol maximum. The token's transactions join the largest privacy set, proving and inclusion have the protocol's full window, and the freeze window is covered operationally by the immediate pause (`pause → freeze → wait → unpause`) or accepted as the 24-hour exposure the assessment already documents in kind. Requires the e2e test build with a short constant. This is what the framework's own compliance token does.
- **Compliance-first: keep 360 s**, and state what it costs: a six-minute proving-and-inclusion budget that a wallet must be designed around, and a transaction shape that identifies the token on any network where the neighbours use the protocol's defaults.

An intermediate value (an hour, six hours) buys a shorter freeze window at the price of a privacy set that has to be shared with someone, and nothing known shares it; it should be chosen only if a measured population of contracts on the target network clusters there. Either way, add `set_delay` for `issuer_address` (option 3, the single-instance case) so that the one variable that can be tuned after deployment can be, and keep a single value across the four variables. The number that would settle the choice is still the one the 0.3.0 report asked for and nobody has: how long a transfer takes to prove on the devices the token's holders will use.

#### Applied after the review (2026-09-18): one hour, adjustable

The project chose the intermediate position, **3,600 s**, with the runtime setter, i.e. options 1 and 3 together:

- `CHANGE_ROLES_DELAY_SECONDS = 3600` in `enforcementModule.nr` and `validationModule.nr`; the three tokens re-export the library's constant instead of carrying a third copy, so there is one value. The comment on the constant records the reasoning (the 360 s example it replaced, the 24 h reference token, the library's guidance).
- A `roles_delay: PublicMutable<u64>` setting, appended **last** in every storage struct so no existing slot moves (the private-balance slot stays 22, pinned), initialised by the constructor to the constant; `set_roles_delay(new_delay)` (`DEFAULT_ADMIN_ROLE`, `1..=86400`) writes it, calls `schedule_delay_change` on the single instances (`issuer_address`, and `operationsFlag` where the variant has lists) and emits `RolesDelayChanged { new_delay, operator, effective_at }`; `roles_delay()` reads it. The upper bound is `MAX_ROLES_DELAY_SECONDS = 86400`, the protocol's transaction lifetime: a longer delay widens no validity window.
- The per-address maps are handled as the section proposed: `freeze`, `unfreeze`, `add_to_list` and `remove_from_list` take the setting as a `delay` argument, call `schedule_delay_change(delay)` on the entry and then `schedule_value_change`, through one library helper `schedule_with_delay`, and **return the scheduled `effective_at`**, which the events now carry instead of `now + constant`. Cost: `2N + 2` extra `SSTORE`s per write, in public. Entries converge to the setting as they are written; an untouched entry keeps its previous delay.
- The library's asymmetry holds and is tested: an increase applies at once (`a_longer_delay_applies_at_once_to_the_issuer`, `a_freeze_adopts_the_current_setting`), a decrease only after the difference (`a_shorter_delay_takes_effect_after_the_difference`, `once_current_the_shorter_delay_governs_the_next_write`), plus the role, the bound and zero refused; three tests per authorization crate for the same surface. The pause has no delay to adjust: it is a `PublicMutable` and immediate by the H-3 decision, which is what makes the *pause → freeze → wait → unpause* playbook work at any delay.
- The e2e suite's wait moved from 360 s to 3,600 s (one wait after deployment). It is no longer a wait: since 2026-09-23 the suite warps the chain instead, the clock claim in H-10 being wrong. Two authorization events and one token event changed shape only in the source of `effective_at`, not in their fields; the ABI gains `set_roles_delay`, `roles_delay` and `RolesDelayChanged` in the five contracts.

What the change does **not** settle is the privacy-set question: at one hour the token's transactions expire an hour after their anchor, a value nothing known on the network shares. The setter is the answer to that: the day the neighbours' delays and the holders' proving times are known, the issuer moves the setting (upwards, at once) without a redeployment.

**Correction to the privacy-set argument (2026-09-18).** The fingerprint the sections above attribute to the delay is dominated, for this token, by a leak the 0.3.0 review's H-3 already accepted: every value-moving operation enqueues a public call whose target is this contract (`_transfer()`, `_mint(minter, amount)`, `_burn(burner, amount)`, `_credit_public` / `_debit_public`, and the authorization hook's `is_burn` call). An observer therefore reads "this token, this operation" from the public call before it reads any expiry, and the expiry adds nothing about *which* contract at any value of the delay. Two consequences. The choice of delay is a compliance-window versus proving-budget trade only, which the one-hour setting was in fact made on; and H-3 and H-6 are one decision, not two: an immediate pause spends the privacy the delay could protect, a delayed pause (a `DelayedPublicMutable` at a few slots or more, never zero, since a zero delay makes every reading transaction unincludable) would give it back for transfers only, at the price of a slow emergency lever. Mints and burns keep a public half in every design, because the role check and `total_supply` are public state. The residual leak the delay carries at any value is timing: `expiration_timestamp − delay` is the anchor block the sender proved against. The README's *What each operation publishes* and its FAQ state this.

### H-7. Public-call fingerprint, extended — keep

| Private entry point | Public calls enqueued | Public arguments |
|---|---:|---|
| `mint_to_private`, `mint_batch` | 1 | minter, amount |
| `transfer_private_to_private`, `transfer_batch`, `transfer_private_to_commitment` | 1 | *none* |
| `burn`, `burn_batch` | 1 | burner, amount |
| `transfer_private_to_public`, `…_with_commitment` | 1 | public recipient, amount |
| `transfer_public_to_private` | 1 | public sender, amount |
| `initialize_transfer_commitment`, `cancel_authwit` | 0 | — |

Every value-moving entry point enqueues exactly one public call, so the count does not distinguish them; the callee's selector does, as 0.3.0's H-3 records and `doc/README.md` states. The two zero-call entry points move no value. No L2→L1 messages anywhere. **Keep.**

### H-8. What the bridges publish — verified

Traced every argument of the two new public halves. `_credit_public(to, amount)`: the public recipient and the amount — the credited balance is public state, so both are observable regardless. `_debit_public(from, amount)`: the public sender and the amount — same reasoning. Neither receives the private party. `transfer_private_to_commitment` enqueues the argument-less `_transfer()`; `initialize_transfer_commitment` enqueues nothing and its private log goes constrained to the issuer only. This is exactly the disclosure `doc/README.md` promises ("the mover's own side"), and each public half carries a `PRIVACY:` comment saying which argument must never be added. **Verified.**

### H-9. The completion amount is public — keep

`complete_from_private` emits the completion as a log tagged by the commitment with `[storage_slot, value]` in clear — the library's design, not this project's. An observer learns the amount and cannot link it to a party without the commitment's preimage. Disclosed in `doc/README.md`, the standards documents and the assessment's privacy discussion. **Keep**; it is the price of the partial-note pattern.

### H-10. Issuer processing of offchain copies — root cause found; fix and tests laid out

**The finding.** The design's hard requirement is that the issuer can reconstruct every balance. K-2 proves each note movement emits an offchain message *addressed to the issuer* (one per mint or burn, two per transfer, following a rotation). What no test proved is that the issuer's PXE can *do anything with them*. The 0.3.0 README states the belief the code was built on: an onchain copy to a non-owner "breaks discovery" because "note discovery computes the note's nullifier, which needs the owner's nullifier key", and "delivering the issuer's copy offchain sidesteps that". This section checks that belief against aztec-nr v5.2.0 and the PXE, finds it half right, and sets out what can be done.

#### What the code does with a copy of someone else's note

Onchain and offchain messages are processed by the **same** function. `sync_state_with_secrets` (`messages/discovery/mod.nr`) first processes the tagged logs fetched from the node, then, if an offchain inbox exists, every message the recipient handed to `offchain_receive`, and both go through `process_message_ciphertext` → `process_private_note_msg` → `attempt_note_discovery` → `attempt_note_nonce_discovery`. Offchain delivery changes *how the ciphertext reaches the PXE* (a call to `offchain_receive` instead of a tag query), not what happens to it afterwards.

In `attempt_note_nonce_discovery` (`messages/discovery/nonce_discovery.nr`), after the note hash has been matched against the transaction's unique note hashes, the note's nullifier is computed through the contract's `compute_nullifier_unconstrained`, which for `UintNote` is `try_get_public_keys(owner).map(|pk| get_nhk_app(pk.npk_m_hash))`. Two outcomes, depending on what the issuer's PXE knows about the holder:

| Issuer's PXE state | `try_get_public_keys(holder)` | Then | Result for the copy |
|---|---|---|---|
| Holder's complete address **not registered** | `None` | `compute_nullifier_unconstrained` returns `None` | The library logs `Unable to compute nullifier of unique note … skipping PXE insertion` and **drops the note**. The comment above that branch reads: "TODO: down the line we want to be able to store notes for which we don't know their nullifier, e.g. notes that belong to someone that is not us … https://linear.app/aztec-labs/issue/F-265/store-external-notes". |
| Holder's complete address **registered** (as a sender or contact) | `Some(keys)` | `get_nhk_app(npk_m_hash)` → PXE `KeyStore.getKeyValidationRequest` → `getKeyPrefixAndAccount` scans the key store, which holds secrets only for the PXE's own accounts | The key store **throws** `Could not find key prefix.`; the oracle call fails inside `sync_state`, so the issuer's sync of this contract aborts — including for the issuer's own notes. |

So the README's premise is right (the nullifier needs the owner's key) and its conclusion is wrong: offchain delivery does not sidestep it, because the offchain path reaches the same line. At 5.2.0 **a stock PXE cannot store a note it does not own, by either delivery mode**, and the framework says so in a TODO. The copies are not useless — the issuer holds the keys to decrypt them, and custom tooling can decrypt a message, recompute the note hash and prove its membership in the tree — but nothing in `@aztec/pxe` does that today.

Two further facts change what "the issuer's audit trail" rests on:

- **Spent status is invisible even with the copies.** A stored copy would tell the issuer that a note *was created* for a holder, never that it was *spent*: the nullifier is `H(note_hash, nhk_app)` and unlinkable without the holder's key. A ledger of creations is not a balance. Only the constrained **`Transfer` event** (H-4), delivered to the issuer with `from`, `to` and `amount`, gives the movements; replaying mint, transfer and burn amounts is what reconstructs a balance. The note copies can at most *corroborate* the events (the preimage of a note the event says was created).
- **Offchain copies depend on the sender forwarding them.** An offchain message is returned to the *sender's* wallet as an `OffchainEffect` of its own simulation; nothing on chain carries it. The holder's software has to transport `(ciphertext, recipient, tx_hash, anchor_block_timestamp)` to the issuer and the issuer has to call `offchain_receive`. A holder that does not forward is undetectable on chain, which the README already notes; combined with the previous point, the onchain constrained `Transfer` event is the only record the issuer gets without the holder's cooperation. Private events have no owner and no nullifier, so the issuer's PXE **can** process them: `process_private_event_msg` validates the event commitment against the tree and stores it, with no key lookup on any other party.

#### Can it be fixed?

Four routes, from cheapest to least available:

| Route | What it is | Available at 5.2.0 | What the issuer gets | Cost |
|---|---|---|---|---|
| **A. Events as the ledger** | Treat the constrained `Transfer` event stream as the audit record it already is; add constrained private events to the issuer for **mint** and **burn** (today `_mint` / `_burn` only touch `total_supply` in public, so the issuer learns amounts from the public `total_supply` delta and the holder from its note, but no per-holder private record reaches the issuer) | Yes | Every movement with parties and amounts, on chain, unforgeable, processable by a stock PXE; balances by replay | Two more constrained event deliveries per mint / burn (about 20,200 gates each by the 0.4.0 measurement); the issuer reads `getPrivateEvents` |
| **B. Custom audit message + capsule ledger** | Deliver the issuer's copy as a **custom message** (`custom_msg_type_id(0)`, `encode_message`, `do_private_message_delivery`) instead of a private-note message, and register a `custom_message_handler` (`#[aztec(AztecConfig::new().custom_message_handler(…))]`) that recomputes the note hash, checks it against `resolved_tx.unique_note_hashes_in_tx` with the public `compute_note_hash_nonce` / `compute_siloed_note_hash` / `compute_unique_note_hash`, and stores `(owner, unique_note_hash, value)` in a **capsule** keyed by owner; a `#[external("utility")] fn audit_notes_of(holder)` reads it back | Yes — the framework ships `custom_message_contract` as the reference for exactly this handler-plus-capsule pattern | A verified list of every note created per holder, processable by a stock PXE, without the holder's keys; still no spent status (see above) | One custom handler per variant (about 60 lines, shareable through a library function), one custom message per note instead of a note message (same size), tests through `env.offchain_messages()` + `offchain_receive` in the TXE |
| **C. Upstream F-265, "store external notes"** | The library stores notes whose nullifier it cannot compute | No (TODO in the source, no date) | The same as B, done by the framework, with the note in the note store rather than a capsule | None here; unknown timing |
| **D. Share the app-siloed nullifier key** | The holder gives the issuer `nhk_app` for this contract (the README's "app-siloed key" alternative), letting the issuer compute nullifiers and so see spends without being able to prove a spend (the kernel's key validation needs the master key) | No — the PXE key store has no notion of a viewing-only app-siloed key for another address; it would need a custom PXE and a key-sharing protocol | Full per-holder ledger including spends | A new trust relationship (the issuer learns every spend), custom PXE, no framework support |

**Recommendation.** A is the honest description of what already holds and closes the largest gap for a small, measurable cost: the `Transfer` event already does the work for transfers, and mint and burn are the two movements the issuer currently learns only in aggregate. B is worth doing if the issuer needs note-level corroboration (for example to prove to a third party that a specific note exists), and it is the route that makes the existing offchain copies *processable* instead of decoratively delivered. C and D are not decisions this project can take. Whichever is chosen, the README sentence "delivering the issuer's copy offchain sidesteps that" should be corrected to what the code does: the copy arrives, is decryptable by the issuer, and is dropped by a stock PXE.

#### How the tests would be implemented in this project

Two tests, one per environment, because the TXE cannot reproduce the situation and the e2e suite can.

**Why the TXE cannot prove or disprove H-10.** The TXE runs one PXE and one key store for every account of a test. When the issuer scope ingests the holder's copy through `offchain_receive`, `try_get_public_keys(holder)` succeeds and `get_nhk_app` finds the holder's secret in the shared store, so the note is accepted and stored — for the holder, whose note it is. A green TXE test would say nothing about an issuer that does not hold the holder's keys. What the TXE *can* pin is the framework's behaviour on the path (that the copies are decryptable and match the tree) and the ingestion call itself; the reference token's `transfer_in_private_with_offchain_delivery_updates_both_balances` test is the model, with the shape `env.offchain_messages()` → batch of at most `MAX_OFFCHAIN_MESSAGES_PER_RECEIVE_CALL` → `env.execute_utility(Token::at(token).offchain_receive(batch))`; K-2's tests already use the first of those calls to count the copies and check their recipient.

**The e2e test that answers the question** — `src/test/e2e/issuer_audit.test.ts`, on a sandbox, built from the two-PXE setup that `scripts/multiple_pxe.ts` already contains:

1. **Two PXEs, two wallets.** PXE A holds the holder's account; PXE B holds only the issuer's account. Deploy `CMTATAztec` from B with the issuer as issuer and admin; grant `MINTER_ROLE`. Register the token's artifact in both PXEs.
2. **Mint and transfer from A.** `mint_to_private(holder, 1_000)` from the issuer (on B), then `transfer_private_to_private(holder, other, 100, 0)` from the holder (on A), capturing the interaction's `OffchainOutput`: `offchainMessages` filtered to `recipient == issuer`.
3. **Forward the copies to B.** `token.methods.offchain_receive([{ ciphertext, recipient: issuer, tx_hash, anchor_block_timestamp }]).simulate({ from: issuer })` on B, in batches of 16, exactly as the *Offchain message delivery* documentation shows.
4. **Sync B and observe.** Three assertions, each of which is a fact today rather than a wish:
   - `balance_of_private(holder)` executed as a utility on B returns **0** (the copy was dropped, first row of the table above), and B's log contains `skipping PXE insertion`; if the holder's complete address was registered on B beforehand (`registerSender`), the sync instead **throws** `Could not find key prefix.` (second row) — the test should cover both, since an issuer that registers its holders as senders, which is the natural thing to do, hits the worse case.
   - `getPrivateEvents(Transfer, { contractAddress: token, scopes: [issuer] })` on B returns the transfer with `from = holder`, `to = other`, `amount = 100`: the event path works for a non-owner.
   - `balance_of_private(holder)` on A returns 900: the holder's own view is unaffected by anything the issuer did.
5. **After A or B is implemented**, the first assertion flips: with route A, B's events also carry the mint (and a burn, if the test adds one); with route B, `audit_notes_of(holder)` on B returns the change note and `audit_notes_of(other)` the payment note, both with hashes present in the tree.

Two practical notes for whoever writes it. The test has to clear `CHANGE_ROLES_DELAY_SECONDS` after deployment before the first mint. **Correction (2026-09-23):** this section said the sandbox clock could not be fast-forwarded and that the test therefore had to wait it out. It can: a local network's L1 is anvil, and `RollupCheatCodes.advanceToSlot` warps it while `EthCheatCodes.syncDateProvider` brings the client's clock along. The suite now does that (`src/utils/time_travel.ts`) and sleeps only against a real network. And `getPrivateEvents` needs the event's metadata from the generated artifact (`CMTATAztecContract.events.Transfer`), which `yarn codegen` produces.

**Status.** Root cause established from the source; the auditability claim is delivery-proven (K-2), event-processable by construction, note-processable **not** — and not fixable inside the PXE at 5.2.0 without route B. The e2e test has not been run (no sandbox in this review).

**Route A applied after the review.** `mint_to_private`, `mint_batch` (one per recipient), `burn` and `burn_batch` (one for the batch total, since the batch debits one account) now emit `Transfer` with the zero address on the private side's slot — the ERC-20 / AIP-20 convention — delivered `onchain_constrained` to the issuer, in all three variants. The `Transfer` stream is therefore a complete ledger of movements the issuer's PXE can process without anyone else's keys. Verified:

- `tests/cmtat-aztec/src/test_issuer_records.nr`, four tests. The TXE cannot read a private event's content, so each test counts what the event leaves in the transaction (`aztec::test::helpers::txe_oracles::get_last_tx_effects`): one private log and two nullifiers (the event commitment and the constrained delivery's sequence nullifier). Each operation runs twice and the second transaction is measured, because a first contact also creates the handshakes tagging needs and their notes, logs and nullifiers would make the counts depend on delivery order. Measured without the event, a warm mint leaves 1 note, 1 log, 2 nullifiers; with it, 1 note, 2 logs, 4 nullifiers.
- Mutants: removing the four `emit`s in the base contract fails all four tests.
- Gates: `mint_to_private` +24,086, `burn` +23,703, `mint_batch` +86,085 (four events), `burn_batch` +21,357 (one event), see the baseline table; the batch caps hold (`mint_batch` at 4 carries eight constrained deliveries, the count `transfer_batch` at 2 already carried).
- The README's *Events* and *Limitations* sections corrected as recommended above.

Route B stays available if note-level corroboration is ever needed; the two-PXE e2e test described above is still the one that would demonstrate, on a real PXE, the drop of the note copy and the processing of the events.

### J-2. Tests in contract crates — corrected, then fixed

The 0.3.0 report corrected an earlier claim with "it does not warn at 5.2.0 … a full `aztec-nargo compile --workspace` produced 33 warnings, none mentioning tests". That run used `aztec-nargo`, which at 5.2.0 is a bare `nargo`. **`aztec compile` — the command the project actually uses — does warn**: `checkNoTestsInContracts` in the CLI runs `nargo test --list-tests` after every compile and prints `WARNING: Found tests in contract crate(s):` followed by every test in a `type = "contract"` package (`compile.js`, `@aztec/aztec` 5.2.0). This review saw the list for all five contract crates. The consequence the 0.3.0 report named — every test-only edit recompiles the contract — also stands, and with 187 tests it is felt. **Fixed after the review** (same day), following the layout the Aztec docs recommend (*Testing Contracts → Keep tests in the test crate*: `aztec new` scaffolds a contract crate and a sibling `type = "lib"` test crate; "a contract's compiled artifact depends on everything in its crate, so a test-only edit forces the contract to recompile even though its logic has not changed"). Each contract's `src/test.nr` + `src/test/*.nr` became `tests/<contract>/src/lib.nr` + `src/*.nr` in a crate named `<contract>_test` that depends on the contract, on the library and on `test-helpers/`; `crate::test::utils` → `crate::utils`, `crate::CMTATAztec` → `cmtat_aztec::CMTATAztec`, `env.deploy("CMTATAztec")` → `env.deploy("@cmtat_aztec/CMTATAztec")`; `mod test;` and the `cmtat_aztec_test_helpers` dependency left the contract crates. Thirty files moved with `git mv`, no test changed. Verified: `aztec compile --workspace` no longer prints the warning; `aztec test --workspace` 216/216 (the five contract packages now report 0 tests each, the five test crates the former counts); and the stated benefit is real — appending a comment to `tests/cmtat-aztec/src/test_mint.nr` and running `aztec compile` left the mtimes of all five `target/*.json` unchanged. The `@crate/Contract` deploy strings, named as the risk, are pinned by the `setup*` helpers in each crate's `utils.nr`.

### J-4 / K-1. `default-member` — fixed (see K-1)

## K. Tests — correctness, coverage and edge cases

There is no line or branch coverage tool for Noir contracts under the TXE at 5.2.0; no percentage below comes from a tool. Coverage is an inventory — entry points, assert messages, `if`/`else` branches — checked against the tests by script and by hand. Correctness is a mutation check: a change that should break a test, and whether it did.

### K-1. `aztec test` compiled one contract of five — fixed

`aztec test` runs a bare `aztec compile` before `nargo test`, and a bare `aztec compile` in a workspace compiles the **`default-member`** only. `Nargo.toml` declared `default-member = "contracts/cmtat-aztec"`. So after any edit to `lib/`, `yarn test:nr` (`aztec test --workspace`) rebuilt `CMTATAztec` and ran the other four contracts' tests against whatever artifact `target/` held — up to date only if `yarn compile` had run since. Found the hard way: a mutant in `authorizationHookModule.nr` (K.1 below) survived `aztec test --package cmtat_aztec_auth` twice while `Compilation complete!` was printed and the auth artifact's mtime did not change; an explicit `aztec compile --package cmtat_aztec_auth` then killed it. **Fix:** the `default-member` line is removed; a bare `aztec compile` now rebuilds all five artifacts (verified by mtime after `touch`ing a library file), and the same mutant dies under `aztec test` with no explicit compile. `yarn compile` (`--workspace`) is unaffected. This also explains why the 0.3.0 mutation of `tokenModule`-era code was always caught: it lived in the default member.

### K.1 — Correctness: mutation spot-checks

Five mutants, each a one-line change to a library module, each followed by the tests that should catch it. `aztec compile` was forced before each run once K-1 was understood.

| # | Mutant | Test(s) expected to fail | Result |
|---|---|---|---|
| 1 | Drop `assert(!is_frozen(to))` from `FreezeAndLists::transfer` | `transfer_restricted_when_freezed`, `private_to_public_reverts_for_frozen_recipient` | **killed** — both "passed when they should have failed" |
| 2 | Drop `deliver_to(issuer, offchain())` from `credit_private` | `transfer_private_check_issuer_view`, `mint_private_success` | **survived** → K-2 |
| 3 | Invert `require_transfer` to `assert(pause.is_paused())` | `transfer_when_paused_fails` | **killed** |
| 4 | `is_burn_selector` returns `false` (every hook call treated as a transfer) | `burn_passes_when_paused` (auth) | **survived** against the stale artifact → K-1; **killed** once recompiled |
| 5 | Drop `screening.recipient(to)` from `open_commitment` | `frozen_recipient_cannot_open_a_commitment` | **killed** |

Two of five survived on first run, for two different reasons, both now fixed and both re-verified as killed.

**Message attribution.** Every `should_fail_with` string was checked against the assert it is meant to reach: the 15 `AccessControlUnauthorizedAccount` tests all intend the role check (`*_requires_role`, `*_by_non_admin_fails`, `test_pause_roles`, …); the 4 `Balance too low` tests grant the role before over-spending; the 4 `Unknown auth witness` tests are the on-behalf-of paths without or with the wrong authwit. No test was found to pass on an earlier, unintended assert. **Delayed state**: every freeze/list test advances past `CHANGE_ROLES_DELAY_SECONDS` before asserting the new value; the before-delay twin existed only in the auth crates and is added to the base suite in K-3. **Discovery**: balance assertions go through `balance_of_private`, so note discovery is exercised — including for completed partial notes. **Tautologies**: none found. **Isolation**: every test builds its own `TestEnvironment`.

### K-2. The issuer-copy invariant had no test that could fail — fixed

Mutant 2 removed the issuer's copy of every note created and the suite stayed green. `transfer_private_check_issuer_view`, despite its name, asserts the *holders'* balances; nothing read anything from the issuer's side. The TXE exposes `env.offchain_messages()` — the offchain effects of the last call, each with its `recipient` — so the invariant is assertable mechanically. `test_issuer_copies.nr` (4 tests): a mint emits exactly one offchain message and it is addressed to the issuer; a transfer emits two (change note, recipient note); a burn one; after `set_issuer` and the delay, the copies go to the new issuer. Re-applying mutant 2: three of the four fail. What the tests do **not** prove is processing on the issuer's side — H-10.

### K.2 — Coverage by inventory

Entry points are counted from `#[external]` declarations; "tested" means called by at least one test in that crate (the chains are shared, so a Debt or Light entry point exercised only in the base suite is *not* counted for the variant — the residue that K-4 guards is exactly those declarations).

| Contract | Entry points | Called by a test | Not called | Tests |
|---|---:|---:|---|---:|
| `CMTATAztec` | 53 | 49 | `cancel_authwit`, `renounce_role`*, `private_get_name`*, `private_get_symbol`* (*now covered by K-3) → **1** | 111 |
| `CMTATAztecDebt` | 58 | 19 | the 34 shared declarations + the 5 debt-specific views; K-4 pins the 14 shared selectors | 12 |
| `CMTATAztecLight` | 49 | 14 | 30 shared declarations; K-4 pins 14 selectors | 7 |
| `CMTATAztecAuth` | 22 | 15 | `only_role`, `revoke_role`, `renounce_role`, `get_operations`, `remove_from_list`, `get_frozen`, `unfreeze` | 29 |
| `CMTATAztecAuthMultiToken` | 22 | 15 | same seven | 28 |

**Asserts with a negative test** — 29 distinct assert messages in the library and the base contract, before this review 14 had a `should_fail_with`; after K-3, **21**. The eight without:

| Assert | Where | Verdict |
|---|---|---|
| `Storage slot 0 not allowed…` | every module's `StateVariable::new` | acceptable — the `#[storage]` macro allocates from 1; a downstream hand-written slot 0 is the only caller and the assert is its guard |
| `Accounts and values arrays mismatch`, `Mint module empty` | `tokenModule` | **removed** (D-3) — could not fire |
| `Revoke Role: Cannot revoke role from self`, `Renounce Role: Addresses do not match`, `invalid admin`, `error: address already freezed`, `error: address already unfreezed` | access control, constructor, enforcement | **covered** (K-3) |
| `The sender is in the blacklist` on the *commitment payer* path (`operateOnFrom` via `pay_commitment`), `The recipient is in the blacklist` on the *commitment opener* path (`operateOnTo`) | validation, reached only through the bridges | **covered** (K-3) — the messages had tests, but only on the transfer path |
| (auth crates) `unfreeze` refusal, `remove_from_list` | enforcement / validation through the auth surface | must cover — mechanical, same shape as the token tests; not written here |

**Branches, both sides** — the library has 16 `if`/`else` sites. `authorizationHookModule::require_lifecycle_allows` (`is_burn`): both sides tested (`burn_passes_when_paused`, `private_transfer_reverts_when_paused`). `validationModule`: the four `operateOn*` functions each branch on `operate_blacklist` / `operate_whitelist` / neither — transfer: all three (`transfer_when_blacklisted`, `transfer_when_not_whitelisted`, `transfer_when_no_operations`); mint and burn: blacklist and whitelist sides (`mint_to_blacklisted_fails`, `mint_to_non_whitelisted_fails`, `burn_from_blacklisted_fails`), neither-side implicit in every default-mode test; `operateOnFrom` / `operateOnTo`: blacklist side now tested on the commitment paths (K-3) and whitelist side by `unlisted_recipient_cannot_open_a_commitment_under_whitelist`; the `UserFlags` / `SetFlag` bit packing (six `if`s) is exercised by every list test through `add_to_list` → `get_current_value`. No branch with an untested side remains in the library.

### K-3. Guards, delay twin, edge cases — fixed (12 tests, `test_guards.nr`)

`constructor_rejects_the_zero_admin`; `admin_cannot_revoke_its_own_role` / `admin_can_revoke_another_accounts_role`; `renounce_requires_the_callers_own_address_as_confirmation` / `renounce_with_the_right_confirmation_drops_the_role`; `freezing_twice_reverts`; `unfreezing_an_unfrozen_address_reverts`; `a_freeze_is_not_effective_before_its_delay` (the before-delay twin of `transfer_restricted_when_freezed`); `zero_amount_transfer_is_accepted_and_changes_nothing` (records the current behaviour — CMTAT Solidity accepts a zero transfer too; if the project decides otherwise, this test is the one that changes); `a_blacklisted_recipient_cannot_open_a_commitment`; `a_blacklisted_payer_cannot_complete_a_commitment`; `private_getters_match_the_public_ones`. All twelve passed first run against unmodified code, which for the negative tests means the assert they name is the one that fires.

### K-4. The two smaller variants — fixed

`CMTATAztecDebt` (11 tests) and `CMTATAztecLight` (6) exercised their variant-specific modules and one smoke path each. The chains they share with the base are tested once, in the base suite, which the token-module refactor makes legitimate — but the *declarations* are per variant, and nothing would have noticed a renamed or re-typed entry point in one of them. `test_selectors.nr` in each pins the 14 shared entry points to the base's selectors (the 7 AIP-20 profile values, the 6 bridge values, and `burn` ≠ AIP-20's `burn_private`). A drift in one variant's declaration now fails that variant's suite.

### K.3 — Edge cases

Per family; ✓ has a test, ✚ added in this review, ✗ missing with the test proposed.

| Family | Case | Status |
|---|---|---|
| Zero and identity | amount `0` | ✚ `zero_amount_transfer_is_accepted_and_changes_nothing` |
| | `AztecAddress::zero()` as admin / issuer | ✚ constructor / ✓ `set_issuer_to_zero_fails` |
| | `from == to` | ✓ `transfer_private_to_self` |
| | zero address as mint recipient or commitment completer | ✗ — *design question*: a note owned by the zero address is unspendable (a de-facto burn that leaves `total_supply` unchanged); a zero completer makes a commitment uncompletable but locks nothing. Decide whether to refuse; record under K-5 |
| Note budget | one more than the balance | ✓ 4 `Balance too low` tests |
| | a balance spread over more than 16 notes (`BalanceSet::sub` hard-codes `max_notes = 16`) | ✚ `a_balance_spread_over_more_than_sixteen_notes_cannot_be_spent_at_once` (17 notes → `Balance too low`), and the ceiling turned out lower: `twelve_notes_can_be_spent_in_one_transfer` / `thirteen_notes_exceed_the_per_call_budget` (`push out of bounds`) — K-7 |
| | exactly the balance | ✚ `transferring_exactly_the_balance_leaves_zero` |
| Batches | the cap | ✓ every batch test |
| | the cap plus one | ✓ measured, recorded in the cap comment (a compile-time size, not a runtime test) |
| | the same address twice in a batch | ✚ `the_same_address_twice_in_a_batch_receives_the_sum` |
| | `u128` overflow across the loop | ✓ `mint_private_failure_overflow` |
| Delays | before / after | ✚ before-delay twin; ✓ after |
| | two changes scheduled before the first lands | ✚ `a_second_scheduled_issuer_replaces_the_first` (value is B, copies go to B, none to A) |
| | expiration honoured | not testable in the TXE (no mempool); the e2e suite would need a deliberately slow inclusion |
| Lifecycle | paused / unpaused / deactivated, each operation; deactivate without pause; unpause after deactivate; pause twice | ✓ `test_pause_module.nr`, 17 tests |
| Authwits | self with nonce 0 | ✓ |
| | self with a non-zero nonce | ✚ `the_account_itself_must_pass_a_zero_nonce` (`Invalid authwit nonce`) |
| | third party valid / without approval / wrong caller | ✓ |
| | a consumed authwit replayed | ✚ `a_consumed_authwit_cannot_be_replayed` (`Nullifier collision`) |
| | `cancel_authwit` then use | ✚ `a_cancelled_authwit_cannot_be_used` (`Nullifier collision`; the inner hash is `[from, selector, hash_args(args)]`) |
| Roles | grant / use / revoke / renounce | ✓ and ✚ |
| | the last admin renouncing | ✗ — *design question*: OpenZeppelin and CMTAT allow it; the contract then has no admin forever. Decide whether to refuse; record under K-5 |
| Delivery | note copies to the issuer | ✚ K-2 (count and recipient) |
| | `Transfer` event read by the recipient and by the issuer | ✗ — **not testable in the TXE at 5.2.0**: `get_private_events` / `discover_event` are `pub(crate)`; belongs in the e2e suite with `getPrivateEvents`, alongside H-10 |
| | issuer *processing* of the copies | ✗ — H-10 |
| Partial notes | open by recipient, complete by the completer | ✓ |
| | completion by a party that is not the completer | ✚ `only_the_designated_completer_can_pay_a_commitment` (`reading an unknown nullifier`: the validity commitment for the other completer was never pushed) |
| | complete twice | ✚ measured first as a loss (sender debited twice, recipient holds one payment), then fixed: `a_second_payment_into_the_same_commitment_is_refused`, `a_sender_opened_commitment_cannot_be_paid_twice_either` (`Nullifier collision`), `the_first_payment_into_a_commitment_is_received`; K-6 |
| | complete before the opening is mined | **not observable in the TXE**: every `call_private` mines a block, so the opening is always settled before the next call (tried: the completion passes without `mine_block()`) |
| | recipient frozen or delisted between opening and completion | ✚ `a_recipient_frozen_after_opening_a_commitment_is_still_paid` — records the gap (no expiry, F-1) |
| Public halves | `_transfer` takes no arguments | ✚ `the_public_half_of_a_transfer_takes_no_arguments` (compile-time pin) |
| | a public revert discards private effects | not observable after `should_fail_with` in the TXE (the test ends at the revert); the e2e suite can assert balances after a failed send |
| Constructors and views | re-calling the initializer | ✚ `the_initializer_cannot_be_called_a_second_time` (`duplicate nullifier`: the initialization nullifier) |
| | `view_public` on every `#[view]` | ✓ (typed; a dropped attribute fails to compile) |
| | selectors pinned to the standard | ✓ and ✚ K-4 |
| Storage | private-balance slot unchanged against a baseline | ✚ `the_private_balance_slot_is_pinned` — `STORAGE_LAYOUT_CMTATAztec.fields.private_balances.slot == 22` (the `storage_layout()` getter is not callable from a test; the global is) |

### K-5. Remaining edge cases — fixed for the mechanical rows

Of the fourteen ✗ rows, twelve mechanical ones are now tests in `tests/cmtat-aztec/src/test_edge_cases.nr` (15 tests: the note-ceiling row needed three), and the two untested asserts of the authorization crates got theirs (`unfreeze`: sends again after the delay, not before, refused on an unfrozen address; `remove_from_list`: sends again after the delay, not before, requires `ADDRESS_LIST_REMOVE_ROLE` — 6 tests per crate). One row moved to "not observable in the TXE" after trying it. Two rows are design questions and stay open under K-6 alongside the finding below; two are e2e-only (H-10).

Two of the new tests measured behaviour the code did not state, and both are recorded rather than changed:

- **K-7 — the note ceiling of one transfer is 12, not 16.** `BalanceSet::sub` offers 16, but the per-call side-effect budget is exhausted first: 12 notes pass, 13 to 16 abort with `push out of bounds`, 17 and more fail in `sub` with `Balance too low`. A holder paid in many small notes consolidates with transfers to self, twelve notes at a time; the README's *Batching limits* now says so. F1 (A-5) is the fix, and this test is its acceptance criterion.
- **K-6 — a second payment into the same commitment is lost.** `PartialUintNote::complete` is documented as not single-use ("the recipient only discovers the first completion, so anything carried by further ones is lost"). Two `transfer_private_to_commitment` of 100 into one commitment leave the sender down 200, the recipient with 100 and `total_supply` at 1,000: 100 units are no one's, yet still counted in supply. AIP-20 has the same behaviour. The contract could refuse it — the private half pushes a nullifier derived from the commitment next to the completion, so a second payment is an invalid transaction — at the cost of one nullifier per completion and a departure from the standard's semantics (an earlier draft of this row placed the nullifier in the public half; that would publish the commitment — see `doc/technical/commitment-reuse.md`). Decided and applied the same day: see the K-6 row above and the design note.

## Summary table for K

| Contract | Entry points tested | Asserts with a negative test (library + contract) | Branches both sides | Mutants survived → after fixes |
|---|---|---|---|---|
| `CMTATAztec` | 53 / 53 | 22 / 29 (7 remaining: 1 acceptable, 2 removed, 4 auth-surface or e2e) | 16 / 16 | 2 / 5 → 0 / 5 |
| `CMTATAztecDebt` | 19 / 58 direct + 14 selectors pinned; chains tested in base | shared | shared | — |
| `CMTATAztecLight` | 14 / 49 direct + 14 selectors pinned; chains tested in base | shared | shared | — |
| `CMTATAztecAuth` / `…MultiToken` | 17 / 22 each | 9 / 9 | 1 / 1 | 1 / 1 (stale artifact) → 0 |

---

## What was run, and what was not

**Run.** `aztec compile --workspace` (clean); `aztec profile gates ./target` three times (baseline, after A-4's refactor, after D-3); `aztec test --workspace` — **214 tests passed** (126 base, 12 Debt, 7 Light, 35 + 34 authorization; plus 2 library tests) after the additions, 216/216 from the `tests/` crates after the J-2 move, 218/218 after the K-6 fix (128 base), 222/222 after route A of H-10 (132 base), and 225/225 after A-5 (135 base), and 237/237 after H-6 (143 base, 38 + 37 authorization); five mutation runs with the targeted tests, plus their re-runs after the fixes; the `default-member` experiment (mtime of all five artifacts after a bare `aztec compile`); a scripted inventory of entry points, asserts, branches, `should_fail_with` strings and tested entry points.

**Not run.** `aztec-wallet profile` (needs a sandbox); `yarn test:js`; any test of the issuer's PXE processing offchain messages (H-10).

**Hazards for what this report recommends.** A-5 / F-1 changes how many notes a call consumes, not the note layout — but every value-moving path at once, so the gate profile *and* the note-count edge cases in K.3 should be the acceptance tests. J-2 moved tests, not code; the risk was the `@crate/Contract` deploy strings. Nothing here touches a storage slot; nothing here may be "fixed in an upgrade".

---

*Produced with Claude Code against `aztec` 5.2.0 / `aztec-nr` v5.2.0 / Noir 1.0.0-beta.25, commit `1a7470c`, on 2026-09-16. Findings were verified against the code at that commit; line numbers are not cited for that reason.*
