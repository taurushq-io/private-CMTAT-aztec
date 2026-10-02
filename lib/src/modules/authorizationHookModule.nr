//! The rules an ARC-403 authorization contract applies on behalf of a CMTAT deployment, shared by the
//! `CMTATAztecAuth` (AIP-20 token) and `CMTATAztecAuthMultiToken` (ARC-1155) contracts.
//!
//! The hook receives `(from, amount, selector)` - never the recipient, never the initiator - so the
//! rules are the subset of CMTAT Solidity's `ValidationModule` that can be evaluated on `from` alone:
//!
//! - a **transfer** (any selector that is not a burn) requires the contract not paused, `from` not
//!   frozen and `from` clear of the enabled list: `_canTransferStandardByModule` minus the `spender`
//!   and `to` checks;
//! - a **burn** requires the contract not deactivated, `from` not frozen and `from` clear of the
//!   enabled list: `_canMintBurnByModule(from)` (allowlist variant).
//!
//! The list check is sender-only for the same reason: a blacklisted address cannot send or burn but
//! can still receive. The token contracts screen both parties.
//!
//! A mint never reaches the hook (the AIP-20 and ARC-1155 mint paths do not call it), so the
//! `_canMintBurnByModule(to)` rule of a mint cannot be applied and the minter must be trusted.
//!
//! Which rule applies is decided from the selector the token passes. Only the two burn selectors are
//! recognised; everything else, including a selector from an unknown caller, gets the stricter
//! transfer rule. The selectors are computed from the signatures of the reference contracts in
//! `submodules/aztec-standards` (parameter names do not enter a selector; `AztecAddress` encodes as
//! `(Field)`), so a fork that renames or re-types `burn_private` / `burn_public` must update them.

use crate::modules::enforcementModule::{Freezable, FreezableFlag};
use crate::modules::pauseModule::PauseModule;
use crate::modules::validationModule::{UserFlags, ValidationModule};
use aztec::context::{PrivateContext, PublicContext};
use aztec::protocol::abis::function_selector::FunctionSelector;
use aztec::protocol::address::AztecAddress;
use aztec::protocol::traits::ToField;

// AIP-20 `Token`: `burn_private(from: AztecAddress, amount: u128, _nonce: Field)` and `burn_public` alike.
pub global AIP20_BURN_PRIVATE_SELECTOR: Field =
    FunctionSelector::from_signature("burn_private((Field),u128,Field)").to_field();
pub global AIP20_BURN_PUBLIC_SELECTOR: Field =
    FunctionSelector::from_signature("burn_public((Field),u128,Field)").to_field();

// ARC-1155 `MultiToken`: `burn_private(from: AztecAddress, id: Field, amount: u128, _nonce: Field)` and `burn_public` alike.
pub global ARC1155_BURN_PRIVATE_SELECTOR: Field =
    FunctionSelector::from_signature("burn_private((Field),Field,u128,Field)").to_field();
pub global ARC1155_BURN_PUBLIC_SELECTOR: Field =
    FunctionSelector::from_signature("burn_public((Field),Field,u128,Field)").to_field();

global TEXT_FROM_IS_FROZEN: str<20> = "Frozen: from address";
global TEXT_PAUSED: str<25> = "Error: contract is paused";
global TEXT_DEACTIVATED: str<30> = "Error: contract is deactivated";

/// True when `selector` is one of the two burn selectors given; every other selector is a transfer.
pub fn is_burn_selector(selector: Field, burn_selectors: [Field; 2]) -> bool {
    (selector == burn_selectors[0]) | (selector == burn_selectors[1])
}

/// The private half of the hook: the only rule a private function can evaluate is the freeze flag,
/// because it is a `DelayedPublicMutable`. The pause and deactivation flags are `PublicMutable`
/// (immediate, as CMTAT requires) and are checked by an enqueued public call - see
/// [`require_lifecycle_allows`].
pub fn require_from_not_frozen_private(
    enforcement: Freezable<FreezableFlag, &mut PrivateContext>,
    from: AztecAddress,
) {
    assert(!enforcement.is_frozen(from), TEXT_FROM_IS_FROZEN);
}

/// The sender-side list check, in private. Reverts with the validation module's own messages
/// (`The sender is in the blacklist` / `The sender is not in the whitelist`).
pub fn require_from_listed_private(
    validation: ValidationModule<UserFlags, &mut PrivateContext>,
    from: AztecAddress,
) {
    validation.operateOnFrom(from);
}

/// The sender-side list check, in public.
pub fn require_from_listed_public(
    validation: ValidationModule<UserFlags, PublicContext>,
    from: AztecAddress,
) {
    validation.operateOnFrom(from);
}

/// The public half of the hook, and the whole of it when the token calls `authorize_public`.
///
/// `is_burn` selects the CMTAT rule: a burn is stopped by deactivation, a transfer by a pause.
/// Deactivation implies a pause (`deactivate` requires one and `unpause` refuses afterwards), so the
/// transfer rule does not re-check deactivation - the same shortcut CMTAT Solidity takes in
/// `_canTransferStandardByModuleAndRevert`.
pub fn require_lifecycle_allows(pause: PauseModule<PublicContext>, is_burn: bool) {
    if is_burn {
        assert(!pause.is_deactivated(), TEXT_DEACTIVATED);
    } else {
        assert(!pause.is_paused(), TEXT_PAUSED);
    }
}

/// Freeze rule evaluated in public, for `authorize_public`.
pub fn require_from_not_frozen_public(
    enforcement: Freezable<FreezableFlag, PublicContext>,
    from: AztecAddress,
) {
    assert(!enforcement.is_frozen(from), TEXT_FROM_IS_FROZEN);
}
