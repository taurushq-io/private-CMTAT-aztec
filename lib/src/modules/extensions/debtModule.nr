use crate::modules::access_controlModule::{AccessControlModule, DEBT_ROLE};
use aztec::context::PublicContext;
use aztec::protocol::address::AztecAddress;
use aztec::protocol::traits::{Deserialize, Packable, Serialize};
use aztec::state_vars::{PublicMutable, StateVariable};
use compressed_string::FieldCompressedString;

pub global DEBT_IDENTIFIER_SERIALIZED_LEN: u32 = 4;
pub global DEBT_INSTRUMENT_SERIALIZED_LEN: u32 = 12;
// `DebtInformation` is the two sub-structs back to back, so `get_debt()` returns the identifier
// first and the instrument after it.
pub global T_SERIALIZED_LEN: u32 = DEBT_IDENTIFIER_SERIALIZED_LEN + DEBT_INSTRUMENT_SERIALIZED_LEN;

/**
* @dev Who is involved in the debt, mirroring the Solidity `ICMTATDebt.DebtIdentifier`.
*
* Field order matches the Solidity struct so that the serialized form returned by `get_debt()` can
* be read against the CMTAT interface directly.
*/
#[derive(Deserialize, Eq, Packable, Serialize)]
pub struct DebtIdentifier {
    pub issuerName: FieldCompressedString,
    pub issuerDescription: FieldCompressedString,
    pub guarantor: FieldCompressedString,
    pub debtHolder: FieldCompressedString,
}

/**
* @dev The instrument's terms, mirroring the Solidity `ICMTATDebt.DebtInstrument`.
*
* The three numeric attributes are `uint256` in Solidity and `Field` here: a Noir `Field` holds
* ~254 bits, so it carries any realistic rate, par value or denomination, but it is not a 256-bit
* integer and does not wrap like one.
*
* `currencyContract` is the address of the token the payments are made in, as in Solidity. It is an
* `AztecAddress`, so it can only name a contract on this chain - a payment currency that lives on
* another ledger has to be identified through the `currency` string instead.
*/
#[derive(Deserialize, Eq, Packable, Serialize)]
pub struct DebtInstrument {
    pub interestRate: Field,
    pub parValue: Field,
    pub minimumDenomination: Field,
    pub issuanceDate: FieldCompressedString,
    pub maturityDate: FieldCompressedString,
    pub couponPaymentFrequency: FieldCompressedString,
    // Interest schedule format (if any), setting the dates on which interest payments accrue:
    // - Format A: start date/end date/period
    // - Format B: start date/end date/day of period (e.g. quarter or year)
    // - Format C: date 1/date 2/date 3/...
    pub interestScheduleFormat: FieldCompressedString,
    // - Format A: period between the accrual date for the interest payment and the date on which
    //   the payment is scheduled to be made
    // - Format B: specific date
    pub interestPaymentDate: FieldCompressedString,
    pub dayCountConvention: FieldCompressedString,
    pub businessDayConvention: FieldCompressedString,
    pub currency: FieldCompressedString,
    pub currencyContract: AztecAddress,
}

/**
* @dev The whole debt record, mirroring the Solidity `ICMTATDebt.DebtInformation`.
*/
#[derive(Deserialize, Eq, Packable, Serialize)]
pub struct DebtInformation {
    pub debtIdentifier: DebtIdentifier,
    pub debtInstrument: DebtInstrument,
}

pub struct Debt<T, Context> {
    pub debt: PublicMutable<DebtInformation, Context>,
}

// TODO(#13824): remove this impl once we allow structs to hold state variables.
impl<T, Context> StateVariable<T_SERIALIZED_LEN, Context> for Debt<T, Context> {
    fn new(context: Context, storage_slot: Field) -> Self {
        assert(storage_slot != 0, "Storage slot 0 not allowed. Storage slots must start from 1.");
        Self { debt: PublicMutable::new(context, storage_slot) }
    }

    fn get_storage_slot(self) -> Field {
        self.debt.get_storage_slot()
    }
}

impl<T> Debt<T, PublicContext> {
    /**
    * @notice Set the whole debt record: who is involved and the instrument's terms.
    * @dev As in CMTAT Solidity, every attribute is replaced even when the new value equals the
    * current one, so a caller that wants to keep a value MUST re-supply it. Use `setDebtInstrument`
    * to change the terms without restating the identifier.
    */
    pub fn setDebt(
        self: Self,
        debt_: DebtInformation,
        caller: AztecAddress,
        ac: AccessControlModule<bool, PublicContext>,
    ) {
        ac.only_role(DEBT_ROLE, caller);
        self.debt.write(debt_);
    }

    /**
    * @notice Set only the instrument's terms, leaving the debt identifier untouched.
    * @dev Mirrors the Solidity `setDebtInstrument`, which assigns `$._debt.debtInstrument` alone.
    * The identifier is read back and rewritten because a `PublicMutable` is written whole.
    */
    pub fn setDebtInstrument(
        self: Self,
        debtInstrument_: DebtInstrument,
        caller: AztecAddress,
        ac: AccessControlModule<bool, PublicContext>,
    ) {
        ac.only_role(DEBT_ROLE, caller);
        let current = self.debt.read();
        self.debt.write(
            DebtInformation {
                debtIdentifier: current.debtIdentifier,
                debtInstrument: debtInstrument_,
            },
        );
    }

    pub fn get_debt(self: Self) -> [Field; T_SERIALIZED_LEN] {
        self.debt.read().serialize()
    }
}
