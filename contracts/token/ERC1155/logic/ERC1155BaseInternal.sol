// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { Context } from "@openzeppelin/contracts/utils/Context.sol";
import { IERC1155Receiver } from '@solidstate/contracts/interfaces/IERC1155Receiver.sol';
import { IERC1155BaseInternal } from "@solidstate/contracts/token/ERC1155/base/IERC1155BaseInternal.sol";

import { ERC1155BaseVData } from "./ERC1155BaseVData.sol";

/**
 * @title Storage-agnostic ERC1155 balance internals
 * @dev Derived from https://github.com/solidstate-network/solidstate-solidity/ (MIT)
 * and https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT)
 */
abstract contract ERC1155BaseInternal is
  Context,
  IERC1155BaseInternal,
  ERC1155BaseVData
{
  function _balanceOf(address account, uint256 id) internal view virtual returns (uint256) {
    if (account == address(0)) revert ERC1155Base__BalanceQueryZeroAddress();
    return _get_balance(account, id);
  }

  function _mint(
    address account,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) internal virtual {
    if (account == address(0)) revert ERC1155Base__MintToZeroAddress();

    _beforeTokenTransfer(
      _msgSender(),
      address(0),
      account,
      _asSingletonArray(id),
      _asSingletonArray(amount),
      data
    );

    _set_balance(
      account,
      id,
      _get_balance(account, id) + amount
    );

    emit TransferSingle(_msgSender(), address(0), account, id, amount);
  }

  function _safeMint(
    address account,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) internal virtual {
    _mint(account, id, amount, data);

    _doSafeTransferAcceptanceCheck(
      _msgSender(),
      address(0),
      account,
      id,
      amount,
      data
    );
  }

  function _mintBatch(
    address account,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual {
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
      _set_balance(
        account,
        ids[i],
        _get_balance(account, ids[i]) + amounts[i]
      );
    }

    emit TransferBatch(_msgSender(), address(0), account, ids, amounts);
  }

  function _safeMintBatch(
    address account,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual {
    _mintBatch(account, ids, amounts, data);

    _doSafeBatchTransferAcceptanceCheck(
      _msgSender(),
      address(0),
      account,
      ids,
      amounts,
      data
    );
  }

  function _burn(
    address account,
    uint256 id,
    uint256 amount
  ) internal virtual {
    if (account == address(0)) revert ERC1155Base__BurnFromZeroAddress();

    _beforeTokenTransfer(
      _msgSender(),
      account,
      address(0),
      _asSingletonArray(id),
      _asSingletonArray(amount),
      ''
    );

    uint256 fromBalance = _get_balance(account, id);
    if (amount > fromBalance) revert ERC1155Base__BurnExceedsBalance();
    unchecked {
      _set_balance(
        account,
        id,
        fromBalance - amount
      );
    }

    emit TransferSingle(_msgSender(), account, address(0), id, amount);
  }

  function _burnBatch(
    address account,
    uint256[] memory ids,
    uint256[] memory amounts
  ) internal virtual {
    if (account == address(0)) revert ERC1155Base__BurnFromZeroAddress();
    if (ids.length != amounts.length) revert ERC1155Base__ArrayLengthMismatch();

    _beforeTokenTransfer(_msgSender(), account, address(0), ids, amounts, '');

    for (uint256 i; i < ids.length; i++) {
      uint256 id = ids[i];
      uint256 amount = amounts[i];

      uint256 fromBalance = _get_balance(account, id);
      if (amount > fromBalance) revert ERC1155Base__BurnExceedsBalance();
      unchecked {
        _set_balance(
          account,
          id,
          fromBalance - amount
        );
      }
    }

    emit TransferBatch(_msgSender(), account, address(0), ids, amounts);
  }

  function _transfer(
    address operator,
    address sender,
    address recipient,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) internal virtual {
    if (recipient == address(0)) revert ERC1155Base__TransferToZeroAddress();

    _beforeTokenTransfer(
      operator,
      sender,
      recipient,
      _asSingletonArray(id),
      _asSingletonArray(amount),
      data
    );

    uint256 fromBalance = _get_balance(sender, id);
    if (amount > fromBalance) revert ERC1155Base__TransferExceedsBalance();
    unchecked {
      _set_balance(
        sender,
        id,
        fromBalance - amount
      );
    }
    _set_balance(
      recipient,
      id,
      _get_balance(recipient, id) + amount
    );

    emit TransferSingle(operator, sender, recipient, id, amount);
  }

  function _safeTransfer(
    address operator,
    address sender,
    address recipient,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) internal virtual {
    _transfer(operator, sender, recipient, id, amount, data);

    _doSafeTransferAcceptanceCheck(
      operator,
      sender,
      recipient,
      id,
      amount,
      data
    );
  }

  function _transferBatch(
    address operator,
    address sender,
    address recipient,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual {
    if (recipient == address(0)) revert ERC1155Base__TransferToZeroAddress();
    if (ids.length != amounts.length) revert ERC1155Base__ArrayLengthMismatch();

    _beforeTokenTransfer(operator, sender, recipient, ids, amounts, data);

    for (uint256 i; i < ids.length; i++) {
      uint256 id = ids[i];
      uint256 amount = amounts[i];

      uint256 fromBalance = _get_balance(sender, id);
      if (amount > fromBalance) revert ERC1155Base__TransferExceedsBalance();
      unchecked {
        _set_balance(
          sender,
          id,
          fromBalance - amount
        );
      }
      _set_balance(
        recipient,
        id,
        _get_balance(recipient, id) + amount
      );
    }

    emit TransferBatch(operator, sender, recipient, ids, amounts);
  }

  function _safeTransferBatch(
    address operator,
    address sender,
    address recipient,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) internal virtual {
    _transferBatch(operator, sender, recipient, ids, amounts, data);

    _doSafeBatchTransferAcceptanceCheck(
      operator,
      sender,
      recipient,
      ids,
      amounts,
      data
    );
  }

  function _setApprovalForAll(
    address account,
    address operator,
    bool status
  ) internal virtual {
    if (account == operator) revert ERC1155Base__SelfApproval();
    _set_operatorApproval(account, operator, status);
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
    if (Address.isContract(to)) {
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
    if (Address.isContract(to)) {
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