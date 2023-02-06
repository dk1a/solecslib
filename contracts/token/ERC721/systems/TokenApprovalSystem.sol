// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { IWorld } from "@latticexyz/solecs/src/interfaces/IWorld.sol";
import { System, ISystem } from "@latticexyz/solecs/src/System.sol";
import { getAddressById } from "@latticexyz/solecs/src/utils.sol";

import { ERC721BaseSubsystem } from "../ERC721BaseSubsystem.sol";

/**
 * @title Optional forwarder system that wraps executeApprove into its execute
 */
contract TokenApprovalSystem is System {
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
    uint256 tokenId
  ) public {
    execute(abi.encode(operator, tokenId));
  }

  function execute(bytes memory arguments) public override returns (bytes memory) {
    (
      address operator,
      uint256 tokenId
    ) = abi.decode(arguments, (address, uint256));

    ERC721BaseSubsystem(
      getAddressById(world.systems(), erc721BaseSubsystemId)
    ).executeApprove(
      msg.sender,
      operator,
      tokenId
    );

    return '';
  }
}