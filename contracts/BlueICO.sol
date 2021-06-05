//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "./BlueCoin.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract BlueICO is Ownable {
    // library usage
    using Address for address payable;

    BlueCoin private _coin;
    address private _owner;
    uint256 public tokenPrice;
    uint256 public currentTime;
    uint256 public timeEnd;
    uint256 private _numTokensApproved;
    address public ICOAddress;

    enum State {inactive, active}
    State public curStatus;

    event Deposit(address indexed sender, uint256 amount);
    event Withdraw(address indexed recipient, uint256 amount);

    constructor(address tokenAddress) {
        _coin = BlueCoin(tokenAddress);
        _owner = _coin.getOwner();
        Ownable.transferOwnership(_owner);
        ICOAddress = address(this);

        // Only part of the totalSupply of BlueCoin will be assigned to our ICO  contract address
        // _numTokensApproved = numTokensApproved_;

        tokenPrice = 1e9; // 1 gwei expressed in wei
        curStatus = State.active;
        timeEnd = block.timestamp + 1209600; // two weeks in seconds
    }

    modifier onlyActive {
        require(block.timestamp < timeEnd, "This operation is reserved for active contracts.");
        _;
    }

    modifier onlyInactive {
        require(block.timestamp >= timeEnd, "This operation is reserved for inactive contracts.");
        _;
    }

    function getState() public view returns (State) {
        if (block.timestamp >= timeEnd) {
            return State.inactive; // State.inactive;
        } else {
            return State.active; // State.active;
        }
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getMyTokenBalance() public view returns (uint256) {
        return _coin.balanceOf(msg.sender);
    }

    function getTotalSupply() public view returns (uint256) {
        return _coin.totalSupply();
    }

    // when someone sends DIRECTLY ether to this account.
    // example: use Metamask & send ether  directly to the contract address
    receive() external payable {
        buyTokens();
    }

    // initial designation by the owner
    // this could be done directly in the test
    // with the approve() from the Coin contract
    function approveInitialSupply(uint256 numTokensApproved) public onlyOwner {
        _coin.approve(ICOAddress, numTokensApproved);
    }

    function buyTokens() public payable {
        _buyTokens(msg.sender, msg.value);
    }

    // Send ether through a function.
    function _buyTokens(address sender, uint256 amount) private onlyActive {
        // 1 token has 18 zeros in decimals
        // when you buy 1 token, you buy 18 zeros
        // when the price of 1 token is 1 gwei
        // then if you give 1 gwei you get 18 zeros in your balance
        // the msg.sender counts in wei, so if you give 10*9 wei, you have to make a calculation that gives you 18 zeros in your account. 10*9 times 10*9 gives 18 zeros (1 full token or 18 zeros of tokens)

        uint256 numTokens = amount * 10**9;

        // NOTE: ERC20 _transfer() is applied inside transferTo() and it already REQUIRES & CHECKS if amount exists
        // _msgSender of buyTokens is the msg.sender
        // _msgSender of transferFrom will be the address of the conttact
        _coin.transferFrom(_owner, sender, numTokens);

        emit Deposit(sender, amount);
    }

    // function convertToTokens(uint256 inputWei) private view returns (uint256) {
    //     return inputWei / tokenPrice;
    // }

    function withdrawEther() public onlyOwner onlyInactive {
        uint256 depositBalance = address(this).balance;
        require(depositBalance > 0, "FlashCoinICO: can not withdraw 0 ether");

        payable(_owner).sendValue(depositBalance);
        emit Withdraw(_owner, depositBalance);
    }

    function getOwner() public view returns (address) {
        return Ownable.owner();
    }
}
