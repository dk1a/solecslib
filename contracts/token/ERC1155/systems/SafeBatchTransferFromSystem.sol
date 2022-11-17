// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { IWorld } from "@latticexyz/solecs/src/interfaces/IWorld.sol";
import { System, ISystem } from "@latticexyz/solecs/src/System.sol";
import { getAddressById } from "@latticexyz/solecs/src/utils.sol";

import { ERC1155BaseSystem } from "../ERC1155BaseSystem.sol";

/**
 * @title Optional forwarder system that wraps executeSafeTransferBatch into its execute
 */
contract SafeBatchTransferFromSystem is System {
  uint256 immutable erc1155BaseSystemId;

  constructor(
    IWorld _world,
    address _components,
    uint256 _erc1155BaseSystemId
  ) System(_world, _components) {
    erc1155BaseSystemId = _erc1155BaseSystemId;
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

    ERC1155BaseSystem(
      getAddressById(world.systems(), erc1155BaseSystemId)
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