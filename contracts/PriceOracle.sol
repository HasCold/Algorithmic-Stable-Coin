// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18.0;

// Chainlink is a Decentralized Oracle Systems Network.

// ChainLink Price Feeds 
// https://docs.chain.link/data-feeds/price-feeds/addresses?network=ethereum&page=1#networks

// You can refer how does the price you can read from chainlink data feed 
// https://docs.chain.link/data-feeds/using-data-feeds

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// Change the following thing going down into the node_modules dir follow the path :-  @chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol
// 1. latestRoundData() -->> Change data-type "answer" parameter from int256 to uint256  

contract PriceOracle {
    using SafeMath for uint256;

    AggregatorV3Interface private priceOracle;
    uint256 public unstableColPrice;   // like WETH 
    address public dataFeed;  // get a different token price 

    function setDataFeedAddress(address contractAddress) external {
        require(contractAddress != address(0), "Invalid address");

        dataFeed = contractAddress;
        priceOracle = AggregatorV3Interface(dataFeed);
    }

    function collPriceToWei() external {
        (, uint256 price, , ,) = priceOracle.latestRoundData();  // Tuple to get only answer value only

        // ETH/USD price 8 decimal convert it into 18(wei) decimal places 1e8 * 1e10 = 1e18 wei
        unstableColPrice = price.mul(1e10);   // 1e8 * 1e10 = 1e18 wei
    }

    // Price Feeds Data :- https://docs.chain.link/data-feeds/price-feeds/addresses?network=ethereum&page=1#networks
    // Sepolia Testnet Network :-  ETH/USD 0x694AA1769357215DE4FAC081bf1f309aDC325306

    function rawCollPrice() external view returns(uint256) {
        (, uint256 price, , ,) = priceOracle.latestRoundData();  // Tuple to get only answer value only
        return price;
    }

}