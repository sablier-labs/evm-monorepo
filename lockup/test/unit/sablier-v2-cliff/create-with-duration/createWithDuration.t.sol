// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import { ISablierV2Cliff } from "@sablier/v2-core/interfaces/ISablierV2Cliff.sol";

import { stdError } from "forge-std/stdlib.sol";

import { SablierV2CliffUnitTest } from "../../SablierV2CliffUnitTest.t.sol";

contract SablierV2Cliff__CreateWithDuration__UnitTest is SablierV2CliffUnitTest {
    /// @dev When the duration calculation overflows uint256, it should revert.
    function testCannotCreateWithDuration__DurationCalculationOverflow() external {
        vm.expectRevert(stdError.arithmeticError);
        uint256 duration = type(uint256).max - cliffStream.startTime + 1;
        sablierV2Cliff.createWithDuration(
            cliffStream.sender,
            cliffStream.recipient,
            cliffStream.depositAmount,
            cliffStream.token,
            duration,
            DEFAULT_CLIFF_DURATION,
            cliffStream.cancelable
        );
    }

    /// @dev When all checks pass, it should create the linear stream with duration.
    function testCreateWithDuration() external {
        uint256 streamId = sablierV2Cliff.nextStreamId();
        sablierV2Cliff.createWithDuration(
            cliffStream.sender,
            cliffStream.recipient,
            cliffStream.depositAmount,
            cliffStream.token,
            DEFAULT_DURATION,
            DEFAULT_CLIFF_DURATION,
            cliffStream.cancelable
        );
        ISablierV2Cliff.CliffStream memory createdCliffStream = sablierV2Cliff.getCliffStream(streamId);
        assertEq(cliffStream, createdCliffStream);
    }
}
