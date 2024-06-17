// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundme;
    address private USER = makeAddr("user");
    uint256 private constant SEND_VALUE = 0.1 ether;
    uint256 private constant USER_BALANCE = 100 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        //fundme = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundme = deployFundMe.run();
        vm.deal(USER, USER_BALANCE);
    }

    function testMinimumDollarIsFive() public view {
        assertEq(fundme.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsSender() public view {
        console.log("Owner is ", fundme.getOwner());
        console.log("MSG SENDER ", msg.sender);
        console.log("THIS ADDRESS ", address(this));
        assertEq(fundme.getOwner(), msg.sender);
    }

    // What can we do to work with addresses outside our system?
    // 1. Unit
    //    - Testing a specific part of our code.
    // 2. Integration
    //    - Testing how our code works with other parts of our code.
    // 3. Forked
    //    - Testing our code on a simulated real environment.
    // 4. Staging
    //    - Testing our code in a real environment that is not prod.

    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundme.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert(); // hey the next line shoudl revert
        // assert(tx fails)
        //fundme.fund{value: 10e8}(); // send 0 value
        fundme.fund();
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER);
        fundme.fund{value: SEND_VALUE}();
        uint256 amountFunded = fundme.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    modifier funded() {
        vm.prank(USER);
        
        fundme.fund{value: SEND_VALUE}();
        _;
    }

    function testAddsFunderToArrayOfFunders() public funded {
        address funder = fundme.getFunders(0);
        assertEq(funder, USER);
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        vm.prank(USER);
        fundme.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        //Arrange
        uint256 startingOwnerBalance = fundme.getOwner().balance;
        uint256 startingFundmeBalance = address(fundme).balance;

        // Act
        vm.txGasPrice(GAS_PRICE);
        vm.prank(fundme.getOwner());
        fundme.withdraw();

        // Assert
        uint256 endingOwnerBalance = fundme.getOwner().balance;
        uint256 endingFundmeBalance = address(fundme).balance;

        assertEq(endingFundmeBalance, 0);
        assertEq(startingFundmeBalance + startingOwnerBalance, endingOwnerBalance);
    }

    function testWithdrawFromMultipleFunders() public funded {
        // Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 2;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE);
            fundme.fund{value: SEND_VALUE}();
        }
        uint256 startingOwnerBalance = fundme.getOwner().balance;
        uint256 startingFundmeBalance = address(fundme).balance;

        // Act
        vm.txGasPrice(GAS_PRICE);
        vm.startPrank(fundme.getOwner());
        fundme.withdraw();
        vm.stopPrank();

        // Assert
        assert(address(fundme).balance == 0);
        assert(startingFundmeBalance + startingOwnerBalance == fundme.getOwner().balance);
    }

    function testWithdrawCheaperFromMultipleFunders() public funded {
        // Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 2;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE);
            fundme.fund{value: SEND_VALUE}();
        }
        uint256 startingOwnerBalance = fundme.getOwner().balance;
        uint256 startingFundmeBalance = address(fundme).balance;

        // Act
        vm.txGasPrice(GAS_PRICE);
        vm.startPrank(fundme.getOwner());
        fundme.cheaperWithdraw();
        vm.stopPrank();

        // Assert
        assert(address(fundme).balance == 0);
        assert(startingFundmeBalance + startingOwnerBalance == fundme.getOwner().balance);
    }
}
