// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/**
 * @title Virtual data abstraction, like an internal interface
 */
abstract contract ERC721BaseVData {
  /*//////////////////////////////////////////////////////////////
                            OWNERSHIP
  //////////////////////////////////////////////////////////////*/

  function _get_ownerOf(
    uint256 tokenId
  ) internal view virtual returns (address);

  function _get_balanceOf(
    address account
  ) internal view virtual returns (uint256);

  function _set_tokenOwner(
    address account,
    uint256 tokenId
  ) internal virtual;

  /*//////////////////////////////////////////////////////////////
                          OPERATOR APPROVAL
  //////////////////////////////////////////////////////////////*/

  function _get_operatorApproval(
    address account,
    address operator
  ) internal view virtual returns (bool);

  function _set_operatorApproval(
    address account,
    address operator,
    bool value
  ) internal virtual;

  /*//////////////////////////////////////////////////////////////
                            TOKEN APPROVAL
  //////////////////////////////////////////////////////////////*/

  function _get_tokenApproval(
    uint256 tokenId
  ) internal view virtual returns (address);

  function _set_tokenApproval(
    uint256 tokenId,
    address operator
  ) internal virtual;
}