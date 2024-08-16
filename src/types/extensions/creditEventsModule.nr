use dep::aztec::protocol_types::traits::{FromField, ToField, Serialize, Deserialize};
use dep::aztec::prelude::{AztecAddress, SharedMutable, Map, PrivateSet, PublicMutable};
use dep::aztec::context::{PublicContext, PrivateContext};
use dep::aztec::{
        unencrypted_logs::{unencrypted_event_emission::{emit, encode_event}},
        encrypted_logs::encrypted_note_emission::encode_and_encrypt_note,
    }; 
use dep::compressed_string::FieldCompressedString;
use crate::types::access_control::{AccessControl,DEBT_CREDIT_EVENT_ROLE};


global FLAG_DEFAULT_FLAG = 1;
global FLAG_REDEEMED_FLAG = 2;


global T_SERIALIZED_LEN = 3; 

    struct CreditEventsStruct {
        flagDefault: bool,
        flagRedeemed: bool,
        rating: FieldCompressedString,
    }

    struct CreditEvents<T, Context> {
        credit_event: PublicMutable<CreditEventsStruct,Context>,
    }

    #[aztec(event)]
    struct FlagDefault {
        newFlagDefault: bool
    }

    #[aztec(event)]
    struct FlagRedeemed {
        newFlagRedeemed: bool
    }

    //the type of newRating should be a string
    #[aztec(event)]
    struct Rating {
        newRating: Field,
    }


impl<T,Context> CreditEvents<T,Context> {

    pub fn new(context: Context, storage_slot: Field) -> Self {
        assert(storage_slot != 0, "Storage slot 0 not allowed. Storage slots must start from 1.");
        Self {
            credit_event: PublicMutable::new(context, storage_slot),
        }
    }
}

impl<T> CreditEvents<T, &mut PublicContext> {
    /** 
    * @notice Set all attributes of creditEvents
    * The values of all attributes will be changed even if the new values are the same as the current ones
    */
    fn setCreditEvents( self: Self, credit_events: CreditEventsStruct, caller: AztecAddress, ac: AccessControl<bool,  &mut PublicContext>){
        ac.only_role(DEBT_CREDIT_EVENT_ROLE, caller);
        let creditEvents = CreditEventsStruct {flagDefault: credit_events.flagDefault, flagRedeemed: credit_events.flagRedeemed, rating: credit_events.rating};
        self.credit_event.write(creditEvents);
            
        //the below works here
        //let context = self.credit_event.context;
        //context.emit_unencrypted_log(  flagDefault_);
        //the below only works in main contract
        //FlagDefault{newFlagDefault: flagDefault_}.emit(encode_event(&mut context));
    }

    // fn get_flag_default(self: Self) -> Field {
    //      self.credit_event.read().flagDefault.to_field()
    // }

    // fn get_flag_redeemed(self: Self) -> Field {
    //      self.credit_event.read().flagRedeemed.to_field()
    // }

    // fn get_rating(self: Self) -> Field {
    //     self.credit_event.read().rating.serialize()[0]
    // }

    fn get_credit_events(self: Self) -> [Field; T_SERIALIZED_LEN]{
        self.credit_event.read().serialize()
    }
}

// We implement this as it is used when serializing the state variable into return values
// This is very inefficient if used to store the state variable.
// We are currently "abusing" that the `to_field` is called in the `scheduled_value_change`
// where we are using this value.
impl Serialize<T_SERIALIZED_LEN> for CreditEventsStruct {
    fn serialize(self) -> [Field; T_SERIALIZED_LEN] {
        [self.flagDefault.to_field(), self.flagRedeemed.to_field(), self.rating.serialize()[0]]
    }
}

// We implement this as it is required for other contracts to be able to "rebuild" the variable
// after having received the serialized value as a return-value
impl Deserialize<T_SERIALIZED_LEN> for CreditEventsStruct {
    fn deserialize(fields: [Field; T_SERIALIZED_LEN]) -> Self {
        Self {
            flagDefault: fields[0] as bool,
            flagRedeemed: fields[1] as bool,
            rating: FieldCompressedString::from_field(fields[2]),
        }
    }
}