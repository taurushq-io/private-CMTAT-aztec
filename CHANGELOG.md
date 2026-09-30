# CHANGELOG

Please follow [https://changelog.md/](https://changelog.md/) conventions.

> **This code has not been audited.** It is a prototype of a private CMTAT on Aztec, published for review and experimentation, and it is not fit for production use with real assets.

## Semantic Version 2.0.0

Given a version number MAJOR.MINOR.PATCH, increment the:

1. MAJOR version when the new version makes:
   - An incompatible change to contract **storage** — the `#[storage] struct Storage` layout, a state-variable type (`PublicMutable` / `DelayedPublicMutable` / `Owned<BalanceSet>`), or the shape of a note (`UintNote`) or a packed struct (`UserFlags`, `FreezableFlag`, `Terms`, `CreditEventsStruct`, `DebtInformation`)
   - A significant change in external APIs (`#[public]` / `#[private]` / `#[utility]` functions, their arguments, or the numeric role constants) or in the internal architecture
   - A change to the Aztec/`aztec-nr` version that alters the contract class ID or breaks previously generated artifacts
2. MINOR version when the new version adds functionality in a backward compatible manner
3. PATCH version when the new version makes backward compatible bug fixes

See [https://semver.org](https://semver.org)

> **No upgradeability.** Unlike the Solidity CMTAT, this contract cannot be upgraded behind a proxy: any MAJOR change means deploying a new contract and migrating holders. Private balances live as notes in each user's PXE, so a migration is not a storage copy — plan it as part of the release.

## Type of changes

- `Summary`: main new features/change with a description (keep it short) (not a changelog tag)
- `Added` for new features.
- `Changed` for changes in existing functionality.
- `Deprecated` for soon-to-be removed features.
- `Removed` for now removed features.
- `Fixed` for any bug fixes.
- `Security` in case of vulnerabilities.

Reference: [keepachangelog.com/en/1.1.0/](https://keepachangelog.com/en/1.1.0/)

Custom changelog tag: `Dependencies`, `Documentation`, `Testing`

## Entry style

- One line per bullet or paragraph — never hard-wrap prose. Markdown renders a wrapped bullet identically, but a one-word edit reflows every following line and buries the real change in diff noise. Keep line structure only where it is semantic: fenced code blocks, tables, blockquotes.
- Past roughly three sentences, split a bullet into a lead sentence naming what changed plus one sub-bullet per distinct claim — impact, fix, behaviour-change warning, migration note. Sub-bullets are one line each too.

## Checklist

> Before a new release, perform the following tasks

- Code: update `VERSION` in each contract's `main.nr` ([cmtat-aztec](./contracts/cmtat-aztec/src/main.nr), [cmtat-aztec-debt](./contracts/cmtat-aztec-debt/src/main.nr), [cmtat-aztec-light](./contracts/cmtat-aztec-light/src/main.nr), and the two authorization contracts [cmtat-aztec-auth](./contracts/cmtat-aztec-auth/src/main.nr) and [cmtat-aztec-auth-multitoken](./contracts/cmtat-aztec-auth-multitoken/src/main.nr), which carry the same number), and check the mirrors — the `Implementation version` row of `doc/cmtat-assessment/README.md`, and the version named in any release tag.
- Pin one Aztec version, and check that it is the same in all three places: the `tag = "vX.Y.Z"` entries in [Nargo.toml](./Nargo.toml), the `@aztec/*` versions in [package.json](./package.json), and the `aztec-up X.Y.Z` instruction in [README.md](./README.md) and [doc/README.md](./doc/README.md)
- Rebuild artifacts from a clean tree, so the release is not validated against a stale `src/artifacts/`

```bash
yarn clean
yarn compile
yarn codegen
```

- Run the formatter over the Noir sources and type-check the TypeScript

```bash
aztec-nargo fmt          # or: nargo fmt (at 5.2.0 aztec-nargo is a bare nargo, which is fine for fmt)
yarn typecheck           # never `npx tsc`: it can resolve to the Aztec toolchain's own compiler
```

- Run both test profiles — neither one covers the other

```bash
yarn test:nr             # Noir/TXE unit tests in contracts/*/src/test/
yarn test:js             # Jest e2e tests in src/test/e2e/, requires: aztec start --local-network
```

- Documentation
  - Update [doc/README.md](./doc/README.md) whenever the specification changes: the assumptions, the per-operation privacy requirements, the module descriptions, and the limitations list
  - Update the agent guide, and keep [CLAUDE.md](./CLAUDE.md) and [AGENTS.md](./AGENTS.md) byte-for-byte identical (`diff CLAUDE.md AGENTS.md` must be empty)
  - Check that no Markdown file mixes hard-wrapped and one-line-per-block prose
  - Update this changelog

## 0.5.0 — unreleased

`version()` returns `0.5.0` in all five contracts. Nothing so far changes contract behaviour: this release is the security review of 0.4.0, the tests it asked for, and the one documentation correction it found. These entries sit here rather than under 0.4.0 because the `v0.4.0` tag does not contain them.

### Changed

- `VERSION` bumped to `0.5.0` in the three token contracts and the two authorization contracts; the two authorization-contract tests that pin the value follow it.

### Testing

- Three tests in `test_invariants.nr` close the two gaps the security review left open, neither of them needing a contract change.
  - `total_supply` is now asserted against the sum of every balance, private and public, across four holders and a mixed sequence — two mints, a private transfer, both bridges and a burn. Individual bridge tests already checked that supply was unmoved by one call; the invariant itself had no test, so a bridge that credited without debiting would have passed the suite.
  - Two tests pin the reach of the `Transfer` event stream by counting what a transaction leaves. A warm `transfer_private_to_private` leaves two notes and four private logs — one per note plus the event's two constrained deliveries, to the recipient and to the issuer. A `transfer_private_to_commitment` of the same value leaves the same two notes and **two** logs: no event at all, because at completion the contract holds the commitment and never the recipient's address. Either path gaining or losing an event now fails the suite.
  - A balance-level replay of the event stream is not expressible in the TXE, which cannot read a private event's content, so these count logs instead; the reasoning is in the tests' own comments.
  - New helper `setup_and_more_addresses_public_side` in the base crate's `utils.nr`, for tests needing several holders with the public side on.
- The Debt and Light suites gained the supply invariant, which neither asserted anywhere before — not in aggregate and not per operation (0.5.0 review, K-1). Light is the variant that needed it: `FreezeOnly` screening and no validation module mean its value-moving chains compile to their own shorter circuits, so a supply error reachable only through them had nothing to catch it. Debt shares the token module byte for byte, and its twin exists because the crate asserted supply nowhere at all.
- The Noir suite is 244 tests (146 base, 13 Debt, 8 Light, 38 and 37 authorization) plus 2 library tests.

### Documentation

- `doc/README.md` no longer presents the `Transfer` event stream as covering every movement without qualification. The claim is now scoped to the fully private token, where it holds, and the two public-side exceptions are stated.
  - The bridges publish a `Transfer` naming their public party and the `PRIVATE_ADDRESS_MAGIC_VALUE` sentinel for the private one, so the movement is recorded but the private counterparty is not.
  - A commitment completion emits no `Transfer` at all, and cannot: at completion the contract holds the commitment and never the recipient's address, so an event naming an unverifiable recipient would be forgeable by the payer. The issuer reconstructs these from `CommitmentInitialized` plus the commitment-tagged completion log, which the same section already described.
  - Both paths exist only when a token is deployed with `public_side_enabled = true`; nothing changed for a fully private deployment, and no contract code changed at all.
- Added `doc/audits/tools/v0.5.0/CLAUDE_ANALYSIS.md`, the code-quality review of this release. It is a delta review and says so: the only change to contract or library source since `v0.4.0` is the `VERSION` string, so the 0.4.0 review remains the current analysis of the code.
  - The bump is **gate-neutral, measured**: all 40 circuits in the 0.4.0 baseline report the same gate count at 0.5.0, compared mechanically rather than by eye.
  - Three findings against this release's own new code. The new `setup_and_more_addresses_public_side` helper duplicates its sibling and drops the `with_account_contracts` parameter; the Debt and Light suites assert `total_supply` nowhere at all, and Light compiles its own shorter bridge circuits, so nothing would catch a supply error reachable only through it; and the mechanism that compensates for the security review's F-1 — the issuer's `CommitmentInitialized` event — has no test, so removing its delivery would leave the whole suite green.
  - The checks that examine unchanged source were not re-run, and the report lists which and why rather than implying a full pass.
- Added `doc/audits/tools/v0.4.0/CLAUDE_AUDIT.md`, the tool-assisted security review of the 0.4.0 release. The review is described in the 0.4.0 section below; the file itself landed after the tag.

## 0.4.0 — 2026-09-29

Commit: `1d63038a5ff813ac04f9aa909d5343b5850c7cd4`

MAJOR under the policy above: a packed struct changed shape on `CMTATAztecDebt`, five entry points were renamed, and the constructor takes a new argument, so 0.4.0 is not compatible with a 0.3.0 deployment. `version()` returns `0.4.0` in all five contracts. Built and tested on Aztec **5.2.0**.

### Summary

- Two new contracts that are not tokens: `CMTATAztecAuth` and `CMTATAztecAuthMultiToken` apply CMTAT's pause, deactivation, freeze and a sender-side blacklist / whitelist to the stock `aztec-standards` AIP-20 `Token` and ARC-1155 `MultiToken` through the ARC-403 hook those contracts already call. The repository now ships five contracts over one library.
- The three token variants gained the four AIP-20 private/public bridges and `balance_of_public`, all behind a new constructor flag `public_side_enabled`, so a deployment that wants none of them behaves exactly as 0.3.0 did. Each bridge runs the full CMTAT chain: both parties screened in private, the issuer's copy of every note, the pause check in the enqueued public half.
- The mint, transfer, burn and bridge chains moved out of the three `main.nr` files into `lib/src/modules/tokenModule.nr`, so the compliance chain exists once instead of three times. Verified gate-neutral circuit by circuit.
- Three breaking changes, each deliberate: the delay on every delayed value is one hour instead of six minutes and is now adjustable at runtime up to 24 hours; `CreditEventsStruct` packs into two storage Fields instead of three; and five entry points carry the AIP-20 names so the private profile answers the standard's selectors, which `burn` deliberately does not join because its authorisation differs.
- Three guarantees that were missing rather than wrong: a debit now spends two notes and recurses for more instead of compiling for sixteen (−42,000 gates on every debit, and a fragmented balance costs a nested call rather than failing), a commitment can be paid exactly once, and mints and burns deliver the same constrained `Transfer` event to the issuer — so the issuer's event stream is a complete, unforgeable ledger and the note copies are only corroboration.
- The tests were audited as code. They moved out of the contract crates, where a test edit invalidated the artifact; mutation spot-checks found two invariants that no test could fail, including the issuer-copy rule the whole audit story rests on; and `aztec test` was found to be running four of the five contracts against stale artifacts. The suite is 239 Noir tests and 17 end-to-end tests, with the Noir suite now run by GitHub Actions on every push.
- The documentation was reconciled with the code rather than extended: `doc/standards/` and `doc/design/` merged into `doc/technical/`, the equivalency assessment brought up to this release, `LEARN-AZTEC.md` rewritten against Aztec 5.2.0 after drifting several releases, and a code-quality review of this release added under `doc/audits/tools/v0.4.0/`.

### Added

- GitHub Actions workflow `.github/workflows/noir-tests.yml`, running the Noir/TXE suite on pushes and pull requests to `dev`, `master` and `main`.
  - It runs `yarn compile`, `yarn test:nr`, then `yarn codegen` and `yarn typecheck`, so an ABI change the generated bindings did not follow fails the run.
  - The end-to-end suite is deliberately excluded: it needs a local Aztec network, which the workflow does not start.
  - A first step fails the run when the Aztec version drifts apart between `lib/Nargo.toml`, `package.json` and the workflow, which is the checklist rule made automatic.

- Every mint and burn now delivers a constrained `Transfer` event to the issuer, with the zero address on the private side (`from = 0` for a mint, `to = 0` for a burn, the ERC-20 and AIP-20 convention), in the three token variants; `mint_batch` emits one per recipient, `burn_batch` one for the batch total (review finding H-10, route A).
  - Why: the issuer's offchain note copies cannot be stored by a stock PXE, by either delivery mode — note discovery skips any note whose nullifier it cannot compute, and that needs the owner's key — and a copy would in any case never show that a note was spent. The `Transfer` event stream, which a PXE processes without anyone else's keys, is the issuer's ledger; it now covers every movement, so replaying it reconstructs every holder's balance.
  - Cost: one constrained delivery per record. `mint_to_private` 36,976 → 61,062 gates, `burn` 87,935 → 111,638, `mint_batch` 132,584 → 218,669, `burn_batch` 331,362 → 352,719 (base and Debt); Light 30,776 → 54,862, 81,736 → 105,439, 107,871 → 193,956, 306,820 → 328,177. Batch caps unchanged.
  - The README's limitation on the issuer's copy is corrected accordingly: offchain delivery avoids the cost of an unusable onchain copy, it does not make the copy processable.
- `CMTATAztecAuth` and `CMTATAztecAuthMultiToken`, two ARC-403 authorization contracts that apply CMTAT's pause, deactivation, freeze and a sender-side blacklist / whitelist to the stock AIP-20 `Token` and ARC-1155 `MultiToken` of the `aztec-standards` fork, which call them before every transfer and burn. Documented in `doc/auth/README.md`, with three PlantUML sequence diagrams under `doc/auth/img/` (AIP-20 flow, ARC-1155 flow, public entry points).
  - Rules follow CMTAT Solidity on the arguments the hook provides: a transfer needs the contract not paused and `from` neither frozen nor stopped by the enabled list; a burn needs it not deactivated and the same on `from`; burns are recognised by the reference contracts' selectors, everything else is a transfer. The hook is not called on mints, and neither the recipient nor the initiator is passed, so a listed or frozen address can still receive.
  - The freeze and list flags are read in private; the pause and deactivation flags are `PublicMutable` and checked by one enqueued public call whose only argument is `is_burn`, the same immediate-pause choice the token contracts made under `H-3`.
  - Same modules, roles, events, freeze delay and `version()` as the token contracts; the two versions are kept equal by hand and the release checklist now lists five `VERSION` constants.
  - New library module `authorizationHookModule.nr` holds the rules and the four pinned burn selectors; two contracts because the MultiToken hook carries an `id` and Noir has no overloading.
  - Verified by 57 unit tests and by 10 integration tests against the real fork tokens run in a copy of the fork (`doc/auth/integration-test.md`); `authorize_private` measures 14,650 gates, of which 6,203 are the list check.
  - AIP-721 is not covered: the fork's `NFT` contract has no ARC-403 hook. What it would take is written down in `doc/auth/README.md`.

### Fixed

- Pinned `zod` to `4.4.3` with a `resolutions` entry in `package.json`. Five `@aztec/*` packages depend on it at `^4`, yarn resolved **4.5.4**, and that release's recursive-schema memoizer overflows the stack on `@aztec/stdlib`'s self-referential `NestedProcessReturnValues`, so every end-to-end test failed at contract deployment with `RangeError: Maximum call stack size exceeded`.
  - 4.4.3 is the newest release in existence when Aztec 5.2.0 was published: zod 4.5.0 shipped eleven days later, so the toolchain was never built against the code that breaks.
  - `resolutions` rather than a dependency, because nothing in this repository imports zod; what has to be pinned is the copy the `@aztec/*` packages resolve.
  - Rationale, the stack trace and when the pin can be removed: `doc/technical/zod-pin.md`.

- `aztec test` (and so `yarn test:nr`) rebuilt only `contracts/cmtat-aztec` before running the tests, because the workspace `Nargo.toml` named it as `default-member` and `aztec test` runs a bare `aztec compile`; the Debt, Light and the two authorization contracts were tested against whatever artifact `target/` held. The `default-member` line is removed, and a bare `aztec compile` now rebuilds all five artifacts. Found when a deliberately broken rule in `authorizationHookModule.nr` left the authorization tests green (0.4.0 review, K-1).
- Two asserts on the batch entry points (`Mint module empty`, `Accounts and values arrays mismatch`) compared compile-time array lengths and could never fire; removed, with the gate profile of every circuit confirmed unchanged (0.4.0 review, D-3).
- The architecture diagram and two glossary / guide sentences still described the pre-refactor layout (three variants, `_*_internal` helpers); redrawn and reworded (0.4.0 review, G-7, G-8).

### Testing

- `Accounts › Creates accounts with fee juice` passes, so `yarn test:js` is 17/17 against a local network. Two defects, both in the test and neither in the token.
  - **The claim was one block early.** The test forced two blocks after bridging and then consumed the L1-to-L2 Fee Juice message, following the Aztec documentation's "about two L2 blocks"; the membership witness was measured to appear only at the third, so the claim failed on every run with `No L1 to L2 message found for message hash …`.
  - The fix does not count blocks at all: new `src/utils/l1_to_l2_message.ts` produces blocks until the node serves a witness for every deposited message, bounded at ten. The lag depends on where in the slot the deposit landed and on the archiver's L1 sync, so hard-coding three would have replaced an off-by-one with a flakier one.
  - **The fee bound had gone stale.** The balance after the self-paid deployment was asserted to be at least `claimAmount - 10^10`, a constant carrying the comment "Need to manually update this if fees increase significantly"; the deployment now costs about 7.6e12, 757 times that bound. The test reads the exact figure from `receipt.transactionFee` and asserts equality, with a separate check that the fee is non-zero so the equality cannot hold trivially.
  - Both are written up in `doc/technical/test.md`, together with the measurement table.

- The L1 mnemonic is no longer a literal in the source. `src/utils/l1_dev_account.ts` reads `L1_MNEMONIC` from the environment and throws with an instruction when it is unset; `.env.example` carries anvil's published default, the same one `aztec start --local-network` uses.
  - It was hard-coded in two places, `src/test/e2e/accounts.test.ts` and `scripts/fees.ts`, one of which is a testnet script that reads every other credential from `.env`.
  - The value was never a secret, being a public dev default. What it was is the shape a contributor copies when pointing the same script at a funded account.
  - Cost: `yarn test:js` and `yarn fees` now need `cp .env.example .env`, where before the local run needed no configuration.

- The end-to-end suite moves the chain's clock instead of waiting on it (`src/utils/time_travel.ts`).

- The hard audit invariant — every note written for a holder is also delivered to the issuer — had no test that could fail: removing the issuer's copy left the suite green. `test_issuer_copies.nr` asserts, through the TXE's `offchain_messages()`, that a mint or burn emits one offchain message and a transfer two, all addressed to the issuer, and that they follow a rotated issuer (0.4.0 review, K-2).
- Twelve tests in `test_guards.nr` cover the guards that had no negative test (zero admin at construction, revoking one's own role, renouncing with the wrong confirmation, freezing twice, unfreezing an unfrozen address), the before-delay twin of the freeze test, a zero-amount transfer, a blacklisted party opening or paying a commitment, and the private getters (0.4.0 review, K-3).
- `CMTATAztecDebt` and `CMTATAztecLight` pin the selectors of their 14 shared entry points to the base variant's values in `test_selectors.nr`, so a declaration that drifts in one variant fails that variant's suite; the chains themselves are tested once, in the base suite (0.4.0 review, K-4).
- Fifteen edge-case tests in `test_edge_cases.nr` close the mechanical rows of the review's edge-case table: a balance spread over more than sixteen notes, exactly the balance, the same address twice in a batch, two issuer changes scheduled before the first lands, the account itself passing a non-zero authwit nonce, a consumed and a cancelled authwit, completion of a commitment by the wrong party, twice, and after a freeze, a second call to the initializer, the argument-less public half of a transfer, and the private-balance storage slot pinned to its current value so a re-slot fails a test rather than orphaning every note.
  - Two of them measured behaviour the code did not state. One transfer could spend at most **12 notes**: 13 to 16 aborted with `push out of bounds` before `BalanceSet::sub`'s own sixteen-note limit was reached, 17 and more failed with `Balance too low` (since lifted by the note budget above). And a second payment into the same commitment is **lost to the recipient** while the sender is debited and `total_supply` unchanged — inherited from `PartialUintNote::complete`, which is not single-use; a wallet opens one commitment per expected payment. Both are documented in `doc/README.md` and recorded as K-6 and K-7 in the review.
- The two authorization contracts test `unfreeze` and `remove_from_list`: the address sends again after the delay and not before, an unfreeze of an unfrozen address is refused, and a removal needs `ADDRESS_LIST_REMOVE_ROLE` (six tests per crate).
- The Noir tests moved out of the contract crates into one `type = "lib"` test crate per contract under `tests/` (`cmtat_aztec_test`, `cmtat_aztec_debt_test`, `cmtat_aztec_light_test`, `cmtat_aztec_auth_test`, `cmtat_aztec_auth_multitoken_test`), the layout `aztec new` scaffolds and the Aztec documentation asks for.
  - Why: `aztec compile` warned `Found tests in contract crate(s)` for all five contracts, and a contract artifact depends on everything in its crate, so every test-only edit recompiled the contract. Verified after the move: the warning is gone, and a test edit leaves the five `target/*.json` untouched.
  - How: thirty files moved with `git mv`, no test body changed; a test crate imports its contract by package name (`use cmtat_aztec::CMTATAztec`) and deploys it with `env.deploy("@cmtat_aztec/CMTATAztec")`; `mod test;` and the `cmtat_aztec_test_helpers` dependency left the contract crates.
  - Running one crate is now `aztec test --package cmtat_aztec_test` (was `cmtat_aztec`); `yarn test:nr` (`aztec test --workspace`) is unchanged.
- Three tests pin the single-payment rule of commitments: a second payment is refused, both for a commitment the recipient opened and for one the sender opened with `transfer_private_to_public_with_commitment`, and the first payment is received unchanged; both refusal tests were confirmed to fail with the guard removed.
- Four tests in `test_issuer_records.nr` pin the issuer's mint and burn records by counting what each event leaves in the transaction (one private log, two nullifiers), measured on a second call so that first-contact handshakes do not enter the count; all four fail with the emits removed.
- The note-count edge cases follow the new debit: two notes without recursion, three through one recursive call, twelve and seventeen in one transfer, a fragmented balance that is still short, and `_recurse_debit` refused to an outside caller.
- Eight tests in `test_roles_delay.nr` and three per authorization crate pin the delay setting: the initial hour, an increase applying at once to the issuer address and to the next freeze, a decrease applying only after the difference and then governing the next write, the admin role, the 24-hour bound and zero refused.

- Four compiler warnings in the base test crate silenced. The Noir suite is now 237 tests (143 base, 12 Debt, 7 Light, 38 and 37 authorization) plus 2 library tests.

### Documentation

- `aztec start --sandbox` replaced by `aztec start --local-network` everywhere it was an instruction: the release checklist, the quick starts in both READMEs, the glossary, the agent guide, and `src/test/e2e/accounts.test.ts`, which spawned it. The flag was renamed at Aztec 3.0 and does not exist at 5.2.0, so every one of those was a command that fails.

- New `Tests` section in `doc/README.md`: the two suites and their commands, the `L1_MNEMONIC` and `SKIP_SANDBOX` requirements of the end-to-end one, why it warps the chain past the one-hour delay, and a pointer to the note below. The specification described how to deploy but never how to test, so `doc/technical/test.md` was reachable only from the agent guides.
- New `doc/technical/test.md`, on the end-to-end suite: what each of its two files covers, the two defects that kept the Fee Juice test red and how each was measured, and why the suite warps the chain past the one-hour delay instead of waiting for it.
- New `doc/scripts/convert_links_for_pdf_assessment.sh`, the PDF link conversion for `doc/cmtat-assessment/README.md`, delegating to `convert_links_for_pdf.sh` exactly as the root-README entry point does.
- `doc/cmtat-assessment/README.md` brought up to the release it claims to assess.
  - The *fee payer / gasless* row is answered `n.a.` rather than `partial`: the criterion asks for an ERC-2771 meta-transaction module, and Aztec chooses the fee payer per transaction, so such a module would be redundant rather than missing. The row is in the Extended-functionalities table, so the 19/42 scorecard counts are unchanged.
  - Two internal contradictions fixed: the closing paragraph still granted equivalency "subject to accepting the two mandatory `partial` answers on freeze and unfreeze", although criteria 19 and 20 are answered `y` and the scorecard counts zero mandatory partials; and the Reference table pinned a third commit, described as a development branch, while the identification table named another.
  - The assessment's own version was set to `0.3.0-rc1`, mirroring the template's `v0.3.0`; the template states the two are independent and that only the second row is the author's. It is now `0.1.0`, the first published revision, earlier drafts never having been published.
  - The pinned source commit and the assessment date were two weeks older than the code: they named a commit predating the bridges, the token module, the commitment guard, the issuer events, the note budget and the one-hour delay. Both now name the release, the commit row carrying the `v0.4.0` tag next to the SHA.
  - The privacy table's *balance of an address* and *transfer amount* rows are now conditional on `public_side_enabled`, with a note under the table recording that the flag is a deployment-time choice an assessor should write down. No criterion answer changes; the counts are unaffected.

- Added `doc/audits/tools/v0.4.0/CLAUDE_AUDIT.md`, a tool-assisted security review of this release, filed beside the code-quality review and separate from it.
  - Result: no Critical, High, Medium or Low finding; one Info, an over-reaching sentence in `doc/README.md` that presents the `Transfer` stream as a complete ledger although a commitment completion emits no event and the two bridges mask the private counterparty. No code fix is available — at completion the contract holds only the commitment, never the recipient — and the correct mechanism is documented elsewhere in the same file.
  - It records what was verified rather than only what was found: eight invariants with the test that establishes each, every privileged entry point against its guard, what each operation publishes, and the hypotheses that were probed and did not hold (no unguarded internal entry point, no detached authorisation attribute, no way to shorten a delay past its promise, no prover-controlled oracle value).
  - Two mutation spot-checks were run and both were killed: removing the recipient freeze check and removing the single-payment commitment guard each break the tests that claim to cover them. Three more remain, and the report carries them as an open item rather than as a clean result.
  - The report is the whole of what the review publishes. Its working deliverables — the threat model, the test-gap analysis and the raw findings file — stay local and are not committed, so the report has to carry every claim it makes rather than deferring to a file a reader cannot open.
- Added `doc/audits/tools/v0.4.0/CLAUDE_ANALYSIS.md`, the code-quality review of this release: the gate baseline re-measured for every private function including the bridges, the token-module refactor verified gate-neutral circuit by circuit, and a new section on the tests — five mutation spot-checks (two survived, both fixed), an inventory of entry points, asserts and branches against the suite, and an edge-case table with fourteen cases still untested, nine of them mechanical and two design questions. It also corrects the 0.3.0 report: `aztec compile` does warn about tests in contract crates (the earlier check had used `aztec-nargo`), so that finding is reopened; and it records as open that nothing yet shows the issuer's PXE can process the offchain copies it receives.
- Added `doc/technical/token-module.md`, a design note on moving the mint, transfer, burn and bridge chains out of the three `main.nr` files into a library module: what Noir allows, the measured duplication, cost, advantages, disadvantages and remaining limits. Not applied.
- Added `doc/technical/commitment-reuse.md`, a design note on the second payment into an already-paid commitment: the flow step by step, what happens on a reuse in this contract and in the AIP-20 reference (identical on the transfer paths, by the same library call; AIP-20 also has `mint_to_commitment`, where a reuse inflates supply), why it matters more for a security token (the issuer books both payments, the holder's wallet holds one), seven options from documentation to a commitment nullifier pushed in the private half, and a recommendation.
- `doc/standards/` and `doc/design/` merged into one directory, `doc/technical/`: the four standards comparisons and the two design notes now sit together, since both answer "why is the code the way it is" rather than "how do I use it". Every reference in the repository was repointed; the released 0.3.0 entries below keep the paths the files had at the time.
- `doc/technical/token-module.md` gained a second status block recording where the applied code differs from the note's own sketch: `Screening` is the trait rather than the `Option`-carrying struct, `require_mint` / `require_burn` / `increase_supply` / `decrease_supply` were folded into `mint_public` and `burn_public`, the bridge chains landed in `tokenModule.nr` rather than `hybridModule.nr`, the module grew from 281 to 360 lines through the note budget and the commitment guard, and the selector-set test the note asked for now exists.
- `LEARN-AZTEC.md` rewritten against Aztec 5.2.0. It had drifted several releases: it described four account key pairs with the outgoing viewing key in use, Pedersen note hashes, a PXE that trial-decrypts every log, `compute_note_hash_and_optionally_a_nullifier`, `SharedMutable`, shield/unshield, and an install procedure on Node 20. It now covers the six protocol key pairs, tag-based note discovery, `DelayedPublicMutable`, the three message-delivery modes, transaction phases, fees, L1 messaging and the current toolchain, with a table mapping the old vocabulary to the new.
- `doc/technical/aip20-features-for-cmtat.md` reconciled with the release. Its summary table scored seven AIP-20 features against two planned products, CMTAT-private and a fourth AIP-20 variant; the release built neither shape, putting the features into the three existing variants behind `public_side_enabled`, so the table asserted the opposite of the code for F2, F4 and F6.
  - The two product columns are replaced by a state column: F1, F4 and F5 done, F2 done without its mandatory expiry, F6 done in a narrower form than the one refused, F3 and F7 open, both rejections still rejected.
  - The product map, the per-feature verdicts that depended on it and the recommended order are marked superseded rather than deleted, with what actually happened next to each; a *What is left* section names the three remaining items.
  - It records an open gap it cannot close itself: the privacy table in `doc/cmtat-assessment/README.md` still answers *balance of an address* and *transfer amount* as plain `private` and does not mention the bridges, the public balance or the unencrypted commitment amount, which the document's own test 2 requires to be disclosed.
- `doc/technical/building-on-aip20.md` gained a status block: the verdict stands, and three of its proposals have since been acted on — the mirror image of Option B is the two authorization contracts, Option F is the pinned CMTA fork at Aztec 5.2.0, and interface alignment shipped in the three variants. Its recommendation's first item, the note budget, is marked done with the measured figure.
- `doc/README.md`: two statements contradicted by 0.4.0 corrected — that putting the value-moving chains in a library "would mean much more boilerplate code" (it removed about 500 lines and changed no circuit), and that a constrained issuer record for mint and burn remained open (it shipped; what is open is the holder-facing record).
- Prose pass over the documentation against the project's AI-phrasing checklist, touching wording only — no claim, figure or path changed.
  - Rewritten: the impact trope in `doc/README.md`'s opening ("marks a significant step forward"), and the vague-noun stand-ins for code — *scaffolding*, *boilerplate*, *machinery*, *wiring* — each replaced by the thing it was standing in for, such as the two helpers `test-helpers/` actually holds.
  - Rewritten: the reach metaphor in five places (`never reaches a tree`, `never reach the hook`, `never reach the public half`, `cannot reach either`, `AIP-721 is out of reach`), which said that something failed to arrive where the fact is that it is absent or not called.
  - Rewritten: four dismissive tails (`and nothing else`) into the `only` they meant, and three intensifiers that carried a claim no stated property backed.
  - Four overloaded parentheticals in `LEARN-AZTEC.md` promoted to sentences.
  - Left alone: released history (the 0.3.0 review and the released CHANGELOG sections), and the uses the checklist itself exempts — `actually` where the sentence names the contrast it is drawing, and one `genuinely` marking a distinction the sentence states.

- `doc/README.md`'s validation-module *Delay issue* section now states what is implemented rather than leaving all three mitigations theoretical.
  - Corrected a factual error: the delayed state is the validation flags, the freeze flags and `issuer_address`, not the roles — `RoleData.has_role` is a `PublicMutable<bool>` and a grant or revoke takes effect in the same block, despite the `CHANGE_ROLES_DELAY_SECONDS` name.
  - Solution 3 (whitelist rather than blacklist) is marked as implemented and selectable at runtime through `set_operations`, with the reason it helps: in whitelist mode the delay runs in the safe direction, at the cost of delaying every new holder.
  - Solution 2 is marked as available by hand — `pause_contract` / `add_to_list` / `unpause_contract` — since the pause is deliberately immediate; solution 1 is marked unavailable, as reading public state privately still has no protocol support.
  - The per-flag delay is described as the runtime setting `roles_delay()` rather than the compile-time constant, and the section cross-references the delay section and the freeze-notice FAQ entry.

- New **Gas sponsorship** section in `doc/README.md`, and both READMEs corrected: they listed "gasless transactions" as unsupported, which contradicted the equivalency assessment and the repository's own `src/utils/sponsored_fpc.ts`.
  - What is absent is CMTAT's ERC-2771 meta-transaction module, and it is unnecessary here: Aztec chooses the fee payer per transaction rather than in the contract, so a holder needs no Fee Juice and the token needs no forwarder.
  - The section gives the three payment routes (self, sponsored FPC, third-party FPC), records that this repository already deploys accounts through a sponsored FPC, and states why an FPC cannot practically charge in this token — the setup-phase allowlist since Aztec 4.2.0, and private balances whose screening could revert a non-revertible phase.
  - It also records sponsorship as a privacy measure: fee payment is public, so a holder paying its own fee publishes that it transacted even though the transfer reveals neither party nor amount.
### Removed

- Two stray files untracked: `.DS_Store` (macOS Finder metadata, committed in December 2024 and carried ever since because `.gitignore` had listed it from the start, which does not untrack an already-tracked file) and `.latest_aztec_cli_vars` (a cache the `aztec` CLI wrapper writes, listing the environment variable names it forwards; names only, no values, and describing a CLI several major versions old). Both stay on disk and are now ignored; neither was referenced anywhere.

- `doc/standards/cmtat-as-aip20-auth-contract.md`, the feasibility study for an authorization contract. Superseded by the contracts themselves: its mandatory-criteria scorecard (re-scored against what was built) and its list of hook changes that would close the partials moved into `doc/auth/README.md`; the probe measurements it recorded are replaced by the shipped contracts' numbers.

- The four AIP-20 private/public bridges, in all three token variants, behind a new deployment flag: `transfer_private_to_public`, `transfer_public_to_private`, `transfer_private_to_commitment` with `initialize_transfer_commitment`, and `transfer_private_to_public_with_commitment`, plus `balance_of_public` and `public_get_public_side_enabled`. Same names, types and selectors as the standard, pinned by a test. Documented in `doc/README.md`, "Private/public bridges".
  - BREAKING CHANGE: the constructor takes a fifth argument, `public_side_enabled: bool`, stored as a `PublicImmutable`; every bridge reverts with `Error: public side disabled at deploy` when it is off, so a token deployed with `false` behaves exactly as before. Two storage fields (`public_balances`, `public_side_enabled`) are appended after the existing ones.
  - Each bridge runs the CMTAT chain: both parties screened for freeze and lists in the private half, the issuer's copy of every note, the pause check in the enqueued public half. The public half publishes the mover's own side (public party and amount) by design, with a public `Transfer` event using AIP-20's `PRIVATE_ADDRESS_MAGIC_VALUE` for the private side.
  - A commitment's recipient is screened when it is opened; the issuer receives a constrained `CommitmentInitialized { to, completer, commitment }` event, since the library delivers a partial note to its owner alone. No commitment expiry, no public-to-public transfer, no public mint or burn.
  - New library module `lib/src/modules/hybridModule.nr` holds the public-balance state and the partial-note helpers. It is derived from the AIP-20 `Token` of `aztec-standards` and is released under the MIT licence only, with Wonderland's copyright notice in its header and in `LICENSE-MIT.md`.
  - `ValidationModule` gained `operateOnTo(to)`, the recipient half of `operateOnTransfer`; `operateOnMint` delegates to it.
  - Tests: 17 in the base variant (flag, each bridge's happy path, pause, freeze and list refusals on the right party, overdraft, commitment open/complete including a frozen or unlisted recipient refused at opening, selector pins) and a smoke pair in each other variant; the TypeScript callers pass `false`.

### Changed

- BREAKING CHANGE: the delay of the delayed values (freeze flags, list flags, list mode, issuer address) is one hour initially instead of six minutes, and it is adjustable at runtime: `set_roles_delay(new_delay)` (`DEFAULT_ADMIN_ROLE`, `1 ≤ new_delay ≤ 86400`) and `roles_delay()` are added to the five contracts, with a `RolesDelayChanged { new_delay, operator, effective_at }` event (review finding H-6).
  - Why: with 360 s every value-moving transaction had to be proved and included within six minutes of its anchor block and carried a six-minute expiration that identified the token on chain; the framework's own compliance token uses 24 hours and the library recommends hours. One hour keeps the freeze window short, and the setter lets the issuer move in either direction without a redeployment.
  - How: the library's `schedule_delay_change` makes an increase effective at once and a decrease effective after the difference between the old and new delay, so nothing already scheduled lands earlier than promised. The issuer address and the list mode adopt the setting in the `set_roles_delay` call; the per-address freeze and list entries carry their own delay and adopt the setting when next written (`freeze`, `unfreeze`, `add_to_list`, `remove_from_list` apply it first, at `2N + 2` extra public storage writes), so an untouched entry keeps its previous delay.
  - `effective_at` in `AddressFrozen`, `AddressListed`, `OperationsSet` and `IssuerChanged` is now the timestamp the library scheduled rather than `now + constant`, which differs whenever an entry's delay differs from the setting.
  - Storage: one `PublicMutable<u64>` appended last in every storage struct, so no existing slot moves; the private-balance slot stays 22. The pause is unchanged: it is a `PublicMutable` with no delay and takes effect at once.
  - Migration: an operator runbook and the e2e suite wait one hour after deployment for the issuer address, not six minutes. `CHANGE_ROLES_DELAY_SECONDS` is now the *initial* value only; read `roles_delay()` for the current setting.
- A debit spends two notes first and recurses for more, instead of being compiled for sixteen: `debit_private` tries `DEBIT_INITIAL_MAX_NOTES` (2) notes and, when the holder's balance is spread over more, the contract calls its new `#[only_self]` entry point `_recurse_debit`, `DEBIT_RECURSIVE_MAX_NOTES` (8) notes per call, as many times as needed. The scheme and both values are AIP-20's (`_subtract_balance` / `recurse_subtract_balance_internal` in `aztec-standards`), credited in the code (review finding A-5).
  - Why: a circuit pays for every note slot it may read, about 3,050 gates each, whether the holder has one note or sixteen; sizing for the common case and growing on demand removes 14 unused slots from most debits.
  - Measured: `transfer_private_to_private` 161,493 → 119,290 gates, `burn` 111,638 → 69,434, `transfer_private_to_public` 95,941 → 53,737, `transfer_private_to_commitment` 93,063 → 50,857, `transfer_private_to_public_with_commitment` 129,874 → 87,671, `transfer_batch` 312,909 → 228,274, `burn_batch` 352,719 → 183,691 (base and Debt; Light about 10,400 lower); `_recurse_debit` is 30,138 gates per recursive call.
  - Behaviour change: a balance spread over three or more notes now costs a nested private call per eight notes instead of the flat circuit, and the two former limits are gone — twelve notes was the most one transfer could spend and seventeen or more failed; fifty notes in one transfer were measured to pass. `Balance too low` still fires at every depth for a balance that is short.
  - ABI addition: one new private entry point per token variant, `_recurse_debit(account, remaining)`, callable only by the contract itself. No storage or note-layout change.
- A commitment can be paid exactly once: `pay_commitment` (behind `transfer_private_to_commitment` in the three token variants) pushes a nullifier derived from the commitment, `H(commitment, DOM_SEP__CMTAT_COMMITMENT_PAID)`, so a second payment into the same commitment is a duplicate nullifier and never lands (review finding K-6).
  - Why: the library's `PartialUintNote::complete` is not single-use, and a second payment debits the payer for a note the recipient's wallet never discovers; measured before the fix at payer −200, recipient +100, `total_supply` unchanged. The framework leaves the single-completion guarantee to contract logic (aztec-packages #14364); the AIP-20 token has not added one, so this is a deliberate difference from the standard's code, in the stricter direction only.
  - Cost: +52 gates on `transfer_private_to_commitment` (93,011 → 93,063 base and Debt, 86,812 → 86,864 Light); no storage or ABI change; nothing new is published, the nullifier being unlinkable to the completion log tag without the commitment.
  - Behaviour change: the refusal is an invalid transaction (a duplicate nullifier, `Nullifier collision` in the TXE), not a named revert; a wallet can pre-check by deriving the nullifier. Design note and the options considered: `doc/technical/commitment-reuse.md`.
- BREAKING CHANGE: `CreditEventsStruct` is now packed into two storage Fields instead of three on `CMTATAztecDebt` — the two flags share one Field as bits, the rating keeps the other — matching the two slots CMTAT Solidity's `CreditEvents` occupies (0.3.0 review, B-3, deferred then to "the next storage break", which this release is).
  - Every state variable declared after `credit_event_module` moves one slot, including `private_balances`, so a Debt instance deployed from 0.3.0 cannot be upgraded in place; 0.4.0 is a redeployment for every variant anyway.
  - The ABI is unchanged: `get_credit_events` still returns `[Field; 3]`. Round-trip tests in the library module keep the hand-written packing honest.
- `VERSION` bumped to `0.4.0` in the three token contracts and the two authorization contracts; `version()` returns it, and the authorization-contract tests pin the new value.
- The mint, transfer, burn and bridge chains moved out of the three `main.nr` files into `lib/src/modules/tokenModule.nr`, so the compliance chain exists once (`doc/technical/token-module.md`).
  - Each variant's entry points now call `mint_private` / `transfer_private` / `burn_private` / `bridge_*` / `open_commitment` / `pay_commitment` with a `Screening` value built from its own storage (`FreezeAndLists` for the base and Debt variants, `FreezeOnly` for Light); the enqueued public halves call `mint_public` / `require_transfer` / `burn_public` / `credit_public` / `debit_public`. Noir keeps the declarations, attributes, enqueues and event emissions in the contract module, so those remain per variant.
  - No storage, ABI, selector or note-layout change; the gate profile of every private circuit is identical before and after (both `#[internal]` helpers and library functions are inlined). The three `main.nr` lost 105, 105 and 97 lines.
  - Closes the open `D-1` finding of the 0.3.0 review (cross-variant drift): a change to a chain now lands in all three variants by construction.
- BREAKING CHANGE: five entry points renamed to the AIP-20 names, in all three token variants, so the private profile answers the standard's selectors: `transfer` → `transfer_private_to_private`, `mint` → `mint_to_private`, `public_get_name` / `public_get_symbol` / `public_get_decimals` → `name` / `symbol` / `decimals`.
  - Selectors depend on the name and parameter types only, so `authwit_nonce` keeps its name and the seven-function private profile (`transfer_private_to_private`, `mint_to_private`, `name`, `symbol`, `decimals`, `balance_of_private`, `total_supply`) now matches the fork's `Token::interface()` exactly; `test_aip20_profile.nr` pins the values.
  - `burn` is deliberately not renamed: AIP-20's `burn_private` is holder-authorised and CMTAT's burn is `BURNER_ROLE`-gated, and an identical selector with different authorisation would mislead wallets. `transfer_batch`, `mint_batch`, `burn_batch`, `cancel_authwit` and the `private_get_*` getters are unchanged.
  - Every caller must follow: the generated TypeScript, the e2e suite, `scripts/interaction.ts`, the Noir tests and the diagrams were updated. This is a partial profile, not AIP-20 conformance — see "AIP-20 private profile" in `doc/README.md`.
- `ValidationModule` gained `operateOnFrom(from)`, the sender half of `operateOnTransfer`, in both the private and the public context; `operateOnBurn` now delegates to it. Used by the authorization contracts, whose hook is never told the recipient.
- The `aztec-standards` submodule now tracks the [CMTA fork](https://github.com/CMTA/aztec-standards) at `5433e9c` (`Upgrade to Aztec 5.2.0`) instead of upstream `defi-wonderland/aztec-standards` at `a3859e5`, and lives at `submodules/aztec-standards` with the other reference repositories rather than under `lib/`.
  - The fork is upstream `a3859e5` with its eleven Noir manifests and the `@aztec/*` packages moved from `v5.0.0-rc.2` to `v5.2.0`, the pin this repository uses, so the AIP-20 reference contracts and this token now compile and test on one toolchain: 22 artifacts, 79/79 `token_contract` tests.
  - Nothing in the build depends on it yet; it is the pinned source the standards documents cite and the base for any AIP-20 integration work in 0.4.0.
  - It has to be built and tested from a copy outside this tree (`git archive` into a temporary directory): `nargo` resolves the outermost `[workspace]`, which from inside the submodule is this repository's. Recorded as Trap 3 in `doc/technical/upgrading-aztec-standards.md`.

## 0.3.0 — 2026-09-14

MAJOR under the policy above: storage layout, note delivery and the external API all changed with the framework upgrade, and 0.3.0 is not compatible with a 0.2.0 deployment. `version()` returns `0.3.0`. Built and tested on Aztec **5.2.0** (sandbox and testnet).

First release published on [github.com/CMTA/private-CMTAT-aztec](https://github.com/CMTA/private-CMTAT-aztec); from 0.3.0 on, releases are made there. Earlier releases were published on [github.com/taurushq-io/private-CMTAT-aztec](https://github.com/taurushq-io/private-CMTAT-aztec).

### Summary

- Upgraded from Aztec 0.87.8 to **5.2.0**, which is a rewrite of every file rather than a version bump: the framework renamed its function and state-variable macros, moved contract state behind `self`, replaced note delivery, and replaced the PXE-centric TypeScript API with a Wallet-centric one.
- Moved private balances from the hand-written `BalanceSet` of 0.2.0 onto the framework's own `balance_set` library, and the module structs onto the framework's `StateVariable` trait.
- Split into three deployment variants (`CMTATAztecLight`, `CMTATAztec`, `CMTATAztecDebt`) over one shared module library, and closed the CMTAT equivalency gaps: permanent deactivation, token ID, terms, `version()`, credit events and the `ICMTATDebt` record, issuer rotation with `set_issuer`, mint and burn lifecycle and screening rules aligned with CMTAT Solidity.
- Made every state change observable: public events on every public entry point, and a `Transfer` event delivered constrained to both the recipient and the issuer, so the issuer holds an unforgeable on-chain record of who paid whom. Batching caps are now measured: 4 addresses for mint and burn, 2 recipients for transfer.
- Documented the design in full: what each operation publishes, the delayed-flag model and its cost, the AIP-20 relationship in five standards documents, the equivalency assessment, and a tool-assisted code-quality review under `doc/audits/tools/v0.3.0/` whose findings are all fixed, decided or explicitly left open.
- Copyright passed from Taurus SA to the Capital Market and Technology Association from the commit after `61f4220d` (the 0.2.0 release); the MIT / MPL-2.0 dual licence is unchanged.

### Changed

- The `Transfer` event is now delivered `onchain_constrained` to **both** the recipient and the issuer, replacing an `onchain_unconstrained` delivery to the recipient alone.
  - The event's only information not already carried by the notes is the sender's identity, to the recipient. Unconstrained delivery let the sender forge that: the circuit computed `from` correctly, but nothing proved the posted ciphertext encrypted it. The receipt is now provable.
  - The issuer's note copies must be offchain, because PXE cannot discover a note it does not own. An event has no nullifier, and it was verified in the suite that the issuer can receive one constrained and on chain — its first on-chain, data-available, unforgeable record of who paid whom and how much.
  - Measured cost: `transfer` 120,824 → 161,493 gates, about 20,200 per constrained delivery.
  - BREAKING CHANGE: `transfer_batch` now accepts at most **2** recipients, down from 4, under a new `MAX_TRANSFER_ADDR_PER_CALL`. Each recipient costs four constrained deliveries and three already exceed a per-call budget (`push out of bounds`); a model consistent with every measurement is two key-validation requests per constrained delivery against a limit of sixteen. `mint_batch` and `burn_batch` keep `MAX_ADDR_PER_CALL = 4`.
  - The README gained an *Events* section listing every event, its fields, its emitter and, for `Transfer`, the reasoning above.
- Mint and burn now follow CMTAT Solidity's lifecycle and screening rules: they continue through a pause, stop at deactivation, and their target is screened against the enabled list.
  - CMTAT's `_canMintBurnByModule` checks deactivation and the freeze flag, never `paused()`, and its allowlist variant screens the recipient of a mint and the account of a burn. Previously this token blocked mint and burn during a pause and did not apply the lists to either — the first a documented deviation, the second a gap the `mint` NatSpec had claimed was closed.
  - `_mint` and `_burn` now assert `!is_deactivated()` in their enqueued public half; `_transfer` still asserts `!is_paused()`. The validation module gained `operateOnMint(to)` and `operateOnBurn(account)`, called from `_mint_internal` and `_burn_internal`.
  - Measured cost: +6,200 gates on `mint` (30,776 → 36,976) and +6,199 on `burn` (81,736 → 87,935) for the two list reads. `transfer` and the Light variant, which has no validation module, are unchanged.
  - BREAKING CHANGE (behaviour): an issuer can now mint into and redeem from a paused token, and a blacklisted or non-whitelisted address can no longer be minted to or burned from. Seven tests changed or were added to pin both directions; each was confirmed to fail against the previous behaviour.
- `terms`, `get_credit_events`, `get_debt` and `only_role` are now `#[view]`, and those three getters plus `total_supply` return `-> pub`, matching every other read-only entry point.
  - `#[view]` is an enforced guarantee rather than a hint, and its absence mattered most on the getters other contracts call: without it a caller composing against them could not rely on their being side-effect-free.
  - The evidence that this was drift rather than intent is that `get_operations` — the same shape of function, in the same file — already had it.
  - The tests for those getters now call `view_public` instead of `call_public`, which is both the correct call for a read and a compile-time guard: `view_public` does not type-check against a non-view function, so the attribute cannot be dropped silently.
  - `only_role` had no test caller at all, so two were added to pin its attribute and confirm it still reverts for a non-holder through a static call.
- Dropped `downlevelIteration` from [tsconfig.json](./tsconfig.json). The option only affects ES5/ES3 emit and the project targets `es2020`, so it was already inert; TypeScript 6 reports it as deprecated.
- Contract functions use the `#[external("private" | "public" | "utility")]` macros instead of `#[private]` / `#[public]` / `#[utility]`, and contract state is reached through `self.storage` instead of a free `storage` binding.
- Private-to-public calls go through `self.enqueue_self`, private-to-private helpers through `self.internal`, and the enqueued public halves (`_mint`, `_transfer`, `_burn`) are now `#[external("public")] #[only_self]`.
- Authwit validation on `transfer`, `transfer_batch`, `burn` and `burn_batch` is now the `#[authorize_once("from", "authwit_nonce")]` macro instead of a hand-written `assert_current_call_valid_authwit` call.
  - The `_nonce` parameter is renamed `authwit_nonce`, and the caller must pass `0` when acting for themselves - a non-zero nonce from the `from` account is now rejected.
  - The macro also adds replay protection, which the previous hand-written check left to the caller.
- `SharedMutable` became `DelayedPublicMutable`, and its delay is a **duration in seconds** rather than a number of blocks.
  - `CHANGE_ROLES_DELAY_BLOCKS = 2` is now `CHANGE_ROLES_DELAY_SECONDS = 360` in the contract and in the enforcement and validation modules.
  - This affects operators: freezing an account, blacklisting an address and rotating the issuer now take six minutes rather than two blocks, and a freshly deployed contract cannot mint, transfer or burn until the delay has elapsed, because all three read the issuer address the constructor scheduled.
- Private balances moved from a hand-written `BalanceSet` over `Map<AztecAddress, ...>` to `Owned<BalanceSet>` from the `balance_set` aztec-nr library, accessed as `private_balances.at(address)`.
- Module structs implement `StateVariable<N, Context>` (which now owns both `new` and `get_storage_slot`) instead of the old `Storage<N>` trait, and take `PublicContext` by value rather than `&mut PublicContext`.
- `burn_batch` now debits a single `from` account rather than one holder per array entry.
  - The old signature validated one authwit per entry, which `#[authorize_once]` cannot express: it authorizes exactly one `from`.
  - At the current `MAX_ADDR_PER_CALL` of 1 this is the same operation; it only narrows what a larger batch could do.
- The TypeScript layer is built on `EmbeddedWallet` from `@aztec/wallets`, which owns its own PXE, rather than constructing a PXE service and deriving a wallet per account.
  - Every `send()` and `simulate()` now names its sender with `from`, so one contract handle serves all accounts instead of one handle per wallet.
  - `TxStatus.SUCCESS` is gone; `TxStatus` now tracks finalization, and execution success is `receipt.hasExecutionSucceeded()`.
  - `deriveSigningKey` is gone; accounts rebuilt from `.env` now derive their signing key with `deriveMasterMessageSigningSecretKey`. Both this and address computation changed, so the addresses recorded in `.env.example` no longer correspond to its SECRET/SALT pairs.
- `transfer_batch` now emits one `Transfer` event per recipient, as `transfer` already did.
  - The two paths move tokens identically — at a batch of one they are the same operation — but only one of them left a trail, so anything built on the event silently missed every batched transfer.
  - Delivered in the same mode as the single path, so the two remain consistent. (Both paths were later changed to constrained delivery to the recipient and the issuer — see the *Changed* entry on the `Transfer` event.)
  - Costs 1,687 gates and one private log per recipient. That matters because the batch cap is set by the per-call log budget: the full suite was re-run at the cap of 4 to confirm the extra logs still fit.
- `MAX_ADDR_PER_CALL` raised from 1 to **4**, so `mint_batch`, `transfer_batch` and `burn_batch` act on up to four addresses.
  - The ceiling was measured rather than derived: at 5 the batched mint and burn finish with a wrong total supply, and at 6 and above `transfer_batch` aborts with `push out of bounds`. Everything passes at 4.
  - `transfer` is what sets the cap for all three, because it creates two notes and two constrained deliveries per recipient where mint and burn create one.
  - The previous comment blamed the 8-nested-private-call limit. That was never the constraint: the `_*_internal` helpers are inlined, so a batch makes no nested private calls at any cap.
  - The issuer address is now read once per call and passed into the helpers, instead of once per address. That saves 5,748 gates in each batch function at the new cap and leaves the single-entry paths unchanged.
  - Batching does not make the circuit cheaper: a four-recipient transfer is 447,303 gates against 119,145 for a single transfer, and the user's own device produces that proof. What it saves is the fixed per-transaction overhead that four separate transfers would pay four times.
  - BREAKING CHANGE: the array lengths in `mint_batch`, `transfer_batch` and `burn_batch` are part of the ABI, so callers passing one-element arrays must now pass four.
- `burn` and `burn_batch` name their target `account`, not `from`, following the CMTAT Solidity burn module.
  - CMTAT Solidity uses `account` for `burn` and `mint` and reserves `from`/`to` for transfers, where there really are two parties. A burn has one.
  - This is what produced the frozen-holder message bug fixed below: `from` implied a counterparty, and the assertion copied from the mint module named the one a burn does not have.
  - The authwit macro takes the parameter by name, so it is now `#[authorize_once("account", "authwit_nonce")]`.
  - BREAKING CHANGE: the generated TypeScript signature becomes `burn(account, amount, authwit_nonce)`. Arguments are positional, so existing calls behave identically, but any caller using the generated named types must be updated. `mint` still names its target `to`; aligning it with CMTAT would be a second ABI change and has not been made.

### Added

- `UserFlagsTrait` and `FreezableFlagTrait` are now `pub`, so a downstream contract can supply its own flag type as the `T` of `ValidationModule<T, Context>` and `Freezable<T, Context>` (for example a list entry with a KYC bit, or a freeze flag with a reason code) and enforce its extra flags itself by reading `map.at(address).get_current_value()`.
  - Until now the type parameter was unusable outside the library: the bounds were private, so `T` could only be `UserFlags` / `FreezableFlag`. Verified with a downstream contract that compiles against the library unmodified.
  - The traits are a public API from this release on: adding a method to either is a MAJOR change under the policy above, since it breaks every downstream implementor.
- `set_issuer(new_issuer)`, so the address that receives the audit copy of every note can be rotated without redeploying the token.
  - Guarded by `DEFAULT_ADMIN_ROLE`; refuses the zero address; schedules the change on the existing `DelayedPublicMutable`, so it becomes current after `CHANGE_ROLES_DELAY_SECONDS` and every mint, transfer and burn keeps addressing the previous issuer until then. Emits `IssuerChanged` with `effective_at`.
  - Rotation redirects future copies only. A note copy already delivered to the previous issuer cannot be recalled, so a compromised issuer key keeps the history it already holds; and the new issuer's PXE must be live from `effective_at`, or copies sent in the gap are lost to the issuer side while still reaching the holders. Both consequences are recorded in the README.
  - Closes the long-standing `TODO` above `public_get_issuer`. Tests cover the delay on both read paths, that transfers keep working before and after the change, and the two refusals.
- Public events on every remaining state-changing entry point: `Paused`, `Unpaused`, `RoleRevoked` (from both `revoke_role` and `renounce_role`), `AddressFrozen` (from both `freeze` and `unfreeze`, with an `is_frozen` flag), `AddressListed` (from both `add_to_list` and `remove_from_list`) and `OperationsSet`.
  - Names follow the reference where one exists: the pause and role events are the OpenZeppelin ones CMTAT Solidity inherits, `AddressFrozen` is CMTAT's own. With these, every operation that changes contract state leaves a trail; previously `grant_role` emitted and `revoke_role` did not, `deactivate_contract` emitted and `pause_contract` did not.
  - The three events for delayed flags carry `effective_at`, the timestamp from which the scheduled value is current — exactly what the state variable records, so an indexer need not know the contract's delay to know when a freeze or a listing takes effect.
  - The README no longer describes events as future work, and the assessment's Conclusion no longer says batching is capped at one address.
- `NewRole` is now emitted for the roles the constructor grants, which were previously the only silent grants in the contract's life.
  - An indexer built on `NewRole` saw every later grant and missed the founding ones, so the role table it reconstructed was wrong rather than obviously incomplete.
  - Every grant now goes through one inlined `_grant_role_internal` helper that writes and emits together, so the two cannot be separated again. It is `#[internal("public")]`, so it costs no call and no gas, and it replaces what would otherwise be nine copies of the emit across the three variants.
  - `AccessControlModule` gained `only_role_admin`, the check half of its `grant_role`, so the contract can authorise and then write-and-emit while the authorisation logic stays in the library.
  - Added `test_access_control.nr`: the deny path of `grant_role` had no test at all, so the change above had nothing guarding it.
- Realigned the debt module with the current CMTAT Solidity `ICMTATDebt` interface, adding the five attributes it had gained.
  - `DebtBaseStruct`, a flat struct of twelve attributes, is replaced by `DebtInformation { debtIdentifier, debtInstrument }`, mirroring the Solidity structs field for field and in their order.
  - New attributes: `issuerName` and `issuerDescription` on the identifier, and `minimumDenomination`, `currency` and `currencyContract` on the instrument. The last three close equivalency criteria 52 and 54, which the assessment recorded as absent.
  - `currencyContract` is an `AztecAddress`, so it can only name a contract on this chain; a payment currency on another ledger has to be identified through the `currency` string.
  - Removed `publicHolidaysCalendar`, which the CMTAT interface no longer carries.
  - Renamed to match Solidity: `bondHolder` is now `debtHolder`, and `couponFrequency` is now `couponPaymentFrequency`.
  - BREAKING CHANGE: the record grows from twelve fields to sixteen, so the module's storage span changes and every state variable declared after it moves. `set_debt_base(DebtBaseStruct)` and `get_debt_base()` are renamed `set_debt(DebtInformation)` and `get_debt()`, the getter now returns `[Field; 16]`, and the module file moves from `debtBaseModule.nr` to `debtModule.nr`. A deployed token cannot be migrated in place.
- `set_debt_instrument`, which updates the instrument's terms and leaves the debt identifier untouched.
  - Mirrors the Solidity `setDebtInstrument`, added alongside `setDebt` for the common case where a coupon schedule changes but the guarantor and debtholder representative do not.
  - Without it, changing one term meant re-supplying the identifier as well, and a caller that forgot silently blanked it.
- Public events on the debt entry points: `DebtLogEvent`, `DebtInstrumentLogEvent` and `CreditEventsLogEvent`.
  - CMTAT Solidity emits these with no payload to keep the contract small. These carry the caller instead, matching the existing `NewRole` and `Deactivated` events; the values themselves stay readable through `get_debt()` and `get_credit_events()`.
- `deactivate_contract` and `public_get_deactivated`, implementing the CMTAT permanent-deactivation feature (equivalency criteria 17 and 18).
  - Modelled on CMTAT Solidity's `PauseModule`: the caller needs the admin role, the contract must already be paused, and a second call is refused.
  - `unpause_contract` now refuses to run once the flag is set, which is what makes the deactivation permanent — the flag itself is never cleared.
  - `_transfer` stops on a deactivated contract through its not-paused assertion, since deactivation requires a pause and blocks unpause forever. `_mint` and `_burn` carry an explicit not-deactivated assertion instead, because — as in CMTAT Solidity — they are permitted while merely paused. (Earlier in this release all three asserted not-paused; see the *Changed* entry on mint and burn semantics.)
  - Emits a new `Deactivated` public event carrying the caller.
  - BREAKING CHANGE: `PauseModule` now occupies two storage slots instead of one, so every state variable declared after it moves. A deployed token cannot be migrated in place.
- Split into three deployment variants over a shared module library, as a Nargo workspace.
  - `CMTATAztecLight`, `CMTATAztec` and `CMTATAztecDebt` are separate contract packages in `contracts/`; every module moved to `lib/` (`cmtat_aztec_lib`, `type = "lib"`).
  - Noir has no inheritance and allows one contract per package, so a variant is a separate package composing a different subset of modules, not a subclass. An entry point added to a shared module must be declared in each variant's `main.nr` that should expose it.
  - Credit events and debt base are now carried only by `CMTATAztecDebt`; the validation module only by `CMTATAztec` and `CMTATAztecDebt`.
  - Measured artifact sizes are 6.25 MB (Light), 6.46 MB (base) and 6.50 MB (Debt), so dropping modules saves about 4% — the bulk is the private circuits for mint, transfer and burn, which every variant carries. The split is about deploying only what an issuance needs, not about size.
  - BREAKING CHANGE: the contract is renamed from `CMTAToken` to `CMTATAztec`, so its class ID, its generated TypeScript (`src/artifacts/CMTATAztec.ts`) and every deployment reference change. `yarn compile` and `yarn test:nr` now run across the workspace.
- `set_token_id` and `token_id`, the CMTAT token identifier (equivalency criterion 5), in all three variants.
  - Lives on the same extra-information module as the terms, guarded by `EXTRA_INFORMATION_ROLE`, and follows CMTAT Solidity in writing the value even when it equals the current one.
  - A `PublicMutable<FieldCompressedString>`, so it is settable after deployment as in Solidity, and capped at 31 characters — enough for an ISIN.
  - Completes criterion 50 (unique identifier / hash), which needs `tokenId` alongside the terms document hash.
  - BREAKING CHANGE: the extra-information module now occupies six storage slots instead of five, so every state variable declared after it moves.
- `version()`, returning the implementation version as a compile-time constant (equivalency criterion 6).
  - Follows the CMTAT Solidity `VersionModule`: a constant of the code, not stored state, so it cannot be desynchronised from the deployed contract and changes only through a new deployment.
  - Aztec's contract class ID already identifies the deployed artifact, but it is a hash: it does not order releases and does not correspond to a release tag, so it does not answer the same question.
  - The value lives in `VERSION` in `src/main.nr` and MUST be bumped with every release; the pre-release checklist below carries that step.
- `set_terms` and `terms`, carrying the reference to the legally required documentation (equivalency criterion 2), in a new `extraInformationModule`.
  - Uses the CMTAT Solidity notation: the setter takes a `DocumentInfo` of `{name, uri, documentHash}` and `terms()` returns the equivalent of `CMTATTerms`, with `lastModified` stamped by the contract from the block timestamp so a caller cannot forge it.
  - `name` and `uri` are `FieldCompressedString` and are therefore capped at 31 characters each.
  - The `bytes32` document hash is stored as two `u128` halves, because a Noir `Field` holds ~254 bits and a 256-bit digest does not fit in one. Split the digest high-16-bytes / low-16-bytes and reassemble it the same way.
  - Adds `EXTRA_INFORMATION_ROLE = 11`, matching the role CMTAT Solidity uses for `setTerms`.
  - BREAKING CHANGE: adds a storage field, so every state variable declared after it moves.
- `cancel_authwit`, which pushes the authwit nullifier so a granted authentication witness can be revoked before use.
- Agent guide files [CLAUDE.md](./CLAUDE.md) and [AGENTS.md](./AGENTS.md), and this changelog.

- `yarn typecheck`, a script that type-checks the TypeScript with the compiler pinned in `package.json`.
  - The pre-release checklist said `npx tsc --noEmit`, which is not reproducible: the Aztec toolchain ships its own `tsc` under `~/.aztec/current/node_modules/.bin/`, and on a machine where that directory precedes `./node_modules/.bin` on `PATH` the checklist type-checks the project with the toolchain's compiler instead of the pinned one.
  - Observed with toolchain 5.2.0, which bundles TypeScript 6.0.3 against the project's 5.5.x pin: the release check failed on a deprecation warning the project's own compiler does not emit.
  - A `yarn` or `npm` script prepends `./node_modules/.bin` to `PATH`, so the pinned compiler wins regardless of what else is installed. The checklist now calls the script.
- A `Terms` event on `set_terms`, which previously wrote the terms with no observable trail while its sibling `set_token_id` emitted one.
  - Follows the CMTAT Solidity `event Terms(CMTATTerms newTerm)`, which publishes the whole stored terms: the document name, its URI, the two halves of the content hash, and the `lastModified` the contract stamped.
  - That is deliberately unlike the debt events added in this release, which carry only the caller because their Solidity counterparts are payload-free.
  - `set_terms` now reads the block timestamp into a local and passes it to both the write and the event, so the two cannot disagree.

### Fixed

- `yarn compile` produced artifacts that `yarn codegen` could not consume.
  - The script called `aztec-nargo compile`, and at Aztec 5.2.0 `aztec-nargo` is a bare symlink to `nargo`: it compiles Noir but does not run the AVM transpiler, so codegen aborted with `Contract's public bytecode has not been transpiled`.
  - It went unnoticed because `aztec test` transpiles as a side effect, so anyone running the tests between compiling and generating never saw it. The pre-release checklist in this file is the one path that does not — it rebuilds from a clean tree without a test run.
  - The script is now `aztec compile --workspace`, and the environment override is renamed from `AZTEC_NARGO` to `AZTEC_COMPILE` because it names the `aztec` CLI rather than the nargo binary.
- `burn_batch` reported a frozen holder as `Frozen: Recipient`, naming a party a burn does not have.
  - `_burn_internal` asserted with the mint module's message; `burn` happened to mask it by checking the same flag itself first, so only the batch path showed it. On a circuit an assertion message is the only diagnostic there is, so the wrong one sends an operator after the wrong address.
  - The duplicate check in `burn` is removed as part of the fix, which also drops `burn` from 83,656 to 81,736 gates — the same circuit size as `burn_batch`. Behaviour is unchanged: the check still runs, once, inside `_burn_internal`.
  - Covered by `burn_batch_restricted_when_freezed`, added and confirmed to fail against the unfixed contract.

### Removed

- `FLAG_DEFAULT_FLAG` and `FLAG_REDEEMED_FLAG` from the credit-events module. They were public constants that nothing read: the module has always stored the two flags as `bool` fields of `CreditEventsStruct`, never as bits of a field.
- The sanction-list mode of the validation module, which was declared but never implemented.
  - `SANCTIONLIST_FLAG`, `SetFlag.operate_sanctionlist`, `UserFlags.is_in_sanction_list` and `get_is_in_sanction_list` are gone, and `operateOnTransfer` now dispatches to the blacklist and the whitelist only.
  - It was a trap rather than a gap: `operateOnTransfer` routed the mode to a handler that called `panic("not implemented.")`, so turning it on blocked every transfer instead of screening anything.
  - Nothing replaces it. `RuleSanctionsList` works on Ethereum because a Chainalysis oracle can be queried on-chain, and Aztec has no equivalent register to read; a sanctioned address must be blocked through the blacklist.
  - BREAKING CHANGE: `SetFlag` and `UserFlags` each lose a field, so the ABI of `set_operations`, `add_to_list` and `remove_from_list` changes and previously generated TypeScript artifacts no longer match. The `BLACKLIST_FLAG` and `WHITELIST_FLAG` bit values are unchanged, so `get_operations` still returns the same numbers.
- `src/types/balance_set.nr`, superseded by the `balance_set` library. The file is left in the tree but is no longer part of the module graph and should be deleted.
- The `value_note` and `authwit` entries in `Nargo.toml`: `value_note` was never used, and `authwit` is now part of the `aztec` library (`aztec::authwit`).
- The reference FPC's private and public fee-payment demonstrations in `scripts/fees.ts`. `FeeJuicePaymentMethod` no longer exists (an account holding Fee Juice pays with it automatically), and `PrivateFeePaymentMethod` / `PublicFeePaymentMethod` are deprecated and do not work beyond a local network.

### Security

- The issuer's copy of every note is now delivered **offchain** rather than onchain, which weakens the auditability guarantee.
  - The framework documents an onchain constrained copy to an auditor as the supported pattern, and the contract compiles that way, but PXE cannot process an onchain note message addressed to someone who is not the note's owner: note discovery computes the note's nullifier, which requires the owner's nullifier key.
  - The consequence is that the issuer's copy has no onchain data availability: the issuer must capture these messages as they are produced, and a sender who drops one is not detectable onchain.
  - The delivery mode is a one-line change in each of `_mint_internal`, `_transfer_internal` and `_burn_internal`, should a later Aztec version process non-owner note messages.

### Dependencies

- Aztec and `aztec-nr` upgraded from `v0.87.8` to **v5.2.0**, and the libraries now come from the standalone `AztecProtocol/aztec-nr` repository rather than a directory inside `aztec-packages`.
- Added the `balance_set` library; dropped `value_note` and the separate `authwit` library.
- `@aztec/aztec.js`, `@aztec/accounts`, `@aztec/builder`, `@aztec/noir-contracts.js`, `@aztec/kv-store` and `@aztec/pxe` pinned to 5.2.0, and `@aztec/wallets` added.
- Noir compiler is now 1.0.0-beta.25, shipped with the 5.2.0 toolchain.

### Testing

- The Noir test suite is rewritten against the current `TestEnvironment` API: `create_light_account` / `create_contract_account`, `deploy(...).with_public_initializer(...)`, and `call_private` / `call_public` / `view_public` / `view_private` / `execute_utility` taking an explicit sender, in place of `impersonate` and `.call(&mut env.private())`.
- Tests that act on someone else's behalf grant the caller access to the owner's notes with `call_private_opts(..., CallPrivateOptions::new().with_additional_scopes([owner]))`, since spending a note needs the owner's secrets even when an authwit authorizes the call.
- The two test helpers that do not name a contract, `advance_past_delay` and `call_private_on_behalf_of`, now live once in a new `test-helpers/` library crate (`cmtat_aztec_test_helpers`, a workspace member) instead of being copied into each variant's `src/test/utils.nr`; each `utils.nr` re-exports them, so call sites are unchanged. The `setup*` helpers stay per variant because they deploy that variant's contract. The crate is separate from `lib/` so test scaffolding is not part of the contract library.
- Tests that depend on a scheduled value change advance the chain past the delay with `advance_next_block_timestamp_by` plus `mine_block`, rather than mining a fixed number of blocks.
- The end-to-end suite waits out the real `CHANGE_ROLES_DELAY_SECONDS` once after deployment, because a sandbox's timestamps cannot be fast-forwarded and every mint, transfer and burn reads the issuer address.

### Documentation

- The analysis report now states how long a delayed pause would take and records a new finding about the delay itself.
  - A `DelayedPublicMutable` pause would take at least the contract's 360 seconds, and the library recommends delays of "at least a couple hours" and calls the type unsuitable for an emergency shutdown, because a private read sets the transaction's `expiration_timestamp`: a shorter delay narrows every transaction's validity window and fingerprints it. That effectively closes the one option that would hide the transfer selector.
  - The same reasoning applies to the contract's existing 360-second delay, which is an order of magnitude under the recommendation: every mint, transfer and burn expires six minutes after its anchor block, and a delay shorter than other contracts' is distinguishable. Against that, a short delay is a short freeze window. Recorded as an open decision for the compliance owner and the network operator, with the three facts needed to settle it.
- [SECURITY.md](./SECURITY.md) now defers to the [CMTAT security policy](https://github.com/CMTA/CMTAT/blob/master/SECURITY.md), following the transfer of the project to CMTA; the previous Taurus SA Signal and e-mail contacts are no longer the reporting channel.
- Copyright changed hands: the code is copyright (c) Capital Market and Technology Association, 2026, from the commit after `61f4220d5565840fd4fcdd2b723c9f55eb824c60`, the 0.2.0 release; releases 0.1.0, 0.1.1 and 0.2.0 stay copyright (c) 2025 Taurus SA. Both README files and `LICENSE-MIT.md` carry the two notices; the licenses are unchanged, MIT and MPL-2.0 at the licensee's choice.
- The root `README.md` is now a short entry point (what the project is, the variants, features, quick start, repository layout, links) and the full specification moved unchanged to `doc/README.md`, with its relative links and image paths repointed; every reference from the code and the guides follows.
- The public-selector finding (`H-3`) is closed by decision: the pause flag stays a `PublicMutable` checked in the enqueued public half of `transfer`, because a delayed pause of hours is too slow for an emergency lever. The README now states this next to the selector leak it leaves, with the rejected alternative and its cost, and the agent guide warns against moving the flag to `DelayedPublicMutable`.
- The README now states exactly what each private operation publishes, in a table under *Security and confidentiality properties*: a mint publishes the minter and the amount, a burn the burner and the amount, a transfer nothing but the fact that one occurred.
  - Both amounts were already inferable from the public `total_supply` delta, and the published address always holds a public role, so the marginal disclosure is which role-holder acted and when; the recipient of a mint and the debited account of a burn are not published.
  - The caveat that matters is boxed: `BURNER_ROLE` and `MINTER_ROLE` must remain issuer roles. A holder granted `BURNER_ROLE` who redeems its own tokens publishes itself, turning a private operation public without any code changing.
  - The equivalency assessment's privacy table gained matching rows for minter and burner, and each public half in the contract carries a `PRIVACY:` comment stating what crosses the boundary and what must not be added — `_transfer` in particular must keep taking no arguments.
- `doc/standards/building-on-aip20.md` gained a section on pause and deactivation through the ARC-403 hook, and its blocker table no longer lists "no pause anywhere" as a blocker.
  - Both are expressible through the hook. On pause the hook can be more faithful to CMTAT Solidity than this repository is: the reference lets mint and burn continue through a pause (`_canMintBurnByModule` checks deactivation and freeze, not `paused()`), which a hook reproduces exactly, while this token blocks all three.
  - On deactivation the hook falls short in one place: minting cannot be stopped, because the mint paths are not hooked. Criterion 17 would carry that caveat.
  - Records the immediate-versus-delayed choice for a pause flag read from private context, which is the same choice this repository already faces.
- Added `doc/standards/aip20-features-for-cmtat.md`, assessing which AIP-20 features could be adopted while staying CMTAT-equivalent. Each is scored against the 61 equivalency criteria, against the assessment's nine-row privacy table — the section that makes this a *private* CMTAT — and for two products: CMTAT-private, the three existing variants, and CMTAT-private-AIP20, a fourth variant integrating AIP-20.
  - Product map: CMTAT-private gains only the note budget with recursion and the rule-engine hook; the AIP20 variant adds commitment transfers, the five renames and named constructors. Public balances belong to neither, since both products are named for the property it removes.
  - Recommended order: the note budget with recursive subtraction (a measured 43,046-gate saving per transfer, prerequisite a note-count distribution and a re-measured batch cap); commitment transfers screened at initialization, bundled with the five AIP-20 entry-point renames; a settable rule-engine hook that passes the recipient and the caller, which is CMTAT's own `RuleEngine` in ARC-403's calling convention.
  - Commitment transfers carry three mandatory additions the standard lacks: an expiry, because the recipient cannot be re-screened at completion; a second delivery to the issuer, because the library delivers a partial note to one recipient only; and explicit disclosure that the completion amount is emitted in an unencrypted log.
  - Holder self-burn and a single immutable minter are rejected as regressions of criteria 11 and 29–31. Public balances are CMTAT-compatible but contradict this token's premise and are left to a possible fourth variant.
- Corrected the comparison document's second conflict. The AIP-20 documentation says a commitment's recipient is "not yet determined"; the source shows `initialize_transfer_commitment` takes the recipient and binds the partial note to it, and that `PRIVATE_ADDRESS_MAGIC_VALUE` marks a private party in public events rather than an unknown recipient. The conflict is a bounded-timing problem, not an impossibility, and the three other standards documents were aligned with the correction.
- Added `doc/standards/upgrading-aztec-standards.md`, instructions for bringing a fork of `aztec-standards` from `v5.0.0-rc.2` to this repository's `v5.2.0` so the two can be built, tested and composed on one toolchain.
  - Eleven `Nargo.toml` repoints and no source changes. Four aztec-nr crates move to the standalone `AztecProtocol/aztec-nr` repository; the `serde` protocol-circuits crate stays in `aztec-packages` with only its tag bumped, because that tree did not move — a blanket URL replace breaks it.
  - Includes the script that performs the repoint, verified to reproduce the measured result, and the workspace-wide compile and test commands with their expected outputs (eleven artifacts, 79 token tests).
  - Records the second trap: compiling one package and testing it crashes the TXE on the missing `GenericProxy` artifact and cascades `client error (Connect)` into every later test.
  - Explains how the fork is consumed from here — as contract interfaces by path dependency, never as an extensible base — and that both repositories must pin the same `aztec-nr` tag.
- Added `doc/standards/cmtat-as-aip20-auth-contract.md`, assessing whether the module library could be packaged as an ARC-403 authorization contract so that a stock AIP-20 token gains CMTAT compliance without modification.
  - It can: a probe composing the access-control, pause, freeze, validation and extra-information modules into a contract with the `authorize_private` / `authorize_public` interface compiles against the library unchanged, and its private hook measures 20,715 gates.
  - Because the hook is told which token function is running, a policy can refuse every commitment path and every public-balance path outright — closing two of the three conflicts with AIP-20 by refusal rather than by design.
  - What it cannot do follows from two arguments the hook does not pass: the recipient and the initiator. Recipient screening, issuer-only burn and role-gated mint are inexpressible, and the issuer receives no note copies. Five of the nineteen mandatory equivalency criteria come out `partial`.
  - Per transfer it costs roughly 185,000 gates against 120,824 for the integrated token, most of it the cross-contract kernel iteration. The verdict is a legitimate second product for issuers who need the standard artifact itself, not a replacement for the token.
- `doc/standards/building-on-aip20.md` now answers whether this token's entry points could be aligned with AIP-20's without adopting its architecture.
  - They can, by renaming: Aztec selectors are derived from the function name and parameter types, not parameter names — verified by computing selectors from both compiled artifacts — so renaming `transfer` to `transfer_private_to_private` with `authwit_nonce` unchanged yields AIP-20's exact selector. `balance_of_private` and `total_supply` already match.
  - `burn` must not be aliased to `burn_private`: AIP-20's is holder-authorised, CMTAT's requires `BURNER_ROLE`, and an identical selector with different authorisation is a trap for any caller.
  - Alignment is not conformance, and Aztec has no interface detection, so a partial profile is invisible until a missing function is called. The document recommends five renames plus an explicit README statement, or nothing.
- `doc/standards/building-on-aip20.md` gained a sixth option: forking `aztec-standards` and moving it to `v5.2.0`. It was tried rather than estimated.
  - Eleven `Nargo.toml` edits and no source changes: the four aztec-nr crates repointed to the standalone repository at `v5.2.0`, and one protocol-circuits crate (`serde`) left in `aztec-packages` with its tag bumped, because that tree did not move. The whole 11-crate workspace compiles and all 79 of the token's tests pass.
  - The version mismatch is therefore downgraded from a blocker to a chore in the document's blocker table, and the recommendation's reasoning changes from "hard to port" to "every design conflict survives the port".
  - Profiling both tokens on the same toolchain, AIP-20's private transfer costs 63,310 gates against this project's 120,824. The gap reconciles to within ~2,400 gates against components already measured here — validation module, `Transfer` event and the note budget — so the CMTAT features cost what they were measured to cost, and only the note budget is a free saving.
- Added `doc/standards/building-on-aip20.md`, assessing whether the project could be rebuilt on the `aztec-standards` AIP-20 token rather than implementing CMTAT directly. It cannot, for three reasons found by reading the library rather than its documentation.
  - Every crate in `aztec-standards` is `type = "contract"`, and Noir has no inheritance, so there is nothing to depend on and extend — its own vault "extension" is a separate contract that calls the token.
  - AIP-20 does provide a transfer-authorization hook, but it receives only the sender, the amount and the selector. It cannot screen the recipient, while a CMTAT freeze blocks receiving and a whitelist requires both parties listed. Minting is not hooked at all.
  - The library pins a different aztec-nr tag from a different repository than this project, and describes itself as a pre-release.
  - The document also corrects `cmtat-vs-aip20.md`, which stated AIP-20 had no compliance extension point at all, and replaces its first suggestion with a narrower one: pass the recipient to the hook.
- Added `doc/standards/cmtat-vs-aip20.md`, a detailed comparison of CMTAT with Aztec's AIP-20 fungible-token standard.
  - Explains why this contract is deliberately not AIP-20: public balances would add a transparent second ledger to a token built to avoid one, and partial-note transfers cannot coexist with recipient screening, because the recipient is unknown by design when the funds are locked.
  - Carries suggestions in both directions — extension points AIP-20 would need before a compliant token could conform to it, and patterns CMTAT should adopt for ledgers that are not account-model and transparent.
  - The strongest of those is measured rather than argued: sizing a transfer's note budget the way AIP-20 does is worth 43,046 gates, 36% of a transfer, on the proof the user's own device produces.
- Added `EXTRA_INFORMATION_ROLE` (11) to the role enumerations that still stopped at `DEBT_CREDIT_EVENT_ROLE` (10).
  - Three places were stale: the README glossary, the assessment's grant-role criterion, and the assessment's access-control note. The role itself has existed since the terms and token-id module was added.
  - The list is maintained by hand in four places — the code plus three documents — with nothing tying them together, so the next role added will drift the same way unless a check is added.
- The README's account of `issuer_address` was corrected twice in this release. It first claimed the address could be rotated when no setter existed; the claim was removed and the constraint recorded under *Limitations*. A setter was then added (see *Added*), and the documentation now describes what rotation does and does not achieve: future copies are redirected, delivered copies are not recalled.
- Added six PlantUML diagrams to the README, with sources under `doc/img/`.
  - Two structural: the three contract packages over the shared module library, and what the contract keeps public against what lives as notes in each holder's PXE.
  - Three flows: private mint, private transfer, and burn with and without an authwit. Each shows where the private half ends and the enqueued public half begins, and calls out exactly which values become public.
  - One explaining why the compliance flags are `DelayedPublicMutable` at all, and the window that opens between scheduling a freeze and its taking effect.
  - The `.puml` files are the source of truth; regenerate a PNG with `plantuml -tpng doc/img/<name>.puml` after editing one.
- Added `doc/audits/tools/v0.3.0/CLAUDE_ANALYSIS.md`, a code-quality review of the Noir sources against Aztec 5.2.0. Reports live under `doc/audits/<reviewer kind>/<release>/`, so this one is filed against the release it prepares.
  - It is explicitly not a security audit: nothing it reports lets an unauthorized party move value, bypass a restriction or brick a contract.
  - Carries a measured per-function gate baseline from `aztec profile gates`, so a future change can be compared against a number rather than an impression.
  - Findings have stable IDs and each ends in a verdict — implement, decide, or leave with the reason recorded. Two are marked as corrections, where measurement disproved the finding as first written.
- README updated for the renamed state variables, the per-call protocol limits (now 8 private calls and 16 private logs, up from 4 and 4), the `aztec-up install 5.2.0` instruction, and the delivery mode of the issuer's note copy.

## 0.2.0 — 2025-07-28

Commit [`61f4220d5565840fd4fcdd2b723c9f55eb824c60`](https://github.com/taurushq-io/private-CMTAT-aztec/commit/61f4220d5565840fd4fcdd2b723c9f55eb824c60). Last release published on [github.com/taurushq-io/private-CMTAT-aztec](https://github.com/taurushq-io/private-CMTAT-aztec) and the last one copyright (c) 2025 Taurus SA.

### Summary

- Testnet release: upgraded from Aztec 0.63.1 to **0.87.8**, the first version with a public testnet, and added the scripts to deploy and interact with the token there.
- Restructured the contract into module structs under `src/modules/`, and replaced the `ValueNote` balance map with a hand-written `BalanceSet` over `UintNote`.

### Changed

- Aztec and `aztec-nr` upgraded from `aztec-packages-v0.63.1` to **v0.87.8** (`aztec`, `authwit`, `compressed_string`, `value_note`, `uint_note`), with the `@aztec/*` JavaScript packages pinned to the same version.
- The modules moved from `src/types/` to `src/modules/` and became structs implementing a `Storage<N>` trait: access control, pause, enforcement, validation, and the credit-events and debt-base extensions.
- Private balances are held in a hand-written `BalanceSet` (`src/types/balance_set.nr`) over `UintNote`, replacing the `ValueNote` balance map and the custom token note.
- The end-to-end suite moved to `src/test/e2e/` and gained an accounts suite; `src/index.ts` was removed.
- `yarn clean` also removes `codegenCache.json`; the local PXE `store/` is gitignored.

### Added

- Testnet deployment and interaction scripts under [scripts/](./scripts): `deploy_contract.ts`, `deploy_account.ts`, `interaction.ts`, `multiple_pxe.ts`, `get_block.ts`, `fees.ts`, `profile_deploy.ts`.
- TypeScript helpers under [src/utils/](./src/utils) for wallet setup (sandbox and testnet), Schnorr account deployment, account recreation from `.env`, and the sponsored FPC fee-payment method.
- `.env.example` with the testnet variables (`L1_URL`, `NODE_URL`, `CMTA_TOKEN_CONTRACT_ADDRESS`, secrets and salts, `L1_CHAIN_ID`).

### Documentation

- README updated with the testnet deployment guidelines.

## 0.1.1 — 2025-02-20

Commit [`7c5dba760eea5e1b45a4a67290741f191f6a221a`](https://github.com/taurushq-io/private-CMTAT-aztec/commit/7c5dba760eea5e1b45a4a67290741f191f6a221a).

### Summary

- Documentation and licensing release. No contract changes: the token code is the same as 0.1.0, still built on Aztec 0.63.1.

### Documentation

- Rewrote the README: functionality overview, assumptions and requirements, storage description, per-operation (mint/transfer/burn) specifications, module design notes, and the limitations list.
- Added the security policy in [SECURITY.md](./SECURITY.md).

### Changed

- Dual-licensed the project under MIT and MPL-2.0, © 2025 Taurus SA — see [LICENSE-MIT.md](./LICENSE-MIT.md) and [LICENSE-MPL.md](./LICENSE-MPL.md).

## 0.1.0 — 2025-01-13

Commit [`47edc39256aeaa45d2546d53b73e672ca5828601`](https://github.com/taurushq-io/private-CMTAT-aztec/commit/47edc39256aeaa45d2546d53b73e672ca5828601).

### Summary

- First public release: a fully featured private CMTAT prototype on Aztec, built on Aztec 0.63.1.
- Aztec had no public testnet at the time, so this release runs on the local sandbox only.
- Not audited, and not guaranteed to be compliant with Swiss law.

### Added

- Private mint, transfer and burn of a CMTAT security token, with balances held as encrypted notes in each user's PXE.
- Public `totalSupply`, updated by the public half of each mint and burn.
- Issuer auditability: every note written for a user is also emitted to the issuer, so the issuer can reconstruct balances and transfers.
- Role-based access control in public state, with an admin role that grants and revokes the operational roles.
- Public pause of the contract and public freeze of individual accounts.
- Transfer restriction through a validation module holding blacklist and whitelist flags.
- Authentication witness support on transfer, the equivalent of `transferFrom`; mint and burn are restricted to the issuer and take no authwit.
- CMTAT extension modules: credit events (`flagDefault`, `flagRedeemed`, `rating`) and debt base (interest rate, par value, maturity date, day-count and business-day conventions), each guarded by its own role.
- Batched mint, transfer and burn, capped at one address per call by the four-encrypted-log limit of the time.
