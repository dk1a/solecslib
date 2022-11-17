// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { IWorld } from "@latticexyz/solecs/src/interfaces/IWorld.sol";
import { System, ISystem } from "@latticexyz/solecs/src/System.sol";
import { getAddressById } from "@latticexyz/solecs/src/utils.sol";

import { ERC721BaseSystem } from "../ERC721BaseSystem.sol";

/**
 * @title Optional forwarder system that wraps executeSetApprovalForAll into its execute
 */
contract OperatorApprovalSystem is System {
  uint256 immutable erc721BaseSystemId;

  constructor(
    IWorld _world,
    address _components,
    uint256 _erc721BaseSystemId
  ) System(_world, _components) {
    erc721BaseSystemId = _erc721BaseSystemId;
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

    ERC721BaseSystem(
      getAddressById(world.systems(), erc721BaseSystemId)
    ).executeSetApprovalForAll(
      msg.sender,
      operator,
      status
    );

    return '';
  }
}