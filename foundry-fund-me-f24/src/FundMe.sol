//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

//we can import the interface directly from the chainlinks github repo.
import{AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
//we can import our Price converter library in this contract.
import {PriceConverter} from "./PriceConverter.sol";

//we'll then create our custom error which will act in place of require functions.
error FundMe__NotOwner();

contract FundMe{
//to attach the functions in our price converter library to all uint256s
 using PriceConverter for uint256;

 //let's say we want users to spend 5 dollars as opposed to one whole ethereum.
uint256 public constant MINIMUM_USD = 5 * 1e18;
 
//we can as well make a mapping of adresses to see how much money each funder has sent
mapping (address funder => uint256 amountFunded) private s_addressToAmountFunded;
//we can also keep an array of funders and keep track of actually who sends us money
address[] private s_funders;

address private immutable i_owner;
AggregatorV3Interface private s_priceFeed;
//we can set up a constructor that whenever the contract is deployed the owner gets notified.
 constructor(address priceFeed){
    i_owner = msg.sender;
    s_priceFeed = AggregatorV3Interface(priceFeed);//allows work dynamically with different price feeds not having to hardcode addresses
 }
//let's say we have specific functions that should only be called by the owner

function fund() public payable {
  
 //we want this fn to allow users to send money and have a minimum $ sent.
 //the payable keyword makes the function able to accept blockchain
 require(msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,"Didn't Send Enough ETH");//require people to send at least 5usd
 s_funders.push(msg.sender);//updates who's the sender of a particular transaction
 //whatever they previously funded plus what they've added now.
 s_addressToAmountFunded[msg.sender] = s_addressToAmountFunded[msg.sender] + msg.value;
 }

 function getVersion() public view returns(uint256){
  return s_priceFeed.version();
 }
 
//we'll need a function to withdraw

//To avoid reading from storage every time we withdraw and save on gas we can create a new function
function cheaperWithdraw() public onlyOwner{
    uint256 fundersLength = s_funders.length;
    //this will allow us to only read it from storage one time
    for(uint256 funderIndex=0;
    funderIndex<fundersLength;/*(now a memory variable instead of storage variable)*/ funderIndex++){
        address funder = s_funders[funderIndex];
        s_addressToAmountFunded[funder] = 0;
    }
     s_funders = new address[](0);
     (bool callSuccess,)  = payable(msg.sender).call{value : address(this).balance}("");
     require(callSuccess, "Call failed");
}


function withdraw() public onlyOwner{
//when we withdraw all the money we'll need to set the mappings back to zero.
//we'll do this using a for loop.
for(uint256 funderIndex=0; funderIndex < s_funders.length; funderIndex++){
    address funder = s_funders[funderIndex];
    s_addressToAmountFunded[funder] = 0;
//the above for loop means we'll start at the 0th index and get the address of the funder at that index and reset the amount they sent to zero then move up to next index.
}
//now we'll need to reset the array 
s_funders = new address[](0);//new address array starting off at length of 0.
//to send ether and native blockchain they're actually 3 ways to do this

/*using transfer
payable(msg.sender).transfer(address(this).balance);//we'll type cast message from adress type to payable address type.

//using send since it returns bool
bool sendSuccess = payable(msg.sender).send(address(this).balance);
require(sendSuccess, "Send failed");*/

//using call command
(bool callSuccess,)  = payable(msg.sender).call{value : address(this).balance}("");
require(callSuccess, "Call failed");
//we only want the owner of the contract to be the only one able to withdraw the money no one else.

}
//we'll create a modifier 
  modifier onlyOwner(){
    //first we set only the owner of the contract to withdraw no one else
    /*require(msg.sender == i_owner,"Must be Owner!");
     _; */
      if(msg.sender != i_owner){revert FundMe__NotOwner();}
      _;
  }
  //if sb sends this contract ETH without calling the Fund function we can use fallbacks and receive functions
  //if sb accidentally sends money we can still process the transaction
  receive() external payable{
    //we'll just have this function call fund
    fund();
   }
  //we'll do the same thing with our fallback function
  fallback() external payable{
    //we'll have it call fund too
    fund();
  }
  //we can go ahead and create getters for this contract to be visible to othe contracts
  //(view/ pure functions(getters))
  function getAddressToAmountFunded(address fundingAddress)
       external view returns(uint256)
  {
       return s_addressToAmountFunded[fundingAddress];
  }
  
  //we can also do one for the funders
  function getFunder(uint256 index) 
  external view returns(address){
    return s_funders[index];
  }
  //Next is getter for get owner
  function getOwner() external view returns(address){
    return i_owner;
  }
}