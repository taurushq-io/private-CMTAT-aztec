use crate::modules::access_controlModule::{AccessControlModule, DEFAULT_ADMIN_ROLE, PAUSE_ROLE};
use aztec::context::PublicContext;
use aztec::protocol::address::AztecAddress;
use aztec::state_vars::{PublicMutable, StateVariable};

pub global PAUSED_FLAG: u64 = 1;
pub global T_SERIALIZED_LEN: u32 = 1;

pub struct PauseModule<Context> {
    pub is_paused: PublicMutable<bool, Context>,
    pub is_deactivated: PublicMutable<bool, Context>,
}

// TODO(#13824): remove this impl once we allow structs to hold state variables.
//
// Two slots: `is_paused` at `storage_slot`, `is_deactivated` at `storage_slot + 1`.
impl<Context> StateVariable<2, Context> for PauseModule<Context> {
    fn new(context: Context, storage_slot: Field) -> Self {
        assert(storage_slot != 0, "Storage slot 0 not allowed. Storage slots must start from 1.");
        Self {
            is_paused: PublicMutable::new(context, storage_slot),
            is_deactivated: PublicMutable::new(context, storage_slot + 1),
        }
    }

    fn get_storage_slot(self) -> Field {
        // the *first* slot; the framework reserves the following one for `is_deactivated`
        self.is_paused.get_storage_slot()
    }
}

impl PauseModule<PublicContext> {

    pub fn is_paused(self: Self) -> bool {
        self.is_paused.read()
    }

    pub fn is_deactivated(self: Self) -> bool {
        self.is_deactivated.read()
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    pub fn pause(self: Self, caller: AztecAddress, ac: AccessControlModule<bool, PublicContext>) {
        ac.only_role(PAUSE_ROLE, caller);
        self._require_not_paused();
        self.is_paused.write(true);
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     * - The contract must not be deactivated. This is what makes deactivation permanent.
     */
    pub fn unpause(self: Self, caller: AztecAddress, ac: AccessControlModule<bool, PublicContext>) {
        ac.only_role(PAUSE_ROLE, caller);
        self._require_not_deactivated();
        self._require_paused();
        self.is_paused.write(false);
    }

    /**
     * @dev Permanently deactivates the contract. There is no way back: the flag is never cleared,
     * and `unpause` refuses to run once it is set.
     *
     * Follows the CMTAT Solidity `PauseModule.deactivateContract`: the contract must already be
     * paused, so deactivation freezes that pause in place rather than introducing a second
     * "everything is blocked" state. Every value-moving operation in this contract asserts
     * `is_paused == false` in its enqueued public half, so a contract that is deactivated - and
     * therefore paused forever - can no longer mint, transfer or burn. That is the same reasoning
     * CMTAT Solidity gives for not re-checking deactivation on its transfer path.
     *
     * Requirements:
     *
     * - The caller must have the admin role.
     * - The contract must be paused.
     * - The contract must not already be deactivated.
     */
    pub fn deactivate(
        self: Self,
        caller: AztecAddress,
        ac: AccessControlModule<bool, PublicContext>,
    ) {
        ac.only_role(DEFAULT_ADMIN_ROLE, caller);
        self._require_paused();
        self._require_not_deactivated();
        self.is_deactivated.write(true);
    }

    fn _require_not_paused(self: Self) {
        assert(self.is_paused.read() == false, "error: contract already paused");
    }

    fn _require_paused(self: Self) {
        assert(self.is_paused.read() == true, "error: contract already unpaused");
    }

    fn _require_not_deactivated(self: Self) {
        assert(self.is_deactivated.read() == false, "error: contract is deactivated");
    }
}
