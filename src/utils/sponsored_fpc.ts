import { Fr } from '@aztec/aztec.js/fields';
import { SponsoredFeePaymentMethod } from '@aztec/aztec.js/fee/testing';
import { SponsoredFPCContract } from '@aztec/noir-contracts.js/SponsoredFPC';
import { getContractInstanceFromInstantiationParams } from '@aztec/stdlib/contract';
import type { ContractInstanceWithAddress } from '@aztec/stdlib/contract';
import type { EmbeddedWallet } from '@aztec/wallets/embedded';

const SPONSORED_FPC_SALT = new Fr(0);

export async function getSponsoredFPCInstance(): Promise<ContractInstanceWithAddress> {
    return await getContractInstanceFromInstantiationParams(SponsoredFPCContract.artifact, {
        salt: SPONSORED_FPC_SALT,
    });
}

export async function getSponsoredFPCAddress() {
    return (await getSponsoredFPCInstance()).address;
}

/**
 * Registers the sponsored FPC with the wallet and returns the payment method to pass as
 * `fee.paymentMethod`. Every testnet call in this repository pays this way, since fresh accounts have
 * no fee juice of their own.
 */
export async function getSponsoredPaymentMethod(
    wallet: EmbeddedWallet,
): Promise<SponsoredFeePaymentMethod> {
    const instance = await getSponsoredFPCInstance();
    await wallet.registerContract(instance, SponsoredFPCContract.artifact);
    return new SponsoredFeePaymentMethod(instance.address);
}
