// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.17;

import { IERC1155Internal } from "@solidstate/contracts/interfaces/IERC1155Internal.sol";
import { Context } from "@openzeppelin/contracts/utils/Context.sol";

/**
 * @title Storage-agnostic ERC1155 operator approval internals
 * @dev Derived from https://github.com/solidstate-network/solidstate-solidity/ (MIT)
 * and https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT)
 */
abstract contract ERC1155AccessInternal is Context, IERC1155Internal {
  error ERC1155Base__NotOwnerOrApproved();
  error ERC1155Base__SelfApproval();

  /**
   * @dev Storage-agnostic getter, must be overridden
   */
  function _get_operatorApprovals(
    address account,
    address operator
  ) internal view virtual returns (bool);

  /**
   * @dev Storage-agnostic setter, must be overridden
   */
  function _set_operatorApprovals(
    address account,
    address operator,
    bool value
  ) internal virtual;

  // ERC1155 METHODS

  function _isApprovedForAll(
    address account,
    address operator
  ) internal view virtual returns (bool) {
    return _get_operatorApprovals(account, operator);
  }

  function _setApprovalForAll(address operator, bool status) internal virtual {
    if (_msgSender() == operator) revert ERC1155Base__SelfApproval();
    _set_operatorApprovals(_msgSender(), operator, status);
    emit ApprovalForAll(_msgSender(), operator, status);
  }

  function _requireOwnerOrApproved(address from) internal view {
    if (from != _msgSender() && !_isApprovedForAll(from, _msgSender())) {
      revert ERC1155Base__NotOwnerOrApproved();
    }
  }
}