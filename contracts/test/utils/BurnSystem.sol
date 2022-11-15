// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.17;

import { IWorld } from "@latticexyz/solecs/src/interfaces/IWorld.sol";
import { System, ISystem } from "@latticexyz/solecs/src/System.sol";
import { getAddressById } from "@latticexyz/solecs/src/utils.sol";

import { LibForwarder } from "../../token/ERC1155/LibForwarder.sol";
import { ERC1155ExecuteType } from "../../token/ERC1155/ERC1155BaseSystem.sol";

uint256 constant ID = uint256(keccak256("test.system.BurnSystem"));

contract BurnSystem is System {
  uint256 immutable erc1155SystemId;

  constructor(
    IWorld _world,
    address _components,
    uint256 _erc1155SystemId
  ) System(_world, _components) {
    erc1155SystemId = _erc1155SystemId;
  }

  function executeTyped(
    address account,
    uint256[] memory ids,
    uint256[] memory amounts
  ) public {
    execute(abi.encode(account, ids, amounts));
  }

  function execute(bytes memory arguments) public override returns (bytes memory) {
    ISystem erc1155System = ISystem(
      getAddressById(world.systems(), erc1155SystemId)
    );

    // forward the original msg.sender
    LibForwarder.execute(
      erc1155System,
      msg.sender,
      abi.encode(ERC1155ExecuteType.BURN_BATCH, arguments)
    );

    return '';
  }
}