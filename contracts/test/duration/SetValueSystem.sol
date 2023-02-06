// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { IWorld } from "@latticexyz/solecs/src/interfaces/IWorld.sol";
import { IComponent } from "@latticexyz/solecs/src/interfaces/IComponent.sol";
import { System } from "@latticexyz/solecs/src/System.sol";
import { getAddressById } from "@latticexyz/solecs/src/utils.sol";

uint256 constant ID = uint256(keccak256("test.system.SetValue"));

/// @dev Sets value of `entity` to `newValue` for the component with `componentId`
contract SetValueSystem is System {
  constructor(IWorld _world, address _components) System(_world, _components) {}

  function execute(bytes memory args) public returns (bytes memory) {
    (uint256 componentId, uint256 entity, bytes memory newValue) = abi.decode(
      args,
      (uint256, uint256, bytes)
    );

    IComponent comp = IComponent(getAddressById(components, componentId));
    comp.set(entity, newValue);
    return "";
  }

  function executeTyped(
    uint256 componentId,
    uint256 entity,
    bytes memory newValue
  ) public {
    execute(abi.encode(componentId, entity, newValue));
  }
}