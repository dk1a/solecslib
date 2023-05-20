import { mudConfig, resolveTableId } from "@latticexyz/world/register";

export default mudConfig({
  tables: {
    // common
    OperatorApproval: {
      keySchema: {
        account: "address",
        operator: "address",
      },
      schema: "bool",
      storeArgument: true,
      tableIdArgument: true,
    },
    // ERC-721
    Ownership: {
      keySchema: {
        tokenId: "uint256"
      },
      schema: "address",
      storeArgument: true,
      tableIdArgument: true,
    },
    TokenApproval: {
      keySchema: {
        tokenId: "uint256"
      },
      schema: "address",
      storeArgument: true,
      tableIdArgument: true,
    },
    // ERC-1155
    Balance: {
      keySchema: {
        account: "address",
        tokenId: "uint256"
      },
      schema: "uint256",
      storeArgument: true,
      tableIdArgument: true,
    },
  },
  modules: [
    {
      name: "KeysWithValueModule",
      root: true,
      args: [resolveTableId("Ownership")],
    }
  ]
})