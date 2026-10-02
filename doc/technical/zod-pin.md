# Why `zod` is pinned in `package.json`

A three-line entry in [`package.json`](../../package.json) that is not obvious from reading it:

```json
"resolutions": {
  "zod": "4.4.3"
},
```

This note records what it does, why the version is that one, and when it can be removed.

## Table of contents

- [What zod is, and why it is here at all](#what-zod-is-and-why-it-is-here-at-all)
- [The failure it fixes](#the-failure-it-fixes)
- [Why 4.4.3](#why-443)
- [Why `resolutions` rather than a dependency](#why-resolutions-rather-than-a-dependency)
- [Verifying the pin](#verifying-the-pin)
- [When to remove it](#when-to-remove-it)
- [The general lesson](#the-general-lesson)

## What zod is, and why it is here at all

[zod](https://zod.dev/) is a TypeScript schema-validation library: you describe the shape data should have, and it checks incoming data against that shape and hands back a typed value.

**Nothing in this repository imports it.** It arrives transitively, because five `@aztec/*` packages depend on it — `aztec.js`, `stdlib`, `foundation`, `ethereum` and `entrypoints` — and each declares the range `^4`. Aztec uses it to validate everything crossing the JSON-RPC boundary between a client and a node: transaction objects, simulation results, contract artifacts, all of which arrive as untyped JSON.

## The failure it fixes

With the range left to resolve freely, yarn installed **zod 4.5.4**, and every end-to-end test failed at contract deployment:

```
● Token › Deploys the contract
  RangeError: Maximum call stack size exceeded
    at NestedProcessReturnValues.get schema
       (@aztec/stdlib/dest/tx/public_simulation_output.js:23:42)
    at isRecursive (zod/v4/core/memoizer.js:84:29)
    at check      (zod/v4/core/memoizer.js:26:39)      ← repeating to the stack limit
```

The schema at the top of that stack is **self-referential**, and legitimately so:

```js
static get schema() {
    return z.object({
        values: NullishToUndefined(z.array(schemas.Fr)),
        nested: z.array(z.lazy(() => NestedProcessReturnValues.schema)),
    })...
}
```

A public simulation result contains nested results of its own type, because a public call can enqueue further public calls. `z.lazy(...)` is how that cycle is expressed. zod 4.5's memoizer walks a schema to decide whether it is recursive, and on this one its `isRecursive` and `check` functions call each other until the stack runs out instead of detecting the cycle.

The effect on a test run is out of proportion to the cause: deployment throws, so every later test fails with `Cannot read properties of undefined (reading 'methods')` on a contract that was never deployed. Of 16 failures, 2 were real and 14 were that cascade.

## Why 4.4.3

Dates decide it:

| | |
|---|---|
| `@aztec/stdlib@5.2.0` published | **2026-08-17** |
| Newest zod in existence at that moment | **4.4.3** (2026-05-04) |
| zod 4.5.0 released | 2026-08-28 — eleven days **after** Aztec 5.2.0 |
| What yarn had resolved | 4.5.4 |

The memoizer that overflows is new in the 4.5 line, so the toolchain was never built or tested against it. 4.4.3 is the newest release Aztec 5.2.0 could have seen, which makes it the version to pin rather than a 4.5.x picked by trial.

## Why `resolutions` rather than a dependency

Adding `zod` to `dependencies` would pin the copy this project imports — and it imports none. What has to be pinned is the copy the `@aztec/*` packages resolve, which is a nested dependency. Yarn 1's `resolutions` field overrides a version anywhere in the tree, which is exactly the reach needed here.

It also matches the discipline the project already applies elsewhere: every `@aztec/*` entry is pinned to an exact `5.2.0`, and the agent guide requires one Aztec version across `Nargo.toml`, `package.json` and the installed CLI. zod was the one hole in that.

## Verifying the pin

```bash
yarn install
node -p "require('./node_modules/zod/package.json').version"   # 4.4.3
find node_modules -maxdepth 4 -name zod -type d                # no nested copies on 4.5.x
```

The stack overflow is gone once this holds: an end-to-end run no longer reports `Maximum call stack size exceeded`.

**What the pin does not fix.** It removes one blocker, not every one. The end-to-end suite has separate problems of its own, unrelated to zod, and a green `yarn test:js` is not implied by a correct pin.

## When to remove it

Remove it when the Aztec packages are upgraded to a release built against zod 4.5 or later, or when zod fixes the recursion check and Aztec widens its range. Both are visible in the same place: if `@aztec/stdlib`'s declared range stops being a bare `^4`, the pin has been superseded.

Until then, treat it as part of the version set that has to move together, and re-check it when bumping Aztec — the same step that already updates `Nargo.toml`, `package.json` and `aztec-up`.

## The general lesson

A caret range on a **transitive** dependency is a dependency the project never chose. `^4` was written by Aztec, resolved by yarn, and the outcome changed eleven days after the Aztec release without anything in this repository changing. A lockfile records what was resolved but does not stop a fresh `yarn install` on another machine from resolving differently once the lockfile is regenerated.

The cost of finding this was an hour of a release checklist; the cost of preventing it was three lines.
