// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

//import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {AggregatorV3Interface} from "lib/foundry-chainlink-toolkit/lib/chainlink-brownie-contracts/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getPrice(address priceFeed) internal view returns (uint256 price) {
        // address 0x694AA1769357215DE4FAC081bf1f309aDC325306
        // abi

        AggregatorV3Interface dataFeed = AggregatorV3Interface(priceFeed);

        (,int256 answer,,,) = dataFeed.latestRoundData(); // return the price of eth in terms of usd 1 eth = 319762 usd.
        price = uint256(answer * 1e10);
    }

    function getConversionRate(uint256 ethAmount, address priceFeed) internal view returns(uint256 ethAmountInUsd) {
        //1 eth ?
        // let say this returns 2000_000000000000000000
        uint256 ethPrice = getPrice(priceFeed);
        //(2000_000000000000000000 * 1_000000000000000000) / 1e18 = 2000 USD = 1 ETH
        ethAmountInUsd = (ethPrice * ethAmount) / 1e18; //since both ethPrice and ethAmount have 18 decimal houses, we'll have as result a number with 36 decimal houses hence we need to divide by 18 decimals
    }

    function getVersion(address priceFeed) internal view returns (uint256 version) {
        AggregatorV3Interface dataFeed = AggregatorV3Interface(priceFeed);

        version = dataFeed.version();
    }
}