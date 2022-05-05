// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ISablierV2 } from "@sablier/v2-core/interfaces/ISablierV2.sol";

import { stdError } from "forge-std/Test.sol";

import { AbstractSablierV2UnitTest } from "../AbstractSablierV2UnitTest.t.sol";

contract AbstractSablierV2__DecreaseAuthorization__UnitTest is AbstractSablierV2UnitTest {
    /// @dev When the new authorization amount calculation underflows uint256, it should revert.
    function testCannotDecreaseAuthorization__Underflow() external {
        vm.expectRevert(stdError.arithmeticError);
        abstractSablierV2.decreaseAuthorization(users.funder, 1);
    }

    /// @dev When all checks pass, it should increase the authorization.
    function testDecreaseAuthorization() external {
        uint256 authorization = DEFAULT_DEPOSIT_AMOUNT;
        abstractSablierV2.increaseAuthorization(users.funder, authorization);
        abstractSablierV2.decreaseAuthorization(users.funder, authorization);
        uint256 expectedAuthorization = 0;
        uint256 actualAuthorization = abstractSablierV2.getAuthorization(users.sender, users.funder);
        assertEq(expectedAuthorization, actualAuthorization);
    }

    /// @dev When all checks pass, it should emit an Authorize event.
    function testDecreaseAuthorization__Event() external {
        uint256 authorization = DEFAULT_DEPOSIT_AMOUNT;
        abstractSablierV2.increaseAuthorization(users.funder, authorization);
        vm.expectEmit(true, true, false, true);
        emit Authorize(users.sender, users.funder, 0);
        abstractSablierV2.decreaseAuthorization(users.funder, authorization);
    }
}
