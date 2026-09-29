//! Test helpers shared by the Noir test suites of the deployment variants.
//!
//! Only helpers that do not name a contract type belong here. The `setup*` and balance-check
//! helpers stay in each variant's test crate (`tests/<contract>/src/utils.nr`) because they
//! deploy that variant's contract (`cmtat_aztec::CMTATAztec as Token`, the `@cmtat_aztec/CMTATAztec`
//! deploy string), which a shared crate cannot do (analysis D-1, D-2). This crate is `type = "lib"`
//! and separate from `cmtat_aztec_lib` so that test scaffolding does not ship inside the contract
//! library.
use aztec::context::calls::PrivateCall;
use aztec::protocol::address::AztecAddress;
use aztec::protocol::traits::Deserialize;
use aztec::test::helpers::test_environment::{CallPrivateOptions, TestEnvironment};

/// Calls a private function as `caller` while granting the transaction access to `owner`'s secrets.
///
/// While an authwit authorizes a contract to perform an action, spending private notes still requires
/// knowledge of the note secrets, so the owner's scope must be available to the transaction. Making
/// `caller` the sender is what makes `msg_sender` differ from `from`, which is the condition that
/// triggers authwit validation.
pub unconstrained fn call_private_on_behalf_of<let M: u32, let N: u32, T>(
    env: TestEnvironment,
    caller: AztecAddress,
    owner: AztecAddress,
    call: PrivateCall<M, N, T>,
) -> T
where
    T: Deserialize,
{
    env.call_private_opts(caller, CallPrivateOptions::new().with_additional_scopes([owner]), call)
}

/// Advances the chain past a DelayedPublicMutable delay so that a scheduled value change (the issuer
/// address, a freeze, a blacklist entry, an operations flag) has become the current value.
pub unconstrained fn advance_past_delay(env: TestEnvironment, delay: u64) {
    env.advance_next_block_timestamp_by(delay + 1);
    env.mine_block();
}
