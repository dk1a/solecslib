// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { IWorld } from "@latticexyz/solecs/src/interfaces/IWorld.sol";

import { SafeTransferSystem } from "../../../token/ERC721/systems/SafeTransferSystem.sol";
import { ID as ERC721BaseSystemID } from "./ERC721BaseSystemMock.sol";

uint256 constant ID = uint256(keccak256("test.system.SafeTransfer"));

contract SafeTransferSystemMock is SafeTransferSystem {
  constructor(
    IWorld _world,
    address _components
  ) SafeTransferSystem(_world, _components, ERC721BaseSystemID) {}

  // to test transfer from self
  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) public pure returns (bytes4) {
    return this.onERC721Received.selector;
  }
}