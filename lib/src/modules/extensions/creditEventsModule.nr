use crate::modules::access_controlModule::{AccessControlModule, DEBT_CREDIT_EVENT_ROLE};
use aztec::context::PublicContext;
use aztec::protocol::address::AztecAddress;
use aztec::protocol::traits::{Deserialize, Packable, Serialize};
use aztec::state_vars::{PublicMutable, StateVariable};
use compressed_string::FieldCompressedString;

// ABI length: `get_credit_events` returns the three fields as Solidity's `CreditEvents` lists them.
global T_SERIALIZED_LEN: u32 = 3;
// Storage length: the two flags share one Field, the rating takes the other - the layout Solidity's
// storage packer produces for the same struct (two slots), written by hand because a derived
// `Packable` spends a whole Field per `bool` (0.3.0 review, B-3).
global T_PACKED_LEN: u32 = 2;
global FLAG_DEFAULT_BIT: u64 = 1;
global FLAG_REDEEMED_BIT: u64 = 2;

#[derive(Deserialize, Eq, Serialize)]
pub struct CreditEventsStruct {
    pub flagDefault: bool,
    pub flagRedeemed: bool,
    pub rating: FieldCompressedString,
}

impl Packable for CreditEventsStruct {
    let N: u32 = T_PACKED_LEN;

    fn pack(self) -> [Field; T_PACKED_LEN] {
        let mut flags: u64 = 0;
        if self.flagDefault {
            flags = flags | FLAG_DEFAULT_BIT;
        }
        if self.flagRedeemed {
            flags = flags | FLAG_REDEEMED_BIT;
        }
        [flags as Field, self.rating.serialize()[0]]
    }

    fn unpack(fields: [Field; T_PACKED_LEN]) -> Self {
        let flags = fields[0] as u64;
        Self {
            flagDefault: (flags & FLAG_DEFAULT_BIT) == FLAG_DEFAULT_BIT,
            flagRedeemed: (flags & FLAG_REDEEMED_BIT) == FLAG_REDEEMED_BIT,
            rating: FieldCompressedString::deserialize([fields[1]]),
        }
    }
}

pub struct CreditEvents<T, Context> {
    pub credit_event: PublicMutable<CreditEventsStruct, Context>,
}

// TODO(#13824): remove this impl once we allow structs to hold state variables.
impl<T, Context> StateVariable<T_PACKED_LEN, Context> for CreditEvents<T, Context> {
    fn new(context: Context, storage_slot: Field) -> Self {
        assert(storage_slot != 0, "Storage slot 0 not allowed. Storage slots must start from 1.");
        Self { credit_event: PublicMutable::new(context, storage_slot) }
    }

    fn get_storage_slot(self) -> Field {
        self.credit_event.get_storage_slot()
    }
}

impl<T> CreditEvents<T, PublicContext> {
    /**
    * @notice Set all attributes of creditEvents
    * The values of all attributes will be changed even if the new values are the same as the current ones
    */
    pub fn setCreditEvents(
        self: Self,
        credit_events: CreditEventsStruct,
        caller: AztecAddress,
        ac: AccessControlModule<bool, PublicContext>,
    ) {
        ac.only_role(DEBT_CREDIT_EVENT_ROLE, caller);
        let creditEvents = CreditEventsStruct {
            flagDefault: credit_events.flagDefault,
            flagRedeemed: credit_events.flagRedeemed,
            rating: credit_events.rating,
        };
        self.credit_event.write(creditEvents);
    }

    pub fn get_credit_events(self: Self) -> [Field; T_SERIALIZED_LEN] {
        self.credit_event.read().serialize()
    }
}

mod test {
    use super::CreditEventsStruct;
    use aztec::protocol::traits::Packable;
    use compressed_string::FieldCompressedString;

    /// A hand-written `pack` is code the derive cannot get wrong; the round trip is what keeps it honest.
    #[test]
    fn credit_events_pack_round_trips_every_flag_combination() {
        let rating = FieldCompressedString::from_string("AAA0000000000000000000000000000");
        for d in 0..2 {
            for r in 0..2 {
                let x = CreditEventsStruct { flagDefault: d == 1, flagRedeemed: r == 1, rating };
                let packed = x.pack();
                assert_eq(packed.len(), 2);
                assert_eq(CreditEventsStruct::unpack(packed), x);
            }
        }
    }

    #[test]
    fn credit_events_flags_occupy_distinct_bits() {
        let rating = FieldCompressedString::from_string("B000000000000000000000000000000");
        let only_default =
            CreditEventsStruct { flagDefault: true, flagRedeemed: false, rating }.pack();
        let only_redeemed =
            CreditEventsStruct { flagDefault: false, flagRedeemed: true, rating }.pack();
        assert_eq(only_default[0], 1);
        assert_eq(only_redeemed[0], 2);
        assert_eq(only_default[1], only_redeemed[1]);
    }
}
