// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {PriceConverter} from "./PriceConverter.sol";

error FundMe__NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    mapping(address => uint256) private s_addressToAmountFunded;
    address[] private s_funders;

    address private i_owner;
    address private priceFeed;
    uint256 public constant MINIMUM_USD = 5e18;

    constructor(address _priceFeed) {
        i_owner = msg.sender;
        priceFeed = _priceFeed;
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _;
    }

    function changePriceFeed(address _priceFeed) public onlyOwner {
        priceFeed = _priceFeed;
    }

    function getVersion() public view returns(uint256) {
        return PriceConverter.getVersion(priceFeed);
    }

    function fund() public payable {
        require(msg.value.getConversionRate(priceFeed) >= MINIMUM_USD, "Didn't send enough ETH");

        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        address funder;
        uint256 fundersLength = s_funders.length;
        for(uint256 fundersIndex = 0; fundersIndex < fundersLength; fundersIndex++) {
            funder = s_funders[fundersIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);

        /*
        * We can transfer funds using 3 different methods
        * transfer, send or call
        * 
        * transfer is limited to 2300 gas, throws an error if it runs out of gas.
        * if the transfer fails, throws an error reverting the transaction, which also reverts the arrays and mapping changes.
        * payable(msg.sender).transfer(address(this).balance); 
        * 
        * send returns a boolean, doesn't revert the transaction, you'll need to revert with require if needed.
        * bool sendSuccess = payable(msg.sender).send(address(this).balance);
        * require(sendSuccess, "Send Failed");
        * 
        * call is a lower level function used to call any function in the ethereum without even knowing the ABI.
        * Returns two variables a bool and a byte
        */

        (bool callSucess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSucess, "Call failed");
    }

    /*
    * When someone sends this contract ETH without calling fund function, it'll execute one of these two functions, receive or fallback
    * IF the calldata is blank and the receive function exists, it'll be executed
    * ELSE if the calldata is filed but the function is not found OR if the calldata is blank and there isn't a receive function.
    * THEN fallback will be executed.
    */
    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
    
    function getAddressToAmountFunded(address fundingAddress) external view returns(uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getFunder(uint256 index) external view returns(address) {
        return s_funders[index];
    }

    function getOwner() external view returns(address) {
        return i_owner;
    }

    function getPriceFeed() external view returns(address) {
        return priceFeed;
    }
   
}