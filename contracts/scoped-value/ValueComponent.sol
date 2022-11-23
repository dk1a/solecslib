// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { Uint256BareComponent } from "@latticexyz/std-contracts/src/components/Uint256BareComponent.sol";

contract ValueComponent is Uint256BareComponent {
  constructor(address world, uint256 id) Uint256BareComponent(world, id) {}
}