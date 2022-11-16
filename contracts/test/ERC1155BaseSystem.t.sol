// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.17;

import { PRBTest } from "@prb/test/src/PRBTest.sol";

// ECS
import { World } from "@latticexyz/solecs/src/World.sol";
// systems
import { BurnSystem, ID as BurnSystemID } from "./utils/BurnSystem.sol";
import { MintSystem, ID as MintSystemID } from "./utils/MintSystem.sol";
import { ForwardTransferSystem, ID as ForwardTransferSystemID } from "./utils/ForwardTransferSystem.sol";
// ERC1155 system mock
import { ERC1155BaseSystemMock, ID as ERC1155BaseSystemMockID } from "./utils/ERC1155BaseSystemMock.sol";

// ERC1155 events
import { IERC1155Internal } from "@solidstate/contracts/interfaces/IERC1155Internal.sol";

// errors
import { IOwnableInternal } from "@solidstate/contracts/access/ownable/IOwnableInternal.sol";
import { OwnableAndWriteAccess } from "../mud/OwnableAndWriteAccess.sol";
import { ERC1155BaseInternal } from "../token/ERC1155/logic/ERC1155BaseInternal.sol";

contract ERC1155BaseSystemTest is
  PRBTest,
  IERC1155Internal
{
  address deployer = address(bytes20(keccak256("deployer")));
  
  address alice = address(bytes20(keccak256("alice")));
  address bob = address(bytes20(keccak256("bob")));
  address eve = address(bytes20(keccak256("eve")));

  World world;
  // ERC1155 and System
  ERC1155BaseSystemMock erc1155System;
  // calls executeBurnBatch
  BurnSystem burnSystem;
  BurnSystem unauthBurnSystem;
  // calls executeSafeMintBatch
  MintSystem mintSystem;
  MintSystem unauthMintSystem;
  // calls executeSafeTransferBatch with msg.sender as opearator
  ForwardTransferSystem forwardTransferSystem;
  ForwardTransferSystem unauthForwardTransferSystem;

  uint256 tokenId = 1337;
  
  function setUp() public virtual {
    vm.startPrank(deployer);

    // deploy world
    world = new World();
    world.init();

    address components = address(world.components());
    // deploy systems
    erc1155System = new ERC1155BaseSystemMock(world, components);
    burnSystem = new BurnSystem(world, components);
    mintSystem = new MintSystem(world, components);
    forwardTransferSystem = new ForwardTransferSystem(world, components);
    // register systems
    world.registerSystem(address(erc1155System), ERC1155BaseSystemMockID);
    world.registerSystem(address(burnSystem), MintSystemID);
    world.registerSystem(address(mintSystem), MintSystemID);
    world.registerSystem(address(forwardTransferSystem), ForwardTransferSystemID);
    // allows calling erc1155System's execute
    erc1155System.authorizeWriter(address(burnSystem));
    erc1155System.authorizeWriter(address(mintSystem));
    erc1155System.authorizeWriter(address(forwardTransferSystem));

    // deploy unauthorized systems
    unauthBurnSystem = new BurnSystem(world, components);
    unauthMintSystem = new MintSystem(world, components);
    unauthForwardTransferSystem = new ForwardTransferSystem(world, components);

    vm.stopPrank();
  }

  // HELPERS

  function _asArray(uint256 number) internal pure returns (uint256[] memory result) {
    result = new uint256[](1);
    result[0] = number;
  }

  // only operator is important for forwarding, ERC1155 events are tested elsewhere
  function _expectEmitTransferBatch(address operator) internal {
    vm.expectEmit(true, false, false, false);
    emit TransferBatch(operator, address(0), address(0), _asArray(0), _asArray(0));
  }

  // AUTHORIZE

  function testOwnerAuthorizeWriter() public {
    vm.prank(deployer);
    erc1155System.authorizeWriter(alice);
    assertTrue(erc1155System.writeAccess(alice));
  }

  function testNotOwnerAuthorizeWriter() public {
    vm.prank(alice);
    vm.expectRevert(IOwnableInternal.Ownable__NotOwner.selector);
    erc1155System.authorizeWriter(alice);
  }

  // MINT

  function testMint() public {
    mintSystem.executeTyped(alice, _asArray(tokenId), _asArray(10), '');
    assertEq(erc1155System.balanceOf(alice, tokenId), 10);
  }

  function testMintDirect() public {
    // owner should be authorized automatically
    vm.prank(deployer);

    erc1155System.executeSafeMintBatch(alice, _asArray(tokenId), _asArray(10), '');
    assertEq(erc1155System.balanceOf(alice, tokenId), 10);
  }

  function testMintUnauth() public {
    vm.expectRevert(OwnableAndWriteAccess.OwnableAndWriteAccess__NotWriter.selector);
    unauthMintSystem.executeTyped(alice, _asArray(tokenId), _asArray(10), '');
  }

  function testMintDirectUnauth() public {
    vm.expectRevert(OwnableAndWriteAccess.OwnableAndWriteAccess__NotWriter.selector);
    erc1155System.executeSafeMintBatch(alice, _asArray(tokenId), _asArray(10), '');
  }

  // BURN

  function testBurn() public {
    mintSystem.executeTyped(alice, _asArray(tokenId), _asArray(100), '');

    burnSystem.executeTyped(alice, _asArray(tokenId), _asArray(80));
    assertEq(erc1155System.balanceOf(alice, tokenId), 20);
  }

  function testBurnDirect() public {
    mintSystem.executeTyped(alice, _asArray(tokenId), _asArray(100), '');

    // owner should be authorized automatically
    vm.prank(deployer);

    erc1155System.executeBurnBatch(alice, _asArray(tokenId), _asArray(80));
    assertEq(erc1155System.balanceOf(alice, tokenId), 20);
  }

  function testBurnUnauth() public {
    mintSystem.executeTyped(alice, _asArray(tokenId), _asArray(100), '');

    vm.expectRevert(OwnableAndWriteAccess.OwnableAndWriteAccess__NotWriter.selector);
    unauthBurnSystem.executeTyped(alice, _asArray(tokenId), _asArray(80));
  }

  function testBurnDirectUnauth() public {
    mintSystem.executeTyped(alice, _asArray(tokenId), _asArray(100), '');

    vm.expectRevert(OwnableAndWriteAccess.OwnableAndWriteAccess__NotWriter.selector);
    erc1155System.executeBurnBatch(alice, _asArray(tokenId), _asArray(80));
  }

  // TRANSFER

  function testForwardTransfer() public {
    mintSystem.executeTyped(alice, _asArray(tokenId), _asArray(100), '');

    vm.prank(alice);
    _expectEmitTransferBatch(alice);

    forwardTransferSystem.executeTyped(alice, bob, _asArray(tokenId), _asArray(80), '');
    assertEq(erc1155System.balanceOf(alice, tokenId), 20);
    assertEq(erc1155System.balanceOf(bob, tokenId), 80);
  }

  function testForwardNonOwnerTransfer() public {
    mintSystem.executeTyped(alice, _asArray(tokenId), _asArray(100), '');

    vm.prank(bob);
    vm.expectRevert(ERC1155BaseInternal.ERC1155Base__NotOwnerOrApproved.selector);

    forwardTransferSystem.executeTyped(alice, bob, _asArray(tokenId), _asArray(80), '');
  }

  function testForwardTransferUnauth() public {
    mintSystem.executeTyped(alice, _asArray(tokenId), _asArray(100), '');

    vm.prank(alice);
    vm.expectRevert(OwnableAndWriteAccess.OwnableAndWriteAccess__NotWriter.selector);

    unauthForwardTransferSystem.executeTyped(alice, bob, _asArray(tokenId), _asArray(80), '');
  }

  // this is the same as testForwardNonOwnerTransfer
  function testForwardTransferFromSystem() public {
    mintSystem.executeTyped(address(forwardTransferSystem), _asArray(tokenId), _asArray(100), '');

    vm.prank(bob);
    vm.expectRevert(ERC1155BaseInternal.ERC1155Base__NotOwnerOrApproved.selector);

    forwardTransferSystem.executeTyped(address(forwardTransferSystem), bob, _asArray(tokenId), _asArray(80), '');
  }

  // this is the same as testForwardTransferUnauth
  function testForwardTransferUnauthFromSystem() public {
    mintSystem.executeTyped(address(unauthForwardTransferSystem), _asArray(tokenId), _asArray(100), '');

    vm.prank(bob);
    vm.expectRevert(OwnableAndWriteAccess.OwnableAndWriteAccess__NotWriter.selector);

    unauthForwardTransferSystem.executeTyped(address(unauthForwardTransferSystem), bob, _asArray(tokenId), _asArray(80), '');
  }
}