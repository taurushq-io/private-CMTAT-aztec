# Transactions & Fees

> Source: https://docs.aztec.network/developers/docs/tutorials/js_tutorials/webapp/transactions-and-fees

---

- [![Home](https://docs.aztec.network/img/Aztec_Symbol_Dark.png)![Home](https://docs.aztec.network/img/Aztec%20Symbol_Light.png)](https://docs.aztec.network/)
- Tutorials
- Full-Stack Tutorials
- [Building a Webapp](https://docs.aztec.network/developers/docs/tutorials/js_tutorials/webapp)
- 5. Transactions & Fees

On this page
# Transactions & Fees

This section covers what happens when you send a transaction on Aztec and how fee payment works with SponsoredFPC.

## Transaction lifecycle[​](#transaction-lifecycle)

When you call `.send()` on a contract method, it handles the entire lifecycle automatically — proving, submission, and waiting for confirmation:

```
.send() → PXE proves locally → Sent to node → Included in block → Receipt returned
```

1. **Private execution**: PXE (Private eXecution Environment) simulates the function locally using your private state and decryption keys, producing new notes, nullifiers (which mark old notes as spent), and any enqueued public function calls.
2. **Proof generation**: Barretenberg (Aztec's proving system) generates a ZK-SNARK proving that the execution was valid — without revealing your private inputs to anyone.
3. **Submission**: The proof, encrypted notes, nullifiers, and any public function calls are bundled together and sent to the Aztec node.
4. **Inclusion**: The node's sequencer validates the proof, executes any enqueued public functions, and includes the transaction in the next block.
5. **Confirmation**: The block is published to L1 (Ethereum), and a receipt with the transaction hash is returned to your app.

## Tracking transaction status[​](#tracking-transaction-status)

Open `src/components/TxStatus.tsx`:

tx-status-component
```
/** * Displays the current transaction lifecycle stage. * Transactions flow: send() -> proving -> confirmed (or error). */export function TxStatus({ state, txHash, error }: TxStatusProps) {  if (state === 'idle') return null;  const messages: Record<TxState, string> = {    idle: '',    sending: 'Sending transaction...',    proving: 'Proving transaction (generating ZK proof)...',    confirmed: 'Transaction confirmed!',    error: `Transaction failed: ${error}`,  };  return (    <div className={`tx-status tx-status-${state}`}>      <p>{messages[state]}</p>      {txHash && <p className="tx-hash">Tx: {txHash.slice(0, 10)}...</p>}    </div>  );}
```

> [Source code: docs/examples/webapp-tutorial/src/components/TxStatus.tsx#L11-L34](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/webapp-tutorial/src/components/TxStatus.tsx#L11-L34)

Integrate with contract calls:

```
setTxState('sending');try {  const receipt = await contract.methods    .play_round(gameId, round, t1, t2, t3, t4, t5)    .send({ from: account });  setTxState('confirmed');  setTxHash(receipt.receipt.txHash.toString());} catch (err) {  setTxState('error');  setTxError(err.message);}
```

`.send()` handles the full lifecycle: it generates a proof, submits the transaction to the node, waits for it to be included in a block, and returns the receipt. If you need to send without waiting, pass `wait: NO_WAIT` in the options to get a `TxHash` back immediately instead. `NO_WAIT` is exported from `@aztec/aztec.js/contracts`.

## Fee payment with SponsoredFPC[​](#fee-payment-with-sponsoredfpc)

Every Aztec transaction requires fee payment, similar to gas on Ethereum. Without a fee, the sequencer won't include your transaction. **SponsoredFPC** (Fee Payment Contract) is a special contract that agrees to pay fees on behalf of any transaction. This is useful for onboarding new users who don't yet have fee tokens.

### How it works[​](#how-it-works)

get-sponsored-fpc
```
/** * Returns the SponsoredFPC contract details. * The SponsoredFPC (Fee Payment Contract) pays transaction fees on behalf of users. * This is deployed at a well-known address derived from a fixed salt. */export async function getSponsoredFPCContract() {  const { SponsoredFPCContractArtifact } = await import(    '@aztec/noir-contracts.js/SponsoredFPC'  );  const instance = await getContractInstanceFromInstantiationParams(    SponsoredFPCContractArtifact,    { salt: new Fr(SPONSORED_FPC_SALT) }  );  return { instance, artifact: SponsoredFPCContractArtifact };}
```

> [Source code: docs/examples/webapp-tutorial/src/fees.ts#L8-L24](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/webapp-tutorial/src/fees.ts#L8-L24)

`SPONSORED_FPC_SALT` is a fixed constant so that the SponsoredFPC contract is deployed at a deterministic, well-known address across all networks (local network and beyond). Your app can always compute where it lives without querying a registry.

### Registering with PXE[​](#registering-with-pxe)

PXE needs the SponsoredFPC contract artifact registered so it can include fee payment logic when constructing transaction proofs. Without registration, PXE wouldn't know how to interact with the fee contract.

register-fpc
```
/** * Registers the SponsoredFPC contract with PXE so it can be used for fee payment. * This must be called before sending any transactions. */export async function registerSponsoredFPC(pxe: PXE) {  const contract = await getSponsoredFPCContract();  await pxe.registerContractClass(contract.artifact);  await pxe.registerContract(contract.instance);  return contract.instance.address;}
```

> [Source code: docs/examples/webapp-tutorial/src/fees.ts#L26-L37](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/webapp-tutorial/src/fees.ts#L26-L37)

### Manual fee payment[​](#manual-fee-payment)

For explicit control:

create-fee-payment
```
/** * Creates a SponsoredFeePaymentMethod that can be passed as the * `paymentMethod` option when sending transactions. */export async function createSponsoredFeePayment() {  const contract = await getSponsoredFPCContract();  return new SponsoredFeePaymentMethod(contract.instance.address);}
```

> [Source code: docs/examples/webapp-tutorial/src/fees.ts#L39-L48](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/docs/examples/webapp-tutorial/src/fees.ts#L39-L48)

```
const paymentMethod = await createSponsoredFeePayment();await contract.methods  .play_round(gameId, round, t1, t2, t3, t4, t5)  .send({    from: account,    fee: { paymentMethod },  });
```

The `EmbeddedWallet` handles this automatically via `completeFeeOptions` — you don't need to pass `fee` options manually when using it.

infoSponsoredFPC is for development. Production apps use their own fee payment strategy.

## Next steps[​](#next-steps)

Now [put everything together](https://docs.aztec.network/developers/docs/tutorials/js_tutorials/webapp/putting-it-together).

[Edit this page](https://github.com/AztecProtocol/aztec-packages/edit/next/docs/docs-developers/docs/tutorials/js_tutorials/webapp/05-transactions-and-fees.md)