# Getting Started on Testnet

> Source: https://docs.aztec.network/developers/getting_started_on_testnet

---

- [![Home](https://docs.aztec.network/img/Aztec_Symbol_Dark.png)![Home](https://docs.aztec.network/img/Aztec%20Symbol_Light.png)](https://docs.aztec.network/)
- Getting Started on Testnet

On this page
# Getting Started on Testnet

This guide walks you through deploying your first contract on the Aztec testnet. You will install the CLI tools, create an account using the Sponsored FPC (so you don't need to bridge Fee Juice yourself), and deploy and interact with a contract.

## Testnet vs Local Network[​](#testnet-vs-local-network)

| Feature | Local Network | Testnet |
| --- | --- | --- |
| **Environment** | Local machine | Decentralized network on Sepolia |
| **Fees** | Free (test accounts prefunded) | Sponsored FPC available |
| **Proving** | Optional | Required |
| **Accounts** | Test accounts pre-deployed | Must create and deploy your own |

infoIf you want to develop and iterate quickly, start with the [local network guide](https://docs.aztec.network/developers/getting_started_on_local_network). The local network has instant blocks and no proving, making it faster for development.

## Prerequisites[​](#prerequisites)

- Aztec libraries require Node.js version 24. If you have an older version installed, the installer will try to upgrade via [nvm](https://github.com/nvm-sh/nvm) if available. If nvm is not installed, you will need to upgrade Node.js manually (e.g. `nvm install 24` after installing nvm).

## Install the Aztec toolchain[​](#install-the-aztec-toolchain)

Install the testnet version of the Aztec CLI:

```
VERSION=5.2.0 bash -i <(curl -sL https://install.aztec.network/5.2.0)
```

warningTestnet is version-dependent. It is currently running version `5.2.0`. Maintain version consistency when interacting with the testnet to avoid errors.

This installs:

- **aztec** - Compiles and tests Aztec contracts, launches infrastructure, and provides utility commands
- **aztec-up** - Version manager for the Aztec toolchain (`aztec-up install`, `aztec-up use`, `aztec-up list`)
- **aztec-wallet** - CLI tool for interacting with the Aztec network

## Getting started on testnet[​](#getting-started-on-testnet)

### Step 1: Set up your environment[​](#step-1-set-up-your-environment)

Set the required environment variables:

```
export NODE_URL=https://v5.testnet.rpc.aztec-labs.comexport SPONSORED_FPC_ADDRESS=0x130925fbd734a252e3d8ddff87f6c346052dd5c13314eb96026b32baa1923296
```

### Step 2: Register the Sponsored FPC[​](#step-2-register-the-sponsored-fpc)

The Sponsored FPC (Fee Payment Contract) pays transaction fees on your behalf, so you don't need to bridge Fee Juice from L1. Register it in your wallet:

```
aztec-wallet register-contract \    --node-url $NODE_URL \    --alias sponsoredfpc \    $SPONSORED_FPC_ADDRESS SponsoredFPC \    --salt 0
```

### Step 3: Create and deploy an account[​](#step-3-create-and-deploy-an-account)

Unlike the local network, testnet has no pre-deployed accounts. Create and deploy your own:

```
aztec-wallet create-account \    --node-url $NODE_URL \    --alias my-wallet \    --payment method=fpc-sponsored,fpc=$SPONSORED_FPC_ADDRESS
```

noteThe first transaction will take longer as it downloads proving keys. If you see `Timeout awaiting isMined`, the transaction is still processing: this is normal on testnet.

### Step 4: Deploy a contract[​](#step-4-deploy-a-contract)

Deploy a token contract as an example:

```
aztec-wallet deploy \    --node-url $NODE_URL \    --from accounts:my-wallet \    --payment method=fpc-sponsored,fpc=$SPONSORED_FPC_ADDRESS \    --alias token \    TokenContract \    --args accounts:my-wallet Token TOK 18
```

This deploys the `TokenContract` with:

- `admin`: your wallet address
- `name`: Token
- `symbol`: TOK
- `decimals`: 18

You can check the transaction status on [Aztecscan](https://testnet.aztecscan.xyz).

### Step 5: Interact with your contract[​](#step-5-interact-with-your-contract)

Mint some tokens:

```
aztec-wallet send mint_to_public \    --node-url $NODE_URL \    --from accounts:my-wallet \    --payment method=fpc-sponsored,fpc=$SPONSORED_FPC_ADDRESS \    --contract-address token \    --args accounts:my-wallet 100
```

Check your balance:

```
aztec-wallet simulate balance_of_public \    --node-url $NODE_URL \    --from accounts:my-wallet \    --contract-address token \    --args accounts:my-wallet
```

This should print:

```
Simulation result:  100n
```

Move tokens to private state:

```
aztec-wallet send transfer_to_private \    --node-url $NODE_URL \    --from accounts:my-wallet \    --payment method=fpc-sponsored,fpc=$SPONSORED_FPC_ADDRESS \    --contract-address token \    --args accounts:my-wallet 25
```

Check your private balance:

```
aztec-wallet simulate balance_of_private \    --node-url $NODE_URL \    --from accounts:my-wallet \    --contract-address token \    --args accounts:my-wallet
```

This should print:

```
Simulation result:  25n
```

## Viewing transactions on the block explorer[​](#viewing-transactions-on-the-block-explorer)

You can view your transactions, contracts, and account on the testnet block explorers:

- [Aztecscan](https://testnet.aztecscan.xyz)
- [Aztec Explorer](https://aztecexplorer.xyz/?network=testnet)

Search by transaction hash, contract address, or account address to see details and status.

## Registering existing contracts[​](#registering-existing-contracts)

To interact with a contract deployed by someone else, you need to register it in your local PXE first:

```
aztec-wallet register-contract \    --node-url $NODE_URL \    --alias mycontract \    <CONTRACT_ADDRESS> <ArtifactName>
```

For example, to register a `TokenContract` deployed by someone else:

```
aztec-wallet register-contract \    --node-url $NODE_URL \    --alias external-token \    0x1234...abcd TokenContract
```

After registration, you can interact with it using `aztec-wallet send` and `aztec-wallet simulate` as shown above.

## Paying fees without the Sponsored FPC[​](#paying-fees-without-the-sponsored-fpc)

The Sponsored FPC is convenient for getting started, but you can also pay fees directly by bridging Fee Juice from Ethereum Sepolia. See [Paying Fees](https://docs.aztec.network/developers/docs/aztec-js/how_to_pay_fees#bridge-fee-juice-from-l1) for details on bridging and other fee payment methods.

## Getting Fee Juice from the faucet[​](#getting-fee-juice-from-the-faucet)

If you want to pay fees directly instead of using the Sponsored FPC, you can request **Fee Juice** from the testnet faucet:

- [Aztec Fee Juice Faucet](https://aztec-faucet.nethermind.io/) - dispenses testnet Fee Juice to your account

Fee Juice is not the AZTEC tokenThis faucet dispenses **Fee Juice**, the asset used to pay transaction fees (gas) on Aztec. Fee Juice lives on Aztec (L2) and is only used to pay fees. It is **not** the AZTEC token, which is a separate asset that lives on Ethereum (L1). This faucet does not dispense AZTEC tokens.

## Testnet information[​](#testnet-information)

For complete testnet technical details including contract addresses and network configuration, see the [Networks page](https://docs.aztec.network/networks#testnet).

## Next steps[​](#next-steps)

- Check out the [Tutorials](https://docs.aztec.network/developers/docs/tutorials/contract_tutorials/counter_contract) for building more complex contracts
- Learn about [paying fees](https://docs.aztec.network/developers/docs/aztec-js/how_to_pay_fees) with different methods
- Explore [Aztec Playground](https://play.aztec.network/) for an interactive development experience

Need help?If something does not work, see the [support guide](https://docs.aztec.network/developers/support). It tells you when to ask in [Discord](https://discord.gg/aztec) or the [forum](https://forum.aztec.network), when to [open a GitHub issue](https://github.com/AztecProtocol/aztec-packages/issues/new?template=bug_report.yml), and how to disclose security issues responsibly.

**Tags:**
- [testnet](https://docs.aztec.network/developers/tags/testnet)

[Edit this page](https://github.com/AztecProtocol/aztec-packages/edit/next/docs/docs-developers/getting_started_on_testnet.md)