//! H-10, route A: every mint and burn delivers a constrained `Transfer` event to the issuer, the
//! on-chain record a stock PXE can process (the offchain note copies, it cannot: it does not own
//! the notes). The TXE cannot read a private event's content (`discover_event` is `pub(crate)`),
//! so these tests count what the event leaves in the transaction: one private log (the encrypted,
//! tagged event) and two nullifiers (the event commitment and the constrained delivery's sequence
//! nullifier). Each operation is run twice and the second transaction is measured, because the
//! first contact between two parties also creates the handshakes that tagging needs (extra notes,
//! logs and nullifiers of the registry) and would make the counts depend on delivery order.
//! Measured with the event removed, a warm mint leaves 1 note, 1 log and 2 nullifiers; with it,
//! 1 note, 2 logs and 4 nullifiers. Remove an `emit` and its test fails.
use crate::utils;
use aztec::test::helpers::txe_oracles::get_last_tx_effects;
use cmtat_aztec::CMTATAztec as Token;
use cmtat_aztec_lib::modules::access_controlModule::{BURNER_ROLE, MINTER_ROLE};

#[test]
unconstrained fn a_mint_leaves_the_issuer_one_event_log_and_its_two_nullifiers() {
    let (env, token, issuer, user) = utils::setup(false);
    env.call_public(issuer, Token::at(token).grant_role(MINTER_ROLE, issuer));
    env.call_private(issuer, Token::at(token).mint_to_private(user, 1_000)); // warm-up: handshakes
    env.call_private(issuer, Token::at(token).mint_to_private(user, 1_000));
    let effects = get_last_tx_effects();
    assert_eq(effects.note_hashes.len(), 1, "one note: the recipient's");
    assert_eq(effects.private_logs.len(), 2, "the note and the issuer's event");
    assert_eq(
        effects.nullifiers.len(),
        4,
        "two without the event, plus its commitment and its delivery sequence",
    );
}

#[test]
unconstrained fn a_batch_mint_leaves_one_event_per_recipient() {
    let (env, token, issuer, user) = utils::setup(false);
    env.call_public(issuer, Token::at(token).grant_role(MINTER_ROLE, issuer));
    env.call_private(issuer, Token::at(token).mint_batch([user, user, user, user], [1, 2, 3, 4]));
    env.call_private(issuer, Token::at(token).mint_batch([user, user, user, user], [1, 2, 3, 4]));
    let effects = get_last_tx_effects();
    assert_eq(effects.note_hashes.len(), 4, "four notes");
    assert_eq(effects.private_logs.len(), 8, "four notes and four issuer events");
}

#[test]
unconstrained fn a_burn_leaves_the_issuer_one_event_log_and_its_two_nullifiers() {
    let (env, token, issuer, _, _) = utils::setup_and_mint(false); // the issuer holds the minted notes
    env.call_public(issuer, Token::at(token).grant_role(BURNER_ROLE, issuer));
    env.call_private(issuer, Token::at(token).burn(issuer, 100, 0)); // warm-up
    env.call_private(issuer, Token::at(token).burn(issuer, 100, 0));
    let effects = get_last_tx_effects();
    assert_eq(effects.note_hashes.len(), 1, "the change note");
    assert_eq(effects.private_logs.len(), 2, "the change note and the issuer's event");
}

#[test]
unconstrained fn a_batch_burn_leaves_one_event_for_the_total() {
    let (env, token, issuer, _, _) = utils::setup_and_mint(false); // the issuer holds the minted notes
    env.call_public(issuer, Token::at(token).grant_role(BURNER_ROLE, issuer));
    env.call_private(issuer, Token::at(token).burn_batch(issuer, [1, 2, 3, 4], 0)); // warm-up
    env.call_private(issuer, Token::at(token).burn_batch(issuer, [1, 2, 3, 4], 0));
    let effects = get_last_tx_effects();
    // Four debits of the same account inside one call: the intermediate change notes are spent in
    // the same transaction and squashed, one change note remains; each debit still delivered its
    // change message. Four change-note logs and one event.
    assert_eq(effects.note_hashes.len(), 1, "one change note survives the squash");
    assert_eq(effects.private_logs.len(), 5, "four change-note logs and one issuer event");
}
