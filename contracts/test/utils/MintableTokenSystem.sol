// SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.17;

import { IWorld } from "@latticexyz/solecs/src/interfaces/IWorld.sol";
import { MudERC1155 } from '../../token/ERC1155/MudERC1155.sol';

uint256 constant ID = uint256(keccak256("test.system.MintableTokenSystem"));

uint256 constant balancesComponentId = uint256(keccak256(
  abi.encode(ID, "component.Balances")
));
uint256 constant operatorApprovalsComponentId = uint256(keccak256(
  abi.encode(ID, "component.OperatorApprovals")
));

contract MintableTokenSystem is MudERC1155 {
  error MintableTokenSystem__InvalidCaller();

  constructor(
    IWorld _world,
    address _components
  ) MudERC1155(_world, _components, balancesComponentId, operatorApprovalsComponentId) {}

  function execute(bytes memory args) public virtual override returns (bytes memory) {
    // limited execute with only 1 branch for testing
    if (isTrustedForwarder(msg.sender)) {
      _executeSafeMint(args);
    } else {
      revert MintableTokenSystem__InvalidCaller();
    }

    return '';
  }

  function _executeSafeMint(bytes memory args) private {
    (address account, uint256 id, uint256 amount, bytes memory data)
      = abi.decode(args, (address, uint256, uint256, bytes));

    _safeMint(account, id, amount, data);
  }
}