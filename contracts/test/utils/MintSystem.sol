// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.17;

import { IWorld } from "@latticexyz/solecs/src/interfaces/IWorld.sol";
import { System, ISystem } from "@latticexyz/solecs/src/System.sol";
import { getAddressById } from "@latticexyz/solecs/src/utils.sol";

import { ERC1155BaseSystem, ID as ERC1155BaseSystemID } from "./ERC1155BaseSystemMock.sol";

uint256 constant ID = uint256(keccak256("test.system.Mint"));

contract MintSystem is System {
  constructor(
    IWorld _world,
    address _components
  ) System(_world, _components) {}

  function executeTyped(
    address account,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) public {
    execute(abi.encode(account, ids, amounts, data));
  }

  function execute(bytes memory arguments) public override returns (bytes memory) {
    ISystem erc1155System = ISystem(
      getAddressById(world.systems(), ERC1155BaseSystemID)
    );

    erc1155System.execute(
      abi.encode(ERC1155BaseSystem.executeSafeMintBatch.selector, arguments)
    );

    return '';
  }
}