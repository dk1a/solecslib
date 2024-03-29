// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { BaseTest } from "./BaseTest.sol";

// systems
import { SafeBatchTransferFromSystemMock, ID as SafeBatchTransferFromSystemMockID } from "./SafeBatchTransferFromSystemMock.sol";

// errors
import { IERC1155BaseInternal } from "@solidstate/contracts/token/ERC1155/base/IERC1155BaseInternal.sol";

contract SafeBatchTransferFromSystemTest is BaseTest {
  SafeBatchTransferFromSystemMock transferSystem;

  function setUp() public virtual override {
    super.setUp();

    vm.startPrank(deployer);

    address components = address(world.components());
    // deploy systems
    transferSystem = new SafeBatchTransferFromSystemMock(world, components);
    world.registerSystem(address(transferSystem), SafeBatchTransferFromSystemMockID);
    // authorize
    ercSubsystem.authorizeWriter(address(transferSystem));

    vm.stopPrank();
  }

  // only operator is important for forwarding, ERC1155 events are tested elsewhere
  function _expectEmitTransferBatch(address operator) internal {
    vm.expectEmit(true, false, false, false);
    emit TransferBatch(operator, address(0), address(0), _asArray(0), _asArray(0));
  }

  function testExecute() public {
    _defaultMintToAlice();

    vm.prank(alice);
    _expectEmitTransferBatch(alice);
    transferSystem.executeTyped(alice, bob, _asArray(tokenId), _asArray(80), '');

    assertEq(ercSubsystem.balanceOf(alice, tokenId), 20);
    assertEq(ercSubsystem.balanceOf(bob, tokenId), 80);
  }

  function testExecuteNotOwner() public {
    _defaultMintToAlice();

    vm.prank(bob);
    vm.expectRevert(IERC1155BaseInternal.ERC1155Base__NotOwnerOrApproved.selector);
    transferSystem.executeTyped(alice, bob, _asArray(tokenId), _asArray(80), '');
  }

  function testExecuteNotOwnerFromForwarder() public {
    vm.prank(writer);
    ercSubsystem.executeSafeMintBatch(address(transferSystem), _asArray(tokenId), _asArray(100), '');

    vm.prank(bob);
    vm.expectRevert(IERC1155BaseInternal.ERC1155Base__NotOwnerOrApproved.selector);
    transferSystem.executeTyped(address(transferSystem), bob, _asArray(tokenId), _asArray(80), '');
  }
}