//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title BlueCoin (BCN)
 * @author Alector
 * @dev BlueCoin is a token that is going to be bought as a coin in the Initial Coin Offering  (BlueCoinICO.sol).
 * Users can buy coins from BlueCoinICO and then consume them to use other services like Calculator.sol.
 */
contract BlueCoin is ERC20 {
    address private _owner;

    /**
     * @dev BlueCoin is an instance of ERC20 standard
     * @param owner_ the address of the owner
     * @param owner_ the total supply of tokens
     * By default all tokens be assigned to the balance of the owner
     * The _mint() is build-in function of ERC20 standard, and allocates totalSuppy to _balances[owner_]
     * The Total supply belongs to owner_ and is accessible through totalSupply(),also equal to balanceOf(owner_)
     **/
    constructor(address owner_, uint256 totalSupply_) ERC20("BlueCoin", "BCN") {
        _owner = owner_;
        _mint(owner_, totalSupply_ * 10**decimals());
    }

    function getOwner() public view returns (address) {
        return _owner;
    }
}
