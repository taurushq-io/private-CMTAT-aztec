use dep::aztec::protocol_types::traits::{FromField, ToField, Serialize, Deserialize, Packable};
use dep::aztec::{prelude::{AztecAddress, SharedMutable, Map},  state_vars::storage::Storage};
use dep::aztec::context::{PublicContext, PrivateContext};

use crate::types::access_controlModule::{AccessControlModule,VALIDATION_ROLE, ADDRESS_LIST_ADD_ROLE, ADDRESS_LIST_REMOVE_ROLE};

pub global BLACKLIST_FLAG: u64 = 1;
pub global WHITELIST_FLAG: u64 = 2;
pub global SANCTIONLIST_FLAG: u64 = 4;

pub global CHANGE_ROLES_DELAY_BLOCKS: u32 = 2;

global TEXT_ADDRESS_FROM_IS_BLACKLISTED: str<30> = "The sender is in the blacklist";
global TEXT_ADDRESS_TO_IS_BLACKLISTED: str<33> = "The recipient is in the blacklist";
global TEXT_ADDRESS_FROM_NOT_WHITELISTED: str<34> = "The sender is not in the whitelist";
global TEXT_ADDRESS_TO_NOT_WHITELISTED: str<37> = "The recipient is not in the whitelist";

#[derive(Deserialize, Packable, Eq, Serialize)]

pub struct SetFlag {
    operate_blacklist: bool,
    operate_whitelist: bool,
    operate_sanctionlist: bool,
}
#[derive(Deserialize, Eq, Serialize)]
pub struct UserFlags {
    is_blacklisted: bool,
    is_whitelisted: bool,
    is_in_sanction_list: bool,
}

trait UserFlagsTrait {
    fn get_is_blacklisted(self) -> bool;
    fn get_is_whitelisted(self) -> bool;
    fn get_is_in_sanction_list(self) -> bool;
}

pub struct ValidationModule<T,Context> {
    pub map: Map<AztecAddress, SharedMutable<T,CHANGE_ROLES_DELAY_BLOCKS ,Context>, Context>,
    pub operationsFlag: SharedMutable<SetFlag,CHANGE_ROLES_DELAY_BLOCKS, Context>
}

impl<T,Context> Storage<9> for ValidationModule<T,Context> {
        fn get_storage_slot(self) -> Field {
        // this returns the *first* slot; the framework will then reserve
        // one more slot (so slots N and N+1 in total)
        self.map.get_storage_slot()
        }
}

impl<T,Context> ValidationModule<T,Context> where T: Eq + ToField + FromField + UserFlagsTrait{
    pub fn new(context: Context, storage_slot: Field) -> Self {
        assert(storage_slot != 0, "Storage slot 0 not allowed. Storage slots must start from 1.");
        let map_slot = storage_slot;
        let ops_slot = storage_slot + 1;
        Self {
            map: Map::new(
                context,
                map_slot,
                |context, slot| SharedMutable::new(context, slot)
            ),
            operationsFlag: SharedMutable::new(context, ops_slot)
        }
    }
}

impl<T> ValidationModule<T, &mut PublicContext> where T: Eq + ToField + FromField + UserFlagsTrait + Packable<1>{
    pub fn get_operations(self: Self) -> Field {
        let operations = self.operationsFlag.get_current_value();
        operations.to_field()
    }

    pub fn set_operations(self: Self, caller: AztecAddress, operations: SetFlag, access_control: AccessControlModule<bool, &mut PublicContext>) {
        access_control.only_role(VALIDATION_ROLE, caller);
        self.operationsFlag.schedule_value_change(operations);
    }


    //problem: here the one that has the ADDRESS_LIST_ADD_ROLE can also remove from list by overwritting userFlag
    pub fn add_to_list(self:Self,  caller: AztecAddress, newListAddress: AztecAddress, userFlag: T, access_control: AccessControlModule<bool, &mut PublicContext>) {
        access_control.only_role(ADDRESS_LIST_ADD_ROLE, caller);
        self.map.at(newListAddress).schedule_value_change(userFlag);
    }

    pub fn remove_from_list(self:Self, caller: AztecAddress, removeListAddress: AztecAddress, userFlag: T, access_control: AccessControlModule<bool, &mut PublicContext>) {
        access_control.only_role(ADDRESS_LIST_REMOVE_ROLE, caller);
        self.map.at(removeListAddress).schedule_value_change(userFlag);
    }
}

impl<T> ValidationModule<T,&mut PrivateContext> where T: Eq + ToField + FromField + UserFlagsTrait + Packable<1>{


    pub fn operateOnTransfer(self: Self, from: AztecAddress, to:AztecAddress) {
        let operations = self.operationsFlag.get_current_value();

        if (operations.operate_blacklist) {
            self.detectTransferRestriction_blacklist(from,to);
        } else if(operations.operate_whitelist) {
            self.detectTransferRestriction_whitelist(from,to);
        } else if (operations.operate_sanctionlist) {
            self.detectTransferRestriction_sanctionlist(from,to);
        }
    }

    fn detectTransferRestriction_blacklist(self: Self, from: AztecAddress, to:AztecAddress){
        assert(!self.map.at(from).get_current_value().get_is_blacklisted(), TEXT_ADDRESS_FROM_IS_BLACKLISTED);
        assert(!self.map.at(to).get_current_value().get_is_blacklisted(), TEXT_ADDRESS_TO_IS_BLACKLISTED);
    }

    fn detectTransferRestriction_whitelist(self: Self, from: AztecAddress, to:AztecAddress){
        assert(self.map.at(from).get_current_value().get_is_whitelisted(), TEXT_ADDRESS_FROM_NOT_WHITELISTED);
        assert(self.map.at(to).get_current_value().get_is_whitelisted(), TEXT_ADDRESS_TO_NOT_WHITELISTED);
    }

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

impl Packable<1> for UserFlags {

    fn pack(self) -> [Field;1] {
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
        [value.to_field()]
    }

    fn unpack(fields: [Field;1]) -> Self {
        let value: u64 = fields[0] as u64;
        let is_blacklisted = (value & BLACKLIST_FLAG) == BLACKLIST_FLAG;
        let is_whitelisted = (value & WHITELIST_FLAG) == WHITELIST_FLAG;
        let is_in_sanction_list = (value & SANCTIONLIST_FLAG) == SANCTIONLIST_FLAG;

        Self { is_blacklisted, is_whitelisted, is_in_sanction_list }
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
