// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

// ---------- We are going to associate this smart contract to the governance smart contract ------------

// This contract have a ERC20 tokens
contract H2USD is ERC20, ERC20Burnable, Ownable, AccessControl {
    using SafeMath for uint;
    using SafeERC20 for ERC20;

    constructor() ERC20("H2USD Stable", "H2USD") Ownable(msg.sender) {  //  ERC20("Name", "Symbol")
        // enabling the manager role in the deployer account ; when I deploy the contract it assign the MANAGER_ROLE and ADMIN_ROLE in the function
        _grantRole("ADMIN_ROLE", _msgSender());
        _grantRole("MANAGER_ROLE", _msgSender());        
    }  

    // Track through mapping :- How many times have we mint the tokens or have we mint the stable coins
    mapping(address => uint256) private _balances;

    uint256 private _totalSupply;
    // Access Control ; So that I can make sure that not any everybody can mint tokens  
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    function mint(uint256 amount) external {
        require(amount > 0, "Amount must be greater than zero");
        require(hasRole(MANAGER_ROLE, _msgSender()), "Not Allowed");

        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        // Mint the tokens and make sure that the tokens are delievred to their account
        _mint(msg.sender, amount);  // _mint function can be found at this openzeppelin/contracts/token/ERC20/ERC20.sol
    }
}