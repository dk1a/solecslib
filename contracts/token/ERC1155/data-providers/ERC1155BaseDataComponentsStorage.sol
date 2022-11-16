// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { BalanceComponent } from "../components/BalanceComponent.sol";
import { OperatorApprovalComponent } from "../components/OperatorApprovalComponent.sol";

library ERC1155BaseDataComponentsStorage {
  bytes32 internal constant STORAGE_SLOT =
    keccak256('solecslib.contracts.storage.ERC1155BaseDataComponents');

  struct Layout {
    BalanceComponent balanceComponent;
    OperatorApprovalComponent operatorApprovalComponent;
  }

  function layout() internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      l.slot := slot
    }
  }
}