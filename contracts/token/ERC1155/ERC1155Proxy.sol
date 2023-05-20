// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { IERC165 } from "@solidstate/contracts/interfaces/IERC165.sol";
import { IERC1155 } from "@solidstate/contracts/interfaces/IERC1155.sol";
import { IERC1155BaseInternal } from "@solidstate/contracts/token/ERC1155/base/IERC1155BaseInternal.sol";

import { IBaseWorld } from "@latticexyz/world/src/interfaces/IBaseWorld.sol";
import { ResourceSelector } from "@latticexyz/world/src/ResourceSelector.sol";

import { OperatorApproval } from "../../codegen/tables/OperatorApproval.sol";
import { Balance } from "../../codegen/tables/Balance.sol";
import { ERC1155InternalSystem } from "./ERC1155InternalSystem.sol";

contract ERC1155Proxy is
  IERC165,
  IERC1155
{
  // World and System that will be proxied
  IBaseWorld immutable world;
  bytes16 immutable namespace;

  bytes16 immutable systemFile;

  bytes32 immutable balanceTableId;
  bytes32 immutable approvalTableId;

  constructor(
    IBaseWorld _world,
    bytes16 _namespace,
    bytes16 _systemFile,
    bytes16 _balanceFile,
    bytes16 _approvalFile
  ) {
    world = _world;
    namespace = _namespace;

    systemFile = _systemFile;

    balanceTableId = ResourceSelector.from(namespace, _balanceFile);
    approvalTableId = ResourceSelector.from(namespace, _approvalFile);
  }

  function supportsInterface(bytes4 interfaceId) external view virtual override returns (bool) {
    return 
      interfaceId == type(IERC1155).interfaceId ||
      interfaceId == type(IERC165).interfaceId;
  }

  /**
   * @inheritdoc IERC1155
   */
  function balanceOf(address account, uint256 id)
    public
    view
    virtual
    returns (uint256)
  {
    if (account == address(0)) revert IERC1155BaseInternal.ERC1155Base__BalanceQueryZeroAddress();
    return Balance.get(world, balanceTableId, account, id);
  }

  /**
   * @inheritdoc IERC1155
   */
  function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
    public
    view
    virtual
    returns (uint256[] memory)
  {
    if (accounts.length != ids.length) revert IERC1155BaseInternal.ERC1155Base__ArrayLengthMismatch();

    uint256[] memory batchBalances = new uint256[](accounts.length);

    for (uint256 i; i < accounts.length; i++) {
      batchBalances[i] = balanceOf(accounts[i], ids[i]);
    }

    return batchBalances;
  }

  /**
   * @inheritdoc IERC1155
   */
  function isApprovedForAll(address account, address operator) public view returns (bool) {
    return OperatorApproval.get(world, approvalTableId, account, operator);
  }

  /**
   * @inheritdoc IERC1155
   */
  function setApprovalForAll(address operator, bool status) public {
    world.call(
      namespace,
      systemFile,
      abi.encodeWithSelector(
        ERC1155InternalSystem.setApprovalForAll.selector,
        msg.sender,
        operator,
        status
      )
    );
  }

  /**
   * @inheritdoc IERC1155
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) public virtual {
    _requireOwnerOrApproved(from);
    world.call(
      namespace,
      systemFile,
      abi.encodeWithSelector(
        ERC1155InternalSystem.safeTransfer.selector,
        msg.sender,
        from,
        to,
        id,
        amount,
        data
      )
    );
  }

  /**
    * @inheritdoc IERC1155
    */
  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) public virtual {
    _requireOwnerOrApproved(from);
    world.call(
      namespace,
      systemFile,
      abi.encodeWithSelector(
        ERC1155InternalSystem.safeTransferBatch.selector,
        msg.sender,
        from,
        to,
        ids,
        amounts,
        data
      )
    );
  }

  function _requireOwnerOrApproved(address from) internal view {
    if (from != msg.sender && !isApprovedForAll(from, msg.sender)) {
      revert IERC1155BaseInternal.ERC1155Base__NotOwnerOrApproved();
    }
  }
}