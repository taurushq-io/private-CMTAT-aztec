# Moving mint, transfer and burn into a library module

> **Status (2026-09-15): applied.** `lib/src/modules/tokenModule.nr` exists (281 lines), the three `main.nr` shrank by 105 / 105 / 97 lines, the `Screening` trait was used rather than the `Option`, and the gate profile of all 48 private circuits is byte-identical before and after. Test counts unchanged. The rest of this note is the analysis as written before the change.
>
> **Where the applied code differs from the sketch below (2026-09-22).** The note is kept as written, so four names in [The change](#the-change) do not exist in the repository, and one placement changed.
>
> - **`Screening` is the trait, not the struct.** The sketch shows a `Screening<Context>` struct carrying `Option<ValidationModule>`; the code has a `pub trait Screening` with two implementations, `FreezeAndLists` (base, Debt) and `FreezeOnly` (Light) — the shape [Disadvantages](#disadvantages) recommends over the `Option`.
> - **The public halves were not split the way the sketch splits them.** `require_mint` + `increase_supply` became one `mint_public`, `require_burn` + `decrease_supply` one `burn_public`; only `require_transfer` kept its name. Searching the repository for the other four finds nothing.
> - **The bridge chains live in `tokenModule.nr`, not `hybridModule.nr`.** `bridge_private_to_public`, `bridge_public_to_private`, `open_commitment` and `pay_commitment` sit next to the three operations; `hybridModule.nr` kept `PublicBalances`, `initialize_commitment` and `complete_commitment`, which is also what keeps its MIT-only provenance clean.
> - **The module is now 360 lines, not 281**, and the growth is the note's argument being cashed in: `A-5` added the note budget (`try_debit`, `debit_recursive`, `debit_private` and the recursion closure the four chains take) and `K-6` added `commitment_paid_nullifier`, each written **once** where before 0.4.0 each would have been written three times. Those are the first two changes to the compliance chain since the refactor.
> - **The verification plan's counts are superseded.** It expects 95 / 11 / 6 / 29 / 28; the suite is at **237** (143 base, 12 Debt, 7 Light, 38 + 37 authorization). The gate-diff step is unchanged and is still the acceptance test — the 0.4.0 review adopted it as the standing rule for any change claiming to be a pure refactor.
> - **The residue guard [Limitations that remain](#limitations-that-remain) asks for exists.** "A test that computes each variant's selectors and asserts the shared set is equal across the three artifacts" is `tests/cmtat-aztec-debt/src/test_selectors.nr` and its Light twin, added as `K-4`.

A design note for a refactor that was then done: taking the bodies of the value-moving operations — mint, transfer, burn, their batch forms, their enqueued public halves and the four private/public bridges — out of the three `main.nr` files and into one module of `cmtat_aztec_lib`, so that the compliance chain exists once instead of three times. It states what would change, what it would cost, what it would buy, what it would not, and what Noir does not allow.

## Table of contents

- [The duplication today](#the-duplication-today)
- [What Noir allows and what it does not](#what-noir-allows-and-what-it-does-not)
- [The change](#the-change)
- [Cost](#cost)
- [Advantages](#advantages)
- [Disadvantages](#disadvantages)
- [Limitations that remain](#limitations-that-remain)
- [Alternatives considered](#alternatives-considered)
- [Verification plan](#verification-plan)
- [Recommendation](#recommendation)

## The duplication today

The three deployment variants are separate contract packages because Noir allows one contract per package and has no inheritance. Every module they share (`AccessControlModule`, `PauseModule`, `Freezable`, `ValidationModule`, `ExtraInformation`, the debt and credit-events extensions) already lives once, in `lib/src/modules/`, and each `main.nr` declares thin entry points around it — `pause_contract` is four lines. The value-moving operations are the exception: their logic sits in the contract files themselves.

Measured on the three `main.nr` at the head of the 0.4.0 branch, by banner section:

| Section | `CMTATAztec` | `CMTATAztecDebt` | `CMTATAztecLight` | Nature |
|---|---:|---:|---:|---|
| MINT | 59 | 59 | 57 | entry points + `_mint_internal` chain |
| TRANSFER | 101 | 101 | 100 | entry points + `_transfer_internal` chain + `cancel_authwit` |
| BURN | 63 | 63 | 61 | entry points + `_burn_internal` chain |
| INTERNAL | 57 | 57 | 57 | `_mint` / `_transfer` / `_burn` public halves, role grant helper |
| HYBRID | 179 | 179 | 176 | four bridges, helpers, public halves |
| **Total** | **459** | **459** | **451** | of 1,046 / 1,146 / 955 lines |

The Light variant's copies differ from the base only by the three list-check lines it lacks (it has no `ValidationModule`); the Debt variant's are identical to the base's. Line for line, 506 of the base's lines also appear in Light and 550 in Debt. So roughly **1,370 lines exist in triplicate**, and about two thirds of them — the internal chains, the batch loops, the public halves, the hybrid helpers — are logic, not declarations.

The cost of the triplication is not the lines; it is the rule that goes with them. `CLAUDE.md` says "keep the three `main.nr` files in step", and the 0.3.0 review recorded the risk as finding `D-1`, *cross-variant drift*, left open as structural: "it costs nothing while the three files agree, and becomes expensive the moment one of them is edited alone". Every change made in 0.4.0 to these paths — the AIP-20 renames, the bridges, the hook-related screening helpers — was applied three times by a script and checked by diff. That works while one person does it with tooling; it is exactly the kind of invariant that a second contributor breaks.

## What Noir allows and what it does not

The reason the operations are not in a module is a real language constraint, but a narrower one than "modules cannot hold token logic".

**Must stay in the contract module (`#[aztec] pub contract … { }` in `main.nr`):**

- the `#[external(...)]` function declarations themselves, with their attributes — `#[authorize_once("from", "authwit_nonce")]`, `#[only_self]`, `#[view]`, `#[initializer]`. The `#[aztec]` macro collects external functions from the contract module only; a library cannot contribute an entry point;
- `self.enqueue_self.<fn>(...)`: the enqueue targets are the contract's own public functions and the generated `enqueue_self` object is contract-specific;
- `self.emit(Event { .. })`: `#[event]` structs are contract types, and the `#[aztec]` macro keeps a global event-selector registry — the same struct in two crates collides (this is why `contracts/cmtat-aztec-auth` could not be a dependency of a token, see `doc/auth/README.md`);
- the `#[storage] struct Storage` and its slot order.

**Can move to a library:**

- everything a function does with the state variables once it has them. Library functions already take state-variable structs by value — `ac: AccessControlModule<bool, PublicContext>`, `Freezable<FreezableFlag, &mut PrivateContext>` — because each module struct is a plain value holding a context and a slot. `Owned<BalanceSet<Context>>`, `PublicMutable<u128, Context>` and `DelayedPublicMutable<..>` are the same kind of value and can be passed the same way;
- the `#[internal("private")]` helper bodies (`_mint_internal`, `_transfer_internal`, `_burn_internal`, `_screen_transfer`, `_debit_private`, `_credit_private`, `_open_commitment` minus its event) and the `#[internal("public")]` ones (`_grant_role_internal` minus its event);
- the bodies of the enqueued public halves (`_mint`, `_transfer`, `_burn`, `_credit_public`, `_debit_public`), which are a role check, a lifecycle check and a `total_supply` or public-balance update;
- the batch loops.

Two properties make the move free at runtime. `#[internal]` functions are inlined by the framework, and ordinary Noir library functions are inlined by the compiler, so the circuits are the same either way — the 0.3.0 review's `A-1` measurement (hoisting the issuer read out of the batch loop) already relied on this. And passing state variables as arguments does not touch the `#[storage]` struct, so no slot moves: the note-hash and nullifier derivations, which depend on the `private_balances` slot, are untouched.

## The change

One new file, `lib/src/modules/tokenModule.nr`, and thinner `main.nr` files.

### The library side

```noir
/// Which parties a screening applies to. The Light variant has no ValidationModule, so the list
/// check is optional; the freeze check is not.
pub struct Screening<Context> {
    pub enforcement: Freezable<FreezableFlag, Context>,
    pub validation: Option<ValidationModule<UserFlags, Context>>,
}

impl Screening<&mut PrivateContext> {
    pub fn transfer(self, from: AztecAddress, to: AztecAddress) { /* freeze both, operateOnTransfer */ }
    pub fn mint(self, to: AztecAddress)                          { /* freeze to,   operateOnMint   */ }
    pub fn burn(self, account: AztecAddress)                     { /* freeze acct, operateOnBurn   */ }
    pub fn sender(self, from: AztecAddress)                      { /* freeze from, operateOnFrom   */ }
    pub fn recipient(self, to: AztecAddress)                     { /* freeze to,   operateOnTo     */ }
}

// Note movement, with the issuer's audit copy of every note - the invariant the README calls hard.
pub fn debit_private(balances: Owned<BalanceSet<&mut PrivateContext>, &mut PrivateContext>, from, amount, issuer)
pub fn credit_private(balances: ..., to, amount, issuer)

// The three operations' private chains: screen, then move notes.
pub fn mint_private(balances, screening, to, amount, issuer)
pub fn transfer_private(balances, screening, from, to, amount, issuer)
pub fn burn_private(balances, screening, account, amount, issuer)

// The enqueued public halves' bodies. Lifecycle differs by operation, as CMTAT Solidity requires.
pub fn require_mint(ac, pause, caller)        // MINTER_ROLE, not deactivated
pub fn require_burn(ac, pause, caller)        // BURNER_ROLE, not deactivated
pub fn require_transfer(pause)                // not paused
pub fn increase_supply(total_supply: PublicMutable<u128, PublicContext>, amount)
pub fn decrease_supply(total_supply, amount)
```

The hybrid helpers (`PublicBalances`, `initialize_commitment`, `complete_commitment`) already live in `hybridModule.nr`; the refactor would give that module the bridges' private chains too (`bridge_private_to_public`, `bridge_public_to_private`, `open_commitment`, `pay_commitment`) so that each bridge in `main.nr` becomes one call, one enqueue and, where there is one, one event.

Error messages move with the logic and become one set of strings, which is a small correctness gain in itself: today `Frozen: Sender` / `Frozen: Recipient` / `Frozen: Account` appear in three files each and any reviewer checking them has to check three times.

### The contract side

```noir
#[authorize_once("from", "authwit_nonce")]
#[external("private")]
fn transfer_private_to_private(from: AztecAddress, to: AztecAddress, amount: u128, authwit_nonce: Field) {
    let issuer = self.storage.issuer_address.get_current_value();
    transfer_private(self.storage.private_balances, self.screening(), from, to, amount, issuer);
    self.enqueue_self._transfer();
    let transfer_event = self.emit(Transfer { from, to, amount });
    transfer_event.deliver_to(to, MessageDelivery::onchain_constrained());
    transfer_event.deliver_to(issuer, MessageDelivery::onchain_constrained());
}

#[external("public")]
#[only_self]
fn _transfer() {
    require_transfer(self.storage.pause_module);
}
```

with `self.screening()` a two-line `#[contract_library_method]` (or a plain helper) that builds the `Screening` value from the variant's storage — `Option::some(self.storage.validation_module)` in the base and Debt variants, `Option::none()` in Light. That helper is the **only** place the variants differ on these paths.

Per `main.nr`, the five sections above shrink from ~459 lines to an estimated ~200 (declarations, attributes, `PRIVACY:` comments, event lines, enqueues). The library gains ~250 lines that replace ~780. Net across the repository: about 500 lines fewer, and one copy of every rule.

## Cost

| Item | Estimate | Note |
|---|---|---|
| Library module | ~250 lines, new file | Straight extraction; the code exists |
| Three `main.nr` | ~260 lines removed each, ~60 rewritten | Mechanical, but it is the core of the token |
| Tests | none added for behaviour; the existing 95 + 11 + 6 Noir tests are the net | One test per operation that the Light variant screens freeze only, if not already present |
| Gate profile | one `aztec profile gates ./target` run, diffed against the current numbers | Expected identical for every private function; any change is a bug in the refactor |
| Documents | `CLAUDE.md`/`AGENTS.md` key concepts and file tree, `doc/README.md` module section, the standards documents that name `_transfer_internal` (`aip20-features-for-cmtat.md` F1, `cmtat-vs-aip20.md`) | Names only |
| Storage, ABI, selectors, note layout, `VERSION` | **unchanged** | Not a MAJOR reason; fits inside 0.4.0 or after it equally |

Effort is in the order of a day's careful work, most of it in re-reading the three files side by side before touching them and in the profile diff afterwards.

## Advantages

- **One compliance chain.** The property the equivalency assessment audits — freeze on both parties, list on both parties, role and lifecycle in public, the issuer's copy of every note — is asserted in one function per operation. A reviewer reads it once; a change lands once. `D-1` closes.
- **The variants become what the README says they are**: compositions of modules. Today `CMTATAztecLight` is "the base without the validation module" in the README and "the base with three lines deleted from five sections" in the code.
- **Error messages, constants and `PRIVACY:` reasoning in one place.** The hard-won comments on what the public halves must not take as arguments would sit next to the one function that enqueues them.
- **A fourth variant costs a storage struct and thin declarations**, not a fourth copy of 460 lines. The hybrid flag, the debt modules and any future module already compose that way; the token core would too.
- **The authorization contracts already prove the shape works.** `authorizationHookModule.nr` holds the rules and `CMTATAztecAuth` / `CMTATAztecAuthMultiToken` are thin declarations over it; that is this refactor applied to a smaller surface, and it compiled first time.
- **No runtime cost**, for the inlining reasons above — to be confirmed by measurement, not assumed.

## Disadvantages

- **The library becomes opinionated.** Today `cmtat_aztec_lib` is a set of independent modules a downstream contract can pick from (the `J-3` probe); `tokenModule.nr` would encode *this* token's chain — issuer copy offchain, constrained event to two parties, lifecycle-by-operation. A downstream contract that wants a different chain writes its own, as today, so nothing is lost, but the module's name should not suggest it is the only way to use the balance set.
- **Indirection for the reader of `main.nr`.** The contract file stops being self-contained: to know what `transfer_private_to_private` checks, one opens the library. The `PRIVACY:` comments mitigate this only if they stay at the call site, where the arguments are.
- **`Option<ValidationModule>` is a small lie in two variants.** It says "maybe a list" where the variant has decided. A `Screening` trait with two implementations (`WithLists`, `FreezeOnly`) is cleaner and monomorphises identically; it costs a trait and two impls. Either is acceptable; the note recommends the trait.
- **A refactor of the core paths, all at once.** The risk is a transcription error in the one place that now matters three times. The mitigation is the existing suite — every refusal path has a test — and the gate diff, which catches an accidental extra read or delivery.
- **Compile-error locality.** A type error inside a generic library function surfaces at the library, with the call site in a "while running this function attribute" trace; the 0.4.0 work has already shown these traces are readable but longer.

## Limitations that remain

- **The entry-point declarations stay triplicated**, by language design: ~200 lines per variant of signatures, attributes, doc comments, enqueues and event emissions. `CLAUDE.md`'s "keep the three files in step" survives for that residue; it just guards declarations instead of logic. A test that computes each variant's selectors and asserts the shared set is equal across the three artifacts would make the residue machine-checked.
- **Events cannot be shared**, because of the selector registry, so `Transfer`, `NewRole`, `CommitmentInitialized` and the rest remain declared in each contract and emitted at each call site. The library can return the values to emit; it cannot emit them.
- **`enqueue_self` targets stay per contract.** A library function can decide *that* a public half must run and *with which arguments*; the call itself is written in `main.nr`. This is also the right place for it — the argument list of an enqueued call is exactly the disclosure surface the `PRIVACY:` comments police.
- **Storage stays per contract**, and with it the slot layout. The library takes the variables as arguments and never owns them; a composite `TokenCore` state variable holding `private_balances` and `total_supply` was considered and rejected because it would re-slot `private_balances`, which feeds every note hash and nullifier.
- **Generic over `Context`, twice.** Private and public halves need separate `impl` blocks, as every existing module has (`impl … <PublicContext>` / `impl … <&mut PrivateContext>`). The two are not interchangeable and the module cannot hide that.
- **Batch caps stay measured, not derived.** `MAX_ADDR_PER_CALL` and `MAX_TRANSFER_ADDR_PER_CALL` are per-call protocol budgets; moving the loop body into the library changes nothing about them. They could become library globals so a fourth variant inherits the measured values.

## Alternatives considered

- **Comptime code generation.** Noir's `comptime` metaprogramming could, in principle, generate the entry points themselves from a description — the `#[aztec]` macro does exactly this for `interface()` and `enqueue_self`. A project-level macro that stamps the value-moving functions into each contract would remove the last residue. It is also the most fragile choice: it depends on macro internals that changed between every Aztec release this repository has lived through, it makes the entry points invisible to a reader of `main.nr`, and the `#[aztec]` macro would have to see the generated functions before it runs. Not recommended while the framework's macros are moving.
- **One contract, feature flags in storage** (a single `CMTATAztec` whose debt and validation modules are enabled by constructor flags). Removes the variants entirely, at the cost of every deployment carrying the storage and the circuits of every module, and of the assessment describing a configuration rather than a contract. The `public_side_enabled` flag is this pattern applied to one feature; applying it to all of them is a different product decision, not a refactor.
- **Leave it, keep the diff-check.** Zero risk today, and the drift risk `D-1` names stays open. Acceptable while one maintainer applies changes by script; it is what the repository has done through 0.4.0.

## Verification plan

1. `aztec profile gates ./target` before, saved.
2. Extract, one operation at a time (mint, then burn, then transfer, then the bridges), running the base suite after each.
3. `yarn compile && yarn test:nr` — expect the current counts exactly (95 / 11 / 6 / 29 / 28).
4. `aztec profile gates ./target` after, diffed: every private circuit identical to the gate.
5. `yarn codegen && yarn typecheck`: the ABI must not have changed, so the generated TypeScript must diff to nothing but ordering.
6. `diff CLAUDE.md AGENTS.md` empty; the standards documents that quote helper names updated.

## Recommendation

Do it, as its own commit, with the `Screening` trait rather than the `Option`, and the gate diff as the acceptance test. It is the last structural duplication the 0.3.0 review flagged, the bridges just made it 179 lines larger, and every prerequisite is already in the repository: the library takes state variables by value, the authorization contracts prove the thin-declaration shape, and the suite covers each refusal path. Whether it lands before or after the 0.4.0 tag is a scheduling choice — it changes no storage, ABI or selector — with a mild argument for before: 0.4.0 already rewrites these paths, and a release whose three variants are provably one implementation is easier to assess than one whose equality is a diff.
