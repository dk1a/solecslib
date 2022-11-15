// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.17;

import { IWorld } from "@latticexyz/solecs/src/interfaces/IWorld.sol";
import { System } from "@latticexyz/solecs/src/System.sol";
import { getAddressById } from "@latticexyz/solecs/src/utils.sol";

import { IERC1155 } from "@solidstate/contracts/interfaces/IERC1155.sol";
import { IERC1155Receiver } from '@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol';

import { LibForwarder } from "../../token/ERC1155/LibForwarder.sol";

uint256 constant ID = uint256(keccak256("test.system.TransferSystem"));

contract TransferSystem is System {
  uint256 immutable erc1155SystemId;

  constructor(
    IWorld _world,
    address _components,
    uint256 _erc1155SystemId
  ) System(_world, _components) {
    erc1155SystemId = _erc1155SystemId;
  }

  function executeTyped(address from, address to, uint256 id, uint256 amount, bytes memory data) public {
    execute(abi.encode(from, to, id, amount, data));
  }

  function execute(bytes memory arguments) public override returns (bytes memory) {
    address erc1155System = getAddressById(world.systems(), erc1155SystemId);

    // forward the original msg.sender
    LibForwarder.functionCall(
      address(erc1155System),
      msg.sender,
      IERC1155.safeTransferFrom.selector,
      arguments
    );

    return '';
  }

  // to test transfer from self
  function onERC1155Received(
    address,
    address,
    uint256,
    uint256,
    bytes calldata
  ) public pure returns (bytes4) {
    return this.onERC1155Received.selector;
  }

  // to test transfer from self
  function onERC1155BatchReceived(
    address,
    address,
    uint256[] calldata,
    uint256[] calldata,
    bytes calldata
  ) public pure returns (bytes4) {
    return this.onERC1155BatchReceived.selector;
  }
}