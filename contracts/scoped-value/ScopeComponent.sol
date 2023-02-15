// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { Component } from "solecs/Component.sol";
import { LibTypes } from "solecs/LibTypes.sol";

contract ScopeComponent is Component {
  constructor(address world, uint256 id) Component(world, id) {}

  function getSchema() public pure virtual override returns (string[] memory keys, LibTypes.SchemaValue[] memory values) {
    keys = new string[](1);
    values = new LibTypes.SchemaValue[](1);

    keys[0] = "value";
    values[0] = LibTypes.SchemaValue.BYTES;
  }

  function set(uint256 entity, string memory value) public virtual {
    set(entity, abi.encode(value));
  }

  function getValue(uint256 entity) public view virtual returns (string memory) {
    string memory value = abi.decode(getRawValue(entity), (string));
    return value;
  }

  function getEntitiesWithValue(string memory value) public view virtual returns (uint256[] memory) {
    return getEntitiesWithValue(abi.encode(value));
  }
}