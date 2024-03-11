//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

//we'll need to import some test folders
import {Test, console} from "forge-std/Test.sol"; //build in solidity test file
//we'll also need to import our FundMe contract for it to be visible to the test contract
import {FundMe} from "../../src/FundMe.sol";
//we can as well import our deploy contract so that we dont have to change our deploy when we update tests
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {FundFundMe, WithdrawFundMe} from "../../script/Interactions.s.sol";

//our Test contract will now inherit everything from the file
contract FundMeTestIntegration is Test {

    FundMe fundMe;
    //We'll make our fake address to do our tests
    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

  
   function setUp() external {
     //we'll first deploy our fund Me
     DeployFundMe deploy = new DeployFundMe();
     fundMe = deploy.run(); //we do this since run in our deploy contract returns fund me
        //we'll create a cheatcode to send our USER money since we'll be using the address for tests
        vm.deal(USER, STARTING_BALANCE);
   }
    
   function testUserCanFundIntegration() public{
   //instead of funding directly by the functions we'll import from interactions script.
   //we then declare the fund fund me
    FundFundMe fundFundMe = new FundFundMe();
    fundFundMe.fundFundMe(address(fundMe));

    //we'll fund using our scripts and withdraw using our scripts as well
    WithdrawFundMe withdrawFundMe = new WithdrawFundMe();
    withdrawFundMe.withdrawFundMe(address(fundMe));
    
    assert(address(fundMe).balance==0);
     
   }

}