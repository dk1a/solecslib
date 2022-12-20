// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { IWorld } from "@latticexyz/solecs/src/interfaces/IWorld.sol";
import { System, ISystem } from "@latticexyz/solecs/src/System.sol";
import { getAddressById } from "@latticexyz/solecs/src/utils.sol";

import { ERC1155BaseSubsystem } from "../ERC1155BaseSubsystem.sol";

/**
 * @title Optional forwarder system that wraps executeSafeTransferBatch into its execute
 */
contract SafeBatchTransferFromSystem is System {
  uint256 immutable erc1155BaseSubsystemId;

  constructor(
    IWorld _world,
    address _components,
    uint256 _erc1155BaseSubsystemId
  ) System(_world, _components) {
    erc1155BaseSubsystemId = _erc1155BaseSubsystemId;
  }

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

    ERC1155BaseSubsystem(
      getAddressById(world.systems(), erc1155BaseSubsystemId)
    ).executeSafeTransferBatch(
      msg.sender,
      from,
      to,
      ids,
      amounts,
      data
    );

    return '';
  }
}