// SPDX-License-Identifier: MIT

pragma solidity ^0.8.28;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant INITIAL_BALANCE = 10 ether;

    function setUp() external {
        DeployFundMe deployer = new DeployFundMe();
        fundMe = deployer.run();
        vm.deal(USER, INITIAL_BALANCE);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testMinimumDollarIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMessageSender() public  view {
        assertEq(fundMe.getOwner(), msg.sender); // because we're getting the contract from the deploy, and it does a broadcast we can use now msg.sender insteda of address(this)
    }

    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughEth() public {
        vm.expectRevert(); // the next transaction should revert.
        fundMe.fund();
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER); // the next transaction will be sent by the user
        fundMe.fund{value: SEND_VALUE}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE); 
    }

    function testFunderAddedToFundersArray() public funded {
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    function testCanChangePriceFeed() public {
        address someAddress = makeAddr("newPriceFeed");
        vm.prank(fundMe.getOwner());
        fundMe.changePriceFeed(someAddress);
        assertEq(fundMe.getPriceFeed(), someAddress);
    }

    function testOnlyOWnerCanChangePriceFeed() public {
        address someAddress = makeAddr("newPriceFeed");
        vm.expectRevert();
        vm.prank(USER);
        fundMe.changePriceFeed(someAddress);
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw();
    }

    function testCanWithdraw() public funded {
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;

        assertEq(endingFundMeBalance, 0);
        assertEq(endingOwnerBalance, startingFundMeBalance + startingOwnerBalance);
    }

    function testCanWithdrawFromMultipleFunders() public funded {
        uint160 qtyFunders = 10;
        uint160 startingIndex = 1;

        for(uint160 index = startingIndex; index < qtyFunders; index++) {
            hoax(address(index), SEND_VALUE); // you can generate an address from uint160 values because they have the same amount of bytes. Also hoax does prank and deal at the same time.
            fundMe.fund{value: SEND_VALUE}(); 
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;

        assertEq(endingFundMeBalance, 0);
        assertEq(endingOwnerBalance, startingFundMeBalance + startingOwnerBalance);
    }

    function testReceiveFunction() public {
        uint256 fundAmount = 1 ether;
        vm.prank(USER);

        (bool sent, ) = address(fundMe).call{value: fundAmount}("");
        assertTrue(sent, "Funds transfer failed");
    }

    function testReceiveFunctionFails() public {
        (bool sent, ) = address(fundMe).call("");
        assertFalse(sent, "Funds transfer succeeded.");
    }

    function testFallbackWithData() public {
        bytes memory nonExistentFunctionSigned = abi.encodeWithSignature("nonExistentFunction()");
        
        vm.prank(USER);
        (bool success, ) = address(fundMe).call{value: 1 ether}(nonExistentFunctionSigned);
        assertTrue(success, "Funds transfer failed");
    }

    function testFallbackFailsWithoutEnoughEth() public {
        bytes memory nonExistentFunctionSigned = abi.encodeWithSignature("nonExistentFunction()");
        
        vm.prank(USER);
        (bool success, ) = address(fundMe).call(nonExistentFunctionSigned);
        assertFalse(success, "Funds transfer succeeded");
    }
}