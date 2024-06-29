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

    uint256 public currentReserveId;

    struct ReserveVault{
        IERC20 collateral;
        uint256 amount; 
    }

    mapping (uint256 => ReserveVault) public _rsvVault;

    event Withdraw(uint256 indexed vid, uint256 amount);  // vid = vault Id
    event Deposit(uint256 indexed vid, uint256 amount);

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE"); // Admin role allow the people allow the owner of the smart contract to add more people

    constructor() Ownable(msg.sender){
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(MANAGER_ROLE, _msgSender());
    }

    function checkReserveContract(IERC20 _collateral) internal view {
        for (uint i; i < currentReserveId; i++){
            require(_rsvVault[i].collateral != _collateral, "Collateral Address Already Added");  // current IERC20 collateral address doesn't match in the vault
        }
    }

    function addReservesVault(IERC20 _collateral) external {
        require(hasRole(MANAGER_ROLE, _msgSender()), "Not Allowed");

        checkReserveContract(_collateral); // Check that this reserve is not already exist into the vault
        _rsvVault[currentReserveId].collateral = _collateral;
        currentReserveId++;  // To increase the Reserve Vault id to plus 1
    }

    function depositCollateral(uint256 _vid, uint256 _amount) external {  // vid = vault id
        require(hasRole(MANAGER_ROLE, _msgSender()), "Not Allowed");
        require(_amount > 0, "Amount must be greater than zero");

        IERC20 reserves = _rsvVault[_vid].collateral;  // first pre-approve the USDT or WETH tokens before sending to this smart contract 
        reserves.safeTransferFrom(address(msg.sender), address(this), _amount);  // From myWallet, to this Smart contract, amount

        // Update the current vault amount
        uint256 currentVaultBalance = _rsvVault[_vid].amount;
        _rsvVault[_vid].amount = currentVaultBalance.add(_amount);  // simplify like that _rsvVault[vid].amount += _amount 
        emit Deposit(_vid, _amount);
    }

        function withdrawCollateral(uint256 _vid, uint256 _amount) external {  
        require(hasRole(MANAGER_ROLE, _msgSender()), "Not Allowed");
        require(_amount > 0, "Amount must be greater than zero");

        IERC20 reserves = _rsvVault[_vid].collateral;
        uint256 currentVaultBalance = _rsvVault[_vid].amount;
        // Update the current vault amount
        if(currentVaultBalance >= _amount){
            reserves.safeTransfer(address(msg.sender), _amount);  // From this Smart contract, amount
            _rsvVault[_vid].amount = currentVaultBalance.sub(_amount);  // simplify like that _rsvVault[vid].amount += _amount 
            
        } // vid[0] = usdt ; vid[1] = utility token (WETH)

        emit Withdraw(_vid, _amount);
    }
}