// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { Component } from "@latticexyz/solecs/src/Component.sol";
import { LibTypes } from "@latticexyz/solecs/src/LibTypes.sol";

contract OwnershipComponent is Component {
  constructor(address world, uint256 id) Component(world, id) {}

  function getSchema() public pure override returns (string[] memory keys, LibTypes.SchemaValue[] memory values) {
    keys = new string[](1);
    values = new LibTypes.SchemaValue[](1);

    keys[0] = "value";
    values[0] = LibTypes.SchemaValue.ADDRESS;
  }

  function set(uint256 entity, address value) public {
    set(entity, abi.encode(value));
  }

  function getValue(uint256 entity) public view returns (address) {
    bytes memory rawValue = getRawValue(entity);
    if (rawValue.length > 0) {
      return abi.decode(rawValue, (address));
    } else {
      return address(0);
    }
  }

  function getEntitiesWithValue(address value) public view returns (uint256[] memory) {
    return getEntitiesWithValue(abi.encode(value));
  }

  function getEntitiesWithValueLength(address value) public view returns (uint256) {
    return getEntitiesWithValueLength(abi.encode(value));
  }

  function getEntitiesWithValueLength(bytes memory value) public view returns (uint256) {
    return valueToEntities.size(uint256(keccak256(value)));
  }
}