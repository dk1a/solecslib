// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.17;

// this is just the ERC1155 events
import { IERC1155Internal } from "@solidstate/contracts/interfaces/IERC1155Internal.sol";

import { ERC1155Test } from "./ERC1155Test.sol";

import { ERC1155BaseSystem, ID as ERC1155BaseSystemMockID } from "./utils/ERC1155BaseSystemMock.sol";
import { BurnSystem } from "./utils/BurnSystem.sol";
import { MintSystem } from "./utils/MintSystem.sol";
import { TransferSystem } from "./utils/TransferSystem.sol";

import { ERC1155AccessInternal } from "../token/ERC1155/logic/ERC1155AccessInternal.sol";
import { ERC1155BalanceInternal } from "../token/ERC1155/logic/ERC1155BalanceInternal.sol";

contract ForwardingTest is
  ERC1155Test,
  IERC1155Internal
{
  BurnSystem untrustedBurnSystem;
  MintSystem untrustedMintSystem;
  TransferSystem untrustedTransferSystem;
  uint256 tokenId;

  function setUp() public virtual override {
    super.setUp();

    address components = address(world.components());
    // deploy untrusted systems
    untrustedBurnSystem = new BurnSystem(world, components, ERC1155BaseSystemMockID);
    untrustedMintSystem = new MintSystem(world, components, ERC1155BaseSystemMockID);
    untrustedTransferSystem = new TransferSystem(world, components, ERC1155BaseSystemMockID);
  }

  // HELPERS

  function _asArray(uint256 number) internal pure returns (uint256[] memory result) {
    result = new uint256[](1);
    result[0] = number;
  }

  // only operator is important for forwarding, ERC1155 events are tested elsewhere
  function _expectEmitTransferSingle(address operator) internal {
    vm.expectEmit(true, false, false, false);
    emit TransferSingle(operator, address(0), address(0), 0, 0);
  }

  // only operator is important for forwarding, ERC1155 events are tested elsewhere
  function _expectEmitTransferBatch(address operator) internal {
    vm.expectEmit(true, false, false, false);
    emit TransferBatch(operator, address(0), address(0), new uint256[](0), new uint256[](0));
  }

  // FORWARDER

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

  // MINT

  function testForwardMint() public {
    vm.prank(bob);
    _expectEmitTransferBatch(bob);

    mintSystem.executeTyped(alice, _asArray(tokenId), _asArray(10), '');
    assertEq(erc1155System.balanceOf(alice, tokenId), 10);
  }

  function testForwardMintUntrusted() public {
    vm.expectRevert(ERC1155BaseSystem.ERC1155BaseSystem__NotTrustedExecutor.selector);
    untrustedMintSystem.executeTyped(alice, _asArray(tokenId), _asArray(10), '');
  }

  // BURN

  function testForwardBurn() public {
    mintSystem.executeTyped(alice, _asArray(tokenId), _asArray(100), '');

    vm.prank(bob);
    _expectEmitTransferBatch(bob);

    burnSystem.executeTyped(alice, _asArray(tokenId), _asArray(80));

    assertEq(erc1155System.balanceOf(alice, tokenId), 20);
  }

  function testForwardBurnUntrusted() public {
    mintSystem.executeTyped(alice, _asArray(tokenId), _asArray(100), '');

    vm.prank(bob);
    vm.expectRevert(ERC1155BaseSystem.ERC1155BaseSystem__NotTrustedExecutor.selector);

    untrustedBurnSystem.executeTyped(alice, _asArray(tokenId), _asArray(80));
  }

  // TRANSFER

  function testForwardTransfer() public {
    mintSystem.executeTyped(alice, _asArray(tokenId), _asArray(100), '');

    vm.prank(alice);
    _expectEmitTransferSingle(alice);

    transferSystem.executeTyped(alice, bob, tokenId, 80, '');
    assertEq(erc1155System.balanceOf(alice, tokenId), 20);
    assertEq(erc1155System.balanceOf(bob, tokenId), 80);
  }

  function testForwardTransferNotOwner() public {
    mintSystem.executeTyped(alice, _asArray(tokenId), _asArray(100), '');

    vm.prank(bob);
    vm.expectRevert(ERC1155AccessInternal.ERC1155Base__NotOwnerOrApproved.selector);

    transferSystem.executeTyped(alice, bob, tokenId, 80, '');
  }

  function testForwardTransferUntrusted() public {
    mintSystem.executeTyped(alice, _asArray(tokenId), _asArray(100), '');

    vm.prank(alice);
    vm.expectRevert(ERC1155AccessInternal.ERC1155Base__NotOwnerOrApproved.selector);

    untrustedTransferSystem.executeTyped(alice, bob, tokenId, 80, '');
  }

  // this is the same as testForwardTransferNotOwner, but the next variation is interesting
  function testForwardTransferFromSystem() public {
    mintSystem.executeTyped(address(transferSystem), _asArray(tokenId), _asArray(100), '');

    vm.prank(bob);
    vm.expectRevert(ERC1155AccessInternal.ERC1155Base__NotOwnerOrApproved.selector);

    untrustedTransferSystem.executeTyped(address(transferSystem), bob, tokenId, 80, '');
  }

  // An edge case where untrustedTransferSystem's transfer actually succeeds
  // because non-arbitrary transfer just checks operator approval,
  // and although msg.sender forwarding is disabled,
  // transfers from owner (or approved) are still allowed
  function testForwardTransferUntrustedFromSystem() public {
    mintSystem.executeTyped(address(untrustedTransferSystem), _asArray(tokenId), _asArray(100), '');

    vm.prank(bob);
    _expectEmitTransferSingle(address(untrustedTransferSystem));

    untrustedTransferSystem.executeTyped(address(untrustedTransferSystem), bob, tokenId, 80, '');
    assertEq(erc1155System.balanceOf(address(untrustedTransferSystem), tokenId), 20);
    assertEq(erc1155System.balanceOf(bob, tokenId), 80);
  }
}