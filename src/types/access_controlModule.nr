use dep::aztec::{prelude::{AztecAddress, PublicMutable, Map}, state_vars::storage::Storage};
use dep::aztec::context::{PublicContext};


// Type alias for better readability
pub type Role = Field;

pub global DEFAULT_ADMIN_ROLE: Field = 1;
pub global PAUSE_ROLE: Field = 2;
pub global ENFORCEMENT_ROLE: Field =  3;
pub global VALIDATION_ROLE: Field = 4;
pub global ADDRESS_LIST_ADD_ROLE: Field = 5;
pub global ADDRESS_LIST_REMOVE_ROLE: Field = 6;
pub global MINTER_ROLE: Field = 7;
pub global BURNER_ROLE: Field = 8;
pub global DEBT_ROLE: Field = 9;
pub global DEBT_CREDIT_EVENT_ROLE: Field = 10;


// Define the storage for role data
pub struct RoleData<Context> {
    pub has_role: Map<AztecAddress, PublicMutable<bool, Context>, Context>,
}

impl<Context> Storage<1> for RoleData<Context> {
        fn get_storage_slot(self) -> Field {
            self.has_role.get_storage_slot()
        }
}

//Define the AccessControl storage
pub struct AccessControlModule<T,Context> {
    pub roles: Map<Role, RoleData<Context>, Context>,
}

impl<T,Context> Storage<1> for AccessControlModule<T,Context> {
        fn get_storage_slot(self) -> Field {
            self.roles.get_storage_slot()
        }
}

impl<T,Context> AccessControlModule<T,Context> {

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


impl<T> AccessControlModule<T, &mut PublicContext> {
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
        assert(self.has_role(role, account),"AccessControlUnauthorizedAccount");
    }

    // Modifier to check role
    pub fn only_role(self: Self, role: Role, caller: AztecAddress) {
        self.check_role(role, caller);
    }

    pub fn getRoleAdmin(self: Self, role: Role) -> Role {
        let mut role_nb: Role = 0;
        if role == DEFAULT_ADMIN_ROLE {
            role_nb = DEFAULT_ADMIN_ROLE;
        } else if role == PAUSE_ROLE {
            role_nb = PAUSE_ROLE;
        } else if role == ENFORCEMENT_ROLE {
            role_nb =  ENFORCEMENT_ROLE;
        } else if role == VALIDATION_ROLE {
            role_nb = VALIDATION_ROLE;
        } else if role == ADDRESS_LIST_ADD_ROLE {
            role_nb = ADDRESS_LIST_ADD_ROLE;
        } else if role == ADDRESS_LIST_REMOVE_ROLE {
            role_nb = ADDRESS_LIST_REMOVE_ROLE;
        } else if role == MINTER_ROLE {
            role_nb = MINTER_ROLE;
        } else if role == BURNER_ROLE {
            role_nb = BURNER_ROLE;
        } else if role == DEBT_ROLE {
            role_nb = DEBT_ROLE;
        } else if role == DEBT_CREDIT_EVENT_ROLE {
            role_nb = DEBT_CREDIT_EVENT_ROLE;
        } else {
            assert(false, "AccessControlInvalidRole");
            role_nb = 0; 
        }
        role_nb
    }

    // renounce ownership of a role
    // This is a public function because it can be called by the user
    // @dev: 
    pub fn renounce_role(self:Self, role: Field, caller: AztecAddress, callerConfirmation: AztecAddress) {
        assert(caller == callerConfirmation, "Renounce Role: Addresses do not match");
        self._revoke_role(role, callerConfirmation)   
    }

    // Grant a role to an account
    /* TODO: this is absolutely not secure, as it allows anyone to grant roles to anyone else. But 
    for now, we keep it like this as idk how to properly set storage slots for roles.
    */
    pub fn grant_role( self: Self, role: Role, account: AztecAddress) {
        self.only_role(self.getRoleAdmin(role), account);
        self._grant_role(role,account);
    }

    // Revoke a role from an account
    pub fn revoke_role(self:Self, role: Role, account: AztecAddress) {
        self.only_role(self.getRoleAdmin(role), account);
        self._revoke_role(role,account);
    }

    //this is made public so that the constructor can call it. 
    //TODO: see how to make otherwise
    pub fn _grant_role( self:Self, role: Role, account: AztecAddress) {
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
        Self { has_role: has_role}
    }
}
