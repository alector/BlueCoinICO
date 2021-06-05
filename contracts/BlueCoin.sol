//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BlueCoin is ERC20 {
    address private _owner;

    constructor(address owner_, uint256 totalSupply_) ERC20("BlueCoin", "BCN") {
        _owner = owner_;
        _mint(owner_, totalSupply_ * 10**decimals());
        // NOTE: _mint adds totalSuppy to _balances[owner_]
        // Total supply belongs to owner_ and is accessible
        // through totalSupply(),
        // also equal to balanceOf(owner_)
    }

    function getOwner() public view returns (address) {
        return _owner;
    }

    // NOTE: in case of multiple inheritance down to ICO
    // function transferTo(address sender, uint256 amount) public returns (bool) {
    //     require(msg.sender == _owner, "BlueCoin:Only owner can transfer coins directly");
    //     _transfer(_owner, sender, amount);
    //     return true;
    // }
}
