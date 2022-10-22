const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect, assert } = require("chai");
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

describe("Card VRF Tests", async function () {
  async function deployRandomNumberConsumerFixture() {
    const [deployer, addr1] = await ethers.getSigners();

    let myToken;
    const MyToken = await ethers.getContractFactory("MyToken");
    console.log("deploying MyToken ...");
    myToken = await MyToken.deploy();
    await myToken.deployed();

    await myToken.transfer(addr1.address, ethers.utils.parseEther("2000000"));
    const addr1Balance = await myToken.balanceOf(addr1.address);

    const BASE_FEE = "100000000000000000";
    const GAS_PRICE_LINK = "1000000000";

    const VRFCoordinatorV2MockFactory = await ethers.getContractFactory(
      "VRFCoordinatorV2Mock"
    );

    const VRFCoordinatorV2Mock = await VRFCoordinatorV2MockFactory.deploy(
      BASE_FEE,
      GAS_PRICE_LINK
    );

    const fundAmount = "1000000000000000000";
    const transaction = await VRFCoordinatorV2Mock.createSubscription();
    const transactionReceipt = await transaction.wait(1);
    const subscriptionId = ethers.BigNumber.from(
      transactionReceipt.events[0].topics[1]
    );
    await VRFCoordinatorV2Mock.fundSubscription(subscriptionId, fundAmount);

    const vrfCoordinatorAddress = VRFCoordinatorV2Mock.address;
    const keyHash =
      "0xd89b2bf150e3b9e13446986e571fb9cab24b13cea0a43ea20a6049a85cc807cc";

    // CARD

    const cardFactory = await ethers.getContractFactory("Card");
    const card = await cardFactory
      .connect(deployer)
      .deploy(myToken.address, subscriptionId, vrfCoordinatorAddress, keyHash);

    await myToken.connect(addr1).approve(card.address, addr1Balance);
    await VRFCoordinatorV2Mock.addConsumer(subscriptionId, card.address);
    return { card, VRFCoordinatorV2Mock };
  }
  it("Card VRF Test -- Should successfully request a random number and get a result", async function () {
    const { card, VRFCoordinatorV2Mock } = await loadFixture(
      deployRandomNumberConsumerFixture
    );
    const [deployer, addr1] = await ethers.getSigners();

    const cardResponse = await card.connect(addr1).createCard(2000000);
    const requestId = await card.s_requestId();
    await VRFCoordinatorV2Mock.fulfillRandomWords(requestId, card.address);
    const firstRandomNumber = await card.s_randomWords(0);
    const secondRandomNumber = await card.s_randomWords(1);

    console.log(firstRandomNumber, "firstRandomNumber card");
    console.log(secondRandomNumber, "secondRandomNumber card");

    const cardItem = await card.getCardByAddress(addr1.address);
    console.log(cardItem, "addr1.address card");

    assert(
      firstRandomNumber.gt(ethers.constants.Zero),
      "First random number is greather than zero"
    );

    assert(
      secondRandomNumber.gt(ethers.constants.Zero),
      "Second random number is greather than zero"
    );
  });
});
