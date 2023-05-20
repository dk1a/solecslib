// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/* Autogenerated file. Do not edit manually. */

interface IERC1155InternalSystem {
  function mint(address account, uint256 id, uint256 amount, bytes memory data) external;

  function safeMint(address account, uint256 id, uint256 amount, bytes memory data) external;

  function mintBatch(address account, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external;

  function safeMintBatch(address account, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external;

  function burn(address account, uint256 id, uint256 amount) external;

  function burnBatch(address account, uint256[] memory ids, uint256[] memory amounts) external;

  function transfer(
    address operator,
    address sender,
    address recipient,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) external;

  function safeTransfer(
    address operator,
    address sender,
    address recipient,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) external;

  function transferBatch(
    address operator,
    address sender,
    address recipient,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) external;

  function safeTransferBatch(
    address operator,
    address sender,
    address recipient,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) external;

  function setApprovalForAll(address account, address operator, bool status) external;
}
