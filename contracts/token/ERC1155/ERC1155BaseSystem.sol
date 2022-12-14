// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

// erc165
import { ERC165, IERC165 } from "@solidstate/contracts/introspection/ERC165.sol";
import { ERC165Storage } from "@solidstate/contracts/introspection/ERC165Storage.sol";
import { IERC1155 } from "@solidstate/contracts/interfaces/IERC1155.sol";
import { ISystem } from "@latticexyz/solecs/src/interfaces/ISystem.sol";

// ECS
import { IWorld } from "@latticexyz/solecs/src/interfaces/IWorld.sol";
//import { System } from "@latticexyz/solecs/src/System.sol";
import { SystemFacet } from "../../mud/SystemFacet.sol";

// ERC1155 logic and data provider
import { ERC1155BaseLogic } from "./logic/ERC1155BaseLogic.sol";
import { ERC1155BaseDataComponents } from "./data-providers/ERC1155BaseDataComponents.sol";

/**
 * @title ERC1155 and ECS System that uses components.
 * @dev ALL component changes MUST go through this system.
 * Call `authorizeWriter` to let another system write to this.
 * 
 * TODO metadata, enumerable?
 * TODO atm not using solecs's System in favour of custom owner+writeAccess
 */
contract ERC1155BaseSystem is
  ERC165,
  ERC1155BaseDataComponents,
  ERC1155BaseLogic,
  SystemFacet
{
  using ERC165Storage for ERC165Storage.Layout;

  error ERC1155BaseSystem__InvalidExecuteSelector();

  // TODO diamond-compatible version?
  constructor(
    IWorld _world,
    address _components,
    uint256 balanceComponentId,
    uint256 operatorApprovalComponentId
  ) {
    // initialize base system
    __SystemFacet_init(_world, _components);

    // create components
    // (they're tightly coupled to this system, so making them separately isn't useful)
    __ERC1155BaseDataComponents_init(_world, balanceComponentId, operatorApprovalComponentId);

    // register interfaces
    ERC165Storage.Layout storage erc165 = ERC165Storage.layout();
    // IERC165
    erc165.setSupportedInterface(type(IERC165).interfaceId, true);
    // IERC1155
    erc165.setSupportedInterface(type(IERC1155).interfaceId, true);
    // ISystem
    erc165.setSupportedInterface(type(ISystem).interfaceId, true);
  }

  /**
   * @notice Internally calls the specified execute method, if it's available
   */
  function execute(bytes memory args) public virtual returns (bytes memory) {
    (bytes4 executeSelector, bytes memory innerArgs)
      = abi.decode(args, (bytes4, bytes));

    // mint
    if (executeSelector == this.executeSafeMintBatch.selector) {
      (
        address account,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
      ) = abi.decode(innerArgs, (address, uint256[], uint256[], bytes));
      executeSafeMintBatch(account, ids, amounts, data);

    // burn
    } else if (executeSelector == this.executeBurnBatch.selector) {
      (
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
      ) = abi.decode(innerArgs, (address, uint256[], uint256[]));
      executeBurnBatch(account, ids, amounts);

    // transfer (approval-checked for `operator`)
    } else if (executeSelector == this.executeSafeTransferBatch.selector) {
      (
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
      ) = abi.decode(innerArgs, (address, address, address, uint256[], uint256[], bytes));
      executeSafeTransferBatch(operator, from, to, ids, amounts, data);

    // transfer (from arbitrary account)
    } else if (executeSelector == this.executeArbitrarySafeTransferBatch.selector) {
      (
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
      ) = abi.decode(innerArgs, (address, address, uint256[], uint256[], bytes));
      executeArbitrarySafeTransferBatch(from, to, ids, amounts, data);

    // approve `operator` to use tokens of `account`
    } else if (executeSelector == this.executeSetApprovalForAll.selector) {
      (
        address account,
        address operator,
        bool status
      ) = abi.decode(innerArgs, (address, address, bool));
      executeSetApprovalForAll(account, operator, status);

    } else {
      revert ERC1155BaseSystem__InvalidExecuteSelector();
    }

    return '';
  }

  /**
   * @notice Mint tokens to any account
   */
  function executeSafeMintBatch(
    address account,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) public virtual onlyWriter {
    _safeMintBatch(account, ids, amounts, data);
  }

  /**
   * @notice Burn tokens from any account
   */
  function executeBurnBatch(
    address account,
    uint256[] memory ids,
    uint256[] memory amounts
  ) public virtual onlyWriter {
    _burnBatch(account, ids, amounts);
  }

  /**
   * @notice Transfer with approval check for `operator`
   *
   * This can be used to forward transfers
   */
  function executeSafeTransferBatch(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) public virtual onlyWriter {
    if (from != operator && !isApprovedForAll(from, operator)) {
      revert ERC1155Base__NotOwnerOrApproved();
    }
    _safeTransferBatch(operator, from, to, ids, amounts, data);
  }

  /**
   * @notice Transfer tokens from any account without needing approval
   */
  function executeArbitrarySafeTransferBatch(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) public virtual onlyWriter {
    _safeTransferBatch(_msgSender(), from, to, ids, amounts, data);
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
}