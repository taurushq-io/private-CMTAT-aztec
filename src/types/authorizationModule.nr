use dep::aztec::protocol_types::traits::{FromField, ToField, Serialize, Deserialize};
use dep::aztec::prelude::{AztecAddress, PublicMutable, Map, PrivateSet};
use dep::aztec::context::{PublicContext, PrivateContext};


// Type alias for better readability
type Role = Field;

global DEFAULT_ADMIN_ROLE: Role = 0;

// Define the storage for role data
struct RoleData<Context> {
    has_role: Map<AztecAddress, PublicMutable<bool, Context>, Context>,
    admin_role: Role,
}

//Define the AccessControl storage
struct AccessControl<Context> {
    roles: Map<Role, RoleData<Context>, Context>,
}

impl<Context> AccessControl<Context> {

    pub fn new(context: Context, storage_slot: Field) -> Self {
        assert(storage_slot != 0, "Storage slot 0 not allowed. Storage slots must start from 1.");
        Self {
            roles: Map::new(
                context,
                storage_slot,
                |context,storage_slot| RoleData::new(context, storage_slot)
            )
        }
    }
    }


impl AccessControl<&mut PublicContext> {
    // Get role storage
    fn get_role_storage(self: Self, role: Role) -> RoleData<&mut PublicContext>{
        self.roles.at(role)
    }

    // Check if an account has a role
    pub fn has_role(self: Self, role: Role, account: AztecAddress) -> bool {
        let role_data = self.get_role_storage(role);
        role_data.has_role.at(account).read()
    }

    // Check role internally
    fn check_role(self: Self, role: Role, account: AztecAddress) {
        assert(!self.has_role(role, account),"AccessControlUnauthorizedAccount");
    }

    // Modifier to check role
    pub fn only_role(self: Self, role: Role, caller: AztecAddress) {
        self.check_role(role, caller);
    }

    // Grant a role to an account
    pub fn grant_role(&mut self, role: Role, account: AztecAddress) {
        let mut role_data = self.get_role_storage(role);
        role_data.has_role.at(account).write(true);
    }

    // Revoke a role from an account
    pub fn revoke_role(&mut self, role: Role, account: AztecAddress) {
        let mut role_data = self.get_role_storage(role);
        role_data.has_role.at(account).write(false);
    }
}

impl<Context> RoleData<Context> {
    pub fn new(context: Context, storage_slot: Field) -> Self {
        let has_role = Map::new(
                context,
                storage_slot,
                |context,storage_slot| PublicMutable::new(context, storage_slot)
            );
        let admin_role = DEFAULT_ADMIN_ROLE;
        Self { has_role: has_role, admin_role: admin_role }
    }
}
