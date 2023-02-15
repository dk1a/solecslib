// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { StringComponent } from "@latticexyz/std-contracts/src/components/StringComponent.sol";

contract ScopeComponent is StringComponent {
  constructor(address _world, uint256 _id) StringComponent(_world, _id) {}
}