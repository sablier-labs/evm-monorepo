// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ISablierV2Cliff } from "@sablier/v2-core/interfaces/ISablierV2Cliff.sol";

import { stdError } from "forge-std/Test.sol";

import { SablierV2CliffUnitTest } from "../SablierV2CliffUnitTest.t.sol";

contract SablierV2Cliff__CreateWithDuration__UnitTest is SablierV2CliffUnitTest {
    /// @dev When the cliff duration calculation overflows uint256, it should revert.
    function testCannotCreateWithDuration__CliffDurationCalculationOverflow() external {
        vm.expectRevert(stdError.arithmeticError);
        uint256 cliffDuration = type(uint256).max - stream.startTime + 1;
        sablierV2Cliff.createWithDuration(
            stream.sender,
            stream.recipient,
            stream.depositAmount,
            stream.token,
            cliffDuration,
            TOTAL_DURATION,
            stream.cancelable
        );
    }

    /// @dev When the total duration calculation overflows uint256, it should revert.
    function testCannotCreateWithDuration__TotalDurationCalculationOverflow() external {
        vm.expectRevert(stdError.arithmeticError);
        uint256 totalDuration = type(uint256).max - stream.startTime + 1;
        sablierV2Cliff.createWithDuration(
            stream.sender,
            stream.recipient,
            stream.depositAmount,
            stream.token,
            CLIFF_DURATION,
            totalDuration,
            stream.cancelable
        );
    }

    /// @dev When all checks pass, it should create the stream with duration.
    function testCreateWithDuration() external {
        uint256 streamId = sablierV2Cliff.nextStreamId();
        sablierV2Cliff.createWithDuration(
            stream.sender,
            stream.recipient,
            stream.depositAmount,
            stream.token,
            CLIFF_DURATION,
            TOTAL_DURATION,
            stream.cancelable
        );
        ISablierV2Cliff.Stream memory createdStream = sablierV2Cliff.getStream(streamId);
        assertEq(stream, createdStream);
    }
}
