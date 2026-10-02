> **Superseded for the 0.4.0 release by [`../v0.4.0/CLAUDE_ANALYSIS.md`](../v0.4.0/CLAUDE_ANALYSIS.md)**, which carries the open findings forward (B-3, B-4, F-1, H-6), reopens J-2 (the correction below was wrong: `aztec compile` does warn about tests in contract crates; `aztec-nargo compile` does not) and adds a check on the tests themselves.

# private-CMTAT-aztec — Aztec.nr Code Quality Review

| | |
|---|---|
| Scope | `lib/` (`cmtat_aztec_lib`) and the three contract crates `contracts/cmtat-aztec`, `contracts/cmtat-aztec-debt`, `contracts/cmtat-aztec-light` |
| Commit | `6728a8a` (branch `dev`) |
| Aztec CLI | `5.2.0` |
| `aztec-nr` tag | `v5.2.0` (from `Nargo.toml`) |
| Noir compiler | `1.0.0-beta.25` |
| Date | 2026-09-09 |
| Produced with | Claude Code |

**This is a code-quality review, not a security audit.** Nothing in this report lets an unauthorized party move value, spend another holder's note, bypass a restriction or brick a contract. Every `#[external("public")]` function that services an enqueued private call carries `#[only_self]`; the role check and the pause check are present on every value-moving path; no unconstrained value reaches a constrained assertion. Two items sit on the boundary and are called out where they appear: **A-1** (a duplicated check — wasteful, not unsound) and **H-1** (an address published in a public call's arguments — see below for why its blast radius is small).

**Privacy findings are in section H.** On Aztec that is what a reader looks for first, and it is the section where a correct contract can still defeat its own purpose. The headline is that this contract's private/public split is mostly *right*: `mint` does not publish its recipient, and the enqueued half of `transfer` takes no arguments at all. The residue is in H-1 and H-3.

**A-1, A-2, C-1, C-2, C-3, C-4, C-6, E-1, E-2, G-1, G-2, G-3, G-4, G-6, H-1 and H-4 were fixed after the review** (commit follows this report); every other Outcome below is a verdict, not a record of work done. Two temporary probes were compiled and deleted (B-1, J-1/J-3); the working tree was verified clean afterwards and the baseline gate counts reproduced.

---

## Disposition summary

| ID | Finding | Outcome |
|---|---|---|
| A-1 | Duplicated `is_frozen(from)` read in `burn` — 1,920 gates | ✅ fixed |
| A-2 | Issuer read sat inside the per-address loop | ✅ fixed — cap raised to 4, issuer hoisted, 5,748 gates |
| A-3 | `#[internal("private")]` on the three `_*_internal` helpers | ✅ keep — correct as written |
| A-4 | No runtime-bounded loops, no unconstrained-then-constrained patterns | ✅ nothing to do |
| B-1 | `SetFlag` derives `Packable` (N=2) where `UserFlags` hand-packs (N=1) | ⚠️ **corrected** — measured +7 gates, do not change |
| B-2 | `UserFlags` splits derived `Serialize` from hand-written `Packable` | ✅ keep — this is the documented split |
| B-3 | `CreditEventsStruct` packs two `bool`s into two Fields where Solidity uses one | ⬜ decide — fold into the next storage break, do not schedule one |
| B-4 | `PauseModule` uses two one-`bool` slots | ⬜ leave — hot and cold flags, sharing would tax the hot read |
| C-1 | `transfer_batch` emits no `Transfer` event; `transfer` does | ✅ fixed |
| C-2 | `Transfer` delivered `onchain_unconstrained()` to `to` only | ✅ fixed — D adopted |
| C-3 | `set_terms` emits nothing; `set_token_id` emits `TokenId` | ✅ fixed |
| C-4 | Constructor configures the contract with no event at all | ✅ fixed |
| C-5 | No undelivered messages anywhere | ✅ checked — clean |
| C-6 | Nine state-changing admin entry points emit nothing | ✅ fixed |
| D-1 | The three `main.nr` files are 99–100% identical | ✅ closed in 0.4.0 — the value-moving chains were extracted into `lib/src/modules/tokenModule.nr` (`doc/technical/token-module.md`); "extraction is not available" held for the entry-point declarations only |
| D-2 | `test/utils.nr` duplicated 75/78 lines across three crates | ✅ fixed (partially, as scoped) — the two contract-agnostic helpers moved to a `test-helpers` lib crate |
| E-1 | `#[view]` missing on four read-only entry points | ✅ fixed |
| E-2 | Getters returning without `pub`, unlike every sibling | ✅ fixed — four, not three |
| E-3 | `#[only_self]`, `#[initializer]`, `#[noinitcheck]` discipline | ✅ checked — clean |
| F-1 | Should this token implement AIP-20? | ⬜ decide — answered: no, but take its note budget (36% of a transfer) |
| G-1 | `mint` NatSpec claims a validation check that does not run | ✅ fixed — by making the code match the comment |
| G-2 | `_burn_internal` asserts `"Frozen: Recipient"` on a burn's sender | ✅ fixed |
| G-3 | `issuer_address` has no setter, but three documents describe changing it | ✅ fixed — setter added |
| G-4 | `EXTRA_INFORMATION_ROLE = 11` missing from role lists | ✅ fixed — three places, not two |
| G-5 | Doc-comment length; no `.md` pointers in contract source | ✅ checked — clean |
| G-6 | `yarn compile` produces artifacts `yarn codegen` cannot consume | ✅ fixed |
| H-1 | `burn` publishes the caller's address and the amount | ✅ fixed — documented, as decided |
| H-2 | `mint` hides `to`; `_transfer()` takes no arguments | ✅ keep — now protected by `PRIVACY:` comments on all three public halves |
| H-3 | The enqueued public selector reveals which operation ran | ✅ decided — option 1: the pause stays a `PublicMutable` checked in public, and the leak is documented; a delayed pause of hours was judged too slow for the emergency lever |
| H-4 | The `Transfer` event: its only unique datum is the sender, to the recipient, and it is delivered unverifiably | ✅ fixed — D adopted; transfer batch cap re-measured and lowered to 2 |
| H-6 | The 360-second delay is an order of magnitude under the library's recommended minimum | ⬜ decide — validity window and privacy set vs. freeze window |
| I-1 | Workspace dependency graph | ✅ checked — clean |
| J-1 | `UserFlagsTrait` / `FreezableFlagTrait` are not `pub` | ✅ fixed — both `pub`, after checking that exposing the extension point beats removing it; a downstream probe with three-flag and reason-coded types compiles |
| J-2 | `#[test]` functions live inside the contract crates | ⚠️ **corrected** — no compiler warning at 5.2.0 |
| J-3 | Module structs are genuinely reusable | ✅ verified by compiling a downstream probe |

**Counts:** 35 rows — 29 ✅ (9 checked/keep, 19 fixed, 1 decided), 2 ⚠️ corrected, 4 ⬜ open (3 *decide*: B-3, F-1, H-6; 1 *leave*: B-4). The *implement* set is exhausted. *Counted from the table; earlier revisions of this line over-stated the row total by one.*

G-6 was not found by reading; it surfaced while regenerating artifacts after the A-1 fix. It is included because it breaks the project's own documented build sequence.

## Outstanding

| ID | Item | Why it is still open |
|---|---|---|
| B-3 | Credit-events packing | Unambiguously correct — Solidity gets the same layout for free, and unlike B-1 no measurement argues against it — but it is a storage break on a variant that only bond issuers deploy. Worth folding into a break that is happening anyway; not worth causing one. |
| F-1 | AIP-20 | Answered in F-1: do not adopt it — public balances defeat the premise and partial notes cannot coexist with recipient screening. Two things remain: state the non-conformance in the README, and treat AIP-20's note budget as a separate optimisation worth a measured 43,046 gates per transfer. |
| H-6 | The delay itself | 360 seconds is far below the library's recommended "couple hours": every value-moving transaction expires six minutes after its anchor block, and a delay shorter than other contracts' is a fingerprint. Against that, a short delay is a short freeze window. Needs the network's typical delay, real proving times, and a compliance call. |

---

## Gate-count baseline

Measured with `aztec profile gates ./target` at commit `6728a8a`, after a clean `aztec-nargo compile --workspace`. **These are per-function circuit sizes for this contract only — they exclude the protocol kernel overhead entirely.**

| Function | `CMTATAztec` | `CMTATAztecDebt` | `CMTATAztecLight` |
|---|---:|---:|---:|
| `transfer` | 120,824 | 120,824 | 110,416 |
| `transfer_batch` | 119,145 | 119,145 | 108,737 |
| `burn` | 83,656 | 83,656 | 83,656 |
| `burn_batch` | 81,736 | 81,736 | 81,736 |
| `mint` | 30,776 | 30,776 | 30,776 |
| `mint_batch` | 30,776 | 30,776 | 30,776 |
| `cancel_authwit` | 6,436 | 6,436 | 6,436 |
| `private_get_issuer` | 8,347 | 8,347 | 8,347 |
| `private_get_name` / `_symbol` | 8,229 | 8,229 | 8,229 |
| `private_get_decimals` | 8,230 | 8,230 | 8,230 |

> The `burn` row is the **pre-fix** baseline. A-1 has since been applied, so `burn` is now 81,736 in all three variants; the row is left at its measured value so the saving below is reproducible.

Three differences in that table are themselves measurements, and each supports a finding below:

| Quantity | Derivation | Gates |
|---|---|---:|
| The validation module's cost on a transfer | base `transfer` − Light `transfer` | **10,408** |
| The `Transfer` event | `transfer` − `transfer_batch` (which does not emit one) | **1,679** |
| The duplicated freeze check in `burn` | `burn` − `burn_batch`, confirmed by removing it | **1,920** |

**What is not measured here.** Whole-transaction cost — `private_kernel_init` / `_inner` / `_tail` plus the account entrypoint — needs `aztec-wallet profile` against a running sandbox, which this review did not start. The reference figures (~290,000 fixed kernel overhead per transaction, ~101,000 per additional private call) are quoted from `writing_efficient_contracts.md`, **not measured**, and are used below only to argue about the *shape* of a change, never as a finding's evidence. Public functions are AVM bytecode and cost gas, not gates; no gate number in this report is quoted for a public function.

---

## A. Circuit cost — private functions

### A-1. `burn` reads the freeze flag twice — `contracts/cmtat-aztec/src/main.nr:562` and `:540`

`burn` checks the sender's freeze flag, then calls `_burn_internal`, which checks it again:

```noir
fn burn(from: AztecAddress, amount: u128, authwit_nonce: Field) {
    assert(!self.storage.enforcement_module.is_frozen(from), "Frozen: Sender");   // :562
    self.internal._burn_internal(from, amount);
    ...
}

fn _burn_internal(from: AztecAddress, amount: u128) {
    assert(!self.storage.enforcement_module.is_frozen(from), "Frozen: Recipient"); // :540
    ...
}
```

Because `_burn_internal` is `#[internal("private")]` it is inlined, so both reads land in the same circuit. `is_frozen` is a `DelayedPublicMutable` read.

**Measured.** Deleting line 562 and recompiling `cmtat_aztec` moved `burn` from **83,656 → 81,736** gates — a saving of **1,920**, and exactly the value of `burn_batch`, which reaches `_burn_internal` without the extra check. That is well under the ~4,000 the docs quote for a `DelayedPublicMutable` read, which is worth stating: the second read of the same slot shares most of its constraints with the first, so the naive "one read = 4,000 gates" arithmetic overstates it by more than 2×. The probe was reverted and the baseline reproduced.

**Consequence.** 1,920 gates of proving time on the user's own device, on every burn, for a check that has already run. Against a whole transaction of roughly 290k+ kernel gates it is ~0.5% — small, but it is free to remove and the removal also fixes G-2.

**Verdict: implement — done.** Line 562 was deleted and the surviving assertion in `_burn_internal` now reads `"Frozen: Sender"` (G-2), in all three variants. Re-profiled after the change: `burn` is **81,736**, exactly matching `burn_batch`, as predicted. The regression test is `burn_batch_restricted_when_freezed` (see G-2); the full suite is 76 tests passing, up from 75.

### A-2. The issuer read sat inside the per-address loop — fixed, and the cap raised to 4

**The finding as written.** `mint_batch`, `transfer_batch` and `burn_batch` call their `_*_internal` helper once per array entry, and because the helper is `#[internal("private")]` it is inlined — so each entry re-executed everything in the body, including reads that are the same for the whole call:

| Read | Varies per entry? |
|---|---|
| `issuer_address.get_current_value()` | **No** — one issuer per call |
| `is_frozen(from)` in `_transfer_internal`, `is_frozen(account)` in `_burn_internal` | **No** — a single sender/debited account |
| `operateOnTransfer`'s `operationsFlag` and sender flags | **No** |
| `is_frozen(to)` and the recipient's list flags | Yes — genuinely per-recipient |

At `MAX_ADDR_PER_CALL = 1` this cost nothing, which is why it did not appear in the baseline. The original verdict was therefore "decide before raising the cap", with the cheap action being to write the dependency into the `MAX_ADDR_PER_CALL` comment.

**What was done instead: the cap was measured and raised.** The comment invited raising the value ("could now be raised above 1") on reasoning that turns out to be wrong in two ways — it cited the 8-nested-private-call limit, which is irrelevant because the helpers are inlined and a batch makes no nested calls at all; and it did not identify transfer as the binding path. So the cap was established by experiment: set the global, adjust the tests, run the full suite.

| `MAX_ADDR_PER_CALL` | Suite result |
|---:|---|
| 1, 2, 4 | all tests pass |
| 5 | `transfer_batch` passes; batched mint and burn finish with a wrong total supply (cause not pinned down — TXE `println` output could not be captured) |
| 6, 8 | `transfer_batch` aborts with `Assertion failed: push out of bounds` — a per-call protocol array overflowing |

**4 is the verified ceiling.** At N=4 the batch tests were rewritten with distinct amounts and repeated recipients (`[user1, user2, user1, user2]` / `[1000, 2000, 300, 400]`) and assert each holder's balance separately, so a dropped, duplicated or misdirected note changes an assertion. All 76 tests pass. N=5 was not adopted: transfer passes there, but two batch tests fail without a protocol error, and an unexplained failure is not a basis for shipping a limit.

**The hoist, measured.** The issuer read was moved out of all three loops and passed into the helpers as a parameter:

| Function | N=1 | N=4, unhoisted | N=4, hoisted | Saved |
|---|---:|---:|---:|---:|
| `mint_batch` | 30,776 | 113,619 | **107,871** | 5,748 |
| `burn_batch` | 81,736 | 312,568 | **306,820** | 5,748 |
| `transfer_batch` | 119,145 | 453,051 | **447,303** | 5,748 |
| `mint` / `transfer` / `burn` | 30,776 / 120,824 / 81,736 | — | unchanged | 0 |

5,748 is exactly 1,916 × 3 — one redundant `DelayedPublicMutable` read per extra address, at almost precisely the 1,920 gates A-1 measured for the same thing. The single-entry paths are byte-for-byte unchanged in cost, confirming the refactor is neutral where there is no loop.

**What was deliberately not hoisted, and why.** The sender freeze check and the validation module's `operationsFlag` and sender-flag reads are also loop-invariant, and hoisting them would save roughly three times as much again. They were left because moving them changes *where a safety check lives*: `CLAUDE.md` states the invariant chain explicitly — "freeze check + validation check in the private internal function, role check + pause check in the enqueued public internal function" — and lifting a freeze check into the batch entry point puts the single-entry and batch paths on different guarantees. The issuer read has no such semantics: it is a value the helper needs, not a check it performs. Hoisting the rest is a real optimisation but it should be a deliberate change to that convention, not a side effect of a gate saving.

**Cost, stated honestly.** Batching moves work rather than removing it: a 4-recipient transfer is a 447,303-gate circuit against 119,145 for one transfer, and that proof is produced on the user's own device. What is saved is the fixed per-transaction protocol overhead that four separate transfers would pay four times (~290,000 each by the framework's figure, **not measured here**). Batch for one transaction, not for a cheaper circuit.

### A-3. The `#[internal("private")]` helpers are the right structure — keep

`_mint_internal`, `_transfer_internal` and `_burn_internal` are `#[internal("private")]`, so the macro inlines them at compile time: no nested call, no extra `private_kernel_inner` iteration. Had they been `#[external("private")]` or `#[only_self]`, each call site would add a kernel iteration — on the order of 101,000 gates per call by the framework's own figure, which is roughly **the whole of `mint`** (30,776) three times over.

The mirror-image structure — splitting unbounded work across `#[only_self]` recursion — is not applicable here: every loop is bounded by `MAX_ADDR_PER_CALL`, a compile-time constant of 1.

**Verdict: keep, and this is worth a comment.** The temptation to "clean up" these three helpers into ordinary private functions is real and the penalty is invisible in the source. One line above `_transfer_internal` saying *this must stay `#[internal]`; making it a private call adds a kernel iteration* would prevent a five-figure regression that no test would catch.

### A-4. Patterns checked and absent

- **No runtime-bounded loops.** Every loop bound is `MAX_ADDR_PER_CALL`, a `global`.
- **No unconstrained-then-constrained computation.** There is no `sqrt`, sort or array-compaction pattern, so the "constraint is incomplete" failure mode does not arise. `balance_of_private` is `#[external("utility")] unconstrained` and its result is returned to the caller, never fed into an assertion.
- **No `self.utility.call(...)` from a private function**, so there is no unproven value crossing into a constrained context.
- **No bit-manipulation or relational operators on a hot path.** The only bitwise code is `UserFlags`/`SetFlag` pack/unpack (`&`, `|` on a `u64`), which runs at most twice per transfer.

**Verdict: nothing to do.** Recorded so the absence is visible as *checked* rather than *not looked at*.

---

## B. Storage, packing and note reads

### B-1. ⚠️ Corrected — `SetFlag`'s derived `Packable` is *not* worth replacing

**The finding as originally written.** `lib/src/modules/validationModule.nr:23` derives `Packable` on `SetFlag`, a struct of two `bool`s, giving `N = 2`. Twelve lines below, `UserFlags` — also two `bool`s — carries a **hand-written** `Packable` with `N = 1`, and `SetFlag` already has the exact bit-packing logic written out in its `ToField`/`FromField` impls. It looked like a copy-paste omission: the pack function exists, it is simply not wired to `Packable`. `SetFlag` lives in a `DelayedPublicMutable`, and the module's storage span is declared as `M + 2` where `M` is the packed length of `DelayedPublicMutableValues<SetFlag, …>`, so a smaller `SetFlag` shrinks the module's slot span too.

**What the measurement showed.** I wired `Packable for SetFlag` to the existing `to_field`/`from_field` (`N = 1`), recompiled `cmtat_aztec`, and re-profiled:

| | `transfer` | `transfer_batch` |
|---|---:|---:|
| Derived `Packable`, `N = 2` (current) | 120,824 | 119,145 |
| Hand-written `Packable`, `N = 1` | 120,831 | 119,152 |

The change made the private hot path **7 gates more expensive**, not cheaper. The bit-packing arithmetic in-circuit costs marginally more than reading one additional field out of the already-hashed `DelayedPublicMutableValues`. The prediction was wrong in sign, if trivially so in size.

**What survives.** The storage-slot argument is untouched by that measurement — `N` really does go 2 → 1, and the module's span shrinks with it, which is fewer `SLOAD`/`SSTORE` in `set_operations` and `get_operations`. **I did not measure public gas**, and the honest position is that a sub-ten-gate private regression against an unmeasured public saving is not a case for a change that moves every storage slot after the validation module.

**Verdict: leave it, and this entry is the reason.** The asymmetry with `UserFlags` looks like an oversight and will be re-proposed by the next reader; the measurement above is what stops that happening twice. If the packing is ever revisited as part of an unrelated storage break, the round-trip test `assert(SetFlag::unpack(x.pack()) == x)` is mandatory — a hand-written pack/unpack is code the derive cannot get wrong, and that assertion is the only thing keeping it honest.

### B-2. `UserFlags` splits its encodings correctly — keep

`UserFlags` (`validationModule.nr:29–35`, `:189`) derives `Serialize`/`Deserialize` and hand-writes `Packable`. That is exactly the split the framework requires and it is easy to get backwards:

- `Serialize`/`Deserialize` is the **ABI boundary**. `UserFlags` is an argument to `add_to_list` and `remove_from_list`, so its serialization must match Noir's intrinsic layout. Hand-rolling it here would produce an "arguments hash mismatch" at call time — a runtime failure, not a compile error.
- `Packable` is the **storage encoding**, internal to the contract, and may be packed freely. It is.

**Verdict: keep.** Worth naming in the report precisely because B-1 makes the opposite change look attractive.

### B-3. `CreditEventsStruct` spends two Fields on two `bool`s — `creditEventsModule.nr:10`

`#[derive(Deserialize, Eq, Packable, Serialize)]` on `{ flagDefault: bool, flagRedeemed: bool, rating: FieldCompressedString }` gives `N = 3`; the two flags could share one Field for `N = 2`.

**What CMTAT Solidity does with the same struct.** The interface is identical (`ICMTAT.sol`):

```solidity
struct CreditEvents {
    bool flagDefault;
    bool flagRedeemed;
    string rating;
}
```

and it occupies **two storage slots**, not three: Solidity's storage layout packs adjacent sub-word fields into one 32-byte slot, so the two `bool`s share a slot (one byte each, thirty wasted) and `string rating` takes its own. CMTAT contains **no packing code whatsoever** — `DebtModule.sol` has no bit manipulation and no packing comment — because the compiler does it. Solidity developers never think about this.

Noir has no equivalent. A derived `Packable` is one Field per field, full stop, and a Field is ~254 bits — the same order as a Solidity slot, so the comparison is fair. **Reaching parity with the Solidity layout means hand-writing `pack`/`unpack`**, which is exactly the asymmetry already visible in the validation module, where `UserFlags` hand-packs two `bool`s into one Field (B-2) and `SetFlag` does not (B-1).

One place where the Noir version is **better** than Solidity, and worth recording so the comparison is not one-sided: `rating` is a `FieldCompressedString`, which is exactly one Field and capped at 31 characters. Solidity's `string` is unbounded, and a rating longer than 31 bytes spills into further slots. Noir is worse on the flags and better on the string.

**Unlike B-1, there is no counter-measurement here — and that matters.** B-1 was rejected because hand-packing `SetFlag` made the *private* transfer path 7 gates more expensive: the bit arithmetic costs more in-circuit than reading one extra field. Credit events have **no private read path at all**. `set_credit_events` and `get_credit_events` are both `#[external("public")]`, and nothing in `_mint_internal`, `_transfer_internal` or `_burn_internal` touches the module. So the trade here is one `SLOAD`/`SSTORE` saved per access against no circuit penalty whatsoever. B-3 is the change B-1 only looked like.

**What the assessment adds: the blast radius is one variant out of three.** The deployment-variants matrix in `doc/cmtat-assessment/README.md` records that credit events (criteria 44–47) exist in `CMTATAztecDebt` only — `CMTATAztec` and `CMTATAztecLight` do not carry the module, so the slot does not exist for them. That mirrors CMTAT Solidity exactly, where `DebtModule` is not part of CMTAT Standard: as the assessment puts it, "an issuer deploying a bond deploys `CMTATAztecDebt`, exactly as a CMTAT Solidity issuer deploys CMTAT Debt rather than CMTAT Standard."

So the wasted slot is paid only by an issuer who deliberately chose the bond variant, on a struct written once at issuance and read occasionally — not on any hot path, and not at all for a plain security token.

**Verdict: decide, and the answer is "fold it into the next storage break, do not schedule one for it".** The change is unambiguously correct — Solidity already gets this layout for free, and unlike B-1 nothing measurable argues against it — but it moves every state variable declared after the credit-events module, and the contract is not upgradeable, so on a deployed token it means a redeployment and a holder migration. The debt realignment in this release is already such a break; folding B-3 into it would have cost nothing. Once 0.3 ships, the saving is one slot on one variant and no longer worth a break of its own.

If it is taken, the round-trip test is mandatory: `assert(CreditEventsStruct::unpack(x.pack()) == x)`. A hand-written pack is code the derive cannot get wrong.

**B-4 — `PauseModule`'s two one-`bool` slots — is the same shape with a weaker case.** Solidity would again pack `paused` and `deactivated` into one slot for free. Here they are two separate `PublicMutable<bool>`, so two slots. But unlike credit events they are read on different paths and at different frequencies — `is_paused` on every mint, transfer and burn; `is_deactivated` only by `unpause_contract` and its getter — so sharing a Field would make the hot read pay for unpacking the cold flag. **Verdict: leave.**

### B-5. Note reads — not applicable, and worth saying why

The `get_notes`-vs-`pop_notes` question, `NoteGetterOptions` limits, and post-retrieval filtering do not arise: this contract never calls the note-getter API directly. All note handling goes through `Owned<BalanceSet>` from the `balance_set` aztec-nr library (`private_balances.at(x).add/sub/balance_of`), which owns those choices. There is no `PrivateMutable` in the storage struct, so the "reading a `PrivateMutable` is a write" contention issue does not apply either.

**Verdict: nothing to do** — but note the flip side. Delegating note handling to the library means the project's note-read efficiency is the library's to change, and a future `balance_set` upgrade can move these gate counts without a line changing here. The baseline table above is what makes that visible.

---

## C. Deliveries, events and messages

### C-1. `transfer_batch` emits no `Transfer` event — `main.nr:478` vs `:495`

`transfer` emits `Transfer { from, to, amount }`; `transfer_batch` performs the same state change and emits nothing.

**Consequence.** Two entry points that move tokens identically leave different trails. Anything built on the event — an issuer's reconciliation, a block explorer, a compliance feed — silently misses every batched transfer. At `MAX_ADDR_PER_CALL = 1` the two functions are the *same operation*, so this is not a batching edge case: it is one of two equivalent paths having no record.

**Measured cost of the event:** 1,679 gates (`transfer` 120,824 − `transfer_batch` 119,145).

**Verdict: implement — done.** `transfer_batch` now emits one `Transfer` per recipient, inside the loop, in the same mode as `transfer`. The delivery mode was deliberately **not** changed here: that is C-2 / H-4 and is still open, and matching the single path is what C-1 is for. If the mode later moves to `offchain()`, both call sites change together.

Measured after the change: `transfer_batch` went 447,303 → **454,050** at `MAX_ADDR_PER_CALL = 4`, so 6,747 for four events — 1,687 each, consistent with the 1,679 the single path costs.

**The budget check mattered here and was not skipped.** Each event delivered `onchain_unconstrained()` is an extra private log, and the batch cap of 4 was itself set by the per-call note-hash and log budgets (A-2). Four more logs could plausibly have pushed `transfer_batch` past `push out of bounds`. It does not: the full suite passes at cap 4 with the event. The README's measurement table now records that the rows above 4 were taken before this event existed and are therefore conservative, since an extra log per recipient can only tighten the budget.

### C-2. The `Transfer` event pays for data availability and buys no guarantee — `main.nr:478`

```noir
self.emit(Transfer { from, to, amount }).deliver_to(
    to,
    MessageDelivery::onchain_unconstrained(),
);
```

Three things are worth separating:

- **The mode.** `onchain_unconstrained()` pays blob cost for the log and gives no guarantee the sender delivered correct content. The framework documentation is blunt that this is strictly worse than `offchain()` where an offchain channel is available. The recipient does **not** depend on this event — they receive their note via `onchain_constrained()` two lines earlier — so the guarantee `onchain_constrained()` would buy is not needed, and the DA cost `onchain_unconstrained()` incurs is not bought back.
- **The recipient set.** Only `to`. The sender gets no record of their own transfer, and neither does the issuer.
- **The issuer omission is a rule violation.** `CLAUDE.md` states: *"Any note written for a user must also be delivered to the current `issuer_address` — auditability is a hard requirement of the design."* Both note messages in `_transfer_internal` honour that. The event does not. An event is not a note, so this is not a contradiction of the letter — but the event carries `from`, `to` and `amount` in one place, which is precisely what an auditor wants, and it is the one message the issuer does not receive.

**Verdict: decide — the options are costed in [H-4](#h-4-the-transfer-event-what-it-is-for-what-it-tells-whom-and-whether-anything-else-already-tells-them), which first establishes what the event uniquely provides — only the sender's identity, to the recipient, and unverifiably in the current mode — and then proposes a one-line experiment that may make the strongest option available.** The short version: `offchain()` to `to`, `from` and the issuer is the cheapest coherent answer, but it is worth first testing whether an `onchain_constrained()` event to the issuer works — the PXE limitation that forced the *note* copies offchain is about note discovery and may not apply to events. Whichever way it goes, record the choice next to the emit, as the issuer-copy decision already is at `main.nr:57`.

### C-3. `set_terms` emits nothing while `set_token_id` emits `TokenId` — `main.nr:288` vs `:309`

The two setters sit in the same module, are guarded by the same role, and were added in the same release. One is observable, the other is not. CMTAT Solidity emits `Terms(CMTATTerms)` from `setTerms`, so the reference implementation has the event this one is missing.

**Verdict: implement — done.** `set_terms` now emits a `Terms` event in all three variants.

Modelled on the Solidity, which was worth reading rather than guessing at: `ExtraInformationModule._setTerms` ends with `emit Terms($._terms)` — it publishes **the whole stored terms**, not merely the caller. So this event carries the flattened `CMTATTerms`: the document name, its URI, the 256-bit hash as its two 128-bit halves, and the `lastModified` the contract stamped. That differs deliberately from the debt events added earlier in this release, which carry only the caller because *their* Solidity counterparts are payload-free by design (`event DebtLogEvent()`, to keep the contract small).

One small refactor came with it: `set_terms` previously passed `self.context.timestamp()` straight into the module call. It now reads the timestamp into a local and passes the same value to both the write and the event, so the event cannot report a `lastModified` different from the one stored.

**No test asserts the event, and that is a tooling limit rather than an omission.** `TestEnvironment` at 5.2.0 offers `discover_event` for *private* `EventMessage` values; `set_terms` is a public function and `self.emit` there produces a public log, for which the harness exposes no getter. The pre-existing `TokenId`, `NewRole` and `Deactivated` events are unasserted for the same reason. The existing `set_terms` tests still cover the state write, and `Terms` appears in the generated TypeScript ABI alongside `TokenId`, which is what an integrator consumes.

### C-4. The constructor configures the contract and emits nothing — `main.nr:119–122`

```noir
self.storage.access_control._grant_role(DEFAULT_ADMIN_ROLE, admin);   // :119
self.storage.access_control._grant_role(VALIDATION_ROLE, admin);      // :120
self.storage.issuer_address.schedule_value_change(admin);             // :122
```

`grant_role` emits `NewRole`. `_grant_role`, called twice here, does not. So the two most consequential role grants in the contract's life — the admin and the validation role, both to the deployer — are the only two with no event, and the issuer address is set for the only time it is ever set (G-3) with no event either.

**Consequence.** An indexer built on `NewRole` sees every subsequent grant and misses the founding ones, which is worse than seeing none: the role table it reconstructs is wrong rather than obviously incomplete.

**Verdict: implement — done, structurally rather than by adding two emits.**

Every role grant now goes through one `#[internal("public")]` helper:

```noir
#[internal("public")]
fn _grant_role_internal(role: Field, account: AztecAddress) {
    self.storage.access_control._grant_role(role, account);
    self.emit(NewRole { role, account });
}
```

The constructor calls it once per role and `grant_role` calls it after authorising, so the write and the emit cannot be separated — which is precisely how they came apart. `#[internal("public")]` is inlined at compile time, so this costs no call and no gas. Without it the emit would have been written three times per file and nine times across the three variants.

To keep the authorisation in the library where the rest of it lives, `AccessControlModule` gained `only_role_admin(role, sender)` — the check half of its existing `grant_role`, exposed on its own. `grant_role` in the contract is now `only_role_admin` followed by the helper.

⚠️ **Correction to this finding as first written.** It proposed a helper owning "validate + write + emit", and claimed the side benefit that the validation "would start guarding the constructor path too". **That is wrong and would not compile into working behaviour**: at construction time no account holds `DEFAULT_ADMIN_ROLE`, so an admin check inside the helper would make every deployment revert. Authorisation has to stay with the caller — `grant_role` checks, the constructor deliberately cannot. The helper owns write + emit only.

**Test coverage was missing entirely and is now added.** There was no `test_access_control.nr`: `grant_role`'s happy path was exercised incidentally by other tests, and its deny path by nothing at all — so the authorisation swap above had no guard. `grant_role_by_admin_succeeds` and `grant_role_by_non_admin_fails` now cover both. The deny test was verified to fail when `only_role_admin` is removed, so it is a regression test rather than a guess.

### C-5. No undelivered messages — checked, clean

`aztec-nargo compile --workspace` produces **33 warnings, all identical** (`Return variable contains a constant value`) and **all originating in aztec-nr's own macro expansion** (`aztec/src/macros/internals_functions_generation/external/private.nr:166`). Zero warnings point at project source, and specifically there is no unused-value warning — which is the signal an undelivered `EventMessage` or `NoteMessage` would produce. Every `self.emit(...)` site (15 across the three variants) either has a `.deliver_to(...)` or is a bare public event.

**Verdict: nothing to do** — but note the hazard this creates. A build that always prints 33 warnings trains everyone to ignore the warning stream, which is exactly where an undelivered-message warning would appear. Worth a line in the agent guide saying the expected count is 33 and all should be from aztec-nr, so a 34th is noticed.

### C-6. Nine state-changing entry points emit nothing

`pause_contract`, `unpause_contract`, `freeze`, `unfreeze`, `set_operations`, `add_to_list`, `remove_from_list`, `revoke_role`, `renounce_role`. Four entry points do emit (`grant_role`, `deactivate_contract`, `set_token_id`, `transfer`), plus three added with the debt realignment.

The README already records event coverage as future work, so this is not news. It is listed here to make the shape visible: the emitting set is not a coherent subset — `grant_role` emits and `revoke_role` does not; `deactivate_contract` emits and `pause_contract` does not. Any observer reconstructing contract state from events gets a partial and asymmetric picture.

**Verdict: decide — resolved as: all nine, done.** Every state-changing entry point now emits, in all three variants.

Names follow the reference where one exists: `Paused` / `Unpaused` and `RoleRevoked` are the OpenZeppelin events CMTAT Solidity inherits (`NewRole`, kept as is, corresponds to `RoleGranted`); `AddressFrozen` is CMTAT's own, emitted by both `freeze` and `unfreeze` with an `is_frozen` flag as CMTAT does. `AddressListed` (both `add_to_list` and `remove_from_list`, through one `#[internal("public")]` helper so the shape lives in one place) and `OperationsSet` have no exact CMTAT counterpart because CMTAT's list events are allowlist-specific.

**One addition beyond the reference.** The three events for `DelayedPublicMutable` flags carry `effective_at: u64` — the timestamp from which the scheduled value is current. It is computed as `context.timestamp() + delay`, which was checked against `DelayedPublicMutable::schedule_and_get_value_change` (`timestamp_of_change = current_timestamp + current_delay`) and is exact because neither module ever reschedules its delay. An indexer therefore does not need to know the contract's delay to know when a freeze bites, which is the operational question the freeze-window discussion in the assessment turns on.

No test asserts these, for the reason recorded under C-3: the harness exposes no public-log getter at 5.2.0. All eleven base-variant events appear in the generated TypeScript ABI, and the full suite passes.

---

## D. Duplication

### D-1. The three `main.nr` files are 99–100% identical

Measured over code lines only (comments and blanks stripped):

| Pair | Identical code lines | As a share of the smaller file |
|---|---:|---:|
| `cmtat-aztec` (378) vs `cmtat-aztec-debt` (431) | 377 | 100% |
| `cmtat-aztec` (378) vs `cmtat-aztec-light` (341) | 339 | 99% |
| `cmtat-aztec-debt` (431) vs `cmtat-aztec-light` (341) | 339 | 99% |

So roughly **340 lines exist in triplicate**, and the Light variant is the base variant minus one module.

**Why it was not shared, which is the part that matters.** This is not a missed extraction. Noir allows one contract per crate, and every user-callable entry point must be declared *inside* the `#[aztec]` contract module — a `#[external("private")]` function cannot live in a `type = "lib"` crate. The logic is already in `cmtat_aztec_lib`; what is duplicated is the declaration shell that the framework requires. There is no extraction available at 5.2.0.

**Consequence.** `CLAUDE.md` already carries the rule — *"Adding an entry point to a shared module means adding it to every variant that should expose it … Keep the three `main.nr` files in step"* — which is an accurate statement of a manual invariant with 340 lines of surface and no enforcement. The debt realignment in `6728a8a` is a live example: it touched only `cmtat-aztec-debt`, correctly, but nothing would have caught it if it had needed to touch the others.

**Verdict: decide — guard it mechanically rather than trying to remove it.** A short script that strips the variant-specific banner sections and diffs the remainder across the three files, run in CI, converts a convention into a check. That is the whole of the available fix, and it is worth saying plainly in the report that the duplication itself is not a defect.

### D-2. `test/utils.nr` is duplicated across three crates, and part of it need not be

All three copies are 78 code lines; 75 are identical between any pair. Unlike D-1, this is ordinary Noir with no framework constraint — but only *part* of it can move:

- **Cannot move:** `setup`, `setup_and_more_addresses`, `setup_and_mint`, `check_private_balance`. All name the contract type (`crate::CMTATAztec as Token`) and the deploy string, which differ per variant. This is the same constraint as D-1.
- **Can move:** `advance_past_delay` (4 lines) and `call_private_on_behalf_of` (14 lines). Neither mentions a contract type; both are generic helpers over `TestEnvironment`. They are currently maintained in triplicate, and `call_private_on_behalf_of` carries a six-line doc comment explaining the authwit/scopes interaction — the kind of explanation that drifts between copies.

**Verdict: implement, partially — done.** The fourth-crate form was taken: `test-helpers/` is a `type = "lib"` package named `cmtat_aztec_test_helpers`, a workspace member depending on `aztec` only, holding `advance_past_delay` and `call_private_on_behalf_of` with their doc comments. Each variant's `Nargo.toml` adds it as a path dependency and each `test/utils.nr` re-exports the two with `pub use`, so every existing call site (`utils::advance_past_delay(...)`) is unchanged. Each `utils.nr` loses 32 lines (107 to 79, doc comments included) and now differs between variants only in the three lines that name the contract type and deploy string. Suite unchanged at 89/89. The per-variant `setup*` and `check_private_balance` stay triplicated for the D-1 reason, recorded in the crate's module comment and the agent guide.

---

## E. Macro and attribute convention drift

### E-1. `#[view]` is missing on four read-only entry points

The contract's own convention is unambiguous — `has_role`, `get_operations`, `token_id`, `version`, `total_supply`, `public_get_name`/`_symbol`/`_decimals`/`_issuer`, `public_get_pause`, `public_get_deactivated` and `get_frozen` all carry `#[view]`. These do not:

| Function | File:line | Mutates state? |
|---|---|---|
| `only_role` | `cmtat-aztec/src/main.nr:136` (all three variants) | No — reads the role map and asserts |
| `terms` | `cmtat-aztec/src/main.nr:298` (all three variants) | No |
| `get_credit_events` | `cmtat-aztec-debt/src/main.nr:324` | No |
| `get_debt` | `cmtat-aztec-debt/src/main.nr:371` | No |

`#[view]` is an enforced guarantee, not a hint. Its absence matters most on `terms`, `get_credit_events` and `get_debt`, which exist to be read by other contracts and by integrators: without it, a caller composing against them cannot rely on their being side-effect-free, and the framework will not stop a future edit from adding a write.

The evidence that this is drift rather than intent is the sibling test: `get_operations` — the same shape of function, in the same banner block, written by the same hand — has it.

**Verdict: implement — done.** `#[view]` added to all four, in every variant that declares them.

**The guard turned out to be stronger than predicted, and it is worth recording why.** The prediction was "a test that compiles". In fact `TestEnvironment::view_public` is *typed* on the attribute — calling it against a non-view function does not compile at all:

```
error: Expected type PublicStaticCall<_, _, _>, found type PublicCall<5, 0, [Field; 5]>
```

That was verified by removing `#[view]` from `terms` and rebuilding. So switching the tests for `terms`, `get_credit_events` and `get_debt` from `call_public` to `view_public` — which is also simply the correct call for a read — makes the attribute impossible to drop silently.

`only_role` had no test caller at all, so its attribute would have stayed unguarded. `only_role_passes_for_a_holder` and `only_role_reverts_for_a_non_holder` were added: the first pins the attribute, the second confirms the assertion still fires through a static call.

### E-2. Four getters return without `pub`

`terms() -> [Field; 5]` (`:298`), `get_credit_events() -> [Field; 3]`, `get_debt() -> [Field; 16]`, and `total_supply() -> u128` (`:379`) return without the `pub` return marker that every other getter uses (`-> pub Field`, `-> pub FieldCompressedString`, `-> pub AztecAddress`). `total_supply` is the interesting one: it has `#[view]` but not `pub`, so it is not the same omission as the other three and is likely older.

**Verdict: implement — done.** All four now return `-> pub`, matching every other getter in the contract. `total_supply` remains the odd one out in origin: it already carried `#[view]`, so it was never the same omission as the other three.

### E-3. Attribute discipline elsewhere — checked, clean

- **`#[only_self]`** is present on all three enqueued targets (`_mint`, `_transfer`, `_burn`) in all three variants — 9 of 9. This is the highest-consequence item in this check and there is nothing to report.
- **`#[noinitcheck]`**: zero occurrences. Correct — it is right for pre-funded-account patterns and wrong essentially everywhere else.
- **`#[allow_phase_change]`**: zero occurrences.
- **`#[initializer]`**: exactly one per contract, and `contracts/*/src/test/utils.nr` deploys through it via `with_public_initializer`, so the declared and the called initializer agree.
- **`unconstrained` on `#[external("utility")]`**: one such function (`balance_of_private`), correctly declared `unconstrained`, and no caller treats its result as proven.

---

## F. Standard conformance

### F-1. Should this token implement AIP-20?

> The full standard-to-standard comparison behind this finding is in [`doc/technical/cmtat-vs-aip20.md`](../../../technical/cmtat-vs-aip20.md), and the engineering question — could this project be *rebuilt on* the `aztec-standards` library — is answered in [`doc/technical/building-on-aip20.md`](../../../technical/building-on-aip20.md). This section states the decision for *this* contract.
>
> ⚠️ One correction from reading that library's source: AIP-20 **does** have a transfer-authorization hook (ARC-403), which this finding's first revision did not know about. It does not change the verdict — the hook is not passed the recipient, so it cannot express CMTAT's screening — but it narrows the gap from "no extension point" to "one missing argument".

Checked against the bundled `aztec-nr/standards/aip-20.md` and the DeFi Wonderland `aztec-standards` repository it names as the source. **Short answer: no, not as a whole — two of its central features are incompatible with what a CMTAT is for. But one part of it is worth taking on its own merits, and the measurement below says it is worth 36% of a transfer.**

#### What AIP-20 requires that this contract does not have

| AIP-20 feature | Here |
|---|---|
| `public_balances: Map<AztecAddress, PublicMutable<u128>>` and the hybrid private/public transfer paths | Absent. Balances are private only; the sole public quantity is `total_supply` |
| Partial-note transfers: `initialize_transfer_commitment`, `transfer_private_to_commitment`, `complete_from_private` | Absent |
| `PRIVATE_ADDRESS_MAGIC_VALUE`, the "this party is private" marker used in public events | Absent |
| `INITIAL_TRANSFER_CALL_MAX_NOTES = 2` / `RECURSIVE_TRANSFER_CALL_MAX_NOTES = 8` with `#[only_self]` recursive subtraction | Absent; `BalanceSet::sub` uses a flat `max_notes = MAX_NOTE_HASH_READ_REQUESTS_PER_CALL` (16) |
| `minter: PublicImmutable<AztecAddress>`, `upgrade_authority: PublicImmutable<AztecAddress>` | Role-based `MINTER_ROLE`, grantable and revocable; no upgrade authority, the contract is not upgradeable |
| `asset` / `vault_offset` for the AIP-4626 vault pattern | Absent |

So there is no partial conformance to repair: the two designs overlap only on `name`/`symbol`/`decimals`, `total_supply` and an `Owned<BalanceSet>` for private balances.

#### Why the answer is no — two conflicts, not two workloads

**1. Public balances defeat the product.** The README's own assumptions are that holder balances are private and only the supply is public. AIP-20's public side would add a second, fully public balance ledger to a token whose reason to exist is that it does not have one.

It is not enough to say "an issuer simply would not use it". Publishing the surface means a wallet advertising AIP-20 support offers users a public-transfer button, and every public path would then need the freeze, blacklist and whitelist checks duplicated onto it — checks that currently live in `_transfer_internal` and run in private. A compliance surface that exists but is only correct if nobody uses half of it is worse than not having it.

**2. Partial notes and recipient screening are mutually exclusive as designed.** This is the deep one, and it is architectural rather than a matter of effort.

The purpose of `initialize_transfer_commitment` is that the recipient is *not known* when the sender locks the funds — that is what `PRIVATE_ADDRESS_MAGIC_VALUE` encodes, and it is what makes private DeFi composability possible, because a private function cannot read the public state (an order book, an auction result) that determines who should be paid.

CMTAT requires the recipient to be screened before the transfer: `operateOnTransfer(from, to)` checks `to` against the blacklist or whitelist, and `_transfer_internal` checks `is_frozen(to)`. **Neither check can run when `to` is the placeholder.** The options are all bad:

- **Screen at completion.** The completer is a public function, so the compliance check would publish the recipient's address on every transfer — surrendering exactly the privacy the token is built for, and only for transfers that used a commitment.
- **Skip screening on the commitment path.** Then a sanctioned address can be paid through any commitment-based flow, and the restriction module becomes advisory.
- **Restrict completers to an allowlist of settlement contracts.** Workable in principle, but Aztec has no interface check (see I-1), so it reduces to configuration discipline and pushes the compliance obligation into a second contract the issuer must also assure.

None of these is a small decision. The honest conclusion is that a *transfer-restricted* token and a *composable* token pull in opposite directions, and AIP-20 is designed for the second.

#### What is worth taking anyway, and it is not small

AIP-20's note-count strategy is orthogonal to conformance, and this contract is currently on the wrong side of it.

`BalanceSet::sub` — the library function every transfer and burn calls — hardcodes its note budget to the whole per-call allowance:

```noir
pub fn sub(self: Self, amount: u128) -> MaybeNoteMessage<UintNote> {
    let subtracted = self.try_sub(amount, MAX_NOTE_HASH_READ_REQUESTS_PER_CALL);  // 16
    ...
}
```

The library's own comment says the gate count scales roughly linearly with `max_notes`. So **every transfer sizes its circuit for sixteen notes**, whether the sender's balance is one note or sixteen. AIP-20 instead tries two, and recurses through `#[only_self]` into calls of up to eight when two are not enough.

**Measured, not estimated.** Replacing the `sub` in `_transfer_internal` with `try_sub(amount, 2)` plus the change note, recompiling `cmtat_aztec` and re-profiling:

| `_transfer_internal` note budget | `transfer` gates |
|---|---:|
| 16 (current, via `BalanceSet::sub`) | 120,824 |
| 2 (AIP-20's initial budget) | **77,778** |

**43,046 gates, 36% of a transfer**, on the proof the user's own device has to produce. The probe was reverted and the baseline reproduced.

That number is the size of the prize, not the net gain, and the caveat matters: at a budget of 2, a transfer from a holder whose balance is spread across three or more notes fails outright. AIP-20 pays for that with recursion, and each recursive level is a fresh kernel iteration — on the order of 101,000 gates by the framework's own figure. So the real trade is:

- balance settles in ≤ 2 notes → **~78k instead of ~121k**
- balance needs 3–8 notes → ~78k **plus** a recursive kernel, so worse than today
- so it is a clear win only if most transfers settle in one or two notes, which for a security token with infrequent, large transfers is plausible but **unmeasured here**

Before adopting it, the thing to measure is the note-count distribution of a realistic holder, not the gate count — that number is already known.

#### Verdict

- **Do not implement AIP-20.** Say so explicitly instead: one line in the README stating that this contract implements CMTAT directly, is deliberately not AIP-20, and has no partial-note path. An Aztec integrator's default assumption is that a token is AIP-20-shaped, and today they discover otherwise from a compile error. *(This part of the finding remains open.)*
- **Record the reason, not just the fact.** "Not AIP-20" reads as an omission; "transfer restriction and commitment-based composability are mutually exclusive" is a design position, and it is the one the token has taken.
- **Treat the note budget as a separate, live optimisation** — filed here only because AIP-20 is where the better pattern is documented. It is worth 36% of a transfer in the common case, it requires no standard conformance, and its prerequisite is a note-distribution measurement rather than an architecture decision.
- **Revisit partial notes only if a compliant on-chain secondary market becomes a goal.** At that point the question is not "should we adopt AIP-20" but "where does recipient screening live when the recipient is unknown", and the answer decides whether the token can be composable at all.

---

## G. Code / documentation mismatch

### G-1. `mint`'s NatSpec claims a validation check that does not run — `main.nr:427`

```noir
* - The recipient must respect the allowlist constraints of the validation module.
```

`_mint_internal` (`:405–416`) checks the freeze flag and nothing else; `operateOnTransfer` is called only from `_transfer_internal` (`:509`). The identical claim on `transfer` at `:468` **is** accurate.

This behaviour is already recorded, correctly, in `doc/cmtat-assessment/README.md` — *"mint and burn are not screened by the lists at all … A blacklisted address can therefore still be minted to and burned from"*. So the code is understood and the assessment is right; the defect is the source comment, which tells the opposite story to whoever reads the contract without the assessment beside it.

**Verdict: implement — resolved the other way, by decision of the compliance owner: the code now does what the comment said.** And the decision went further than the comment, to full alignment with CMTAT Solidity's mint/burn rules.

The reference was read rather than recalled. `ValidationModule._canMintBurnByModule(target)` refuses on *deactivation* or a *frozen* target and never consults `paused()`; `ValidationModuleAllowlist._canMintByModuleAndRevert(to)` and `_canBurnByModuleAndRevert(from)` add the list check on the target. So three things changed, in all variants that carry the module:

1. `_mint_internal` screens `to` and `_burn_internal` screens `account` against the enabled list, through two new module methods `operateOnMint` / `operateOnBurn` that reuse the existing sender/recipient messages.
2. `_mint` and `_burn` assert `!is_deactivated()` where they asserted `!is_paused()`. `_transfer` is unchanged. A pause therefore stops transfers only, as in the reference; the assessment's "Mint and burn are blocked while paused, where CMTAT Solidity allows them" is no longer a difference.
3. The NatSpec on both is now true.

**Measured:** `mint` 30,776 → 36,976 (+6,200) and `burn` 81,736 → 87,935 (+6,199) — the operations flag and one address flag, the first read of each slot. `mint_batch` and `burn_batch` grew ~24,700 each: the operations flag is re-read per iteration inside the module method, the same loop-invariant shape A-2 hoisted for the issuer read. `transfer` and the Light variant are untouched.

**Tests, written first.** Seven tests were written or changed before the code and run against it: three new list tests (`mint_to_blacklisted_fails`, `mint_to_non_whitelisted_fails`, `burn_from_blacklisted_fails`), `mint_when_paused_fails` inverted to `mint_when_paused_succeeds` with a balance assertion, a new `burn_when_paused_succeeds`, and `mint_when_deactivated_fails` / new `burn_when_deactivated_fails` expecting the new message. All seven failed on the old behaviour — exactly those seven, and nothing else — and all pass after. 85 tests across the workspace.

The assessment's Restriction row for *Blacklist* moves from `partial` to `y`, and the two mint/burn diagrams in the README were re-rendered.

### G-2. `_burn_internal` reports the wrong party — `main.nr:540`

```noir
fn _burn_internal(from: AztecAddress, amount: u128) {
    assert(!self.storage.enforcement_module.is_frozen(from), "Frozen: Recipient");
```

There is no recipient in a burn. The caller at `:562` gets it right (`"Frozen: Sender"`), which is how the mistake is visible at all. `_mint_internal:406` uses `"Frozen: Recipient"` correctly, so this looks like a copy from there.

**Consequence.** `burn_batch` reaches `_burn_internal` without the `:562` check, so a frozen holder's batched burn fails with `Frozen: Recipient` — pointing the operator at the wrong address to investigate. On a circuit the assertion message is the only debugging output there is.

**Root cause, addressed separately.** The parameter was called `from`, which implies a counterparty and invites the mint module's wording. CMTAT Solidity avoids this by naming the target of `burn` and `mint` `account`, reserving `from`/`to` for transfers. The burn path has been renamed to match (`burn`, `burn_batch` and `_burn_internal` now take `account`), which removes the conditions that produced the bug rather than only its symptom. `mint` still uses `to`; aligning it too would be a second ABI change and was left.

**Verdict: implement — done**, together with A-1.

The fix was pinned by a test written *before* it and confirmed to fail against the unfixed code, which is the only thing that makes it a regression test rather than a guess:

```
[cmtat_aztec] Testing test::test_enforcement_module::burn_batch_restricted_when_freezed ... FAIL
error: Test failed with the wrong message.
Got: "Assertion failed: Frozen: Recipient"
```

`burn_batch_restricted_when_freezed` freezes a holder and calls `burn_batch`, asserting `"Frozen: Sender"`. It lives in the base variant's suite, which by project convention carries the full test surface. After the fix it passes, and the pre-existing `burn_restricted_when_freezed` (which exercised `burn`, and passed only because the now-deleted duplicate check ran first) still passes.

### G-3. `issuer_address` cannot be changed, and three documents imply it can — `main.nr:383`

```noir
//TODO: we should be able to change the address of the issuer and put some ACL on it
```

The TODO is accurate. `issuer_address` is written exactly once, by `schedule_value_change` in the constructor (`:122`); there is no setter in any of the three variants. Against that:

- `CLAUDE.md` lists `issuer_address` among the `DelayedPublicMutable` values whose changes take `CHANGE_ROLES_DELAY_SECONDS`, which describes a change operation.
- `CHANGELOG.md` states the delay change "affects operators: freezing an account, blacklisting an address **and changing the issuer** now take six minutes rather than two blocks" — a migration note about an operation that does not exist.
- `doc/cmtat-assessment/README.md` describes the issuer as receiving audit copies without qualifying that the address is fixed for the contract's life.

**Consequence.** The issuer address is the audit endpoint for every note this contract ever creates. That it is immutable after deployment — so a compromised or rotated issuer key means redeploying and migrating every holder — is a material operational constraint that no document states and one document contradicts.

**Verdict: decide — resolved in two steps.** First the documentation was corrected to the setter-less reality. Then the setter was added, which is the resolution that stands:

`set_issuer(new_issuer)`, `DEFAULT_ADMIN_ROLE`, refuses the zero address, schedules on the existing `DelayedPublicMutable`, emits `IssuerChanged { issuer, operator, effective_at }`. The `TODO` above `public_get_issuer` is gone.

**What a rotation does and does not do** is the part worth recording, because it is easy to over-promise. It redirects *future* audit copies after the delay. It does not recall copies already delivered — nothing can un-deliver an encrypted message — so a compromised issuer keeps the history it already holds, and rotation limits damage forward rather than undoing it. And the new issuer's PXE must be live and registered from `effective_at`, or copies sent in the gap reach the holders but not the issuer side. The README states all three.

**Tests** cover the delay on both read paths (`public_get_issuer` and `private_get_issuer` return the old value before the delay and the new one after), that transfers keep working during and after the change, and the two refusals. What they cannot cover is *where the offchain copy went*: the TXE exposes no view of offchain deliveries, so the redirect is verified by the read paths the deliveries use, not by observing a delivery. 89 tests across the workspace.

### G-4. `EXTRA_INFORMATION_ROLE = 11` is missing from two role lists

The code defines eleven roles (`access_controlModule.nr`), and `CLAUDE.md` lists all eleven. Two documents stop at ten:

- `doc/cmtat-assessment/README.md:289` — the criterion-29 implementation-details cell enumerates `DEFAULT_ADMIN_ROLE` 1 … `DEBT_CREDIT_EVENT_ROLE` 10.
- `README.md:544` — the glossary's **Role** entry, same enumeration.

Both were written before the extra-information module existed and were not revisited when it landed. (The assessment's prose count of roles was corrected to eleven during the debt work; these two enumerations were missed.)

**Verdict: implement — done.** There turned out to be **three** stale enumerations, not two: a second one in the assessment's Access Control note (`:295`) said the roles run "up to `DEBT_CREDIT_EVENT_ROLE` at `10`", which the first pass over this finding missed because it reads as prose rather than a list.

All three now end at `EXTRA_INFORMATION_ROLE` 11. A sweep for role-count claims confirms nothing else stops short: the assessment's Conclusion already says "Eleven numeric roles", and `CLAUDE.md` / `AGENTS.md` were correct throughout.

The underlying hazard remains and is worth naming: the role table is a hand-maintained list duplicated across the code and three documents, with nothing tying them together. The next role added will drift the same way. A cheap guard would be a check that every `pub global .*_ROLE` in `access_controlModule.nr` appears in each enumeration — the same shape of mechanical check proposed for D-1.

### G-6. `yarn compile` produces artifacts that `yarn codegen` cannot consume — `package.json:13`

Found while regenerating artifacts after the A-1 fix, not by reading. The build script was:

```json
"compile": "${AZTEC_NARGO:-aztec-nargo} compile --workspace",
```

At 5.2.0, `aztec-nargo` is a bare symlink to `nargo`:

```
/home/ryan/.aztec/versions/5.2.0/bin/aztec-nargo: symbolic link to ../internal-bin/nargo
```

so it compiles Noir but does **not** run the AVM transpiler over the public bytecode. Running the project's own documented sequence — `yarn compile` then `yarn codegen` — therefore fails:

```
Error: Could not generate contract artifact for CMTATAztec:
       Error: Contract's public bytecode has not been transpiled
```

**Why it was not noticed.** `aztec test` transpiles as a side effect. Anyone who runs the tests between compiling and generating — which is the normal working order, and the order `yarn test` enforces — never sees it. It only bites on the pre-release path in `CHANGELOG.md`, which is `yarn clean && yarn compile && yarn codegen` with no test run in between: precisely the clean-tree rebuild the checklist exists to guarantee.

**Verdict: implement — done.** The script is now `${AZTEC_COMPILE:-aztec} compile --workspace`. `aztec compile` runs nargo and then post-processes ("Successfully processed 3 artifact(s)"), and `--workspace` forwards through to nargo unchanged. Verified: `aztec compile --workspace` → `aztec codegen` → `yarn typecheck` all succeed from a compiled tree. The environment override is renamed `AZTEC_COMPILE` because it now names the `aztec` CLI rather than the nargo binary, and `CLAUDE.md` / `AGENTS.md` record why the distinction matters.

### G-5. Doc-comment health and doc pointers — checked, clean

- **Comments referencing documentation files:** zero. Grepped `.nr` sources for `.md`, `docs/`, `doc/` and `See <file>` — nothing. So the failure mode where a docs reorganisation invalidates a pointer baked into deployed source does not exist here.
- **Doc-comment block lengths:** 103 blocks; **median 4 lines, mean 5.3, longest 18**. The three longest (18 lines, one per variant) document `transfer`'s authwit semantics — the caller-vs-`from` distinction, the nonce-zero rule and the replay protection — which is a genuine footgun and earns the space. Next is 17 lines on `pauseModule::deactivate`, documenting an irreversible operation. Nothing in the distribution suggests comments that have outgrown their code.

**Verdict: nothing to do.** Recorded because "the comments are fine" is only credible with the distribution attached.

---

## H. Weird behaviour and privacy leakage

### H-1. `burn` publishes the caller's address and the amount — `main.nr:565`, `:613`

```noir
self.enqueue_self._burn(self.msg_sender(), amount);
...
fn _burn(caller: AztecAddress, amount: u128) {
    self.storage.access_control.only_role(BURNER_ROLE, caller);
```

Every argument to a public function is public, so both `caller` and `amount` are published in the clear. `mint` does the same with the minter and the minted amount.

**Scoping this honestly, because the obvious reading overstates it:**

- The **holder** is not published. `from` stays in the private half; only `msg_sender()` crosses over. A burn from Alice, executed by the issuer under an authwit, publishes the issuer — not Alice.
- The address published **always holds `BURNER_ROLE`** (or `MINTER_ROLE`), and the role table is public state that anyone can already enumerate. So the marginal disclosure is *which* role-holder acted and *when* — not a new identity.
- The **amount is unavoidable**. `total_supply` is a `PublicMutable<u128>` by design and moves by exactly that amount in the same transaction; passing it as an argument reveals nothing the state change does not.

**What remains.** An observer learns that a specific role-holder minted or burned a specific quantity at a specific time. Where the issuer is the sole minter and burner — the expected deployment — that is a public issuance-and-redemption ledger keyed to the issuer, which is arguably what a security token wants. It becomes a real leak only if burner authority is ever delegated to holders, at which point the burner *is* the holder and the burn becomes fully public.

**Verdict: decide — resolved as: document, do not redesign. Done, in three places.**

- **README**, a new *What each operation publishes* table under *Security and confidentiality properties*: per operation, the public callee, what is published and what is kept private — followed by the three qualifications above and a boxed warning that `BURNER_ROLE` (and `MINTER_ROLE`) must stay issuer roles, because the privacy of a burn rests entirely on the burner and the holder being different parties. The selector leak (H-3) is stated in the same place, with why it has no cheap fix.
- **Assessment privacy table**, two new rows — *Minter and minted amount* and *Burner and burned amount*, both `public` in the implementation as in CMTAT Solidity — so the section that makes this a *private* CMTAT no longer implies that everything about a mint or a burn is private.
- **Code**, a `PRIVACY:` comment on each of `_mint`, `_transfer` and `_burn` stating what crosses the boundary and what must not be added. This also discharges H-2's "protect from simplification": the comment on `_transfer` says it MUST take no arguments and why.

No behaviour changed, so no test changed; the guard here is that the property is now written where a refactor would have to read it.

### H-2. `mint` hides its recipient and `_transfer` takes no arguments — keep, and protect

Two things this contract gets right, and both are the kind of thing a later "simplification" removes:

- **`mint(to, amount)` enqueues `_mint(msg_sender(), amount)` — `to` never crosses into public.** The recipient of newly issued tokens is exactly what an issuance should hide, and it is hidden. The obvious-looking refactor — pass `to` to `_mint` so the public half can do something with it — would publish it.
- **`_transfer()` takes no arguments at all.** It asserts not-paused and nothing else. `from`, `to` and `amount` all stay private. This is the single most important privacy property in the contract and it is achieved by the public half being deliberately ignorant.

**Verdict: keep, and comment.** A line on `_transfer` saying *this must not take arguments; anything passed here is published* costs nothing and defends a property that no test can assert.

### H-3. The enqueued public selector reveals which operation ran — decide

Tabulating the observable public footprint per private entry point:

| Private entry point | Public calls | L2→L1 messages | Public callee | Public arguments |
|---|---:|---:|---|---|
| `mint`, `mint_batch` | 1 | 0 | `_mint` | minter, amount |
| `transfer`, `transfer_batch` | 1 | 0 | `_transfer` | *none* |
| `burn`, `burn_batch` | 1 | 0 | `_burn` | burner, amount |
| `cancel_authwit` | 0 | 0 | — | — |
| `private_get_*` | 0 | 0 | — | — |

**The good news:** the *count* does not distinguish the three value-moving operations — all enqueue exactly one public call and produce no L2→L1 messages. Count-based fingerprinting, which the framework documentation identifies as the leak that padding does not cover, does not apply. Note hashes, nullifiers and private logs are padded by the protocol, so the differing note counts (mint 1, transfer 2, burn 1) are not distinguishing either.

**What does distinguish them** is the callee: `_mint`, `_transfer` and `_burn` are three different public functions, so an observer sees which of the three occurred. For transfer that reveals only "a transfer happened", which is unavoidable and harmless. For mint and burn it composes with H-1.

`cancel_authwit` enqueues nothing, so it is distinguishable from every value-moving operation by having zero public calls — but it also moves no value, so there is little to learn.

**What can actually be done.** Four options, in increasing order of disruption. Only the last two change anything real.

**1. Document it (recommended baseline).** Add the table above to the README's privacy section. The residual leak is genuinely small, and the reason is worth stating rather than assuming: `total_supply` is a `PublicMutable<u128>` that moves visibly on every mint and burn, so **an observer can already tell mint from burn from transfer without looking at the selector at all** — mint increases it, burn decreases it, transfer leaves it alone. The selector's marginal contribution is confirming that *this contract* was the one used. That is worth writing down; it is not worth a redesign on its own.

**2. Collapse the three public halves into one `_post_op(caller, kind, amount)` — do not do this.** It equalises the selector but publishes `kind` as an argument instead, so it hides nothing. Worse, it would drag `transfer` down to the level of the other two: `_transfer()` currently takes **no arguments at all**, and merging it into a common signature would newly publish the transferring caller's address on every transfer. This option makes the contract strictly less private and is listed only so it is not proposed again.

**3. Drop the public call from `transfer` entirely — the one structural fix that works.** `_transfer()` does exactly one thing:

```noir
fn _transfer() {
    assert(!self.storage.pause_module.is_paused(), "Error: token contract is paused");
}
```

The entire public half of a transfer exists to read one boolean. It has to be public because `is_paused` is a `PublicMutable<bool>`, and a private function cannot read current mutable public state. If the pause flag were a `DelayedPublicMutable<bool, DELAY>` — exactly what the freeze and validation flags already are, and for exactly the same reason — the check could run in the private half and `transfer` would enqueue nothing. A transfer would then produce **zero public calls**, removing the clearest public signal that this contract was used for a transfer.

- **What it costs: a pause that takes at least six minutes, and by the framework's own guidance should take hours.** The duration is the `DELAY` type parameter of the `DelayedPublicMutable`. If the pause flag reused this contract's `CHANGE_ROLES_DELAY_SECONDS`, that is **360 seconds** — six minutes, five slots at this network's 72-second slot. It could be given its own, shorter constant, but the library says why it should not be, and the reasons are structural rather than a matter of taste:
  - **Every private read of a `DelayedPublicMutable` sets the transaction's `expiration_timestamp`** to before the delay elapses — the read is only sound if the transaction is included while the historical value is still guaranteed current. So the delay *is* the transaction's validity window. A 60-second pause delay would make every transfer of this token expire 60 seconds after its anchor block: a slow prover fails, a congested sequencer fails, and the user pays for priority inclusion to be safe.
  - **A short delay is a fingerprint.** The library's words: *"If the delay is smaller than that of any other contract, then this privacy leak might be large enough to uniquely identify those transactions that interact with the contract — fully defeating the purpose of `DelayedPublicMutable`."* The expiration timestamp is set by the *shortest* delay read in the transaction, so a pause flag with a shorter delay than the freeze and list flags would stamp every transfer with a distinguishing expiration.
  - **The library recommends "a delay of at least a couple hours"**, and the state-variable documentation says the type is *"unsuitable for actions that must be executed immediately — such as an emergency shutdown."* That sentence describes option 3 exactly.

  So the honest statement of option 3 is not "trade immediacy for privacy". It is: a pause that cannot take effect in under six minutes as this contract is configured, and that the framework says should not take effect in under two hours. CMTAT treats pause as the emergency lever, and criteria 14–16 are answered `y` here on it being immediate. That is a compliance regression with a number attached, and the number is not small.
- **A middle position exists.** Keep the public pause check on `mint` and `burn` — they already enqueue a public call for `total_supply`, so it is free there — and accept the delay only on `transfer`. Pause would then halt issuance and redemption instantly and transfers after `DELAY`. Whether that is acceptable is a compliance question, not an engineering one.
- **It is also a gate saving**, though a small one, and it would need measuring rather than assuming: a `DelayedPublicMutable` read in private costs gates where an enqueued call costs none in the private circuit.

**4. Make the role table `DelayedPublicMutable` too.** This is the symmetric fix for H-1: if roles could be read privately, `_mint`/`_burn` would not need the caller as an argument and the role-holder's address would stop being published. **The cost is worse than the disease** — a revoked minter would keep the ability to mint for the whole delay window, which is a live security regression, not a privacy trade. Recorded so the symmetry is visible and the answer is on file.

**Verdict: option 1, decided.** The project owner's call: keep the pause check where it is, because a pause that takes several hours is too slow for a pause. The residual leak is documented in the README under *What each operation publishes*, together with the reason the pause flag stays a `PublicMutable` while the freeze and list flags are delayed. Option 3 is recorded below as considered and rejected.

The analysis that led there: Option 3 is the only one that removes the leak rather than relocating it, but the leak it removes — that a transfer of this token occurred — is bought with a pause that takes six minutes at best and, by the library's guidance, hours. For a security token whose pause is the emergency lever, that is the wrong trade, and the framework's own documentation says so in as many words. Options 2 and 4 are recorded as rejected with reasons. What the duration analysis *did* surface is recorded separately as H-6.

### H-4. The `Transfer` event: what it is for, what it tells whom, and whether anything else already tells them

The options (C-2) only make sense once three prior questions are answered: what is the event's *purpose* here, exactly what *information* does it carry to each party, and can that information be *obtained another way*. This section does that first, then costs the options.

#### What the event is

```noir
self.emit(Transfer { from, to, amount }).deliver_to(to, MessageDelivery::onchain_unconstrained());
```

Emitted by `transfer` and, since C-1, by `transfer_batch` once per recipient. Delivered to **`to` only**, encrypted, posted on chain, **unconstrained** — which the library defines as "on-chain delivery without constrained encryption/tagging": the circuit computes `{from, to, amount}` correctly, but nothing proves that the ciphertext the sender's PXE actually posts encrypts those values. The recipient decrypts whatever the sender chose to encrypt.

#### Its purpose here is not its purpose in ERC-20

In CMTAT Solidity, `Transfer(from, to, value)` is a **public** log: the primary feed for indexers, explorers, accounting systems and the issuer's own reconciliation. It is how anyone who is not a party learns that a transfer happened and between whom.

Here it cannot be that. It is encrypted to one party, so no indexer reads it, no explorer shows it, and the issuer does not receive it. Its only possible purpose is as a **receipt to the recipient** — a message saying "you were sent `amount` by `from`". Whether that receipt is worth having depends entirely on whether the recipient learns anything from it that it does not already learn from the note it also receives.

#### What each party learns, and from where

Every transfer already delivers two notes: the sender's change note (`onchain_constrained`, to `from`) and the recipient's new note (`onchain_constrained`, to `to`), each with an offchain copy to the issuer. A `UintNote` is:

```noir
pub struct UintNote {
    pub value: u128,
}
```

— a value and, through the delivery, an owner. **It has no sender field.**

| Information | Party | Available without the event? | From where |
|---|---|---|---|
| `amount` | recipient | **yes** | `value` of the note it receives |
| `amount` | sender | yes | it chose it; its change note confirms the debit |
| `amount` | issuer | **yes** | `value` of its copy of the recipient's note |
| `to` | recipient | yes | it is the note's owner |
| `to` | issuer | **yes** | owner of the recipient-note copy |
| `from` | sender | yes | it is the sender |
| `from` | issuer | **yes** | owner of the change-note copy, in the same transaction |
| `from` ↔ `to` pairing | issuer | yes, **by correlation** — the two copies must be grouped by transaction; the event would state the pair directly |
| **`from`** | **recipient** | **no** | the note carries no sender; the event is the only in-band source |
| that a transfer occurred | anyone | yes | the enqueued `_transfer()` call |

*(Whether the delivery layer's tagging lets a recipient's PXE infer a sender is a PXE implementation detail outside this contract's control, and for a contract-emitted note the tag is derived from the contract, not the holder. The contract should not rely on it either way.)*

So the event carries exactly **one** datum that nothing else provides: **the sender's identity, to the recipient.** Everything else it says is a restatement of the notes.

#### And that one datum is unverifiable in the current mode

Because delivery is `onchain_unconstrained`, the `from` the recipient decrypts is not proven to be the `from` the circuit checked. A sender can transfer 100 tokens to Bob and hand Bob a receipt saying they came from Carol. The one thing the event uniquely offers, it offers without a guarantee. The recipient's *note* is constrained; the receipt naming the sender is not. That is the wrong way round for a receipt.

This reframes the question. It is not "should we pay DA for this event" but "**do recipients need a trustworthy statement of who paid them, and does the issuer want the pairing stated rather than inferred?**"

#### The options, re-costed against that

| | Mode and recipients | Sender identity to recipient | Pairing to issuer | DA | Proving |
|---|---|---|---|---|---|
| **A** | Drop the event | not available | inferred from two copies | none | −1,679 gates |
| **B** | `offchain()` to `to`, `from`, issuer | delivered, **not verifiable** | stated, not verifiable, no availability guarantee | none | ~1,679 |
| **C** | `onchain_unconstrained()` to `to` *(current)* | delivered, **not verifiable** | not delivered | 1 log | 1,679 |
| **D** | `onchain_constrained()` to `to` and the issuer | delivered, **verifiable** | stated, verifiable, on chain | 1 log each | more than 1,679 |

**C is dominated.** It pays data availability for a receipt whose only unique claim is unverifiable and which the issuer does not receive. Whatever else is decided, C should not survive.

**A and B are the "the notes are enough" answers.** A says the recipient does not need to know the sender in-band — plausible for a security token, where counterparties are known off-chain and the issuer reconciles from copies. B keeps a best-effort receipt for all three parties at zero DA cost, matching how the issuer's note copies already travel, and accepting the same no-guarantee caveat.

**D is the "the event has a job" answer**, and it is the only one that makes the event's unique datum trustworthy. It also does something the notes cannot: it puts the issuer's `from`↔`to` pairing **on chain, constrained**, instead of leaving it to offchain correlation. That matters because of the finding that makes D worth testing before choosing B: the issuer's *note* copies were forced offchain by a PXE limitation about **note discovery** — computing a note's nullifier needs the owner's key. **An event is not a note.** It has no nullifier and no such discovery step, so the limitation may simply not apply — in which case the issuer could receive a guaranteed, on-chain, constrained record of every transfer even though it cannot receive guaranteed note copies. That would put the most important part of the audit trail — who paid whom, how much — back on chain with data availability, which the CHANGELOG currently records as absent.

#### The experiment, run

Delivery changed to `onchain_constrained()` to **both** the recipient and the issuer, in `transfer` on the base variant, and the full package suite run:

**76 / 76 pass** — including `transfer_private_check_issuer_view`, where the issuer is a third party to a user-to-user transfer. **The hypothesis holds: an event can be delivered constrained and on chain to the issuer.** The limitation that forced the note copies offchain is specific to note discovery and does not touch events.

The full price list, measured on `transfer`:

| Delivery of `Transfer` | Gates | vs. today |
|---|---:|---:|
| A — drop it | 119,145 | −1,679 |
| B — `offchain()` to recipient and issuer | 119,227 | −1,597 |
| C — `onchain_unconstrained()` to recipient *(today)* | 120,824 | — |
| `onchain_constrained()` to recipient only | 140,988 | +20,164 |
| D — `onchain_constrained()` to recipient **and** issuer | 161,493 | +40,669 |

Two things the numbers say. Offchain delivery is essentially free in-circuit — 82 gates for two. A constrained delivery costs **~20,200 gates each**, so D is a 34% increase on a transfer.

**Verdict: recommend D, framed as two separate purchases — and one prerequisite before adopting it.**

- **The issuer leg (+20k) is the one to buy.** It gives the issuer, for the first time, an on-chain, data-available, *constrained* record of every transfer — `from`, `to`, `amount`, unforgeable by the sender — where today its entire audit trail is offchain and a dropped message is undetectable. That is the weakness the CHANGELOG's Security section records against this design, and a security token's audit trail is the point of the instrument. Twenty thousand gates is a fair price for closing it.
- **The recipient leg (+20k) is the one to argue about.** Its value is a *verifiable* statement of who paid, which matters if recipients act on receipts — source-of-funds, settlement confirmation. If they do, buy it; the alternative to a verifiable receipt is no receipt (A), never an unverifiable one (C), because a receipt the sender can forge is a settlement-confirmation attack surface, not a convenience.
- **Prerequisite, now done: the batch cap was re-measured, and the private-log arithmetic above was wrong.** Under D, `transfer_batch` aborts with `push out of bounds` at **4 and at 3**; it passes at **2**. The binding array is therefore not the sixteen private logs — 3 × 4 = 12 would have fitted. A model consistent with every measurement is that each constrained delivery consumes **two** of the sixteen key-validation requests a call may make: the old scheme at 4 recipients used 4 × 2 constrained × 2 = 16 exactly, D at 3 needs 24. The TXE gives no stack trace for the overflow, so this is recorded as a model, and the cap as the measurement. Mint and burn batches, which emit no per-recipient event, keep 4 under `MAX_ADDR_PER_CALL`; transfer gets its own `MAX_TRANSFER_ADDR_PER_CALL = 2`.
- **Adopted.** D is implemented in all three variants: `transfer` and `transfer_batch` deliver `Transfer` constrained to the recipient and the issuer; `transfer` measures 161,493 and a 2-recipient batch 312,909. The README gained an *Events* section that records the reasoning. **Follow-on, not now:** the same on-chain record for mint and burn. The public halves already publish minter/burner and amount (H-1); what the issuer's on-chain trail would still lack is the private party — the recipient of a mint, the account of a burn. A constrained event to the issuer on those two paths would complete it.

### H-6. The 360-second delay is below the library's recommended minimum — decide

Found while answering how long a delayed pause would take (H-3). Every `DelayedPublicMutable` in this contract — the freeze flags, the list flags, the operations switch, `issuer_address` — uses `CHANGE_ROLES_DELAY_SECONDS = 360`. The library's documentation of the type says: *"In practice, a delay of at least a couple hours is recommended."* Six minutes is an order of magnitude under that, and the two reasons the library gives both apply here.

**The transaction validity window.** A private read of a delayed value sets the transaction's `expiration_timestamp` to the moment the read could stop being valid. Every mint, transfer and burn reads at least one such value (the issuer address; transfers read four), so **every value-moving transaction of this token expires 360 seconds after its anchor block**. A 161,493-gate transfer that takes a slow device longer than that to prove, or that waits in a congested mempool, is dead on arrival. The README's assumption that users prove on their own devices makes this a real constraint, not a theoretical one.

**The privacy set.** The expiration timestamp is visible. If most contracts on the network follow the library's guidance and use multi-hour delays, a transaction that expires six minutes after its anchor is distinguishable as one that interacted with a contract using a six-minute delay — potentially this one. The library calls this out as the leak that can *"fully defeat the purpose"* of the type. Whether it does depends on what other contracts on the same network use, which cannot be known from inside this repository.

**Why 360 was chosen, and what it buys.** It was set during the 5.2.0 migration as the seconds equivalent of the previous two-block delay, and the documentation's own example uses the same value. Its benefit is exactly the freeze-window argument in the assessment: a freeze or a listing bites in six minutes rather than hours, and the mitigation for the window — pause, schedule, wait, unpause — is short.

**The tension, stated plainly.** Compliance wants the delay short: a freeze that takes two hours to bite is a two-hour window in which a sanctioned holder can move funds. Privacy and usability want it long: a long delay is a wide validity window and a large anonymity set. The library's recommendation is written for the second pair of concerns; this token is built for the first. There is no value that serves both, and the current choice sits at the compliance end.

**Verdict: decide, and it belongs to the compliance owner together with the network operator.** Three things should be established before this is settled: what delay other contracts on the target network actually use (the privacy-set question); how long a transfer takes to prove on the devices holders will use (the validity-window question); and whether a freeze window of hours rather than minutes is acceptable to the issuer's compliance posture. Whatever is chosen, it should be one value for every delayed variable in the contract — a mix would fingerprint operations by which flags they read — and the assessment's Enforcement note, which currently states 360 seconds as a fact, should record the reasoning. The one thing that is clearly wrong is deciding it by the documentation's example value, which is how it is decided today.

### H-5. Patterns checked and absent

- **`self.enqueue(...)` to another contract:** none. The contract makes no cross-contract calls at all, so the "enqueueing publishes `msg_sender`" leak has no site beyond the `enqueue_self` calls analysed in H-1. `enqueue_incognito` is therefore not applicable.
- **L2→L1 messages:** none anywhere, so the "fully public message and L1 execution" exposure does not arise.
- **Unsupported primitives in public functions:** none. No ECDSA, AES-128, Blake2s or Blake3 in any `#[external("public")]` function, so the transpiler-panic failure mode does not apply. Public code uses only comparisons, arithmetic and state access.
- **Cross-contract utility calls:** none, so no getter depends on the wallet's `authorizeUtilityCall` hook. The one utility function (`balance_of_private`) reads only this contract's own notes.
- **Hardcoded "everything is fine" answers:** none found. `operateOnTransfer` returning without checking when no mode is enabled is the closest thing, and it is documented behaviour in both the module and the assessment rather than a stub.

---

## I. Dependency and interface granularity

### I-1. The workspace graph — checked, clean

| Crate | Type | Depends on |
|---|---|---|
| `cmtat_aztec_lib` | `lib` | aztec, compressed_string, uint_note, balance_set |
| `cmtat_aztec` | `contract` | the above + `cmtat_aztec_lib` (path) |
| `cmtat_aztec_debt` | `contract` | same |
| `cmtat_aztec_light` | `contract` | same |

- **No contract crate depends on another contract crate**, so the circular generated-interface hazard the framework warns about does not exist here.
- **No crate pulls in a whole contract to call one function**, because there are no cross-contract calls at all.
- **Shared code is in a `type = "lib"` crate**, which is the required structure and is what makes the three variants possible.

**One prose obligation worth naming:** `issuer_address` is documented as the party that must capture offchain note messages, and nothing in the contract can check that it does — the CHANGELOG's Security section states this plainly ("a sender who drops one is not detectable onchain"). Aztec has no ERC-165 equivalent, so **no interface check could be added even in principle**; this remains operational discipline and is correctly documented as such rather than guarded by code that could not exist.

**Verdict: nothing to do.**

---

## J. Modularity

### J-1. The generic type parameters are decorative, because their trait bounds are private

`ValidationModule<T, Context>` and `Freezable<T, Context>` are generic in `T`, bounded on `UserFlagsTrait` (`validationModule.nr:35`) and `FreezableFlagTrait` (`enforcementModule.nr:16`). Neither trait is `pub`.

**Verified by compiling a probe** — a separate contract crate depending only on `cmtat_aztec_lib`, declaring its own three-flag type and implementing the trait:

```
error: UserFlagsTrait is private and not visible from the current module
   ┌─ src/main.nr:12:28
   │
12 │         validationModule::{UserFlagsTrait, ValidationModule},
   │                            -------------- UserFlagsTrait is private
```

So `T` can only ever be the module's own `UserFlags` / `FreezableFlag`. Every declaration site in the repo confirms it: `ValidationModule<UserFlags, Context>`, `Freezable<FreezableFlag, Context>` in all three storage structs.

**Consequence.** The genericity reads as an extension point and is not one. A downstream contract wanting blacklist/whitelist plus one extra flag — the obvious first customisation — cannot have it, and discovers this only at compile time.

**Verdict: implement — two words.** Make both traits `pub`. There is no downside: they are already implemented for the module's own types and exporting them costs nothing. Then the type parameter means what it appears to mean.

**Done, after a second look at whether exposing the parameter is better than deleting it.** "Two words" was the cost of one of two consistent states; the other is to drop `T` altogether (`Freezable<Context>` over `FreezableFlag`, `ValidationModule<Context>` over `UserFlags`), which is what a reviewer applying "you aren't going to need it" would propose. The two were weighed on what the generic can actually deliver:

- **What `T` buys a downstream contract.** The module's screening reads exactly two predicates (`get_is_blacklisted`, `get_is_whitelisted`) and one (`get_is_frozen`). Everything else about `T` is the downstream contract's business: it can carry a KYC tier, a jurisdiction, a freeze reason, and enforce those itself by reading `map.at(address).get_current_value()`, which is `pub`. That is the customisation a regulated issuer asks for first, and it needs no change to the library. The `operationsFlag` (`SetFlag`) is *not* generic, so the module's own enforcement cannot be extended; that boundary is now stated in the trait docs.
- **What it costs.** Nothing at runtime: Noir monomorphises, so `ValidationModule<UserFlags, _>` compiles to the same circuit as a non-generic module. Nothing in storage: `T`'s packing only sizes the per-address `DelayedPublicMutable` (`2 * N + 2` slots), which is the same accounting the module already does for `UserFlags`. One thing in API terms: a `pub` trait is a public contract, so adding a method to it later breaks every downstream implementor and is a MAJOR change under this project's semver policy. Both traits are one and two methods and are unlikely to grow; the note is in the changelog.
- **What deleting `T` would cost.** A signature change on both modules and all three storage structs for no capability gained, and the loss of the extension point that J-3 was written to confirm the modules have.

**Verified by compiling a second probe**, the mirror image of the first: a contract crate depending only on `cmtat_aztec_lib`, declaring a three-flag `KycFlags { is_blacklisted, is_whitelisted, is_kyc }` (derived `Packable`, hand-written `ToField`/`FromField`, `impl UserFlagsTrait`) and a `FreezeWithReason { is_freezed, reason: u8 }` (`impl FreezableFlagTrait`), using `ValidationModule<KycFlags, Context>` and `Freezable<FreezeWithReason, Context>` in storage, with public `add_to_list` / `set_operations` / `freeze` entry points and a private function that runs `operateOnTransfer` and then asserts the downstream-only `is_kyc` bit. `aztec compile` exits 0 and emits the artifact. The two traits carry doc comments stating the contract a `T` must satisfy and the packing cost. Suite unchanged at 89/89; the ABI of the three variants is unchanged, so no artifact regeneration is forced.

### J-2. ⚠️ Corrected — tests live in the contract crates, but the compiler does not object

`#[test]` functions live inside the contract crates (`contracts/*/src/test/*.nr`, 75 tests across three crates), not in separate test crates. General Aztec guidance holds that `aztec compile` warns about this.

**It does not, at 5.2.0.** A full `aztec-nargo compile --workspace` produced 33 warnings, all of them from aztec-nr's macro expansion and none mentioning tests. The expected warning did not reproduce, and I am recording that rather than repeating the claim.

**What remains true** is the build-time consequence: `#[test]` functions in a contract crate are part of that crate's compilation unit, so a test-only edit recompiles the contract. With three contract crates and a workspace build measured in minutes, that is a real cost on the inner loop — but it is a build-time consideration, not a correctness or convention violation, and the current layout keeps each variant's tests beside the variant they exercise, which has its own value (see D-2 for why `setup` cannot be shared anyway).

**Verdict: leave.** Reported so that the next reviewer who reaches for the "tests in the wrong crate" finding sees that it was checked and that the usual evidence for it is absent here.

### J-3. The module structs are genuinely reusable — verified by compilation

The central Aztec modularity question is whether a *different* contract can hold one of this project's modules in its own `#[storage]`. Because `#[storage]` may be used once per contract, the unit of storage reuse must be a struct implementing `StateVariable<N, Context>` with `new(context, storage_slot)` and `get_storage_slot` — which is exactly what every module here does.

**This was tested rather than asserted.** A throwaway contract crate (`probe_reuse`) depending only on `cmtat_aztec_lib` was written to hold `AccessControlModule` and `ValidationModule<UserFlags>` in its own storage struct, expose `set_operations` / `get_operations`, and — the part that matters — call `operateOnTransfer` from a **private** function:

```noir
#[storage]
struct Storage<Context> {
    access_control: AccessControlModule<bool, Context>,
    validation_module: ValidationModule<UserFlags, Context>,
}

#[external("private")]
fn guarded_op(from: AztecAddress, to: AztecAddress) {
    self.storage.validation_module.operateOnTransfer(from, to);
}
```

**It compiles, with no changes to the library.** The probe crate was then deleted.

That is a stronger result than "the code looks modular": a downstream project can lift the validation module — including its private-context read path, which is the hard part — into an unrelated contract. The same shape applies to `PauseModule`, `Freezable` and `ExtraInformation`.

**Two caveats the probe also established:**

1. It works because `UserFlags` is the library's own type. Substituting a custom flag type fails on J-1.
2. The modules take their `AccessControlModule` as an explicit parameter (`ac: AccessControlModule<bool, PublicContext>`) rather than reaching for `self.storage.access_control`. That is the hook pattern, done right: a host supplies its own access control instead of being forced to have a field with a particular name and semantics. It is the single design decision that makes the probe compile, and it is worth naming so that a future refactor toward "convenience" does not undo it.

**Verdict: keep — and consider promoting the probe.** If reuse is a property the project wants to hold, the probe crate belongs in the workspace as a compiling test fixture; otherwise the property regresses silently the first time a module reaches into its host's storage. That said, this project has three known deployments and no prospective external consumer, so **do not manufacture further modularity work here** — the structure is already better than it needs to be for its current use.

### J-4. Legibility — checked, clean

```
./lib/Nargo.toml                          type = "lib"        (no contract — correct)
./contracts/cmtat-aztec/Nargo.toml        type = "contract"   pub contract CMTATAztec
./contracts/cmtat-aztec-debt/Nargo.toml   type = "contract"   pub contract CMTATAztecDebt
./contracts/cmtat-aztec-light/Nargo.toml  type = "contract"   pub contract CMTATAztecLight
```

Every `type = "contract"` crate contains exactly one `pub contract`, whose name matches the directory. The `type = "lib"` crate contains no contract and is named for what it is. No crate has grown a second conceptual contract inside one `#[aztec]` module. A reader can tell what each crate is from its name and manifest.

---

## Method and limitations

**What was run.** `aztec-nargo compile --workspace` (clean, exit 0); `aztec test --workspace` (75 tests passing at review time: 62 base, 9 debt, 4 light; 76 after the A-1/G-2 regression test); `aztec profile gates ./target` for the baseline and for three before/after comparisons; three throwaway contract crates compiled for J-1 (before and after the fix) and J-3 and deleted; a full-text sweep of `.nr` sources for doc pointers, attribute usage, emit sites and trait visibility.

**What was reasoned about but not executed.**

- **Whole-transaction cost.** `aztec-wallet profile` needs a running sandbox, which this review did not start. Every kernel figure quoted (~290k fixed, ~101k per private call) is from the framework documentation, not measured here, and is used only to argue about the shape of a change — never as a finding's evidence.
- **Public gas.** Nothing in B-3, B-4 or the public halves was measured in gas. Where a public-side saving is claimed it is stated as a change in `Packable::N` (a slot count), with the measurement gap named.
- **The e2e suite.** `yarn test:js` was not run; it needs a sandbox and the `CHANGE_ROLES_DELAY_SECONDS` wait. No finding depends on it.

**Before acting on any structural finding**, note the refactoring hazards that apply to this contract specifically:

- **B-1 and B-3 are storage-layout changes.** `#[storage]` allocates slots sequentially in declaration order, so changing any module's packed length moves every state variable declared after it and orphans the public state at the old slots.
- **There is no upgrade path.** The contract is not upgradeable and there is no proxy; the CHANGELOG says so. A storage change is a redeployment plus a holder migration, and because balances are notes in holders' own PXEs, the issuer cannot perform that migration unilaterally. Nothing in this report should be deferred to "we can fix it in an upgrade".
- **Note layout is untouched by every finding here**, which is fortunate: the storage slot feeds the note hash and the note hash feeds the nullifier, so a change there would make existing notes unspendable. No recommendation in this report alters `UintNote` or the `balance_set` layout.
- **E-1/E-2 do not change the ABI** (attributes and return markers only), so no TypeScript regeneration is forced. C-1/C-3/C-4 add events, which do change the artifact; `yarn codegen` and `yarn typecheck` must run in the same change.

**How to guard what this report recommends.** For A-1, the guard is not a unit test — a functional test cannot see a gate count. Capture `aztec profile gates --json ./target` and diff it in CI. For E-1, the guard is a test that *compiles*: a caller exercising the read path, so removing `#[view]` breaks the build. For G-1 and G-4, the "test" is against the documented claim, not the code.

---

*Produced with Claude Code against `aztec` 5.2.0 / `aztec-nr` v5.2.0 / Noir 1.0.0-beta.25, commit `6728a8a`, on 2026-09-09. Findings were verified against the code at that commit; line numbers drift.*
