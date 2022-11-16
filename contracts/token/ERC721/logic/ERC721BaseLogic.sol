// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { IERC721 } from "@solidstate/contracts/interfaces/IERC721.sol";
import { ERC721BaseInternal } from "./ERC721BaseInternal.sol";

/**
 * @title Storage-agnostic ERC721 implementation
 * @dev Derived from https://github.com/solidstate-network/solidstate-solidity/ (MIT)
 * and https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT)
 */
abstract contract ERC721BaseLogic is
  IERC721,
  ERC721BaseInternal
{
  /**
   * @inheritdoc IERC721
   */
  function balanceOf(address account) public view override returns (uint256) {
    return _balanceOf(account);
  }

  /**
   * @inheritdoc IERC721
   */
  function ownerOf(uint256 tokenId) public view override returns (address) {
    return _ownerOf(tokenId);
  }

  /**
   * @inheritdoc IERC721
   */
  function getApproved(uint256 tokenId) public view override returns (address) {
    return _getApproved(tokenId);
  }

  /**
   * @inheritdoc IERC721
   */
  function isApprovedForAll(address account, address operator) public view override returns (bool) {
    return _isApprovedForAll(account, operator);
  }

  /**
   * @inheritdoc IERC721
   */
  function approve(address operator, uint256 tokenId) public payable virtual override {
    address owner = ownerOf(tokenId);
    if (operator == owner) revert ERC721Base__SelfApproval();
    if (_msgSender() != owner && !isApprovedForAll(owner, msg.sender)) {
      revert ERC721Base__NotOwnerOrApproved();
    }
    _approve(operator, tokenId);
  }

  /**
   * @inheritdoc IERC721
   */
  function setApprovalForAll(address operator, bool status) public virtual override {
    if (operator == _msgSender()) revert ERC721Base__SelfApproval();
    _set_operatorApproval(_msgSender(), operator, status);
    emit ApprovalForAll(_msgSender(), operator, status);
  }

  /**
   * @inheritdoc IERC721
   */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public payable virtual override {
    _requireApprovedOrOwner(tokenId);
    _transfer(from, to, tokenId);
  }

  /**
    * @inheritdoc IERC721
    */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public payable virtual override {
    safeTransferFrom(from, to, tokenId, '');
  }

  /**
   * @inheritdoc IERC721
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public payable {
    _requireApprovedOrOwner(tokenId);
    _safeTransfer(_msgSender(), from, to, tokenId, data);
  }
}