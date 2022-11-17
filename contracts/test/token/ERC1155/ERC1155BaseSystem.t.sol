// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { PRBTest } from "@prb/test/src/PRBTest.sol";

// ECS
import { World } from "@latticexyz/solecs/src/World.sol";
// systems
import { ForwardTransferSystem, ID as ForwardTransferSystemID } from "./ForwardTransferSystem.sol";
import { ERC1155BaseSystemMock, ID as ERC1155BaseSystemMockID } from "./ERC1155BaseSystemMock.sol";

// ERC1155 events
import { IERC1155Internal } from "@solidstate/contracts/interfaces/IERC1155Internal.sol";

// errors
import { IOwnableInternal } from "@solidstate/contracts/access/ownable/IOwnableInternal.sol";
import { OwnableAndWriteAccess } from "../../../mud/OwnableAndWriteAccess.sol";
import { ERC1155BaseSystem } from "../../../token/ERC1155/ERC1155BaseSystem.sol";
import { ERC1155BaseInternal } from "../../../token/ERC1155/logic/ERC1155BaseInternal.sol";

contract ERC1155BaseSystemTest is
  PRBTest,
  IERC1155Internal
{
  address deployer = address(bytes20(keccak256("deployer")));
  
  address alice = address(bytes20(keccak256("alice")));
  address bob = address(bytes20(keccak256("bob")));
  address eve = address(bytes20(keccak256("eve")));

  address writer = address(bytes20(keccak256("writer")));
  address notWriter = address(bytes20(keccak256("notWriter")));

  World world;
  // ERC1155 System
  ERC1155BaseSystemMock ercSystem;
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
    ercSystem = new ERC1155BaseSystemMock(world, components);
    forwardTransferSystem = new ForwardTransferSystem(world, components);
    unauthForwardTransferSystem = new ForwardTransferSystem(world, components);
    // register systems
    world.registerSystem(address(ercSystem), ERC1155BaseSystemMockID);
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

  function _asArray(uint256 number) internal pure returns (uint256[] memory result) {
    result = new uint256[](1);
    result[0] = number;
  }

  // only operator is important for forwarding, ERC1155 events are tested elsewhere
  function _expectEmitTransferBatch(address operator) internal {
    vm.expectEmit(true, false, false, false);
    emit TransferBatch(operator, address(0), address(0), _asArray(0), _asArray(0));
  }

  // EXECUTE

  function testInvalidExecute() public {
    vm.prank(deployer);
    vm.expectRevert(ERC1155BaseSystem.ERC1155BaseSystem__InvalidExecuteSelector.selector);
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
    ercSystem.executeSafeMintBatch(alice, _asArray(tokenId), _asArray(100), '');
    assertEq(ercSystem.balanceOf(alice, tokenId), 100);
  }

  function testMintDirectNotWriter() public {
    vm.prank(notWriter);
    vm.expectRevert(OwnableAndWriteAccess.OwnableAndWriteAccess__NotWriter.selector);
    ercSystem.executeSafeMintBatch(alice, _asArray(tokenId), _asArray(100), '');
  }

  function _mintExec(address receiver, uint256 _tokenId) internal {
    ercSystem.execute(abi.encode(
      ercSystem.executeSafeMintBatch.selector,
      abi.encode(receiver, _asArray(_tokenId), _asArray(100), '')
    ));
  }

  function testMintWriter() public {
    vm.prank(writer);
    _mintExec(alice, tokenId);
    assertEq(ercSystem.balanceOf(alice, tokenId), 100);
  }

  function testMintNotWriter() public {
    vm.prank(notWriter);
    vm.expectRevert(OwnableAndWriteAccess.OwnableAndWriteAccess__NotWriter.selector);
    _mintExec(alice, tokenId);
  }

  function testMintOwner() public {
    vm.prank(deployer);
    _mintExec(alice, tokenId);
    assertEq(ercSystem.balanceOf(alice, tokenId), 100);
  }

  // BURN

  function testBurnDirectWriter() public {
    _defaultMintToAlice();

    vm.prank(writer);
    ercSystem.executeBurnBatch(alice, _asArray(tokenId), _asArray(80));
    assertEq(ercSystem.balanceOf(alice, tokenId), 20);
  }

  function testBurnDirectNotWriter() public {
    _defaultMintToAlice();

    vm.prank(notWriter);
    vm.expectRevert(OwnableAndWriteAccess.OwnableAndWriteAccess__NotWriter.selector);
    ercSystem.executeBurnBatch(alice, _asArray(tokenId), _asArray(80));
  }

  function _burnExec(address account, uint256 _tokenId) internal {
    ercSystem.execute(abi.encode(
      ercSystem.executeBurnBatch.selector,
      abi.encode(account, _asArray(_tokenId), _asArray(80))
    ));
  }

  function testBurnWriter() public {
    _defaultMintToAlice();

    vm.prank(writer);
    _burnExec(alice, tokenId);
    assertEq(ercSystem.balanceOf(alice, tokenId), 20);
  }

  function testBurnNotWriter() public {
    _defaultMintToAlice();

    vm.prank(notWriter);
    vm.expectRevert(OwnableAndWriteAccess.OwnableAndWriteAccess__NotWriter.selector);
    _burnExec(alice, tokenId);
  }

  function testBurnOwner() public {
    _defaultMintToAlice();

    vm.prank(deployer);
    _burnExec(alice, tokenId);
    assertEq(ercSystem.balanceOf(alice, tokenId), 20);
  }

  // TRANSFER

  function testTransferDirectWriter() public {
    _defaultMintToAlice();

    vm.prank(writer);
    ercSystem.executeSafeTransferBatch(alice, alice, bob, _asArray(tokenId), _asArray(80), '');
    assertEq(ercSystem.balanceOf(alice, tokenId), 20);
    assertEq(ercSystem.balanceOf(bob, tokenId), 80);
  }

  function testTransferDirectNotWriter() public {
    _defaultMintToAlice();

    vm.prank(notWriter);
    vm.expectRevert(OwnableAndWriteAccess.OwnableAndWriteAccess__NotWriter.selector);
    ercSystem.executeSafeTransferBatch(alice, alice, bob, _asArray(tokenId), _asArray(80), '');
  }

  function _transferExec(
    address operator,
    address from,
    address to,
    uint256 _tokenId,
    uint256 amount,
    bytes memory data
  ) internal {
    ercSystem.execute(abi.encode(
      ercSystem.executeSafeTransferBatch.selector,
      abi.encode(operator, from, to, _asArray(_tokenId), _asArray(amount), data)
    ));
  }

  function testTransferWriter() public {
    _defaultMintToAlice();

    vm.prank(writer);
    _transferExec(alice, alice, bob, tokenId, 80, '');
    assertEq(ercSystem.balanceOf(alice, tokenId), 20);
    assertEq(ercSystem.balanceOf(bob, tokenId), 80);
  }

  function testTransferNotWriter() public {
    _defaultMintToAlice();

    vm.prank(notWriter);
    vm.expectRevert(OwnableAndWriteAccess.OwnableAndWriteAccess__NotWriter.selector);
    _transferExec(alice, alice, bob, tokenId, 80, '');
  }

  function testTransferOwner() public {
    _defaultMintToAlice();

    vm.prank(deployer);
    _transferExec(alice, alice, bob, tokenId, 80, '');
    assertEq(ercSystem.balanceOf(alice, tokenId), 20);
    assertEq(ercSystem.balanceOf(bob, tokenId), 80);
  }

  // FORWARD TRANSFER

  function testForwardTransfer() public {
    _defaultMintToAlice();

    assertEq(ercSystem.balanceOf(alice, tokenId), 100);

    vm.prank(alice);
    _expectEmitTransferBatch(alice);
    forwardTransferSystem.executeTyped(alice, bob, _asArray(tokenId), _asArray(80), '');

    assertEq(ercSystem.balanceOf(alice, tokenId), 20);
    assertEq(ercSystem.balanceOf(bob, tokenId), 80);
  }

  function testForwardNotOwnerTransfer() public {
    _defaultMintToAlice();

    assertEq(ercSystem.balanceOf(alice, tokenId), 100);

    vm.prank(bob);
    vm.expectRevert(ERC1155BaseInternal.ERC1155Base__NotOwnerOrApproved.selector);
    forwardTransferSystem.executeTyped(alice, bob, _asArray(tokenId), _asArray(80), '');
  }

  function testForwardNotOwnerTransferFromForwarder() public {
    vm.prank(writer);
    _mintExec(address(forwardTransferSystem), tokenId);

    assertEq(ercSystem.balanceOf(address(forwardTransferSystem), tokenId), 100);

    vm.prank(bob);
    vm.expectRevert(ERC1155BaseInternal.ERC1155Base__NotOwnerOrApproved.selector);
    forwardTransferSystem.executeTyped(alice, bob, _asArray(tokenId), _asArray(80), '');
  }
}