// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { AddressUtils } from "@solidstate/contracts/utils/AddressUtils.sol";
import { IERC1155Receiver } from '@solidstate/contracts/interfaces/IERC1155Receiver.sol';
import { IERC1155BaseInternal } from "@solidstate/contracts/token/ERC1155/base/IERC1155BaseInternal.sol";

import { WorldContext } from "@latticexyz/world/src/WorldContext.sol";
import { System } from "@latticexyz/world/src/System.sol";

import { Balance } from "../../codegen/tables/Balance.sol";
import { OperatorApproval } from "../../codegen/tables/OperatorApproval.sol";

/**
 * @title MUD-based ERC1155 internal system
 * @dev WARNING: do NOT deploy it with public access! Grant proxy access.
 *
 * Derived from https://github.com/solidstate-network/solidstate-solidity/ (MIT)
 * and https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT)
 */
contract ERC1155InternalSystem is
  System,
  IERC1155BaseInternal
{
  bytes32 immutable balanceTableId;
  bytes32 immutable approvalTableId;

  constructor(
    bytes32 _balanceTableId,
    bytes32 _approvalTableId
  ) {
    balanceTableId = _balanceTableId;
    approvalTableId = _approvalTableId;
  }

  function mint(
    address account,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) public virtual {
    if (account == address(0)) revert ERC1155Base__MintToZeroAddress();

    _beforeTokenTransfer(
      _msgSender(),
      address(0),
      account,
      _asSingletonArray(id),
      _asSingletonArray(amount),
      data
    );

    Balance.set(
      balanceTableId,
      account,
      id,
      Balance.get(balanceTableId, account, id) + amount
    );

    emit TransferSingle(_msgSender(), address(0), account, id, amount);
  }

  function safeMint(
    address account,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) public virtual {
    mint(account, id, amount, data);

    _doSafeTransferAcceptanceCheck(
      _msgSender(),
      address(0),
      account,
      id,
      amount,
      data
    );
  }

  function mintBatch(
    address account,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) public virtual {
    if (account == address(0)) revert ERC1155Base__MintToZeroAddress();
    if (ids.length != amounts.length) revert ERC1155Base__ArrayLengthMismatch();

    _beforeTokenTransfer(
      _msgSender(),
      address(0),
      account,
      ids,
      amounts,
      data
    );

    for (uint256 i; i < ids.length; i++) {
      Balance.set(
        balanceTableId,
        account,
        ids[i],
        Balance.get(balanceTableId, account, ids[i]) + amounts[i]
      );
    }

    emit TransferBatch(_msgSender(), address(0), account, ids, amounts);
  }

  function safeMintBatch(
    address account,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) public virtual {
    mintBatch(account, ids, amounts, data);

    _doSafeBatchTransferAcceptanceCheck(
      _msgSender(),
      address(0),
      account,
      ids,
      amounts,
      data
    );
  }

  function burn(
    address account,
    uint256 id,
    uint256 amount
  ) public virtual {
    if (account == address(0)) revert ERC1155Base__BurnFromZeroAddress();

    _beforeTokenTransfer(
      _msgSender(),
      account,
      address(0),
      _asSingletonArray(id),
      _asSingletonArray(amount),
      ''
    );

    uint256 fromBalance = Balance.get(balanceTableId, account, id);
    if (amount > fromBalance) revert ERC1155Base__BurnExceedsBalance();
    unchecked {
      Balance.set(
        balanceTableId,
        account,
        id,
        fromBalance - amount
      );
    }

    emit TransferSingle(_msgSender(), account, address(0), id, amount);
  }

  function burnBatch(
    address account,
    uint256[] memory ids,
    uint256[] memory amounts
  ) public virtual {
    if (account == address(0)) revert ERC1155Base__BurnFromZeroAddress();
    if (ids.length != amounts.length) revert ERC1155Base__ArrayLengthMismatch();

    _beforeTokenTransfer(_msgSender(), account, address(0), ids, amounts, '');

    for (uint256 i; i < ids.length; i++) {
      uint256 id = ids[i];
      uint256 amount = amounts[i];

      uint256 fromBalance = Balance.get(balanceTableId, account, id);
      if (amount > fromBalance) revert ERC1155Base__BurnExceedsBalance();
      unchecked {
        Balance.set(
          balanceTableId,
          account,
          id,
          fromBalance - amount
        );
      }
    }

    emit TransferBatch(_msgSender(), account, address(0), ids, amounts);
  }

  function transfer(
    address operator,
    address sender,
    address recipient,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) public virtual {
    if (recipient == address(0)) revert ERC1155Base__TransferToZeroAddress();

    _beforeTokenTransfer(
      operator,
      sender,
      recipient,
      _asSingletonArray(id),
      _asSingletonArray(amount),
      data
    );

    uint256 fromBalance = Balance.get(balanceTableId, sender, id);
    if (amount > fromBalance) revert ERC1155Base__TransferExceedsBalance();
    unchecked {
      Balance.set(
        balanceTableId,
        sender,
        id,
        fromBalance - amount
      );
    }
    Balance.set(
      balanceTableId,
      recipient,
      id,
      Balance.get(balanceTableId, recipient, id) + amount
    );

    emit TransferSingle(operator, sender, recipient, id, amount);
  }

  function safeTransfer(
    address operator,
    address sender,
    address recipient,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) public virtual {
    transfer(operator, sender, recipient, id, amount, data);

    _doSafeTransferAcceptanceCheck(
      operator,
      sender,
      recipient,
      id,
      amount,
      data
    );
  }

  function transferBatch(
    address operator,
    address sender,
    address recipient,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) public virtual {
    if (recipient == address(0)) revert ERC1155Base__TransferToZeroAddress();
    if (ids.length != amounts.length) revert ERC1155Base__ArrayLengthMismatch();

    _beforeTokenTransfer(operator, sender, recipient, ids, amounts, data);

    for (uint256 i; i < ids.length; i++) {
      uint256 id = ids[i];
      uint256 amount = amounts[i];

      uint256 fromBalance = Balance.get(balanceTableId, sender, id);
      if (amount > fromBalance) revert ERC1155Base__TransferExceedsBalance();
      unchecked {
        Balance.set(
          balanceTableId,
          sender,
          id,
          fromBalance - amount
        );
      }
      Balance.set(
        balanceTableId,
        recipient,
        id,
        Balance.get(balanceTableId, recipient, id) + amount
      );
    }

    emit TransferBatch(operator, sender, recipient, ids, amounts);
  }

  function safeTransferBatch(
    address operator,
    address sender,
    address recipient,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) public virtual {
    transferBatch(operator, sender, recipient, ids, amounts, data);

    _doSafeBatchTransferAcceptanceCheck(
      operator,
      sender,
      recipient,
      ids,
      amounts,
      data
    );
  }

  function setApprovalForAll(
    address account,
    address operator,
    bool status
  ) public virtual {
    if (account == operator) revert ERC1155Base__SelfApproval();
    OperatorApproval.set(approvalTableId, account, operator, status);
    emit ApprovalForAll(account, operator, status);
  }

  function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual {}

  function _doSafeTransferAcceptanceCheck(
    address operator,
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) private {
    if (AddressUtils.isContract(to)) {
      try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
        if (response != IERC1155Receiver.onERC1155Received.selector) {
          revert ERC1155Base__ERC1155ReceiverRejected();
        }
      } catch Error(string memory reason) {
        revert(reason);
      } catch {
        revert ERC1155Base__ERC1155ReceiverNotImplemented();
      }
    }
  }

  function _doSafeBatchTransferAcceptanceCheck(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) private {
    if (AddressUtils.isContract(to)) {
      try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (bytes4 response) {
        if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
          revert ERC1155Base__ERC1155ReceiverRejected();
        }
      } catch Error(string memory reason) {
        revert(reason);
      } catch {
        revert ERC1155Base__ERC1155ReceiverNotImplemented();
      }
    }
  }

  function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
    uint256[] memory array = new uint256[](1);
    array[0] = element;
    return array;
  }
}