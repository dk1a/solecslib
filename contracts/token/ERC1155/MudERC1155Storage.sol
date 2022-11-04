// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.17;

import { BalancesComponent } from "./components/BalancesComponent.sol";
import { OperatorApprovalsComponent } from "./components/OperatorApprovalsComponent.sol";

library MudERC1155Storage {
  bytes32 internal constant STORAGE_SLOT =
    keccak256('mud-erc1155.contracts.storage.MudERC1155');

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