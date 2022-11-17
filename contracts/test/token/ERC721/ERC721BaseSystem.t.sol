// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { PRBTest } from "@prb/test/src/PRBTest.sol";

// ECS
import { World } from "@latticexyz/solecs/src/World.sol";
// systems
import { ForwardTransferSystem, ID as ForwardTransferSystemID } from "./ForwardTransferSystem.sol";
import { ERC721BaseSystemMock, ID as ERC721BaseSystemMockID } from "./ERC721BaseSystemMock.sol";

// ERC721 events
import { IERC721Internal } from "@solidstate/contracts/interfaces/IERC721Internal.sol";

// errors
import { IOwnableInternal } from "@solidstate/contracts/access/ownable/IOwnableInternal.sol";
import { OwnableAndWriteAccess } from "../../../mud/OwnableAndWriteAccess.sol";
import { ERC721BaseSystem } from "../../../token/ERC721/ERC721BaseSystem.sol";
import { ERC721BaseInternal } from "../../../token/ERC721/logic/ERC721BaseInternal.sol";

contract ERC721BaseSystemTest is
  PRBTest,
  IERC721Internal
{
  address deployer = address(bytes20(keccak256("deployer")));
  
  address alice = address(bytes20(keccak256("alice")));
  address bob = address(bytes20(keccak256("bob")));
  address eve = address(bytes20(keccak256("eve")));

  address writer = address(bytes20(keccak256("writer")));
  address notWriter = address(bytes20(keccak256("notWriter")));

  World world;
  // ERC721 System
  ERC721BaseSystemMock ercSystem;
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
    ercSystem = new ERC721BaseSystemMock(world, components);
    forwardTransferSystem = new ForwardTransferSystem(world, components);
    unauthForwardTransferSystem = new ForwardTransferSystem(world, components);
    // register systems
    world.registerSystem(address(ercSystem), ERC721BaseSystemMockID);
    world.registerSystem(address(forwardTransferSystem), ForwardTransferSystemID);
    world.registerSystem(address(unauthForwardTransferSystem), uint256(keccak256('unauthForwardTransferSystem')));
    // allows calling ercSystem's execute
    ercSystem.authorizeWriter(address(forwardTransferSystem));
    ercSystem.authorizeWriter(writer);

    vm.stopPrank();
  }

  // HELPERS

  function _defaultMintToAlice() internal {
    vm.prank(writer);
    _mintExec(alice, tokenId);
  }

  // EXECUTE

  function testInvalidExecute() public {
    vm.prank(deployer);
    vm.expectRevert(ERC721BaseSystem.ERC721BaseSystem__InvalidExecuteSelector.selector);
    ercSystem.execute(abi.encode(
      bytes4(keccak256("invalid selector")),
      bytes('data')
    ));
  }

  // AUTHORIZE

  function testOwnerAuthorizeWriter() public {
    vm.prank(deployer);
    ercSystem.authorizeWriter(alice);
    assertTrue(ercSystem.writeAccess(alice));
  }

  function testNotOwnerAuthorizeWriter() public {
    vm.prank(alice);
    vm.expectRevert(IOwnableInternal.Ownable__NotOwner.selector);
    ercSystem.authorizeWriter(alice);
  }

  // MINT

  function testMintDirectWriter() public {
    vm.prank(writer);
    ercSystem.executeSafeMint(alice, tokenId, '');
    assertEq(ercSystem.ownerOf(tokenId), alice);
  }

  function testMintDirectNotWriter() public {
    vm.prank(notWriter);
    vm.expectRevert(OwnableAndWriteAccess.OwnableAndWriteAccess__NotWriter.selector);
    ercSystem.executeSafeMint(alice, tokenId, '');
  }

  function _mintExec(address receiver, uint256 _tokenId) internal {
    ercSystem.execute(abi.encode(
      ercSystem.executeSafeMint.selector,
      abi.encode(receiver, _tokenId, '')
    ));
  }

  function testMintWriter() public {
    vm.prank(writer);
    _mintExec(alice, tokenId);
    assertEq(ercSystem.ownerOf(tokenId), alice);
  }

  function testMintNotWriter() public {
    vm.prank(notWriter);
    vm.expectRevert(OwnableAndWriteAccess.OwnableAndWriteAccess__NotWriter.selector);
    _mintExec(alice, tokenId);
  }

  function testMintOwner() public {
    vm.prank(deployer);
    _mintExec(alice, tokenId);
    assertEq(ercSystem.ownerOf(tokenId), alice);
  }

  // BURN

  function testBurnDirectWriter() public {
    _defaultMintToAlice();

    vm.prank(writer);
    ercSystem.executeBurn(tokenId);
    assertEq(ercSystem.balanceOf(alice), 0);
  }

  function testBurnDirectNotWriter() public {
    _defaultMintToAlice();

    vm.prank(notWriter);
    vm.expectRevert(OwnableAndWriteAccess.OwnableAndWriteAccess__NotWriter.selector);
    ercSystem.executeBurn(tokenId);
  }

  function _burnExec(uint256 _tokenId) internal {
    ercSystem.execute(abi.encode(
      ercSystem.executeBurn.selector,
      abi.encode(_tokenId)
    ));
  }

  function testBurnWriter() public {
    _defaultMintToAlice();

    vm.prank(writer);
    _burnExec(tokenId);
    assertEq(ercSystem.balanceOf(alice), 0);
  }

  function testBurnNotWriter() public {
    _defaultMintToAlice();

    vm.prank(notWriter);
    vm.expectRevert(OwnableAndWriteAccess.OwnableAndWriteAccess__NotWriter.selector);
    _burnExec(tokenId);
  }

  function testBurnOwner() public {
    _defaultMintToAlice();

    vm.prank(deployer);
    _burnExec(tokenId);
    assertEq(ercSystem.balanceOf(alice), 0);
  }

  // TRANSFER

  function testTransferDirectWriter() public {
    _defaultMintToAlice();

    vm.prank(writer);
    ercSystem.executeSafeTransfer(alice, alice, bob, tokenId, '');
    assertEq(ercSystem.ownerOf(tokenId), bob);
  }

  function testTransferDirectNotWriter() public {
    _defaultMintToAlice();

    vm.prank(notWriter);
    vm.expectRevert(OwnableAndWriteAccess.OwnableAndWriteAccess__NotWriter.selector);
    ercSystem.executeSafeTransfer(alice, alice, bob, tokenId, '');
  }

  function _transferExec(
    address operator,
    address from,
    address to,
    uint256 _tokenId,
    bytes memory data
  ) internal {
    ercSystem.execute(abi.encode(
      ercSystem.executeSafeTransfer.selector,
      abi.encode(operator, from, to, _tokenId, data)
    ));
  }

  function testTransferWriter() public {
    _defaultMintToAlice();

    vm.prank(writer);
    _transferExec(alice, alice, bob, tokenId, '');
    assertEq(ercSystem.ownerOf(tokenId), bob);
  }

  function testTransferNotWriter() public {
    _defaultMintToAlice();

    vm.prank(notWriter);
    vm.expectRevert(OwnableAndWriteAccess.OwnableAndWriteAccess__NotWriter.selector);
    _transferExec(alice, alice, bob, tokenId, '');
  }

  function testTransferOwner() public {
    _defaultMintToAlice();

    vm.prank(deployer);
    _transferExec(alice, alice, bob, tokenId, '');
    assertEq(ercSystem.ownerOf(tokenId), bob);
  }

  // FORWARD TRANSFER

  function testForwardTransfer() public {
    _defaultMintToAlice();

    assertEq(ercSystem.ownerOf(tokenId), alice);

    vm.prank(alice);
    forwardTransferSystem.executeTyped(alice, bob, tokenId, '');

    assertEq(ercSystem.ownerOf(tokenId), bob);
  }

  function testForwardNotOwnerTransfer() public {
    _defaultMintToAlice();

    assertEq(ercSystem.ownerOf(tokenId), alice);

    vm.prank(bob);
    vm.expectRevert(ERC721BaseInternal.ERC721Base__NotOwnerOrApproved.selector);
    forwardTransferSystem.executeTyped(alice, bob, tokenId, '');
  }

  function testForwardNotOwnerTransferFromForwarder() public {
    vm.prank(writer);
    _mintExec(address(forwardTransferSystem), tokenId);

    assertEq(ercSystem.ownerOf(tokenId), address(forwardTransferSystem));

    vm.prank(bob);
    vm.expectRevert(ERC721BaseInternal.ERC721Base__NotOwnerOrApproved.selector);
    forwardTransferSystem.executeTyped(address(forwardTransferSystem), bob, tokenId, '');
  }
}