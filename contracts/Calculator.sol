// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./BlueCoin.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Calculator is Ownable {
    uint256 private _calcPrice;
    BlueCoin private _coin;
    address private _owner;

    event Calculation(string calcType, address indexed user, int256 a, int256 b, int256 result);

    constructor(address coinAddress) {
        _coin = BlueCoin(coinAddress);
        _owner = _coin.getOwner();
        Ownable.transferOwnership(_owner);
        _calcPrice = 1 ether;
    }

    function setPrice(uint256 price_) public onlyOwner {
        _calcPrice = price_;
    }

    function getPrice() public view returns (uint256) {
        return _calcPrice;
    }

    function getOwner() public view returns (address) {
        return _owner;
    }

    modifier haveEnoughTokens() {
        require(
            _coin.balanceOf(msg.sender) >= _calcPrice,
            "Calculator: you need more tokens to perform this operation "
        );
        _;
    }

    function _pay(address sender) internal {
        // NO NEED TO CHECK FOR REQUIRED ALLOWANCE, THE ERC20 ALREADY DOES THAT
        _coin.transferFrom(sender, _owner, _calcPrice);
    }

    function add(int256 a, int256 b) public haveEnoughTokens returns (bool) {
        _pay(msg.sender);
        emit Calculation("add", msg.sender, a, b, a + b);
        return true;
    }

    function sub(int256 a, int256 b) public haveEnoughTokens returns (bool) {
        _pay(msg.sender);
        emit Calculation("sub", msg.sender, a, b, a - b);
        return true;
    }
}
