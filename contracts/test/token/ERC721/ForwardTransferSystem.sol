// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { IWorld } from "@latticexyz/solecs/src/interfaces/IWorld.sol";
import { System, ISystem } from "@latticexyz/solecs/src/System.sol";
import { getAddressById } from "@latticexyz/solecs/src/utils.sol";

import { IERC721Receiver } from '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';

import { ERC721BaseSystem, ID as ERC721BaseSystemID } from "./ERC721BaseSystemMock.sol";

uint256 constant ID = uint256(keccak256("test.system.ForwardTransfer"));

contract ForwardTransferSystem is System, IERC721Receiver {
  constructor(
    IWorld _world,
    address _components
  ) System(_world, _components) {}

  function executeTyped(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public {
    execute(abi.encode(from, to, tokenId, data));
  }

  function execute(bytes memory arguments) public override returns (bytes memory) {
    (
      address from,
      address to,
      uint256 tokenId,
      bytes memory data
    ) = abi.decode(arguments, (address, address, uint256, bytes));

    ISystem erc721System = ISystem(
      getAddressById(world.systems(), ERC721BaseSystemID)
    );

    erc721System.execute(
      abi.encode(
        ERC721BaseSystem.executeSafeTransfer.selector,
        abi.encode(msg.sender, from, to, tokenId, data)
      )
    );

    return '';
  }

  // to test transfer from self
  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) public pure override returns (bytes4) {
    return this.onERC721Received.selector;
  }
}