// SPDX-License-Identifier: MIT LICENSE

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

pragma solidity ^0.8.17.0;
// Docs :- https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/

contract WETH is ERC20, ERC20Burnable, Ownable {
    using SafeERC20 for ERC20;
    constructor() ERC20("Wrapped ETH", "WETH") Ownable(msg.sender) {}

    function mint(uint256 _amount) external onlyOwner {
        _mint(msg.sender, _amount);
    }

}

//  We are not going to mint any tokens becuase we don't know the price of ETH or don't know the supply of tokens ; we are just going to add the smart contract into the reserve smart contract or add this contract into the vault