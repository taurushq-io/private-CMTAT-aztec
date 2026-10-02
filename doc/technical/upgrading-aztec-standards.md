# Upgrading the `aztec-standards` fork to Aztec 5.2.0

Step-by-step instructions to bring a fork of [`aztec-standards`](https://github.com/defi-wonderland/aztec-standards) from the `v5.0.0-rc.2` it pins to the **`v5.2.0`** this repository uses, so that the two can be compiled, tested and composed on one toolchain.

Every step below was performed once already, in a scratch copy, while writing [`building-on-aip20.md`](./building-on-aip20.md) (Option F). The outcome was **eleven manifest edits, zero source changes, the whole 11-crate workspace compiling, and 79/79 token tests passing.** These instructions reproduce that result on the real fork and record the traps hit along the way.

> **Status (2026-09-14).** Done. The fork is [`CMTA/aztec-standards`](https://github.com/CMTA/aztec-standards), checked out as the submodule `submodules/aztec-standards` at commit `5433e9c7dc34f1b426adfe0ce9e0ae3a688351d9` (`Upgrade to Aztec 5.2.0`, branch `dev`, on top of upstream `a3859e5`). That commit repoints the eleven manifests as Step 1 describes and also bumps the TypeScript packages (Step 4) with a few matching edits to the escrow key-derivation code and the test utilities. Verified again from this repository: `aztec compile --workspace` exits 0 with 22 artifacts and `aztec test --package token_contract` passes **79/79** — but only when run from a copy **outside** this repository's tree; see Trap 3 in Step 2. The steps stay here for the next Aztec bump.

## Table of contents

- [Before you start](#before-you-start)
- [Step 0 — point the submodule at the fork](#step-0--point-the-submodule-at-the-fork)
- [Step 1 — repoint the Noir dependencies](#step-1--repoint-the-noir-dependencies)
- [Step 2 — compile the whole workspace](#step-2--compile-the-whole-workspace)
- [Step 3 — run the library's own tests](#step-3--run-the-librarys-own-tests)
- [Step 4 — the TypeScript side](#step-4--the-typescript-side)
- [Step 5 — use it from this repository](#step-5--use-it-from-this-repository)
- [Step 6 — record the pin](#step-6--record-the-pin)
- [Keeping the fork in sync with upstream](#keeping-the-fork-in-sync-with-upstream)
- [Checklist](#checklist)

## Before you start

| | |
|---|---|
| Upstream commit the fork starts from | `a3859e5` — `feat: ARC-1155 (#351)`, described as `prerelease-0200230-14-ga3859e5` |
| Its pin | `v5.0.0-rc.2`, from `AztecProtocol/aztec-packages`, directory `noir-projects/aztec-nr/<crate>` |
| Target pin | `v5.2.0`, from the standalone `AztecProtocol/aztec-nr` repository, directory `<crate>` — the same source this repository's `lib/Nargo.toml` uses |
| Toolchain | `aztec-up install 5.2.0`; `aztec --version` must print `5.2.0` |

**Why the two repositories differ.** Between `5.0.0-rc.2` and `5.2.0` the aztec-nr libraries moved out of `aztec-packages/noir-projects/aztec-nr/` into their own repository, `AztecProtocol/aztec-nr`, with the crates at its root. Most of the fork's dependencies follow that move. One does not — see the trap in Step 1.

## Step 0 — point the submodule at the fork

`.gitmodules` points at the fork, under `submodules/` with the other reference repositories (in this workspace `lib/` means "the shared Noir library", so the submodule was moved out of it):

```ini
[submodule "submodules/aztec-standards"]
	path = submodules/aztec-standards
	url = https://github.com/CMTA/aztec-standards
```

To move to a newer commit of the fork:

```bash
git submodule sync submodules/aztec-standards
cd submodules/aztec-standards
git remote -v                      # origin must be the fork
git fetch origin dev
git checkout --detach <commit>     # the parent repository records the commit, not the branch
```

> **Moving a submodule.** `git mv` updates `path =` but keeps the old section name and the old `.git/modules/<name>` directory. To rename both, edit the section name in `.gitmodules`, `git config --rename-section submodule.<old> submodule.<new>`, move `.git/modules/<old>` to `.git/modules/<new>`, and rewrite the `gitdir:` line in the submodule's `.git` file; then `git submodule sync`. That is what was done for `lib/aztec-standards` → `submodules/aztec-standards`.

## Step 1 — repoint the Noir dependencies

Eleven `Nargo.toml` files pin `v5.0.0-rc.2`:

```
src/dripper/Nargo.toml
src/escrow_contract/Nargo.toml
src/escrow_contract/src/test/test_logic_contract/Nargo.toml
src/generic_proxy/Nargo.toml
src/multitoken_contract/Nargo.toml
src/multitoken_contract/src/test/multitoken_authorization_contract/Nargo.toml
src/nft_contract/Nargo.toml
src/token_contract/Nargo.toml
src/token_contract/src/test/test_authorization_contract/Nargo.toml
src/vault_contract/Nargo.toml
src/vault_deployer/Nargo.toml
```

Two kinds of line need changing, and they go to **different repositories**.

**Kind A — the aztec-nr crates.** `aztec` (11 manifests), `compressed_string` (3), `uint_note` (1), `balance_set` (1). These moved to the standalone repository:

```toml
# before
aztec = { git = "https://github.com/AztecProtocol/aztec-packages/", tag = "v5.0.0-rc.2", directory = "noir-projects/aztec-nr/aztec" }
# after
aztec = { git = "https://github.com/AztecProtocol/aztec-nr/", tag = "v5.2.0", directory = "aztec" }
```

The same shape for the other three: `directory = "noir-projects/aztec-nr/uint-note"` becomes `directory = "uint-note"`, and likewise `balance-set` and `compressed-string`.

**Kind B — the protocol-circuits crate.** `serde` (1 manifest, `src/escrow_contract/Nargo.toml`) lives in `noir-projects/noir-protocol-circuits/`, which did **not** move. It stays in `aztec-packages` with only the tag bumped:

```toml
# before
serde = { git = "https://github.com/AztecProtocol/aztec-packages/", tag = "v5.0.0-rc.2", directory = "noir-projects/noir-protocol-circuits/crates/serde" }
# after
serde = { git = "https://github.com/AztecProtocol/aztec-packages", tag = "v5.2.0", directory = "noir-projects/noir-protocol-circuits/crates/serde" }
```

> **Trap 1 — do not blanket-replace the repository URL.** The first attempt did exactly that, and the `serde` line ended up pointing at `aztec-nr/…/noir-protocol-circuits/…`, which does not exist. The failure is not a compile error but a fetch error, and it names the wrong path:
> `Cannot read file …/aztec-nr/v5.2.0/noir-projects/noir-protocol-circuits/crates/serde/Nargo.toml - does it exist?`

Unchanged: `bignum` (`noir-lang/noir-bignum` `v0.10.0`) and `sha512` (`noir-lang/sha512`) are not Aztec crates and are left alone.

The whole step, as a script run from the fork's root:

```python
#!/usr/bin/env python3
# Repoint every Nargo.toml from aztec-packages v5.0.0-rc.2 to Aztec 5.2.0.
import glob

AZTEC_NR = {  # crates that moved to the standalone aztec-nr repository
    "noir-projects/aztec-nr/aztec": "aztec",
    "noir-projects/aztec-nr/uint-note": "uint-note",
    "noir-projects/aztec-nr/balance-set": "balance-set",
    "noir-projects/aztec-nr/compressed-string": "compressed-string",
}
OLD = 'git = "https://github.com/AztecProtocol/aztec-packages/", tag = "v5.0.0-rc.2", directory = "'

changed = 0
for path in glob.glob("src/**/Nargo.toml", recursive=True):
    s = open(path).read()
    o = s
    for old_dir, new_dir in AZTEC_NR.items():
        s = s.replace(OLD + old_dir + '"',
                      'git = "https://github.com/AztecProtocol/aztec-nr/", tag = "v5.2.0", directory = "' + new_dir + '"')
    # protocol-circuits crates stay in aztec-packages; bump the tag only
    s = s.replace(OLD + "noir-projects/noir-protocol-circuits",
                  'git = "https://github.com/AztecProtocol/aztec-packages", tag = "v5.2.0", directory = "noir-projects/noir-protocol-circuits')
    if s != o:
        open(path, "w").write(s)
        changed += 1

left = sum(open(p).read().count("v5.0.0-rc.2") for p in glob.glob("src/**/Nargo.toml", recursive=True))
print(f"repointed {changed} manifests; remaining v5.0.0-rc.2 references: {left}")
```

Expected output: `repointed 11 manifests; remaining v5.0.0-rc.2 references: 0`.

Optionally also bump `compiler_version` in the manifests that still say `">=0.25.0"` (`generic_proxy`) to `">=1.0.0"` for consistency; it is not required, the 5.2.0 toolchain's `1.0.0-beta.25` satisfies both.

## Step 2 — compile the whole workspace

```bash
cd submodules/aztec-standards
aztec compile --workspace
```

> **Trap 3 — a submodule inside a Nargo workspace cannot be built in place.** `nargo` resolves the workspace by walking **up** from the current directory to the outermost `Nargo.toml` that declares `[workspace]`. From `submodules/aztec-standards/` that is this repository's root manifest, whose members are the CMTAT crates, so `aztec compile --workspace` silently compiles **this** project (its warnings appear, no `target/` is created in the fork) and `aztec test --package token_contract` fails with `Selected package `token_contract` was not found`. `--program-dir` does not help; the walk starts from it. Build and test the fork from a copy outside this tree:
>
> ```bash
> tmp=$(mktemp -d) && git -C submodules/aztec-standards archive HEAD | tar -x -C "$tmp" && cd "$tmp"
> aztec compile --workspace && aztec test --package token_contract
> ```
>
> This is also why the scratch-copy run in the preamble worked and an in-place run does not. A contract in *this* workspace that depends on the fork by path (Step 5) is unaffected: it is compiled from this root, where the walk stops.

Two things to note:

- **Use `aztec compile`, not `aztec-nargo compile`.** At 5.2.0 `aztec-nargo` is a bare symlink to `nargo` and does not run the AVM transpiler, so the artifacts it produces cannot be consumed by `aztec codegen` or by the TXE. This repository hit that (`Contract's public bytecode has not been transpiled`) and its own `yarn compile` was changed for the same reason.
- **Compile the whole workspace, not one package.** The tests need sibling artifacts — see Trap 2.

Expected: `Compilation complete!`, zero `error:` lines, and eleven artifacts in `target/`:

```
dripper-Dripper.json
escrow_contract-Escrow.json
generic_proxy-GenericProxy.json
multitoken_authorization_contract-MultiTokenAuthorizationContract.json
multitoken_contract-MultiToken.json
nft_contract-NFT.json
test_authorization_contract-AuthorizationContract.json
test_logic_contract-TestLogic.json
token_contract-Token.json
vault_contract-Vault.json
vault_deployer-VaultDeployer.json
```

No source file should need editing. If one does, the API gap has grown since this was written — check the Aztec changelog for the macro or state-variable rename involved before touching anything.

## Step 3 — run the library's own tests

```bash
aztec test --package token_contract
```

Expected: **79 tests passed**. Then the rest of the workspace if wanted (`aztec test --workspace`; the escrow and vault suites are slower).

> **Trap 2 — a missing sibling artifact crashes the TXE and cascades.** If only `token_contract` was compiled, the first "on behalf of" test deploys `GenericProxy`, the TXE server cannot open `target/generic_proxy-GenericProxy.json`, the server dies, and **every subsequent test** fails with `Failed calling external resolver. client error (Connect)`. The first run of this migration showed 78 failures for that reason alone. The real error is the `ENOENT` in the very first failure; everything after it is noise. Step 2's `--workspace` prevents it.

If a test is failing for a reason of its own rather than under parallel load, `--test-threads 1` makes the output readable, and `aztec test --package token_contract <test_name>` runs one.

## Step 4 — the TypeScript side

The fork's `package.json` pins the JavaScript packages at `5.0.0-rc.2`:

```json
"@aztec/accounts": "5.0.0-rc.2",
"@aztec/aztec.js": "5.0.0-rc.2",
"@aztec/pxe": "5.0.0-rc.2",
"@aztec/stdlib": "5.0.0-rc.2",
"@aztec/wallets": "5.0.0-rc.2"
```

Bump all five to `5.2.0` and reinstall. This is only needed if the fork's own TypeScript tests or benchmarks will be run; the Noir side is independent of it. Expect the `5.0.0-rc.2 → 5.2.0` JavaScript API delta to be small but non-zero — this repository's migration notes in `CHANGELOG.md` list the renames that bit here (`TxStatus.SUCCESS` → `receipt.hasExecutionSucceeded()`, `deriveSigningKey` → `deriveMasterMessageSigningSecretKey`, `send({ from })`).

## Step 5 — use it from this repository

Once compiled at `v5.2.0`, the fork's crates can be depended on **as contract interfaces**. Every crate in it is `type = "contract"`, so a dependency gives you `Token::at(address).<fn>(…)` for calling a deployed instance — never its implementation to extend. That is the only way the library's own vault consumes the token, and it is the only way this repository can.

**A. Reference only — nothing to do.** For the comparisons in `doc/technical/`, the checkout itself is the artefact; no manifest in this workspace needs to change.

**B. A contract in this workspace that calls the AIP-20 token** — for example an end-to-end harness that deploys a stock token beside one of the authorization contracts of [`doc/auth/README.md`](../auth/README.md) (`contracts/cmtat-aztec-auth*`). Add the crate to the new package's manifest by path:

```toml
[dependencies]
aztec = { git = "https://github.com/AztecProtocol/aztec-nr/", tag = "v5.2.0", directory = "aztec" }
cmtat_aztec_lib = { path = "../../lib" }
token_contract = { path = "../../submodules/aztec-standards/src/token_contract" }
```

and import the generated interface: `use token_contract::Token;`. Add the package to the root `Nargo.toml` workspace `members`; the fork itself does **not** become a member.

> **The tags must agree exactly.** If this repository is on `v5.2.0` and the fork is on anything else, the build fails with `similar names, but are actually distinct types` — two `aztec` crates from different pins in one graph. That is the whole reason for this upgrade, and it is why the fork's pin must be bumped again in lockstep whenever this repository's is.

**C. The TypeScript artifacts.** `aztec codegen` over the fork's `target/` produces a `Token.ts` that this repository's e2e tests can deploy alongside `CMTATAztec`. Point it at the fork's target directory explicitly; do not merge the two `target/` trees.

## Step 6 — record the pin

Update the "What was checked" tables in the three standards documents with the fork's commit and branch once the upgrade is committed:

- [`building-on-aip20.md`](./building-on-aip20.md)
- [`cmtat-vs-aip20.md`](./cmtat-vs-aip20.md)
- [`doc/auth/README.md`](../auth/README.md)

and add the fork to the dependency notes in `CLAUDE.md` / `AGENTS.md`, which must stay identical.

## Keeping the fork in sync with upstream

Upstream moves slowly — four commits in the ninety days before `a3859e5`, three of them their own version bumps (`4.3.0`, `5.0.0`, `5.0.0-rc.2`). Expect them to reach `5.2.0` on their own; when they do, the fork's manifest diff collapses to nothing and the fork can be rebased onto upstream cleanly.

```bash
cd submodules/aztec-standards
git remote add upstream https://github.com/defi-wonderland/aztec-standards.git
git fetch upstream
git log --oneline HEAD..upstream/dev        # what has landed since the fork point
git rebase upstream/dev                     # or merge, per the fork's policy
aztec compile --workspace && aztec test --package token_contract   # from a copy outside this tree, see Trap 3
```

Watch upstream's `chore: upgrade …` commits in particular: each one changes the same eleven manifests this document changes, so a rebase across one will conflict trivially and resolve to "take upstream's line, then re-check the tag matches this repository".

## Checklist

- [x] `.gitmodules` points at the fork (`submodules/aztec-standards` → `CMTA/aztec-standards`); `git submodule sync` done
- [x] Eleven manifests repointed; `grep -r "v5.0.0-rc.2" --include=Nargo.toml` returns nothing (fork commit `5433e9c`)
- [x] `serde` in `escrow_contract` still points at `aztec-packages`, tag `v5.2.0`
- [x] `aztec compile --workspace` — zero errors (22 artifacts, from a copy outside this tree)
- [x] `aztec test --package token_contract` — 79 passed
- [x] `package.json` `@aztec/*` bumped to `5.2.0`
- [x] Fork commit and branch recorded in the standards documents and the agent guides
- [x] Both this repository and the fork pin the **same** `aztec-nr` tag (`v5.2.0`)
