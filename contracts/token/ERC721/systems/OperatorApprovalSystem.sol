// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { IWorld } from "@latticexyz/solecs/src/interfaces/IWorld.sol";
import { System, ISystem } from "@latticexyz/solecs/src/System.sol";
import { getAddressById } from "@latticexyz/solecs/src/utils.sol";

import { ERC721BaseSubsystem } from "../ERC721BaseSubsystem.sol";

/**
 * @title Optional forwarder system that wraps executeSetApprovalForAll into its execute
 */
contract OperatorApprovalSystem is System {
  uint256 immutable erc721BaseSubsystemId;

  constructor(
    IWorld _world,
    address _components,
    uint256 _erc721BaseSubsystemId
  ) System(_world, _components) {
    erc721BaseSubsystemId = _erc721BaseSubsystemId;
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

    ERC721BaseSubsystem(
      getAddressById(world.systems(), erc721BaseSubsystemId)
    ).executeSetApprovalForAll(
      msg.sender,
      operator,
      status
    );

    return '';
  }
}