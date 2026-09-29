use crate::modules::access_controlModule::{AccessControlModule, ENFORCEMENT_ROLE};
use aztec::context::{PrivateContext, PublicContext};
use aztec::protocol::address::AztecAddress;
use aztec::protocol::traits::{Deserialize, Packable, Serialize};
use aztec::state_vars::{DelayedPublicMutable, Map, StateVariable};

// Initial delay before a scheduled change to a delayed value takes effect, in seconds (since Aztec v3 a
// DelayedPublicMutable's delay is a duration, not a number of blocks). One hour: review finding H-6
// chose it over the 360 s of the framework's `auth_contract` example, which made every value-moving
// transaction expire six minutes after its anchor block and singled it out on chain, and below the
// 24 h of the framework's `token_blacklist_contract`, which the compliance freeze window rules out.
// It is the *initial* value of every delayed variable: the contract's admin can change it at runtime
// with `set_roles_delay` (increases apply at once, decreases after the difference), and the modules'
// setters apply the contract's current setting to the entry they touch (`delay` parameter), because
// a `Map` entry carries its own delay and cannot be changed from outside.
pub global CHANGE_ROLES_DELAY_SECONDS: u64 = 3600;

/// Applies the contract's delay setting to one delayed variable, then schedules `val` on it, and returns
/// the timestamp at which `val` becomes current. Shared by the enforcement and validation setters.
pub fn schedule_with_delay<T>(
    var: DelayedPublicMutable<T, CHANGE_ROLES_DELAY_SECONDS, PublicContext>,
    val: T,
    delay: u64,
) -> u64
where
    T: Packable + Eq,
{
    var.schedule_delay_change(delay);
    var.schedule_value_change(val);
    let (_, effective_at) = var.get_scheduled_value();
    effective_at
}

#[derive(Deserialize, Packable, Eq, Serialize)]
pub struct FreezableFlag {
    pub is_freezed: bool,
}

/// The contract a flag type must satisfy to be the `T` of `Freezable<T, Context>`. The module only
/// ever asks a flag whether the address is frozen; a downstream contract may carry more state per
/// address (a reason code, an expiry) in its own `T`, as long as `T` is also `Eq + Packable`.
/// Keep `T`'s packing small: a `DelayedPublicMutable<T>` costs `2 * N + 2` slots per address.
pub trait FreezableFlagTrait {
    fn get_is_frozen(self) -> bool;
}

pub struct Freezable<T, Context> {
    pub map: Map<AztecAddress, DelayedPublicMutable<T, CHANGE_ROLES_DELAY_SECONDS, Context>, Context>,
}

// TODO(#13824): remove this impl once we allow structs to hold state variables.
impl<T, Context> StateVariable<1, Context> for Freezable<T, Context> {
    fn new(context: Context, storage_slot: Field) -> Self {
        assert(storage_slot != 0, "Storage slot 0 not allowed. Storage slots must start from 1.");
        Self { map: Map::new(context, storage_slot) }
    }

    fn get_storage_slot(self) -> Field {
        self.map.get_storage_slot()
    }
}

impl<T> Freezable<T, PublicContext>
where
    T: Eq + FreezableFlagTrait + Packable,
{

    pub fn is_frozen(self: Self, address: AztecAddress) -> bool {
        self.map.at(address).get_current_value().get_is_frozen()
    }

    /**
     * @dev Freezes an account. An account can be unfrozen
     *
     * Requirements:
     *
     * - The account must not be already frozen
     */
    /// Schedules `val` for `address` and returns the timestamp from which it is current. `delay` is the
    /// contract's current delay setting: it is applied to this address's entry first, so that entries
    /// converge to the setting as they are touched (a `Map` entry carries its own delay; see
    /// [`CHANGE_ROLES_DELAY_SECONDS`]). A longer delay applies at once, a shorter one only after the
    /// difference has elapsed, so the value change scheduled here never lands earlier than the entry's
    /// previous delay promised.
    pub fn freeze(
        self: Self,
        caller: AztecAddress,
        address: AztecAddress,
        val: T,
        ac: AccessControlModule<bool, PublicContext>,
        delay: u64,
    ) -> u64 {
        ac.only_role(ENFORCEMENT_ROLE, caller);
        self._require_not_freezed(address);
        schedule_with_delay(self.map.at(address), val, delay)
    }

    /// The reverse of [`freeze`]; same delay handling and same return value.
    pub fn unfreeze(
        self: Self,
        caller: AztecAddress,
        address: AztecAddress,
        val: T,
        ac: AccessControlModule<bool, PublicContext>,
        delay: u64,
    ) -> u64 {
        ac.only_role(ENFORCEMENT_ROLE, caller);
        self._require_freezed(address);
        schedule_with_delay(self.map.at(address), val, delay)
    }

    // Internal functions
    fn _require_not_freezed(self: Self, address: AztecAddress) {
        assert(
            self.map.at(address).get_current_value().get_is_frozen() == false,
            "error: address already freezed",
        );
    }

    fn _require_freezed(self: Self, address: AztecAddress) {
        assert(
            self.map.at(address).get_current_value().get_is_frozen() == true,
            "error: address already unfreezed",
        );
    }
}

impl<T> Freezable<T, &mut PrivateContext>
where
    T: Eq + FreezableFlagTrait + Packable,
{

    pub fn is_frozen(self: Self, user: AztecAddress) -> bool {
        let user_roles: T = self.map.at(user).get_current_value();
        user_roles.get_is_frozen()
    }
}

impl FreezableFlagTrait for FreezableFlag {
    fn get_is_frozen(self) -> bool {
        self.is_freezed
    }
}
