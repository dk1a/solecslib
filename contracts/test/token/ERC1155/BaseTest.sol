// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { PRBTest } from "@prb/test/src/PRBTest.sol";

// ECS
import { World } from "@latticexyz/solecs/src/World.sol";
// systems
import { ERC1155BaseSystemMock, ID as ERC1155BaseSystemMockID } from "./ERC1155BaseSystemMock.sol";

// ERC1155 events
import { IERC1155Internal } from "@solidstate/contracts/interfaces/IERC1155Internal.sol";

contract BaseTest is
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

  uint256 tokenId = 1337;

  function setUp() public virtual {
    vm.startPrank(deployer);

    // deploy world
    world = new World();
    world.init();

    address components = address(world.components());
    // deploy systems
    ercSystem = new ERC1155BaseSystemMock(world, components);
    // register systems
    world.registerSystem(address(ercSystem), ERC1155BaseSystemMockID);
    // allows calling ercSystem's execute
    ercSystem.authorizeWriter(writer);

    vm.stopPrank();
  }

  // HELPERS

  function _defaultMintToAlice() internal {
    vm.prank(writer);
    ercSystem.executeSafeMintBatch(alice, _asArray(tokenId), _asArray(100), '');
  }

  function _asArray(uint256 number) internal pure returns (uint256[] memory result) {
    result = new uint256[](1);
    result[0] = number;
  }
}