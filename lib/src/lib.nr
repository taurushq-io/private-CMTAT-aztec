//! Shared CMTAT modules for the Aztec deployment variants.
//!
//! Noir has no inheritance, so each concern is a struct implementing `StateVariable` and held as a
//! field of a contract's `#[storage]` struct. The variants in `contracts/` compose different subsets
//! of these; every user-callable entry point is still declared in each contract's `main.nr`.
pub mod modules;
