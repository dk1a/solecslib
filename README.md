# solecslib
ERC1155 and ERC721 Systems that use components to store data

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

[Forge](https://book.getfoundry.sh/forge/writing-tests) is used for tests internally. Except ERC tests are entirely taken from [@solidstate/spec](https://github.com/solidstate-network/solidstate-solidity/tree/master/spec), which is why hardhat is also used.

----------

## Tokens

### ERC1155, ERC721

They have similar contracts with shared suffixes:
- VData - Virtual data abstraction, like an internal interface
- Internal - ERC internals, inherits VData
- Logic - ERC public+internal methods, inherits Internal. This is a full ERC implementation, lacking only a data provider.
- DataComponents - data provider (only simple setters/getters), inherits VData.
- ERC__System - Logic + DataComponents + System + constructor + default execute implementation.

#### ERC1155BaseSystem, ERC721BaseSystem
Full ERC1155/721 and System implementation, with a default execute and sub-executes (mint,burn,transfer all share 1 contract). Its components may be read by anyone without even awareness of ERC1155/721, but writes must always go through ERC__BaseSystem (this is mostly because of events, only 1 contract should emit them).

#### Notes on VData and Logic
Data and Logic separation isn't really necessary, but this was an interesting use case for it. For example by having *Logic + DataStorage + constructor* you could get an ordinary ERC1155/721 implementation (where DataStorage implements VData but just uses normal contract storage). And imo keeping components away from Logic makes it easier to compare to @solidstate/contracts (I tried to keep it very similar, and even reuse tests via @solidstate/spec).

----------