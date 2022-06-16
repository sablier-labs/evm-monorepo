// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ISablierV2Linear } from "@sablier/v2-core/interfaces/ISablierV2Linear.sol";

import { stdError } from "forge-std/Test.sol";

import { SablierV2LinearUnitTest } from "../SablierV2LinearUnitTest.t.sol";

contract SablierV2Linear__UnitTest__CreateWithDuration is SablierV2LinearUnitTest {
    /// @dev When the total duration calculation overflows uint256, it should revert.
    function testCannotCreateWithDuration__TotalDurationCalculationOverflow() external {
        vm.expectRevert(stdError.arithmeticError);
        uint256 duration = type(uint256).max - stream.startTime + 1;
        sablierV2Linear.createWithDuration(
            stream.sender,
            stream.recipient,
            stream.depositAmount,
            stream.token,
            duration,
            stream.cancelable
        );
    }

    /// @dev When all checks pass, it should create the stream with duration.
    function testCreateWithDuration() external {
        uint256 streamId = sablierV2Linear.createWithDuration(
            stream.sender,
            stream.recipient,
            stream.depositAmount,
            stream.token,
            TOTAL_DURATION,
            stream.cancelable
        );
        ISablierV2Linear.Stream memory createdStream = sablierV2Linear.getStream(streamId);
        assertEq(stream, createdStream);
    }
}
