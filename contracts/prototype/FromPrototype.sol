// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { IUint256Component } from "@latticexyz/solecs/src/interfaces/IUint256Component.sol";
import { getAddressById } from "@latticexyz/solecs/src/utils.sol";

import { FromPrototypeComponent } from "./FromPrototypeComponent.sol";

/**
 * @title Instantiates prototypes, ensures a reverse mapping.
 * @dev Avoid using FromPrototypeComponent directly
 */
library FromPrototype {
  struct Self {
    FromPrototypeComponent comp;
    bytes instanceContext;
  }

  /**
   * @param components world.components()
   * @param fromPrototypeComponentId ID of FromPrototypeComponent implementation
   * @param instanceContext encoded with protoEntity to get instanced entity
   *
   * instanceContext example: `abi.encode("MyLib", targetEntity)`
   * 
   * instanceContext can even be '' if protoEntity is already instantiated and not a prototype,
   * but then you may not need FromPrototype at all.
   */
  function __construct(
    IUint256Component components,
    uint256 fromPrototypeComponentId,
    bytes memory instanceContext
  ) internal view returns (Self memory) {
    return Self({
      comp: FromPrototypeComponent(getAddressById(components, fromPrototypeComponentId)),
      instanceContext: instanceContext
    });
  }

  /**
   * @notice Get prototype for instantiated `entity`
   * @dev newInstance must have been called
   */
  function getPrototype(
    Self memory __self,
    uint256 entity
  ) internal view returns (uint256) {
    return __self.comp.getValue(entity);
  }

  /**
   * @notice Whether `entity` is an instantiated prototype
   */
  function hasPrototype(
    Self memory __self,
    uint256 entity
  ) internal view returns (bool) {
    return __self.comp.has(entity);
  }

  /**
   * @notice Make new instance from prototype and context
   */
  function newInstance(
    Self memory __self,
    uint256 protoEntity
  ) internal returns (uint256) {
    uint256 entity = _instance(__self, protoEntity);

    // protoEntity is assumed immutable, since entity is its hash
    if (!__self.comp.has(entity)) {
      __self.comp.set(entity, protoEntity);
    }

    return entity;
  }

  /**
   * @notice Whether newInstance had been called for given `context` and `protoEntity`
   * @dev Use with getInstance for read-only methods
   */
  function hasInstance(
    Self memory __self,
    uint256 protoEntity
  ) internal view returns (bool) {
    uint256 entity = _instance(__self, protoEntity);
    return hasPrototype(__self, entity);
  }

  /**
   * @notice Get existing instance for prototype and context
   * @dev newInstance must have been called
   */
  function getInstance(
    Self memory __self,
    uint256 protoEntity
  ) internal view returns (uint256) {
    uint256 entity = _instance(__self, protoEntity);
    // newInstance must be used for uninstantiated prototypes
    assert(__self.comp.has(entity));
    return entity;
  }

  /**
   * @notice Get all instances with `protoEntity`.
   * @dev WARNING: FromPrototypeComponent will revert, since it's bare.
   * If you need this method, e.g. use Uint256Component instead.
   */
  function getInstancesWithPrototype(
    Self memory __self,
    uint256 protoEntity
  ) internal view returns (uint256[] memory) {
    return __self.comp.getEntitiesWithValue(abi.encode(protoEntity));
  }

  /**
   * @dev Hash context and prototype to instantiate an entity
   */
  function _instance(
    Self memory __self,
    uint256 protoEntity
  ) private pure returns (uint256) {
    return uint256(keccak256(abi.encode(__self.instanceContext, protoEntity)));
  }
}