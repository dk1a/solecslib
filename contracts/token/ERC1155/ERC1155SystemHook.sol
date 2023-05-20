// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { IERC1155Internal } from "@solidstate/contracts/interfaces/IERC1155Internal.sol";

import { IBaseWorld } from "@latticexyz/world/src/interfaces/IBaseWorld.sol";

import { ERC1155InternalSystem } from "./ERC1155InternalSystem.sol";

abstract contract ERC1155SystemHook is IERC1155Internal {
  IBaseWorld immutable world;

  constructor(IBaseWorld _world) {
    world = _world;
  }

  function onBeforeCallSystem(address msgSender, address systemAddress, bytes memory funcSelectorAndArgs) external {
    // TODO
  }

  function onAfterCallSystem(address msgSender, address systemAddress, bytes memory funcSelectorAndArgs) external {
    // TODO (probably don't need both hooks for this?)
  }
}