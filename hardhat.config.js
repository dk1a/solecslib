require('@nomiclabs/hardhat-ethers')
require('hardhat-preprocessor')
require('@nomicfoundation/hardhat-chai-matchers')

const readFileSync = require('fs').readFileSync

function getRemappings() {
  return readFileSync("remappings.txt", "utf8")
    .split("\n")
    // remove empty lines
    .filter(Boolean)
    .map((line) => line.trim().split("="))
    // remove node_modules prefix
    .map(([from, to]) => [from, to.replace(/^.*node_modules\//, '')])
}

module.exports = {
  solidity: {
    version: '0.8.17',
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  preprocess: {
    eachLine: (hre) => ({
      transform: (line) => {
        if (line.match(/^\s*import .*"\s*;/i)) {
          for (const [from, to] of getRemappings()) {
            const regex = new RegExp(`^(\s*import .*")(${from})(.*"\s*;)`);
            if (line.match(regex)) {
              line = line.replace(regex, `$1${to}$3`);
              break;
            }
          }
        }
        return line;
      },
    }),
  },
}