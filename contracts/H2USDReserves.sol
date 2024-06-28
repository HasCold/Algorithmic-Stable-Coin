// SPDX-License-Identifier: MIT LICENSE

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";


pragma solidity ^0.8.17.0;
// Docs :- https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/

contract H2USDReserves is Ownable, ReentrancyGuard, AccessControl {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    constructor() Ownable(msg.sender) {}

    
}