// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { IBaseWorld } from "@latticexyz/world/src/interfaces/IBaseWorld.sol";

import { ERC1155InternalSystem } from "../../../token/ERC1155/ERC1155InternalSystem.sol";
import { ERC1155Proxy } from "../../../token/ERC1155/ERC1155Proxy.sol";

contract ERC1155ProxyMock is ERC1155Proxy {
  constructor(
    IBaseWorld _world,
    bytes16 _namespace,
    bytes16 _systemFile,
    bytes16 _balanceFile,
    bytes16 _approvalFile
  ) ERC1155Proxy(_world, _namespace, _systemFile, _balanceFile, _approvalFile) {}

  // this is for hardhat tests
  function mint(
    address account,
    uint256 id,
    uint256 amount
  ) external {
    world.call(
      namespace,
      systemFile,
      abi.encodeWithSelector(
        ERC1155InternalSystem.safeMint.selector,
        account,
        id,
        amount, ""
      )
    );
  }

  // this is for hardhat tests
  function burn(
    address account,
    uint256 id,
    uint256 amount
  ) external {
    world.call(
      namespace,
      systemFile,
      abi.encodeWithSelector(
        ERC1155InternalSystem.burn.selector,
        account,
        id,
        amount, ""
      )
    );
  }
}