// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { Ownable } from "@solidstate/contracts/access/ownable/Ownable.sol";
import { OwnableAndWriteAccessStorage } from "./OwnableAndWriteAccessStorage.sol";

/**
 * @title Simplified access control, with owner and authorized writers rather than full roles
 */
abstract contract OwnableAndWriteAccess is Ownable {
  error OwnableAndWriteAccess__NotWriter();

  function writeAccess(address operator) public view returns (bool) {
    return OwnableAndWriteAccessStorage.layout().writeAccess[operator]
      || operator == owner();
  }

  /** Revert if caller does not have write access to this component */
  modifier onlyWriter() {
    if (!writeAccess(msg.sender)) {
      revert OwnableAndWriteAccess__NotWriter();
    }
    _;
  }

  /**
   * Grant write access to the given address.
   * Can only be called by the owner.
   * @param writer Address to grant write access to.
   */
  function authorizeWriter(address writer) public onlyOwner {
    OwnableAndWriteAccessStorage.layout().writeAccess[writer] = true;
  }

  /**
   * Revoke write access from the given address.
   * Can only be called by the owner.
   * @param writer Address to revoke write access.
   */
  function unauthorizeWriter(address writer) public onlyOwner {
    delete OwnableAndWriteAccessStorage.layout().writeAccess[writer];
  }
}
