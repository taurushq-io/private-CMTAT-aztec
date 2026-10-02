# Compiling Contracts

> Source: https://docs.aztec.network/developers/docs/aztec-nr/compiling_contracts

---

- [![Home](https://docs.aztec.network/img/Aztec_Symbol_Dark.png)![Home](https://docs.aztec.network/img/Aztec%20Symbol_Light.png)](https://docs.aztec.network/)
- [Aztec.nr](https://docs.aztec.network/developers/docs/aztec-nr)
- Compiling Contracts

On this page
# Compiling Contracts

This guide shows you how to compile your Aztec contracts into artifacts ready for deployment and interaction.

## Prerequisites[​](#prerequisites)

- An Aztec contract written in Aztec.nr
- `aztec` installed
- Contract project with proper `Nargo.toml` configuration

## Compile your contract[​](#compile-your-contract)

Compile your Noir contracts to generate JSON artifacts:

```
aztec compile
```

This outputs contract artifacts to the `target` folder.

## Use generated interfaces[​](#use-generated-interfaces)

The compiler automatically generates type-safe interfaces for contract interaction.

### Import and use contract interfaces[​](#import-and-use-contract-interfaces)

Use generated interfaces instead of manual function calls:

```
contract MyContract {    use token::Token;    #[external("private")]    fn transfer_tokens(token_address: AztecAddress, recipient: AztecAddress, amount: u128) {        // Use the generated Token interface to call another contract        self.call(Token::at(token_address).transfer(recipient, amount));    }    #[external("private")]    fn transfer_then_mint(token_address: AztecAddress, recipient: AztecAddress, amount: u128) {        // Private call executed immediately        self.call(Token::at(token_address).transfer(recipient, amount));        // Public call enqueued for later execution        self.enqueue(Token::at(token_address).mint_to_public(recipient, amount));    }}
```

warningDo not import generated interfaces from the same project as the source contract to avoid circular references.

## Next steps[​](#next-steps)

After compilation, use the generated artifacts to:

- Deploy contracts with the `Contract` class from `aztec.js`
- Interact with deployed contracts using type-safe interfaces
- Import contracts in other Aztec.nr projects

**Tags:**
- [contracts](https://docs.aztec.network/developers/tags/contracts)

[Edit this page](https://github.com/AztecProtocol/aztec-packages/edit/next/docs/docs-developers/docs/aztec-nr/compiling_contracts.md)