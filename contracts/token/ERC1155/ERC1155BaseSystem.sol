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
import { BalancesComponent, getBalanceEntity } from "./components/BalancesComponent.sol";
import { OperatorApprovalsComponent, getOperatorApprovalEntity } from "./components/OperatorApprovalsComponent.sol";

// ERC2771 (forwarding)
import { Context } from "@openzeppelin/contracts/utils/Context.sol";
import { ERC2771Context } from "../../metatx/ERC2771Context.sol";

// ERC1155 logic and data provider
import { ERC1155BaseLogic } from "./logic/ERC1155BaseLogic.sol";
import { ERC1155BaseDataComponents } from "./data-providers/ERC1155BaseDataComponents.sol";

import { ERC1155AccessInternal } from "./logic/ERC1155AccessInternal.sol";
import { ERC1155BalanceInternal } from "./logic/ERC1155BalanceInternal.sol";

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
//ERC1155Base_ProviderECS,
abstract contract ERC1155BaseSystem is
  ERC2771Context,
  ERC165,
  ERC1155BaseDataComponents,
  ERC1155BaseLogic,
  System
{
  using ERC165Storage for ERC165Storage.Layout;

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

  // TODO should execute have a default implementation?
  /*function execute(bytes memory) public virtual override returns (bytes memory) {
    revert('PH');
  }*/

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

  

  // OPERATOR APPROVAL
 /* function operatorApprovalsComponent() public view returns (OperatorApprovalsComponent) {
    return ERC1155BaseSystemStorage.layout().operatorApprovalsComponent;
  }

  // access getter
  function _get_operatorApprovals(
    address account,
    address operator
  ) internal view virtual override returns (bool) {
    uint256 entity = getOperatorApprovalEntity(account, operator);
    return operatorApprovalsComponent().getValue(entity);
  }

  // access setter
  function _set_operatorApprovals(
    address account,
    address operator,
    bool value
  ) internal virtual override {
    uint256 entity = getOperatorApprovalEntity(account, operator);
    if (value) {
      operatorApprovalsComponent().set(entity);
    } else {
      operatorApprovalsComponent().remove(entity);
    }
  }*/
}