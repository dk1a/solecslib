// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.17;

import { ERC1155Test } from "./ERC1155Test.sol";

import { MintSystem } from "./utils/MintSystem.sol";
import { TransferSystem } from "./utils/TransferSystem.sol";

import { ERC1155AccessInternal } from "../token/ERC1155/logic/ERC1155AccessInternal.sol";

contract ForwardingTest is ERC1155Test {
  MintSystem badMintSystem;
  TransferSystem badTransferSystem;
  uint256 tokenId;

  function setUp() public virtual override {
    super.setUp();
  }

  function testOwnerSetForwarder() public {
    vm.prank(deployer);
    erc1155System.setTrustedForwarder(alice, true);

    assertTrue(
      erc1155System.isTrustedForwarder(alice)
    );
  }

  function testNotOwnerSetForwarder() public {
    vm.prank(alice);
    vm.expectRevert("ONLY_OWNER");
    erc1155System.setTrustedForwarder(alice, true);
  }

  function testForwardMint() public {
    mintSystem.executeTyped(alice, tokenId, 10, '');
    assertEq(erc1155System.balanceOf(alice, tokenId), 10);
  }

  function testTransfer() public {
    mintSystem.executeTyped(alice, tokenId, 100, '');

    vm.prank(alice);
    transferSystem.executeTyped(alice, bob, tokenId, 80, '');
    assertEq(erc1155System.balanceOf(alice, tokenId), 20);
    assertEq(erc1155System.balanceOf(bob, tokenId), 80);
  }

  function testNotOwnerTransfer() public {
    mintSystem.executeTyped(alice, tokenId, 100, '');

    vm.expectRevert(ERC1155AccessInternal.ERC1155Base__NotOwnerOrApproved.selector);
    transferSystem.executeTyped(alice, bob, tokenId, 80, '');
  }
}