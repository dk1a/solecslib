// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.17;

/**
 * @title Virtual data abstraction, like an internal interface
 */
abstract contract ERC1155BaseVData {
  /*//////////////////////////////////////////////////////////////
                            BALANCE
  //////////////////////////////////////////////////////////////*/

  function _get_balance(
    address account,
    uint256 id
  ) internal view virtual returns (uint256);

  function _set_balance(
    address account,
    uint256 id,
    uint256 value
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
}