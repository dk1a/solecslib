// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { BaseTest } from "./BaseTest.sol";

// errors
import { IOwnableInternal } from "@solidstate/contracts/access/ownable/IOwnableInternal.sol";
import { OwnableAndWriteAccess } from "../../../mud/OwnableAndWriteAccess.sol";
import { ERC721BaseSystem } from "../../../token/ERC721/ERC721BaseSystem.sol";

contract ERC721BaseSystemTest is BaseTest {
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
}