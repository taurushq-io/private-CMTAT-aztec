# Could private-CMTAT-aztec be built on top of AIP-20?

An assessment of whether this project could be rebuilt on the [`aztec-standards`](https://github.com/defi-wonderland/aztec-standards) AIP-20 token rather than implementing CMTAT from scratch — written after checking out the library at `lib/aztec-standards` and reading its source, rather than its documentation.

> **Companion document.** [`cmtat-vs-aip20.md`](./cmtat-vs-aip20.md) compares the two *standards*. This one asks the engineering question: given the library as it actually is, what would "building on top" mean, and does any version of it work?

> **Status (2026-09-22).** The verdict stands: this project is not built on `aztec-standards`, and the reason is still the design conflicts rather than the cost of porting. Three parts of the document have since been acted on and carry their own status notes where they occur.
>
> - **Option B's mirror image was built.** `CMTATAztecAuth` and `CMTATAztecAuthMultiToken` apply pause, deactivation, freeze and sender-side lists to the fork's `Token` and `MultiToken` through the hook ([`doc/auth/README.md`](../auth/README.md)) — and hit exactly the limit predicted below, the missing recipient.
> - **Option F was carried out.** The submodule is the [CMTA fork](https://github.com/CMTA/aztec-standards) at `5433e9c`, moved to Aztec 5.2.0, 79/79 passing. The section's estimate held: eleven manifest edits, no source changes.
> - **Interface alignment shipped**, in the three token variants rather than a fourth — see the status note on that section, and [`aip20-features-for-cmtat.md`](./aip20-features-for-cmtat.md) for the feature-by-feature state, which is the document to read for *what is in the code today*. The recommendation's first item, the note budget, is done too.
>
> What is unchanged and still worth reading: the six options and why five of them fail, the measured cost of the fork, the burn trap, and the upstream request for a recipient argument on the ARC-403 hook.

## Table of contents

- [What was checked](#what-was-checked)
- [Correction to the earlier analysis](#correction-to-the-earlier-analysis)
- [Short answer](#short-answer)
- [The six things "on top of" could mean](#the-six-things-on-top-of-could-mean)
  - [Option A — depend on the crate and extend it](#option-a--depend-on-the-crate-and-extend-it)
  - [Option B — use the ARC-403 authorization hook](#option-b--use-the-arc-403-authorization-hook)
  - [Option C — wrap the token in a compliance contract](#option-c--wrap-the-token-in-a-compliance-contract)
  - [Option D — vendor the contract and modify it](#option-d--vendor-the-contract-and-modify-it)
  - [Option E — copy the patterns, not the code](#option-e--copy-the-patterns-not-the-code)
  - [Option F — fork the library and move it to v5.2.0](#option-f--fork-the-library-and-move-it-to-v520)
- [Interface alignment — an AIP-20 private profile](#interface-alignment--an-aip-20-private-profile)
- [Pause and deactivation on top of AIP-20](#pause-and-deactivation-on-top-of-aip-20)
- [Practical blockers independent of the design](#practical-blockers-independent-of-the-design)
- [Recommendation](#recommendation)
- [What to do with the submodule](#what-to-do-with-the-submodule)

## What was checked

| | |
|---|---|
| Library | `submodules/aztec-standards`, upstream commit `a3859e5` (`prerelease-0200230-14-ga3859e5`); since 0.4.0 the checkout is the CMTA fork at `5433e9c`, which is `a3859e5` moved to Aztec 5.2.0 |
| Token source | `src/token_contract/src/main.nr`, 695 lines, one contract |
| Its aztec-nr pin | `v5.0.0-rc.2`, from `aztec-packages/noir-projects/aztec-nr` |
| This project's pin | `v5.2.0`, from the standalone `AztecProtocol/aztec-nr` repository |
| Workspace members | 11 crates, **all `type = "contract"`** — there is no `type = "lib"` crate |

Everything below is from reading that source. Where a figure is from the Aztec documentation rather than measured here, it says so.

## Correction to the earlier analysis

**[`cmtat-vs-aip20.md`](./cmtat-vs-aip20.md) states that AIP-20 has "no compliance surface at all, and no extension point at which one could be added in a standard way", and suggestion A-1 proposes adding one. That is wrong for this version of the library.**

The token implements **ARC-403, an authorization hook**:

```noir
auth_contract: PublicImmutable<AztecAddress, Context>,
```

```noir
#[internal("private")]
fn _call_auth_private(from: AztecAddress, amount: u128) {
    let auth = self.storage.auth_contract.read();
    if !auth.eq(AztecAddress::zero()) {
        let selector = self.context.selector().to_field();
        self.call(AuthorizationContract::at(auth).authorize_private(from, amount, selector));
    }
}
```

An external contract nominated at deployment is called on every transfer and burn, and may revert. That is exactly the extension point the comparison document said was missing. The companion document has been corrected; this section records the correction so the mistake is visible rather than quietly edited away.

**It does not change the conclusion**, for the reason set out in Option B — but it changes the reasoning, and it makes the honest answer "the hook gets you about half of CMTAT" rather than "there is nowhere to put compliance".

## Short answer

**No — but closer than expected, and one option is worth keeping on the table.**

- Building on the library as a *dependency* is impossible: every crate is `type = "contract"`, and Noir has neither inheritance nor a way to extend a contract crate. This is a property of the language, not an oversight in the library.
- The ARC-403 hook can express **pause, deactivation, amount limits, and sender-side freeze/blacklist/whitelist**. It cannot express **recipient screening**, because the hook is not given the recipient — and recipient screening is not optional in CMTAT.
- Every other route is a fork, a wrapper that re-implements the token, or copying patterns without the code.
- **The fork itself is cheap** — moving the library to `v5.2.0` took eleven manifest edits and no source changes, and all 79 of its tests pass. What is not cheap is what comes after the fork, and that is unchanged.
- **Interface alignment is available without any of the above**: selectors depend on function names and parameter *types* only, so renaming five entry points makes this token answer AIP-20's private-path selectors exactly (two already match). `burn` must stay unaliased — its authorisation differs. See [Interface alignment](#interface-alignment--an-aip-20-private-profile).

## The six things "on top of" could mean

### Option A — depend on the crate and extend it

**Verdict: impossible, and not for want of trying.**

Noir permits one contract per crate, and a `type = "contract"` crate cannot be extended. Importing `token_contract` gives you its *generated interface* — `Token::at(address).transfer_private_to_private(...)` — for making calls to a deployed instance. It does not give you its implementation to build on.

The library confirms this is the intended reading: AIP-4626, which the documentation describes as "extending the AIP-20 token contract", depends on it exactly that way —

```toml
# src/vault_contract/Nargo.toml
token_contract = { path = "../token_contract" }
```

— and then *calls* it: `Token::at(shares_token).burn_public(from, shares, nonce)`. The vault is a separate deployed contract that holds and moves a separate deployed token. "Extends" means "composes with", not "inherits from".

There is no `type = "lib"` crate anywhere in the workspace, so there is not even a partial reuse path for note types or balance helpers. The reusable pieces this project does depend on — `aztec`, `uint_note`, `balance_set`, `compressed_string` — come from aztec-nr, which both projects already use directly.

### Option B — use the ARC-403 authorization hook

**Verdict: the closest any option comes to working, and it fails on one specific thing.**

> The mirror image of this option — building the *hook contract* out of `cmtat_aztec_lib` so a stock AIP-20 token gains CMTAT compliance — is built, tested and measured: [`doc/auth/README.md`](../auth/README.md). It reaches the same limit from the other side, and adds a second missing argument: the hook is not told who initiated the operation either.

The design would be: deploy a stock AIP-20 token, deploy a CMTAT compliance contract, and nominate the latter as the token's `auth_contract`. The compliance contract holds the roles, the pause flag, the freeze flags and the lists, and reverts in `authorize_private` / `authorize_public` when a transfer must not proceed.

**What the hook is given:** `(from: AztecAddress, amount: u128, selector: Field)`.

**Where it is called:** nine sites — all five private transfer paths, both public transfer paths, `burn_private` and `burn_public`.

**Where it is not called:** `mint_to_private`, `mint_to_public` and `mint_to_commitment`. Minting is not hooked at all. *(This project screens the recipient of a mint and the account of a burn against the lists, as CMTAT Solidity does; the code-quality review's `G-1` was closed by making the code do what its comment claimed. The hook is not called on either, so a sidecar cannot screen them.)*

#### What CMTAT controls the hook can and cannot express

| CMTAT control | Expressible through the hook? | Why |
|---|---|---|
| Pause | ✔ | Revert unconditionally; needs no argument |
| Permanent deactivation | ✔ | Same |
| Maximum transfer amount | ✔ | `amount` is passed |
| Freeze the **sender** | ✔ | `from` is passed |
| Blacklist / whitelist the **sender** | ✔ | `from` is passed |
| Per-operation rules by function | ✔ | `selector` is passed |
| Freeze the **recipient** | ✘ | **`to` is not passed** |
| Blacklist / whitelist the **recipient** | ✘ | Same |
| Maximum balance per holder | ✘ | Needs the recipient and their balance |
| Restrictions on mint | ✘ | Mint does not call the hook |
| Forced transfer | ✘ | Not expressible anywhere in AIP-20 |

#### Why the missing recipient is decisive

CMTAT's enforcement module blocks a frozen address from **sending and receiving**. Its whitelist requires **both parties** to be listed; its blacklist rejects if **either** is listed. This implementation follows that: `tokenModule::transfer_private` (through the variant's `Screening`) asserts on `is_frozen(from)` *and* `is_frozen(to)`, and `operateOnTransfer(from, to)` screens both.

Through the hook, a frozen or blacklisted address can still **receive** tokens. An issuer who has frozen an account to stop it trading would find that the account can still be paid into — and under a whitelist regime, that tokens can be delivered to an address that was never approved to hold them. Whitelisting in particular becomes close to meaningless when only the sending side is checked: the population of addresses that may *hold* the security is exactly what a whitelist exists to control.

Two escapes, both unsatisfactory:

1. **Have the completer or recipient pull instead of push.** Restructures every transfer flow and does not help `transfer_private_to_private`, where the sender pushes by construction.
2. **Fork the token to pass `to` to the hook.** This works, and it is a small change — but it is Option D, not Option B: you now maintain a fork, and the resulting token is no longer the standard one, which was the entire reason for building on it.

#### The cost, which is not small either

The hook is a **cross-contract call from private context**. By the framework's own figure — quoted from the Aztec documentation, **not measured here** — each additional private call adds roughly 101,000 gates for the extra kernel iteration. A transfer in this project currently costs 120,824 gates, so routing every transfer through an external hook would be on the order of a 80% increase in the user's proving work, before the compliance contract does anything.

There is also a privacy consequence worth naming: a compliance contract that must consult public state (a role table, a pause flag) faces exactly the problem this project already solved. It must either enqueue a public call — publishing the sender's address on every transfer — or hold its flags as `DelayedPublicMutable` and accept the delay. The library's own test hook takes the first route: `authorize_private` enqueues `record_call_internal(from, amount, selector)`, which publishes `from`. A real hook must not do that.

### Option C — wrap the token in a compliance contract

**Verdict: collapses into re-implementing the token.**

The idea: deploy a stock AIP-20 token, have a CMTAT contract hold all of it, and let the CMTAT contract track the beneficial owner of each unit.

It fails immediately. AIP-20's private transfer functions are callable by any holder directly; a wrapper cannot intercept them. To make the wrapper authoritative it must be the sole holder — at which point the underlying token has one holder, all real balances live in the wrapper's own ledger, and the wrapper has re-implemented notes, balances, transfers and delivery. The AIP-20 token beneath it is then an accounting artefact whose only effect is a contract call on every operation.

This is the pattern AIP-4626 uses legitimately, because a vault genuinely *is* a separate instrument holding a separate asset. It does not transfer to a token that is meant to *be* the asset.

### Option D — vendor the contract and modify it

**Verdict: possible, honest, and probably not worth it.**

Copy `token_contract/src/main.nr` — 695 lines — into this repository, add the compliance modules, and extend the hook signature to include the recipient.

What it buys:

- The partial-note helpers — `initialize_commitment`, `complete_commitment` and the validity-commitment check — already written and tested.
- The recursive balance subtraction, which [`F-1`](../audits/tools/v0.3.0/CLAUDE_ANALYSIS.md) measures as worth **43,046 gates, 36% of a transfer**.
- The public/private balance split, if wanted.
- The AIP-20 entry-point names, which tooling recognises — though a fork that adds recipient screening is no longer conformant, so this benefit is partly illusory.

What it costs:

- A hard fork with no upstream path. `aztec-standards` is pre-release and moving; every upstream fix becomes a manual merge into a file that has diverged.
- The compliance surface must be added to **every** path — five private transfer variants, two public, three mints, two burns — where this project has three. That is a larger attack surface to get right, and each path needs its own tests.
- The two conflicts from the comparison document remain in reduced form: public balances would have to be either screened or removed, and the commitment paths can screen the recipient only at initialization, so they need an expiry to bound the gap before completion (see the corrected Conflict 2).

### Option E — copy the patterns, not the code

**Verdict: this is what is already recommended, and it does not require the submodule.**

The valuable, portable ideas are:

- **The note budget with recursion** (`INITIAL_TRANSFER_CALL_MAX_NOTES = 2`, `RECURSIVE_TRANSFER_CALL_MAX_NOTES = 8`). Measured worth: 43,046 gates per transfer, with the caveat that the recursion has to be built to make it safe. *Taken in 0.4.0 (review A-5): `tokenModule::debit_private` with `DEBIT_INITIAL_MAX_NOTES` / `DEBIT_RECURSIVE_MAX_NOTES` and a `_recurse_debit` entry point per variant, −42,203 gates on a transfer.*
- **A named sentinel for "this party is private" in public events** rather than overloading the zero address.
- **The hook shape itself** — now that ARC-403 exists, a CMTAT-on-Aztec that wants to be hook-compatible could adopt the same signature *plus* the recipient, and propose the addition upstream.

None of these needs a dependency. All are implementable against the aztec-nr libraries this project already uses.

### Option F — fork the library and move it to v5.2.0

**Verdict: mechanically trivial — measured, not estimated — which relocates the argument rather than settling it.**

The hypothesis: fork `aztec-standards`, bring it from `v5.0.0-rc.2` to the `v5.2.0` this project already uses, and build from there. Rather than estimate the migration effort, it was done in a scratch copy of the checkout.

**What the migration consisted of.** Eleven `Nargo.toml` edits and **no source changes at all**:

- the four aztec-nr crates (`aztec`, `uint_note`, `balance_set`, `compressed_string`) repointed from `aztec-packages/noir-projects/aztec-nr/<crate>` at `v5.0.0-rc.2` to the standalone `AztecProtocol/aztec-nr` repository at `v5.2.0` — the same source this project uses;
- one protocol-circuits crate (`serde`, used by `escrow_contract`) left in `aztec-packages` with its tag bumped to `v5.2.0`, because that tree does not exist in the standalone repository.

That second point is the only trap: the library mixes crates that moved to the standalone repository with one that did not, so the remap is not a pure find-and-replace. Getting it wrong produces `Cannot read file .../noir-protocol-circuits/crates/serde/Nargo.toml`, which is what the first attempt hit.

**Result.**

| Step | Outcome |
|---|---|
| `aztec-nargo compile --package token_contract` | 0 errors |
| `aztec-nargo compile --workspace` (all 11 crates) | 0 errors |
| `aztec test --package token_contract` | **79 / 79 pass** |

The API gap between `v5.0.0-rc.2` and `v5.2.0` is, for this library, nil. That is not surprising in hindsight — the rc.2 → 5.2.0 hop is a patch series inside one major, where this project's own 0.63.1 → 5.2.0 migration crossed the macro rewrite — but it needed measuring, because the [blocker table](#practical-blockers-independent-of-the-design) below originally listed the version mismatch as a wall. It is a one-afternoon task, and the table has been corrected.

*(A first test run showed 78 failures; that was a setup error, not the fork — only `token_contract` had been compiled, and the "on behalf of" tests deploy `GenericProxy`, whose missing artifact crashed the TXE server and cascaded `client error (Connect)` into every later test. Compiling the workspace fixed it. Recorded because it is the same `ENOENT` class this project hit during its own migration.)*

**What the fork buys, measured.** With the artifacts built at `v5.2.0`, the two tokens can be profiled on the same toolchain:

| Operation | AIP-20 token (`v5.2.0` fork) | private-CMTAT-aztec |
|---|---:|---:|
| Private → private transfer | **63,310** | 120,824 |
| Private burn | 38,221 | 81,736 |
| Mint to private | 28,654 | 30,776 |
| One recursion step (fragmented balance) | 30,136 + a kernel iteration | — |

The transfer gap is large, and it reconciles almost exactly against components already measured in this repository: **120,824 − 10,408** (validation module, base vs Light) **− 1,679** (`Transfer` event) **− 43,046** (16-note vs 2-note budget) **= 65,691**, against AIP-20's 63,310. The residual ~2,400 gates is the two freeze reads, the issuer read and the two issuer note copies, less the hook's `PublicImmutable` check. In other words: the CMTAT features cost what they were measured to cost, and **the note budget is the only part of the gap that is a free lunch** — which is why Option E already recommends taking it.

**What the fork does not change.** Every design conclusion above stands:

- It is still a `type = "contract"` crate. A fork could *add* a `type = "lib"` crate by extracting the token's internal helpers — but that is new engineering the upstream has not done, and it is exactly the module-library structure this project already has.
- The ARC-403 hook is still not passed the recipient. Adding `to` is a small change in a fork — and the moment it is made, the token is no longer AIP-20, which was the point of starting from it.
- Public balances and commitment paths still conflict with screening (Conflicts 1 and 2 in the [comparison](./cmtat-vs-aip20.md)).

**The maintenance cost, quantified.** The upstream is slow-moving: 4 commits in the 90 days before the pinned commit, all four touching `token_contract`, and three of them version bumps (`upgrade to 4.3.0`, `upgrade v5.0.0`, `upgrade to 5.0.0 rc.2`). ARC-403 itself landed on 2026-07-06, which is why the Aztec documentation does not mention it. A fork would mostly be *ahead* of upstream on Aztec versions and would have little to merge — the "fast-moving target" concern in Option D is weaker than stated there.

**So where does that leave it?** Option F makes Option D cheap to *start*. It does not make it cheap to *finish*: the work is not the port, it is adding recipient screening to every one of twelve transfer, mint and burn paths and deciding what to do about public balances and commitments — after which the result is a CMTAT with AIP-20 function names that no AIP-20 wallet can safely treat as AIP-20. The fork is feasible; it is not obviously desirable.

## Interface alignment — an AIP-20 private profile

> **Status (2026-09-14): done.** The five renames below were applied to all three variants in 0.4.0 — `transfer` → `transfer_private_to_private`, `mint` → `mint_to_private`, `public_get_name` / `_symbol` / `_decimals` → `name` / `symbol` / `decimals`; `burn` was kept, as the trap below requires. A test in the base variant (`test_aip20_profile.nr`) pins the seven private-profile selectors to the values read from the fork's `Token::interface()` and checks that `burn` does not answer AIP-20's `burn_private`. The table and mapping below are kept as the record of why.

A narrower question than the options above: without adopting AIP-20's architecture, could this token's **entry points** be aligned with AIP-20's, so that tooling written for the standard's private paths works against it unchanged?

**Yes, and it is a rename.** On Aztec a caller reaches a function by its **selector**, which is derived from the function name and the parameter *types* — not the parameter names. That was checked rather than assumed, by computing selectors from both compiled artifacts with `FunctionSelector.fromNameAndParameters`:

| Function | AIP-20 | This token | Same selector? |
|---|---|---|---|
| `balance_of_private(owner)` | `0x4375727c` | `0x4375727c` | **already** |
| `total_supply()` | `0x8dd382ec` | `0x8dd382ec` | **already** |
| `transfer_private_to_private(from, to, amount, _nonce)` | `0xedc09d49` | `transfer(…)` → `0x49b80d25` | after rename: **`0xedc09d49`** — with `authwit_nonce` left as is |
| `mint_to_private(to, amount)` | `0xf8f84119` | `mint(…)` → `0x724402ae` | after rename: yes |
| `name()` / `symbol()` / `decimals()` | `0x5c5c9c42` / … | `public_get_name()` → `0xc8bbd7b4` / … | after rename: yes |
| `burn_private(from, amount, _nonce)` | `0xc282ed79` | `burn(account, …)` → `0x16a23d86` | after rename: yes — **but see below** |

The third row is the useful one: renaming `transfer` to `transfer_private_to_private` and changing nothing else — same types, `authwit_nonce` kept — produces AIP-20's exact selector. Parameter names are invisible to the selector, so the descriptive name this project chose costs nothing.

### What each entry point maps to

| This token | Alignment | Note |
|---|---|---|
| `transfer` | **rename** → `transfer_private_to_private` | Same shape; ours may also revert for compliance reasons, which AIP-20's may too, via its hook |
| `mint` | **rename** → `mint_to_private` | AIP-20 checks a single immutable minter, ours checks `MINTER_ROLE`; identical from the caller's side |
| `public_get_name` / `_symbol` / `_decimals` | **rename** → `name` / `symbol` / `decimals` | Pure rename. The `private_get_*` variants stay as this project's extras |
| `balance_of_private`, `total_supply` | **already aligned** | Nothing to do |
| `burn` | **do not alias** to `burn_private` | Different authorisation — see the trap below |
| `transfer_batch`, `mint_batch`, `burn_batch`, `cancel_authwit` | keep | No AIP-20 counterpart; harmless extras |
| every `*_to_public`, `*_to_commitment`, `balance_of_public`, `initialize_transfer_commitment`, `get_auth_contract` | **absent, deliberately** | Conflicts 1 and 2 in the [comparison](./cmtat-vs-aip20.md) |
| `constructor` | stays different | AIP-20's two constructors take an `auth_contract`; deployment tooling differs regardless |

The `Transfer` event already has the same name and the same fields (`from`, `to`, `amount`) on both sides.

### The full AIP-20 surface, and what CMTAT does not have

The profile above is seven functions. The fork's `Token` exposes twenty-two. This is the whole list, so that "partial profile" has a precise meaning; the status is for the three token variants after the 0.4.0 renames.

| AIP-20 entry point | Context | In CMTAT | Why not, or what it would take |
|---|---|---|---|
| `constructor_with_initial_supply(name, symbol, decimals, initial_supply, to, auth_contract)` | public, initializer | different | CMTAT's `constructor(admin, name, symbol, decimals)` seats a role table and an issuer, not a minter and a hook. Deployment tooling differs whatever else is aligned; F7 in [`aip20-features-for-cmtat.md`](./aip20-features-for-cmtat.md#f7--named-constructors) adds named constructors |
| `constructor_with_minter(name, symbol, decimals, minter, auth_contract)` | public, initializer | different | Same |
| `transfer_private_to_private(from, to, amount, _nonce)` | private | **yes** | Aligned; may revert for compliance |
| `transfer_private_to_public(from, to, amount, _nonce)` | private | **yes, behind `public_side_enabled`** | Since 0.4.0 — see [the cross-domain paths](#the-cross-domain-paths-what-they-are-for-and-offering-them-as-a-holders-choice) |
| `transfer_private_to_public_with_commitment(from, to, amount, _nonce)` | private | **yes, behind `public_side_enabled`** | Since 0.4.0 |
| `transfer_private_to_commitment(from, commitment, amount, _nonce)` | private | **yes, behind `public_side_enabled`** | Since 0.4.0; the recipient is screened at `initialize_transfer_commitment` and the issuer is notified there. No expiry (F2 addition 1) yet |
| `transfer_public_to_private(from, to, amount, _nonce)` | private | **yes, behind `public_side_enabled`** | Since 0.4.0 |
| `initialize_transfer_commitment(to, completer)` | private | **yes, behind `public_side_enabled`** | Since 0.4.0; screens `to` and notifies the issuer |
| `transfer_public_to_public(from, to, amount, _nonce)` | public | **no** | Public balances on both sides, and the parties and amount are public call arguments (conflict 1) |
| `transfer_public_to_commitment(from, commitment, amount, _nonce)` | public | **no** | Conflicts 1 and 2 |
| `balance_of_private(owner)` | utility | **yes** | Aligned |
| `balance_of_public(owner)` | public, view | **yes** | Since 0.4.0 (reads zero when the public side is off) |
| `total_supply()` | public, view | **yes** | Aligned |
| `name()`, `symbol()`, `decimals()` | public, view | **yes** | Aligned; `private_get_*` are extras |
| `get_auth_contract()` | public, view | **no** | CMTAT's compliance is internal to the token; there is no hook to point at. F3 would add a rule-engine hook, in the ARC-403 shape but passed the recipient and caller, with its own getter |
| `mint_to_private(to, amount)` | private | **yes** | Aligned; `MINTER_ROLE` instead of one immutable minter |
| `mint_to_public(to, amount)` | public | **no** | Public balances (conflict 1) |
| `mint_to_commitment(commitment, amount)` | public | **no** | Partial notes (conflict 2) |
| `burn_private(from, amount, _nonce)` | private | **deliberately not** | CMTAT has `burn(account, amount, authwit_nonce)`, `BURNER_ROLE`-gated on top of the holder's authwit — see the trap below. Same shape, different authorisation, so a different name |
| `burn_public(from, amount, _nonce)` | public | **no** | Public balances (conflict 1) |

Read down the "why" column and the missing fifteen collapse to three causes: **public balances** (eight entry points), **partial notes** (five, two of them also public), and the **burn authorisation** (one), plus the constructors. The first two are the design conflicts the comparison document identifies, and both are answered by the same product decision recorded in [`aip20-features-for-cmtat.md`](./aip20-features-for-cmtat.md): they stay out of CMTAT-private and go, if anywhere, into a separate CMTAT-private-AIP20 variant that discloses what they publish.

What CMTAT has that AIP-20 does not, for the mirror image: `transfer_batch`, `mint_batch`, `burn_batch`, `cancel_authwit`, the `private_get_*` getters, `public_get_issuer` / `private_get_issuer` / `set_issuer`, `version`, and the whole compliance and metadata surface (roles, pause, deactivation, freeze, lists, terms, token ID, and on the Debt variant credit events and debt).

### The cross-domain paths: what they are for, and offering them as a holder's choice

> **Status (2026-09-14): implemented in 0.4.0**, as proposed below — the four bridges plus `initialize_transfer_commitment` and `balance_of_public`, behind the `public_side_enabled` deployment flag, with the compliance chain in the private half, recipient screening at commitment opening and a `CommitmentInitialized` event to the issuer. Not implemented: the commitment expiry, and the public-to-public transfer, public mint and public burn (decision 2 below, left as "not needed"). One deliberate departure from the standard's code, added after the 0.4.0 review (K-6): a commitment can be **paid only once** — `pay_commitment` pushes a nullifier derived from the commitment, where AIP-20 lets a second completion debit the payer for a note the recipient never discovers; see [`doc/technical/commitment-reuse.md`](commitment-reuse.md). The derived code is in `lib/src/modules/hybridModule.nr` under the MIT licence. User documentation: [`doc/README.md`, "Private/public bridges"](../README.md#privatepublic-bridges).

Four of the missing entry points are not "public balances" in the sense of a transparent ledger; they are the **bridges between the private and the public domain** that give AIP-20 its "hybrid" character. A holder who has private notes can decide to move some of them into the public side of the token, and back. The question this raises for CMTAT is different from F6's: not "should balances be public" but "may a holder *choose* to make one of their own transfers public".

#### What each one does, from the AIP-20 documentation and source

| Entry point | What happens | Who decides | What becomes public | What stays private |
|---|---|---|---|---|
| `transfer_private_to_public(from, to, amount, _nonce)` | `from`'s notes are spent in private; `to`'s **public balance** is credited by an enqueued public call | The sender | `to`, `amount` (arguments of the public call) and a `Transfer(PRIVATE_ADDRESS, to, amount)` event | `from` |
| `transfer_public_to_private(from, to, amount, _nonce)` | `from`'s public balance is debited by an enqueued public call; `to` receives a **note** | The sender (who holds a public balance) | `from`, `amount`, `Transfer(from, PRIVATE_ADDRESS, amount)` | `to` |
| `transfer_private_to_commitment(from, commitment, amount, _nonce)` | `from`'s notes are spent; the amount completes a **partial note** that `to` created earlier with `initialize_transfer_commitment(to, completer)` and handed to the sender | The recipient prepares, the sender pays | Nothing about the parties; the completion log carries the **amount unencrypted** (visible but unlinked, see F2) | `from`, `to` |
| `transfer_private_to_public_with_commitment(from, to, amount, _nonce)` | `transfer_private_to_public` plus a partial note for `to` with the sender as completer, returned as a commitment | The sender | As `transfer_private_to_public` | `from`; the commitment's recipient |

The AIP-20 page states the purpose plainly. Private functions run on the holder's device against an anchor block and cannot read current public state — a DEX quote, an auction result, a vault's share price — so a private holder cannot interact with a public-side protocol in one step. The domain bridges are how a holder *enters* such a protocol (`private_to_public`: pay a contract that keeps public balances), *leaves* it again (`public_to_private`: shield the proceeds back into notes), and the partial-note forms are how the return leg can be prepared privately before the public computation happens (`_with_commitment`: deposit publicly now, receive the private output later through a note only the sender can complete; `to_commitment`: pay into a note whose owner is already fixed, so a contract or a counterparty can settle later). These are the AIP-4626 vault and AMM flows in the fork's own test suites, and they are also, in the words of [`cmtat-vs-aip20.md`](./cmtat-vs-aip20.md), delivery-versus-payment: an investor pre-opens a commitment, the other leg pays into it when it settles.

#### Could CMTAT offer them alongside `transfer_private_to_private`?

Yes, as a **holder's deliberate choice**, and the case is stronger than the F6 verdict suggests, because the four paths do not make the *token* public — they make *one transfer* public, at the initiative of the party whose side becomes visible:

- In `transfer_private_to_public` the sender chooses; what is published is the recipient's public credit and the amount, and the recipient, by holding a public balance at all, has already accepted that its public position is visible. The sender stays private.
- In `transfer_public_to_private` the sender is already public; the recipient stays private. Nobody's privacy is reduced by someone else's choice.
- In the commitment forms the parties stay private on both sides; only the amount leaks, unlinked, and only when the recipient chose to work with a commitment.

So the privacy-table change is not "balances become public" but *"a holder may opt a transfer, and its own public balance, out of privacy; counterparties keep theirs"*. Read that way the paths are compatible with a token that is private by default, provided the compliance chain follows them. What following them requires, path by path:

| | Screening | Audit copy to the issuer | Lifecycle |
|---|---|---|---|
| `transfer_private_to_public` | `from` and `to` in the private half, exactly as today (`operateOnTransfer(from, to)`, freeze on both) | The public credit is public state the issuer reads directly; nothing to deliver | Pause check in the enqueued public half, as today |
| `transfer_public_to_private` | Same, in the private half — the function is private in AIP-20 too | The note for `to` gets the issuer's offchain copy, as every note does | Same |
| `transfer_private_to_commitment` | `from` at completion; **`to` at `initialize_transfer_commitment`**, since the commitment holds nothing to screen later | The issuer must receive the partial note at initialization (F2, addition 2) | Pause at completion; an **expiry** on the commitment (F2, addition 1) so a recipient frozen after initialization cannot be paid indefinitely |
| `transfer_private_to_public_with_commitment` | As `private_to_public`, plus `to` is the commitment's recipient — already screened | As above | As above |

The first two are a small change: two entry points, one `public_balances` map, `balance_of_public` to read it, the same private-half invariant chain the token already has, and the public `Transfer` events with the `PRIVATE_ADDRESS` marker (F5) that AIP-20 indexers expect. The commitment forms carry F2's three additions, and F2's conclusion stands: they belong to a variant that discloses the unencrypted completion amount.

Two things would have to be decided by the issuer, not the holder, and both are one flag:

1. **Whether holders get the choice at all.** A `PublicImmutable<bool>` set at deployment — `public_side_enabled` — under which the four paths revert. A token deployed with it off is byte-for-byte today's behaviour and privacy table; a token deployed with it on is the hybrid, and its assessment says so. This keeps one codebase and lets the privacy table read *"private; the issuer may enable a public side that holders opt into per transfer"*.
2. **Whether public balances are also transferable publicly.** `transfer_public_to_public`, `mint_to_public` and `burn_public` are not needed for the four bridges — a public balance can exist only as a landing and departure point — but a holder with a public balance will expect to move it. If they are added, their compliance chain runs entirely in public (both parties, freeze, lists, pause), which is straightforward but doubles the surface to test; the parties and amounts are public call arguments, which is what the holder chose.

**Where this leaves F6.** The F6 verdict — public balances in neither product — was written for a transparent second ledger. The four bridges are the narrower thing: per-transfer, holder-initiated, issuer-enabled. They are compatible with the CMTAT-private premise under the flag above and are the natural first content of the CMTAT-private-AIP20 variant; whether to enable them on a given deployment is the issuer's compliance call, and the assessment's privacy table must be filled for the deployment, not the code.

### The burn trap

`burn` is the one function that *could* be renamed to match and *must not* be, because an identical selector with different semantics is worse than a different name.

- AIP-20 `burn_private(from, amount, _nonce)` is **holder-authorised**: the only gate is `#[authorize_once("from", "_nonce")]`. Any holder burns their own tokens.
- CMTAT `burn(account, amount, authwit_nonce)` is **privileged**: the caller must hold `BURNER_ROLE` *and* the holder must consent. A plain holder calling it gets `AccessControlUnauthorizedAccount`. This is by design — in CMTAT, burning is redemption, an issuer act.

A wallet that sees selector `0xc282ed79` would call it as a self-burn and fail with a role error it has no way to anticipate. Keeping the CMTAT name makes the difference discoverable instead of surprising. *(CMTAT Solidity's `BURNER_SELF_ROLE` lives in the cross-chain module, not the core, so there is no core self-burn to map to either.)*

### What alignment buys, and what it does not

**Buys.** Any tool or contract that uses only AIP-20's private paths — `transfer_private_to_private`, `mint_to_private`, `balance_of_private`, `total_supply`, `name`/`symbol`/`decimals` — works unchanged, because it addresses the token by selector. That includes *other contracts*: a Noir contract holding a generated `Token::at(address)` interface for those functions would call this token successfully. The generated TypeScript call shapes become identical too, since arguments are positional.

**Does not buy.** Aztec has no interface detection, so a partial profile is invisible until a missing function is called: a tool that also uses `transfer_public_to_public` or the commitment paths fails at that call, not at discovery. This is exactly why the README must state the non-conformance explicitly rather than let the matching names imply it. And the constructor still differs, so deployment tooling is unaffected either way.

**Costs.** It is an ABI break — five renames across three `main.nr` files, the generated TypeScript, the e2e tests, the interaction scripts, and every document that names the functions, including the equivalency assessment's implementation-details cells. One-time, mechanical, and no storage or note-layout change.

### Verdict

**Worth doing, as a bounded change, if being reachable by AIP-20 private-profile tooling is wanted** — five renames (`transfer`, `mint`, `public_get_name`, `public_get_symbol`, `public_get_decimals`), `burn` kept as is, and a README sentence stating that the token exposes the AIP-20 private profile only and why. It is not conformance and should not be described as such; it is the largest slice of compatibility available without touching any of the conflicts, and its entire cost is a rename.

## Pause and deactivation on top of AIP-20

The blocker table below used to list "no pause anywhere" as if it were a wall. It is not: AIP-20 ships no pause, but the ARC-403 hook is exactly where one goes, and **both pause and permanent deactivation are expressible through it** — with one asymmetry on minting that is worth stating precisely, because it cuts in an unexpected direction.

### What "paused" blocks — three implementations, three answers

The reference is not what this repository does. CMTAT Solidity's validation (`ValidationModule._canMintBurnByModule`) refuses a mint or burn when the contract is **deactivated** or the target is frozen — it does **not** consult `paused()`. Only standard transfers check the pause flag. So in the reference, pause is a transfer restriction and issuance and redemption continue through it; deactivation is what stops everything.

| While **paused** | CMTAT Solidity | This repository | AIP-20 + a CMTAT hook |
|---|---|---|---|
| Transfer | ✘ blocked | ✘ blocked | ✘ blocked — every transfer path is hooked |
| Mint | ✔ allowed | ✔ allowed | ✔ allowed — mint is not hooked |
| Burn | ✔ allowed | ✔ allowed | **policy's choice** — burn is hooked, and the hook receives the selector, so it can let burns through a pause |

| While **deactivated** | CMTAT Solidity | This repository | AIP-20 + a CMTAT hook |
|---|---|---|---|
| Transfer | ✘ | ✘ | ✘ |
| Mint | ✘ — explicit check | ✘ — explicit check | **✔ — cannot be blocked**, mint is not hooked |
| Burn | ✘ — explicit check | ✘ — explicit check | ✘ — the hook refuses |

Two observations fall out of that.

**On pause, the hook can be exactly as faithful to CMTAT as this repository now is.** This repository used to block mint and burn while paused, a documented deviation; it has since been aligned with the reference — `_transfer` asserts not-paused, `_mint` and `_burn` assert not-deactivated. A hook-based pause reproduces the same thing: transfers refused, mint untouched because it is never hooked, burn let through by matching its selector.

**On deactivation, the hook leaves one gap, and it is the mint gap again.** A deactivated AIP-20 token can still be minted into, because `mint_to_private`, `mint_to_public` and `mint_to_commitment` do not call the hook. CMTAT Solidity blocks that explicitly, and so does this repository, with the same explicit not-deactivated check in `_mint`. Behind the hook it is an operational rule — the minter is the issuer's own key, so the issuer stops minting — but it is not enforced, and criterion 17 (*Deactivate contract*) should be answered with that caveat rather than a clean `y`.

### Immediate or delayed — the same choice this repository already made

`authorize_private` runs in private context, and a private function cannot read a `PublicMutable`. A pause flag inside the hook therefore has two possible shapes:

- **`DelayedPublicMutable<bool>`** — readable from private, so the hook decides without enqueuing anything and the token's transfer acquires no public footprint at all. The cost is that a pause takes the delay to bite. The early feasibility probe did this; the shipped [`CMTATAztecAuth`](../auth/README.md#why-the-pause-is-checked-in-public) does not, for the reason given under `H-3`.
- **`PublicMutable<bool>` plus an enqueued public check** — `authorize_private` enqueues a call to the hook's own `#[only_self]` checker. The pause is immediate. The price is a public call on every transfer that reveals the hook was consulted — the same footprint this repository's `_transfer()` already has, for the same reason.

The first is not the free choice it looks. The delay would be at least this repository's 360 seconds, the library recommends *"at least a couple hours"* for a `DelayedPublicMutable`, and its documentation calls the type *"unsuitable for actions that must be executed immediately — such as an emergency shutdown"* — a shorter delay narrows every transaction's validity window and fingerprints it, since a private read sets the transaction's `expiration_timestamp`. CMTAT expects immediacy, so a policy that wants to match the reference takes the second. `authorize_public` can read the flag directly, but a CMTAT policy refuses every public path anyway. See the code-quality review's H-3 and H-6 for the full duration analysis.

### Permanence, status, and where they live

- **Deactivation is permanent for the same reason it is here.** The hook holds the flag, and `cmtat_aztec_lib`'s `PauseModule` already implements *deactivate requires an existing pause, then blocks unpause forever*. The token's `auth_contract` pointer being `PublicImmutable` means the hook cannot be swapped out to undo it — immutability works in the policy's favour on this one point.
- **Status is readable, but from the hook.** Criteria 16 and 18 (*know pause status*, *know deactivate status*) are answered by getters on the authorization contract. A tool that only knows the token finds them through `get_auth_contract()`, and the assessment must say so.
- **Cost.** A `DelayedPublicMutable` read in private is on the order of the 1,920 gates one measured at in the code-quality review; the enqueued alternative costs the public call instead. Both are inside the 20,715 gates the probe's whole `authorize_private` measured at.

**Verdict.** Pause and deactivation are not a reason to avoid the hook; they are among the things it does best. The one caveat to disclose is that deactivation cannot stop minting, which is the same mint gap that runs through every other section of this document.

## Practical blockers independent of the design

Even if one of the options above were chosen, these apply:

| Blocker | Detail |
|---|---|
| **Version mismatch** — *downgraded from blocker to chore* | `aztec-standards` pins `v5.0.0-rc.2` from `aztec-packages`; this project pins `v5.2.0` from the standalone `aztec-nr` repository. An earlier revision of this document called this a wall. It was then tried ([Option F](#option-f--fork-the-library-and-move-it-to-v520)): eleven manifest edits, no source changes, 79/79 tests pass. The only trap is that one crate (`serde`) lives in a tree that did not move to the standalone repository. |
| **Pre-release library** | The checkout describes itself as `prerelease-0200230-14-ga3859e5`. Its interfaces are not stable, and the Aztec documentation already warns that it differs from the reference contracts in `aztec-packages`. |
| **`auth_contract` is `PublicImmutable`** | The compliance contract is fixed at deployment and cannot be replaced. A bug in it, or a change of compliance policy that needs new state, means redeploying the token and migrating every holder. CMTAT's Solidity RuleEngine is settable for exactly this reason. |
| **The token depends on a test crate** | `token_contract/Nargo.toml` lists `authorization_contract = { path = "src/test/test_authorization_contract" }` — the production crate depends on a crate under `src/test/` for the hook interface. Workable, but it signals the hook interface has not yet been factored out for third-party use. |
| **No pause, freeze or lists built in** — *not a blocker* | Confirmed by inspection: zero occurrences of pause, freeze, blacklist or allowlist in the token contract. All of it lives behind the hook — and pause and deactivation in particular are fully expressible there, with one caveat on minting. See [Pause and deactivation on top of AIP-20](#pause-and-deactivation-on-top-of-aip-20). |

## Recommendation

**Do not rebuild on `aztec-standards` — and the reason is no longer "it would be hard to port".** Option F showed the port is trivial. The reason is that after the port every design problem is still there, and solving them produces a fork that is no longer the standard. Keep the current architecture — CMTAT modules over aztec-nr, three deployment variants — and take from AIP-20 the two things that are portable:

1. **Adopt the note-budget-plus-recursion pattern.** This is the measured win and it is independent of everything else. Prerequisite is a note-count distribution measurement, not an architecture decision. — **Done** in 0.4.0 under review finding A-5: two notes, then `_recurse_debit` at eight per call, AIP-20's constants credited in the code; −42,203 gates on a transfer.
2. **Consider aligning a future compliance hook with ARC-403's shape**, so that a CMTAT compliance contract could serve both this token and a stock AIP-20 token if the hook ever gains a recipient argument. — **Done on the contract side, not on the token side.** The two authorization contracts are that compliance contract, in ARC-403's shape, serving the fork's tokens today. The token's own settable hook — F3 of the features document, with `to` and the caller added — is still open.

**And raise the recipient argument upstream.** `authorize_private(from, amount, selector)` cannot express recipient screening, which every regulated token needs and which is not an exotic requirement — ERC-3643, ERC-1404 and CMTAT all check both parties. Adding `to` to the hook signature would cost the standard very little and would be the difference between "a compliant token can use AIP-20" and "a compliant token must fork it". That is the single most valuable change this project could suggest to the standard, and it supersedes suggestion A-1 in the companion document, which asked for a hook that already exists.

## What to do with the submodule

`submodules/aztec-standards` is checked out but nothing in the build references it — no `Nargo.toml` in this workspace depends on it, and the workspace members are unchanged.

Two coherent choices:

- **Keep it, as a reference.** It is the canonical AIP-20 source and the documentation explicitly says the reference contracts in `aztec-packages` differ from it. Having it pinned makes claims about AIP-20 checkable. It now lives under `submodules/` with the other reference repositories, since `lib/` in this workspace means "the shared Noir library" and a second meaning there is confusing.
- **Drop it**, and cite the repository by URL and commit in these two documents instead.

Keeping it is the better answer while these comparisons are live; it was moved out of `lib/` and repointed at the [CMTA fork](https://github.com/CMTA/aztec-standards), which carries the 5.2.0 upgrade of Option F.
