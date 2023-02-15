// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { PRBTest } from "@prb/test/src/PRBTest.sol";

import { World } from "@latticexyz/solecs/src/World.sol";

import { ScopeComponent } from "../../scoped-value/ScopeComponent.sol";
import { ValueComponent } from "../../scoped-value/ValueComponent.sol";
import { FromPrototypeComponent } from "../../prototype/FromPrototypeComponent.sol";

import { ScopedValueFromPrototype } from "../../scoped-value/ScopedValueFromPrototype.sol";
import { ScopedValue } from "../../scoped-value/ScopedValue.sol";
import { FromPrototype } from "../../prototype/FromPrototype.sol";

uint256 constant TimeScopeComponentID = uint256(keccak256("test.component.TimeScope"));
uint256 constant TimeValueComponentID = uint256(keccak256("test.component.TimeValue"));
uint256 constant FromPrototypeComponentID = uint256(keccak256("test.component.FromPrototype"));

struct TimeScope {
  bytes4 timeType;
  uint256 entity;
}

// can't expectRevert internal calls, so this is an external wrapper
contract ScopedValueRevertHelper {
  function decreaseEntity(
    ScopedValueFromPrototype.Self memory _sv,
    string memory scope,
    uint256 protoEntity,
    uint256 value
  ) public {
    ScopedValueFromPrototype.decreaseEntity(_sv, scope, protoEntity, value);
  }
}

contract ScopedValueFromPrototypeTest is PRBTest {
  using ScopedValueFromPrototype for ScopedValueFromPrototype.Self;

  World world;

  ScopeComponent scopeComponent;
  ValueComponent valueComponent;
  FromPrototypeComponent fromPrototypeComponent;

  ScopedValueFromPrototype.Self _sv;
  ScopedValueRevertHelper _svRevertHelper;

  uint256 targetEntity = uint256(keccak256('targetEntity'));

  bytes instanceContext = abi.encode("Time", targetEntity);

  // duration prototype entities
  uint256 de1 = uint256(keccak256('duration1'));
  uint256 de2 = uint256(keccak256('duration2'));
  uint256 de3 = uint256(keccak256('duration3'));

  string roundScope = string(abi.encode(
    TimeScope({
      timeType: bytes4(keccak256("round")),
      entity: targetEntity
    })
  ));
  string turnScope = string(abi.encode(
    TimeScope({
      timeType: bytes4(keccak256("turn")),
      entity: targetEntity
    })
  ));

  function setUp() public {
    // deploy world
    world = new World();
    world.init();

    // deploy components
    scopeComponent = new ScopeComponent(address(world), TimeScopeComponentID);
    valueComponent = new ValueComponent(address(world), TimeValueComponentID);
    fromPrototypeComponent = new FromPrototypeComponent(address(world), FromPrototypeComponentID);

    // deploy and authorize helper
    _svRevertHelper = new ScopedValueRevertHelper();
    scopeComponent.authorizeWriter(address(_svRevertHelper));
    valueComponent.authorizeWriter(address(_svRevertHelper));
    fromPrototypeComponent.authorizeWriter(address(_svRevertHelper));

    // init library's object
    _sv = ScopedValueFromPrototype.__construct(
      ScopedValue.__construct(
        world.components(),
        TimeScopeComponentID,
        TimeValueComponentID
      ),
      FromPrototype.__construct(
        world.components(),
        FromPrototypeComponentID,
        instanceContext
      )
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
    // de2 + 100
    _sv.increaseEntity(turnScope, de2, 100);
    // de1 - 200
    _sv.decreaseEntity(roundScope, de1, 200);
    // de2 + 50
    _sv.decreaseEntity(turnScope, de2, 50);

    assertEq(_sv.getValue(de2), 50);
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