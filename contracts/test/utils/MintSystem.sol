// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.17;

import { IWorld } from "solecs/interfaces/IWorld.sol";
import { System, ISystem } from "solecs/System.sol";
import { getAddressById } from "solecs/utils.sol";
import { LibForwarder } from "../../token/ERC1155/LibForwarder.sol";

uint256 constant ID = uint256(keccak256("test.system.MintSystem"));

contract MintSystem is System {
  uint256 immutable erc1155SystemId;

  constructor(
    IWorld _world,
    address _components,
    uint256 _erc1155SystemId
  ) System(_world, _components) {
    erc1155SystemId = _erc1155SystemId;
  }

  function executeTyped(address account, uint256 id, uint256 amount, bytes memory data) public {
    execute(abi.encode(account, id, amount, data));
  }

  function execute(bytes memory arguments) public override returns (bytes memory) {
    ISystem erc1155System = ISystem(
      getAddressById(world.systems(), erc1155SystemId)
    );

    // forward self as msg.sender
    LibForwarder.execute(erc1155System, address(this), arguments);

    return '';
  }
}