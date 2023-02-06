// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { IWorld } from "@latticexyz/solecs/src/interfaces/IWorld.sol";
import { System, ISystem } from "@latticexyz/solecs/src/System.sol";
import { getAddressById } from "@latticexyz/solecs/src/utils.sol";

import { ERC1155BaseSubsystem } from "../ERC1155BaseSubsystem.sol";

/**
 * @title Optional forwarder system that wraps executeSetApprovalForAll into its execute
 */
contract OperatorApprovalSystem is System {
  uint256 immutable erc1155BaseSubsystemId;

  constructor(
    IWorld _world,
    address _components,
    uint256 _erc1155BaseSubsystemId
  ) System(_world, _components) {
    erc1155BaseSubsystemId = _erc1155BaseSubsystemId;
  }

  function executeTyped(
    address operator,
    bool status
  ) public {
    execute(abi.encode(operator, status));
  }

  function execute(bytes memory arguments) public override returns (bytes memory) {
    (
      address operator,
      bool status
    ) = abi.decode(arguments, (address, bool));

    ERC1155BaseSubsystem(
      getAddressById(world.systems(), erc1155BaseSubsystemId)
    ).executeSetApprovalForAll(
      msg.sender,
      operator,
      status
    );

    return '';
  }
}