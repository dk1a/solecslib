// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

// ECS interfaces
import { IWorld } from "@latticexyz/solecs/src/interfaces/IWorld.sol";

// ERC721 virtual data interfaces
import { ERC721BaseVData } from "../logic/ERC721BaseVData.sol";

// ECS components
import { OwnershipComponent } from "../components/OwnershipComponent.sol";
import { OperatorApprovalComponent, getOperatorApprovalEntity } from "../components/OperatorApprovalComponent.sol";
import { TokenApprovalComponent } from "../components/TokenApprovalComponent.sol";

// internal storage for component addresses
import { ERC721BaseDataComponentsStorage } from "./ERC721BaseDataComponentsStorage.sol";

/**
 * @title ERC721Base logic that uses ECS components for data (ownership/approvals)
 *
 * @dev IMPORTANT: initialize the components!
 * Init needs component ids, which should be constants defined for the specific ERC721.
 * Components are assumed to be fully trusted and valid contracts.
 */
abstract contract ERC721BaseDataComponents is ERC721BaseVData {
  error ERC721BaseDataComponents__ComponentsNotInitialized();
  error ERC721BaseDataComponents__AlreadyInitialized();

  /**
   * @dev Initializes components, should be called in constructor/initializer
   */
  function __ERC721BaseDataComponents_init(
    IWorld world,
    uint256 ownershipComponentId,
    uint256 operatorApprovalComponentId,
    uint256 tokenApprovalComponentId
  ) internal {
    ERC721BaseDataComponentsStorage.Layout storage l = ERC721BaseDataComponentsStorage.layout();

    // Prevents accidental change of components
    if (address(l.ownershipComponent) != address(0)) revert ERC721BaseDataComponents__AlreadyInitialized();

    l.ownershipComponent = new OwnershipComponent(address(world), ownershipComponentId);
    l.operatorApprovalComponent = new OperatorApprovalComponent(address(world), operatorApprovalComponentId);
    l.tokenApprovalComponent = new TokenApprovalComponent(address(world), tokenApprovalComponentId);
  }

  /*//////////////////////////////////////////////////////////////
                              OWNERSHIP
  //////////////////////////////////////////////////////////////*/

  /// @notice Get ownership component
  function ownershipComponent() public view returns (OwnershipComponent comp) {
    comp = ERC721BaseDataComponentsStorage.layout().ownershipComponent;
    if (address(comp) == address(0)) {
      revert ERC721BaseDataComponents__ComponentsNotInitialized();
    }
  }

  // getter
  function _get_ownerOf(
    uint256 tokenId
  ) internal view virtual override returns (address) {
    return ownershipComponent().getValue(tokenId);
  }

  // getter
  function _get_balanceOf(
    address account
  ) internal view virtual override returns (uint256) {
    return ownershipComponent().getEntitiesWithValueLength(account);
  }

  // setter
  function _set_tokenOwner(
    address account,
    uint256 tokenId
  ) internal virtual override {
    if (account != address(0)) {
      ownershipComponent().set(tokenId, account);
    } else {
      ownershipComponent().remove(tokenId);
    }
  }

  /*//////////////////////////////////////////////////////////////
                          OPERATOR APPROVAL
  //////////////////////////////////////////////////////////////*/

  /// @notice Get operatorApproval component
  function operatorApprovalComponent() public view returns (OperatorApprovalComponent comp) {
    comp = ERC721BaseDataComponentsStorage.layout().operatorApprovalComponent;
    if (address(comp) == address(0)) {
      revert ERC721BaseDataComponents__ComponentsNotInitialized();
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
                            TOKEN APPROVAL
  //////////////////////////////////////////////////////////////*/

  /// @notice Get tokenApproval component
  function tokenApprovalComponent() public view returns (TokenApprovalComponent comp) {
    comp = ERC721BaseDataComponentsStorage.layout().tokenApprovalComponent;
    if (address(comp) == address(0)) {
      revert ERC721BaseDataComponents__ComponentsNotInitialized();
    }
  }

  // getter
  function _get_tokenApproval(
    uint256 tokenId
  ) internal view virtual override returns (address) {
    return tokenApprovalComponent().getValue(tokenId);
  }

  // setter
  function _set_tokenApproval(
    uint256 tokenId,
    address operator
  ) internal virtual override {
    if (operator != address(0)) {
      tokenApprovalComponent().set(tokenId, operator);
    } else {
      tokenApprovalComponent().remove(tokenId);
    }
  }
}