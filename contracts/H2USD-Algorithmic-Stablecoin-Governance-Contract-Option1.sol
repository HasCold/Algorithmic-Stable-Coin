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

// Option 1 :- To repeg the value H2USD stable coin to 1$ we burnt or mint the token of our H2USD Stable Coin.
// Option 2 :- To repeg the value H2USD stable coin to 1$ we burnt or mint our own utility token in this case.

contract H2USDGovernance is Ownable, ReentrancyGuard, AccessControl {
        using SafeERC20 for IERC20;
        using SafeMath for uint256;

        constructor(H2USD _h2usd) Ownable(msg.sender) {
            // In this way governance smart contract gets attached to the stablecoin smart contract
            h2usd =  _h2usd;
            _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
            _grantRole(GOVERN_ROLE, _msgSender());
        }

        struct SuppChange {  // supply change
            string method;  // Method will be checked either it is mint or burned
            uint256 amount;  // Burning Amount
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
        function collateralRebalancing() internal returns (bool) {  // we are going to call this function in validatePer()
            // This information here going to give the algorithm stablecoin 
            // .collToken has IERC20 interface function which you can call  // 0 means usdt  // How much stable collateral do we have 
            uint256 stableBalance = rsvList[0].collToken.balanceOf(reserveContract); 
            uint256 unstableBalance = rsvList[1].collToken.balanceOf(reserveContract); // 1 -->> WETH 
        
            if(stableBalance != stableCollatAmount){
                stableCollatAmount = stableBalance;
            }
            if(unstableBalance != unstableCollatAmount){
                unstableCollatAmount = unstableBalance;
            }
            return true;
        }

// --------------- Algorithmic Stable Coin Functionality ---------------------------
        function validatePeg() external nonReentrant {
            require(hasRole(GOVERN_ROLE, _msgSender()), "Not Allowed");
            h2usdSupply = h2usd.totalSupply();
            bool res = collateralRebalancing();

            if(res == true){            // stable price + unstable price
                uint256 rawCollPrice = (stableCollatAmount.mul(1e18)).add(unstableCollatAmount.mul(unstableCollatPrice));
                uint256 collValue = rawCollPrice.mul(WEI_VALUE);  // Total Collateral Value
                if(collValue < h2usdSupply){    
                    // Suppose the price of WETH is going down so in this way we are going to burn the tokens 
                    uint256 supplyChange = h2usdSupply.sub(collValue); // 1M tokens - Collateral Value
                    h2usd.burn(supplyChange);

                    _supplyChanges[supplyChangeCount].method = "Burn";
                    _supplyChanges[supplyChangeCount].amount = supplyChange;
                }

                // Suppose the price of collateral or WETH is going up so in this way we are going to rebalancing or mint the h2usd stable coin 
                if(collValue > h2usdSupply) {
                    uint256 supplyChange = collValue.sub(h2usdSupply); 
                    h2usd.mint(supplyChange);

                    _supplyChanges[supplyChangeCount].method = "Mint";
                    _supplyChanges[supplyChangeCount].amount = supplyChange;
                }  

                h2usdSupply = collValue;  // collateral value dictate how many stable coins we have
                _supplyChanges[supplyChangeCount].timeStamp = block.timestamp;
                _supplyChanges[supplyChangeCount].blockNum = block.number;
                supplyChangeCount++;

                emit RepegAction(block.timestamp, collValue);               
            }
        }

        // h2usd tokens held in our govrnance smart contract 
        function withdraw(uint256 _amount) external nonReentrant {
            require(hasRole(GOVERN_ROLE, _msgSender()), "Not Allowed");
            require(_amount > 0 , "Amount must be greater than zero");

            IERC20(h2usd).safeTransferFrom(address(this), address(msg.sender), _amount);  // transfer amount from governance contract to my wallet
            emit Withdraw(block.timestamp, _amount);
        }
}