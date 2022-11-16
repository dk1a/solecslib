// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

library ERC2771Storage {
  bytes32 internal constant STORAGE_SLOT =
    keccak256('solecslib.contracts.storage.ERC2771');

  struct Layout {
    mapping(address => bool) trustedForwarders;
  }

  function layout() internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      l.slot := slot
    }
  }
}