    use dep::aztec::{prelude::{AztecAddress}, unencrypted_logs::unencrypted_event_emission,  context::PublicContext};
    use dep::aztec::protocol_types::traits::{FromField, ToField, Serialize, Deserialize};
    
    global PAUSED_FLAG: u64 = 1;

    struct Pausable{
        is_paused: bool,
    }

//TODO: is it okay to not have a context? SHouldn't we do a PublicContext implementation?
impl Pausable{

    pub fn new() -> Self {
        Self{
            is_paused: false,
        }
    }

    pub fn is_paused(self: Self) -> bool{
        self.is_paused
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    pub fn pause(&mut self){
        self._require_not_paused();
        self.is_paused = true;
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    pub fn unpause(&mut self){
        self._require_paused();
        self.is_paused = false; 
    }

    #[aztec(internal)]
    fn _require_not_paused(self: Self) {
        assert(self.is_paused == false, "error: contract already paused");
    }

    #[aztec(internal)]
    fn _require_paused(self: Self) {
        assert(self.is_paused == true, "error: contract already unpaused");
    }

}

impl FromField for Pausable {
    fn from_field(value: Field) -> Pausable {
        let value: u64 = value as u64;
        let is_paused = ((value & PAUSED_FLAG) == PAUSED_FLAG);

        Self { is_paused }
    }
}

impl ToField for Pausable {
    fn to_field(self) -> Field {
        let mut value: u64 = 0;

        if self.is_paused {
            value = value | PAUSED_FLAG;
        }

        value.to_field()
    }
}

impl Eq for Pausable {
    fn eq(self, other: Self) -> bool {
        (self.is_paused == other.is_paused)
    }
}

impl Serialize<1> for Pausable {
    fn serialize(self) -> [Field; 1] {
        [self.is_paused.to_field()]
        // [self.to_field()]
    }
}


impl Deserialize<1> for Pausable {
    fn deserialize(fields: [Field; 1]) -> Self {
        Self {
            is_paused: fields[0] as bool,
        }
    }
}