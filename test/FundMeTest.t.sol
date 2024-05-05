//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("user");
    /* this is to test easier by making this a constant address but will have not balance so need to
    make the address have ether to do so have to run it in the setUp*/
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;

    //uint256 constant GAS_PRICE = 1;

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinimumDollarIsFive() public {
        assertEq(fundMe.MINIMUM_USD(), 5 * 10 ** 18);
    }

    /*function testOwnerIsMsgSender() public {
        console.log(fundMe.i_owner());
        console.log(msg.sender);
        assertEq(fundMe.i_owner(), address(this));
        assertEq(
            fundMe.i_owner() != msg.sender,
            revert(fundMe.FundMe__NotOwner())
        );*/

    /*function testOwnerIsMsgSender() public {
        console.log(fundMe.i_owner());
        console.log(msg.sender);
        assertEq(fundMe.i_owner(), address(this));

        // Call a function using the onlyOwner modifier with a non-owner address
        address notOwner = address(0x1234567890123456789012345678901234567890); // Example address
        revert(fundMe.callOwnerOnlyFunction{value: 0}(notOwner)); // Example function call
    }*/

    /*function testOwnerIsMsgSender() public {
        console.log(fundMe.i_owner());
        console.log(msg.sender);
        assertEq(fundMe.i_owner(), address(this));

        // Call the withdraw function with a non-owner address
        address notOwner = address(0x1234567890123456789012345678901234567890);
        revert(fundMe.withdraw{value: 0}(notOwner));
    }*/

    /* function testOwnerIsMsgSender() public {
        console.log(fundMe.i_owner());
        console.log(msg.sender);
        assertEq(fundMe.i_owner(), address(this));

        // Call the withdraw function, expecting a revert
        revert(fundMe.withdraw()); // Call without value or arguments
    }*/

    function testOwnerIsMsgSender() public {
        //console.log(fundMe.getOwner()); not needed but good for debugging
        //console.log(msg.sender); not needed but good for debugging
        assertEq(fundMe.getOwner(), msg.sender);
    }

    // function testWithdraw() public {
    //     // Call the withdraw function directly, expecting a revert
    //     fundMe.withdraw(); // Call without value or arguments
    // }

    function testPriceFeedIsAc() public {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4); // why is it 4?
    }

    function testFundFailsWithoutEnoughEth() public {
        vm.expectRevert(); // the next line, should revert
        // assert(this tx fails/reverts)
        fundMe.fund(); //send 0 value
    }

    function testFundUpdatesFundDataStructure() public {
        vm.prank(USER); // the next TX will be sent from USER
        fundMe.fund{value: SEND_VALUE}();

        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();

        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        /*vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();*/ //not needed as it is already funded in the modifier

        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw();
    }

    function testWithdrawASingleFunder() public funded {
        // Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        //uint256 gasStart = gasleft(); = 1000
        //vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner()); // = c: 200
        fundMe.withdraw();

        //uint256 gasEnd = gasleft(); therefore = 800
        //uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;

        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            endingOwnerBalance,
            startingOwnerBalance + startingFundMeBalance
        );
    }

    function testWithdrawFromManyFunders() public funded {
        uint160 numberOfFunders = 10; // if you are wanting to create an address from numbers it needs to be a uint160 as is the same bitsize
        uint160 startingFundingIndex = 1; // 0 can revert and dosnt let you do stuff with it
        for (uint160 i = startingFundingIndex; i < numberOfFunders; i++) {
            //vm.prank new address
            //vm.deal new address
            //address()
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        // Assert
        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
    }
}
