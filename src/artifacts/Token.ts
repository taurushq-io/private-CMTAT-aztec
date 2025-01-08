
/* Autogenerated file, do not edit! */

/* eslint-disable */
import {
  type AbiType,
  AztecAddress,
  type AztecAddressLike,
  CompleteAddress,
  Contract,
  type ContractArtifact,
  ContractBase,
  ContractFunctionInteraction,
  type ContractInstanceWithAddress,
  type ContractMethod,
  type ContractStorageLayout,
  type ContractNotes,
  decodeFromAbi,
  DeployMethod,
  EthAddress,
  type EthAddressLike,
  EventSelector,
  type FieldLike,
  Fr,
  type FunctionSelectorLike,
  L1EventPayload,
  loadContractArtifact,
  type NoirCompiledContract,
  NoteSelector,
  Point,
  type PublicKey,
  PublicKeys,
  type UnencryptedL2Log,
  type Wallet,
  type WrappedFieldLike,
} from '@aztec/aztec.js';
import TokenContractArtifactJson from '../../target/token_contract-Token.json' assert { type: 'json' };
export const TokenContractArtifact = loadContractArtifact(TokenContractArtifactJson as NoirCompiledContract);



/**
 * Type-safe interface for contract Token;
 */
export class TokenContract extends ContractBase {
  
  private constructor(
    instance: ContractInstanceWithAddress,
    wallet: Wallet,
  ) {
    super(instance, TokenContractArtifact, wallet);
  }
  

  
  /**
   * Creates a contract instance.
   * @param address - The deployed contract's address.
   * @param wallet - The wallet to use when interacting with the contract.
   * @returns A promise that resolves to a new Contract instance.
   */
  public static async at(
    address: AztecAddress,
    wallet: Wallet,
  ) {
    return Contract.at(address, TokenContract.artifact, wallet) as Promise<TokenContract>;
  }

  
  /**
   * Creates a tx to deploy a new instance of this contract.
   */
  public static deploy(wallet: Wallet, admin: AztecAddressLike, name: string, symbol: string, decimals: (bigint | number)) {
    return new DeployMethod<TokenContract>(PublicKeys.default(), wallet, TokenContractArtifact, TokenContract.at, Array.from(arguments).slice(1));
  }

  /**
   * Creates a tx to deploy a new instance of this contract using the specified public keys hash to derive the address.
   */
  public static deployWithPublicKeys(publicKeys: PublicKeys, wallet: Wallet, admin: AztecAddressLike, name: string, symbol: string, decimals: (bigint | number)) {
    return new DeployMethod<TokenContract>(publicKeys, wallet, TokenContractArtifact, TokenContract.at, Array.from(arguments).slice(2));
  }

  /**
   * Creates a tx to deploy a new instance of this contract using the specified constructor method.
   */
  public static deployWithOpts<M extends keyof TokenContract['methods']>(
    opts: { publicKeys?: PublicKeys; method?: M; wallet: Wallet },
    ...args: Parameters<TokenContract['methods'][M]>
  ) {
    return new DeployMethod<TokenContract>(
      opts.publicKeys ?? PublicKeys.default(),
      opts.wallet,
      TokenContractArtifact,
      TokenContract.at,
      Array.from(arguments).slice(1),
      opts.method ?? 'constructor',
    );
  }
  

  
  /**
   * Returns this contract's artifact.
   */
  public static get artifact(): ContractArtifact {
    return TokenContractArtifact;
  }
  

  public static get storage(): ContractStorageLayout<'pause_module' | 'validation_module' | 'enforcement_module' | 'access_control' | 'credit_event_module' | 'debt_base_module' | 'issuer_address' | 'balances' | 'total_supply' | 'symbol' | 'name' | 'decimals'> {
      return {
        pause_module: {
      slot: new Fr(1n),
    },
validation_module: {
      slot: new Fr(2n),
    },
enforcement_module: {
      slot: new Fr(5n),
    },
access_control: {
      slot: new Fr(6n),
    },
credit_event_module: {
      slot: new Fr(7n),
    },
debt_base_module: {
      slot: new Fr(8n),
    },
issuer_address: {
      slot: new Fr(9n),
    },
balances: {
      slot: new Fr(10n),
    },
total_supply: {
      slot: new Fr(11n),
    },
symbol: {
      slot: new Fr(12n),
    },
name: {
      slot: new Fr(13n),
    },
decimals: {
      slot: new Fr(14n),
    }
      } as ContractStorageLayout<'pause_module' | 'validation_module' | 'enforcement_module' | 'access_control' | 'credit_event_module' | 'debt_base_module' | 'issuer_address' | 'balances' | 'total_supply' | 'symbol' | 'name' | 'decimals'>;
    }
    

  public static get notes(): ContractNotes<'ValueNote' | 'UintNote'> {
    return {
      ValueNote: {
          id: new NoteSelector(1038582377),
        },
UintNote: {
          id: new NoteSelector(202136239),
        }
    } as ContractNotes<'ValueNote' | 'UintNote'>;
  }
  

  /** Type-safe wrappers for the public methods exposed by the contract. */
  public declare methods: {
    
    /** add_to_list(newListAddress: struct, userFlag: struct) */
    add_to_list: ((newListAddress: AztecAddressLike, userFlag: { is_blacklisted: boolean, is_whitelisted: boolean, is_in_sanction_list: boolean }) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** balance_of_private(owner: struct) */
    balance_of_private: ((owner: AztecAddressLike) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** burn(from: struct, amount: field, nonce: field) */
    burn: ((from: AztecAddressLike, amount: FieldLike, nonce: FieldLike) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** burn_batch(accounts: array, amount: array, nonce: field) */
    burn_batch: ((accounts: AztecAddressLike[], amount: FieldLike[], nonce: FieldLike) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** cancel_authwit(inner_hash: field) */
    cancel_authwit: ((inner_hash: FieldLike) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** compute_note_hash_and_optionally_a_nullifier(contract_address: struct, nonce: field, storage_slot: field, note_type_id: field, compute_nullifier: boolean, serialized_note: array) */
    compute_note_hash_and_optionally_a_nullifier: ((contract_address: AztecAddressLike, nonce: FieldLike, storage_slot: FieldLike, note_type_id: FieldLike, compute_nullifier: boolean, serialized_note: FieldLike[]) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** constructor(admin: struct, name: string, symbol: string, decimals: integer) */
    constructor: ((admin: AztecAddressLike, name: string, symbol: string, decimals: (bigint | number)) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** freeze(user: struct, value: struct) */
    freeze: ((user: AztecAddressLike, value: { is_freezed: boolean }) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** get_credit_events() */
    get_credit_events: (() => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** get_debt_base() */
    get_debt_base: (() => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** get_frozen(user: struct) */
    get_frozen: ((user: AztecAddressLike) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** get_operations() */
    get_operations: (() => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** grant_role(role: field, account: struct) */
    grant_role: ((role: FieldLike, account: AztecAddressLike) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** has_role(role: field, account: struct) */
    has_role: ((role: FieldLike, account: AztecAddressLike) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** mint(to: struct, amount: field) */
    mint: ((to: AztecAddressLike, amount: FieldLike) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** mint_batch(accounts: array, amount: array) */
    mint_batch: ((accounts: AztecAddressLike[], amount: FieldLike[]) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** only_role(role: field, caller: struct) */
    only_role: ((role: FieldLike, caller: AztecAddressLike) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** pause_contract() */
    pause_contract: (() => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** private_get_decimals() */
    private_get_decimals: (() => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** private_get_issuer() */
    private_get_issuer: (() => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** private_get_name() */
    private_get_name: (() => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** private_get_symbol() */
    private_get_symbol: (() => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** public_dispatch(selector: field) */
    public_dispatch: ((selector: FieldLike) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** public_get_decimals() */
    public_get_decimals: (() => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** public_get_issuer() */
    public_get_issuer: (() => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** public_get_name() */
    public_get_name: (() => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** public_get_pause() */
    public_get_pause: (() => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** public_get_symbol() */
    public_get_symbol: (() => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** remove_from_list(removeListAddress: struct, userFlag: struct) */
    remove_from_list: ((removeListAddress: AztecAddressLike, userFlag: { is_blacklisted: boolean, is_whitelisted: boolean, is_in_sanction_list: boolean }) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** renounce_role(role: field, callerConfirmation: struct) */
    renounce_role: ((role: FieldLike, callerConfirmation: AztecAddressLike) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** revoke_role(role: field, account: struct) */
    revoke_role: ((role: FieldLike, account: AztecAddressLike) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** set_credit_events(credit_events: struct) */
    set_credit_events: ((credit_events: { flagDefault: boolean, flagRedeemed: boolean, rating: { value: FieldLike } }) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** set_debt_base(debt_base_: struct) */
    set_debt_base: ((debt_base_: { interestRate: FieldLike, parValue: FieldLike, guarantor: { value: FieldLike }, bondHolder: { value: FieldLike }, maturityDate: { value: FieldLike }, interestScheduleFormat: { value: FieldLike }, interestPaymentDate: { value: FieldLike }, dayCountConvention: { value: FieldLike }, businessDayConvention: { value: FieldLike }, publicHolidaysCalendar: { value: FieldLike }, issuanceDate: { value: FieldLike }, couponFrequency: { value: FieldLike } }) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** set_operations(operations: struct) */
    set_operations: ((operations: { operate_blacklist: boolean, operate_whitelist: boolean, operate_sanctionlist: boolean }) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** sync_notes() */
    sync_notes: (() => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** total_supply() */
    total_supply: (() => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** transfer(to: struct, amount: field) */
    transfer: ((to: AztecAddressLike, amount: FieldLike) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** transfer_batch(accounts: array, amount: array, nonce: field) */
    transfer_batch: ((accounts: AztecAddressLike[], amount: FieldLike[], nonce: FieldLike) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** transfer_from(from: struct, to: struct, amount: field, nonce: field) */
    transfer_from: ((from: AztecAddressLike, to: AztecAddressLike, amount: FieldLike, nonce: FieldLike) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** unfreeze(user: struct, value: struct) */
    unfreeze: ((user: AztecAddressLike, value: { is_freezed: boolean }) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** unpause_contract() */
    unpause_contract: (() => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;
  };

  
}
