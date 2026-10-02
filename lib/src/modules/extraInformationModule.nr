use crate::modules::access_controlModule::{AccessControlModule, EXTRA_INFORMATION_ROLE};
use aztec::context::PublicContext;
use aztec::protocol::address::AztecAddress;
use aztec::protocol::traits::{Deserialize, Packable, Serialize};
use aztec::state_vars::{PublicMutable, StateVariable};
use compressed_string::FieldCompressedString;

global TERMS_SERIALIZED_LEN: u32 = 5;
// `terms` occupies TERMS_SERIALIZED_LEN slots, `tokenId` the one after them.
global MODULE_SLOTS: u32 = TERMS_SERIALIZED_LEN + 1;

/**
* @dev The reference to the legally required documentation (CMTAT equivalency criterion 2).
*
* Mirrors the Solidity `IERC1643CMTAT.DocumentInfo` that `setTerms` takes: the document's name, the
* URI it lives at, and the hash of its content. `lastModified` is not part of it, because the
* contract stamps that itself - see `Terms`.
*/
#[derive(Deserialize, Eq, Packable, Serialize)]
pub struct DocumentInfo {
    pub name: FieldCompressedString,
    pub uri: FieldCompressedString,
    // Solidity carries `documentHash` as a `bytes32`. A Noir `Field` holds ~254 bits, so a 256-bit
    // digest does not fit in one: it is stored as two 128-bit halves rather than being silently
    // truncated. Split a `bytes32` as (high 16 bytes, low 16 bytes) and reassemble the same way.
    pub documentHashHigh: u128,
    pub documentHashLow: u128,
}

/**
* @dev What `terms()` returns: the Solidity `ICMTAT.CMTATTerms`, which is the document name plus an
* `IERC1643.Document` of `{uri, documentHash, lastModified}`. Flattened here because Noir has no
* need for the nested struct, and the serialized form is what the getter returns anyway.
*/
#[derive(Deserialize, Eq, Packable, Serialize)]
pub struct Terms {
    pub name: FieldCompressedString,
    pub uri: FieldCompressedString,
    pub documentHashHigh: u128,
    pub documentHashLow: u128,
    // Unix seconds, written by the contract from the block timestamp - never supplied by the caller.
    pub lastModified: u64,
}

pub struct ExtraInformation<T, Context> {
    pub terms: PublicMutable<Terms, Context>,
    pub tokenId: PublicMutable<FieldCompressedString, Context>,
}

// TODO(#13824): remove this impl once we allow structs to hold state variables.
impl<T, Context> StateVariable<MODULE_SLOTS, Context> for ExtraInformation<T, Context> {
    fn new(context: Context, storage_slot: Field) -> Self {
        assert(storage_slot != 0, "Storage slot 0 not allowed. Storage slots must start from 1.");
        Self {
            terms: PublicMutable::new(context, storage_slot),
            tokenId: PublicMutable::new(context, storage_slot + TERMS_SERIALIZED_LEN as Field),
        }
    }

    fn get_storage_slot(self) -> Field {
        // the *first* slot; the framework reserves the rest for `tokenId`
        self.terms.get_storage_slot()
    }
}

impl<T> ExtraInformation<T, PublicContext> {
    /**
    * @notice Set the reference to the legally required documentation.
    * @dev As in CMTAT Solidity, the terms are overwritten even if the new values equal the current
    * ones, and every field is replaced - a caller that wants to keep a value MUST re-supply it.
    * `timestamp` is taken from the block by the caller of this method, not from the transaction
    * sender, so `lastModified` cannot be forged.
    */
    pub fn setTerms(
        self: Self,
        terms_: DocumentInfo,
        timestamp: u64,
        caller: AztecAddress,
        ac: AccessControlModule<bool, PublicContext>,
    ) {
        ac.only_role(EXTRA_INFORMATION_ROLE, caller);
        let terms = Terms {
            name: terms_.name,
            uri: terms_.uri,
            documentHashHigh: terms_.documentHashHigh,
            documentHashLow: terms_.documentHashLow,
            lastModified: timestamp,
        };
        self.terms.write(terms);
    }

    pub fn get_terms(self: Self) -> [Field; TERMS_SERIALIZED_LEN] {
        self.terms.read().serialize()
    }

    /**
    * @notice Set the token identifier used for the tokenized asset.
    * @dev As in CMTAT Solidity, the value is written even when it equals the current one.
    */
    pub fn setTokenId(
        self: Self,
        tokenId_: FieldCompressedString,
        caller: AztecAddress,
        ac: AccessControlModule<bool, PublicContext>,
    ) {
        ac.only_role(EXTRA_INFORMATION_ROLE, caller);
        self.tokenId.write(tokenId_);
    }

    pub fn get_token_id(self: Self) -> FieldCompressedString {
        self.tokenId.read()
    }
}
