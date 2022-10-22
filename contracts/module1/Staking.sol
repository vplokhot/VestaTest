// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import "hardhat/console.sol";

import "./MyToken.sol";
contract Staking{
    MyToken public stakingToken;
    mapping(address => uint256) private stakedBalanceOf;
    mapping(address => uint256) public lockedBalanceOf;
    uint256 public totalStaked;

    struct LockDeposit {
        uint256 amount;
        uint256 lockTime;
    }

    LockDeposit[] private lockDeposits;
    mapping(address => LockDeposit[]) public lockedDepositsOf;

    constructor(address _stakingToken) {        
        stakingToken = MyToken(_stakingToken);
    }

    function stake(uint _amount) external{
        require(_amount > 0, "amount = 0");
        require(stakingToken.balanceOf(msg.sender) >= _amount, "Not enough funds");
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        stakedBalanceOf[msg.sender] += _amount;
        totalStaked += _amount;
    }

    function withdraw(uint _amount) external {
        require(_amount > 0, "amount = 0");
        require(stakedBalanceOf[msg.sender] >= _amount);
        stakedBalanceOf[msg.sender] -= _amount;
        totalStaked -= _amount;
        stakingToken.transfer(msg.sender, _amount);
    }

    function lock(uint _amount) external{
        require(_amount > 0, "amount = 0");
        require(stakingToken.balanceOf(msg.sender) >= _amount, "Not enough funds");
        LockDeposit memory deposit = LockDeposit({
            amount: _amount,
            lockTime: block.timestamp
        });

        lockDeposits.push(deposit);
        lockedDepositsOf[msg.sender].push(deposit);
        lockedBalanceOf[msg.sender] += _amount;
    }

    function withdrawLock(uint _amount) external {
        require(_amount > 0, "amount = 0");
        require(lockedBalanceOf[msg.sender] >= _amount, "Not enough funds locked");

        LockDeposit[] memory deposits = lockedDepositsOf[msg.sender];
        uint256 withdrawalLimit = checkLockedDeposits(deposits);
        
        require(withdrawalLimit >= _amount, "Can't withdraw that much yet");
        lockedBalanceOf[msg.sender] -= _amount;
        stakingToken.transfer(msg.sender, _amount);

    }

    function checkLockedDeposits(LockDeposit[] memory deposits) internal view returns(uint256){
        uint256 maxLockedDepositWithdrawAmount;
        for(uint i=0; i<deposits.length; i++){
            LockDeposit memory deposit = deposits[i];
            uint lockedDepositLimit = getCurrentLimit(deposit);
            maxLockedDepositWithdrawAmount += lockedDepositLimit;
        }
        return maxLockedDepositWithdrawAmount;
    }

    function getCurrentLimit(LockDeposit memory deposit) internal view returns(uint256){
        uint amount = deposit.amount;
        uint lockTime = deposit.lockTime;
        uint unlockTime = lockTime + 365 days;

        if(block.timestamp >= unlockTime){
            return amount;
        }

        uint months = ((unlockTime - block.timestamp)) / 30 days;
        uint currentLimit = amount / months;
        return currentLimit;
    }

    function getLockedDepositsOf(address _address) external view returns(LockDeposit[] memory){
        return lockedDepositsOf[_address];
    }

    function getCurrentLimitOf(address _address) external view returns(uint256){
        LockDeposit[] memory deposits = lockedDepositsOf[_address];
        uint256 withdrawalLimit = checkLockedDeposits(deposits);
        return withdrawalLimit;
    }

}