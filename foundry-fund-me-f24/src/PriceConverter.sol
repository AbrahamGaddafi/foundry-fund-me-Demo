//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import{AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

//this here will act as a library since we are gonna be using this price converter very often.
library PriceConverter{
//libraries can't have state variables and all the functions has to be marked internal.
  //we'll need to convert the amount of ethereum into it's value of dollars.
//we'll create a function that'll get price of ethereum in terms of usd
function getPrice(AggregatorV3Interface priceFeed) internal view returns(uint256){
//to get the price we'll use a chainlink data feed(statically),we'll need the address of the feed and ABI.
// (Static usage)
//AggregatorV3Interface priceFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
//we'll have to pass everything from our Agreggator github in here as shown;
(,int256 price,,,)= priceFeed.latestRoundData();//price of ETH in USD.
return uint256 (price)* 1e10;//since our price has 8 decimal places and wei has 18 decimal places.
//Also type cast from int to uint
}

//this function will convert eth to dollars.
function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns(uint256) {
//first we'll get the price of ethereum
uint256 ethPrice = getPrice(priceFeed);
uint256 ethAmountInUSD = (ethPrice * ethAmount)/ 1e18;//we divide to reduce it back to 18decimal places from 36(18*18).
return ethAmountInUSD;
}

function getVersion() internal view returns(uint256){
    return AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306).version();
}


}