// SPDX-License-Identifier: MIT
pragma solidity ^0.8.29;

import {PriceConverter} from "./PriceConverter.sol";

error NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;

    address public i_owner;
    uint256 public constant MINIMUM_USD = 5 * 10e18;

    constructor() {
        i_owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert NotOwner();
        }
        _;
    }

    function fund() public payable {
        require(msg.value.getConversionRate() >= MINIMUM_USD, "Didn't send enough ETH");

        funders.push(msg.sender);
        addressToAmountFunded[msg.sender] += msg.value;
    }

    function withdraw() public onlyOwner {
        address funder;
        /* for(uint256 fundersIndex = 0; fundersIndex < funders.length; fundersIndex++) {
            funder = funders[funderwsIndex];
            addressToAmountFunded[funder] = 0;
        } */
        addressToAmountFunded = mapping(address => uint256)();
        funders = new address[](0);

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
}