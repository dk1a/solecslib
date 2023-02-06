// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import { IWorld } from "@latticexyz/solecs/src/interfaces/IWorld.sol";
import { System } from "@latticexyz/solecs/src/System.sol";

import { OwnableWritable } from "@latticexyz/solecs/src/OwnableWritable.sol";

/**
 * Subsystem base contract
 */
abstract contract Subsystem is System, OwnableWritable {
  constructor(IWorld _world, address _components) System(_world, _components) {}

  /** Subsystems have predefined access control for execute */
  function execute(bytes memory args) public override onlyWriter returns (bytes memory) {
    return _execute(args);
  }

  /** Override _execute rather than execute */
  function _execute(bytes memory args) internal virtual returns (bytes memory);
}
