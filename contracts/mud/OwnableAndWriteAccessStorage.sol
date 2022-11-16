// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.17;

library OwnableAndWriteAccessStorage {
  bytes32 internal constant STORAGE_SLOT =
    keccak256('solecslib.contracts.storage.OwnableAndWriteAccess');

  struct Layout {
    /** Addresses with write access */
    mapping(address => bool) writeAccess;
  }

  function layout() internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      l.slot := slot
    }
  }
}