use aztec::context::{PrivateContext, PublicContext};
use aztec::protocol::address::AztecAddress;
use aztec::protocol::delayed_public_mutable::DelayedPublicMutableValues;
use aztec::protocol::traits::{Deserialize, FromField, Packable, Serialize, ToField};
use aztec::state_vars::{DelayedPublicMutable, Map, StateVariable};

use crate::modules::access_controlModule::{
    AccessControlModule, ADDRESS_LIST_ADD_ROLE, ADDRESS_LIST_REMOVE_ROLE, VALIDATION_ROLE,
};
use crate::modules::enforcementModule::schedule_with_delay;

pub global BLACKLIST_FLAG: u64 = 1;
pub global WHITELIST_FLAG: u64 = 2;

// Same value and same reasoning as `enforcementModule::CHANGE_ROLES_DELAY_SECONDS`; keep the two equal,
// a mix would fingerprint a transaction by which flags it read (H-6).
pub global CHANGE_ROLES_DELAY_SECONDS: u64 = 3600;

global TEXT_ADDRESS_FROM_IS_BLACKLISTED: str<30> = "The sender is in the blacklist";
global TEXT_ADDRESS_TO_IS_BLACKLISTED: str<33> = "The recipient is in the blacklist";
global TEXT_ADDRESS_FROM_NOT_WHITELISTED: str<34> = "The sender is not in the whitelist";
global TEXT_ADDRESS_TO_NOT_WHITELISTED: str<37> = "The recipient is not in the whitelist";

#[derive(Deserialize, Packable, Eq, Serialize)]
pub struct SetFlag {
    pub operate_blacklist: bool,
    pub operate_whitelist: bool,
}

#[derive(Deserialize, Eq, Serialize)]
pub struct UserFlags {
    pub is_blacklisted: bool,
    pub is_whitelisted: bool,
}

/// The contract a per-address flag type must satisfy to be the `T` of `ValidationModule<T, Context>`.
/// The module's screening (`operateOnTransfer`, `operateOnMint`, `operateOnBurn`) reads only these
/// two predicates; a downstream contract may add flags of its own to `T` and enforce them itself by
/// reading `map.at(address).get_current_value()`. `T` must also be `Eq + ToField + FromField + Packable`.
pub trait UserFlagsTrait {
    fn get_is_blacklisted(self) -> bool;
    fn get_is_whitelisted(self) -> bool;
}

pub struct ValidationModule<T, Context> {
    pub map: Map<AztecAddress, DelayedPublicMutable<T, CHANGE_ROLES_DELAY_SECONDS, Context>, Context>,
    pub operationsFlag: DelayedPublicMutable<SetFlag, CHANGE_ROLES_DELAY_SECONDS, Context>,
}

// TODO(#13824): remove this impl once we allow structs to hold state variables.
//
// The module occupies one slot for `map` (a Map always reserves exactly one) followed by however many
// `operationsFlag` needs. A DelayedPublicMutable stores a WithHash<DelayedPublicMutableValues<..>>, so
// that is the packed length of the values plus one. Rather than hardcode the total we let the compiler
// derive it from SetFlag's packing, so the layout stays correct if SetFlag ever grows.
impl<T, Context, let M: u32> StateVariable<M + 2, Context> for ValidationModule<T, Context>
where
    DelayedPublicMutableValues<SetFlag, CHANGE_ROLES_DELAY_SECONDS>: Packable<N = M>,
{
    fn new(context: Context, storage_slot: Field) -> Self {
        assert(storage_slot != 0, "Storage slot 0 not allowed. Storage slots must start from 1.");
        let map_slot = storage_slot;
        let ops_slot = storage_slot + 1;
        Self {
            map: Map::new(context, map_slot),
            operationsFlag: DelayedPublicMutable::new(context, ops_slot),
        }
    }

    fn get_storage_slot(self) -> Field {
        // this returns the *first* slot; the framework reserves the rest for `operationsFlag`
        self.map.get_storage_slot()
    }
}

impl<T> ValidationModule<T, PublicContext>
where
    T: Eq + ToField + FromField + UserFlagsTrait + Packable,
{
    pub fn get_operations(self: Self) -> Field {
        let operations = self.operationsFlag.get_current_value();
        operations.to_field()
    }

    pub fn set_operations(
        self: Self,
        caller: AztecAddress,
        operations: SetFlag,
        access_control: AccessControlModule<bool, PublicContext>,
    ) -> u64 {
        access_control.only_role(VALIDATION_ROLE, caller);
        self.operationsFlag.schedule_value_change(operations);
        let (_, effective_at) = self.operationsFlag.get_scheduled_value();
        effective_at
    }

    //problem: here the one that has the ADDRESS_LIST_ADD_ROLE can also remove from list by overwritting userFlag
    pub fn add_to_list(
        self: Self,
        caller: AztecAddress,
        newListAddress: AztecAddress,
        userFlag: T,
        access_control: AccessControlModule<bool, PublicContext>,
        delay: u64,
    ) -> u64 {
        access_control.only_role(ADDRESS_LIST_ADD_ROLE, caller);
        schedule_with_delay(self.map.at(newListAddress), userFlag, delay)
    }

    pub fn remove_from_list(
        self: Self,
        caller: AztecAddress,
        removeListAddress: AztecAddress,
        userFlag: T,
        access_control: AccessControlModule<bool, PublicContext>,
        delay: u64,
    ) -> u64 {
        access_control.only_role(ADDRESS_LIST_REMOVE_ROLE, caller);
        schedule_with_delay(self.map.at(removeListAddress), userFlag, delay)
    }

    /// Public-context twin of the private `operateOnFrom`, for hooks that run in public.
    pub fn operateOnFrom(self: Self, from: AztecAddress) {
        let operations = self.operationsFlag.get_current_value();

        if (operations.operate_blacklist) {
            assert(
                !self.map.at(from).get_current_value().get_is_blacklisted(),
                TEXT_ADDRESS_FROM_IS_BLACKLISTED,
            );
        } else if (operations.operate_whitelist) {
            assert(
                self.map.at(from).get_current_value().get_is_whitelisted(),
                TEXT_ADDRESS_FROM_NOT_WHITELISTED,
            );
        }
    }
}

impl<T> ValidationModule<T, &mut PrivateContext>
where
    T: Eq + ToField + FromField + UserFlagsTrait + Packable,
{

    /**
     * @dev Screens the target of a mint - the recipient - against whichever list mode is enabled,
     * mirroring CMTAT Solidity's `_canMintByModuleAndRevert(to)`. A pause does not stop a mint;
     * the lists and the freeze flag do.
     */
    pub fn operateOnMint(self: Self, to: AztecAddress) {
        self.operateOnTo(to);
    }

    /**
     * @dev Screens one address as the recipient, against whichever list mode is enabled. The
     * recipient half of `operateOnTransfer`; used where the sender is not yet known, such as when a
     * commitment is initialized for `to` before anyone pays into it.
     */
    pub fn operateOnTo(self: Self, to: AztecAddress) {
        let operations = self.operationsFlag.get_current_value();

        if (operations.operate_blacklist) {
            assert(
                !self.map.at(to).get_current_value().get_is_blacklisted(),
                TEXT_ADDRESS_TO_IS_BLACKLISTED,
            );
        } else if (operations.operate_whitelist) {
            assert(
                self.map.at(to).get_current_value().get_is_whitelisted(),
                TEXT_ADDRESS_TO_NOT_WHITELISTED,
            );
        }
    }

    /**
     * @dev Screens the target of a burn - the account being debited - mirroring CMTAT Solidity's
     * `_canBurnByModuleAndRevert(from)`. Same rules as a mint, reported as the sender.
     */
    pub fn operateOnBurn(self: Self, from: AztecAddress) {
        self.operateOnFrom(from);
    }

    /**
     * @dev Screens one address as the sender, against whichever list mode is enabled. This is the
     * sender half of `operateOnTransfer`; the ARC-403 authorization contracts use it because the hook
     * they implement is never told the recipient.
     */
    pub fn operateOnFrom(self: Self, from: AztecAddress) {
        let operations = self.operationsFlag.get_current_value();

        if (operations.operate_blacklist) {
            assert(
                !self.map.at(from).get_current_value().get_is_blacklisted(),
                TEXT_ADDRESS_FROM_IS_BLACKLISTED,
            );
        } else if (operations.operate_whitelist) {
            assert(
                self.map.at(from).get_current_value().get_is_whitelisted(),
                TEXT_ADDRESS_FROM_NOT_WHITELISTED,
            );
        }
    }

    pub fn operateOnTransfer(self: Self, from: AztecAddress, to: AztecAddress) {
        let operations = self.operationsFlag.get_current_value();

        if (operations.operate_blacklist) {
            self.detectTransferRestriction_blacklist(from, to);
        } else if (operations.operate_whitelist) {
            self.detectTransferRestriction_whitelist(from, to);
        }
    }

    fn detectTransferRestriction_blacklist(self: Self, from: AztecAddress, to: AztecAddress) {
        assert(
            !self.map.at(from).get_current_value().get_is_blacklisted(),
            TEXT_ADDRESS_FROM_IS_BLACKLISTED,
        );
        assert(
            !self.map.at(to).get_current_value().get_is_blacklisted(),
            TEXT_ADDRESS_TO_IS_BLACKLISTED,
        );
    }

    fn detectTransferRestriction_whitelist(self: Self, from: AztecAddress, to: AztecAddress) {
        assert(
            self.map.at(from).get_current_value().get_is_whitelisted(),
            TEXT_ADDRESS_FROM_NOT_WHITELISTED,
        );
        assert(
            self.map.at(to).get_current_value().get_is_whitelisted(),
            TEXT_ADDRESS_TO_NOT_WHITELISTED,
        );
    }
}

impl UserFlagsTrait for UserFlags {
    fn get_is_blacklisted(self) -> bool {
        self.is_blacklisted
    }
    fn get_is_whitelisted(self) -> bool {
        self.is_whitelisted
    }
}

impl FromField for UserFlags {
    fn from_field(value: Field) -> UserFlags {
        let value: u64 = value as u64;
        let is_blacklisted = (value & BLACKLIST_FLAG) == BLACKLIST_FLAG;
        let is_whitelisted = (value & WHITELIST_FLAG) == WHITELIST_FLAG;

        Self { is_blacklisted, is_whitelisted }
    }
}

impl ToField for UserFlags {
    fn to_field(self) -> Field {
        let mut value: u64 = 0;

        if self.is_blacklisted {
            value = value | BLACKLIST_FLAG;
        }

        if self.is_whitelisted {
            value = value | WHITELIST_FLAG;
        }

        value.to_field()
    }
}

impl Packable for UserFlags {
    let N: u32 = 1;

    fn pack(self) -> [Field; 1] {
        let mut value: u64 = 0;
        if self.is_blacklisted {
            value = value | BLACKLIST_FLAG;
        }
        if self.is_whitelisted {
            value = value | WHITELIST_FLAG;
        }
        [value.to_field()]
    }

    fn unpack(fields: [Field; 1]) -> Self {
        let value: u64 = fields[0] as u64;
        let is_blacklisted = (value & BLACKLIST_FLAG) == BLACKLIST_FLAG;
        let is_whitelisted = (value & WHITELIST_FLAG) == WHITELIST_FLAG;

        Self { is_blacklisted, is_whitelisted }
    }
}

impl FromField for SetFlag {
    fn from_field(value: Field) -> SetFlag {
        let value: u64 = value as u64;
        let operate_blacklist = (value & BLACKLIST_FLAG) == BLACKLIST_FLAG;
        let operate_whitelist = (value & WHITELIST_FLAG) == WHITELIST_FLAG;

        Self { operate_blacklist, operate_whitelist }
    }
}

impl ToField for SetFlag {
    fn to_field(self) -> Field {
        let mut value: u64 = 0;

        if self.operate_blacklist {
            value = value | BLACKLIST_FLAG;
        }

        if self.operate_whitelist {
            value = value | WHITELIST_FLAG;
        }

        value.to_field()
    }
}
