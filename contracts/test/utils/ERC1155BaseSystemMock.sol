// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.17;

import { IWorld } from "@latticexyz/solecs/src/interfaces/IWorld.sol";
import { ERC1155BaseSystem } from '../../token/ERC1155/ERC1155BaseSystem.sol';

uint256 constant ID = uint256(keccak256("mock.system.ERC1155Base"));

uint256 constant balancesComponentId = uint256(keccak256(
  abi.encode(ID, "mock.component.Balances")
));
uint256 constant operatorApprovalsComponentId = uint256(keccak256(
  abi.encode(ID, "mock.component.OperatorApprovals")
));

contract ERC1155BaseSystemMock is ERC1155BaseSystem {
  error ERC1155BaseSystemMock__InvalidCaller();

  constructor(
    IWorld _world,
    address _components
  ) ERC1155BaseSystem(_world, _components, balancesComponentId, operatorApprovalsComponentId) {}

  function execute(bytes memory args) public virtual override returns (bytes memory) {
    // limited execute with only 1 branch for testing
    if (isTrustedForwarder(msg.sender)) {
      _executeMint(args);
    } else {
      revert ERC1155BaseSystemMock__InvalidCaller();
    }

    return '';
  }

  function _executeMint(bytes memory args) private {
    (address account, uint256 id, uint256 amount, bytes memory data)
      = abi.decode(args, (address, uint256, uint256, bytes));

    _safeMint(account, id, amount, data);
  }

  function mint(
    address account,
    uint256 id,
    uint256 amount
  ) external {
    _safeMint(account, id, amount, '');
  }

  function burn(
    address account,
    uint256 id,
    uint256 amount
  ) external {
    _burn(account, id, amount);
  }
}