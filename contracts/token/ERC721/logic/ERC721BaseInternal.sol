// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.17;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { Context } from "@openzeppelin/contracts/utils/Context.sol";
import { IERC721Receiver } from '@solidstate/contracts/interfaces/IERC721Receiver.sol';
import { IERC721Internal } from "@solidstate/contracts/interfaces/IERC721Internal.sol";

import { ERC721BaseVData } from "./ERC721BaseVData.sol";

abstract contract ERC721BaseInternal is
  Context,
  IERC721Internal,
  ERC721BaseVData
{
  error ERC721Base__NotOwnerOrApproved();
  error ERC721Base__SelfApproval();
  error ERC721Base__BalanceQueryZeroAddress();
  error ERC721Base__ERC721ReceiverNotImplemented();
  error ERC721Base__InvalidOwner();
  error ERC721Base__MintToZeroAddress();
  error ERC721Base__NonExistentToken();
  error ERC721Base__NotTokenOwner();
  error ERC721Base__TokenAlreadyMinted();
  error ERC721Base__TransferToZeroAddress();

  function _balanceOf(address account) internal view virtual returns (uint256) {
    if (account == address(0)) revert ERC721Base__BalanceQueryZeroAddress();
    return _get_balanceOf(account);
  }

  function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
    address owner = _get_ownerOf(tokenId);
    if (owner == address(0)) revert ERC721Base__InvalidOwner();
    return owner;
  }

  function _getApproved(uint256 tokenId) internal view virtual returns (address) {
    if (_get_ownerOf(tokenId) == address(0)) revert ERC721Base__NonExistentToken();

    return _get_tokenApproval(tokenId);
  }

  function _isApprovedForAll(
    address account,
    address operator
  ) internal view virtual returns (bool) {
    return _get_operatorApproval(account, operator);
  }

  function _isApprovedOrOwner(
    address spender,
    uint256 tokenId
  ) internal view virtual returns (bool) {
    address owner = _get_ownerOf(tokenId);
    if (owner == address(0)) revert ERC721Base__NonExistentToken();

    return (spender == owner ||
      _getApproved(tokenId) == spender ||
      _isApprovedForAll(owner, spender));
  }

  function _requireApprovedOrOwner(uint256 tokenId) internal view {
    if (!_isApprovedOrOwner(_msgSender(), tokenId)) revert ERC721Base__NotOwnerOrApproved();
  }

  function _mint(address to, uint256 tokenId) internal virtual {
    if (to == address(0)) revert ERC721Base__MintToZeroAddress();

    if (_get_ownerOf(tokenId) != address(0)) revert ERC721Base__TokenAlreadyMinted();

    _beforeTokenTransfer(address(0), to, tokenId);

    _set_tokenOwner(to, tokenId);

    emit Transfer(address(0), to, tokenId);
  }

  function _safeMint(address to, uint256 tokenId) internal virtual {
    _safeMint(to, tokenId, '');
  }

  function _safeMint(
    address to,
    uint256 tokenId,
    bytes memory data
  ) internal virtual {
    _mint(to, tokenId);

    _doSafeTransferAcceptanceCheck(
      _msgSender(),
      address(0),
      to,
      tokenId,
      data
    );
  }

  function _burn(uint256 tokenId) internal virtual {
    address owner = _ownerOf(tokenId);

    _beforeTokenTransfer(owner, address(0), tokenId);

    _approve(address(0), tokenId);

    _set_tokenOwner(address(0), tokenId);

    emit Transfer(owner, address(0), tokenId);
  }

  function _transfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual {
    if (_ownerOf(tokenId) != from) revert ERC721Base__NotTokenOwner();
    if (to == address(0)) revert ERC721Base__TransferToZeroAddress();

    _beforeTokenTransfer(from, to, tokenId);

    _approve(address(0), tokenId);

    _set_tokenOwner(to, tokenId);

    emit Transfer(from, to, tokenId);
  }

  function _safeTransfer(
    address operator,
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) internal virtual {
    _transfer(from, to, tokenId);

    _doSafeTransferAcceptanceCheck(
      operator,
      from,
      to,
      tokenId,
      data
    );
  }

  function _approve(address operator, uint256 tokenId) internal virtual {
    _set_tokenApproval(tokenId, operator);
    emit Approval(_ownerOf(tokenId), operator, tokenId);
  }

  function _doSafeTransferAcceptanceCheck(
    address operator,
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) internal virtual {
    // TODO this could be synced with how ERC1155 does this (which is better imo),
    // but then you'd need to rewrite some imported solidstate spec tests
    if (Address.isContract(to)) {
      try IERC721Receiver(to).onERC721Received(operator, from, tokenId, data) returns (bytes4 response) {
        if (response != IERC721Receiver.onERC721Received.selector) {
          revert ERC721Base__ERC721ReceiverNotImplemented();
        }
      } catch Error(string memory reason) {
        revert(reason);
      } catch {
        revert("ERC721: transfer to non ERC721Receiver implementer");
      }
    }
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual {}
}