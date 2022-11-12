// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.17;

import { BareComponent } from "@latticexyz/solecs/src/BareComponent.sol";
import { LibTypes } from "@latticexyz/solecs/src/LibTypes.sol";

/**
 * @dev Balance entity = hashed(account, id)
 */
function getBalanceEntity(address account, uint256 id) pure returns (uint256) {
  return uint256(keccak256(abi.encode(account, id)));
}

contract BalancesComponent is BareComponent {
  constructor(address world, uint256 id) BareComponent(world, id) {}

  function getSchema() public pure override returns (string[] memory keys, LibTypes.SchemaValue[] memory values) {
    keys = new string[](1);
    values = new LibTypes.SchemaValue[](1);

    keys[0] = "value";
    values[0] = LibTypes.SchemaValue.UINT256;
  }

  function set(uint256 entity, uint256 value) public {
    set(entity, abi.encode(value));
  }

  function getValue(uint256 entity) public view returns (uint256) {
    bytes memory rawValue = getRawValue(entity);
    if (rawValue.length > 0) {
      return abi.decode(rawValue, (uint256));
    } else {
      return 0;
    }
  }
}