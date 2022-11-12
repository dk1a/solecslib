// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.17;

import { Test } from "./Test.sol";

import { World } from "@latticexyz/solecs/src/World.sol";
import { MintableTokenSystem, ID as MintableTokenSystemID } from "./utils/MintableTokenSystem.sol";
import { MintSystem, ID as MintSystemID } from "./utils/MintSystem.sol";
import { TransferSystem, ID as TransferSystemID } from "./utils/TransferSystem.sol";

contract MudERC1155Test is Test {
  address deployer = address(bytes20(keccak256("deployer")));
  
  address alice = address(bytes20(keccak256("alice")));
  address bob = address(bytes20(keccak256("bob")));
  address eve = address(bytes20(keccak256("eve")));

  World world;
  // ERC1155 and ERC2771Context + execute which mints if isTrustedForwarder
  MintableTokenSystem tokenSystem;
  // forwards mint args and msgSender to tokenSystem's execute
  MintSystem mintSystem;
  // forwards safeTransferFrom args and msgSender to tokenSystem's safeTransferFrom
  TransferSystem transferSystem;
  
  function setUp() public virtual {
    vm.startPrank(deployer);

    // deploy world
    world = new World();
    world.init();

    address components = address(world.components());
    // deploy systems
    tokenSystem = new MintableTokenSystem(world, components);
    mintSystem = new MintSystem(world, components, MintableTokenSystemID);
    transferSystem = new TransferSystem(world, components, MintableTokenSystemID);
    // register systems
    world.registerSystem(address(tokenSystem), MintableTokenSystemID);
    world.registerSystem(address(mintSystem), MintSystemID);
    world.registerSystem(address(transferSystem), TransferSystemID);
    // allow forwarding msg.sender to tokenSystem
    tokenSystem.setTrustedForwarder(address(mintSystem), true);
    tokenSystem.setTrustedForwarder(address(transferSystem), true);

    vm.stopPrank();
  }
}