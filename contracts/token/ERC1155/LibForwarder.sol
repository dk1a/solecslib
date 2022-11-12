// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.17;

import { AddressUtils } from "@solidstate/contracts/utils/AddressUtils.sol";
import { IERC1155 } from "@solidstate/contracts/interfaces/IERC1155.sol";
import { ISystem } from "@latticexyz/solecs/src/interfaces/ISystem.sol";

/**
 * @title Helper functions to forward sender to MudERC1155
 */
library LibForwarder {
  function execute(
    ISystem target,
    address msgSender,

    bytes memory arguments
  ) internal returns (bytes memory) {
    return target.execute(abi.encodePacked(arguments, msgSender));
  }

  function functionCall(
    address target,
    address msgSender,
    bytes4 selector,
    bytes memory arguments
  ) internal returns (bytes memory) {
    return AddressUtils.functionCall(
      target,
      abi.encodePacked(
        // not encodeWithSelector because arguments are already encoded
        selector,
        arguments,
        // forward msg.sender as last 20 bytes
        msgSender
      )
    );
  }

  function safeTransferFrom(
    IERC1155 target,
    address msgSender,

    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) internal {
    functionCall(
      address(target),
      msgSender,
      IERC1155.safeTransferFrom.selector,
      abi.encode(from, to, id, amount, data)
    );
  }

  function safeBatchTransferFrom(
    IERC1155 target,
    address msgSender,

    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal {
    functionCall(
      address(target),
      msgSender,
      IERC1155.safeBatchTransferFrom.selector,
      abi.encode(from, to, ids, amounts, data)
    );
  }

  function setApprovalForAll(
    IERC1155 target,
    address msgSender,

    address operator,
    bool status
  ) internal {
    functionCall(
      address(target),
      msgSender,
      IERC1155.setApprovalForAll.selector,
      abi.encode(operator, status)
    );
  }
}