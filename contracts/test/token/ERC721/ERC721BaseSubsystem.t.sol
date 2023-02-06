// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { BaseTest } from "./BaseTest.sol";

// errors
import { IOwnableInternal } from "@solidstate/contracts/access/ownable/IOwnableInternal.sol";
import { OwnableWritable } from "@latticexyz/solecs/src/OwnableWritable.sol";
import { ERC721BaseSubsystem } from "../../../token/ERC721/ERC721BaseSubsystem.sol";

contract ERC721BaseSystemTest is BaseTest {
  // EXECUTE

  function testInvalidExecute() public {
    vm.prank(deployer);
    vm.expectRevert(ERC721BaseSubsystem.ERC721BaseSubsystem__InvalidExecuteSelector.selector);
    ercSubsystem.execute(abi.encode(
      bytes4(keccak256("invalid selector")),
      bytes('data')
    ));
  }

  // AUTHORIZE

  function testOwnerAuthorizeWriter() public {
    vm.prank(deployer);
    ercSubsystem.authorizeWriter(alice);
    assertTrue(ercSubsystem.writeAccess(alice));
  }

  function testNotOwnerAuthorizeWriter() public {
    vm.prank(alice);
    vm.expectRevert(IOwnableInternal.Ownable__NotOwner.selector);
    ercSubsystem.authorizeWriter(alice);
  }

  // MINT

  function testMintDirectWriter() public {
    vm.prank(writer);
    ercSubsystem.executeSafeMint(alice, tokenId, '');
    assertEq(ercSubsystem.ownerOf(tokenId), alice);
  }

  function testMintDirectNotWriter() public {
    vm.prank(notWriter);
    vm.expectRevert(OwnableWritable.OwnableWritable__NotWriter.selector);
    ercSubsystem.executeSafeMint(alice, tokenId, '');
  }

  function _mintExec(address receiver, uint256 _tokenId) internal {
    ercSubsystem.execute(abi.encode(
      ercSubsystem.executeSafeMint.selector,
      abi.encode(receiver, _tokenId, '')
    ));
  }

  function testMintWriter() public {
    vm.prank(writer);
    _mintExec(alice, tokenId);
    assertEq(ercSubsystem.ownerOf(tokenId), alice);
  }

  function testMintNotWriter() public {
    vm.prank(notWriter);
    vm.expectRevert(OwnableWritable.OwnableWritable__NotWriter.selector);
    _mintExec(alice, tokenId);
  }

  function testMintOwner() public {
    vm.prank(deployer);
    _mintExec(alice, tokenId);
    assertEq(ercSubsystem.ownerOf(tokenId), alice);
  }

  // BURN

  function testBurnDirectWriter() public {
    _defaultMintToAlice();

    vm.prank(writer);
    ercSubsystem.executeBurn(tokenId);
    assertEq(ercSubsystem.balanceOf(alice), 0);
  }

  function testBurnDirectNotWriter() public {
    _defaultMintToAlice();

    vm.prank(notWriter);
    vm.expectRevert(OwnableWritable.OwnableWritable__NotWriter.selector);
    ercSubsystem.executeBurn(tokenId);
  }

  function _burnExec(uint256 _tokenId) internal {
    ercSubsystem.execute(abi.encode(
      ercSubsystem.executeBurn.selector,
      abi.encode(_tokenId)
    ));
  }

  function testBurnWriter() public {
    _defaultMintToAlice();

    vm.prank(writer);
    _burnExec(tokenId);
    assertEq(ercSubsystem.balanceOf(alice), 0);
  }

  function testBurnNotWriter() public {
    _defaultMintToAlice();

    vm.prank(notWriter);
    vm.expectRevert(OwnableWritable.OwnableWritable__NotWriter.selector);
    _burnExec(tokenId);
  }

  function testBurnOwner() public {
    _defaultMintToAlice();

    vm.prank(deployer);
    _burnExec(tokenId);
    assertEq(ercSubsystem.balanceOf(alice), 0);
  }

  // TRANSFER

  function testTransferDirectWriter() public {
    _defaultMintToAlice();

    vm.prank(writer);
    ercSubsystem.executeSafeTransfer(alice, alice, bob, tokenId, '');
    assertEq(ercSubsystem.ownerOf(tokenId), bob);
  }

  function testTransferDirectNotWriter() public {
    _defaultMintToAlice();

    vm.prank(notWriter);
    vm.expectRevert(OwnableWritable.OwnableWritable__NotWriter.selector);
    ercSubsystem.executeSafeTransfer(alice, alice, bob, tokenId, '');
  }

  function _transferExec(
    address operator,
    address from,
    address to,
    uint256 _tokenId,
    bytes memory data
  ) internal {
    ercSubsystem.execute(abi.encode(
      ercSubsystem.executeSafeTransfer.selector,
      abi.encode(operator, from, to, _tokenId, data)
    ));
  }

  function testTransferWriter() public {
    _defaultMintToAlice();

    vm.prank(writer);
    _transferExec(alice, alice, bob, tokenId, '');
    assertEq(ercSubsystem.ownerOf(tokenId), bob);
  }

  function testTransferNotWriter() public {
    _defaultMintToAlice();

    vm.prank(notWriter);
    vm.expectRevert(OwnableWritable.OwnableWritable__NotWriter.selector);
    _transferExec(alice, alice, bob, tokenId, '');
  }

  function testTransferOwner() public {
    _defaultMintToAlice();

    vm.prank(deployer);
    _transferExec(alice, alice, bob, tokenId, '');
    assertEq(ercSubsystem.ownerOf(tokenId), bob);
  }
}