const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");
const { ethers } = require("hardhat");
const {
  time,
  loadFixture,
  mine,
  helpers,
} = require("@nomicfoundation/hardhat-network-helpers");
const {
  latest,
} = require("@nomicfoundation/hardhat-network-helpers/dist/src/helpers/time");
describe("MyToken", function () {
  let myToken;
  let stakingContract;

  beforeEach(async function () {
    console.log("deploying MyToken ...");
    const MyToken = await ethers.getContractFactory("MyToken");
    myToken = await MyToken.deploy();
    await myToken.deployed();

    console.log("deploying Staking ...");
    const Staking = await ethers.getContractFactory("Staking");
    stakingContract = await Staking.deploy(myToken.address);
    await stakingContract.deployed();
  });

  it("Deployment should assign the total supply of tokens to the owner", async function () {
    const [owner] = await ethers.getSigners();
    const ownerBalance = await myToken.balanceOf(owner.address);
    console.log(ownerBalance.toString(), " owner initial balance");
    expect(await myToken.totalSupply()).to.equal(ownerBalance);
  });

  it("Owner should send tokens to address", async function () {
    const [owner, addr1] = await ethers.getSigners();

    await myToken.transfer(addr1.address, ethers.utils.parseEther("2000000"));

    expect(await myToken.balanceOf(addr1.address)).to.equal(
      ethers.utils.parseEther("2000000")
    );
  });
  it("Should deploy the staking contract and stake tokens", async function () {
    const [owner, addr1] = await ethers.getSigners();

    await myToken.transfer(addr1.address, ethers.utils.parseEther("2000000"));
    const originalBalance = await myToken.balanceOf(addr1.address);
    // approve full balance
    await myToken
      .connect(addr1)
      .approve(stakingContract.address, originalBalance);

    //stake full balance
    await stakingContract.connect(addr1).stake(originalBalance);

    expect(await stakingContract.totalStaked()).to.equal(originalBalance);
  });
  it("Should lock funds", async function () {
    // let stakingContract;
    const [owner, addr1] = await ethers.getSigners();

    await myToken.transfer(addr1.address, ethers.utils.parseEther("2000000"));
    const originalBalance = await myToken.balanceOf(addr1.address);
    // approve full balance
    await myToken
      .connect(addr1)
      .approve(stakingContract.address, originalBalance);

    //stake full balance
    await stakingContract.connect(addr1).stake(originalBalance);

    expect(await stakingContract.totalStaked()).to.equal(originalBalance);
  });
  it("Should unlock funds", async function () {
    const [owner, addr1] = await ethers.getSigners();

    await myToken.transfer(addr1.address, ethers.utils.parseEther("8000000"));
    const originalBalance = await myToken.balanceOf(addr1.address);

    // approve full balance
    console.log("Approving full balance - ", originalBalance);
    await myToken
      .connect(addr1)
      .approve(stakingContract.address, originalBalance);

    await stakingContract.connect(addr1).lock(originalBalance);
    console.log("Locking full balance - ", originalBalance);
    // const _30days = 30 * 24 * 60 * 60;
    const _year = 365 * 24 * 60 * 60;
    console.log("Fast forward 1 year ... ");
    await time.increase(_year);

    const withdrawalLimitAfterTimeIncrease =
      await stakingContract.getCurrentLimitOf(addr1.address);
    console.log(
      withdrawalLimitAfterTimeIncrease,
      "should be equal to ",
      originalBalance
    );
    expect(withdrawalLimitAfterTimeIncrease).to.equal(originalBalance);
  });
});
