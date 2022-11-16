// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.17;

import { ISystem } from "@latticexyz/solecs/src/interfaces/ISystem.sol";
import { IUint256Component } from "@latticexyz/solecs/src/interfaces/IUint256Component.sol";
import { IWorld } from "@latticexyz/solecs/src/interfaces/IWorld.sol";
import { SystemStorage } from "./_SystemStorage.sol";

/**
 * @title Diamond-compatible and upgradeable base System
 */
abstract contract SystemFacet is ISystem {
  error System__OnlyOwner();

  function __System_init(IWorld world, address components) internal virtual {
    SystemStorage.layout().owner = msg.sender;
    SystemStorage.layout().components = components == address(0) ? world.components() : IUint256Component(components);
    SystemStorage.layout().world = world;
  }

  modifier onlyOwner() {
    if (msg.sender != SystemStorage.layout().owner) {
      revert System__OnlyOwner();
    }
    _;
  }

  function owner() public view override returns (address) {
    return SystemStorage.layout().owner;
  }
}
