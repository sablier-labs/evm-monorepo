// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ISablierV2 } from "@sablier/v2-core/interfaces/ISablierV2.sol";

import { stdError } from "forge-std/Test.sol";

import { AbstractSablierV2UnitTest } from "../AbstractSablierV2UnitTest.t.sol";

contract AbstractSablierV2__UnitTest__DecreaseAuthorization is AbstractSablierV2UnitTest {
    /// @dev When the calculation underflows uint256, it should revert.
    function testCannotDecreaseAuthorization__Underflow() external {
        vm.expectRevert(stdError.arithmeticError);
        uint256 amount = 1;
        abstractSablierV2.decreaseAuthorization(users.funder, usd, amount);
    }

    /// @dev When the authorization is decreased entirely, it should set the authorization to zero.
    function testDecreaseAuthorization__DecreaseEntirely() external {
        // Increase the authorization.
        uint256 authorization = DEPOSIT_AMOUNT;
        abstractSablierV2.increaseAuthorization(users.funder, usd, authorization);

        // Run the test.
        abstractSablierV2.decreaseAuthorization(users.funder, usd, authorization);
        uint256 actualAuthorization = abstractSablierV2.getAuthorization(users.sender, users.funder, usd);
        uint256 expectedAuthorization = 0;
        assertEq(actualAuthorization, expectedAuthorization);
    }

    /// @dev When the authorization is decreased partially, it should emit an Authorize event.
    function testDecreaseAuthorization__DecreasePartially(uint256 firstAmount, uint256 secondAmount) external {
        // Bound the first authorization to be greater than the second authorization.
        vm.assume(firstAmount > secondAmount);
        abstractSablierV2.increaseAuthorization(users.funder, usd, firstAmount);

        // Run the test.
        abstractSablierV2.decreaseAuthorization(users.funder, usd, secondAmount);
        uint256 actualAuthorization = abstractSablierV2.getAuthorization(users.sender, users.funder, usd);
        uint256 expectedAuthorization = firstAmount - secondAmount;
        assertEq(actualAuthorization, expectedAuthorization);
    }

    /// @dev When the authorization is decreased partially, it should emit an Authorize event.
    function testDecreaseAuthorization__DecreasePartially__Event(uint256 firstAmount, uint256 secondAmount) external {
        // Bound the first authorization to be greater than the second authorization.
        vm.assume(firstAmount > secondAmount);
        abstractSablierV2.increaseAuthorization(users.funder, usd, firstAmount);

        // Run the test.
        vm.expectEmit(true, true, false, true);
        uint256 authorization = firstAmount - secondAmount;
        emit Authorize(users.sender, users.funder, authorization);
        abstractSablierV2.decreaseAuthorization(users.funder, usd, secondAmount);
    }
}
