// SPDX-License-Identifier: MIT
//
// Portions of this file are derived from the AIP-20 `Token` contract of aztec-standards
// (https://github.com/defi-wonderland/aztec-standards, src/token_contract/src/main.nr, as carried
// by the CMTA fork at commit 5433e9c7dc34f1b426adfe0ce9e0ae3a688351d9):
// the public-balance helpers, the partial-note initialization and completion, and the
// PRIVATE_ADDRESS_MAGIC_VALUE sentinel.
//
//   Copyright (c) 2024 Wonderland
//   Licensed under the MIT License (see LICENSE-MIT.md).
//
// The remainder is Copyright (c) 2026 Capital Market and Technology Association, released under the
// same MIT licence for this file so that the derived and original parts carry one licence. This is
// the one file of `cmtat_aztec_lib` that is MIT-only rather than MIT / MPL-2.0 dual-licensed.

//! The private/public bridges of AIP-20, for a CMTAT token that is private by default.
//!
//! AIP-20 keeps a public balance per account next to the private notes, and offers four ways to
//! move value between the two domains: `transfer_private_to_public`, `transfer_public_to_private`,
//! `transfer_private_to_commitment` and `transfer_private_to_public_with_commitment`. This module
//! holds the state and the helpers those entry points need; the entry points themselves, with the
//! CMTAT compliance chain around them, live in each contract's `main.nr` under the HYBRID banner
//! (Noir requires every external function to be declared in the contract module).
//!
//! The bridges are off unless the token was deployed with `public_side_enabled = true`: a holder
//! then chooses, per transfer, to make its own side of a transfer public. What each path publishes
//! is stated in `doc/README.md`, "Private/public bridges".

use aztec::context::{PrivateContext, PublicContext};
use aztec::protocol::address::AztecAddress;
use aztec::protocol::traits::FromField;
use aztec::state_vars::{Map, PublicMutable, StateVariable};
use uint_note::{PartialUintNote, UintNote};

/// Sentinel used in public `Transfer` events for the private side of a cross-domain move, so that an
/// indexer can tell "the counterpart is private" from "the counterpart is the zero address".
/// sha224sum 'PRIVATE_ADDRESS' - the same value AIP-20 uses.
pub global PRIVATE_ADDRESS_MAGIC_VALUE: AztecAddress =
    AztecAddress::from_field(0x1ea7e01501975545617c2e694d931cb576b691a4a867fed81ebd3264);

global TEXT_PUBLIC_SIDE_DISABLED: str<37> = "Error: public side disabled at deploy";
global TEXT_INSUFFICIENT_PUBLIC_BALANCE: str<29> = "Error: public balance too low";

/// Public balances, one `u128` per address in public storage. Only reachable through the four
/// bridges: this module deliberately has no public-to-public transfer, mint or burn.
pub struct PublicBalances<Context> {
    pub map: Map<AztecAddress, PublicMutable<u128, Context>, Context>,
}

// TODO(#13824): remove this impl once we allow structs to hold state variables.
impl<Context> StateVariable<1, Context> for PublicBalances<Context> {
    fn new(context: Context, storage_slot: Field) -> Self {
        assert(storage_slot != 0, "Storage slot 0 not allowed. Storage slots must start from 1.");
        Self { map: Map::new(context, storage_slot) }
    }

    fn get_storage_slot(self) -> Field {
        self.map.get_storage_slot()
    }
}

impl PublicBalances<PublicContext> {
    pub fn balance_of(self: Self, owner: AztecAddress) -> u128 {
        self.map.at(owner).read()
    }

    /// Credits `to`. Derived from AIP-20 `_increase_public_balance`.
    pub fn increase(self: Self, to: AztecAddress, amount: u128) {
        let new_balance = self.map.at(to).read() + amount;
        self.map.at(to).write(new_balance);
    }

    /// Debits `from`, refusing an overdraft with a named error rather than an arithmetic underflow.
    /// Derived from AIP-20 `_decrease_public_balance`.
    pub fn decrease(self: Self, from: AztecAddress, amount: u128) {
        let current = self.map.at(from).read();
        assert(current >= amount, TEXT_INSUFFICIENT_PUBLIC_BALANCE);
        self.map.at(from).write(current - amount);
    }
}

/// Reverts unless the token was deployed with the public side on. `PublicImmutable` is readable from
/// private functions, so every bridge checks this in its private half and no public call is made
/// for a disabled path.
pub fn require_public_side_enabled(enabled: bool) {
    assert(enabled, TEXT_PUBLIC_SIDE_DISABLED);
}

/// Creates a partial note owned by `to` that only `completer` can later complete with an amount.
/// Derived from AIP-20 `_initialize_transfer_commitment`. The library delivers the partial note's
/// private log to `to` (unconstrained); it returns no message the caller can re-deliver, which is
/// why the contracts notify the issuer with a separate event.
pub fn initialize_commitment(
    context: &mut PrivateContext,
    to: AztecAddress,
    completer: AztecAddress,
) -> PartialUintNote {
    UintNote::partial(to, context, to, completer)
}

/// Completes a commitment with `amount` from private context, as AIP-20's
/// `transfer_private_to_commitment` does. The completion log carries `amount` unencrypted,
/// tagged by the commitment; the parties stay private.
pub fn complete_commitment(
    context: &mut PrivateContext,
    commitment: Field,
    completer: AztecAddress,
    balances_storage_slot: Field,
    amount: u128,
) {
    PartialUintNote::from_field(commitment).complete_from_private(
        context,
        completer,
        balances_storage_slot,
        amount,
    );
}
