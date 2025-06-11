use dep::aztec::protocol_types::traits::{Packable, Serialize, Deserialize};
use dep::aztec::{prelude::{AztecAddress, PublicMutable}, state_vars::storage::Storage};
use dep::aztec::context::{PublicContext};
use dep::compressed_string::FieldCompressedString;
use crate::types::access_controlModule::{AccessControlModule,DEBT_CREDIT_EVENT_ROLE};


pub global FLAG_DEFAULT_FLAG: Field = 1;
pub global FLAG_REDEEMED_FLAG: Field = 2;


global T_SERIALIZED_LEN: u32 = 3; 

#[derive(Deserialize, Eq, Packable, Serialize)]
pub struct CreditEventsStruct {
    flagDefault: bool,
    flagRedeemed: bool,
    rating: FieldCompressedString,
}

pub struct CreditEvents<T, Context> {
    pub credit_event: PublicMutable<CreditEventsStruct,Context>,
    }


impl<T,Context> Storage<1> for CreditEvents<T,Context> {
        fn get_storage_slot(self) -> Field {
            self.credit_event.get_storage_slot()
        }
}



//NOTE: events can only be used in contracts from what I understand
    // #[event]
    // struct FlagDefault {
    //     newFlagDefault: bool
    // }

    // #[event]
    // struct FlagRedeemed {
    //     newFlagRedeemed: bool
    // }

    // //the type of newRating should be a string
    // #[event]
    // struct Rating {
    //     newRating: Field,
    // }


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
    pub fn setCreditEvents( self: Self, credit_events: CreditEventsStruct, caller: AztecAddress, ac: AccessControlModule<bool,  &mut PublicContext>){
        ac.only_role(DEBT_CREDIT_EVENT_ROLE, caller);
        let creditEvents = CreditEventsStruct {flagDefault: credit_events.flagDefault, flagRedeemed: credit_events.flagRedeemed, rating: credit_events.rating};
        self.credit_event.write(creditEvents);
            
        //the below works here
        //let context = self.credit_event.context;
        //context.emit_unencrypted_log(  flagDefault_);
        //the below only works in main contract
        //FlagDefault{newFlagDefault: flagDefault_}.emit(encode_event(&mut context));
    }

    pub fn get_credit_events(self: Self) -> [Field; T_SERIALIZED_LEN]{
        self.credit_event.read().serialize()
    }
}