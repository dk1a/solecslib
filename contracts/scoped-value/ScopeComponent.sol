// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { LibTypes } from "@latticexyz/solecs/src/LibTypes.sol";
import { BareComponent } from "@latticexyz/solecs/src/BareComponent.sol";
import { MapSet } from "@latticexyz/solecs/src/MapSet.sol";

contract ScopeComponent is BareComponent {
  /** Reverse mapping from value to set of entities */
  MapSet internal valueToEntities;

  constructor(address _world, uint256 _id) BareComponent(_world, _id) {
    valueToEntities = new MapSet();
  }

  function getSchema() public pure virtual override returns (string[] memory keys, LibTypes.SchemaValue[] memory values) {
    keys = new string[](1);
    values = new LibTypes.SchemaValue[](1);

    keys[0] = "scope";
    values[0] = LibTypes.SchemaValue.BYTES;
  }

  function getEntitiesWithValue(bytes memory value) public view virtual override returns (uint256[] memory) {
    return valueToEntities.getItems(uint256(keccak256(value)));
  }

  /**
   * @inheritdoc BareComponent
   */
  function _set(uint256 entity, bytes memory value) internal virtual override {
    // Remove the entity from the previous reverse mapping if there is one
    valueToEntities.remove(uint256(keccak256(entityToValue[entity])), entity);

    // Add the entity to the new reverse mapping
    valueToEntities.add(uint256(keccak256(value)), entity);

    // Store the entity's value; Emit global event
    super._set(entity, value);
  }

  /**
   * @inheritdoc BareComponent
   */
  function _remove(uint256 entity) internal virtual override {
    // If there is no entity with this value, return
    if (valueToEntities.size(uint256(keccak256(entityToValue[entity]))) == 0) return;

    // Remove the entity from the reverse mapping
    valueToEntities.remove(uint256(keccak256(entityToValue[entity])), entity);

    // Remove the entity from the mapping; Emit global event
    super._remove(entity);
  }
}