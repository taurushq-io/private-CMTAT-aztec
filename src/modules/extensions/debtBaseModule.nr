use dep::aztec::protocol_types::traits::{Packable, Serialize, Deserialize};
use dep::aztec::{prelude::{AztecAddress, PublicMutable}, state_vars::storage::Storage};
use dep::aztec::context::{PublicContext};

    use dep::compressed_string::FieldCompressedString;
use crate::modules::access_controlModule::{AccessControlModule,DEBT_ROLE};


global T_SERIALIZED_LEN: u32 = 12; 


#[derive(Deserialize, Eq, Packable, Serialize)]
pub struct DebtBaseStruct {
  pub interestRate: Field,
  pub parValue: Field,
  pub guarantor: FieldCompressedString,
  pub bondHolder: FieldCompressedString,
  pub maturityDate: FieldCompressedString,
  pub interestScheduleFormat: FieldCompressedString,
  pub interestPaymentDate: FieldCompressedString,
  pub dayCountConvention: FieldCompressedString,
  pub businessDayConvention: FieldCompressedString,
  pub publicHolidaysCalendar: FieldCompressedString,
  pub issuanceDate: FieldCompressedString,
  pub couponFrequency: FieldCompressedString,
}

  pub struct DebtBase<T, Context> {
    pub debt_base: PublicMutable<DebtBaseStruct,Context>,
  }

// TODO(#13824): remove this impl once we allow structs to hold state variables.
impl<T,Context> Storage<1> for DebtBase<T,Context> {
        fn get_storage_slot(self) -> Field {
            self.debt_base.get_storage_slot()
        }
}

impl<T,Context> DebtBase<T,Context> {

    pub fn new(context: Context, storage_slot: Field) -> Self {
        assert(storage_slot != 0, "Storage slot 0 not allowed. Storage slots must start from 1.");
        Self {
          debt_base: PublicMutable::new(context,storage_slot),
        }
    }
}

impl<T> DebtBase<T, &mut PublicContext> {

  pub fn setDebt(self: Self, debt_base_: DebtBaseStruct, caller: AztecAddress, ac: AccessControlModule<bool,  &mut PublicContext>) {
    ac.only_role(DEBT_ROLE, caller);
    self.debt_base.write(debt_base_);
  }

  pub fn get_debt_base(self: Self) -> [Field; T_SERIALIZED_LEN] {
    self.debt_base.read().serialize()
  }
}
