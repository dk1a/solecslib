// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.17;

import { IERC1155 } from "@solidstate/contracts/interfaces/IERC1155.sol";
import { ERC1155BalanceInternal } from "./ERC1155BalanceInternal.sol";
import { ERC1155AccessInternal } from "./ERC1155AccessInternal.sol";

/**
 * @title Storage-agnostic ERC1155 implementation
 * @dev Derived from https://github.com/solidstate-network/solidstate-solidity/ (MIT)
 * and https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT)
 */
abstract contract ERC1155BaseLogic is
  IERC1155,
  ERC1155AccessInternal,
  ERC1155BalanceInternal
{
  /**
   * @inheritdoc IERC1155
   */
  function balanceOf(address account, uint256 id)
    public
    view
    virtual
    returns (uint256)
  {
    return _balanceOf(account, id);
  }

  /**
   * @inheritdoc IERC1155
   */
  function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
    public
    view
    virtual
    returns (uint256[] memory)
  {
    if (accounts.length != ids.length) revert ERC1155Base__ArrayLengthMismatch();

    uint256[] memory batchBalances = new uint256[](accounts.length);

    for (uint256 i; i < accounts.length; i++) {
      batchBalances[i] = _balanceOf(accounts[i], ids[i]);
    }

    return batchBalances;
  }

  /**
   * @inheritdoc IERC1155
   */
  function isApprovedForAll(address account, address operator) public view returns (bool) {
    return _isApprovedForAll(account, operator);
  }

  /**
   * @inheritdoc IERC1155
   */
  function setApprovalForAll(address operator, bool status) public {
    _setApprovalForAll(operator, status);
  }

  /**
   * @inheritdoc IERC1155
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) public virtual {
    _requireOwnerOrApproved(from);
    _safeTransfer(_msgSender(), from, to, id, amount, data);
  }

  /**
    * @inheritdoc IERC1155
    */
  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) public virtual {
    _requireOwnerOrApproved(from);
    _safeTransferBatch(_msgSender(), from, to, ids, amounts, data);
  }
}