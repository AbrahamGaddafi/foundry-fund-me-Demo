//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

//we'll need to import some test folders
import {Test, console} from "forge-std/Test.sol"; //build in solidity test file
//we'll also need to import our FundMe contract for it to be visible to the test contract
import {FundMe} from "../../src/FundMe.sol";
//we can as well import our deploy contract so that we dont have to change our deploy when we update tests
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

//our Test contract will now inherit everything from the file
contract FundMeTest is Test {
    //we wanna first test if our fund me contract is doing what it's meant to do
    FundMe fundMe;
    //We'll make our fake address to do our tests
    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        //we can test using console.log
        //we'll deploy our contract here
        //fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run(); //we do this since run in our deploy contract returns fund me
        //we'll create a cheatcode to send our USER money since we'll be using the address for tests
        vm.deal(USER, STARTING_BALANCE);
    }

    //we can write another test to check minimum $ we specified
    function testMinimumDollarIsFive() public {
        //we'll use the assert equal fn to check this
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    //we can write another one to check if the owner is actually the sender
    function testOwnerIsMsgSender() public {
        assertEq(fundMe.getOwner(), msg.sender);
        //assertEq(fundMe.i_owner(),address(this));//we'll check to see if fundme test is the owner since now we are in this very contract address and not the fund me contract
    }

    //we can write test to test if price feed version is accurate
    function testPriceFeedVersionIsAccurate() public {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    //if we don't send our fund function the function should revert. Let's write a test for that
    function testFundFailsWithoutEnoughETH() public {
        //we can use a cheatcode from foundry documentation to help with this
        //we'll use expect revert
        vm.expectRevert();
        //we then tell foundry to revert.
        fundMe.fund(); //we don't pass in any value ie $0 which is < $5
    }

    //after sending well update the amount funded and add who funded,we need also a test for that
    function testFundUpdatesFundedDataStructure() public {
        //we can use prank cheatcode to always know exactly who is sending what call
        //we can then prank and say the next transaction will be sent by USER
        vm.prank(USER);
        //we'll send a value greater than $5
        fundMe.fund{value: SEND_VALUE}();
        //we'll then need to check if address to amount funded is getting updated
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    //we need a test to check if our funders are added to our array of funders
    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }
    
    //every single time we wanna fund our tests instead of writing numerous codes all the time we can create a modifier to help us
    modifier funded(){
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;  
    }

    //we need to test that only owner can withdraw
    function testOnlyOwnerCanWithdraw() public funded {//public funded passes in the parameters of the funded modifier
        //we'll have the user try to withdraw coz the user aint the owner
        vm.expectRevert();
        vm.prank(USER);//bcoz the user is not the owner
        fundMe.withdraw();
    }
   
    //let's test that withdrawing actually works
    function testWithdrawWithASingleFunder() public funded{
    //also takes everything from the funded modifier
    //We'll use the;
    //(i)Arrange-->first check to see what's our balance b4 we call withdraw so that we can compare it with what our balance is after
    uint256 startingOwnerBalance = fundMe.getOwner().balance;
    //then the actual balance of the fund me contract
    uint256 startingFundMeBalance = address(fundMe).balance;
    //(ii)Act --> 
    //for us to simulate this transaction with actual gas prices we'll use another cheat code
    //we'll tell our test to pretend to use real gas prices
    
    //to see how much gas is gonna be spent we need to call this gas before & after
    uint256 gasStart = gasleft();//gas left is a built in function in solidity and tells u how much gas is left in ur tx call
    vm.txGasPrice(GAS_PRICE);
    vm.prank(fundMe.getOwner());
    fundMe.withdraw();//this is what we are testing
    uint256 gasEnd = gasleft();
    uint256 gasUsed = (gasStart - gasEnd)* tx.gasprice;
    console.log(gasUsed); //we'll see how much gas this exact call used


    //Assert --->last Methodology when working with tests
    uint256 endingOwnerBalance = fundMe.getOwner().balance;
    uint256 endingFundMeBalance = address(fundMe).balance;
    assertEq(endingFundMeBalance,0);//we should have withdrawn all the money of the fund me
    assertEq(startingFundMeBalance + startingOwnerBalance,endingOwnerBalance);

    }

    //we'll the test withdraw from multiple funders
    function testWithdrawFromMultipleFunders() public funded{
    //it's gonna be funded once by our modifier but let's add a ton more funders
    //for addresses we must explicitly do uint 160
    uint160 numberOfFunders = 10;
    //the 0th address sometimes reverts so start with one
    uint160 startingFunderIndex = 1;
    
    //we'll use a loop and create new funders
    for(uint160 i=startingFunderIndex; i<numberOfFunders; i++){
    //we'll use a vm prank and vm deals and create addresses to fund the fund me
    //the hoax cheatcode does both prank and deal combined and we can use that
    hoax (address(i),SEND_VALUE);//we'll create a blank address and add send value
    fundMe.fund{value: SEND_VALUE}();
    }

    //(ACT PHASE)->>we need the starting owner balance now for each
    uint256 startingOwnerBalance = fundMe.getOwner().balance;
    uint256 startingFundMeBalance = address(fundMe).balance;
    
    vm.startPrank(fundMe.getOwner());
    fundMe.withdraw();
    vm.stopPrank();

    //ASSERT PHASE-->> 
    assert(address(fundMe).balance == 0);//we should have removed all the funds of the fund me
    assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance);
    }

    function testWithdrawFromMultipleFundersCheaper() public funded{
    //it's gonna be funded once by our modifier but let's add a ton more funders
    //for addresses we must explicitly do uint 160
    uint160 numberOfFunders = 10;
    //the 0th address sometimes reverts so start with one
    uint160 startingFunderIndex = 1;
    
    //we'll use a loop and create new funders
    for(uint160 i=startingFunderIndex; i<numberOfFunders; i++){
    //we'll use a vm prank and vm deals and create addresses to fund the fund me
    //the hoax cheatcode does both prank and deal combined and we can use that
    hoax (address(i),SEND_VALUE);//we'll create a blank address and add send value
    fundMe.fund{value: SEND_VALUE}();
    }

    //(ACT PHASE)->>we need the starting owner balance now for each
    uint256 startingOwnerBalance = fundMe.getOwner().balance;
    uint256 startingFundMeBalance = address(fundMe).balance;
    
    vm.startPrank(fundMe.getOwner());
    fundMe.cheaperWithdraw();
    vm.stopPrank();

    //ASSERT PHASE-->> 
    assert(address(fundMe).balance == 0);//we should have removed all the funds of the fund me
    assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance);

    }
}
