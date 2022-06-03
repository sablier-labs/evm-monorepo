// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ISablierV2 } from "@sablier/v2-core/interfaces/ISablierV2.sol";

import { stdError } from "forge-std/Test.sol";

import { AbstractSablierV2UnitTest } from "../AbstractSablierV2UnitTest.t.sol";

contract AbstractSablierV2__GetAuthorization__UnitTest is AbstractSablierV2UnitTest {
    /// @dev When the authorization is not set, it should return zero.
    function testGetAuthorization__AuthorizationNotSet() external {
        uint256 expectedAuthorization = 0;
        uint256 actualAuthorization = abstractSablierV2.getAuthorization(users.sender, users.funder);
        assertEq(expectedAuthorization, actualAuthorization);
    }

    /// @dev When the authorization is not set, it should return the correct authorization.
    function testGetAuthorization__AuthorizationSet() external {
        uint256 authorization = DEPOSIT_AMOUNT;
        abstractSablierV2.increaseAuthorization(users.funder, authorization);
        uint256 expectedAuthorization = authorization;
        uint256 actualAuthorization = abstractSablierV2.getAuthorization(users.sender, users.funder);
        assertEq(expectedAuthorization, actualAuthorization);
    }

    /// @dev When all checks pass, it should emit an Authorize event.
    function testDecreaseAuthorization__Event() external {
        uint256 amount = DEPOSIT_AMOUNT;
        abstractSablierV2.increaseAuthorization(users.funder, amount);
        vm.expectEmit(true, true, false, true);
        emit Authorize(users.sender, users.funder, 0);
        abstractSablierV2.decreaseAuthorization(users.funder, amount);
    }
}
