// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { BaseTest } from "./BaseTest.sol";

// errors
import { IOwnableInternal } from "@solidstate/contracts/access/ownable/IOwnableInternal.sol";
import { OwnableAndWriteAccess } from "../../../mud/OwnableAndWriteAccess.sol";
import { ERC1155BaseSystem } from "../../../token/ERC1155/ERC1155BaseSystem.sol";

contract ERC1155BaseSystemTest is BaseTest {
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

  // APPROVAL FOR ALL

  function testApprovalDirectWriter() public {
    vm.prank(writer);
    ercSystem.executeSetApprovalForAll(alice, bob, true);
    assertTrue(ercSystem.isApprovedForAll(alice, bob));
  }

  function testApprovalDirectNotWriter() public {
    vm.prank(notWriter);
    vm.expectRevert(OwnableAndWriteAccess.OwnableAndWriteAccess__NotWriter.selector);
    ercSystem.executeSetApprovalForAll(alice, bob, true);
  }

  function _approvalExec(address account, address operator) internal {
    ercSystem.execute(abi.encode(
      ercSystem.executeSetApprovalForAll.selector,
      abi.encode(account, operator, true)
    ));
  }

  function testApprovalWriter() public {
    vm.prank(writer);
    _approvalExec(alice, bob);
    assertTrue(ercSystem.isApprovedForAll(alice, bob));
  }

  function testApprovalNotWriter() public {
    vm.prank(notWriter);
    vm.expectRevert(OwnableAndWriteAccess.OwnableAndWriteAccess__NotWriter.selector);
    _approvalExec(alice, bob);
  }

  function testApprovalOwner() public {
    vm.prank(deployer);
    _approvalExec(alice, bob);
    assertTrue(ercSystem.isApprovedForAll(alice, bob));
  }
}