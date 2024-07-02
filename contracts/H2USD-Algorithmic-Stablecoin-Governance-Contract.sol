// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import "./H2USD-Stablecoin-Smart-Contract.sol";

contract H2USDGovernance is Ownable, ReentrancyGuard, AccessControl {
        using SafeERC20 for ERC20;
        using SafeMath for uint256;

        constructor(H2USD _h2usd) Ownable(msg.sender) {
            // In this way governance smart contract gets attached to the stablecoin smart contract
            h2usd =  _h2usd;
            _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
            _grantRole(GOVERN_ROLE, _msgSender());
        }

        struct SuppChange {  // supply change
            string method;  // Method will be checked either it is mint or burned
            uint256 amount;
            uint256 timeStamp;
            uint256 blockNum;  // store at one block number that the rebalancing of the token happen  
        }

        struct reserveList {
            IERC20 collToken;
        }

        mapping(uint256 => reserveList) public rsvList;  // store two smart contract addresses 1. USDT 2. WETH
        
        H2USD private h2usd;
        AggregatorV3Interface private priceOracle;
        address private reserveContract;  // used to store information or data internally
        uint256 public h2usdSupply;  // Updated the token supply when we repeg 
        address public dataFeed;  // ETH/USD  or any address that you want to get price info
        uint256 public supplyChangeCount;  // everytime keep a count when we do the rebalancing  
        uint256 public stableCollatPrice = 1e18; 
        uint256 public stableCollatAmount;
        uint256 private constant COL_PRICE_TO_WEI = 1e10;   // receiving a 8 decimal price so we convert it into wei
        uint256 private constant WEI_VALUE = 1e18;  // Convert any value to wei
        uint256 public unstableCollatAmount;
        uint256 public unstableCollatPrice;
        uint256 public reserveCount;  // keep a count for a reserveList when we called

        mapping(uint256 => SuppChange) public _supplyChanges;

        bytes32 public constant GOVERN_ROLE = keccak256("GOVERN_ROLE");  // anyone has a role that can be call the function

        // The Governance Smart Contract holds the H2USD because when it mints the tokens it gets delivered onto the governance smart contract 
        event RepegAction(uint256 indexed time, uint256 indexed amount);
        event Withdraw(uint256 indexed time, uint256 indexed amount);

        function addCollateralToken(IERC20 collContract) external nonReentrant {
            require(hasRole(GOVERN_ROLE, _msgSender()), "Not Allowed");
            rsvList[reserveCount].collToken = collContract;
            reserveCount++;
        }

        function setDataFeedAddress(address contractAddress) external {
            require(hasRole(GOVERN_ROLE, _msgSender()), "Not Allowed");
            require(contractAddress != address(0), "Invalid Address");

            dataFeed = contractAddress;  // we want to know the what is data feed address so that's declare it separately
            priceOracle = AggregatorV3Interface(dataFeed);
        }

        // Get token price
        function fetchCollPrice() external nonReentrant {
            require(hasRole(GOVERN_ROLE, _msgSender()), "Not Allowed");
            (, uint256 price, , ,) = priceOracle.latestRoundData();
            unstableCollatPrice = price.mul(COL_PRICE_TO_WEI);
        }

        // Interact with the reserve smart contract
        function setReserveContract(address reserve) external nonReentrant {
            require(hasRole(GOVERN_ROLE, _msgSender()), "Not Allowed");
            require(reserve != address(0), "Invalid Address");
            reserveContract = reserve;
        }       

        // Collateral Rebalancing function to determine if the balance or reserve is higher or lower and updating those values that we can peg or validate the peg 
        function collateralRebalancing() external returns (bool) {  // we are going to call this function in validatePer()
            // This information here going to give the algorithm stablecoin 
            // .collToken has IERC20 interface function which you can call  // 0 means usdt  // How much stable collateral do we have 
            uint256 stableBalance = rsvList[0].collToken.balanceOf(reserveContract); 
        
        }
}