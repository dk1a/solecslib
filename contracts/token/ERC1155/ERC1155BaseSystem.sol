// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.17;

// erc165
import { ERC165, IERC165 } from "@solidstate/contracts/introspection/ERC165.sol";
import { ERC165Storage } from "@solidstate/contracts/introspection/ERC165Storage.sol";
import { IERC1155 } from "@solidstate/contracts/interfaces/IERC1155.sol";
import { ISystem } from "@latticexyz/solecs/src/interfaces/ISystem.sol";

// ECS
import { IWorld } from "@latticexyz/solecs/src/interfaces/IWorld.sol";
import { System } from "@latticexyz/solecs/src/System.sol";

// ERC2771 (forwarding)
import { Context } from "@openzeppelin/contracts/utils/Context.sol";
import { ERC2771Context } from "../../metatx/ERC2771Context.sol";

// ERC1155 logic and data provider
import { ERC1155BaseLogic } from "./logic/ERC1155BaseLogic.sol";
import { ERC1155BaseDataComponents } from "./data-providers/ERC1155BaseDataComponents.sol";

enum ERC1155ExecuteType {
  SAFE_MINT_BATCH,
  BURN_BATCH,
  SAFE_TRANSFER_BATCH,
  ARBITRARY_SAFE_TRANSFER_BATCH
}

/**
 * @title ERC1155 and ECS System, with components and msg.sender forwarding.
 * @dev ALL balance/approval component changes MUST be forwarded through this system.
 * 
 * See ERC1155BaseSystemSimple for a minimal implementation without components and forwarding.
 *
 * TODO no uri metadata here (which is fine for base IERC1155), maybe make an optional extension
 * TODO same thing for totalSupply and enumeration
 * 
 * 
 * Notes:
 * I don't like other systems using this system instead of components for writes;
 * but an event component can't be just a component because it must have all the ERC1155 methods;
 * components potentially calling systems is way worse than systems calling systems;
 * violating ERC1155 standard makes this whole thing pointless;
 * using it like an external utility would basically be an unregistered system;
 * it can't be just a library - it has events and is bound to specific components;
 */
abstract contract ERC1155BaseSystem is
  ERC2771Context,
  ERC165,
  ERC1155BaseDataComponents,
  ERC1155BaseLogic,
  System
{
  using ERC165Storage for ERC165Storage.Layout;

  error ERC1155BaseSystem__NotTrustedExecutor();
  error ERC1155BaseSystem__InvalidExecuteType();

  // TODO diamond-compatible version?
  constructor(
    IWorld _world,
    address _components,
    uint256 balanceComponentId,
    uint256 operatorApprovalsComponentId
  ) System(_world, _components) {
    // create components
    // (they're tightly coupled to this system, so making them separately isn't useful)
    _initERC1155BaseDataComponents(world, balanceComponentId, operatorApprovalsComponentId);

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
   * @dev ALL writer systems should be made trusted forwarders,
   * isTrustedForwarder can then be used to also check who can call execute.
   * 
   * IMPORTANT: use LibForwarder in forwarders to correctly pass msg.sender
   *
   * (this is not necessary if callers don't need to forward msg.sender,
   * but then you should implement custom access control for them)
   */
  function setTrustedForwarder(address forwarder, bool state) public virtual onlyOwner {
    _setTrustedForwarder(forwarder, state);
  }

  /**
   * @dev Requirement to execute special methods like mint, burn, arbitrary transfer.
   * Reuses trusted forwarder to also be trusted executor, which is fine for Systems.
   * But if you want to also use gas relays, you should separate trusted executors!
   */
  function _requireTrustedExecutor() internal virtual view {
    if (!isTrustedForwarder(msg.sender)) revert ERC1155BaseSystem__NotTrustedExecutor();
  }

  /**
   * @notice Does an action based on ERC1155ExecuteType
   * @dev The actions also have individual methods with specific arguments.
   * Only for trusted forwarders; except SAFE_TRANSFER_BATCH,
   * which just calls safeBatchTransferFrom with its usual requirements
   */
  function execute(bytes memory args) public virtual override returns (bytes memory) {
    _requireTrustedExecutor();
    
    (ERC1155ExecuteType execType, bytes memory innerArgs)
      = abi.decode(args, (ERC1155ExecuteType, bytes));

    // mint
    if (execType == ERC1155ExecuteType.SAFE_MINT_BATCH) {
      (
        address account,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
      ) = abi.decode(innerArgs, (address, uint256[], uint256[], bytes));
      executeSafeMintBatch(account, ids, amounts, data);

    // burn
    } else if (execType == ERC1155ExecuteType.BURN_BATCH) {
      (
        address account,
        uint256[] memory ids,
        uint256[] memory amounts
      ) = abi.decode(innerArgs, (address, uint256[], uint256[]));
      executeBurnBatch(account, ids, amounts);

    // transfer (approval-checked)
    } else if (execType == ERC1155ExecuteType.SAFE_TRANSFER_BATCH) {
      (
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
      ) = abi.decode(innerArgs, (address, address, uint256[], uint256[], bytes));
      safeBatchTransferFrom(from, to, ids, amounts, data);

    // transfer (from arbitrary account)
    } else if (execType == ERC1155ExecuteType.ARBITRARY_SAFE_TRANSFER_BATCH) {
      (
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
      ) = abi.decode(innerArgs, (address, address, address, uint256[], uint256[], bytes));
      executeArbitrarySafeTransferBatch(operator, from, to, ids, amounts, data);

    } else {
      revert ERC1155BaseSystem__InvalidExecuteType();
    }

    return '';
  }

  /**
   * @notice Mint tokens to any account
   * @dev only for trusted forwarders
   */
  function executeSafeMintBatch(
    address account,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) public virtual {
    _requireTrustedExecutor();
    _safeMintBatch(account, ids, amounts, data);
  }

  /**
   * @notice Burn tokens from any account
   * @dev only for trusted forwarders
   */
  function executeBurnBatch(
    address account,
    uint256[] memory ids,
    uint256[] memory amounts
  ) public virtual {
    _requireTrustedExecutor();
    _burnBatch(account, ids, amounts);
  }

  /**
   * @notice Transfer tokens from any account without needing approval
   * @dev only for trusted forwarders
   */
  function executeArbitrarySafeTransferBatch(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) public virtual {
    _requireTrustedExecutor();
    _safeTransferBatch(operator, from, to, ids, amounts, data);
  }

  // CONTEXT
  // trusted forwarding
  function _msgSender()
    internal
    view
    virtual
    override(ERC2771Context, Context)
    returns (address sender)
  {
    return super._msgSender();
  }

  // trusted forwarding
  function _msgData()
    internal
    view
    virtual
    override(ERC2771Context, Context)
    returns (bytes calldata)
  {
    return super._msgData();
  }
}