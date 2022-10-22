// SPDX-License-Identifier: MIT
// An example of a consumer contract that relies on a subscription for funding.
pragma solidity ^0.8.7;
import "hardhat/console.sol";

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "../module1/MyToken.sol";
contract Card is VRFConsumerBaseV2 {
    MyToken public myToken;
    VRFCoordinatorV2Interface immutable COORDINATOR;
    uint64 immutable s_subscriptionId;
    bytes32 immutable s_keyHash;
    uint32 constant CALLBACK_GAS_LIMIT = 1000000;
    uint16 constant REQUEST_CONFIRMATIONS = 3;
    uint32 constant NUM_WORDS = 4;
    uint256[] public s_randomWords;
    uint256 public s_requestId;
    address s_owner;

    mapping(uint256 => address) public s_requestIdToAddress;
    mapping(address => uint256) public addressTokenBalanceOf;
    mapping(address => CardItem) public cards;

    uint256[] colours = [1,2,3];
    uint256[] symbols = [0,2,4,7];
    uint256[] tiers = [1,2,3,4,5];

    struct CardItem{
        uint colour;
        uint symbol;
        uint tier;
        uint evolution;
        uint power;
    }

    event ReturnedRandomness(uint256[] randomWords);
    constructor(
        address _tokenAddress,
        uint64 subscriptionId,
        address vrfCoordinator,
        bytes32 keyHash
    ) VRFConsumerBaseV2(vrfCoordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
        s_keyHash = keyHash;
        s_owner = msg.sender;
        s_subscriptionId = subscriptionId;
        myToken = MyToken(_tokenAddress);
    }

    function createCard(uint256 _amount) external{
        require(_amount > 0, "Amount must be greater than 0");
        require(myToken.balanceOf(msg.sender) > _amount, "Insufficient funds");
        require(addressTokenBalanceOf[msg.sender] == 0, "One card limit");
        myToken.transferFrom(msg.sender, address(this), _amount);
        addressTokenBalanceOf[msg.sender] += _amount;
        requestRandomWords();
    }

    function requestRandomWords() internal{
        uint256 requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            REQUEST_CONFIRMATIONS,
            CALLBACK_GAS_LIMIT,
            NUM_WORDS
        );

        s_requestIdToAddress[requestId] = msg.sender;
        s_requestId = requestId;
        
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        s_randomWords = randomWords;
        address user = s_requestIdToAddress[requestId];
        uint256 initialCardPower = addressTokenBalanceOf[user];

        uint256 colour = colours[randomWords[0] % 3];
        uint256 symbol = symbols[randomWords[1] % 3];
        uint256 tier = tiers[randomWords[2] % 3];
        uint256 evolution = randomWords[3] % 100;
        uint256 power = evolution * (initialCardPower * (tier + colour + symbol));

        CardItem memory card = CardItem(colour, symbol, tier, evolution, power);
        cards[user] = card;
        emit ReturnedRandomness(randomWords);
    }

    function getCardByAddress(address _userAddress) external view returns(CardItem memory){
        return cards[_userAddress];
    }

    modifier onlyOwner() {
        require(msg.sender == s_owner);
        _;
    }
}