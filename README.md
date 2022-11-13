# solecslib
Experimental additions to [@latticexyz/solecs](https://github.com/latticexyz/mud/tree/main/packages/solecs)

See [mud.dev](https://mud.dev/) first for context on solecs and what a System is.

### Development

Install dependencies via node

```bash
yarn install
```

Build contracts via forge

```bash
yarn build
```

Run tests via both forge and hardhat

```bash
yarn test
```

[Forge](https://book.getfoundry.sh/forge/writing-tests) is used for tests internally. Except ERC1155 tests are entirely taken from [@solidstate/spec](https://github.com/solidstate-network/solidstate-solidity/tree/master/spec), which is why hardhat is also used.

----------

### ERC1155

#### `ERC1155BaseSystem` preset
- Is a base ERC1155 (see `logic` for details, especially on internal methods).
- Is a solecs `System` - `ISystem.execute` must be implemented
- Is an `ERC2771Context` - `setTrustedForwarder` allows other Systems to forward msg.sender.
- Receives `balanceComponentId` and `operatorApprovalsComponentId` in constructor, the components will store balance and approval data and can be queried by anyone directly (but ONLY `ERC1155BaseSystem` can have write access).
- Is a solidstate ERC165 - use `ERC165Storage.setSupportedInterface` instead of overriding `supportsInterface`.

`logic` - storage-agnostic ERC1155 methods. Basically the same as `ERC1155Base` in [@solidstate/contracts](https://github.com/solidstate-network/solidstate-solidity/tree/master/contracts)
- public: `ERC1155BaseLogic`
- internal: `ERC1155BalanceInternal`, `ERC1155AccessInternal`
- virtual data: `ERC1155AccessVData`, `ERC1155BalanceVData`

`data-providers` - implementations of VData (virtual data abstraction, like an internal interface).
- ECS Components: `ERC1155BaseDataComponents`, which is used by `ERC1155BaseSystem` preset.

----------

### ERC2771Context

Derived from OpenZeppelin's implementation. Used by `ERC1155System`.

Has `setTrustedForwarder`, which allows multiple trusted forwarders. Unlike OZ's single trustedForwarder set in constructor.

Use case is also different. OZ version and ERC2771 in general are mostly about gas relays, with off-chain signing etc. But `ERC1155System` is a library-like contract. Other Systems are meant to provide more logic externally, like minting/transfers/etc.

----------