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
            "Calculator: you need to buy more tokens to perform this operation"
        );
        _;
    }

    function _pay(address sender) internal {
        // NO NEED TO CHECK FOR REQUIRED ALLOWANCE, THE ERC20 ALREADY DOES THAT
        _coin.transferFrom(sender, _owner, _calcPrice);
    }

    function add(int256 a, int256 b) public haveEnoughTokens returns (bool) {
        _pay(msg.sender);
        emit Calculation("add", msg.sender, a, b, _add(a, b));
        return true;
    }

    function sub(int256 a, int256 b) public haveEnoughTokens returns (bool) {
        _pay(msg.sender);
        emit Calculation("sub", msg.sender, a, b, _sub(a, b));
        return true;
    }

    function mul(int256 a, int256 b) public haveEnoughTokens returns (bool) {
        _pay(msg.sender);
        emit Calculation("mul", msg.sender, a, b, _mul(a, b));
        return true;
    }

    function div(int256 a, int256 b) public haveEnoughTokens returns (bool) {
        _pay(msg.sender);
        emit Calculation("div", msg.sender, a, b, _div(a, b));
        return true;
    }

    function mod(int256 a, int256 b) public haveEnoughTokens returns (bool) {
        _pay(msg.sender);
        emit Calculation("mod", msg.sender, a, b, _mod(a, b));
        return true;
    }

    function _add(int256 a, int256 b) internal pure returns (int256) {
        return a + b;
    }

    function _sub(int256 a, int256 b) internal pure returns (int256) {
        return a - b;
    }

    function _mul(int256 a, int256 b) internal pure returns (int256) {
        return a * b;
    }

    function _mod(int256 a, int256 b) internal pure returns (int256) {
        return a % b;
    }

    function _div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "Can not divide by zero");
        return a / b;
    }
}
