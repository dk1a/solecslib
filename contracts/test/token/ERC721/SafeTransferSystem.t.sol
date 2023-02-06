// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { BaseTest } from "./BaseTest.sol";

// systems
import { SafeTransferSystemMock, ID as SafeTransferSystemMockID } from "./SafeTransferSystemMock.sol";

// errors
import { IERC721BaseInternal } from "@solidstate/contracts/token/ERC721/base/IERC721BaseInternal.sol";

contract SafeTransferSystemTest is BaseTest {
  SafeTransferSystemMock transferSystem;

  function setUp() public virtual override {
    super.setUp();

    vm.startPrank(deployer);

    address components = address(world.components());
    // deploy systems
    transferSystem = new SafeTransferSystemMock(world, components);
    // register systems
    world.registerSystem(address(transferSystem), SafeTransferSystemMockID);
    // allows calling ercSubsystem's execute
    ercSubsystem.authorizeWriter(address(transferSystem));

    vm.stopPrank();
  }

  // FORWARD TRANSFER

  function testExecute() public {
    _defaultMintToAlice();

    vm.prank(alice);
    transferSystem.executeTyped(alice, bob, tokenId, '');

    assertEq(ercSubsystem.ownerOf(tokenId), bob);
  }

  function testExecuteNotOwner() public {
    _defaultMintToAlice();

    vm.prank(bob);
    vm.expectRevert(IERC721BaseInternal.ERC721Base__NotOwnerOrApproved.selector);
    transferSystem.executeTyped(alice, bob, tokenId, '');
  }

  function testExecuteNotOwnerFromForwarder() public {
    vm.prank(writer);
    ercSubsystem.executeSafeMint(address(transferSystem), tokenId, '');

    vm.prank(bob);
    vm.expectRevert(IERC721BaseInternal.ERC721Base__NotOwnerOrApproved.selector);
    transferSystem.executeTyped(address(transferSystem), bob, tokenId, '');
  }
}