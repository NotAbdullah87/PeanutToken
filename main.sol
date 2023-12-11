// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract PeanutToken is ERC20, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _lockedBalances;
    mapping(address => uint256) private _unlockTimes;
    mapping(address => uint256) private _stakingBalances;

    event TokensLocked(address indexed beneficiary, uint256 amount, uint256 unlockTime);
    event TokensUnlocked(address indexed beneficiary, uint256 amount);

    constructor() ERC20("Peanut", "PNUT") {
        _mint(msg.sender, 1000000 * 10**18); // Mint 1,000,000 PNUT tokens initially and assign them to the contract deployer
    }

    // Function to transfer tokens with a time lock
    function transferWithLock(address to, uint256 amount, uint256 unlockTime) public {
        require(to != address(0), "ERC20: transfer to the zero address");
        require(unlockTime > block.timestamp, "Unlock time must be in the future");

        _transfer(msg.sender, to, amount);
        _lockedBalances[to] = _lockedBalances[to].add(amount);
        _unlockTimes[to] = unlockTime;

        emit TokensLocked(to, amount, unlockTime);
    }

    // Function to unlock time-locked tokens
    function unlockTokens() public {
        uint256 lockedAmount = _lockedBalances[msg.sender];
        uint256 unlockTime = _unlockTimes[msg.sender];

        require(lockedAmount > 0, "No locked tokens");
        require(block.timestamp >= unlockTime, "Tokens are still locked");

        _lockedBalances[msg.sender] = 0;
        _unlockTimes[msg.sender] = 0;

        _transfer(address(this), msg.sender, lockedAmount);

        emit TokensUnlocked(msg.sender, lockedAmount);
    }

    // Function to stake tokens
    function stakeTokens(uint256 amount) public {
        require(amount > 0, "Amount must be greater than 0");
        require(balanceOf(msg.sender) >= amount, "Not enough balance to stake");

        _transfer(msg.sender, address(this), amount);
        _stakingBalances[msg.sender] = _stakingBalances[msg.sender].add(amount);
    }

    // Function to unstake tokens
    function unstakeTokens(uint256 amount) public {
        require(amount > 0, "Amount must be greater than 0");
        require(_stakingBalances[msg.sender] >= amount, "Not enough staked balance");

        _stakingBalances[msg.sender] = _stakingBalances[msg.sender].sub(amount);
        _transfer(address(this), msg.sender, amount);
    }

    // Function to get the time remaining for the unlock of locked tokens
    function getTimeRemaining(address beneficiary) public view returns (uint256) {
        if (_unlockTimes[beneficiary] > block.timestamp) {
            return _unlockTimes[beneficiary] - block.timestamp;
        } else {
            return 0;
        }
    }

    // Function to get the staked balance of an address
    function getStakedBalance(address account) public view returns (uint256) {
        return _stakingBalances[account];
    }

    // Override balanceOf to include locked and staked balances
    function balanceOf(address account) public view override returns (uint256) {
        return super.balanceOf(account) + _stakingBalances[account] + _lockedBalances[account];
    }
}
