// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.17;

import { IERC1155Internal } from "@solidstate/contracts/interfaces/IERC1155Internal.sol";
import { Context } from "@openzeppelin/contracts/utils/Context.sol";

import { ERC1155AccessVData } from "./ERC1155AccessVData.sol";

/**
 * @title Storage-agnostic ERC1155 operator approval internals
 * @dev Derived from https://github.com/solidstate-network/solidstate-solidity/ (MIT)
 * and https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT)
 */
abstract contract ERC1155AccessInternal is
  Context,
  IERC1155Internal,
  ERC1155AccessVData
{
  error ERC1155Base__NotOwnerOrApproved();
  error ERC1155Base__SelfApproval();

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