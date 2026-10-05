//! Two whole-token invariants, each raised as a gap by the 0.4.0 security review.
//!
//! `INV-3` — supply equals the sum of every balance. Individual bridge tests in `test_hybrid.nr`
//! already assert `total_supply` is unchanged by a single bridge call; what had no test was the
//! invariant itself, over several holders and a mixed sequence that moves value privately, out to
//! the public side, back again, and through a mint and a burn.
//!
//! `F-1` — the `Transfer` event stream is the issuer's ledger, and a commitment completion is not in
//! it. The TXE cannot read a private event's content (`discover_event` is `pub(crate)`, see
//! `test_issuer_records.nr`), so a balance-level replay is not expressible here; what is expressible
//! is the absence itself, by counting the private logs a payment leaves. That is the machine check
//! the review asked for: the numbers below fail if a `Transfer` is ever added to, or removed from,
//! either path.
use crate::utils;
use aztec::test::helpers::txe_oracles::get_last_tx_effects;
use cmtat_aztec::CMTATAztec as Token;
use cmtat_aztec_lib::modules::access_controlModule::{BURNER_ROLE, MINTER_ROLE};

global MINT: u128 = 10_000;

// --- INV-3: total_supply == the sum of every private and public balance -------------------------

/// A mixed sequence across four holders and both sides of the token, then the invariant.
/// Every operation that moves supply is here: a mint, a burn, a private transfer, and both bridges.
#[test]
unconstrained fn supply_equals_the_sum_of_every_balance_after_a_mixed_sequence() {
    let (env, token, issuer, user1, user2, user3) = utils::setup_and_more_addresses_with_public_side(false, /* public_side_enabled */ true);
    env.call_public(issuer, Token::at(token).grant_role(MINTER_ROLE, issuer));
    env.call_public(issuer, Token::at(token).grant_role(BURNER_ROLE, issuer));

    // Supply in: two mints, to two different holders.
    env.call_private(issuer, Token::at(token).mint_to_private(issuer, MINT));
    env.call_private(issuer, Token::at(token).mint_to_private(user1, 2_500));

    // Private movement.
    env.call_private(issuer, Token::at(token).transfer_private_to_private(issuer, user2, 1_500, 0));

    // Out to the public side, and part of it back to a third holder's private balance.
    env.call_private(issuer, Token::at(token).transfer_private_to_public(issuer, user2, 2_000, 0));
    env.call_private(user2, Token::at(token).transfer_public_to_private(user2, user3, 750, 0));

    // Supply out.
    env.call_private(issuer, Token::at(token).burn(issuer, 1_000, 0));

    let expected_supply = MINT + 2_500 - 1_000;
    assert_eq(
        env.view_public(Token::at(token).total_supply()),
        expected_supply,
        "the mints less the burn",
    );

    let private_total = env.execute_utility(Token::at(token).balance_of_private(issuer))
        + env.execute_utility(Token::at(token).balance_of_private(user1))
        + env.execute_utility(Token::at(token).balance_of_private(user2))
        + env.execute_utility(Token::at(token).balance_of_private(user3));
    let public_total = env.view_public(Token::at(token).balance_of_public(issuer))
        + env.view_public(Token::at(token).balance_of_public(user1))
        + env.view_public(Token::at(token).balance_of_public(user2))
        + env.view_public(Token::at(token).balance_of_public(user3));

    // INV-3. A bridge that credited without debiting, or a mint that missed the supply update,
    // breaks this and nothing else in the suite would notice.
    assert_eq(
        private_total + public_total,
        expected_supply,
        "every token is in exactly one balance, private or public",
    );
}

// --- F-1: the Transfer stream does not cover a commitment completion ---------------------------

/// A warm `transfer_private_to_private` leaves the recipient's note, the change note, and the
/// `Transfer` event delivered constrained to both the recipient and the issuer.
#[test]
unconstrained fn a_private_transfer_leaves_a_transfer_event_in_the_stream() {
    let (env, token, issuer, user) = utils::setup_with_public_side(false, true);
    env.call_public(issuer, Token::at(token).grant_role(MINTER_ROLE, issuer));
    env.call_private(issuer, Token::at(token).mint_to_private(issuer, MINT));
    // Warm-up: the first contact between two parties also creates the tagging handshakes, which
    // would otherwise be counted here (see `test_issuer_records.nr`).
    env.call_private(issuer, Token::at(token).transfer_private_to_private(issuer, user, 100, 0));
    env.call_private(issuer, Token::at(token).transfer_private_to_private(issuer, user, 100, 0));
    let effects = get_last_tx_effects();
    assert_eq(effects.note_hashes.len(), 2, "the recipient's note and the change note");
    // Measured. Four logs: one per note, plus the `Transfer` event delivered constrained TWICE -
    // once to the recipient (the receipt naming the sender) and once to the issuer (the ledger).
    assert_eq(effects.private_logs.len(), 4, "two notes and the event's two deliveries");
    assert_eq(effects.nullifiers.len(), 7, "the spent note, the event and its delivery sequences");
}

/// The same value moved through a commitment. The recipient's credit arrives as a completion of the
/// partial note, and **no `Transfer` event is emitted at all** — `pay_commitment` cannot name the
/// recipient, because at completion the contract holds only the commitment.
#[test]
unconstrained fn a_commitment_payment_leaves_no_transfer_event_in_the_stream() {
    let (env, token, issuer, user) = utils::setup_with_public_side(false, true);
    env.call_public(issuer, Token::at(token).grant_role(MINTER_ROLE, issuer));
    env.call_private(issuer, Token::at(token).mint_to_private(issuer, MINT));

    // Warm-up on a first commitment, so the handshakes are not in the measured transaction. Each
    // commitment is payable exactly once, so the measured run needs its own.
    let warm = env.call_private(user, Token::at(token).initialize_transfer_commitment(user, issuer));
    env.mine_block();
    env.call_private(issuer, Token::at(token).transfer_private_to_commitment(issuer, warm, 100, 0));

    let commitment =
        env.call_private(user, Token::at(token).initialize_transfer_commitment(user, issuer));
    env.mine_block();
    env.call_private(
        issuer,
        Token::at(token).transfer_private_to_commitment(issuer, commitment, 100, 0),
    );
    let effects = get_last_tx_effects();
    // The same two notes a private transfer creates: the payer's change and the recipient's credit,
    // here as the completion of the partial note.
    assert_eq(effects.note_hashes.len(), 2, "the change note and the completion");
    // F-1, pinned. Two logs, one per note, and NOT ONE MORE. A private transfer of the same value
    // leaves four: the two notes plus the `Transfer` event's two constrained deliveries. Those two
    // are exactly what is missing here, so the issuer's event stream does not record this movement
    // and a balance reconstruction that replays `Transfer` alone misattributes it. The contract
    // cannot do better: at completion it holds the commitment, never the recipient's address.
    // The issuer reconstructs it instead from `CommitmentInitialized` plus the commitment-tagged
    // completion log - see doc/README.md, "Private/public bridges".
    assert_eq(effects.private_logs.len(), 2, "the two notes, and no Transfer event");
    assert_eq(effects.nullifiers.len(), 4, "includes the commitment-paid nullifier of K-6");
}

// --- K-2: the mechanism that replaces the Transfer event on the commitment path ------------------

/// `doc/README.md` says the issuer reconstructs a commitment payment from the constrained
/// `CommitmentInitialized { to, completer, commitment }` event it receives when the commitment is
/// opened, plus the commitment-tagged completion log. The two tests above pin the *absence* of a
/// `Transfer` on that path; this one pins the *presence* of the substitute, so that dropping the
/// issuer's delivery from `_open_commitment` cannot leave the suite green.
#[test]
unconstrained fn opening_a_commitment_delivers_the_issuer_its_record() {
    let (env, token, issuer, user) = utils::setup_with_public_side(false, true);
    // Warm-up: first contact between `user` and the issuer creates the tagging handshakes, which
    // would otherwise land in the measured transaction (see `test_issuer_records.nr`).
    let _ = env.call_private(user, Token::at(token).initialize_transfer_commitment(user, issuer));
    env.mine_block();
    let _ = env.call_private(user, Token::at(token).initialize_transfer_commitment(user, issuer));
    let effects = get_last_tx_effects();
    // Measured. No note hash: a partial note's validity commitment is a nullifier, not a note, which
    // is why `doc/README.md` lists this entry point as publishing nothing.
    assert_eq(effects.note_hashes.len(), 0, "a partial note creates no note hash");
    // Two logs, and this is the assertion K-2 exists for: the partial note delivered to `to`, and the
    // `CommitmentInitialized` event delivered constrained to the issuer. Drop the `deliver_to` in
    // `_open_commitment` and this becomes 1, so the issuer's only record of who a commitment belongs
    // to cannot be removed while the suite stays green.
    assert_eq(effects.private_logs.len(), 2, "the partial note, and the issuer's record");
    assert_eq(effects.nullifiers.len(), 4, "the validity commitment, the event and its delivery");
}
