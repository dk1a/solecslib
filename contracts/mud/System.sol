// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.17;

import { ISystem } from "solecs/interfaces/ISystem.sol";
import { IUint256Component } from "solecs/interfaces/IUint256Component.sol";
import { IWorld } from "solecs/interfaces/IWorld.sol";
import { SystemStorage } from "./SystemStorage.sol";

/**
 * @title Diamond-compatible base System
 * TODO finish or remove this?
 */
abstract contract System is ISystem {
  error System__OnlyOwner();

  modifier onlyOwner() {
    if (msg.sender != SystemStorage.layout().owner) {
      revert System__OnlyOwner();
    }
    _;
  }

  function owner() public view override returns (address) {
    return SystemStorage.layout().owner;
  }

  function _initSystem(IWorld world, address components) internal virtual {
    SystemStorage.layout().owner = msg.sender;
    SystemStorage.layout().components = components == address(0) ? world.components() : IUint256Component(components);
    SystemStorage.layout().world = world;
  }
}
