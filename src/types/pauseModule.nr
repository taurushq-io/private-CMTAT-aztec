use dep::aztec::{prelude::{AztecAddress, PublicMutable},  context::PublicContext};
use dep::aztec::protocol_types::traits::{FromField, ToField, Serialize, Deserialize};
use crate::types::access_controlModule::{AccessControlModule, PAUSE_ROLE};

pub global PAUSED_FLAG: u64 = 1;
pub global T_SERIALIZED_LEN: u32 = 1;

    trait BoolEmulTrait {
        pub fn get_pause(self) -> bool;
        pub fn set_pause(&mut self, arg: bool);
    }

    pub struct BoolEmul {
        is_paused: bool,
    }

    pub struct PauseModule<T,Context>{
        pub is_paused: PublicMutable<T, Context>,
    }

impl<T,Context> PauseModule<T,Context> where T: Eq + Serialize<T_SERIALIZED_LEN> + Deserialize<T_SERIALIZED_LEN> + ToField + FromField + BoolEmulTrait{

    pub fn new(context: Context, storage_slot: Field) -> Self {
        assert(storage_slot != 0, "Storage slot 0 not allowed. Storage slots must start from 1.");
        Self {
            is_paused: PublicMutable::new(context,storage_slot),            
        }
    }

}

impl<T> PauseModule<T,&mut PublicContext> where T: Eq + Serialize<T_SERIALIZED_LEN> + Deserialize<T_SERIALIZED_LEN> + ToField + FromField + BoolEmulTrait{


    pub fn is_paused(self: Self) -> bool{
        let val: T = self.is_paused.read();
        val.get_pause()
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
        let mut val: T = self.is_paused.read();
        val.set_pause(true);
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
        let mut val: T = self.is_paused.read();
        val.set_pause(false);
        self.is_paused.write(val); 
    }

    #[aztec(internal)]
    fn _require_not_paused(self: Self) {
        assert(self.is_paused.read().get_pause() == false, "error: contract already paused");
    }

    #[aztec(internal)]
    fn _require_paused(self: Self) {
        assert(self.is_paused.read().get_pause() == true, "error: contract already unpaused");
    }

}

impl BoolEmulTrait for BoolEmul {
    fn get_pause(self) -> bool{
        self.is_paused
    }

    fn set_pause(&mut self, arg: bool) {
        self.is_paused = arg;
    }
}
impl FromField for BoolEmul {
    fn from_field(value: Field) -> BoolEmul {
        let value: u64 = value as u64;
        let is_paused = (value & PAUSED_FLAG) == PAUSED_FLAG;
        Self { is_paused }
    }
}

impl ToField for BoolEmul {
    fn to_field(self) -> Field {
        let mut value: u64 = 0;

        if self.is_paused {
            value = value | PAUSED_FLAG;
        }
        value.to_field()
    }
}

impl Eq for BoolEmul {
    fn eq(self, other: Self) -> bool {
        (self.is_paused == other.is_paused) 
    }
}

// We implement this as it is used when serializing the state variable into return values
// This is very inefficient if used to store the state variable.
// We are currently "abusing" that the `to_field` is called in the `scheduled_value_change`
// where we are using this value.
impl Serialize<T_SERIALIZED_LEN> for BoolEmul {
    fn serialize(self) -> [Field; T_SERIALIZED_LEN] {
        [self.is_paused.to_field()]
    }
}

// We implement this as it is required for other contracts to be able to "rebuild" the variable
// after having received the serialized value as a return-value
impl Deserialize<T_SERIALIZED_LEN> for BoolEmul {
    fn deserialize(fields: [Field; T_SERIALIZED_LEN]) -> Self {
        Self {
            is_paused: fields[0] as bool,
        }
    }
}

