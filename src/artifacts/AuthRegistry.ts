
/* Autogenerated file, do not edit! */

/* eslint-disable */
import {
  AztecAddress,
  AztecAddressLike,
  CompleteAddress,
  Contract,
  ContractArtifact,
  ContractBase,
  ContractFunctionInteraction,
  ContractInstanceWithAddress,
  ContractMethod,
  ContractStorageLayout,
  ContractNotes,
  DeployMethod,
  EthAddress,
  EthAddressLike,
  EventSelector,
  FieldLike,
  Fr,
  FunctionSelectorLike,
  L1EventPayload,
  loadContractArtifact,
  NoirCompiledContract,
  NoteSelector,
  Point,
  PublicKey,
  Wallet,
  WrappedFieldLike,
} from '@aztec/aztec.js';
import AuthRegistryContractArtifactJson from '../../target/auth_registry_contract-AuthRegistry.json' assert { type: 'json' };
export const AuthRegistryContractArtifact = loadContractArtifact(AuthRegistryContractArtifactJson as NoirCompiledContract);



/**
 * Type-safe interface for contract AuthRegistry;
 */
export class AuthRegistryContract extends ContractBase {
  
  private constructor(
    instance: ContractInstanceWithAddress,
    wallet: Wallet,
  ) {
    super(instance, AuthRegistryContractArtifact, wallet);
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
    return Contract.at(address, AuthRegistryContract.artifact, wallet) as Promise<AuthRegistryContract>;
  }

  
  /**
   * Creates a tx to deploy a new instance of this contract.
   */
  public static deploy(wallet: Wallet, ) {
    return new DeployMethod<AuthRegistryContract>(Fr.ZERO, wallet, AuthRegistryContractArtifact, AuthRegistryContract.at, Array.from(arguments).slice(1));
  }

  /**
   * Creates a tx to deploy a new instance of this contract using the specified public keys hash to derive the address.
   */
  public static deployWithPublicKeysHash(publicKeysHash: Fr, wallet: Wallet, ) {
    return new DeployMethod<AuthRegistryContract>(publicKeysHash, wallet, AuthRegistryContractArtifact, AuthRegistryContract.at, Array.from(arguments).slice(2));
  }

  /**
   * Creates a tx to deploy a new instance of this contract using the specified constructor method.
   */
  public static deployWithOpts<M extends keyof AuthRegistryContract['methods']>(
    opts: { publicKeysHash?: Fr; method?: M; wallet: Wallet },
    ...args: Parameters<AuthRegistryContract['methods'][M]>
  ) {
    return new DeployMethod<AuthRegistryContract>(
      opts.publicKeysHash ?? Fr.ZERO,
      opts.wallet,
      AuthRegistryContractArtifact,
      AuthRegistryContract.at,
      Array.from(arguments).slice(1),
      opts.method ?? 'constructor',
    );
  }
  

  
  /**
   * Returns this contract's artifact.
   */
  public static get artifact(): ContractArtifact {
    return AuthRegistryContractArtifact;
  }
  

  public static get storage(): ContractStorageLayout<'reject_all' | 'approved_actions'> {
      return {
        reject_all: {
      slot: new Fr(1n),
    },
approved_actions: {
      slot: new Fr(2n),
    }
      } as ContractStorageLayout<'reject_all' | 'approved_actions'>;
    }
    

  

  /** Type-safe wrappers for the public methods exposed by the contract. */
  public override methods!: {
    
    /** consume(on_behalf_of: struct, inner_hash: field) */
    consume: ((on_behalf_of: AztecAddressLike, inner_hash: FieldLike) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** set_authorized_private(approver: struct, message_hash: field, authorize: boolean) */
    set_authorized_private: ((approver: AztecAddressLike, message_hash: FieldLike, authorize: boolean) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** is_consumable(on_behalf_of: struct, message_hash: field) */
    is_consumable: ((on_behalf_of: AztecAddressLike, message_hash: FieldLike) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** unconstrained_is_consumable(on_behalf_of: struct, message_hash: field) */
    unconstrained_is_consumable: ((on_behalf_of: AztecAddressLike, message_hash: FieldLike) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** set_reject_all(reject: boolean) */
    set_reject_all: ((reject: boolean) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** compute_note_hash_and_optionally_a_nullifier(contract_address: struct, nonce: field, storage_slot: field, note_type_id: field, compute_nullifier: boolean, serialized_note: array) */
    compute_note_hash_and_optionally_a_nullifier: ((contract_address: AztecAddressLike, nonce: FieldLike, storage_slot: FieldLike, note_type_id: FieldLike, compute_nullifier: boolean, serialized_note: FieldLike[]) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** is_reject_all(on_behalf_of: struct) */
    is_reject_all: ((on_behalf_of: AztecAddressLike) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** set_authorized(message_hash: field, authorize: boolean) */
    set_authorized: ((message_hash: FieldLike, authorize: boolean) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;
  };

  
}
