// SPDX-License-Identifier: MIT LICENSE

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

pragma solidity ^0.8.17.0;
// Docs :- https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/

// For SafeMath.sol :-
// https://github.com/ConsenSysMesh/openzeppelin-solidity/blob/master/contracts/math/SafeMath.sol

contract USDT is ERC20, ERC20Burnable, Ownable {
    using SafeERC20 for ERC20;
    constructor() ERC20("Tether USD", "USDT") Ownable(msg.sender) {}

    function mint(uint256 _amount) external onlyOwner {
        _mint(msg.sender, _amount);
    }

}