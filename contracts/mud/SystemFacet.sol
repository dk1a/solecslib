// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { OwnableStorage } from "@solidstate/contracts/access/ownable/OwnableStorage.sol";
import { OwnableAndWriteAccess } from "./OwnableAndWriteAccess.sol";

import { ISystem } from "@latticexyz/solecs/src/interfaces/ISystem.sol";
import { IUint256Component } from "@latticexyz/solecs/src/interfaces/IUint256Component.sol";
import { IWorld } from "@latticexyz/solecs/src/interfaces/IWorld.sol";

import { SystemStorage } from "./SystemStorage.sol";

/**
 * @title Diamond-compatible and upgradeable base System with access control
 */
abstract contract SystemFacet is OwnableAndWriteAccess {
  function __SystemFacet_init(IWorld world, address components) internal virtual {
    OwnableStorage.layout().owner = msg.sender;

    SystemStorage.layout().components = components == address(0) ? world.components() : IUint256Component(components);
    SystemStorage.layout().world = world;
  }
}
