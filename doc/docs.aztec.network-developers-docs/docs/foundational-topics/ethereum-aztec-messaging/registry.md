# Registry

> Source: https://docs.aztec.network/developers/docs/foundational-topics/ethereum-aztec-messaging/registry

---

- [![Home](https://docs.aztec.network/img/Aztec_Symbol_Dark.png)![Home](https://docs.aztec.network/img/Aztec%20Symbol_Light.png)](https://docs.aztec.network/)
- [Foundational Topics](https://docs.aztec.network/developers/docs/foundational-topics)
- [Aztec<>Ethereum Messaging](https://docs.aztec.network/developers/docs/foundational-topics/ethereum-aztec-messaging)
- Registry

On this page
# Registry

The Registry is a contract deployed on L1 that tracks canonical and historical rollup instances. It allows you to query the current rollup contract and look up prior deployments by version.

**Links**: [Interface](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/l1-contracts/src/governance/interfaces/IRegistry.sol), [Implementation](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/l1-contracts/src/governance/Registry.sol).

## `numberOfVersions()`[​](#numberofversions)

Retrieves the number of versions that have been deployed.

registry_number_of_versions
```
function numberOfVersions() external view returns (uint256);
```

> [Source code: l1-contracts/src/governance/interfaces/IRegistry.sol#L25-L27](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/l1-contracts/src/governance/interfaces/IRegistry.sol#L25-L27)

| Name | Description |
| --- | --- |
| ReturnValue | The number of versions that have been deployed |

## `getCanonicalRollup()`[​](#getcanonicalrollup)

Retrieves the current rollup contract.

registry_get_canonical_rollup
```
function getCanonicalRollup() external view returns (IHaveVersion);
```

> [Source code: l1-contracts/src/governance/interfaces/IRegistry.sol#L17-L19](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/l1-contracts/src/governance/interfaces/IRegistry.sol#L17-L19)

| Name | Description |
| --- | --- |
| ReturnValue | The current rollup |

## `getRollup(uint256 _version)`[​](#getrollupuint256-_version)

Retrieves the rollup contract for a specific version.

registry_get_rollup
```
function getRollup(uint256 _chainId) external view returns (IHaveVersion);
```

> [Source code: l1-contracts/src/governance/interfaces/IRegistry.sol#L21-L23](https://github.com/AztecProtocol/aztec-packages/blob/v5.2.0/l1-contracts/src/governance/interfaces/IRegistry.sol#L21-L23)

| Name | Description |
| --- | --- |
| `_version` | The version identifier of the rollup |
| ReturnValue | The rollup for the specified version |

## Other view functions[​](#other-view-functions)

| Function | Returns | Description |
| --- | --- | --- |
| `getVersion(uint256)` | `uint256` | Returns the version number stored at the given index in the historical versions list |
| `getGovernance()` | `address` | Returns the governance contract address (owner) |
| `getRewardDistributor()` | `IRewardDistributor` | Returns the reward distributor contract |

## Related pages[​](#related-pages)

- [Inbox](https://docs.aztec.network/developers/docs/foundational-topics/ethereum-aztec-messaging/inbox) - L1 to L2 message passing
- [Outbox](https://docs.aztec.network/developers/docs/foundational-topics/ethereum-aztec-messaging/outbox) - L2 to L1 message passing
- [L1-L2 Communication (Portals)](https://docs.aztec.network/developers/docs/foundational-topics/ethereum-aztec-messaging) - Overview of cross-chain messaging

**Tags:**
- [portals](https://docs.aztec.network/developers/tags/portals)
- [contracts](https://docs.aztec.network/developers/tags/contracts)

[Edit this page](https://github.com/AztecProtocol/aztec-packages/edit/next/docs/docs-developers/docs/foundational-topics/ethereum-aztec-messaging/registry.md)