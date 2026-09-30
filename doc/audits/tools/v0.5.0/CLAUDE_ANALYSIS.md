# private CMTAT on Aztec — code-quality review, 0.5.0

**Scope.** The repository at `0.5.0`, HEAD `d25f431`. Aztec CLI **5.2.0**; `aztec-nr` pinned at tag **v5.2.0** in `lib/Nargo.toml`; `@aztec/*` at 5.2.0. Date 2026-09-30. Produced with Claude Code.

**Nothing in this report is a vulnerability.** Nothing here lets an unauthorized party move value, spend another holder's note, bypass a restriction or brick a contract. Privacy findings, which on Aztec are the ones that matter most and are not "vulnerabilities" in the usual sense, would be in section **H** — this review adds none, for the reason in A-1.

**This is a delta review, and deliberately short.** The only change to contract or library source since `v0.4.0` is the `VERSION` string, five times:

```
$ git diff v0.4.0..HEAD --stat -- contracts/ lib/ test-helpers/
 5 files changed, 5 insertions(+), 5 deletions(-)
-    pub global VERSION: str<31> = "0.4.0                          ";
+    pub global VERSION: str<31> = "0.5.0                          ";
```

`lib/` is untouched. Re-running the full checklist would therefore reproduce [the 0.4.0 review](../v0.4.0/CLAUDE_ANALYSIS.md), which remains the current analysis of this code. What this review does instead: verify the version bump is cost-neutral, review the genuinely new code — three tests and one test helper — and carry the 0.4.0 report's open items forward. Checks **B, C, E, F, H, I, J** were **not re-run**; no source they examine changed.

## Disposition summary

| ID | Finding | Outcome |
|---|---|---|
| A-1 | The `0.4.0 → 0.5.0` bump is gate-neutral across all 40 measured circuits | ⬜ leave — verified, nothing to change |
| D-1 | `setup_and_more_addresses_public_side` duplicates its sibling and drops a parameter | ⬜ open — one-line fix, proposed below |
| K-1 | Debt and Light assert `total_supply` nowhere at all | ⬜ open — predates 0.5.0 |
| K-2 | The mechanism that compensates for audit finding F-1 has no test | ⬜ open — the strongest finding here |
| K-3 | The new log-count assertions are framework-version-brittle | ⬜ leave — house style, cost recorded |

## Outstanding

| ID | Item | Why it is still open |
|---|---|---|
| K-2 | No test asserts the issuer receives `CommitmentInitialized` | Found while reviewing this release's own tests; a mechanical fix, not yet written |
| K-1 | No supply assertion in the Debt or Light suites | Needs a decision on how much the variant suites should mirror the base one |
| — | Mutations M-3 … M-5 from the 0.4.0 security review | Three five-contract compile cycles; carried forward |
| — | `doc/cmtat-assessment/README.md` still reports `0.4.0` | Correct until the assessment is redone against 0.5.0 |

## Gate-count baseline

`aztec profile gates ./target` after `yarn compile`, against the 0.4.0 report's recorded table. Per-function circuit gates only, no kernel overhead.

**40 of 40 circuits identical, 0 changed.** Compared mechanically rather than by eye:

```
identical: 40   changed: 0   missing: 0
```

Spot values, unchanged in all three token variants: `transfer_private_to_private` 119,290 / 119,290 / 108,882 · `mint_to_private` 61,062 / 61,062 / 54,862 · `burn` 69,434 / 69,434 / 63,235 · `transfer_private_to_commitment` 50,857 / 50,857 / 44,658 · `_recurse_debit` 30,138 in all three · `initialize_transfer_commitment` 39,820 / 39,820 / 33,621 · `authorize_private` 14,650 (Auth) and 14,651 (MultiToken). The four `private_get_*` circuits measure 8,229–8,347, matching the range the 0.4.0 report recorded.

### A-1. A `str<31>` constant change costs nothing, measured

`VERSION` is a compile-time constant returned through `FieldCompressedString`, so the expectation was that no circuit would move. Expectations about circuit cost are exactly what this review is not allowed to trade on, so it was measured: every one of the 40 functions in the 0.4.0 table reports the same gate count at 0.5.0.

**Verdict: leave.** The value is worth recording rather than assuming, because it establishes that the release changed no cost and that any future movement in these numbers came from something else.

## D. Duplication

### D-1. The new test helper duplicates its sibling and silently drops a parameter

`utils.nr` now has two helpers whose bodies differ by one line:

```noir
pub unconstrained fn setup_and_more_addresses(with_account_contracts: bool) -> (...) {
    let (mut env, token_contract_address, issuer, user1) = setup(with_account_contracts);
    let user2 = env.create_light_account();
    let user3 = env.create_light_account();
    (env, token_contract_address, issuer, user1, user2, user3)
}

pub unconstrained fn setup_and_more_addresses_public_side() -> (...) {   // added in 0.5.0
    let (mut env, token_contract_address, issuer, user1) =
        setup_with_public_side(false, /* public_side_enabled */ true);
    ...identical...
}
```

Two defects, both mine, introduced by this release:

- Six of the seven lines are copied, and the pair will drift the first time the setup sequence changes.
- The new one **drops `with_account_contracts`**, hard-coding `false`. A later authwit test that needs several holders and the public side has no helper and will add a third copy.

The project's own convention argues the fix: `setup` already delegates to `setup_with_public_side` rather than duplicating it. The same shape applies here.

```noir
pub unconstrained fn setup_and_more_addresses(with_account_contracts: bool) -> (...) {
    setup_and_more_addresses_with_public_side(with_account_contracts, false)
}

pub unconstrained fn setup_and_more_addresses_with_public_side(
    with_account_contracts: bool,
    public_side_enabled: bool,
) -> (...) { ...the single body... }
```

**Verdict: implement.** It touches one call site (`test_invariants.nr`) and no contract code. Not done here because it renames a helper the same release just introduced, and that belongs in one commit with the call-site change rather than bundled into a review.

## G. Code / documentation mismatch

The 0.5.0 changelog claims the suite is "242 tests (146 base, 12 Debt, 7 Light, 38 and 37 authorization) plus 2 library tests". Counted rather than trusted:

```
cmtat-aztec: 146   auth: 38   auth-multitoken: 37   debt: 12   light: 7   lib: 2   TOTAL: 242
```

The claim holds. No mismatch found in the `doc/README.md` text this release changed; the new passage cites `tests/cmtat-aztec/src/test_invariants.nr` by path, which is a documentation-to-test reference rather than the contract-source-to-docs pointer check G warns about — the test crate is never deployed, so a stale path there misleads a reader but cannot ship inside a contract class. **Acceptable, with that reason recorded.**

## K. Tests

| Contract | Tests | Entry points tested | Asserts with a negative test | Mutants survived |
|---|---:|---|---|---|
| `CMTATAztec` | 146 | all 17 private, all public getters | 18 of 19 distinct messages | 0 of 2 run |
| `CMTATAztecDebt` | 12 | smoke + selectors + debt/credit events | shares the library's asserts | not run |
| `CMTATAztecLight` | 7 | smoke + selectors + hybrid | shares the library's asserts | not run |
| `CMTATAztecAuth` / `MultiToken` | 38 / 37 | hook, lists, admin, delay | — | not run |

The single unmatched assert message across the codebase is `Storage slot 0 not allowed…`, a `StateVariable::new` guard no entry point can reach — untestable rather than untested. Two mutations were run during the 0.4.0 security review and both were killed; three remain.

### K-1. Debt and Light never assert `total_supply`

```
$ grep -c total_supply tests/cmtat-aztec-debt/src/test_hybrid.nr tests/cmtat-aztec-light/src/test_hybrid.nr
0
0
```

Neither variant's suite asserts supply anywhere, per-operation or in aggregate. The base variant now does both. Debt shares the token module byte for byte — its gate counts are identical to the base variant's on every value-moving function — so the invariant is the same code and a shared-module test arguably covers it. **Light does not.** It uses `FreezeOnly` screening, has no validation module, and compiles its own, shorter bridge circuits:

| Bridge | `CMTATAztecLight` | base and Debt |
|---|---:|---:|
| `transfer_private_to_public` | 43,330 | 53,737 |
| `transfer_public_to_private` | 36,425 | 46,833 |
| `transfer_private_to_commitment` | 44,658 | 50,857 |

A supply error reachable only through Light's shorter chain would be caught by nothing.

**Verdict: decide.** The question is how far the variant suites should mirror the base one — a standing choice this project has made deliberately elsewhere (`test_selectors.nr` exists precisely because declarations are the one thing the shared module cannot cover). One `supply_equals_the_sum_of_every_balance` twin in the Light crate is the smallest useful answer.

### K-2. The mechanism that compensates for F-1 has no test

The 0.5.0 tests pin that `transfer_private_to_commitment` emits **no** `Transfer` event, and `doc/README.md` now says the issuer reconstructs that movement from `CommitmentInitialized` plus the commitment-tagged completion log instead. Nothing tests the substitute:

```
$ grep -rn "CommitmentInitialized" tests/
tests/cmtat-aztec/src/test_invariants.nr:122:    // ...reconstructs it instead from `CommitmentInitialized` plus...
```

One hit, and it is a comment. So the release pins the absence of the primary mechanism and leaves the replacement — the thing that makes the audit story true on this path — asserted only in prose. Removing the `deliver_to(issuer, …)` from `_open_commitment` would keep the whole suite green.

The shape already exists in the repository: `test_issuer_records.nr` counts what an event leaves in a transaction, and `test_issuer_copies.nr` reads offchain messages from a second party's view. Either is enough to pin this.

**Verdict: implement.** This is the most valuable test this release could still gain, and it is mechanical.

### K-3. The new count assertions are framework-brittle

`test_invariants.nr` asserts exact private-log and nullifier counts (4 and 7 for a private transfer, 2 and 4 for a commitment payment). Those numbers include framework-side deliveries and handshake nullifiers, so a toolchain bump can move them without any change to this project — the test would fail and look like a regression.

Two mitigations are already present, which is why this is not a defect: the counts are commented with what each component is, so a reader can re-derive them, and the house style pins measured facts exactly this way (`test_issuer_records.nr` asserts the same shape). The nullifier half is the more brittle and buys the least — the log counts alone carry F-1.

**Verdict: leave**, with the cost recorded: at the next Aztec bump, expect these four numbers to need re-measuring, and re-measure rather than relaxing them to inequalities.

## What was not re-run

**B** (storage and packing), **C** (deliveries and events), **E** (macro conventions), **F** (standard conformance), **H** (privacy leakage), **I** (dependency granularity) and **J** (modularity) examine contract and library source, none of which changed. Their 0.4.0 conclusions stand unaltered. The three new tests add no entry point, no state variable, no delivery and no public call, so they cannot have moved **H** — which is the check a reader of an Aztec review looks at first, and the reason this is stated rather than left to inference.
