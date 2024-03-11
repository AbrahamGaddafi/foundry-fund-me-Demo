//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

//here we'll have all the ways that we can actually interact with our contract.
//we'll make a fund script and a withdraw script
import {Script, console} from "forge-std/Script.sol";
//we'll then import our devops tools
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";
//in our foundry.toml we'll set ffi=true
import {FundMe} from "../src/FundMe.sol";

contract FundFundMe is Script {
    //this will be our script for funding the fund me contract
    uint256 constant SEND_VALUE = 0.01 ether;

    function fundFundMe(address mostRecentlyDeployed) public view {
        FundMe(payable(mostRecentlyDeployed)).fund{value: SEND_VALUE};
        console.log("Funded FundMe with %s", SEND_VALUE); //u'll import console as well.
    }

    function run() external {
        //we'll need to fund our most recently deployed contract
        //you can use foundry devops from github, it helps your foundry keep track of the most recently deployed version of the contract.
        //we'll first need to install it.
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "FundMe",
            block.chainid
        ); //pass in contract name as args
        vm.startBroadcast();
        fundFundMe(mostRecentlyDeployed); //we then pass in our most recently deployed in the fund function.
        vm.stopBroadcast();
    }
}

contract WithdrawFundMe is Script {
    //this will be our script for withdrawing from the fund me contract
    function withdrawFundMe(address mostRecentlyDeployed) public {
        vm.startBroadcast();
        FundMe(payable(mostRecentlyDeployed)).withdraw();
        vm.stopBroadcast();
        }

    function run() external {
        //we'll need to fund our most recently deployed contract
        //you can use foundry devops from github, it helps your foundry keep track of the most recently deployed version of the contract.
        //we'll first need to install it.
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment(
            "FundMe",
            block.chainid
        ); //pass in contract name as args
        vm.startBroadcast();
        withdrawFundMe(mostRecentlyDeployed); //we then pass in our most recently deployed in the fund function.
        vm.stopBroadcast();
    }
}
