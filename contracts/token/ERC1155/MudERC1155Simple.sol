// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.17;

// erc165
import { ISystem } from "solecs/interfaces/ISystem.sol";

// ECS
import { IWorld } from "solecs/interfaces/IWorld.sol";
import { System } from "solecs/System.sol";

// erc1155
import { ERC1155 } from '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';

// TODO this is just to see how overengineered the other implementation is
/**
 * @title ERC1155 with execute() and list of executors.
 * @dev Execute should be overridden with the necessary logic.
 */
abstract contract MudERC1155Simple is
  ERC1155,
  System
{
  mapping(address => bool) trustedExecutors;

  constructor(
    string memory uri,
    IWorld _world,
    address _components
  ) ERC1155(uri) System(_world, _components) {}

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return
      interfaceId == type(ISystem).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /**
   * @dev Sets permission to call execute
   */
  function setTrustedExecutor(address executor, bool state) public virtual onlyOwner {
    trustedExecutors[executor] = state;
  }

  // TODO should execute have a default implementation?
  /*function execute(bytes memory) public virtual override returns (bytes memory) {
    revert('PH');
  }*/
}