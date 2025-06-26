use dep::aztec::prelude::{AztecAddress, NoteGetterOptions, NoteViewerOptions, NoteInterface, PrivateSet, Map};
use dep::aztec::{
    context::{PrivateContext, UnconstrainedContext}, hash::pedersen_hash,
    protocol_types::constants::MAX_NOTE_HASH_READ_REQUESTS_PER_CALL,
    note::{note_getter::view_notes, note_getter_options::SortOrder, 
    note_header::NoteHeader, note_interface::NullifiableNote,
        utils::compute_note_hash_for_nullify,},
};
use dep::value_note::{balance_utils, utils, value_note::ValueNote};

pub struct BalancesMap< T, Context> {
    pub map: Map<AztecAddress, PrivateSet<ValueNote, Context>, Context>
}

impl<T, Context> BalancesMap<T, Context> {
    pub fn new(context: Context, storage_slot: Field) -> Self {
        assert(storage_slot != 0, "Storage slot 0 not allowed. Storage slots must start from 1.");
        Self {
            map: Map::new(
                context,
                storage_slot,
                |context, slot| PrivateSet::new(context, slot)
            )
        }
    }
}

impl<T> BalancesMap<T, UnconstrainedContext> {
    unconstrained pub fn balance_of(
        self: Self,
        owner: AztecAddress
    ) -> Field {
        let balance_set = self.map.at(owner);
        balance_utils::get_balance(balance_set)
    }

}

impl<T> BalancesMap<T, &mut PrivateContext> {
    pub fn add<T_SERIALIZED_LEN, T_SERIALIZED_BYTES_LEN>(
        self: Self,
        owner: AztecAddress,
        amount: Field
    )  where T: NullifiableNote {
    }

    pub fn sub<T_SERIALIZED_LEN, T_SERIALIZED_BYTES_LEN>(
        self: Self,
        owner: AztecAddress,
        amount: Field
    )  {
        let balance_set = self.map.at(owner);
        utils::decrement(balance_set, amount, owner, owner, owner)
    }


}
