// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { IWorld } from "@latticexyz/solecs/src/interfaces/IWorld.sol";

import { SafeBatchTransferFromSystem } from "../../../token/ERC1155/systems/SafeBatchTransferFromSystem.sol";
import { ID as ERC1155BaseSubsystemID } from "./ERC1155BaseSubsystemMock.sol";

uint256 constant ID = uint256(keccak256("test.system.SafeBatchTransferFrom"));

contract SafeBatchTransferFromSystemMock is SafeBatchTransferFromSystem {
  constructor(
    IWorld _world,
    address _components
  ) SafeBatchTransferFromSystem(_world, _components, ERC1155BaseSubsystemID) {}

  // to test transfer from self
  function onERC1155Received(
    address,
    address,
    uint256,
    uint256,
    bytes calldata
  ) external pure returns (bytes4) {
    return this.onERC1155Received.selector;
  }

  // to test transfer from self
  function onERC1155BatchReceived(
    address,
    address,
    uint256[] calldata,
    uint256[] calldata,
    bytes calldata
  ) external pure returns (bytes4) {
    return this.onERC1155BatchReceived.selector;
  }
}