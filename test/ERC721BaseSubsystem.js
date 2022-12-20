const ethers = require('hardhat').ethers
const describeBehaviorOfERC721Base = require("@solidstate/spec").describeBehaviorOfERC721Base
const expect = require('chai').expect

describe('ERC721BaseSubsystem', function () {
  let instance

  beforeEach(async function () {
    const worldFactory = await ethers.getContractFactory('World')
    const worldInstance = await worldFactory.deploy()
    await worldInstance.deployed()
    await worldInstance.init()

    const factory = await ethers.getContractFactory('ERC721BaseSubsystemMock')
    instance = await factory.deploy(worldInstance.address, await worldInstance.components())
    await instance.deployed()
  });

  describeBehaviorOfERC721Base(
    () => instance,
    {
      mint(address, tokenId) {
        return instance.mint(address, tokenId)
      },
      burn(tokenId) {
        return instance.burn(tokenId)
      },
    },
    ['#ownerOf(uint256)']
  ),

  // this just changes the error from EnumerableMap__NonExistentKey to ERC721Base__InvalidOwner
  describe('#ownerOf(uint256)', function () {
    it('returns the owner of given token', async function () {
      const [holder] = await ethers.getSigners();

      const tokenId = ethers.constants.Two;
      await instance.mint(holder.address, tokenId);

      expect(await instance.callStatic.ownerOf(tokenId)).to.equal(
        holder.address,
      );
    });

    describe('reverts if', function () {
      it('token does not exist', async function () {
        await expect(
          instance.callStatic.ownerOf(ethers.constants.Two),
        ).to.be.revertedWithCustomError(
          instance,
          'ERC721Base__InvalidOwner',
        );
      });

      it('owner is zero address');
    });
  });
})