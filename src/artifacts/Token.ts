
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
  FieldLike,
  Fr,
  FunctionSelectorLike,
  loadContractArtifact,
  NoirCompiledContract,
  Point,
  PublicKey,
  Wallet,
  WrappedFieldLike,
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
  public static deploy(wallet: Wallet, admin: AztecAddressLike) {
    return new DeployMethod<TokenContract>(Fr.ZERO, wallet, TokenContractArtifact, TokenContract.at, Array.from(arguments).slice(1));
  }

  /**
   * Creates a tx to deploy a new instance of this contract using the specified public keys hash to derive the address.
   */
  public static deployWithPublicKeysHash(publicKeysHash: Fr, wallet: Wallet, admin: AztecAddressLike) {
    return new DeployMethod<TokenContract>(publicKeysHash, wallet, TokenContractArtifact, TokenContract.at, Array.from(arguments).slice(2));
  }

  /**
   * Creates a tx to deploy a new instance of this contract using the specified constructor method.
   */
  public static deployWithOpts<M extends keyof TokenContract['methods']>(
    opts: { publicKeysHash?: Fr; method?: M; wallet: Wallet },
    ...args: Parameters<TokenContract['methods'][M]>
  ) {
    return new DeployMethod<TokenContract>(
      opts.publicKeysHash ?? Fr.ZERO,
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
  

  public static get storage(): ContractStorageLayout<'admin' | 'minters' | 'balances' | 'total_supply' | 'pending_shields' | 'public_balances' | 'symbol' | 'name' | 'decimals'> {
      return {
        admin: {
      slot: new Fr(1n),
      typ: "PublicMutable<AztecAddress, Context>",
    },
minters: {
      slot: new Fr(2n),
      typ: "Map<AztecAddress, PublicMutable<bool, Context>, Context>",
    },
balances: {
      slot: new Fr(3n),
      typ: "BalancesMap<TokenNote, Context>",
    },
total_supply: {
      slot: new Fr(4n),
      typ: "PublicMutable<U128, Context>",
    },
pending_shields: {
      slot: new Fr(5n),
      typ: "PrivateSet<TransparentNote, Context>",
    },
public_balances: {
      slot: new Fr(6n),
      typ: "Map<AztecAddress, PublicMutable<U128, Context>, Context>",
    },
symbol: {
      slot: new Fr(7n),
      typ: "SharedImmutable<FieldCompressedString, Context>",
    },
name: {
      slot: new Fr(8n),
      typ: "SharedImmutable<FieldCompressedString, Context>",
    },
decimals: {
      slot: new Fr(9n),
      typ: "SharedImmutable<u8, Context>",
    }
      } as ContractStorageLayout<'admin' | 'minters' | 'balances' | 'total_supply' | 'pending_shields' | 'public_balances' | 'symbol' | 'name' | 'decimals'>;
    }
    

  public static get notes(): ContractNotes<'TokenNote' | 'TransparentNote'> {
    return {
      TokenNote: {
          id: new Fr(8411110710111078111116101n),
        },
TransparentNote: {
          id: new Fr(84114971101151129711410111011678111116101n),
        }
    } as ContractNotes<'TokenNote' | 'TransparentNote'>;
  }
  

  /** Type-safe wrappers for the public methods exposed by the contract. */
  public override methods!: {
    
    /** private_get_name() */
    private_get_name: (() => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** transfer(from: struct, to: struct, amount: field, nonce: field) */
    transfer: ((from: AztecAddressLike, to: AztecAddressLike, amount: FieldLike, nonce: FieldLike) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** un_get_decimals() */
    un_get_decimals: (() => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** un_get_name() */
    un_get_name: (() => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** privately_mint_private_note(amount: field) */
    privately_mint_private_note: ((amount: FieldLike) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** private_get_symbol() */
    private_get_symbol: (() => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** compute_note_hash_and_nullifier(contract_address: struct, nonce: field, storage_slot: field, note_type_id: field, serialized_note: array) */
    compute_note_hash_and_nullifier: ((contract_address: AztecAddressLike, nonce: FieldLike, storage_slot: FieldLike, note_type_id: FieldLike, serialized_note: FieldLike[]) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** un_get_symbol() */
    un_get_symbol: (() => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** set_admin(new_admin: struct) */
    set_admin: ((new_admin: AztecAddressLike) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** burn(from: struct, amount: field, nonce: field) */
    burn: ((from: AztecAddressLike, amount: FieldLike, nonce: FieldLike) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** constructor(admin: struct) */
    constructor: ((admin: AztecAddressLike) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** is_minter(minter: struct) */
    is_minter: ((minter: AztecAddressLike) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** private_get_decimals() */
    private_get_decimals: (() => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** balance_of_private(owner: struct) */
    balance_of_private: ((owner: AztecAddressLike) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** admin() */
    admin: (() => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** balance_of_public(owner: struct) */
    balance_of_public: ((owner: AztecAddressLike) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** mint_public(to: struct, amount: field) */
    mint_public: ((to: AztecAddressLike, amount: FieldLike) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** public_get_decimals() */
    public_get_decimals: (() => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** mint_private(amount: field, secret_hash: field) */
    mint_private: ((amount: FieldLike, secret_hash: FieldLike) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** shield(from: struct, amount: field, secret_hash: field, nonce: field) */
    shield: ((from: AztecAddressLike, amount: FieldLike, secret_hash: FieldLike, nonce: FieldLike) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** transfer_public(from: struct, to: struct, amount: field, nonce: field) */
    transfer_public: ((from: AztecAddressLike, to: AztecAddressLike, amount: FieldLike, nonce: FieldLike) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** set_minter(minter: struct, approve: boolean) */
    set_minter: ((minter: AztecAddressLike, approve: boolean) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** burn_public(from: struct, amount: field, nonce: field) */
    burn_public: ((from: AztecAddressLike, amount: FieldLike, nonce: FieldLike) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** unshield(from: struct, to: struct, amount: field, nonce: field) */
    unshield: ((from: AztecAddressLike, to: AztecAddressLike, amount: FieldLike, nonce: FieldLike) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** total_supply() */
    total_supply: (() => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** redeem_shield(to: struct, amount: field, secret: field) */
    redeem_shield: ((to: AztecAddressLike, amount: FieldLike, secret: FieldLike) => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** public_get_name() */
    public_get_name: (() => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;

    /** public_get_symbol() */
    public_get_symbol: (() => ContractFunctionInteraction) & Pick<ContractMethod, 'selector'>;
  };
}
