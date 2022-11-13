// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.17;

/**
 * @title Virtual data abstraction, like an internal interface
 */
abstract contract ERC1155AccessVData {
  /**
   * @dev Virtual getter, must be overridden
   */
  function _get_operatorApprovals(
    address account,
    address operator
  ) internal view virtual returns (bool);

  /**
   * @dev Virtual setter, must be overridden
   */
  function _set_operatorApprovals(
    address account,
    address operator,
    bool value
  ) internal virtual;
}