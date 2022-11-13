// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.17;

/**
 * @title Virtual data abstraction, like an internal interface
 */
abstract contract ERC1155BalanceVData {
  /**
   * @dev Virtual getter, must be overridden
   */
  function _get_balances(
    address account,
    uint256 id
  ) internal view virtual returns (uint256);

  /**
   * @dev Virtual setter, must be overridden
   */
  function _set_balances(
    address account,
    uint256 id,
    uint256 value
  ) internal virtual;
}