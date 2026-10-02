# Contract Deployment Reference

> Source: https://docs.aztec.network/developers/docs/aztec-nr/contract_readiness_states

---

- [![Home](https://docs.aztec.network/img/Aztec_Symbol_Dark.png)![Home](https://docs.aztec.network/img/Aztec%20Symbol_Light.png)](https://docs.aztec.network/)
- [Aztec.nr](https://docs.aztec.network/developers/docs/aztec-nr)
- Contract Deployment Reference

On this page
# Contract Deployment Reference

This guide helps you quickly determine which deployment steps your contract needs. For conceptual background on how contract deployment works, see [Contract Deployment](https://docs.aztec.network/developers/docs/foundational-topics/contract_creation).

## What Do I Need to Do?[​](#what-do-i-need-to-do)

Use this decision tree to determine which steps your contract needs.

No initializer?If your contract has no `#[initializer]` function and was deployed with `without_initializer()`, it's considered initialized immediately. Skip the initialization checks above.

## Checking Contract State Programmatically[​](#checking-contract-state-programmatically)

Use `wallet.getContractMetadata(contractAddress)` to check whether a contract is registered, published, and initialized. See [Verify deployment](https://docs.aztec.network/developers/docs/aztec-js/how_to_deploy_contract#verify-deployment) for usage examples and details on what the PXE checks automatically versus what you need to verify manually.

## When Can You Skip States?[​](#when-can-you-skip-states)

| Contract Type | Class Registration | Instance Creation | Initialization | Public Deployment |
| --- | --- | --- | --- | --- |
| Private-only | Optional | Required | Depends | Skip |
| Public-only | Required | Required | Depends | Required |
| Hybrid (private + public) | Required | Required | Depends | Required |
| Stateless helper | Optional | Required | Skip | Depends |

"Depends" means it depends on whether your contract has a constructor marked with `#[initializer]`.

## When Functions Become Callable[​](#when-functions-become-callable)

| State | Private Functions | Public Functions |
| --- | --- | --- |
| Address computed only | With `#[noinitcheck]` | No |
| Class registered | With `#[noinitcheck]` | No |
| Instance deployed (not initialized) | With `#[noinitcheck]` | No |
| Initialized | Yes | No |
| Publicly deployed | Yes | Yes |

Private functions marked with `#[noinitcheck]` can be called as soon as you know the address, even before initialization. This enables patterns like pre-funded accounts.

Contracts without initializersIf your contract has no initializer and is deployed with `without_initializer()`, it's considered initialized immediately. Private functions are callable right after instance creation without needing `#[noinitcheck]`. Public functions still require public deployment.

## Further Reading[​](#further-reading)

- [Contract Deployment](https://docs.aztec.network/developers/docs/foundational-topics/contract_creation) - Conceptual foundation of classes, instances, and lifecycle states
- [Deploying Contracts](https://docs.aztec.network/developers/docs/aztec-js/how_to_deploy_contract) - TypeScript deployment guide
- [Defining Initializer Functions](https://docs.aztec.network/developers/docs/aztec-nr/framework-description/functions/how_to_define_functions#define-initializer-functions) - How to use `#[initializer]` and `#[noinitcheck]`
- [Communicating Cross-Chain](https://docs.aztec.network/developers/docs/aztec-nr/framework-description/ethereum_aztec_messaging) - Portal contracts and L1/L2 messaging

**Tags:**
- [contracts](https://docs.aztec.network/developers/tags/contracts)
- [deployment](https://docs.aztec.network/developers/tags/deployment)
- [initialization](https://docs.aztec.network/developers/tags/initialization)

[Edit this page](https://github.com/AztecProtocol/aztec-packages/edit/next/docs/docs-developers/docs/aztec-nr/contract_readiness_states.md)