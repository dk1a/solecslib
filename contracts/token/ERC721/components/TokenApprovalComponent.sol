// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { BareComponent } from "@latticexyz/solecs/src/BareComponent.sol";
import { LibTypes } from "@latticexyz/solecs/src/LibTypes.sol";

contract TokenApprovalComponent is BareComponent {
  constructor(address world, uint256 id) BareComponent(world, id) {}

  function getSchema() public pure override returns (string[] memory keys, LibTypes.SchemaValue[] memory values) {
    keys = new string[](1);
    values = new LibTypes.SchemaValue[](1);

    keys[0] = "value";
    values[0] = LibTypes.SchemaValue.ADDRESS;
  }

  function set(uint256 entity, address operator) public {
    set(entity, abi.encode(operator));
  }

  function getValue(uint256 entity) public view returns (address) {
    bytes memory rawValue = getRawValue(entity);
    if (rawValue.length > 0) {
      return abi.decode(rawValue, (address));
    } else {
      return address(0);
    }
  }
}