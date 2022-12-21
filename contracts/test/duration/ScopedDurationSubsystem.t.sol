// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { PRBTest } from "@prb/test/src/PRBTest.sol";

import { World } from "@latticexyz/solecs/src/World.sol";

import { Uint256Component } from "@latticexyz/solecs/src/components/Uint256Component.sol";
import { ScopeComponent } from "../../scoped-value/ScopeComponent.sol";
import { ValueComponent } from "../../scoped-value/ValueComponent.sol";
import { SystemCallbackBareComponent, SystemCallback } from "../../mud/SystemCallbackBareComponent.sol";

import { ScopedDurationSubsystem, ScopedDuration } from "../../duration/ScopedDurationSubsystem.sol";
import { SetValueSystem, ID as SetValueSystemID } from "./SetValueSystem.sol";

contract ScopedDurationSubsystemTest is PRBTest {
  World world;

  ScopeComponent scopeComponent;
  uint256 constant TimeScopeComponentID = uint256(keccak256("test.component.TimeScope"));

  ValueComponent valueComponent;
  uint256 constant TimeValueComponentID = uint256(keccak256("test.component.TimeValue"));

  SystemCallbackBareComponent cbComponent;
  uint256 constant SystemCallbackBareComponentID = uint256(keccak256("test.component.SystemCallbackBare"));

  Uint256Component uintComponent;
  uint256 constant Uint256ComponentID = uint256(keccak256("test.component.Uint256"));

  ScopedDurationSubsystem durationSubsystem;
  uint256 constant ScopedDurationSubsystemID = uint256(keccak256("test.system.ScopedDuration"));

  SetValueSystem setValueSystem;

  uint256 targetEntity = uint256(keccak256('targetEntity'));

  uint256 timeScopeId = uint256(keccak256('timeScopeId'));
  uint256 anotherTimeScopeId = uint256(keccak256('anotherTimeScopeId'));
  // duration prototype entities
  uint256 de1 = uint256(keccak256('duration1'));
  uint256 de2 = uint256(keccak256('duration2'));
  uint256 de3 = uint256(keccak256('duration3'));

  function setUp() public {
    // deploy world
    world = new World();
    world.init();

    // deploy components
    scopeComponent = new ScopeComponent(address(world), TimeScopeComponentID);
    valueComponent = new ValueComponent(address(world), TimeValueComponentID);
    cbComponent = new SystemCallbackBareComponent(address(world), SystemCallbackBareComponentID);
    uintComponent = new Uint256Component(address(world), Uint256ComponentID);

    // deploy systems
    setValueSystem = new SetValueSystem(world, address(world.components()));
    world.registerSystem(address(setValueSystem), SetValueSystemID);
    uintComponent.authorizeWriter(address(setValueSystem));

    durationSubsystem = new ScopedDurationSubsystem(
      world,
      address(world.components()),
      TimeScopeComponentID,
      TimeValueComponentID,
      SystemCallbackBareComponentID
    );
    world.registerSystem(address(durationSubsystem), ScopedDurationSubsystemID);
    scopeComponent.authorizeWriter(address(durationSubsystem));
    valueComponent.authorizeWriter(address(durationSubsystem));
    cbComponent.authorizeWriter(address(durationSubsystem));
  }

  function _increaseBy10() internal {
    durationSubsystem.executeIncrease(
      targetEntity,
      de1,
      ScopedDuration({
        timeScopeId: timeScopeId,
        timeValue: 10
      }),
      SystemCallback({
        systemId: SetValueSystemID,
        args: abi.encode(Uint256ComponentID, de1, abi.encode(1337))
      })
    );
  }

  function testGetDuration() public {
    _increaseBy10();

    ScopedDuration memory duration = durationSubsystem.getDuration(targetEntity, de1);
    assertEq(duration.timeScopeId, timeScopeId);
    assertEq(duration.timeValue, 10);

    uint256 timeValue = durationSubsystem.getValue(targetEntity, de1);
    assertEq(timeValue, 10);
  }

  function testDecreaseScopeCallback() public {
    _increaseBy10();

    assertTrue(durationSubsystem.has(targetEntity, de1));

    durationSubsystem.executeDecreaseScope(
      targetEntity,
      ScopedDuration({
        timeScopeId: timeScopeId,
        timeValue: 5
      })
    );

    // not yet (it was 10 - 5)
    assertFalse(uintComponent.has(de1));
    assertTrue(durationSubsystem.has(targetEntity, de1));
    assertEq(durationSubsystem.getValue(targetEntity, de1), 5);

    durationSubsystem.executeDecreaseScope(
      targetEntity,
      ScopedDuration({
        timeScopeId: anotherTimeScopeId,
        timeValue: 5
      })
    );

    // anotherTimeScopeId shouldn't have affected timeScopeId
    assertFalse(uintComponent.has(de1));
    assertTrue(durationSubsystem.has(targetEntity, de1));
    assertEq(durationSubsystem.getValue(targetEntity, de1), 5);

    durationSubsystem.executeDecreaseScope(
      targetEntity,
      ScopedDuration({
        timeScopeId: timeScopeId,
        timeValue: 5
      })
    );

    // now the callback must have been called
    assertEq(uintComponent.getValue(de1), 1337);
    assertFalse(durationSubsystem.has(targetEntity, de1));

    // remove the value and make sure the callback isn't called to set it again
    uintComponent.remove(de1);

    durationSubsystem.executeDecreaseScope(
      targetEntity,
      ScopedDuration({
        timeScopeId: timeScopeId,
        timeValue: 10
      })
    );

    assertFalse(uintComponent.has(de1));
    assertFalse(durationSubsystem.has(targetEntity, de1));
  }

  function testRemoveNoCallback() public {
    _increaseBy10();

    assertTrue(durationSubsystem.has(targetEntity, de1));

    durationSubsystem.executeRemove(
      targetEntity,
      de1
    );

    // remove never executes the callback
    assertFalse(uintComponent.has(de1));
    assertFalse(durationSubsystem.has(targetEntity, de1));

    durationSubsystem.executeDecreaseScope(
      targetEntity,
      ScopedDuration({
        timeScopeId: timeScopeId,
        timeValue: 10
      })
    );

    // since the entity is now removed, executeDecreaseScope won't do anything either
    assertFalse(uintComponent.has(de1));
    assertFalse(durationSubsystem.has(targetEntity, de1));
  }
}