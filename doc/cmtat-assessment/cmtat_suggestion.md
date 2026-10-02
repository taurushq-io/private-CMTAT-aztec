# CMTAT Equivalency Assessment — suggested improvement: the freeze window

## Purpose

This document suggests an addition to the **CMTAT Equivalency Assessment Criteria** (`CMTAT-equivalency-assessment`, template `v0.3.0`): a warning note under the Freeze section, recording that on many blockchains a targeted address can move its tokens between the moment a freeze is submitted and the moment it becomes effective.

It comes from filling that template for the Aztec implementation in this repository (see [`README.md`](./README.md)), and is a suggestion produced here, not a CMTA publication.

## The gap

Criteria 19 and 20 require freeze and unfreeze, and criterion 21 requires the frozen status to be readable. Nothing in the template addresses **when** a freeze takes effect, and the criteria are worded as though it were instantaneous.

Between the moment the issuer decides to freeze an address and the moment the ledger enforces it, there is always a window in which the target can still transfer. It exists on every chain the criteria are likely to be applied to, but its size and its character differ enough that an assessment which does not mention it will record two very different exposures as the same answer.

**On a public EVM chain.** The freeze transaction sits in the public mempool before inclusion. Anyone can read it there, including the address being frozen. A target monitoring the mempool can broadcast a competing transfer with a higher priority fee and be included first. The window runs from broadcast until inclusion: at least one block, and longer if the freeze is underpriced or the network is congested. It is not only a matter of waiting for the next block either, because the party building a block orders the transactions inside it, usually by what it is paid — so the target may be placed ahead of the freeze within the same block. It is a *race*: the issuer can often win it by paying more, and can avoid it by submitting through a private relay, so that the transaction is not publicly visible before inclusion.

**On a chain where compliance state is read privately.** Aztec is the case this repository documents. A private function cannot read current mutable public state, so a freeze flag has to be a value with a scheduled change and a minimum delay, and that delay is what lets a client-side proof rely on the value. The scheduled change is visible in public state as soon as it is submitted, and it becomes effective only when the delay elapses. The window is therefore *deterministic and guaranteed*: it cannot be shortened by paying more, and no private submission path removes it, because the delay is protocol-enforced rather than a consequence of transaction visibility.

**On a permissioned ledger** the window may be negligible or absent, depending on whether the target can observe pending state.

An assessment can currently answer criterion 19 with `y` in all three cases and record none of this. Two implementations with materially different enforcement guarantees then read identically to whoever relies on the assessment.

## Suggestion

Add a warning note to the **Freeze** subsection of *Guideline for New Blockchain Implementations*, and a sentence to the Notes column of criteria 19 and 20 pointing at it.

Proposed wording for the guideline subsection:

> **Warning — the freeze window.** Depending on the underlying ledger, a freeze may not be instantaneous. Between the moment it is submitted and the moment the ledger enforces it, a targeted address that is monitoring the chain may be able to transfer its tokens. On a public blockchain the freeze transaction is visible in the mempool before inclusion, and the target can pay a higher priority fee to be ordered ahead of it; the window lasts until inclusion, so at least one block and longer if the transaction is underpriced or the network is congested, and it can be avoided by submitting through a private relay (for example Flashbots Protect on Ethereum) so that the transaction is not publicly visible beforehand. On a blockchain where compliance state is read from private execution, the flag may instead carry a protocol-enforced delay, in which case the window is deterministic, publicly visible and cannot be avoided by paying more or by routing the transaction differently. On a permissioned ledger the window may be negligible, if pending transactions are not visible to the target.
>
> An implementation SHOULD state which of these applies, whether the window has a bounded length and what that bound is where one exists, and what compensating measure is available — for example pausing the token until the freeze is effective, which blocks every holder rather than racing one address. Where the length cannot be known in advance, as on a chain where it depends on fee markets and congestion, saying so is the useful answer.

Proposed addition to the Notes column of criteria 19 and 20:

> Where a freeze may not take effect immediately, the window between submission and enforcement SHOULD be documented, together with whether its length is bounded; see *Freeze* in the guideline section.

## Why a note rather than a new criterion

A freeze window is a property of the underlying ledger rather than of the token contract, so an implementation cannot be marked non-compliant for having one — CMTAT Solidity has one too. Making it a numbered criterion would also renumber every criterion after it and invalidate assessments already filled against the current template. A warning note in the guideline section, which sits outside the equivalency count, records the difference where an assessor will read it without changing any answer.

## How this repository answers it

The Aztec implementation answers criteria 19 and 20 `y`, and records the window in the *Enforcement* note of its assessment. That note is reproduced in full below so this file can be read on its own; only its closing cross-reference back to this document has been dropped. In it, `CHANGE_ROLES_DELAY_SECONDS` is the contract's freeze delay, currently 360 seconds.

> The flag is a `Map<AztecAddress, DelayedPublicMutable<FreezableFlag, CHANGE_ROLES_DELAY_SECONDS>>`. The delay is not a tuning choice: a private function proves its execution against a historical state, so it can only trust a public value that is guaranteed not to change for a known window. Reading the flag any other way — through a public call — would publish the caller's address on every transfer. The delay is the price of checking compliance state privately.
>
> **Why this is answered `y` and not `partial`.** The delay opens a window in which a target who is watching can still move tokens. That window is not unique to this chain.
>
> - **CMTAT Solidity has the same exposure.** A freeze transaction sits in the public mempool where anyone can see it, and a monitoring target can submit a competing transfer with a higher priority fee and be included first.
> - **Its window is not one block either.** It lasts until the freeze is included, which is longer if the transaction is underpriced or the network is congested, and the party building the block decides the order inside it.
> - **The feature the criteria ask for is fully present.** A role-restricted flag that blocks transfers in both directions and is publicly readable is exactly what criteria 19 and 20 describe, and the template's own definition of `y` allows the chain-level mechanism to differ.
>
> **What differs is whether the issuer can do anything about it.**
>
> - **On Ethereum the window can be won, or hidden.** The freezer can often win the race by paying more, and can avoid it altogether by submitting through a private relay such as Flashbots Protect: the transaction is then not in the public mempool, so the target has nothing to react to. The window still exists, but it is no longer observable.
> - **Here it can be neither won nor hidden.** It is protocol-enforced rather than a consequence of transaction visibility: the scheduled change is visible in public state and becomes effective only after `CHANGE_ROLES_DELAY_SECONDS`.
> - **The mitigation is procedural rather than transactional.** Pause the token, schedule the freeze, wait out the delay, then unpause — which blocks every holder for the duration instead of racing one address.

Answering the two questions this suggestion would add to the template: the window here **is** bounded, at `CHANGE_ROLES_DELAY_SECONDS`, and the compensating measure is the pause described above. This suggestion exists so that a future assessor is prompted to record the same two things rather than having to notice that they are missing.
