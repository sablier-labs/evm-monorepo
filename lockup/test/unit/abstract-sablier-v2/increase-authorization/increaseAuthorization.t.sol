// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ISablierV2 } from "@sablier/v2-core/interfaces/ISablierV2.sol";

import { stdError } from "forge-std/Test.sol";

import { AbstractSablierV2UnitTest } from "../AbstractSablierV2UnitTest.t.sol";

contract AbstractSablierV2__UnitTest__IncreaseAuthorization is AbstractSablierV2UnitTest {
    /// @dev When the calculation overflows uint256, it should revert.
    function testCannotIncreaseAuthorization__Overflow() external {
        abstractSablierV2.increaseAuthorization(users.funder, usd, 1);
        vm.expectRevert(stdError.arithmeticError);
        abstractSablierV2.increaseAuthorization(users.funder, usd, MAX_UINT_256);
    }

    /// @dev When the sender is the zero address, it should revert.
    function testCannotIncreaseAuthorization__SenderZeroAddress() external {
        // Make the zero address the `msg.sender` in this test case.
        changePrank(address(0));

        // Run the test.
        vm.expectRevert(ISablierV2.SablierV2__AuthorizeSenderZeroAddress.selector);
        uint256 authorization = DEPOSIT_AMOUNT;
        abstractSablierV2.increaseAuthorization(users.funder, usd, authorization);
    }

    /// @dev When the amount is zero, it should not increase the authorization.
    function testIncreaseAuthorization__AmountZero() external {
        uint256 authorization = 0;
        abstractSablierV2.increaseAuthorization(users.funder, usd, authorization);
        uint256 actualAuthorization = abstractSablierV2.getAuthorization(users.sender, users.funder, usd);
        uint256 expectedAuthorization = 0;
        assertEq(actualAuthorization, expectedAuthorization);
    }

    /// @dev When the current authorization is zero, it should not increase the authorization.
    function testIncreaseAuthorization__CurrentAuthorizationZero(uint256 authorization) external {
        abstractSablierV2.increaseAuthorization(users.funder, usd, authorization);
        uint256 actualAuthorization = abstractSablierV2.getAuthorization(users.sender, users.funder, usd);
        uint256 expectedAuthorization = authorization;
        assertEq(actualAuthorization, expectedAuthorization);
    }

    /// @dev When the current authorization is not zero, it should increase the authorization.
    function testIncreaseAuthorization__CurrentAuthorizationNonZero(uint256 firstAmount, uint256 secondAmount)
        external
    {
        // Bound the two inputs to max uint256.
        vm.assume(firstAmount <= MAX_UINT_256 - secondAmount);
        abstractSablierV2.increaseAuthorization(users.funder, usd, firstAmount);

        // Run the test.
        abstractSablierV2.increaseAuthorization(users.funder, usd, secondAmount);
        uint256 actualAuthorization = abstractSablierV2.getAuthorization(users.sender, users.funder, usd);
        uint256 expectedAuthorization = firstAmount + secondAmount;
        assertEq(actualAuthorization, expectedAuthorization);
    }

    /// @dev When the current authorization is not zero, it should emit an Authorize event.
    function testIncreaseAuthorization__CurrentAuthorizationNonZero__Event(uint256 firstAmount, uint256 secondAmount)
        external
    {
        // Bound the two inputs to max uint256.
        vm.assume(firstAmount <= MAX_UINT_256 - secondAmount);
        abstractSablierV2.increaseAuthorization(users.funder, usd, firstAmount);

        // Run the test.
        vm.expectEmit(true, true, false, true);
        uint256 authorization = firstAmount + secondAmount;
        emit Authorize(users.sender, users.funder, authorization);
        abstractSablierV2.increaseAuthorization(users.funder, usd, secondAmount);
    }
}
