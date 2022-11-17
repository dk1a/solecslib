// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { BaseTest } from "./BaseTest.sol";

// systems
import { ID as ERC1155BaseSystemID } from "./ERC1155BaseSystemMock.sol";
import { SetApprovalForAllSystem } from "../../../token/ERC1155/systems/SetApprovalForAllSystem.sol";

contract SetApprovalForAllSystemTest is BaseTest {
  SetApprovalForAllSystem safaSystem;

  function setUp() public virtual override {
    super.setUp();

    vm.startPrank(deployer);

    address components = address(world.components());
    // deploy systems
    safaSystem = new SetApprovalForAllSystem(world, components, ERC1155BaseSystemID);
    // register systems
    world.registerSystem(address(safaSystem), uint256(keccak256("safaSystem")));
    // allows calling ercSystem's execute
    ercSystem.authorizeWriter(address(safaSystem));

    vm.stopPrank();
  }

  // only account is important for forwarding, ERC1155 events are tested elsewhere
  function _expectEmitApprovalForAll(address account) internal {
    vm.expectEmit(true, false, false, false);
    emit ApprovalForAll(account, address(0), false);
  }

  function testExecute() public {
    vm.prank(alice);
    _expectEmitApprovalForAll(alice);
    safaSystem.executeTyped(bob, true);

    assertTrue(ercSystem.isApprovedForAll(alice, bob));
  }

  function testExecuteOnSystem() public {
    vm.prank(alice);
    _expectEmitApprovalForAll(alice);
    safaSystem.executeTyped(address(safaSystem), true);

    assertTrue(ercSystem.isApprovedForAll(alice, address(safaSystem)));
  }
}