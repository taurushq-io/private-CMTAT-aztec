use dep::aztec::protocol_types::traits::{FromField, ToField, Serialize, Deserialize};
use dep::aztec::prelude::{AztecAddress, PublicMutable, Map, PrivateSet};
use dep::aztec::context::{PublicContext, PrivateContext};


// Type alias for better readability
type Role = Field;

global DEFAULT_ADMIN_ROLE = 1;
global PAUSE_ROLE = 2;
global ENFORCEMENT_ROLE =  3;
global VALIDATION_ROLE = 4;
global ADDRESS_LIST_ADD_ROLE = 5;
global ADDRESS_LIST_REMOVE_ROLE = 6;
global MINTER_ROLE = 7;
global BURNER_ROLE = 8;


// Define the storage for role data
struct RoleData<Context> {
    has_role: Map<AztecAddress, PublicMutable<bool, Context>, Context>,
    admin_role: Role,
}

//Define the AccessControl storage
struct AccessControl<T,Context> {
    roles: Map<Role, RoleData<Context>, Context>,
}

impl<T,Context> AccessControl<T,Context> {

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


impl<T> AccessControl<T, &mut PublicContext> {
    // Get role storage
    #[aztec(internal)]
    fn get_role_storage(self: Self, role: Role) -> RoleData<&mut PublicContext>{
        self.roles.at(role)
    }

    // Check if an account has a role
    fn has_role(self: Self, role: Role, account: AztecAddress) -> bool {
        let role_data = self.get_role_storage(role);
        role_data.has_role.at(account).read()
    }

    // Check role internally
    #[aztec(internal)]
    fn check_role(self: Self, role: Role, account: AztecAddress) {
        assert(self.has_role(role, account),"AccessControlUnauthorizedAccount");
    }

    // Modifier to check role
    fn only_role(self: Self, role: Role, caller: AztecAddress) {
        self.check_role(role, caller);
    }

    fn getRoleAdmin(self: Self, role: Role) -> Role {
        self.roles.at(role).admin_role
    }

    fn renounce_role(self:Self, role: Field, caller: AztecAddress, callerConfirmation: AztecAddress) {
        assert(caller == callerConfirmation, "Renounce Role: Addresses do not match");
        self._revoke_role(role, callerConfirmation)   
    }

    // Grant a role to an account
    fn grant_role( self: Self, role: Role, account: AztecAddress) {
        self.only_role(self.getRoleAdmin(role), account);
        self._grant_role(role,account);
    }

    // Revoke a role from an account
    fn revoke_role(self:Self, role: Role, account: AztecAddress) {
        self.only_role(self.getRoleAdmin(role), account);
        self._revoke_role(role,account);
    }

    fn _grant_role( self:Self, role: Role, account: AztecAddress) {
        let mut role_data = self.get_role_storage(role);
        role_data.has_role.at(account).write(true);
    }

    fn _revoke_role(self:Self, role: Role, account: AztecAddress) {
        let mut role_data = self.get_role_storage(role);
        role_data.has_role.at(account).write(false);
    }  
}

impl<Context> RoleData<Context> {
    pub fn new(context: Context, storage_slot: Field) -> Self {
        assert(storage_slot != 0, "Storage slot 0 not allowed. Storage slots must start from 1.");

        let has_role = Map::new(
                context,
                storage_slot,
                |context,storage_slot| PublicMutable::new(context, storage_slot)
            );
        let admin_role = DEFAULT_ADMIN_ROLE;
        Self { has_role: has_role, admin_role: admin_role }
    }
}
