// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { IUint256Component } from "@latticexyz/solecs/src/interfaces/IUint256Component.sol";
import { getAddressById } from "@latticexyz/solecs/src/utils.sol";
import { ScopeComponent } from "./ScopeComponent.sol";
import { ValueComponent } from "./ValueComponent.sol";

/**
 * @title Interact with batches (identified by scope) of entity values, or individual entity values.
 * @dev Scope is for doing batched read/increase/decrease without looping through everything.
 * Value is any kind of entity to counter mapping.
 * 
 * You can see a simple example with turn-based time in tests.
 * 
 * A more complex use case:
 * A status effect system adds 3 modifiers to playerEntity:
 * [
 *   { value: 2,  op: "add", element: "fire", topic: "attack", mod: "+# fire to attack" },
 *   { value: 50, op: "mul", element: "fire", topic: "attack", mod: "#% increased fire attack" },
 *   { value: 10  op: "add", element: "none", topic: "life",   mod: "+# life" }
 * ]
 * scoped by affected playerEntity and topic: {playerEntity, topic}.
 * Now if you need attack for player #7, use {7, 'attack'} scope to avoid looping everything.
 * This is only useful if you have many modififers with different topics.
 * And without parameterization (element, op), you could just sum up values and not need scope=>entity mapping.
 *
 * Generally you would need only a subset of ScopedValue's methods,
 * the status effect example wouldn't care about scope modifications (increaseScope/decreaseScope),
 * whereas the time example doesn't care about scope reads (getEntities).
 */
library ScopedValue {
  error ScopedValue__IncreaseByZero();
  error ScopedValue__DecreaseByZero();
  error ScopedValue__EntityAbsent();

  struct Self {
    ScopeComponent scopeComp;
    ValueComponent valueComp;
  }

  function __construct(
    IUint256Component registry,
    uint256 scopeComponentId,
    uint256 valueComponentId
  ) internal view returns (Self memory) {
    return Self({
      scopeComp: ScopeComponent(getAddressById(registry, scopeComponentId)),
      valueComp: ValueComponent(getAddressById(registry, valueComponentId))
    });
  }

  /*//////////////////////////////////////////////////////////////
                              READ
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Whether both scope and value have `entity`
   */
  function has(
    Self memory __self,
    uint256 entity
  ) internal view returns (bool) {
    // invariant: scopeComp.has(entity) == valueComp.has(entity)
    return __self.scopeComp.has(entity);
  }

  /**
   * @notice Get value for `entity`
   */
  function getValue(
    Self memory __self,
    uint256 entity
  ) internal view returns (uint256) {
    return __self.valueComp.getValue(entity);
  }

  /**
   * @notice Get scope for `entity`
   */
  function getScope(
    Self memory __self,
    uint256 entity
  ) internal view returns (uint256) {
    return __self.valueComp.getValue(entity);
  }

  /**
   * @notice Get array of `entities` within `scope`
   */
  function getEntities(
    Self memory __self,
    bytes memory scope
  ) internal view returns (uint256[] memory entities) {
    return __self.scopeComp.getEntitiesWithValue(scope);
  }

  /**
   * @notice Get values for an array of `entities`
   */
  function getValuesForEntities(
    Self memory __self,
    uint256[] memory entities
  ) internal view returns (uint256[] memory values) {
    // get values for entities
    values = new uint256[](entities.length);
    for (uint256 i; i < entities.length; i++) {
      values[i] = __self.valueComp.getValue(entities[i]);
    }
  }

  /*//////////////////////////////////////////////////////////////
                                WRITE
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Increase value for `entity`; update scope if necessary
   * @return isUpdate true if only updated, false if created
   */
  function increaseEntity(
    Self memory __self,
    bytes memory scope,
    uint256 entity,
    uint256 value
  ) internal returns (bool isUpdate) {
    // zero increase is invalid
    if (value == 0) {
      revert ScopedValue__IncreaseByZero();
    }

    // get stored data
    isUpdate = has(__self, entity);
    if (isUpdate) {
      uint256 storedValue = __self.valueComp.getValue(entity);
      _update(__self, scope, entity, storedValue + value);
    } else {
      // set scope and value
      __self.scopeComp.set(entity, scope);
      __self.valueComp.set(entity, value);
    }
  }

  /**
   * @notice Decrease value for `entity`; update scope if necessary
   * @dev When a value would become <= 0, it is removed instead
   * @return isUpdate true if only updated, false if removed
   */
  function decreaseEntity(
    Self memory __self,
    bytes memory scope,
    uint256 entity,
    uint256 value
  ) internal returns (bool isUpdate) {
    // zero decrease is invalid
    if (value == 0) {
      revert ScopedValue__DecreaseByZero();
    }
    // can't decrease nonexistent value
    if (!has(__self, entity)) {
      revert ScopedValue__EntityAbsent();
    }

    uint256 storedValue = __self.valueComp.getValue(entity);
    isUpdate = storedValue > value;
    if (isUpdate) {
      _update(__self, scope, entity, storedValue - value);
    } else {
      removeEntity(__self, entity);
    }
  }

  /**
    * @dev sets new entity values for both increase and decrease
    */
  function _update(
    Self memory __self,
    bytes memory newScope,
    uint256 entity,
    uint256 newValue
  ) private {
    // update scope if necessary
    if (keccak256(newScope) != keccak256(__self.scopeComp.getRawValue(entity))) {
      __self.scopeComp.set(entity, newScope);
    }
    // decrease value
    __self.valueComp.set(entity, newValue);
  }

  /**
   * @notice Within `scope` increase all values
   * 
   * TODO should this return updated values?
   */
  function increaseScope(
    Self memory __self,
    bytes memory scope,
    uint256 value
  ) internal {
    // zero increase is invalid
    if (value == 0) {
      revert ScopedValue__IncreaseByZero();
    }

    uint256[] memory entities = __self.scopeComp.getEntitiesWithValue(scope);
    // loop all entities within scope
    for (uint256 i; i < entities.length; i++) {
      uint256 entity = entities[i];
      uint256 storedValue = __self.valueComp.getValue(entity);
      // increase
      __self.valueComp.set(entity, storedValue + value);
    }
  }

  /**
   * @notice Within `scope` decrease all values
   * @dev When a value would become <= 0, it is removed instead
   * @return removedEntities entities that were removed due to being <= 0
   */
  function decreaseScope(
    Self memory __self,
    bytes memory scope,
    uint256 value
  ) internal returns (uint256[] memory) {
    // zero decrease is invalid
    if (value == 0) {
      revert ScopedValue__DecreaseByZero();
    }

    uint256[] memory entities = __self.scopeComp.getEntitiesWithValue(scope);
    // track removed entities
    uint256[] memory removedEntities = new uint256[](entities.length);
    uint256 removedLength;
    // loop all entities within scope
    for (uint256 i; i < entities.length; i++) {
      uint256 entity = entities[i];
      uint256 storedValue = __self.valueComp.getValue(entity);

      // if decrease >= stored
      if (value >= storedValue) {
        // remove
        removeEntity(__self, entity);

        removedEntities[removedLength++] = entity;
      } else {
        // decrease
        __self.valueComp.set(entity, storedValue - value);
      }
    }

    // return removedEntities with unused space sliced off 
    if (removedEntities.length == removedLength) {
      return removedEntities;
    }
    // TODO I think this can be replaced with something like
    // mstore(removedEntities, sub(mload(removedEntities), lengthDiff))
    uint256[] memory removedEntitiesSliced = new uint256[](removedLength);
    for (uint256 i; i < removedLength; i++) {
      removedEntitiesSliced[i] = removedEntities[i];
    }
    return removedEntitiesSliced;
  }

  /**
   * @notice Remove `entity` from value and scope components
   */
  function removeEntity(
    Self memory __self,
    uint256 entity
  ) internal {
    // TODO should this revert if absent?
    __self.valueComp.remove(entity);
    __self.scopeComp.remove(entity);
  }

  /**
   * @notice Remove all entities within `scope` from value and scope components
   */
  function removeScope(
    Self memory __self,
    bytes memory scope
  ) internal {
    uint256[] memory entities = __self.scopeComp.getEntitiesWithValue(scope);
    for (uint256 i; i < entities.length; i++) {
      __self.valueComp.remove(entities[i]);
      __self.scopeComp.remove(entities[i]);
    }
  }
}