// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { BaseTest } from "./BaseTest.sol";

// systems
import { ID as ERC721BaseSystemID } from "./ERC721BaseSystemMock.sol";
import { OperatorApprovalSystem } from "../../../token/ERC721/systems/OperatorApprovalSystem.sol";

contract OperatorApprovalSystemTest is BaseTest {
  OperatorApprovalSystem oaSystem;

  function setUp() public virtual override {
    super.setUp();

    vm.startPrank(deployer);

    address components = address(world.components());
    // deploy systems
    oaSystem = new OperatorApprovalSystem(world, components, ERC721BaseSystemID);
    // register systems
    world.registerSystem(address(oaSystem), uint256(keccak256("oaSystem")));
    // allows calling ercSystem's execute
    ercSystem.authorizeWriter(address(oaSystem));

    vm.stopPrank();
  }

  // only account is important for forwarding, ERC721 events are tested elsewhere
  function _expectEmitApprovalForAll(address account) internal {
    vm.expectEmit(true, false, false, false);
    emit ApprovalForAll(account, address(0), false);
  }

  function testExecute() public {
    vm.prank(alice);
    _expectEmitApprovalForAll(alice);
    oaSystem.executeTyped(bob, true);

    assertTrue(ercSystem.isApprovedForAll(alice, bob));
  }

  function testExecuteOnSystem() public {
    vm.prank(alice);
    _expectEmitApprovalForAll(alice);
    oaSystem.executeTyped(address(oaSystem), true);

    assertTrue(ercSystem.isApprovedForAll(alice, address(oaSystem)));
  }
}