use dep::aztec::protocol_types::traits::{FromField, ToField, Serialize, Deserialize};
use dep::aztec::prelude::{AztecAddress, SharedMutable, Map, PrivateSet, PublicMutable};
use dep::aztec::context::{PublicContext, PrivateContext};

    use dep::compressed_string::FieldCompressedString;
use crate::types::access_control::{AccessControl,DEBT_ROLE};


global T_SERIALIZED_LEN = 12; 


  struct DebtBaseStruct {
        interestRate: Field,
        parValue: Field,
        guarantor: FieldCompressedString,
        bondHolder: FieldCompressedString,
        maturityDate: FieldCompressedString,
        interestScheduleFormat: FieldCompressedString,
        interestPaymentDate: FieldCompressedString,
        dayCountConvention: FieldCompressedString,
        businessDayConvention: FieldCompressedString,
        publicHolidaysCalendar: FieldCompressedString,
        issuanceDate: FieldCompressedString,
        couponFrequency: FieldCompressedString,
    }

  struct DebtBase<T, Context> {
    debt_base: PublicMutable<DebtBaseStruct,Context>,
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

  fn setDebt(self: Self, debt_base_: DebtBaseStruct, caller: AztecAddress, ac: AccessControl<bool,  &mut PublicContext>) {
    ac.only_role(DEBT_ROLE, caller);
    self.debt_base.write(debt_base_);
  }

  fn get_debt_base(self: Self) -> [Field; T_SERIALIZED_LEN] {
    self.debt_base.read().serialize()
  }
}


// We implement this as it is used when serializing the state variable into return values
// This is very inefficient if used to store the state variable.
// We are currently "abusing" that the `to_field` is called in the `scheduled_value_change`
// where we are using this value.
impl Serialize<T_SERIALIZED_LEN> for DebtBaseStruct {
    fn serialize(self) -> [Field; T_SERIALIZED_LEN] {
        [self.interestRate.to_field(), self.parValue.to_field(), self.guarantor.serialize()[0], self.bondHolder.serialize()[0], self.maturityDate.serialize()[0], self.interestScheduleFormat.serialize()[0], self.interestPaymentDate.serialize()[0], self.dayCountConvention.serialize()[0], self.businessDayConvention.serialize()[0], self.publicHolidaysCalendar.serialize()[0], self.issuanceDate.serialize()[0], self.couponFrequency.serialize()[0]]
    }
}

// We implement this as it is required for other contracts to be able to "rebuild" the variable
// after having received the serialized value as a return-value
impl Deserialize<T_SERIALIZED_LEN> for DebtBaseStruct {
    fn deserialize(fields: [Field; T_SERIALIZED_LEN]) -> Self {
        Self {
            interestRate: fields[0] as Field,
            parValue: fields[1] as Field,
            guarantor: FieldCompressedString::from_field(fields[2]),
            bondHolder: FieldCompressedString::from_field(fields[2]),
            maturityDate: FieldCompressedString::from_field(fields[2]),
            interestScheduleFormat: FieldCompressedString::from_field(fields[2]),
            interestPaymentDate: FieldCompressedString::from_field(fields[2]),
            dayCountConvention: FieldCompressedString::from_field(fields[2]),
            businessDayConvention: FieldCompressedString::from_field(fields[2]),
            publicHolidaysCalendar: FieldCompressedString::from_field(fields[2]),
            issuanceDate: FieldCompressedString::from_field(fields[2]),
            couponFrequency: FieldCompressedString::from_field(fields[2]),
        }
    }
}
