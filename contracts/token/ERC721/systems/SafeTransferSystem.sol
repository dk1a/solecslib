// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { IWorld } from "@latticexyz/solecs/src/interfaces/IWorld.sol";
import { System } from "@latticexyz/solecs/src/System.sol";
import { getAddressById } from "@latticexyz/solecs/src/utils.sol";

import { ERC721BaseSubsystem } from "../ERC721BaseSubsystem.sol";

/**
 * @title Optional forwarder system that wraps executeSafeTransfer into its execute
 */
contract SafeTransferSystem is System {
  uint256 immutable erc721BaseSubsystemId;

  constructor(
    IWorld _world,
    address _components,
    uint256 _erc721BaseSubsystemId
  ) System(_world, _components) {
    erc721BaseSubsystemId = _erc721BaseSubsystemId;
  }

  function executeTyped(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public {
    execute(abi.encode(from, to, tokenId, data));
  }

  function execute(bytes memory arguments) public override returns (bytes memory) {
    (
      address from,
      address to,
      uint256 tokenId,
      bytes memory data
    ) = abi.decode(arguments, (address, address, uint256, bytes));

    ERC721BaseSubsystem(
      getAddressById(world.systems(), erc721BaseSubsystemId)
    ).executeSafeTransfer(
      msg.sender,
      from,
      to,
      tokenId,
      data
    );

    return '';
  }
}