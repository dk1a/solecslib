// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

// ECS interfaces
import { IWorld } from "@latticexyz/solecs/src/interfaces/IWorld.sol";

// ERC1155 virtual data interfaces
import { ERC1155BaseVData } from "../logic/ERC1155BaseVData.sol";

// ECS components
import { OperatorApprovalComponent, getOperatorApprovalEntity } from "../components/OperatorApprovalComponent.sol";
import { BalanceComponent, getBalanceEntity } from "../components/BalanceComponent.sol";

// internal storage for component addresses
import { ERC1155BaseDataComponentsStorage } from "./ERC1155BaseDataComponentsStorage.sol";

/**
 * @title ERC1155Base logic that uses ECS components for data (balance/approval)
 *
 * @dev IMPORTANT: initialize the components!
 * Init needs component ids, which should be constants defined for the specific ERC1155.
 * Components are assumed to be fully trusted and valid contracts.
 */
abstract contract ERC1155BaseDataComponents is ERC1155BaseVData {
  error ERC1155BaseDataComponents__ComponentsNotInitialized();
  error ERC1155BaseDataComponents__AlreadyInitialized();

  /**
   * @dev Initializes components, should be called in constructor/initializer
   */
  function __ERC1155BaseDataComponents_init(
    IWorld world,
    uint256 balanceComponentId,
    uint256 operatorApprovalComponentId
  ) internal {
    ERC1155BaseDataComponentsStorage.Layout storage l = ERC1155BaseDataComponentsStorage.layout();

    // Prevents accidental change of components
    if (address(l.balanceComponent) != address(0)) revert ERC1155BaseDataComponents__AlreadyInitialized();

    l.balanceComponent = new BalanceComponent(address(world), balanceComponentId);
    l.operatorApprovalComponent = new OperatorApprovalComponent(address(world), operatorApprovalComponentId);
  }

  /*//////////////////////////////////////////////////////////////
                          OPERATOR APPROVAL
  //////////////////////////////////////////////////////////////*/

  /// @notice Get operatorApproval component
  function operatorApprovalComponent() public view returns (OperatorApprovalComponent comp) {
    comp = ERC1155BaseDataComponentsStorage.layout().operatorApprovalComponent;
    if (address(comp) == address(0)) {
      revert ERC1155BaseDataComponents__ComponentsNotInitialized();
    }
  }

  // getter
  function _get_operatorApproval(
    address account,
    address operator
  ) internal view virtual override returns (bool) {
    uint256 entity = getOperatorApprovalEntity(account, operator);
    return operatorApprovalComponent().getValue(entity);
  }

  // setter
  function _set_operatorApproval(
    address account,
    address operator,
    bool value
  ) internal virtual override {
    uint256 entity = getOperatorApprovalEntity(account, operator);
    if (value) {
      operatorApprovalComponent().set(entity);
    } else {
      operatorApprovalComponent().remove(entity);
    }
  }

  /*//////////////////////////////////////////////////////////////
                              BALANCE
  //////////////////////////////////////////////////////////////*/

  /// @notice Get balance component
  function balanceComponent() public view returns (BalanceComponent comp) {
    comp = ERC1155BaseDataComponentsStorage.layout().balanceComponent;
    if (address(comp) == address(0)) {
      revert ERC1155BaseDataComponents__ComponentsNotInitialized();
    }
  }

  // getter
  function _get_balance(
    address account,
    uint256 id
  ) internal view virtual override returns (uint256) {
    uint256 entity = getBalanceEntity(account, id);
    return balanceComponent().getValue(entity);
  }

  // setter
  function _set_balance(
    address account,
    uint256 id,
    uint256 value
  ) internal virtual override {
    uint256 entity = getBalanceEntity(account, id);
    if (value > 0) {
      balanceComponent().set(entity, value);
    } else {
      balanceComponent().remove(entity);
    }
  }
}