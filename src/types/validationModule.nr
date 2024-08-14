use dep::aztec::protocol_types::traits::{FromField, ToField, Serialize, Deserialize};
use dep::aztec::prelude::{AztecAddress, SharedMutable, Map, PrivateSet, PublicMutable};
use dep::aztec::context::{PublicContext, PrivateContext};

use crate::types::access_control::{AccessControl,VALIDATION_ROLE, Role, ADDRESS_LIST_ADD_ROLE, ADDRESS_LIST_REMOVE_ROLE};

global BLACKLIST_FLAG: u64 = 1;
global WHITELIST_FLAG: u64 = 2;
global SANCTIONLIST_FLAG: u64 = 4;

global CHANGE_ROLES_DELAY_BLOCKS = 2;

global TEXT_ADDRESS_FROM_IS_BLACKLISTED = "The sender is in the blacklist";
global TEXT_ADDRESS_TO_IS_BLACKLISTED = "The recipient is in the blacklist";
global TEXT_ADDRESS_FROM_NOT_WHITELISTED = "The sender is not in the whitelist";
global TEXT_ADDRESS_TO_NOT_WHITELISTED = "The recipient is not in the whitelist";

struct SetFlag {
    operate_blacklist: bool,
    operate_whitelist: bool,
    operate_sanctionlist: bool,
}

struct UserFlags {
    is_blacklisted: bool,
    is_whitelisted: bool,
    is_in_sanction_list: bool,
}

trait UserFlagsTrait {
    fn get_is_blacklisted(self) -> bool;
    fn get_is_whitelisted(self) -> bool;
    fn get_is_in_sanction_list(self) -> bool;
}

struct ValidationModule<T,Context> {
    map: Map<AztecAddress, SharedMutable<T,CHANGE_ROLES_DELAY_BLOCKS ,Context>, Context>,
    operationsFlag: SharedMutable<SetFlag,CHANGE_ROLES_DELAY_BLOCKS, Context>
}

impl<T,Context> ValidationModule<T,Context> where T: Eq + ToField + FromField + UserFlagsTrait{
    pub fn new(context: Context, storage_slot: Field) -> Self {
        assert(storage_slot != 0, "Storage slot 0 not allowed. Storage slots must start from 1.");
        Self {
            map: Map::new(
                context,
                storage_slot,
                |context, slot| SharedMutable::new(context, slot)
            ),
            operationsFlag: SharedMutable::new(context, storage_slot)
        }
    }
}

impl<T> ValidationModule<T, &mut PublicContext> where T: Eq + ToField + FromField + UserFlagsTrait{
    fn get_operations(self: Self) -> Field {
        let operations = self.operationsFlag.get_current_value_in_public();
        operations.to_field()
    }

    fn set_operations(self: Self, caller: AztecAddress, operations: SetFlag, access_control: AccessControl<bool, &mut PublicContext>) {
        access_control.only_role(VALIDATION_ROLE, caller);
        self.operationsFlag.schedule_value_change(operations);
    }
    //problem: here the one that has the ADDRESS_LIST_ADD_ROLE can also remove from list by overwritting userFlag
    fn add_to_list(self:Self,  caller: AztecAddress, newListAddress: AztecAddress, userFlag: T, access_control: AccessControl<bool, &mut PublicContext>) {
        access_control.only_role(ADDRESS_LIST_ADD_ROLE, caller);
        self.map.at(newListAddress).schedule_value_change(userFlag);
    }

    fn remove_from_list(self:Self, caller: AztecAddress, removeListAddress: AztecAddress, userFlag: T, access_control: AccessControl<bool, &mut PublicContext>) {
        access_control.only_role(ADDRESS_LIST_REMOVE_ROLE, caller);
        self.map.at(removeListAddress).schedule_value_change(userFlag);
    }
}

impl<T> ValidationModule<T,&mut PrivateContext> where T: Eq + ToField + FromField + UserFlagsTrait{


    fn operateOnTransfer(self: Self, from: AztecAddress, to:AztecAddress) {
        let operations = self.operationsFlag.get_current_value_in_private();

        if (operations.operate_blacklist) {
            self.detectTransferRestriction_blacklist(from,to);
        } else if(operations.operate_whitelist) {
            self.detectTransferRestriction_whitelist(from,to);
        } else if (operations.operate_sanctionlist) {
            self.detectTransferRestriction_sanctionlist(from,to);
        }
    }

    #[aztec(internal)]
    fn detectTransferRestriction_blacklist(self: Self, from: AztecAddress, to:AztecAddress){
        assert(!self.map.at(from).get_current_value_in_private().get_is_blacklisted(), TEXT_ADDRESS_FROM_IS_BLACKLISTED);
        assert(!self.map.at(to).get_current_value_in_private().get_is_blacklisted(), TEXT_ADDRESS_TO_IS_BLACKLISTED);
    }

    #[aztec(internal)]
    fn detectTransferRestriction_whitelist(self: Self, from: AztecAddress, to:AztecAddress){
        assert(self.map.at(from).get_current_value_in_private().get_is_whitelisted(), TEXT_ADDRESS_FROM_NOT_WHITELISTED);
        assert(self.map.at(to).get_current_value_in_private().get_is_whitelisted(), TEXT_ADDRESS_TO_NOT_WHITELISTED);
    }

    #[aztec(internal)]
    fn detectTransferRestriction_sanctionlist(self: Self, from: AztecAddress, to:AztecAddress){
        assert(false, "not implemented.");
    }

}

impl UserFlagsTrait for UserFlags {
    fn get_is_blacklisted(self) -> bool {
        self.is_blacklisted
    }
    fn get_is_whitelisted(self) -> bool {
        self.is_whitelisted
    }
    fn get_is_in_sanction_list(self) -> bool {
        self.is_in_sanction_list
    }
}

impl FromField for UserFlags {
    fn from_field(value: Field) -> UserFlags {
        let value: u64 = value as u64;
        let is_blacklisted = (value & BLACKLIST_FLAG) == BLACKLIST_FLAG;
        let is_whitelisted = (value & WHITELIST_FLAG) == WHITELIST_FLAG;
        let is_in_sanction_list = (value & SANCTIONLIST_FLAG) == SANCTIONLIST_FLAG;

        Self { is_blacklisted, is_whitelisted, is_in_sanction_list }
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

        if self.is_in_sanction_list {
            value = value | SANCTIONLIST_FLAG;
        }

        value.to_field()
    }
}

impl Eq for UserFlags {
    fn eq(self, other: Self) -> bool {
        (self.is_blacklisted == other.is_blacklisted) & (self.is_whitelisted == other.is_whitelisted) & (self.is_in_sanction_list == other.is_in_sanction_list)
    }
}

// We implement this as it is used when serializing the state variable into return values
// This is very inefficient if used to store the state variable.
// We are currently "abusing" that the `to_field` is called in the `scheduled_value_change`
// where we are using this value.
impl Serialize<3> for UserFlags {
    fn serialize(self) -> [Field; 3] {
        [self.is_blacklisted.to_field(), self.is_whitelisted.to_field(), self.is_in_sanction_list.to_field()]
        // [self.to_field()]
    }
}

// We implement this as it is required for other contracts to be able to "rebuild" the variable
// after having received the serialized value as a return-value
impl Deserialize<3> for UserFlags {
    fn deserialize(fields: [Field; 3]) -> Self {
        Self {
            is_blacklisted: fields[0] as bool,
            is_whitelisted: fields[1] as bool,
            is_in_sanction_list: fields[2] as bool,
        }
    }
}


impl FromField for SetFlag {
    fn from_field(value: Field) -> SetFlag {
        let value: u64 = value as u64;
        let operate_blacklist = (value & BLACKLIST_FLAG) == BLACKLIST_FLAG;
        let operate_whitelist = (value & WHITELIST_FLAG) == WHITELIST_FLAG;
        let operate_sanctionlist = (value & SANCTIONLIST_FLAG) == SANCTIONLIST_FLAG;

        Self { operate_blacklist, operate_whitelist, operate_sanctionlist }
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

        if self.operate_sanctionlist {
            value = value | SANCTIONLIST_FLAG;
        }

        value.to_field()
    }
}

impl Eq for SetFlag {
    fn eq(self, other: Self) -> bool {
        (self.operate_blacklist == other.operate_blacklist) & (self.operate_whitelist == other.operate_whitelist) & (self.operate_sanctionlist == other.operate_sanctionlist)
    }
}

impl Serialize<3> for SetFlag {
    fn serialize(self) -> [Field; 3] {
        [self.operate_blacklist.to_field(), self.operate_whitelist.to_field(), self.operate_sanctionlist.to_field()]
    }
}

// We implement this as it is required for other contracts to be able to "rebuild" the variable
// after having received the serialized value as a return-value
impl Deserialize<3> for SetFlag {
    fn deserialize(fields: [Field; 3]) -> Self {
        Self {
            operate_blacklist: fields[0] as bool,
            operate_whitelist: fields[1] as bool,
            operate_sanctionlist: fields[2] as bool,
        }
    }
}