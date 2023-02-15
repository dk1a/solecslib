// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { IUint256Component } from "@latticexyz/solecs/src/interfaces/IUint256Component.sol";
import { getAddressById } from "@latticexyz/solecs/src/utils.sol";

import { ScopedValue } from "./ScopedValue.sol";
import { FromPrototype } from "../prototype/FromPrototype.sol";

/**
 * @title ScopedValue wrapper to encapsulate instantiation of prototype entities
 */
library ScopedValueFromPrototype {
  using ScopedValue for ScopedValue.Self;
  using FromPrototype for FromPrototype.Self;

  struct Self {
    ScopedValue.Self sv;
    FromPrototype.Self fromPrototype;
  }

  function __construct(
    ScopedValue.Self memory sv,
    FromPrototype.Self memory fromPrototype
  ) internal pure returns (Self memory) {
    return Self({
      sv: sv,
      fromPrototype: fromPrototype
    });
  }

  function _getInstance(Self memory __self, uint256 protoEntity) private view returns (uint256) {
    return __self.fromPrototype.getInstance(protoEntity);
  }

  /**
   * @dev WARNING: converts in-place
   */
  function _toPrototypes(
    Self memory __self,
    uint256[] memory entities
  ) private view returns (uint256[] memory) {
    for (uint256 i; i < entities.length; i++) {
      entities[i] = __self.fromPrototype.getPrototype(entities[i]);
    }
    return entities;
  }

  /*//////////////////////////////////////////////////////////////
                              READ
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Whether both scope and value have instantiated `protoEntity`
   */
  function has(
    Self memory __self,
    uint256 protoEntity
  ) internal view returns (bool) {
    if (__self.fromPrototype.hasInstance(protoEntity)) {
      return __self.sv.has(
        _getInstance(__self, protoEntity)
      );
    } else {
      return false;
    }
  }

  /**
   * @notice Get value for instantiated `protoEntity`
   */
  function getValue(
    Self memory __self,
    uint256 protoEntity
  ) internal view returns (uint256) {
    return __self.sv.getValue(_getInstance(__self, protoEntity));
  }

  /**
   * @notice Get scope for instantiated `protoEntity`
   */
  function getScope(
    Self memory __self,
    uint256 protoEntity
  ) internal view returns (string memory) {
    return __self.sv.getScope(_getInstance(__self, protoEntity));
  }

  /**
   * @notice Get array of `protoEntities` within `scope`
   */
  function getEntities(
    Self memory __self,
    string memory scope
  ) internal view returns (uint256[] memory) {
    return _toPrototypes(
      __self,
      __self.sv.getEntities(scope)
    );
  }

  /**
   * @notice Get array of `protoEntities` within `scope`, and their `values`
   */
  function getEntitiesValues(
    Self memory __self,
    string memory scope
  ) internal view returns (uint256[] memory, uint256[] memory) {
    (uint256[] memory entities, uint256[] memory values) = __self.sv.getEntitiesValues(scope);
    return (_toPrototypes(__self, entities), values);
  }

  /*//////////////////////////////////////////////////////////////
                                WRITE
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Increase value for instantiated `protoEntity`; update scope if necessary
   * @return isUpdate true if only updated, false if created
   */
  function increaseEntity(
    Self memory __self,
    string memory scope,
    uint256 protoEntity,
    uint256 value
  ) internal returns (bool isUpdate) {
    uint256 entity = __self.fromPrototype.newInstance(protoEntity);
    return __self.sv.increaseEntity(scope, entity, value);
  }

  /**
   * @notice Decrease value for instantiated `protoEntity`; update scope if necessary
   * @dev When a value would become <= 0, it is removed instead
   * @return isUpdate true if only updated, false if removed
   */
  function decreaseEntity(
    Self memory __self,
    string memory scope,
    uint256 protoEntity,
    uint256 value
  ) internal returns (bool isUpdate) {
    uint256 entity = __self.fromPrototype.newInstance(protoEntity);
    return __self.sv.decreaseEntity(scope, entity, value);
  }

  /**
   * @notice Within `scope` increase all values
   */
  function increaseScope(
    Self memory __self,
    string memory scope,
    uint256 value
  ) internal {
    __self.sv.increaseScope(scope, value);
  }

  /**
   * @notice Within `scope` decrease all values
   * @dev When a value would become <= 0, it is removed instead
   * @return removedProtoEntities protoEntities that were removed due to being <= 0
   */
  function decreaseScope(
    Self memory __self,
    string memory scope,
    uint256 value
  ) internal returns (uint256[] memory removedProtoEntities) {
    return _toPrototypes(
      __self,
      __self.sv.decreaseScope(scope, value)
    );
  }

  /**
   * @notice Remove instantiated `protoEntity` from value and scope components
   * @dev Reverts if `protoEntity` was not instantiated
   */
  function removeEntity(
    Self memory __self,
    uint256 protoEntity
  ) internal {
    if (!__self.fromPrototype.hasInstance(protoEntity)) {
      // revert for a clearer message and to avoid _getInstance's assert
      revert ScopedValue.ScopedValue__EntityAbsent();
    }
    __self.sv.removeEntity(_getInstance(__self, protoEntity));
  }

  /**
   * @notice Remove all entities within `scope` from value and scope components
   */
  function removeScope(
    Self memory __self,
    string memory scope
  ) internal {
    __self.sv.removeScope(scope);
  }
}