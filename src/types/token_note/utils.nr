use dep::aztec::{
    messages::logs::note::encode_and_encrypt_note,
    note::{note_getter_options::SortOrder, note_interface::NoteProperties},
    prelude::{AztecAddress, NoteGetterOptions, PrivateContext, PrivateSet},
    protocol_types::traits::Packable,
};

use dep::value_note::{filter::filter_notes_min_sum, value_note::ValueNote};

// Similar to Aztec docs but emits a log with the note encrypted for both the recipient and issuer.


// Sort the note values (0th field) in descending order.
// Pick the fewest notes whose sum is equal to or greater than `amount`.
pub fn create_note_getter_options_for_decreasing_balance<let N: u32>(
    amount: Field,
) -> NoteGetterOptions<ValueNote, N, Field, Field> where ValueNote: Packable<N>, {
    NoteGetterOptions::with_filter(filter_notes_min_sum, amount).sort(
        ValueNote::properties().value,
        SortOrder.DESC
    )
}

// Creates a new note for the recipient.
// Inserts it to the recipient's set of notes.
pub fn increment(
    balance: PrivateSet<ValueNote, &mut PrivateContext>,
    amount: Field,
    recipient: AztecAddress,
    issuer: AztecAddress,
    sender: AztecAddress
) {
    let mut note = ValueNote::new(amount, recipient);
    // Insert the new note to the owner's set of notes and emit the log if value is non-zero.
    let note_insert = balance.insert(note);
    
    note_insert.emit(encode_and_encrypt_note(
        balance.context,
        recipient,
        sender));
    note_insert.emit(encode_and_encrypt_note(
        balance.context,
        issuer,
        sender));

}

// Find some of the `owner`'s notes whose values add up to the `amount`.
// Remove those notes.
// If the value of the removed notes exceeds the requested `amount`, create a new note containing the excess value, so that exactly `amount` is removed.
// Fail if the sum of the selected notes is less than the amount.
pub fn decrement(
    balance: PrivateSet<ValueNote, &mut PrivateContext>,
    amount: Field,
    owner: AztecAddress,
    outgoing_viewer: AztecAddress,
    sender: AztecAddress,
) {
    let sum = decrement_by_at_most(balance, amount, owner, outgoing_viewer, sender);
    assert(sum == amount, "Balance too low");
}

// Similar to `decrement`, except that it doesn't fail if the decremented amount is less than max_amount.
// The motivation behind this function is that there is an upper-bound on the number of notes a function may
// read and nullify. The requested decrementation `amount` might be spread across too many of the `owner`'s
// notes to 'fit' within this upper-bound, so we might have to remove an amount less than `amount`. A common
// pattern is to repeatedly call this function across many function calls, until enough notes have been nullified to
// equal `amount`.
//
// It returns the decremented amount, which should be less than or equal to max_amount.
pub fn decrement_by_at_most(
    balance: PrivateSet<ValueNote, &mut PrivateContext>,
    max_amount: Field,
    owner: AztecAddress,
    outgoing_viewer: AztecAddress,
    sender: AztecAddress,
) -> Field {
    let options = create_note_getter_options_for_decreasing_balance(max_amount);
    let notes = balance.pop_notes(options);

    let mut decremented = 0;
    for i in 0..options.limit {
        if i < notes.len() {
            let note = notes.get_unchecked(i);
            decremented += note.value;
        }
    }

    // Add the change value back to the owner's balance.
    let mut change_value = 0;
    if max_amount.lt(decremented) {
        change_value = decremented - max_amount;
        decremented -= change_value;
    }
    increment(balance, change_value, owner, outgoing_viewer, sender);

    decremented
}