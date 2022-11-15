// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.17;

import { PRBTest } from "@prb/test/src/PRBTest.sol";

import { World } from "@latticexyz/solecs/src/World.sol";
import { ERC1155BaseSystemMock, ID as ERC1155BaseSystemMockID } from "./utils/ERC1155BaseSystemMock.sol";
import { BurnSystem, ID as BurnSystemID } from "./utils/BurnSystem.sol";
import { MintSystem, ID as MintSystemID } from "./utils/MintSystem.sol";
import { TransferSystem, ID as TransferSystemID } from "./utils/TransferSystem.sol";

contract ERC1155Test is PRBTest {
  address deployer = address(bytes20(keccak256("deployer")));
  
  address alice = address(bytes20(keccak256("alice")));
  address bob = address(bytes20(keccak256("bob")));
  address eve = address(bytes20(keccak256("eve")));

  World world;
  // ERC1155 and ERC2771Context and System
  ERC1155BaseSystemMock erc1155System;
  // forwards burn args and msgSender to erc1155System's execute
  BurnSystem burnSystem;
  // forwards mint args and msgSender to erc1155System's execute
  MintSystem mintSystem;
  // forwards safeTransferFrom args and msgSender to erc1155System's safeTransferFrom
  TransferSystem transferSystem;
  
  function setUp() public virtual {
    vm.startPrank(deployer);

    // deploy world
    world = new World();
    world.init();

    address components = address(world.components());
    // deploy systems
    erc1155System = new ERC1155BaseSystemMock(world, components);
    burnSystem = new BurnSystem(world, components, ERC1155BaseSystemMockID);
    mintSystem = new MintSystem(world, components, ERC1155BaseSystemMockID);
    transferSystem = new TransferSystem(world, components, ERC1155BaseSystemMockID);
    // register systems
    world.registerSystem(address(erc1155System), ERC1155BaseSystemMockID);
    world.registerSystem(address(burnSystem), MintSystemID);
    world.registerSystem(address(mintSystem), MintSystemID);
    world.registerSystem(address(transferSystem), TransferSystemID);
    // allow forwarding msg.sender to erc1155System,
    // also allows mints/burns/arbitrary transfers
    erc1155System.setTrustedForwarder(address(burnSystem), true);
    erc1155System.setTrustedForwarder(address(mintSystem), true);
    erc1155System.setTrustedForwarder(address(transferSystem), true);

    vm.stopPrank();
  }
}