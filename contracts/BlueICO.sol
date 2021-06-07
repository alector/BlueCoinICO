//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "./BlueCoin.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title Initial Coin Offering (ICO) of BlueCoin (BCN)
 * @author Alector
 * @dev BlueCoin is a token that is going to be bought as a coin in the Initial Coin Offering  (BlueCoinICO.sol).
 * The code is also inspired by Hardhat-ICO by Jeremie, found here https://github.com/Dzheremilz/Hardhat-ICO
 * Users can buy coins from BlueCoinICO and then consume them to use other services like Calculator.sol.
 * Only part of the totalSupply of BlueCoin will be approved (allowances) to our ICO  contract address
 **/
contract BlueICO is Ownable {
    // library usage
    using Address for address payable;

    BlueCoin private _coin;
    address private _owner;
    uint256 public tokenPrice;
    uint256 public currentTime;
    uint256 public timeEnd;
    uint256 private _numTokensApproved;

    enum State {inactive, active}
    State public curStatus;

    event Deposit(address indexed sender, uint256 amount);
    event Withdraw(address indexed recipient, uint256 amount);

    /**
     * @dev the Initial Coin Offering of a Coin that is deployed in a certai address
     * @param coinAddress address of deployed ERC20 token BlueCoin
     * By default the owner of the coin becomes the owner of the ICO
     * Only part of the totalSupply of BlueCoin will be assigned to our ICO  contract address
     **/
    constructor(address coinAddress) {
        _coin = BlueCoin(coinAddress);
        _owner = _coin.getOwner();
        Ownable.transferOwnership(_owner);
        tokenPrice = 1e9; // 1 gwei expressed in wei
        curStatus = State.active;
        timeEnd = block.timestamp + 1209600; // two weeks in seconds
    }

    modifier onlyActive {
        require(block.timestamp < timeEnd, "BlueICO: This operation is reserved for active contracts.");
        _;
    }

    modifier onlyInactive {
        require(block.timestamp >= timeEnd, "BlueICO: This operation is reserved for inactive contracts.");
        _;
    }

    /**
     * @dev get the state of the contract (active or inactive)
     * after a given period of time the contract becomes inactive
     * @return state of contract (active or inactive)
     **/
    function getState() public view returns (State) {
        if (block.timestamp >= timeEnd) {
            return State.inactive; // State.inactive;
        } else {
            return State.active; // State.active;
        }
    }

    /**
     * @dev get balance of ether in currenct contract
     * @return balance of ether
     **/
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev get balance of ether of certain user
     * @return balance of ether
     **/
    function getMyTokenBalance() public view returns (uint256) {
        return _coin.balanceOf(msg.sender);
    }

    /**
     * @dev get total balance of tokens of deployed BlueCoin
     * @return balance of ether
     **/
    function getTotalSupply() public view returns (uint256) {
        return _coin.totalSupply();
    }

    /**
     * @dev the owner approves initial supply to the ICO
     * This is not necessary to be used, it cone be done directly in the test.
     * @param numTokensApproved the number of Tokens approved to this ICO, this number can be sold to various users
     **/
    function approveInitialSupply(uint256 numTokensApproved) public onlyOwner {
        _coin.approve(address(this), numTokensApproved);
    }

    /**
     * @dev direct transfer of ether to the contract
     * For example, use Metamask & send ether  directly to the address of tye deployed BlueICO contract, and the function receive() will be invoked.
     **/
    receive() external payable {
        buyTokens();
    }

    /**
     * @dev transfer of ether to the contract through a function
     **/
    function buyTokens() public payable {
        _buyTokens(msg.sender, msg.value);
    }

    /**
     * @dev internal function to buy tokens
     * @param sender the address of the msg.sender that buys tokens
     * @param amount the amount of Ether send to the contract that will be converted to tokens
     * IMPORTANT. The amount can only be 10**9 or multiplications of that number. The function assumes that the amount is already checked (in Javascript) to fit that requirement.
     * IMPORTANT. There is no need for additional require to check if ammount exists in the balance of the sender. ERC20 _transfer() is applied inside transferTo() and this already REQUIRES & CHECKS if amount exists.
     **/
    function _buyTokens(address sender, uint256 amount) private onlyActive {
        require(
            amount % 10**9 == 0,
            "BlueICO: Contract doesn't give back change. The received amount must be divisible by price."
        );
        uint256 numTokens = amount * 10**9;
        _coin.transferFrom(_owner, sender, numTokens);
        emit Deposit(sender, amount);
    }

    /**
     * @dev owner withdraws ether after contract expiration date
     **/
    function withdrawEther() public onlyOwner onlyInactive {
        uint256 depositBalance = address(this).balance;
        require(depositBalance > 0, "FlashCoinICO: can not withdraw 0 ether");

        payable(_owner).sendValue(depositBalance);
        emit Withdraw(_owner, depositBalance);
    }

    /**
     * @dev get owner of the contract
     **/

    function getOwner() public view returns (address) {
        return Ownable.owner();
    }
}
