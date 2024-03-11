//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
//we'll need to import scripts from our scripts folder
import {Script} from "forge-std/Script.sol";
//we'll need to import the contracts we deploying as well ie fundMe
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

 //inherit everything from script
 contract DeployFundMe is Script{
  //Function to run our script
  FundMe fundMe;
  function run() external  returns(FundMe){
      //we'll create a new helper config right before we broadcast
      HelperConfig helperConfig = new HelperConfig();
      //now we can get the address we want
       address ethUsdPriceFeed = helperConfig.activeNetworkConfig();//since this is a struct when we add elements we'll wrap the first part with parantheses and separate with commas

      vm.startBroadcast();
      fundMe = new FundMe(ethUsdPriceFeed);//here we actually put the adress to the chainlink we on now
      vm.stopBroadcast();
      return fundMe;

  }
 }
 