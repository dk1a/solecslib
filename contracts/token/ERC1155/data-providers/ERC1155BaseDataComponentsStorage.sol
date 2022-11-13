// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.17;

import { BalancesComponent } from "../components/BalancesComponent.sol";
import { OperatorApprovalsComponent } from "../components/OperatorApprovalsComponent.sol";

library ERC1155BaseDataComponentsStorage {
  bytes32 internal constant STORAGE_SLOT =
    keccak256('solecslib.contracts.storage.ERC1155BaseDataComponents');

  struct Layout {
    BalancesComponent balancesComponent;
    OperatorApprovalsComponent operatorApprovalsComponent;
  }

  function layout() internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      l.slot := slot
    }
  }
}