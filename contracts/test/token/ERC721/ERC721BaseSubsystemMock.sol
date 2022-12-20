// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { IWorld } from "@latticexyz/solecs/src/interfaces/IWorld.sol";
import { ERC721BaseSubsystem } from '../../../token/ERC721/ERC721BaseSubsystem.sol';

uint256 constant ID = uint256(keccak256("mock.system.ERC721Base"));

uint256 constant ownershipComponentId = uint256(keccak256(
  abi.encode(ID, "mock.component.Ownership")
));
uint256 constant operatorApprovalComponentId = uint256(keccak256(
  abi.encode(ID, "mock.component.OperatorApproval")
));
uint256 constant tokenApprovalComponentId = uint256(keccak256(
  abi.encode(ID, "mock.component.TokenApproval")
));

contract ERC721BaseSubsystemMock is ERC721BaseSubsystem {
  error ERC721BaseSubsystemMock__InvalidCaller();

  constructor(
    IWorld _world,
    address _components
  ) ERC721BaseSubsystem(_world, _components, ownershipComponentId, operatorApprovalComponentId, tokenApprovalComponentId) {}

  // this is for hardhat tests
  function mint(
    address account,
    uint256 tokenId
  ) external {
    _safeMint(account, tokenId, '');
  }

  // this is for hardhat tests
  function burn(
    uint256 tokenId
  ) external {
    _burn(tokenId);
  }
}