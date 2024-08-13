use dep::aztec::{prelude::{AztecAddress, SharedMutable, Map}, unencrypted_logs::unencrypted_event_emission,  context::PublicContext, context::PrivateContext};
use dep::aztec::protocol_types::traits::{FromField, ToField, Serialize, Deserialize};

global FREEZED_FLAG: u64 = 1;
global CHANGE_ROLES_DELAY_BLOCKS = 2;

struct FreezableFlag {
    is_freezed: bool,
}

trait FreezableFlagTrait {
    fn get_is_frozen(self) -> bool;
}

struct Freezable<T,Context>{
    map: Map<AztecAddress, SharedMutable<T, CHANGE_ROLES_DELAY_BLOCKS, Context>, Context>
}

impl<T,Context> Freezable<T,Context> where T: Eq + ToField + FromField + FreezableFlagTrait{

    pub fn new(context: Context, storage_slot: Field) -> Self {
        assert(storage_slot != 0, "Storage slot 0 not allowed. Storage slots must start from 1.");
        Self {
            map: Map::new(
                context,
                storage_slot,
                |context, slot| SharedMutable::new(context,slot)
            )
        }
    }
}

impl<T> Freezable<T, &mut PublicContext> where T: Eq + ToField + FromField + FreezableFlagTrait{

    pub fn is_frozen(self: Self, address: AztecAddress) -> pub bool{
        self.map.at(address).get_current_value_in_public().get_is_frozen()
    }

    /**
     * @dev Freezes an account. An account can be unfrozen
     *
     * Requirements:
     *
     * - The account must not be already frozen
     */
    pub fn freeze(self: Self, address: AztecAddress, val: T){
        self._require_not_freezed(address);
        self.map.at(address).schedule_value_change(val);
    }


    pub fn unfreeze(self: Self, address: AztecAddress, val: T){
        self._require_freezed(address);
        self.map.at(address).schedule_value_change(val);
    }

    #[aztec(internal)]
    fn _require_not_freezed(self: Self, address: AztecAddress) {
        assert(self.map.at(address).get_current_value_in_public().get_is_frozen() == false, "error: address already freezed");
    }

    #[aztec(internal)]
    fn _require_freezed(self: Self, address: AztecAddress) {
        assert(self.map.at(address).get_current_value_in_public().get_is_frozen() == true, "error: address already unfreezed");
    }

}

impl<T> Freezable<T,&mut PrivateContext> where T: Eq + ToField + FromField + FreezableFlagTrait{

    fn is_frozen(self: Self, user: AztecAddress) -> bool {
        let user_roles: T = self.map.at(user).get_current_value_in_private();
        user_roles.get_is_frozen()
    }

}

impl FreezableFlagTrait for FreezableFlag {
    fn get_is_frozen(self) -> bool {
        self.is_freezed
    }
}

impl FromField for FreezableFlag {
    fn from_field(value: Field) -> FreezableFlag {
        let value: u64 = value as u64;
        let is_freezed = (value & FREEZED_FLAG) == FREEZED_FLAG;

        Self {is_freezed }
    }
}

impl ToField for FreezableFlag {
    fn to_field(self) -> Field {
        let mut value: u64 = 0;

        if self.is_freezed {
            value = value | FREEZED_FLAG;
        }

        value.to_field()
    }
}

impl Eq for FreezableFlag {
    fn eq(self, other: Self) -> bool {
        self.is_freezed == other.is_freezed
    }
}

// We implement this as it is used when serializing the state variable into return values
// This is very inefficient if used to store the state variable.
// We are currently "abusing" that the `to_field` is called in the `scheduled_value_change`
// where we are using this value.
impl Serialize<1> for FreezableFlag {
    fn serialize(self) -> [Field; 1] {
        [self.is_freezed.to_field()]
    }
}

// We implement this as it is required for other contracts to be able to "rebuild" the variable
// after having received the serialized value as a return-value
impl Deserialize<1> for FreezableFlag {
    fn deserialize(fields: [Field; 1]) -> Self {
        Self {
            is_freezed: fields[0] as bool,
        }
    }
}

