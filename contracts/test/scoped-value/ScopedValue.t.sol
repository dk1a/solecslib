// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { PRBTest } from "@prb/test/src/PRBTest.sol";

import { World } from "@latticexyz/solecs/src/World.sol";

import { ScopeComponent } from "../../scoped-value/ScopeComponent.sol";
import { ValueComponent } from "../../scoped-value/ValueComponent.sol";
import { ScopedValue } from "../../scoped-value/ScopedValue.sol";

uint256 constant TimeScopeComponentID = uint256(keccak256("test.component.TimeScope"));
uint256 constant TimeValueComponentID = uint256(keccak256("test.component.TimeValue"));

struct TimeScope {
  bytes4 timeType;
  uint256 entity;
}

// can't expectRevert internal calls, so this is an external wrapper
contract ScopedValueRevertHelper {
  function decreaseEntity(
    ScopedValue.Self memory _sv,
    bytes memory scope,
    uint256 entity,
    uint256 value
  ) public {
    ScopedValue.decreaseEntity(_sv, scope, entity, value);
  }
}

contract ScopedValueTest is PRBTest {
  using ScopedValue for ScopedValue.Self;

  World world;

  ScopeComponent scopeComponent;
  ValueComponent valueComponent;

  ScopedValue.Self _sv;

  uint256 mainEntity = uint256(keccak256('mainEntity'));

  // duration entities
  uint256 de1 = uint256(keccak256(abi.encode(mainEntity, 'duration1')));
  uint256 de2 = uint256(keccak256(abi.encode(mainEntity, 'duration2')));
  uint256 de3 = uint256(keccak256(abi.encode(mainEntity, 'duration3')));

  bytes roundScope = abi.encode(
    TimeScope({
      timeType: bytes4(keccak256("round")),
      entity: mainEntity
    })
  );
  bytes turnScope = abi.encode(
    TimeScope({
      timeType: bytes4(keccak256("turn")),
      entity: mainEntity
    })
  );

  function setUp() public {
    // deploy world
    world = new World();
    world.init();

    // deploy components
    scopeComponent = new ScopeComponent(address(world), TimeScopeComponentID);
    valueComponent = new ValueComponent(address(world), TimeValueComponentID);

    // init library's object
    _sv = ScopedValue.__construct(
      world.components(),
      TimeScopeComponentID,
      TimeValueComponentID
    );
  }

  // ENTITY CHANGES

  function testSingleEntityIncrease() public {
    // de1 + 500
    _sv.increaseEntity(roundScope, de1, 500);
    assertEq(_sv.getValue(de1), 500);
  }

  function testSingleEntityDecrease() public {
    // de1 + 500
    _sv.increaseEntity(roundScope, de1, 500);
    // de1 - 200
    _sv.decreaseEntity(roundScope, de1, 200);
    assertEq(_sv.getValue(de1), 300);
  }

  function testSingleEntityCannotDecreaseAbsent() public {
    ScopedValueRevertHelper _svRevertHelper = new ScopedValueRevertHelper();

    vm.expectRevert(ScopedValue.ScopedValue__EntityAbsent.selector);
    _svRevertHelper.decreaseEntity(_sv, roundScope, de1, 1);
  }

  function testSingleEntityDecreaseTotal() public {
    // de1 + 500
    _sv.increaseEntity(roundScope, de1, 500);
    assertEq(_sv.getValue(de1), 500);

    // de1 - 600
    _sv.decreaseEntity(roundScope, de1, 600);
    assertFalse(_sv.has(de1));
  }

  function testTwoEntitiesParallelChanges() public {
    // de1 + 500
    _sv.increaseEntity(roundScope, de1, 500);
    // de1 - 200
    _sv.decreaseEntity(roundScope, de1, 200);

    // de2 + 50
    _sv.increaseEntity(turnScope, de2, 50);
    assertEq(_sv.getValue(de2), 50);
    // and make sure de1 is unaffected
    assertEq(_sv.getValue(de1), 300);
  }

  // SCOPE CHANGES

  function testScopeIncrease() public {
    // round, de1 + 1
    _sv.increaseEntity(roundScope, de1, 1);
    // round, de2 + 2
    _sv.increaseEntity(roundScope, de2, 2);
    // turn, de3 + 3
    _sv.increaseEntity(turnScope, de3, 3);

    // + 100 to round scope (de1, de2)
    _sv.increaseScope(roundScope, 100);

    // de1 = 1 + 100 = 101
    assertEq(_sv.getValue(de1), 101);
    // de2 = 2 + 100 = 102
    assertEq(_sv.getValue(de2), 102);
    // de3 = 3 unaffected
    assertEq(_sv.getValue(de3), 3);
  }

  function testScopeDecrease() public {
    // round, de1 + 10
    _sv.increaseEntity(roundScope, de1, 10);
    // round, de2 + 2
    _sv.increaseEntity(roundScope, de2, 2);
    // turn, de3 + 5
    _sv.increaseEntity(turnScope, de3, 5);

    // - 3 to round scope (de1, de2)
    _sv.decreaseScope(roundScope, 3);

    // de1 = 10 - 3 = 7
    assertEq(_sv.getValue(de1), 7);
    // de2 = 2 - 3 = REMOVED
    assertFalse(_sv.has(de2));
    // de3 = 5 unaffected
    assertEq(_sv.getValue(de3), 5);
  }

  function testScopeRemove() public {
    // round, de1 + 1
    _sv.increaseEntity(roundScope, de1, 1);
    // round, de2 + 2
    _sv.increaseEntity(roundScope, de2, 2);
    // turn, de3 + 3
    _sv.increaseEntity(turnScope, de3, 3);

    // remove round scope
    _sv.removeScope(roundScope);

    // de1 REMOVED
    assertFalse(_sv.has(de1));
    // de2 REMOVED
    assertFalse(_sv.has(de2));
    // de3 unaffected
    assertEq(_sv.getValue(de3), 3);
  }
}