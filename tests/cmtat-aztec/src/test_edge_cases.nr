//! Edge cases listed under K-5 of the 0.4.0 review, the mechanical ones: note budget, exact balance,
//! duplicate batch address, two scheduled issuer changes, authwit nonce and replay, cancel_authwit,
//! commitment completion by the wrong party / twice / after a freeze, re-initialization, the
//! argument-less public half, and the storage-slot baseline.
use crate::utils;
use aztec::protocol::traits::ToField;
use aztec::test::helpers::authwit::add_private_authwit_from_call;
use cmtat_aztec::CMTATAztec::CHANGE_ROLES_DELAY_SECONDS;
use cmtat_aztec::CMTATAztec as Token;
use cmtat_aztec_lib::modules::access_controlModule::{ENFORCEMENT_ROLE, MINTER_ROLE};
use cmtat_aztec_lib::modules::enforcementModule::FreezableFlag;

// --- note budget -----------------------------------------------------------------------------------

/// Note budget (review A-5, the AIP-20 scheme). A debit spends `DEBIT_INITIAL_MAX_NOTES` (2) notes
/// first; a balance spread over more is covered by the contract calling its own `_recurse_debit`,
/// `DEBIT_RECURSIVE_MAX_NOTES` (8) notes per call. Before A-5 the debit was sized for 16 notes and
/// one transfer could spend at most 12 (the per-call side-effect budget) and never 17 (`Balance too
/// low` from `sub`); both limits are gone, each recursive call has its own side-effect budget. Fifty
/// notes in one transfer were measured to pass (2 + 6 x 8); the remaining bound is the protocol's
/// nested-call limit, and the cost of a fragmented balance is one recursive call per eight notes.
/// Mints `n` notes of 1 to `user` and spends them all in one transfer.
unconstrained fn spend_n_notes(n: u32) {
    let (env, token, issuer, user) = utils::setup(false);
    env.call_public(issuer, Token::at(token).grant_role(MINTER_ROLE, issuer));
    for _ in 0..n {
        env.call_private(issuer, Token::at(token).mint_to_private(user, 1));
    }
    env.call_private(user, Token::at(token).transfer_private_to_private(user, issuer, n as u128, 0));
    utils::check_private_balance(env, token, user, 0);
    utils::check_private_balance(env, token, issuer, n as u128);
}

#[test]
unconstrained fn two_notes_are_spent_without_recursion() {
    spend_n_notes(2);
}

/// Three notes need one recursive call: the case that was as cheap as one note before A-5 and now
/// pays a second private call. Recorded so the trade-off stays visible.
#[test]
unconstrained fn three_notes_take_one_recursive_debit() {
    spend_n_notes(3);
}

/// Twelve was the ceiling before A-5, seventeen was impossible; both pass through the recursion.
#[test]
unconstrained fn twelve_notes_can_be_spent_in_one_transfer() {
    spend_n_notes(12);
}

#[test]
unconstrained fn seventeen_notes_can_be_spent_in_one_transfer() {
    spend_n_notes(17);
}

/// `Balance too low` still fires at every depth: the first attempt spends what it finds, the
/// recursion spends the rest, and when nothing is left to spend the debit fails.
#[test(should_fail_with = "Balance too low")]
unconstrained fn a_fragmented_balance_that_is_still_too_low_fails() {
    let (env, token, issuer, user) = utils::setup(false);
    env.call_public(issuer, Token::at(token).grant_role(MINTER_ROLE, issuer));
    for _ in 0..5 {
        env.call_private(issuer, Token::at(token).mint_to_private(user, 1));
    }
    env.call_private(user, Token::at(token).transfer_private_to_private(user, issuer, 6, 0));
}

/// Only the contract may run the recursive half: a caller cannot spend a holder's notes through it.
#[test(should_fail_with = "can only be called by the same contract")]
unconstrained fn the_recursive_debit_is_only_self() {
    let (env, token, issuer, user, _) = utils::setup_and_mint(false);
    env.call_private(user, Token::at(token)._recurse_debit(issuer, 1));
}

#[test]
unconstrained fn transferring_exactly_the_balance_leaves_zero() {
    let (env, token, issuer, user, mint_amount) = utils::setup_and_mint(false);
    env.call_private(
        issuer,
        Token::at(token).transfer_private_to_private(issuer, user, mint_amount, 0),
    );
    utils::check_private_balance(env, token, issuer, 0);
    utils::check_private_balance(env, token, user, mint_amount);
}

// --- batches -----------------------------------------------------------------------------------------

#[test]
unconstrained fn the_same_address_twice_in_a_batch_receives_the_sum() {
    let (env, token, issuer, user) = utils::setup(false);
    env.call_public(issuer, Token::at(token).grant_role(MINTER_ROLE, issuer));
    env.call_private(issuer, Token::at(token).mint_batch([user, user, user, user], [1, 2, 3, 4]));
    utils::check_private_balance(env, token, user, 10);
    assert_eq(env.view_public(Token::at(token).total_supply()), 10);
}

// --- delays ------------------------------------------------------------------------------------------

/// Two changes scheduled before the first lands: the second replaces the first, so after one delay
/// the current issuer is the second one and the audit copies go there, never to the first.
#[test]
unconstrained fn a_second_scheduled_issuer_replaces_the_first() {
    let (mut env, token, issuer, user, _) = utils::setup_and_mint(false);
    let a = env.create_light_account();
    let b = env.create_light_account();
    env.call_public(issuer, Token::at(token).set_issuer(a));
    env.call_public(issuer, Token::at(token).set_issuer(b));
    utils::advance_past_delay(env, CHANGE_ROLES_DELAY_SECONDS);
    assert_eq(env.view_public(Token::at(token).public_get_issuer()), b);
    env.call_private(issuer, Token::at(token).transfer_private_to_private(issuer, user, 100, 0));
    let messages = env.offchain_messages();
    assert_eq(messages.len(), 2);
    for i in 0..messages.len() {
        assert_eq(messages.get(i).recipient, b);
    }
}

// --- authwits ----------------------------------------------------------------------------------------

#[test(should_fail_with = "Invalid authwit nonce")]
unconstrained fn the_account_itself_must_pass_a_zero_nonce() {
    let (env, token, issuer, user, _) = utils::setup_and_mint(false);
    env.call_private(issuer, Token::at(token).transfer_private_to_private(issuer, user, 100, 7));
}

/// The nonce is what the macro nullifies, so the same authwit cannot be spent twice.
#[test(should_fail_with = "Nullifier collision")]
unconstrained fn a_consumed_authwit_cannot_be_replayed() {
    let (env, token, issuer, user, _) = utils::setup_and_mint(true);
    let call = Token::at(token).transfer_private_to_private(issuer, user, 100, 1);
    add_private_authwit_from_call(env, issuer, user, call);
    utils::call_private_on_behalf_of(env, user, issuer, call);
    utils::check_private_balance(env, token, user, 100);
    // the same call, the same nonce, the same authwit: replay
    add_private_authwit_from_call(env, issuer, user, call);
    utils::call_private_on_behalf_of(env, user, issuer, call);
}

/// `cancel_authwit` pushes the authwit's nullifier; a later use of that authwit collides with it.
#[test(should_fail_with = "Nullifier collision")]
unconstrained fn a_cancelled_authwit_cannot_be_used() {
    let (env, token, issuer, user, _) = utils::setup_and_mint(true);
    let call = Token::at(token).transfer_private_to_private(issuer, user, 100, 1);
    add_private_authwit_from_call(env, issuer, user, call);
    let inner_hash = aztec::authwit::auth::compute_inner_authwit_hash([
        user.to_field(),
        call.selector.to_field(),
        aztec::hash::hash_args(call.args),
    ]);
    env.call_private(issuer, Token::at(token).cancel_authwit(inner_hash));
    utils::call_private_on_behalf_of(env, user, issuer, call);
}

// --- commitments -------------------------------------------------------------------------------------

/// The validity commitment binds the partial note to its designated completer; anyone else fails.
#[test(should_fail_with = "unknown nullifier")]
unconstrained fn only_the_designated_completer_can_pay_a_commitment() {
    let (mut env, token, issuer, user) = utils::setup_with_public_side(false, true);
    env.call_public(issuer, Token::at(token).grant_role(MINTER_ROLE, issuer));
    let other = env.create_light_account();
    env.call_private(issuer, Token::at(token).mint_to_private(other, 1_000));
    // `user` opens a commitment that only `issuer` may complete
    let commitment =
        env.call_private(user, Token::at(token).initialize_transfer_commitment(user, issuer));
    env.mine_block();
    // `other` tries to complete it with its own funds
    env.call_private(
        other,
        Token::at(token).transfer_private_to_commitment(other, commitment, 100, 0),
    );
}

/// K-6. `PartialUintNote::complete` is not single-use: without a guard a second payment into the same
/// commitment debits the payer again and the recipient's PXE, having matched the first completion,
/// never discovers the second (measured before the fix: payer 800, recipient 100, supply 1,000).
/// `pay_commitment` now pushes `commitment_paid_nullifier(C)`, so the second payment is a duplicate
/// nullifier and never lands. AIP-20 has no such guard; the framework asks contracts for one
/// (aztec-packages #14364).
#[test(should_fail_with = "Nullifier collision")]
unconstrained fn a_second_payment_into_the_same_commitment_is_refused() {
    let (env, token, issuer, user) = utils::setup_with_public_side(false, true);
    env.call_public(issuer, Token::at(token).grant_role(MINTER_ROLE, issuer));
    env.call_private(issuer, Token::at(token).mint_to_private(issuer, 1_000));
    let commitment =
        env.call_private(user, Token::at(token).initialize_transfer_commitment(user, issuer));
    env.mine_block();
    env.call_private(
        issuer,
        Token::at(token).transfer_private_to_commitment(issuer, commitment, 100, 0),
    );
    env.call_private(
        issuer,
        Token::at(token).transfer_private_to_commitment(issuer, commitment, 100, 0),
    );
}

/// The first payment is unaffected by the guard: the recipient holds it, the payer is debited once.
#[test]
unconstrained fn the_first_payment_into_a_commitment_is_received() {
    let (env, token, issuer, user) = utils::setup_with_public_side(false, true);
    env.call_public(issuer, Token::at(token).grant_role(MINTER_ROLE, issuer));
    env.call_private(issuer, Token::at(token).mint_to_private(issuer, 1_000));
    let commitment =
        env.call_private(user, Token::at(token).initialize_transfer_commitment(user, issuer));
    env.mine_block();
    env.call_private(
        issuer,
        Token::at(token).transfer_private_to_commitment(issuer, commitment, 100, 0),
    );
    utils::check_private_balance(env, token, issuer, 900);
    utils::check_private_balance(env, token, user, 100);
    assert_eq(env.view_public(Token::at(token).total_supply()), 1_000 as u128);
}

/// Same guard on the commitment a sender opens for itself with
/// `transfer_private_to_public_with_commitment`: paid once, then refused.
#[test(should_fail_with = "Nullifier collision")]
unconstrained fn a_sender_opened_commitment_cannot_be_paid_twice_either() {
    let (env, token, issuer, user) = utils::setup_with_public_side(false, true);
    env.call_public(issuer, Token::at(token).grant_role(MINTER_ROLE, issuer));
    env.call_private(issuer, Token::at(token).mint_to_private(issuer, 1_000));
    let commitment = env.call_private(
        issuer,
        Token::at(token).transfer_private_to_public_with_commitment(issuer, user, 100, 0),
    );
    env.mine_block();
    env.call_private(
        issuer,
        Token::at(token).transfer_private_to_commitment(issuer, commitment, 100, 0),
    );
    env.call_private(
        issuer,
        Token::at(token).transfer_private_to_commitment(issuer, commitment, 100, 0),
    );
}

/// The documented gap: the recipient is screened when the commitment opens and not again at
/// completion, so a freeze in between does not stop the payment. Recorded so the gap stays visible.
#[test]
unconstrained fn a_recipient_frozen_after_opening_a_commitment_is_still_paid() {
    let (env, token, issuer, user) = utils::setup_with_public_side(false, true);
    env.call_public(issuer, Token::at(token).grant_role(MINTER_ROLE, issuer));
    env.call_public(issuer, Token::at(token).grant_role(ENFORCEMENT_ROLE, issuer));
    env.call_private(issuer, Token::at(token).mint_to_private(issuer, 1_000));
    let commitment =
        env.call_private(user, Token::at(token).initialize_transfer_commitment(user, issuer));
    env.mine_block();
    env.call_public(issuer, Token::at(token).freeze(user, FreezableFlag { is_freezed: true }));
    utils::advance_past_delay(env, CHANGE_ROLES_DELAY_SECONDS);
    env.call_private(
        issuer,
        Token::at(token).transfer_private_to_commitment(issuer, commitment, 100, 0),
    );
    utils::check_private_balance(env, token, user, 100);
}

// --- constructors, public halves, storage ---------------------------------------------------------------

#[test(should_fail_with = "duplicate nullifier")]
unconstrained fn the_initializer_cannot_be_called_a_second_time() {
    let (env, token, issuer, _) = utils::setup(false);
    env.call_public(
        issuer,
        Token::at(token).constructor(
            issuer,
            "TestToken0000000000000000000000",
            "TT00000000000000000000000000000",
            18,
            false,
        ),
    );
}

/// `_transfer` must take no arguments: every public argument is published, and this half exists only
/// to read the pause flag. The line below compiles only while the signature is empty.
#[test]
unconstrained fn the_public_half_of_a_transfer_takes_no_arguments() {
    let (_, token, _, _) = utils::setup(false);
    let call = Token::at(token)._transfer();
    assert(call.selector.to_field() != 0);
}

/// The slot of `private_balances` feeds every note hash. A change here means every existing note of
/// a deployed instance is unspendable; the release that moves it is a redeployment.
#[test]
unconstrained fn the_private_balance_slot_is_pinned() {
    // 22 at 0.4.0: the sum of the packed lengths of the six state variables declared before it
    // (pause, validation, freeze, access control, extra information, the delayed issuer address).
    // Inserting or widening any of them moves this number - and every existing note with it.
    let slot = cmtat_aztec::CMTATAztec::STORAGE_LAYOUT_CMTATAztec.fields.private_balances.slot;
    assert_eq(slot, 22);
}
