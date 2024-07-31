    use dep::aztec::{prelude::{AztecAddress, PublicMutable, Map}, unencrypted_logs::unencrypted_event_emission,  context::PublicContext};
    use dep::aztec::protocol_types::traits::{FromField, ToField, Serialize, Deserialize};
    
    global FREEZED_FLAG: u64 = 1;

    struct Freezable<Context>{
        map: Map<AztecAddress, PublicMutable<bool, Context>, Context>
    }

//Note: pas le bon paradigm de faire ça je pense, il faut implémenter le PublicMutable au niveau du contrat et pas de la librairie
//reste a voir pq j'arrive pas a faire comme BalancesMap, qui utilise un PrivateSet dans la librairie
impl<Context> Freezable<Context>{

    pub fn new(context: Context, storage_slot: Field) -> Self {
        assert(storage_slot != 0, "Storage slot 0 not allowed. Storage slots must start from 1.");
        Self {
            map: Map::new(
                context,
                storage_slot,
                |context, slot| PublicMutable::new(context,slot)
            )
        }
    }
}

impl Freezable<&mut PublicContext> {

    pub fn is_freezed(self: Self, address: AztecAddress) -> bool{
        self.map.at(address).read()
    }

    /**
     * @dev Freezes an account. An account can be unfrozen
     *
     * Requirements:
     *
     * - The account must not be already frozen
     */
    pub fn freeze(&mut self, address: AztecAddress){
        self._require_not_freezed(address);
        self.map.at(address).write(true);
    }


    pub fn unfreeze(&mut self, address: AztecAddress){
        self._require_freezed(address);
        self.map.at(address).write(false);
    }

    #[aztec(internal)]
    fn _require_not_freezed(self: Self, address: AztecAddress) {
        assert(self.map.at(address).read() == false, "error: address already freezed");
    }

    #[aztec(internal)]
    fn _require_freezed(self: Self, address: AztecAddress) {
        assert(self.map.at(address).read() == true, "error: address already unfreezed");
    }

}

