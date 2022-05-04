// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import { ISablierV2Linear } from "@sablier/v2-core/interfaces/ISablierV2Linear.sol";

import { stdError } from "forge-std/stdlib.sol";

import { SablierV2LinearUnitTest } from "../SablierV2LinearUnitTest.t.sol";

contract SablierV2Linear__CreateWithDuration__UnitTest is SablierV2LinearUnitTest {
    /// @dev When the duration calculation overflows uint256, it should revert.
    function testCannotCreateWithDuration__DurationCalculationOverflow() external {
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
        uint256 streamId = sablierV2Linear.nextStreamId();
        sablierV2Linear.createWithDuration(
            stream.sender,
            stream.recipient,
            stream.depositAmount,
            stream.token,
            DEFAULT_TOTAL_DURATION,
            stream.cancelable
        );
        ISablierV2Linear.Stream memory createdStream = sablierV2Linear.getStream(streamId);
        assertEq(stream, createdStream);
    }
}
