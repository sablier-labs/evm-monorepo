// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import { ISablierV2Linear } from "@sablier/v2-core/interfaces/ISablierV2Linear.sol";

import { stdError } from "forge-std/stdlib.sol";

import { SablierV2LinearUnitTest } from "../../SablierV2LinearUnitTest.t.sol";

contract SablierV2Linear__CreateWithDuration__UnitTest is SablierV2LinearUnitTest {
    /// @dev When the duration calculation overflows uint256, it should revert.
    function testCannotCreateWithDuration__DurationCalculationOverflow() external {
        vm.expectRevert(stdError.arithmeticError);
        uint256 duration = type(uint256).max - linearStream.startTime + 1;
        sablierV2Linear.createWithDuration(
            linearStream.sender,
            linearStream.recipient,
            linearStream.depositAmount,
            linearStream.token,
            duration,
            linearStream.cancelable
        );
    }

    /// @dev When all checks pass, it should create the linear stream with duration.
    function testCreateWithDuration() external {
        uint256 streamId = sablierV2Linear.nextStreamId();
        sablierV2Linear.createWithDuration(
            linearStream.sender,
            linearStream.recipient,
            linearStream.depositAmount,
            linearStream.token,
            DEFAULT_TOTAL_DURATION,
            linearStream.cancelable
        );
        ISablierV2Linear.LinearStream memory createdLinearStream = sablierV2Linear.getLinearStream(streamId);
        assertEq(linearStream, createdLinearStream);
    }
}
