use dep::aztec::{prelude::{AztecAddress, PublicMutable},  context::PublicContext, state_vars::storage::Storage};
use crate::modules::access_controlModule::{AccessControlModule, PAUSE_ROLE};

pub global PAUSED_FLAG: u64 = 1;
pub global T_SERIALIZED_LEN: u32 = 1;

    pub struct PauseModule<Context>{
        pub is_paused: PublicMutable<bool, Context>,
    }

// TODO(#13824): remove this impl once we allow structs to hold state variables.
impl<Context> Storage<1> for PauseModule<Context> {
        fn get_storage_slot(self) -> Field {
            self.is_paused.get_storage_slot()
        }
}

impl<Context> PauseModule<Context> {

    pub fn new(context: Context, storage_slot: Field) -> Self {
        assert(storage_slot != 0, "Storage slot 0 not allowed. Storage slots must start from 1.");
        Self {
            is_paused: PublicMutable::new(context,storage_slot),            
        }
    }

}

impl PauseModule<&mut PublicContext>  {


    pub fn is_paused(self: Self) -> bool{
        let val = self.is_paused.read();
        val
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    pub fn pause(self: Self, caller: AztecAddress, ac: AccessControlModule<bool, &mut  PublicContext>){
        ac.only_role(PAUSE_ROLE, caller);
        self._require_not_paused();
        let mut val = self.is_paused.read();
        val = true;
        self.is_paused.write(val);
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    pub fn unpause(self: Self, caller: AztecAddress, ac: AccessControlModule<bool, &mut  PublicContext>){
        ac.only_role(PAUSE_ROLE, caller);
        self._require_paused();
        let mut val = self.is_paused.read();
        val = false;
        self.is_paused.write(val); 
    }

    #[aztec(internal)]
    fn _require_not_paused(self: Self) {
        assert(self.is_paused.read() == false, "error: contract already paused");
    }

    #[aztec(internal)]
    fn _require_paused(self: Self) {
        assert(self.is_paused.read() == true, "error: contract already unpaused");
    }

}


