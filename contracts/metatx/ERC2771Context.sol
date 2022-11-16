// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { Context } from "@openzeppelin/contracts/utils/Context.sol";
import { ERC2771Storage } from "./ERC2771Storage.sol";

/**
 * @dev Context variant with support for ERC2771 and multiple trusted forwarders.
 *
 * Derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT)
 */
abstract contract ERC2771Context is Context {
  function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
    return ERC2771Storage.layout().trustedForwarders[forwarder];
  }

  function _setTrustedForwarder(address forwarder, bool state) internal virtual {
    ERC2771Storage.layout().trustedForwarders[forwarder] = state;
  }

  function _msgSender() internal view virtual override returns (address sender) {
    if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
      // The assembly code is more direct than the Solidity version using `abi.decode`.
      /// @solidity memory-safe-assembly
      assembly {
        sender := shr(96, calldataload(sub(calldatasize(), 20)))
      }
    } else {
      return super._msgSender();
    }
  }

  function _msgData() internal view virtual override returns (bytes calldata) {
    if (msg.data.length >= 20 && isTrustedForwarder(msg.sender)) {
      return msg.data[:msg.data.length - 20];
    } else {
      return super._msgData();
    }
  }
}