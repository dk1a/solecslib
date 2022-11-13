const ethers = require('hardhat').ethers
const describeBehaviorOfERC1155Base = require("@solidstate/spec").describeBehaviorOfERC1155Base

describe('ERC1155BaseSystem', function () {
  let instance

  beforeEach(async function () {
    const worldFactory = await ethers.getContractFactory('World')
    const worldInstance = await worldFactory.deploy()
    await worldInstance.deployed()
    await worldInstance.init()

    const factory = await ethers.getContractFactory('ERC1155BaseSystemMock')
    instance = await factory.deploy(worldInstance.address, await worldInstance.components())
    await instance.deployed()
  });

  describeBehaviorOfERC1155Base(
    () => instance,
    {
      mint(address, id, amount) {
        return instance.mint(address, id, amount)
      },
      burn(address, id, amount) {
        return instance.burn(address, id, amount)
      },
    }
  )
})