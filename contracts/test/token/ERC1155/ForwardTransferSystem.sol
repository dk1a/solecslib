// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { IWorld } from "@latticexyz/solecs/src/interfaces/IWorld.sol";
import { System, ISystem } from "@latticexyz/solecs/src/System.sol";
import { getAddressById } from "@latticexyz/solecs/src/utils.sol";

import { IERC1155Receiver } from '@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol';

import { ERC1155BaseSystem, ID as ERC1155BaseSystemID } from "./ERC1155BaseSystemMock.sol";

uint256 constant ID = uint256(keccak256("test.system.ForwardTransfer"));

contract ForwardTransferSystem is System {
  constructor(
    IWorld _world,
    address _components
  ) System(_world, _components) {}

  function executeTyped(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) public {
    execute(abi.encode(from, to, ids, amounts, data));
  }

  function execute(bytes memory arguments) public override returns (bytes memory) {
    (
      address from,
      address to,
      uint256[] memory ids,
      uint256[] memory amounts,
      bytes memory data
    ) = abi.decode(arguments, (address, address, uint256[], uint256[], bytes));

    ISystem erc1155System = ISystem(
      getAddressById(world.systems(), ERC1155BaseSystemID)
    );

    erc1155System.execute(
      abi.encode(
        ERC1155BaseSystem.executeSafeTransferBatch.selector,
        abi.encode(msg.sender, from, to, ids, amounts, data)
      )
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