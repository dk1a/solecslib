// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { PRBTest } from "@prb/test/src/PRBTest.sol";

// ECS
import { World } from "@latticexyz/solecs/src/World.sol";
// systems
import { ERC721BaseSystemMock, ID as ERC721BaseSystemMockID } from "./ERC721BaseSystemMock.sol";

// ERC721 events
import { IERC721Internal } from "@solidstate/contracts/interfaces/IERC721Internal.sol";

contract BaseTest is
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

  uint256 tokenId = 1337;

  function setUp() public virtual {
    vm.startPrank(deployer);

    // deploy world
    world = new World();
    world.init();

    address components = address(world.components());
    // deploy systems
    ercSystem = new ERC721BaseSystemMock(world, components);
    // register systems
    world.registerSystem(address(ercSystem), ERC721BaseSystemMockID);
    // allows calling ercSystem's execute
    ercSystem.authorizeWriter(writer);

    vm.stopPrank();
  }

  // HELPERS

  function _defaultMintToAlice() internal {
    vm.prank(writer);
    ercSystem.executeSafeMint(alice, tokenId, '');
  }
}