// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { BareComponent } from "@latticexyz/solecs/src/BareComponent.sol";
import { LibTypes } from "@latticexyz/solecs/src/LibTypes.sol";

/**
 * @dev Operator approval entity = hashed(account, operator)
 */
function getOperatorApprovalEntity(address account, address operator) pure returns (uint256) {
  return uint256(keccak256(abi.encode(account, operator)));
}

contract OperatorApprovalComponent is BareComponent {
  constructor(address world, uint256 id) BareComponent(world, id) {}

  function getSchema() public pure override returns (string[] memory keys, LibTypes.SchemaValue[] memory values) {
    keys = new string[](1);
    values = new LibTypes.SchemaValue[](1);

    keys[0] = "value";
    values[0] = LibTypes.SchemaValue.BOOL;
  }

  function set(uint256 entity) public {
    set(entity, abi.encode(true));
  }

  function getValue(uint256 entity) public view returns (bool) {
    bytes memory rawValue = getRawValue(entity);
    if (rawValue.length > 0) {
      return abi.decode(rawValue, (bool));
    } else {
      return false;
    }
  }
}