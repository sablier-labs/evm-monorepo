// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ISablierV2 } from "@sablier/v2-core/interfaces/ISablierV2.sol";

import { stdError } from "forge-std/Test.sol";

import { AbstractSablierV2UnitTest } from "../AbstractSablierV2UnitTest.t.sol";

contract AbstractSablierV2__IncreaseAuthorization__UnitTest is AbstractSablierV2UnitTest {
    /// @dev When the new authorization amount calculation overflows uint256, it should revert.
    function testCannotIncreaseAuthorization__Overflow() external {
        abstractSablierV2.increaseAuthorization(users.funder, 1);
        vm.expectRevert(stdError.arithmeticError);
        abstractSablierV2.increaseAuthorization(users.funder, type(uint256).max);
    }

    /// @dev When the sender is the zero address, it should revert.
    function testCannotIncreaseAuthorization__SenderZeroAddress() external {
        // Make the zero address the `msg.sender` in this test case.
        vm.stopPrank();
        vm.startPrank(address(0));

        vm.expectRevert(ISablierV2.SablierV2__AuthorizeSenderZeroAddress.selector);
        uint256 authorization = DEFAULT_DEPOSIT_AMOUNT;
        abstractSablierV2.increaseAuthorization(users.funder, authorization);
    }

    /// @dev When the funder is the zero address, it should revert.
    function testCannotIncreaseAuthorization__FunderZeroAddress() external {
        vm.expectRevert(ISablierV2.SablierV2__AuthorizeFunderZeroAddress.selector);
        address funder = address(0);
        uint256 authorization = DEFAULT_DEPOSIT_AMOUNT;
        abstractSablierV2.increaseAuthorization(funder, authorization);
    }

    /// @dev When all checks pass, it should increase the authorization.
    function testIncreaseAuthorization() external {
        uint256 authorization = DEFAULT_DEPOSIT_AMOUNT;
        abstractSablierV2.increaseAuthorization(users.funder, authorization);
        uint256 expectedAuthorization = DEFAULT_DEPOSIT_AMOUNT;
        uint256 actualAuthorization = abstractSablierV2.getAuthorization(users.sender, users.funder);
        assertEq(expectedAuthorization, actualAuthorization);
    }

    /// @dev When all checks pass, it should emit an Authorize event.
    function testIncreaseAuthorization__Event() external {
        vm.expectEmit(true, true, false, true);
        uint256 authorization = DEFAULT_DEPOSIT_AMOUNT;
        emit Authorize(users.sender, users.funder, authorization);
        abstractSablierV2.increaseAuthorization(users.funder, authorization);
    }
}
