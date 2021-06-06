// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./BlueCoin.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Calculator
 * @author Alector
 * @dev Calculator is a service that is going to be used with coins bought in the Initial Coin Offering  (BlueCoinICO.sol).
 * Users can buy coins from BlueCoinICO and then consume them to use other services like Calculator.sol.
 */
contract Calculator is Ownable {
    uint256 private _calcPrice;
    BlueCoin private _coin;
    address private _owner;

    event Calculation(string calcType, address indexed user, int256 a, int256 b, int256 result);

    /**
     * @dev set the coin address, the owner and the price
     * the owner of the contract is set, by default, the same as the owner of the coin
     * @param coinAddress address of deployed ERC20 token BlueCoin
     **/

    constructor(address coinAddress) {
        _coin = BlueCoin(coinAddress);
        _owner = _coin.getOwner();
        Ownable.transferOwnership(_owner);
        _calcPrice = 1 ether;
    }

    /**
     * @dev set the price that every operation costs
     * only the owner can set the price
     * @param price_ the cost of every operation
     **/
    function setPrice(uint256 price_) public onlyOwner {
        _calcPrice = price_;
    }

    /**
     * @dev get the price that every operation costs
     * @return the price of every operation
     **/
    function getPrice() public view returns (uint256) {
        return _calcPrice;
    }

    /**
     * @dev get owner of the contract
     * @return the owner of the contract
     **/
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

    /**
     * @dev for every operation user has to pay some tokens
     * Before using this function the owner must have approved the propper ammount of tokens to the contract address
     * Important!  No need to check here if the approval was given and if the allowance exists. The inherited ERC20 already does this required check for us.
     **/
    function _pay(address sender) internal {
        _coin.transferFrom(sender, _owner, _calcPrice);
    }

    /**
     * @dev arithmetic operation of addition
     * @param a the first number of the operation
     * @param b the second number of the operation
     * @return the result of the operation
     * For every operation user has to spend a certain amount of tokens that he bought from the ICO of BlueCoin.
     **/
    function add(int256 a, int256 b) public haveEnoughTokens returns (bool) {
        _pay(msg.sender);
        emit Calculation("add", msg.sender, a, b, _add(a, b));
        return true;
    }

    /**
     * @dev arithmetic operation of subtraction
     * @param a the first number of the operation
     * @param b the second number of the operation
     * @return the result of the operation
     * For every operation user has to spend a certain amount of tokens.
     **/
    function sub(int256 a, int256 b) public haveEnoughTokens returns (bool) {
        _pay(msg.sender);
        emit Calculation("sub", msg.sender, a, b, _sub(a, b));
        return true;
    }

    /**
     * @dev arithmetic operation of multiplication
     * @param a the first number of the operation
     * @param b the second number of the operation
     * @return the result of the operation
     * For every operation user has to spend a certain amount of tokens.
     **/
    function mul(int256 a, int256 b) public haveEnoughTokens returns (bool) {
        _pay(msg.sender);
        emit Calculation("mul", msg.sender, a, b, _mul(a, b));
        return true;
    }

    /**
     * @dev arithmetic operation of division
     * @param a the first number of the operation
     * @param b the second number of the operation
     * @return the result of the operation
     * For every operation user has to spend a certain amount of tokens.
     **/
    function div(int256 a, int256 b) public haveEnoughTokens returns (bool) {
        _pay(msg.sender);
        emit Calculation("div", msg.sender, a, b, _div(a, b));
        return true;
    }

    /**
     * @dev arithmetic operation of modulo
     * @param a the first number of the operation
     * @param b the second number of the operation
     * @return the result of the operation
     * For every operation user has to spend a certain amount of tokens.
     **/
    function mod(int256 a, int256 b) public haveEnoughTokens returns (bool) {
        _pay(msg.sender);
        emit Calculation("mod", msg.sender, a, b, _mod(a, b));
        return true;
    }

    /**
     * @dev pure internal function, arithmetic operation of addition
     * @param a the first number of the operation
     * @param b the second number of the operation
     * @return the result of the operation
     **/
    function _add(int256 a, int256 b) internal pure returns (int256) {
        return a + b;
    }

    /**
     * @dev pure internal function, arithmetic operation of subtraction
     * @param a the first number of the operation
     * @param b the second number of the operation
     * @return the result of the operation
     **/
    function _sub(int256 a, int256 b) internal pure returns (int256) {
        return a - b;
    }

    /**
     * @dev pure internal function, arithmetic operation of multiplication
     * @param a the first number of the operation
     * @param b the second number of the operation
     * @return the result of the operation
     **/
    function _mul(int256 a, int256 b) internal pure returns (int256) {
        return a * b;
    }

    /**
     * @dev pure internal function, arithmetic operation of modulo
     * @param a the first number of the operation
     * @param b the second number of the operation
     * @return the result of the operation
     **/
    function _mod(int256 a, int256 b) internal pure returns (int256) {
        return a % b;
    }

    /**
     * @dev pure internal function, arithmetic operation of division
     * @param a the first number of the operation
     * @param b the second number of the operation
     * @return the result of the operation
     **/
    function _div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0, "Can not divide by zero");
        return a / b;
    }
}
