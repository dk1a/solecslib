// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.17;

import { OwnershipComponent } from "../components/OwnershipComponent.sol";
import { OperatorApprovalComponent } from "../components/OperatorApprovalComponent.sol";
import { TokenApprovalComponent } from "../components/TokenApprovalComponent.sol";

library ERC721BaseDataComponentsStorage {
  bytes32 internal constant STORAGE_SLOT =
    keccak256('solecslib.contracts.storage.ERC721BaseDataComponents');

  struct Layout {
    OwnershipComponent ownershipComponent;
    OperatorApprovalComponent operatorApprovalComponent;
    TokenApprovalComponent tokenApprovalComponent;
  }

  function layout() internal pure returns (Layout storage l) {
    bytes32 slot = STORAGE_SLOT;
    assembly {
      l.slot := slot
    }
  }
}