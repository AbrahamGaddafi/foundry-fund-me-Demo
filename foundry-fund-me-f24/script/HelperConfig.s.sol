//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

//This is a contract we can deploy our own price feed and interact with that for the rest of our tests
//this allows us also to not hardcode addresses 
//in this contract we'll deploy mocks when on local anvil chain
//we'll also keep track of contracts addresses across different chains
import {Script} from "forge-std/Script.sol";
//we'll also need to import mocks to help deal with our local anvil chainlink
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script{
 //Assuming we wanna work with something like sepolia
 //we'll create a function for that
 NetworkConfig public activeNetworkConfig;//we'll set this equal to whichever active network config we are on at a particular time

//then the constructor of a mock takes a decimal and an initial answer
//the decimals of ETH usd is 8  and initial answer(price) we could do sth like 2000
uint8 public constant DECIMALS = 8;
int256 public constant INITIAL_PRICE = 2000e8;

 //we may need a bunch of things we need for our sepolia eg address,gas & so on...so we create structs to help with this
 
 struct NetworkConfig{
     address priceFeed;
 }
 //to set our active network config we'll use a constructor
 constructor(){
      if(block.chainid == 11155111){
        //the chain id refers to the chains current ID,every network has its own ID
        //11155111 is the chain ID for sepolia
        activeNetworkConfig = getSepoliaEthConfig();
      }
      else if(block.chainid == 1){
       activeNetworkConfig = getMainnetEthConfig();
      }
      else{
         activeNetworkConfig = getOrCreateAnvilEthConfig();
      }
  }



 function getSepoliaEthConfig() public pure returns (NetworkConfig memory){
    //this function will return configuration for everything we need in sepolia.
    NetworkConfig memory sepoliaConfig = NetworkConfig(
        {priceFeed :0x694AA1769357215DE4FAC081bf1f309aDC325306});
        return sepoliaConfig;
 }
 
  function getMainnetEthConfig() public pure returns (NetworkConfig memory){
    //for ETH.
    NetworkConfig memory ethConfig = NetworkConfig(
        {priceFeed :0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419});
        return ethConfig;
 }


 function getOrCreateAnvilEthConfig() public  returns (NetworkConfig memory){
//on the anvil network we'll have to deploy ourselves
//to avoid creating a new price feed if we already have one if we call getanvilconfig we wouldn't wanna deploy a new one.

   if(activeNetworkConfig.priceFeed != address(0)){
       return activeNetworkConfig;
   }

//then we'll deploy the mocks then return the mock addresses
//to deploy the mocks to the anvil chain we'll do a broadcast
      vm.startBroadcast();//our function cant now be public pure bcoz we using vm keyword
      //here we create our mock now
      MockV3Aggregator mockPriceFeed = new MockV3Aggregator(DECIMALS,INITIAL_PRICE);      
      vm.stopBroadcast();
      //outside of the broadcast now.
      NetworkConfig memory anvilConfig = NetworkConfig({
        priceFeed: address(mockPriceFeed)
         });
      return anvilConfig;

 }
}
 
