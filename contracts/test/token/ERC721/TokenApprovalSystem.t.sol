// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { BaseTest } from "./BaseTest.sol";

// systems
import { ID as ERC721BaseSubsystemID } from "./ERC721BaseSubsystemMock.sol";
import { TokenApprovalSystem } from "../../../token/ERC721/systems/TokenApprovalSystem.sol";

contract TokenApprovalSystemTest is BaseTest {
  TokenApprovalSystem taSystem;

  function setUp() public virtual override {
    super.setUp();

    vm.startPrank(deployer);

    address components = address(world.components());
    // deploy systems
    taSystem = new TokenApprovalSystem(world, components, ERC721BaseSubsystemID);
    world.registerSystem(address(taSystem), uint256(keccak256("taSystem")));
    // authorize
    ercSubsystem.authorizeWriter(address(taSystem));

    vm.stopPrank();
  }

  // only account is important for forwarding, ERC721 events are tested elsewhere
  function _expectEmitApproval(address account) internal {
    vm.expectEmit(true, false, false, false);
    emit Approval(account, address(0), 0);
  }

  function testExecute() public {
    _defaultMintToAlice();

    vm.prank(alice);
    _expectEmitApproval(alice);
    taSystem.executeTyped(bob, tokenId);

    assertEq(ercSubsystem.getApproved(tokenId), bob);
  }

  function testExecuteOnSystem() public {
    _defaultMintToAlice();

    vm.prank(alice);
    _expectEmitApproval(alice);
    taSystem.executeTyped(address(taSystem), tokenId);

    assertEq(ercSubsystem.getApproved(tokenId), address(taSystem));
  }
}