use aztec::protocol::address::AztecAddress;
use aztec::test::helpers::test_environment::TestEnvironment;

use cmtat_aztec_lib::modules::access_controlModule::{ENFORCEMENT_ROLE, PAUSE_ROLE};
use cmtat_aztec_lib::modules::enforcementModule::{CHANGE_ROLES_DELAY_SECONDS, FreezableFlag};
// Contract-agnostic helpers live in the shared `cmtat_aztec_test_helpers` crate (analysis D-2).
pub use cmtat_aztec_test_helpers::advance_past_delay;
use cmtat_aztec_auth::CMTATAztecAuth as Auth;

/// A selector no burn uses; the hook must treat it as a transfer. Any AIP-20 transfer selector
/// would do - the hook only recognises the two burn selectors and treats the rest alike.
pub global SOME_TRANSFER_SELECTOR: Field = 0xedc09d49; // transfer_private_to_private((Field),(Field),u128,Field)

/// Deploys the authorization contract with `admin` holding DEFAULT_ADMIN_ROLE. `user` stands in for
/// the token: the hook does not restrict its caller, so a test calls it directly.
pub unconstrained fn setup() -> (TestEnvironment, AztecAddress, AztecAddress, AztecAddress) {
    let mut env = TestEnvironment::new();
    let admin = env.create_light_account();
    let user = env.create_light_account();

    let initializer_call = Auth::interface().constructor(admin);
    let auth_address = env.deploy("@cmtat_aztec_auth/CMTATAztecAuth").with_public_initializer(
        admin,
        initializer_call,
    );

    (env, auth_address, admin, user)
}

pub unconstrained fn pause(env: TestEnvironment, auth: AztecAddress, admin: AztecAddress) {
    env.call_public(admin, Auth::at(auth).grant_role(PAUSE_ROLE, admin));
    env.call_public(admin, Auth::at(auth).pause_contract());
}

pub unconstrained fn deactivate(env: TestEnvironment, auth: AztecAddress, admin: AztecAddress) {
    pause(env, auth, admin);
    env.call_public(admin, Auth::at(auth).deactivate_contract());
}

/// Freezes `user` and, when `wait` is set, advances the chain past the delay so the flag is current.
pub unconstrained fn freeze(
    env: TestEnvironment,
    auth: AztecAddress,
    admin: AztecAddress,
    user: AztecAddress,
    wait: bool,
) {
    env.call_public(admin, Auth::at(auth).grant_role(ENFORCEMENT_ROLE, admin));
    env.call_public(admin, Auth::at(auth).freeze(user, FreezableFlag { is_freezed: true }));
    if wait {
        advance_past_delay(env, CHANGE_ROLES_DELAY_SECONDS);
    }
}
