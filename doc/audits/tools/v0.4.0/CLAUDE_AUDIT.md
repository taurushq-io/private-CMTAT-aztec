# CLAUDE_AUDIT.md — security review of private CMTAT on Aztec, v0.4.0

**Tool.** Claude (Anthropic), driven by a set of custom smart-contract security-audit skills.

**Codebase.** `private-CMTAT-aztec` at `0.4.0` — the five contracts `CMTATAztec`, `CMTATAztecDebt`, `CMTATAztecLight`, `CMTATAztecAuth` and `CMTATAztecAuthMultiToken`, and the shared library `cmtat_aztec_lib`. Built against **Aztec / aztec-nr v5.2.0** with CLI `5.2.0`, verified consistent across `lib/Nargo.toml`, `package.json` and the installed toolchain before any review began.

**Audited artifacts.** The review was performed against compiled artifacts, not source alone. Base contract class identifier `0x22f0b218eb7f21905705cbaf2e82f0610e794ea31ed4a247fcf7bac8d3464f73`; the full per-contract surface dumps are in [`surface/`](./surface).

**Severity framework.** Code4rena (Critical / High / Medium / Low / Info).

**Method.** Threat model over the Aztec execution model → enumeration of the privileged and externally reachable surface from the compiled artifacts → targeted review of each value-moving chain → mechanical verification passes (delivery modes, authorisation attributes, delayed state, oracle use) → mutation spot-checks against the test suite → adversarial self-review of every finding. *The specific internal skills used are intentionally not enumerated here.*

**This is a tool-assisted review, not a substitute for a professional security audit.** The contracts remain unaudited by a third party.

---

## 1. Scope

**In scope.** The five contract packages and `lib/src/modules/*`, including the value-moving chains, the authorization-hook rules, the access-control, pause, enforcement, validation and extra-information modules, and the two debt extensions. The Noir test suite was reviewed as part of the work, since a control attested only by a test that cannot fail is not attested.

**Out of scope.** The Aztec protocol itself (L1 rollup contracts, governance, proving system); the `aztec-standards` fork carried as a submodule, except where the authorization contracts couple to it by selector; the TypeScript scripts and the end-to-end suite, except where they establish the deployed configuration; economic and governance design.

**Not attempted.** Formal verification, and any claim about gas or circuit cost beyond what the existing code-quality review measured.

---

## 2. Executive summary

**0 Critical, 0 High, 0 Medium, 0 Low, 1 Info.** One further candidate was raised and dismissed on adversarial review. No finding blocks the release.

The contracts are unusually defensive for a prototype, and three properties in particular are enforced structurally rather than per call site, which is what kept the finding count at zero:

- **The issuer's audit copy cannot be forgotten on a new path.** Both deliveries — the holder's constrained copy and the issuer's offchain copy — live inside the two shared helpers `credit_private` and `debit_private`, which every one of the six value-moving chains calls. A new operation gets the invariant by construction rather than by review.
- **The public half of a private transfer takes no arguments.** `_transfer()` carries nothing, so the only public disclosure of a private transfer is that one occurred.
- **Nothing in the codebase uses unconstrained delivery.** 32 constrained deliveries, 2 offchain (the issuer copies), zero `onchain_unconstrained` — so no receipt in the system is forgeable by its sender.

### Cleared hypotheses

Each of these would have been High or Critical had it held. Each was probed and does not.

| Hypothesis | Result | How it was established |
|---|---|---|
| An internal function is externally reachable without `#[only_self]` | **Does not hold** | Every `_`-prefixed externally callable function in all five compiled artifacts carries `#[only_self]`, checked attribute by attribute. `_grant_role_internal`, `_emit_listed` and `_open_commitment` are `#[internal]` and absent from the ABI entirely |
| An authorisation attribute names a parameter that was later renamed, silently detaching the check | **Does not hold** | All 24 `#[authorize_once]` attributes across the three tokens were matched mechanically against their function signatures |
| The admin can shorten the delay and land a freeze or issuer change earlier than the previous delay promised | **Does not hold** | The per-address setters route through the library's `schedule_delay_change`, whose rule was read at source in protocol-circuits v5.2.0: an increase applies immediately, a decrease only after the difference has elapsed |
| A prover-controlled oracle value gates a security decision | **Does not hold** | The codebase contains no `unsafe {}` block and no `random()` call. The four `push_nullifier_unsafe` uses are the no-note-existence-check API, over preimages (a commitment hash, an authwit hash) that cannot be forged |
| A public half receives an argument its private half was protecting | **Does not hold** | Every enqueued call was mapped to what it publishes; see §6 |
| The role check sits where public state is stale | **Does not hold** | Role and lifecycle checks are in the enqueued public half in every chain, never in private |

---

## 3. Findings

| ID | Severity | Status | Component | PoC |
|---|---|---|---|---|
| F-1 | Info | Open | `doc/README.md:368` | ✗ (test proposed) |

**Tally: 0 Critical, 0 High, 0 Medium, 0 Low, 1 Info.**

### F-1 — The `Transfer` stream is documented as a complete ledger; a commitment completion emits no event

**Severity.** Info. *Adjusted from Low during the adversarial pass — see below.*

**Component.** `doc/README.md:368`; `transfer_private_to_commitment` in all three token variants (base `contracts/cmtat-aztec/src/main.nr:1065-1084`).

**Description.** The specification states:

> The `Transfer` stream is therefore the issuer's on-chain, unforgeable **ledger**. Since 0.4.0 it covers every movement — mints (`from = 0`) and burns (`to = 0`) as well as transfers […] so replaying it reconstructs every holder's balance.

An event map over the contract shows nine emit sites. Every value-moving entry point reaches one except `transfer_private_to_commitment`, which emits nothing:

```noir
fn transfer_private_to_commitment(from, commitment, amount, authwit_nonce) {
    require_public_side_enabled(...);
    pay_commitment(...);            // debits `from`, completes the commitment for `to`
    self.enqueue_self._transfer();  // asserts !paused; no arguments
}                                   // <- no self.emit(Transfer { .. })
```

**Impact.** An issuer that implements the documented procedure — replay the `Transfer` stream to reconstruct balances — misattributes any commitment payment. The failure is **silent**: a replay misses both legs of the transfer, so the reconstructed balances still sum to `total_supply` and nothing looks wrong. The same over-reach applies to the two bridges, whose `Transfer` masks the private counterparty with `PRIVATE_ADDRESS_MAGIC_VALUE`, so the commitment path is not a unique exception.

**This is a documentation defect, not a code defect.** At completion the contract holds only the commitment, never the recipient's address — only `open_commitment` sees `to` — so no correct `Transfer{from, to, amount}` can be emitted there. The design's actual answer is sound and is documented twice elsewhere (`doc/README.md:557`, `doc/technical/commitment-reuse.md:172`): the issuer holds every commitment through the constrained `CommitmentInitialized` event, derives the completion-log tag from it, and reads the amount, which is unencrypted. Both event tables in the specification are exhaustive and correctly omit the commitment path. Only the prose sentence over-reaches.

**Reachability.** `public_side_enabled` is `false` in every deployment the repository ships or documents — `scripts/deploy_contract.ts:28` and `src/test/e2e/index.test.ts:98`, both commented *"keep the fully private token"*, and the default `setup()` of all three token test crates. The flag is immutable after construction.

**Recommendation.** Qualify the sentence at `doc/README.md:368` to the fully private paths it is true of — mint, burn, private transfer and their batches — and point at `:557` for the commitment path. Add the replay-reconciliation test in §8 so the claim is machine-checked rather than asserted.

**Severity adjustment.** Raised at Low, lowered to Info by the adversarial pass on three grounds: unreachable in every configuration the repository deploys, the correct mechanism documented in two other places, and no available code fix. Recorded against that verdict: the audit trail is the declared purpose of the instrument, this is the sentence an issuer would build regulatory reporting from, and the failure mode is undetectable — which makes Low defensible.

---

## 4. Invariant verification

Every invariant from the threat model, with the evidence that establishes it. An invariant asserted without evidence is an opinion.

| ID | Property | Holds? | Evidence |
|---|---|---|---|
| INV-1 | Every note created for a holder is delivered to that holder **and** copied to the issuer | ✅ | Structural: both deliveries are inside `credit_private` / `debit_private` (`tokenModule.nr:174-189`), which all six chains call. Asserted at runtime through `env.offchain_messages()` in `test_issuer_copies.nr` |
| INV-2 | Every movement emits a `Transfer` delivered constrained to the issuer | ⚠️ Partial | Holds for mint, burn, private transfer and their batches. The bridges mask the private counterparty; the commitment completion emits nothing — **F-1** |
| INV-3 | `total_supply` equals the sum of private and public balances | ❓ Unverified | No test asserts it across the bridges. Proposed in §8 — this is a gap, not a pass |
| INV-4 | A frozen or unlisted address can neither send nor receive | ✅ with one disclosed exception | `Screening` screens both parties on transfer, the recipient on mint, the account on burn, in both the `FreezeAndLists` and `FreezeOnly` implementations. **Mutation-verified:** removing the recipient check breaks `test_hybrid::private_to_public_reverts_for_frozen_recipient`. Exception: a commitment opened before a restriction can still be paid into — disclosed at `doc/README.md:557` and pinned by `a_recipient_frozen_after_opening_a_commitment_is_still_paid` |
| INV-5 | A pause stops transfers only; deactivation stops mint and burn; deactivation requires a pause and is irreversible | ✅ | `mint_public` and `burn_public` assert `!is_deactivated`; `require_transfer` asserts `!is_paused`. Matches CMTAT Solidity, where a pause does not stop issuance or redemption |
| INV-6 | A delayed value change never lands earlier than the entry's previous delay promised | ✅ | `schedule_with_delay` routes through the library's `schedule_delay_change`; the increase-immediate / decrease-after-difference rule was read at source in protocol-circuits v5.2.0 rather than inferred from comments. Eight tests in `test_roles_delay.nr` plus three per authorization crate |
| INV-7 | A commitment can be paid exactly once | ✅ | `commitment_paid_nullifier` pushed in the **private** half of `pay_commitment`. **Mutation-verified:** removing it breaks `a_second_payment_into_the_same_commitment_is_refused` and `a_sender_opened_commitment_cannot_be_paid_twice_either`, while `the_first_payment_into_a_commitment_is_received` still passes — so the tests discriminate rather than failing wholesale |
| INV-8 | No externally callable function mutates public state without `#[only_self]` or a role check | ✅ | Verified against all five compiled artifacts, not the source |

**On the strength of this evidence.** Noir has no coverage instrumentation, so no percentage appears in this report. Coverage was established by inventory instead: **72 assert sites, none without a message, 19 distinct messages, 18 matched by a negative test.** The single unmatched message is a `StateVariable::new` storage-slot guard that no entry point can reach. Two of five budgeted mutations were run and both were killed; the three unrun ones are recorded as an open item in §8, because the assert inventory alone cannot tell whether a negative test reaches the assert it names.

---

## 5. Access-control verification

| Entry point | Expected guard | Verified |
|---|---|---|
| `_mint`, `_burn` | `#[only_self]` + `MINTER_ROLE` / `BURNER_ROLE` + not deactivated | ✅ all three tokens |
| `_transfer` | `#[only_self]` + not paused, no arguments | ✅ all three tokens |
| `_credit_public`, `_debit_public` | `#[only_self]` + not paused | ✅ all three tokens |
| `_recurse_debit` | `#[only_self]` | ✅ all three tokens, plus a test that an outside caller is refused |
| `_require_lifecycle_allows` | `#[only_self]` | ✅ both authorization contracts |
| `grant_role` / `revoke_role` | role admin | ✅ negative tests present |
| `freeze` / `unfreeze` | `ENFORCEMENT_ROLE` | ✅ |
| `add_to_list` / `remove_from_list` | `ADDRESS_LIST_ADD_ROLE` / `_REMOVE_ROLE` | ✅ |
| `set_issuer`, `set_roles_delay` | `DEFAULT_ADMIN_ROLE`, delay bounded 1 s – 86 400 s | ✅ zero and out-of-range rejected |
| `set_terms`, `set_token_id` | `EXTRA_INFORMATION_ROLE` | ✅ |
| `set_debt*`, `set_credit_events` | `DEBT_ROLE` / `DEBT_CREDIT_EVENT_ROLE` | ✅ Debt variant |
| `constructor` | single-use | ✅ `the_initializer_cannot_be_called_a_second_time` (`duplicate nullifier`) |
| 8 value-moving entry points per token | `#[authorize_once]` bound to a real parameter | ✅ 24 of 24 |

**Negative results, stated deliberately.**

- **The issuer cannot move a holder's notes.** Spending requires the owner's nullifying key, which the issuer does not hold. Forced transfer and forced burn are not implementable by any role or contract change — freezing is the only enforcement lever. This is a structural property, not a gap that could be closed.
- **`MINTER_ROLE` cannot burn, `BURNER_ROLE` cannot mint**, and a burn additionally requires the holder's authwit.
- **No role can bypass screening.** The freeze and list checks run in the private half of every chain, before any role is consulted.
- **The authorization contracts do not screen the recipient**, because the ARC-403 hook is not passed one. Disclosed in `doc/auth/README.md` and pinned by `blacklisted_recipient_is_not_screened`.

**Centralization premise, stated plainly.** `DEFAULT_ADMIN_ROLE` is the admin of every role and can therefore grant itself any of them, so it implicitly holds all eleven. It can also rotate the issuer and change the delay. This is inherent to the CMTAT role model and is **not** reported as a finding; a deployer should treat that key as the security boundary of the whole instrument. The delay is what bounds the damage: a freeze or issuer change cannot take effect sooner than the entry's current delay allows.

---

## 6. Privacy verification

For a token whose purpose is privacy, what each entry point publishes is a security property, not a footnote.

| Entry point | Enqueued public call | Published | Stays private |
|---|---|---|---|
| `mint_to_private` | `_mint(caller, amount)` | minter, amount | recipient |
| `transfer_private_to_private` | `_transfer()` | **only that a transfer occurred** | from, to, amount |
| `burn` | `_burn(caller, amount)` | burner, amount | account |
| `transfer_private_to_public` | `_credit_public(to, amount)` | to, amount | from |
| `transfer_public_to_private` | `_debit_public(from, amount)` | from, amount | to |
| `transfer_private_to_commitment` | `_transfer()` | occurrence; amount unencrypted in the completion log | from, to |
| `authorize_private` (auth contracts) | `_require_lifecycle_allows(is_burn)` | is_burn | from, amount, id |

No public half receives an argument that its private half was protecting. Two disclosures are deliberate and documented: the argument-free `_transfer()` reveals that a transfer of this token happened, accepted because the pause must be an immediate lever; and every transaction reading a delayed value publishes an expiration timestamp one delay after its anchor block.

---

## 7. Remediation — what was implemented

**Nothing yet. No code changed in response to this review.**

| Finding | Status | What changed | Verified by |
|---|---|---|---|
| F-1 | ⚠️ Open | — | — |

The review was run against the frozen `0.4.0` tree, and its only finding is a documentation over-reach with no code fix available. The recommended edit to `doc/README.md:368` had not been made when this report was written. This section is kept rather than omitted so that a later reader can see the fix status at the time of publication, and so that a doc-only change is never mistaken for a code change.

---

## 8. Potential improvements (open backlog)

Hardening and quality items. **These are not vulnerabilities**, and none of them is a finding; conflating the two would overstate the risk of the codebase.

| # | Improvement | Addresses | Effort | Breaking? | Priority |
|---|---|---|---|---|---|
| 1 | Complete mutation spot-checks M-3 … M-5 (mint lifecycle, commitment recipient screening, minter role) | INV-5, INV-4 attestation | Medium | No | High |
| 2 | Assert `total_supply` = Σ private + public balances after a mixed sequence including bridges | INV-3 | Low | No | High |
| 3 | Replay the `Transfer` stream over a run including a commitment payment and reconcile against `balance_of_private` | F-1 | Low | No | Medium |
| 4 | Pin each entry point's public footprint — enqueued calls, public logs, nullifier count | privacy regressions | Medium | No | Medium |
| 5 | Test `set_roles_delay` to a shorter delay immediately followed by `freeze` | INV-6 | Low | No | Medium |
| 6 | Test the authorization hook with a selector that is neither a known burn nor a transfer | hook classification | Low | No | Low |
| 7 | Add the NatSpec `@dev` / `Requirements:` comment to `only_role` and `has_role` | project convention | Low | No | Low |
| 8 | Commitment expiry | the disclosed screening window | High | Yes | Design decision |

**Rationale for the ones that are not self-evident.**

- **(1) is the highest-value item in this table.** Two mutations were run and both killed, which is evidence that the suite bites. Three invariants — including "a pause does not stop issuance" — currently rest on the assert inventory alone, and that inventory cannot distinguish a negative test that reaches its assert from one that stops at an earlier check. Each mutation costs one full five-contract compile; run them in a `git worktree`, never in the working tree, so a killed run cannot leave patched artifacts in `target/`.
- **(2)** is the only invariant in §4 with no evidence at all. It is cheap and it would have caught any accounting error across the bridges, which are this release's newest code.
- **(4)** would turn the privacy table in §6 from a review artifact into a regression guard. Today, a change that starts publishing an argument passes the suite.
- **(8) is a design decision for the maintainers, not a defect.** Without expiry, a commitment opened before a freeze or delisting stays payable indefinitely, so the recipient-screening rule can be outrun by pre-opening one. The project has already disclosed this (`doc/README.md:557`), pinned it with a test, and recorded expiry as a prerequisite in its own AIP-20 feature analysis. The options are: leave it as a disclosed limitation of a flag that ships off; add an expiry timestamp to the commitment, which changes the note layout and is therefore MAJOR; or screen the recipient again at completion, which the current flow cannot do because it never learns `to`. Presented neutrally — the first is defensible while `public_side_enabled` is off by default.

---

## 9. Scope and duplicate check

**In scope.** All findings and improvements above concern contracts and documentation inside this repository.

**Duplicates.** F-1 does not duplicate the 0.4.0 code-quality review in [`CLAUDE_ANALYSIS.md`](./CLAUDE_ANALYSIS.md), which covers circuit cost, the token-module refactor and test quality rather than the audit-trail claim. No static analyser was run: there is no Slither equivalent for Noir, and the compiled-artifact surface enumeration was used in its place.

**Considered and dismissed.** Recorded so that no threat reads as "never considered".

| Observation | Disposition |
|---|---|
| `only_role` exported in the ABI of all five contracts | **Dismissed.** `#[view]`, mutates nothing, exposes only what `has_role` already returns; documented at `doc/README.md:456`, deliberate since a prior release, and pinned by two tests that call it through `env.view_public`. Removing the export would break the suite |
| A commitment recipient frozen after opening can still be paid | **By design, disclosed** at `doc/README.md:557`, pinned by a test. Backlog item 8 |
| Batch caps exceeded, corrupting `total_supply` | **Not runtime-reachable.** The caps are compile-time array lengths in the ABI; raising one is a build-time decision that requires re-running the suite |
| Note fragmentation denial of service | **Mitigated by design.** Two notes, then recursion at eight per call; a fragmented balance costs a nested call rather than failing |
| The authorization hook's burn-selector list drifting from the fork | **By design, disclosed** in `doc/auth/README.md`, fail-closed (a misclassified burn is stopped by a pause, never allowed through), and pinned by a selector test |
| The MultiToken hook discards the token `id` | **By design, disclosed** at `doc/auth/README.md:52`: pause, freeze and the lists apply to every id alike |
| Anyone may call `authorize_*` on the authorization contracts | **No impact, disclosed.** The calls only assert and enqueue a check on the contract's own state |
| A private entry point answering an AIP-20 selector with different authorisation | **Does not occur.** `burn` is deliberately not named `burn_private` precisely because its authorisation differs; the profile is pinned in `test_aip20_profile.nr` |
| Transaction fingerprinting and the public expiration timestamp | **By design, disclosed**, decided under the project's own `H-3` and `H-6` |
| No upgrade path; notes cannot be migrated by the issuer alone | **Accepted and documented.** A consequence of private balances living in holders' PXEs |
