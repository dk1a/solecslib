// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.17;

import { IUint256Component } from "@latticexyz/solecs/src/interfaces/IUint256Component.sol";
import { IWorld } from "@latticexyz/solecs/src/interfaces/IWorld.sol";

library SystemStorage {
  bytes32 internal constant STORAGE_SLOT =
    keccak256('solecslib.contracts.mud.storage.SystemStorage');

  struct Layout {
    IUint256Component components;
    IWorld world;
    address owner;
  }

  function layout() internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      l.slot := slot
    }
  }
}