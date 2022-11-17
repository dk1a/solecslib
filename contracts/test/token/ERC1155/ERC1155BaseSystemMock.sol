// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { IWorld } from "@latticexyz/solecs/src/interfaces/IWorld.sol";
import { ERC1155BaseSystem } from "../../../token/ERC1155/ERC1155BaseSystem.sol";

uint256 constant ID = uint256(keccak256("test.system.ERC1155Base"));

uint256 constant balanceComponentId = uint256(keccak256(
  abi.encode(ID, "test.component.Balance")
));
uint256 constant operatorApprovalComponentId = uint256(keccak256(
  abi.encode(ID, "test.component.OperatorApproval")
));

contract ERC1155BaseSystemMock is ERC1155BaseSystem {
  constructor(
    IWorld _world,
    address _components
  ) ERC1155BaseSystem(_world, _components, balanceComponentId, operatorApprovalComponentId) {}

  // this is for hardhat tests
  function mint(
    address account,
    uint256 id,
    uint256 amount
  ) external {
    _safeMint(account, id, amount, '');
  }

  // this is for hardhat tests
  function burn(
    address account,
    uint256 id,
    uint256 amount
  ) external {
    _burn(account, id, amount);
  }
}