use dep::aztec::protocol_types::traits::{FromField, ToField, Serialize, Deserialize};
use dep::aztec::prelude::{AztecAddress, SharedMutable, Map, PrivateSet};
use dep::aztec::context::{PublicContext, PrivateContext};

global ADMIN_FLAG: u64 = 1;
global MINTER_FLAG: u64 = 2;
global BLACKLIST_FLAG: u64 = 4;

global CHANGE_ROLES_DELAY_BLOCKS = 2;

struct UserFlags {
    is_admin: bool,
    is_issuer: bool,
    is_blacklisted: bool,
}

trait UserFlagsTrait {
    fn get_admin(self) -> bool;
    fn get_issuer(self) -> bool;
    fn get_blacklisted(self) -> bool;
}

struct Rules<T,Context> {
    map: Map<AztecAddress, SharedMutable<T,CHANGE_ROLES_DELAY_BLOCKS ,Context>, Context>
}

impl<T,Context> Rules<T,Context> where T: Eq + ToField + FromField + UserFlagsTrait{
    pub fn new(context: Context, storage_slot: Field) -> Self {
        assert(storage_slot != 0, "Storage slot 0 not allowed. Storage slots must start from 1.");
        Self {
            map: Map::new(
                context,
                storage_slot,
                |context, slot| SharedMutable::new(context, slot)
            )
        }
    }
}

impl<T> Rules<T, &mut PublicContext> where T: Eq + ToField + FromField + UserFlagsTrait{
    fn get_roles(self: Self, user: AztecAddress) -> pub Field {
        let user_roles: T = self.map.at(user).get_current_value_in_public();
        user_roles.to_field()
    }

    fn grant_roles(self: Self, sender: AztecAddress, user: AztecAddress, authorizationModule: T) {
        let caller_roles: T = self.map.at(sender).get_current_value_in_public();
        assert(caller_roles.get_admin(), "caller is not admin");
        self.map.at(user).schedule_value_change(authorizationModule);
    }
}

impl<T> Rules<T,&mut PrivateContext> where T: Eq + ToField + FromField + UserFlagsTrait{

    fn is_blacklisted(self: Self, user: AztecAddress) -> bool {
        let user_roles: T = self.map.at(user).get_current_value_in_private();
        user_roles.get_blacklisted()
    }

    fn is_issuer(self: Self, user: AztecAddress) -> bool {
        let user_roles: T = self.map.at(user).get_current_value_in_private();
        user_roles.get_issuer()
    }
}

impl UserFlagsTrait for UserFlags {
    fn get_admin(self) -> bool {
        self.is_admin
    }
    fn get_issuer(self) -> bool {
        self.is_issuer
    }
    fn get_blacklisted(self) -> bool {
        self.is_blacklisted
    }
}

impl FromField for UserFlags {
    fn from_field(value: Field) -> UserFlags {
        let value: u64 = value as u64;
        let is_admin = (value & ADMIN_FLAG) == ADMIN_FLAG;
        let is_issuer = (value & MINTER_FLAG) == MINTER_FLAG;
        let is_blacklisted = (value & BLACKLIST_FLAG) == BLACKLIST_FLAG;

        Self { is_admin, is_issuer, is_blacklisted }
    }
}

impl ToField for UserFlags {
    fn to_field(self) -> Field {
        let mut value: u64 = 0;

        if self.is_admin {
            value = value | ADMIN_FLAG;
        }

        if self.is_issuer {
            value = value | MINTER_FLAG;
        }

        if self.is_blacklisted {
            value = value | BLACKLIST_FLAG;
        }

        value.to_field()
    }
}

impl Eq for UserFlags {
    fn eq(self, other: Self) -> bool {
        (self.is_admin == other.is_admin) & (self.is_issuer == other.is_issuer) & (self.is_blacklisted == other.is_blacklisted)
    }
}

// We implement this as it is used when serializing the state variable into return values
// This is very inefficient if used to store the state variable.
// We are currently "abusing" that the `to_field` is called in the `scheduled_value_change`
// where we are using this value.
impl Serialize<3> for UserFlags {
    fn serialize(self) -> [Field; 3] {
        [self.is_admin.to_field(), self.is_issuer.to_field(), self.is_blacklisted.to_field()]
        // [self.to_field()]
    }
}

// We implement this as it is required for other contracts to be able to "rebuild" the variable
// after having received the serialized value as a return-value
impl Deserialize<3> for UserFlags {
    fn deserialize(fields: [Field; 3]) -> Self {
        Self {
            is_admin: fields[0] as bool,
            is_issuer: fields[1] as bool,
            is_blacklisted: fields[2] as bool,
        }
    }
}