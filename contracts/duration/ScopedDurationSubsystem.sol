// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { IWorld } from "@latticexyz/solecs/src/interfaces/IWorld.sol";
import { getAddressById } from "@latticexyz/solecs/src/utils.sol";
import { 
  SystemCallbackBareComponent,
  SystemCallback,
  executeSystemCallback
} from "@latticexyz/std-contracts/src/components/SystemCallbackBareComponent.sol";

import { Subsystem } from "../mud/Subsystem.sol";
import { ScopedValue } from "../scoped-value/ScopedValue.sol";

/// @dev durationEntity = hashed(target, prototype)
function getDurationEntity(uint256 targetEntity, uint256 protoEntity) pure returns (uint256) {
  return uint256(keccak256(abi.encode(targetEntity, protoEntity)));
}

/// @dev durationScope = encoded(target, scopeId)
function getDurationScope(uint256 targetEntity, uint256 timeScopeId) pure returns (bytes memory) {
  // scope isn't hashed because it's not an entity, also scopeId may need to be extracted later
  return abi.encode(targetEntity, timeScopeId);
}

struct ScopedDuration {
  uint256 timeScopeId;
  uint256 timeValue;
}

/**
 * @title Scoped duration time manager.
 * @dev The primary feature is `onEnd` callback which is called when an entity's duration ends.
 * Scope allows parallel timelines, e.g. "realtime", "round", "turn"...
 */
contract ScopedDurationSubsystem is Subsystem {
  using ScopedValue for ScopedValue.Self;

  error ScopedDurationSubsystem__InvalidExecuteSelector();

  uint256 immutable internal timeScopeComponentId;
  uint256 immutable internal timeValueComponentId;
  uint256 immutable internal systemCallbackComponentId;

  /**
   * @dev writeAccess must be provided for all 3 of these components.
   * @param _timeScopeComponentId see `scoped-value/ScopeComponent.sol`
   * @param _timeValueComponentId see `scoped-value/ValueComponent.sol`
   * @param _systemCallbackComponentId see `mud/SystemCallbackBareComponent.sol`
   */
  constructor(
    IWorld _world,
    address _components,
    uint256 _timeScopeComponentId,
    uint256 _timeValueComponentId,
    uint256 _systemCallbackComponentId
  ) Subsystem(_world, _components) {
    timeScopeComponentId = _timeScopeComponentId;
    timeValueComponentId = _timeValueComponentId;
    systemCallbackComponentId = _systemCallbackComponentId;
  }

  /*//////////////////////////////////////////////////////////////
                              EXECUTE
  //////////////////////////////////////////////////////////////*/

  /**
   * @dev Increase duration of `protoEntity` for `targetEntity`.
   * @param onEnd called when the duration ends (set only if `isUpdate` == false and `onEnd.systemId` != 0).
   * @return isUpdate true if an existing value was increased; false if a new value was set.
   */
  function executeIncrease(
    uint256 targetEntity,
    uint256 protoEntity,
    ScopedDuration memory duration,
    SystemCallback memory onEnd
  ) public virtual onlyWriter returns (bool isUpdate) {
    uint256 entity = getDurationEntity(targetEntity, protoEntity);

    isUpdate = _sv().increaseEntity(
      getDurationScope(targetEntity, duration.timeScopeId),
      entity,
      duration.timeValue
    );

    if (isUpdate == false && onEnd.systemId != 0) {
      _cbComp().set(entity, onEnd);
    }
    return isUpdate;
  }

  /// @dev Remove duration of `protoEntity` for `targetEntity`.
  /// Does not execute `onEnd` callback.
  function executeRemove(
    uint256 targetEntity,
    uint256 protoEntity
  ) public virtual onlyWriter {
    _sv().removeEntity(getDurationEntity(targetEntity, protoEntity));
  }

  /// @dev Decrease 1 entire duration scope for `targetEntity`.
  /// Executes `onEnd` callback.
  function executeDecreaseScope(
    uint256 targetEntity,
    ScopedDuration memory duration
  ) public virtual onlyWriter {
    uint256[] memory removedEntities = _sv().decreaseScope(
      getDurationScope(targetEntity, duration.timeScopeId),
      duration.timeValue
    );
    if (removedEntities.length == 0) return;

    // Execute onEnd callbacks for each removed entity
    SystemCallbackBareComponent cbComp = _cbComp();
    for (uint256 i; i < removedEntities.length; i++) {
      uint256 removedEntity = removedEntities[i];

      if (cbComp.has(removedEntity)) {
        // get and remove the callback
        SystemCallback memory cb = cbComp.getValue(removedEntity);
        cbComp.remove(removedEntity);
        // execute it
        executeSystemCallback(world, cb);
      }
    }
  }

  /*//////////////////////////////////////////////////////////////
                                READ
  //////////////////////////////////////////////////////////////*/

  /**
   * @dev Returns true if `targetEntity` has an ongoing duration for `protoEntity`.
   */
  function has(
    uint256 targetEntity,
    uint256 protoEntity
  ) public view returns (bool) {
    return _sv().has(getDurationEntity(targetEntity, protoEntity));
  }

  /**
   * @dev Returns the duration of `protoEntity` for `targetEntity`.
   * Reverts if absent.
   */
  function getDuration(
    uint256 targetEntity,
    uint256 protoEntity
  ) public view returns (ScopedDuration memory) {
    uint256 entity = getDurationEntity(targetEntity, protoEntity);
    ScopedValue.Self memory sv = _sv();

    (, uint256 timeScopeId) = abi.decode(sv.getScope(entity), (uint256, uint256));
    return ScopedDuration({
      timeScopeId: timeScopeId,
      timeValue: sv.getValue(entity)
    });
  }

  /**
   * @dev Returns the duration's `timeValue` of `protoEntity` for `targetEntity`.
   * Reverts if absent.
   */
  function getValue(
    uint256 targetEntity,
    uint256 protoEntity
  ) public view returns (uint256) {
    return _sv().getValue(getDurationEntity(targetEntity, protoEntity));
  }

  /*//////////////////////////////////////////////////////////////
                              INTERNAL
  //////////////////////////////////////////////////////////////*/

  /**
   * @notice Generic execute, calls the specified function.
   * @dev You should use specific functions like `executeIncrease` directly whenever possible.
   */
  function _execute(bytes memory args) internal virtual override returns (bytes memory) {
    (bytes4 executeSelector, bytes memory innerArgs) = abi.decode(args, (bytes4, bytes));

    if (executeSelector == this.executeIncrease.selector) {
      (
        uint256 targetEntity,
        uint256 protoEntity,
        ScopedDuration memory time,
        SystemCallback memory onEnd
      ) = abi.decode(innerArgs, (uint256, uint256, ScopedDuration, SystemCallback));
      return abi.encode(
        executeIncrease(targetEntity, protoEntity, time, onEnd)
      );

    } else if (executeSelector == this.executeRemove.selector) {
      (
        uint256 targetEntity,
        uint256 protoEntity
      ) = abi.decode(innerArgs, (uint256, uint256));
      executeRemove(targetEntity, protoEntity);
      return '';

    } else if (executeSelector == this.executeDecreaseScope.selector) {
      (
        uint256 targetEntity,
        ScopedDuration memory duration
      ) = abi.decode(innerArgs, (uint256, ScopedDuration));
      executeDecreaseScope(targetEntity, duration);
      return '';

    } else {
      revert ScopedDurationSubsystem__InvalidExecuteSelector();
    }
  }

  /// @dev Get the ScopedValue lib model
  /// (it has all the storage/modification logic for the scope+entity+value triplet).
  function _sv() internal view returns (ScopedValue.Self memory) {
    return ScopedValue.__construct(
      components,
      timeScopeComponentId,
      timeValueComponentId
    );
  }

  /// @dev Get the callback component.
  function _cbComp() internal view returns (SystemCallbackBareComponent) {
    return SystemCallbackBareComponent(getAddressById(components, systemCallbackComponentId));
  }
}