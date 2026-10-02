# Testing Governance Rollup Upgrade on Local Network

> Source: https://docs.aztec.network/developers/docs/tutorials/testing_governance_rollup_upgrade

---

- [![Home](https://docs.aztec.network/img/Aztec_Symbol_Dark.png)![Home](https://docs.aztec.network/img/Aztec%20Symbol_Light.png)](https://docs.aztec.network/)
- Tutorials
- Testing Governance Rollup Upgrade on Local Network

On this page
# Testing Governance Rollup Upgrade on Local Network

This guide walks through deploying a new rollup and executing a governance upgrade on a local Aztec network.

## Prerequisites[​](#prerequisites)

- [Aztec tooling](https://docs.aztec.network/developers/getting_started_on_local_network)
- Node.js and yarn

## Local Network Governance Timing[​](#local-network-governance-timing)

The default governance configuration for local networks:

| Parameter | Value | Description |
| --- | --- | --- |
| votingDelay | 60 seconds | Time before voting starts |
| votingDuration | 1 hour | Voting period length |
| executionDelay | 60 seconds | Delay after voting ends before execution |
| gracePeriod | 7 days | Window to execute after becoming executable |
| lockDelay | 30 days | Token lock period for proposers |
| lockAmount | 1,000,000 tokens | Tokens locked when proposing |

---

## Step 1: Start Local Network[​](#step-1-start-local-network)

Ensure you are on the correct Aztec version:

```
aztec-up install 5.2.0
```

```
aztec start --local-network
```

Wait for output showing deployed contract addresses. To get the **Registry Address** and other L1 contract addresses, query the running node:

```
curl -s http://localhost:8080 -X POST -H "Content-Type: application/json" \  -d '{"jsonrpc":"2.0","method":"aztec_getNodeInfo","params":[],"id":1}' | jq '.result.l1ContractAddresses'
```

Note the `registryAddress` from the output.

---

## Step 2: Download the l1-contracts bundle[​](#step-2-download-the-l1-contracts-bundle)

The [`@aztec/l1-artifacts`](https://www.npmjs.com/package/@aztec/l1-artifacts) npm package bundles a self-contained Foundry project with the L1 contract sources, prebuilt artifacts, deploy scripts, and governance payload contracts. Download the version matching your Aztec installation (run `aztec --version` to find it):

```
npm pack @aztec/l1-artifacts@5.2.0mkdir l1-contractstar xzf aztec-l1-artifacts-5.2.0.tgz --strip-components=2 -C l1-contracts package/l1-contractscd l1-contracts
```

No further setup is needed: the bundle includes the library dependencies and the generated verifier, and forge downloads the matching solc version automatically on first use.

noteThe Aztec installer ships Foundry as `aztec-forge`, `aztec-cast`, and `aztec-anvil`. Substitute your own `forge` and `cast` installs in the commands below if you have them.

---

## Step 3: Set Environment Variables[​](#step-3-set-environment-variables)

```
# Anvil's default account 0export PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80export DEPLOYER_ADDRESS=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266# Replace with actual address from Step 1export REGISTRY_ADDRESS=0x...# L1 RPCexport L1_RPC_URL=http://localhost:8545export L1_CHAIN_ID=31337# Rollup configuration (local network defaults)export AZTEC_SLOT_DURATION=36export AZTEC_EPOCH_DURATION=16export AZTEC_TARGET_COMMITTEE_SIZE=48export AZTEC_LAG_IN_EPOCHS_FOR_VALIDATOR_SET=2export AZTEC_LAG_IN_EPOCHS_FOR_RANDAO=2export AZTEC_INBOX_LAG=2export AZTEC_PROOF_SUBMISSION_EPOCHS=2export AZTEC_LOCAL_EJECTION_THRESHOLD=0export AZTEC_SLASHING_ROUND_SIZE_IN_EPOCHS=1export AZTEC_SLASHING_LIFETIME_IN_ROUNDS=10export AZTEC_SLASHING_EXECUTION_DELAY_IN_ROUNDS=1export AZTEC_SLASHING_OFFSET_IN_ROUNDS=0export AZTEC_SLASHER_ENABLED=falseexport AZTEC_SLASHING_VETOER=0x0000000000000000000000000000000000000000export AZTEC_SLASHING_DISABLE_DURATION=0export AZTEC_MANA_TARGET=100000000export AZTEC_EXIT_DELAY_SECONDS=0export AZTEC_PROVING_COST_PER_MANA=100export AZTEC_SLASH_AMOUNT_SMALL=0export AZTEC_SLASH_AMOUNT_MEDIUM=0export AZTEC_SLASH_AMOUNT_LARGE=0export AZTEC_INITIAL_ETH_PER_FEE_ASSET=10000000
```

---

## Step 4: Deploy New Rollup[​](#step-4-deploy-new-rollup)

```
aztec-forge script script/deploy/DeployRollupForUpgrade.s.sol:DeployRollupForUpgrade \  --rpc-url $L1_RPC_URL \  --broadcast \  --private-key $PRIVATE_KEY
```

Note the **new rollup address** from the JSON output.

```
export NEW_ROLLUP_ADDRESS=0x...
```

---

## Step 5: Deploy Governance Payload[​](#step-5-deploy-governance-payload)

tipThe deploy script in Step 4 also deploys this payload and prints it as `payloadAddress` in its JSON output. You can export that address as `PAYLOAD_ADDRESS` and skip this step.

**Important:** Place flags before the contract path to avoid argument parsing issues.

```
cd l1-contractsaztec-forge create \  --rpc-url $L1_RPC_URL \  --private-key $PRIVATE_KEY \  --broadcast \  src/periphery/RegisterNewRollupVersionPayload.sol:RegisterNewRollupVersionPayload \  --constructor-args $REGISTRY_ADDRESS $NEW_ROLLUP_ADDRESS
```

Note the **payload address** from the output.

```
export PAYLOAD_ADDRESS=0x...
```

---

## Step 6: Deposit Governance Tokens[​](#step-6-deposit-governance-tokens)

Mint and deposit tokens to get voting power. You need at least 1,000,000 tokens (1e24 wei) to propose:

```
aztec deposit-governance-tokens \  -r $REGISTRY_ADDRESS \  --recipient $DEPLOYER_ADDRESS \  --amount "2000000000000000000000000" \  --mint \  --l1-rpc-urls $L1_RPC_URL \  -c $L1_CHAIN_ID \  --private-key $PRIVATE_KEY
```

---

## Step 7: Advance Time for Token Checkpoint[​](#step-7-advance-time-for-token-checkpoint)

Critical StepTokens must be deposited **before** the proposal is created. The governance contract snapshots voting power at the proposal creation timestamp. If your deposit checkpoint timestamp >= proposal creation timestamp, your voting power will be **0** and the proposal will be rejected.

Advance Anvil's time to ensure the checkpoint is in the past when the proposal is created:

```
# Get current timestamp and add 120 secondsCURRENT_TS=$(cast block latest --rpc-url $L1_RPC_URL --json | jq -r '.timestamp')TARGET_TS=$((CURRENT_TS + 120))cast rpc anvil_setNextBlockTimestamp $TARGET_TS --rpc-url $L1_RPC_URLcast rpc anvil_mine 1 --rpc-url $L1_RPC_URL
```

Verify the time has advanced:

```
NEW_TS=$(cast block latest --rpc-url $L1_RPC_URL --json | jq -r '.timestamp')echo "New timestamp: $NEW_TS (should be > $CURRENT_TS)"
```

note`anvil_increaseTime` may not reliably update block timestamps. For consistent results, always use `anvil_setNextBlockTimestamp` with an explicit timestamp.

---

## Step 8: Create Proposal[​](#step-8-create-proposal)

```
aztec propose-with-lock \  -r $REGISTRY_ADDRESS \  -p $PAYLOAD_ADDRESS \  --l1-rpc-urls $L1_RPC_URL \  -c $L1_CHAIN_ID \  --private-key $PRIVATE_KEY \  --json
```

Note the **proposal ID** from output.

```
export PROPOSAL_ID=0
```

---

## Step 9: Advance Time Past Voting Delay[​](#step-9-advance-time-past-voting-delay)

The proposal must transition from Pending to Active (votingDelay = 60 seconds):

```
# Get current timestamp and add 120 seconds (buffer over 60s voting delay)CURRENT_TS=$(cast block latest --rpc-url $L1_RPC_URL --json | jq -r '.timestamp')TARGET_TS=$((CURRENT_TS + 120))cast rpc anvil_setNextBlockTimestamp $TARGET_TS --rpc-url $L1_RPC_URLcast rpc anvil_mine 1 --rpc-url $L1_RPC_URL
```

Verify the proposal is now Active (state 1):

```
# Get governance address from node info or use the one from Step 1cast call <GOVERNANCE_ADDRESS> "getProposalState(uint256)(uint8)" $PROPOSAL_ID --rpc-url $L1_RPC_URL# Expected output: 1 (Active)
```

---

## Step 10: Vote on Proposal[​](#step-10-vote-on-proposal)

```
aztec vote-on-governance-proposal \  -p $PROPOSAL_ID \  --in-favor yea \  --wait false \  -r $REGISTRY_ADDRESS \  --l1-rpc-urls $L1_RPC_URL \  -c $L1_CHAIN_ID \  --private-key $PRIVATE_KEY
```

Verify the vote was recorded with your voting power. The CLI output should show non-zero `summedBallot yea` values. If it shows `[0]`, your checkpoint timing was incorrect (see Troubleshooting).

---

## Step 11: Advance Time Past Voting Duration + Execution Delay[​](#step-11-advance-time-past-voting-duration--execution-delay)

Voting duration is 1 hour (3600s) and execution delay is 60 seconds:

```
# Get current timestamp and add 3700 seconds (voting duration + execution delay + buffer)CURRENT_TS=$(cast block latest --rpc-url $L1_RPC_URL --json | jq -r '.timestamp')TARGET_TS=$((CURRENT_TS + 3700))cast rpc anvil_setNextBlockTimestamp $TARGET_TS --rpc-url $L1_RPC_URLcast rpc anvil_mine 1 --rpc-url $L1_RPC_URL
```

Verify the proposal is now Executable (state 3):

```
cast call <GOVERNANCE_ADDRESS> "getProposalState(uint256)(uint8)" $PROPOSAL_ID --rpc-url $L1_RPC_URL# Expected output: 3 (Executable)
```

---

## Step 12: Execute Proposal[​](#step-12-execute-proposal)

```
aztec execute-governance-proposal \  -p $PROPOSAL_ID \  -r $REGISTRY_ADDRESS \  --wait false \  --l1-rpc-urls $L1_RPC_URL \  -c $L1_CHAIN_ID \  --private-key $PRIVATE_KEY
```

## Step 13: Verify the Upgrade[​](#step-13-verify-the-upgrade)

Confirm the new rollup is now the canonical rollup:

```
# Check the canonical rollup address (should match NEW_ROLLUP_ADDRESS)cast call $REGISTRY_ADDRESS "getCanonicalRollup()(address)" --rpc-url $L1_RPC_URL# Check the number of rollup versions (should be 2)cast call $REGISTRY_ADDRESS "numberOfVersions()(uint256)" --rpc-url $L1_RPC_URL
```

---

## Helper Commands[​](#helper-commands)

### Set Anvil timestamp directly[​](#set-anvil-timestamp-directly)

If time advancement isn't working as expected, set the timestamp explicitly:

```
# Get the target timestamp (current + desired seconds)cast rpc anvil_setNextBlockTimestamp <UNIX_TIMESTAMP> --rpc-url $L1_RPC_URLcast rpc anvil_mine 1 --rpc-url $L1_RPC_URL
```

### Check proposal state[​](#check-proposal-state)

```
# States: 0=Pending, 1=Active, 2=Queued, 3=Executable, 4=Rejected, 5=Executed, 6=Dropped, 7=Expiredcast call <GOVERNANCE_ADDRESS> "getProposalState(uint256)(uint8)" $PROPOSAL_ID --rpc-url $L1_RPC_URL
```

### Check current block timestamp[​](#check-current-block-timestamp)

```
cast block latest --rpc-url $L1_RPC_URL | grep timestamp
```

### Check L1 addresses[​](#check-l1-addresses)

```
aztec get-l1-addresses \  -r $REGISTRY_ADDRESS \  -v canonical \  --l1-rpc-urls $L1_RPC_URL \  -c $L1_CHAIN_ID \  --json
```

### Debug rollup state[​](#debug-rollup-state)

```
aztec debug-rollup \  --rollup $NEW_ROLLUP_ADDRESS \  --l1-rpc-urls $L1_RPC_URL \  -c $L1_CHAIN_ID
```

The `--rollup` flag is required; without it the command may fail trying to resolve the default rollup address.

---

## Quick Test (Empty Payload)[​](#quick-test-empty-payload)

If you just want to test the governance flow without deploying a real rollup:

```
cd l1-contracts# Deploy empty payload (no constructor args needed)aztec-forge create \  --rpc-url $L1_RPC_URL \  --private-key $PRIVATE_KEY \  --broadcast \  test/governance/governance/TestPayloads.sol:EmptyPayload# Use the deployed address as PAYLOAD_ADDRESS and continue from Step 6
```

---

## Troubleshooting[​](#troubleshooting)

### "Governance**CheckpointedUintLib**InsufficientValue"[​](#governancecheckpointeduintlibinsufficientvalue)

- You need more tokens. The minimum to propose is 1,000,000 tokens (1e24 wei).
- Deposit more tokens in Step 6.

### "Governance**CheckpointedUintLib**NotInPast"[​](#governancecheckpointeduintlibnotinpast)

- Tokens were deposited at or after the proposal creation time.
- Advance Anvil's time and mine a block before creating the proposal (Step 7).

### "Proposal is not active"[​](#proposal-is-not-active)

- The voting delay hasn't passed yet.
- Advance time past the votingDelay (60 seconds for local networks).

### "Proposal is not executable"[​](#proposal-is-not-executable)

- Either voting period is not complete, or execution delay hasn't passed.
- Advance time past votingDuration (1 hour) + executionDelay (60 seconds).

### Forge create fails with "Error accessing local wallet"[​](#forge-create-fails-with-error-accessing-local-wallet)

- Constructor args may be parsing incorrectly. Place `--constructor-args` at the end of the command, after the contract path.

### Time advancement not working[​](#time-advancement-not-working)

- Anvil may have auto-mined blocks that reset the accumulated time.
- Use `anvil_setNextBlockTimestamp` to set an explicit timestamp instead of `anvil_increaseTime`.

### Vote fails without explicit amount[​](#vote-fails-without-explicit-amount)

- If you see `NotInPast` errors during voting, the CLI may have a bug determining voting power.
- Workaround: specify `--vote-amount` explicitly with your deposited token amount.

**Tags:**
- [local_network](https://docs.aztec.network/developers/tags/local-network)
- [governance](https://docs.aztec.network/developers/tags/governance)
- [testing](https://docs.aztec.network/developers/tags/testing)

[Edit this page](https://github.com/AztecProtocol/aztec-packages/edit/next/docs/docs-developers/docs/tutorials/testing_governance_rollup_upgrade.md)