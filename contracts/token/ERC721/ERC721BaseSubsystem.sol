// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

// erc165
import { ERC165, IERC165 } from "@solidstate/contracts/introspection/ERC165.sol";
import { ERC165Storage } from "@solidstate/contracts/introspection/ERC165Storage.sol";
import { IERC721 } from "@solidstate/contracts/interfaces/IERC721.sol";
import { ISystem } from "@latticexyz/solecs/src/interfaces/ISystem.sol";

// ECS
import { IWorld } from "@latticexyz/solecs/src/interfaces/IWorld.sol";
import { Subsystem } from "@latticexyz/solecs/src/Subsystem.sol";

// ERC721 logic and data provider
import { ERC721BaseLogic } from "./logic/ERC721BaseLogic.sol";
import { ERC721BaseDataComponents } from "./data-providers/ERC721BaseDataComponents.sol";

/**
 * @title ERC721 and ECS Subsystem that uses components.
 * @dev ALL component changes MUST go through this system.
 *
 * `deploy.json` example:
 * ```
 * {
 *   "components": ["ExampleComponent"],
 *   "systems": [
 *     { "name": "ERC721BaseSubsystem", "writeAccess": [] }
 *     { "name": "ExampleSystem", "writeAccess": ["ERC721BaseSubsystem"] },
 *   ]
 * }
 * ```
 * (ERC721BaseSubsystem deploys its components itself, you only need to deploy the subsystem)
 *
 * TODO metadata, enumerable?
 */
contract ERC721BaseSubsystem is
  ERC165,
  ERC721BaseDataComponents,
  ERC721BaseLogic,
  Subsystem
{
  using ERC165Storage for ERC165Storage.Layout;

  error ERC721BaseSubsystem__InvalidExecuteSelector();

  constructor(
    IWorld _world,
    address _components,
    uint256 ownershipComponentId,
    uint256 operatorApprovalComponentId,
    uint256 tokenApprovalComponentId
  ) Subsystem(_world, _components) {
    // create components
    // (they're tightly coupled to this system, so making them separately isn't useful)
    __ERC721BaseDataComponents_init(_world, ownershipComponentId, operatorApprovalComponentId, tokenApprovalComponentId);

    // register interfaces
    ERC165Storage.Layout storage erc165 = ERC165Storage.layout();
    // IERC165
    erc165.setSupportedInterface(type(IERC165).interfaceId, true);
    // IERC721
    erc165.setSupportedInterface(type(IERC721).interfaceId, true);
    // ISystem
    erc165.setSupportedInterface(type(ISystem).interfaceId, true);
  }

  /**
   * @notice Internally calls the specified execute method, if it's available
   */
  function _execute(bytes memory args) internal virtual override returns (bytes memory) {
    (bytes4 executeSelector, bytes memory innerArgs)
      = abi.decode(args, (bytes4, bytes));

    // mint
    if (executeSelector == this.executeSafeMint.selector) {
      (
        address account,
        uint256 tokenId,
        bytes memory data
      ) = abi.decode(innerArgs, (address, uint256, bytes));
      executeSafeMint(account, tokenId, data);

    // burn
    } else if (executeSelector == this.executeBurn.selector) {
      (
        uint256 tokenId
      ) = abi.decode(innerArgs, (uint256));
      executeBurn(tokenId);

    // transfer (approval-checked for `operator`)
    } else if (executeSelector == this.executeSafeTransfer.selector) {
      (
        address operator,
        address from,
        address to,
        uint256 id,
        bytes memory data
      ) = abi.decode(innerArgs, (address, address, address, uint256, bytes));
      executeSafeTransfer(operator, from, to, id, data);

    // transfer (from arbitrary account)
    } else if (executeSelector == this.executeArbitrarySafeTransfer.selector) {
      (
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
      ) = abi.decode(innerArgs, (address, address, uint256, bytes));
      executeArbitrarySafeTransfer(from, to, tokenId, data);

    // approve `operator` to use tokens of `account`
    } else if (executeSelector == this.executeSetApprovalForAll.selector) {
      (
        address account,
        address operator,
        bool status
      ) = abi.decode(innerArgs, (address, address, bool));
      executeSetApprovalForAll(account, operator, status);

    } else if (executeSelector == this.executeApprove.selector) {
      (
        address account,
        address operator,
        uint256 tokenId
      ) = abi.decode(innerArgs, (address, address, uint256));
      executeApprove(account, operator, tokenId);

    } else {
      revert ERC721BaseSubsystem__InvalidExecuteSelector();
    }

    return '';
  }

  /**
   * @notice Mint token to any account
   */
  function executeSafeMint(
    address account,
    uint256 id,
    bytes memory data
  ) public virtual onlyWriter {
    _safeMint(account, id, data);
  }

  /**
   * @notice Burn any existing token
   */
  function executeBurn(
    uint256 tokenId
  ) public virtual onlyWriter {
    _burn(tokenId);
  }

  /**
   * @notice Transfer with approval check for `operator`
   *
   * This can be used to forward transfers
   */
  function executeSafeTransfer(
    address operator,
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public virtual onlyWriter {
    if (!_isApprovedOrOwner(operator, tokenId)) revert ERC721Base__NotOwnerOrApproved();
    _safeTransfer(operator, from, to, tokenId, data);
  }

  /**
   * @notice Transfer tokens from any account without needing approval
   */
  function executeArbitrarySafeTransfer(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public virtual onlyWriter {
    _safeTransfer(_msgSender(), from, to, tokenId, data);
  }

  /**
   * @notice Approve `operator` to use tokens of `account`
   *
   * This can be used to forward approval
   */
  function executeSetApprovalForAll(
    address account,
    address operator,
    bool status
  ) public virtual onlyWriter {
    _setApprovalForAll(account, operator, status);
  }

  /**
   * @notice Approve `operator` to use `tokenId` of `account`
   *
   * This can be used to forward approval
   */
  function executeApprove(
    address account,
    address operator,
    uint256 tokenId
  ) public virtual onlyWriter {
    _approve(account, operator, tokenId);
  }
}