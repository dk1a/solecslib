// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.17;

// ECS interfaces
import { IWorld } from "@latticexyz/solecs/src/interfaces/IWorld.sol";

// ERC1155 virtual data interfaces
import { ERC1155AccessVData } from "../logic/ERC1155AccessVData.sol";
import { ERC1155BalanceVData } from "../logic/ERC1155BalanceVData.sol";

// ECS components
import { OperatorApprovalsComponent, getOperatorApprovalEntity } from "../components/OperatorApprovalsComponent.sol";
import { BalancesComponent, getBalanceEntity } from "../components/BalancesComponent.sol";

// internal storage for component addresses
import { ERC1155BaseDataComponentsStorage } from "./ERC1155BaseDataComponentsStorage.sol";

/**
 * @title ERC1155Base logic that uses ECS components for data (balances/approvals)
 *
 * @dev IMPORTANT: initialize the components!
 * Init needs component ids, which should be constants defined for the specific ERC1155.
 * Components are assumed to be fully trusted and valid contracts.
 */
abstract contract ERC1155BaseDataComponents is
  ERC1155AccessVData,
  ERC1155BalanceVData
{
  error ERC1155BaseDataComponents__ComponentsNotInitialized();

  /**
   * @dev Initializes components, should be called in constructor/initializer
   */
  function _initERC1155BaseDataComponents(
    IWorld world,
    uint256 balanceComponentId,
    uint256 operatorApprovalsComponentId
  ) internal {
    ERC1155BaseDataComponentsStorage.layout().balancesComponent
      = new BalancesComponent(address(world), balanceComponentId);

    ERC1155BaseDataComponentsStorage.layout().operatorApprovalsComponent
      = new OperatorApprovalsComponent(address(world), operatorApprovalsComponentId);
  }

  /*//////////////////////////////////////////////////////////////
                          OPERATOR APPROVALS
  //////////////////////////////////////////////////////////////*/

  /// @notice Get operatorApprovals component
  function operatorApprovalsComponent() public view returns (OperatorApprovalsComponent comp) {
    comp = ERC1155BaseDataComponentsStorage.layout().operatorApprovalsComponent;
    if (address(comp) == address(0)) {
      revert ERC1155BaseDataComponents__ComponentsNotInitialized();
    }
  }

  // getter
  function _get_operatorApprovals(
    address account,
    address operator
  ) internal view virtual override returns (bool) {
    uint256 entity = getOperatorApprovalEntity(account, operator);
    return operatorApprovalsComponent().getValue(entity);
  }

  // setter
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
  }

  /*//////////////////////////////////////////////////////////////
                              BALANCES
  //////////////////////////////////////////////////////////////*/

  /// @notice Get balances component
  function balancesComponent() public view returns (BalancesComponent comp) {
    comp = ERC1155BaseDataComponentsStorage.layout().balancesComponent;
    if (address(comp) == address(0)) {
      revert ERC1155BaseDataComponents__ComponentsNotInitialized();
    }
  }

  // getter
  function _get_balances(
    address account,
    uint256 id
  ) internal view virtual override returns (uint256) {
    uint256 entity = getBalanceEntity(account, id);
    return balancesComponent().getValue(entity);
  }

  // setter
  function _set_balances(
    address account,
    uint256 id,
    uint256 value
  ) internal virtual override {
    uint256 entity = getBalanceEntity(account, id);
    if (value > 0) {
      balancesComponent().set(entity, value);
    } else {
      balancesComponent().remove(entity);
    }
  }
}