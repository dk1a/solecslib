// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/**
 * @dev Helps avoid entity clashes which can arise from naive hashing of common data
 *
 * e.g. equipment and equipment slot both named "Hat", where entity = hashed(name)
 */
function entityFromHash(string memory namespace, bytes memory data) pure returns (uint256) {
  return uint256(keccak256(abi.encode(
    // keccak256 costs less than encoding arrays
    keccak256("entityFromHash::"),
    keccak256(bytes(namespace)),
    keccak256(data))
  ));
}