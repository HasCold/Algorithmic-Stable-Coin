// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18.0;

// Option 2 :- We are now using our own utility unstable token (h2DR) for the 2nd collateral to maintain the stable coin price at 1$ 

// h2DR token :-
//  Market Cap    Supply                 =   Price   
// 80,000,000 / 1 Billion(1,000,000,000) = 0.08 cents price of our utility token(h2DR). 
// 10 million tokens are in reserve contract and are dropping down to price 0.08 as collateral B.  
// 0.08 * 10,000,000  =  800,000 collateral B

// H2USD Stable Coin Peg to 1$ (Supply : 1,000,000)
// collateral A = 200,000  (USDT Stable Coin)
// collateral B = 800,000  (n2DR unstable utility token)

// H2USD stable coin initial supply will be fixed :- 1,000,000 (1 Million)
// Stable Price :- 0.99 - 1.00 $ 

// If the price of n2DR token drop to 0.06 cents
// 0.06 * 10,000,000 = 600,000 collateral B

// We have two options that we could burn the H2USD supply which is 1Million as option1 and the option2 is burn the n2DR token the supply is 1 Billion so it is feasible to burn the n2DR tokens becuase we have more supply rather than H2USD

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./H2USD-Stablecoin-Smart-Contract.sol";
import "./H2DR(utility token).sol";


contract H2USDGovernOpt2 is Ownable, ReentrancyGuard, AccessControl {
        using SafeERC20 for IERC20;
        using SafeMath for uint256;

        constructor(H2USD _h2usd, H2DR _h2dr) Ownable(msg.sender) {
            // In this way governance smart contract gets attached to the stablecoin smart contract
            h2usd =  _h2usd;
            h2dr =  _h2dr;
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
        
        H2USD private h2usd; // Algo Stable Coin
        H2DR private h2dr;  // Collateral B utility token
        address private reserveContract;  // used to store information or data internally
        uint256 public h2usdSupply;  // Updated the token supply when we repeg 
        uint256 public h2drSupply;
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

        // Interact with the reserve smart contract
        function setReserveContract(address reserve) external nonReentrant {
            require(hasRole(GOVERN_ROLE, _msgSender()), "Not Allowed");
            require(reserve != address(0), "Invalid Address");
            reserveContract = reserve;
        }       

        function setH2drTokenPrice(uint256 marketCap) external nonReentrant {
            require(hasRole(GOVERN_ROLE, _msgSender()), "Not Allowed");
            h2drSupply = h2dr.totalSupply();
            
            // Market Cap *  Total Supply
            // 80,000,000   ×   1000000000 (1 Billion)   =   800,000,000,000,000 (8.e+16)
            // 8.e+16   ÷   1e18    =   0.08 cents price of h2dr token

            unstableCollatPrice = (marketCap.mul(h2drSupply)).div(WEI_VALUE);
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

            if(res = true){            // stable price + unstable price
                uint256 rawCollValue = (stableCollatAmount.mul(1e18)).add(unstableCollatAmount.mul(unstableCollatPrice));
                uint256 collValue = rawCollValue.div(WEI_VALUE);  // Total Collateral Value
                if(collValue < h2usdSupply){    
                    // MarketCap         /           Total Supply 
                    // 80,000,000       /       1,000,000,000   =   0.08 cents
                    //  10,000,000 (10 M) tokens are reserved in the vault  *   0.08   =  800,000 collateral B 

                // Suppose the price of our utility token is going down to 0.06 so in this way we are going to burn the tokens
                    // 0.06  *   1,000,000,000      =       60,000,000 (60 M) Market Cap 
                // That Means : - 
                    // 600,000  collateral B 
                    // 200,000 Loss of collateral 
                    //                      1,000,000 - (600,000 + 200,000)
                    uint256 supplyChange = h2usdSupply.sub(collValue); 
                    uint256 burnAmount = (supplyChange.div(unstableCollatPrice)).mul(WEI_VALUE);
                    //                      200,000     /       0.06     =  3,333,333,e+18
                    h2dr.burn(burnAmount);

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

        function withdrawH2dr(uint256 _amount) external nonReentrant {
            require(hasRole(GOVERN_ROLE, _msgSender()), "Not Allowed");
            require(_amount > 0 , "Amount must be greater than zero");

            IERC20(h2dr).safeTransferFrom(address(this), address(msg.sender), _amount);  // transfer amount from governance contract to my wallet
            emit Withdraw(block.timestamp, _amount);
        }
}