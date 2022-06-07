// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { e, SD59x18 } from "@prb/math/SD59x18.sol";

import { SablierV2ProUnitTest } from "../SablierV2ProUnitTest.t.sol";

/// @dev Basic tests found in the SablierV2Linear and SablierV2Cliff contracts.
contract SablierV2Pro__GetWithdrawableAmount__BasicsUnitTest is SablierV2ProUnitTest {
    uint256 internal streamId;

    /// @dev A setup function invoked before each test case.
    function setUp() public override {
        super.setUp();

        // Create the default stream, all tests need it.
        streamId = createDefaultStream();
    }

    /// @dev When the stream does not exist, it should return zero.
    function testGetWithdrawableAmount__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        uint256 expectedWithdrawableAmount = 0;
        uint256 actualWithdrawableAmount = sablierV2Pro.getWithdrawableAmount(nonStreamId);
        assertEq(expectedWithdrawableAmount, actualWithdrawableAmount);
    }

    /// @dev When the start time is greater than the block timestamp, it should return zero.
    function testGetWithdrawableAmount__StartTimeGreaterThanBlockTimestamp() external {
        vm.warp(stream.startTime - 1 seconds);
        uint256 expectedWithdrawableAmount = 0;
        uint256 actualWithdrawableAmount = sablierV2Pro.getWithdrawableAmount(streamId);
        assertEq(expectedWithdrawableAmount, actualWithdrawableAmount);
    }

    /// @dev When the start time is equal to the block timestamp, it should return zero.
    function testGetWithdrawableAmount__StartTimeEqualToBlockTimestamp() external {
        uint256 expectedWithdrawableAmount = 0;
        uint256 withdrawableAmount = sablierV2Pro.getWithdrawableAmount(streamId);
        assertEq(expectedWithdrawableAmount, withdrawableAmount);
    }

    /// @dev When the current time is greater than the stop time and there have been withdrawals, it should
    /// return the deposit amount minus the withdrawn amount.
    function testGetWithdrawableAmount__CurrentTimeGreaterThanStopTime__WithWithdrawals() external {
        vm.warp(stream.stopTime + 1 seconds);
        uint256 withdrawAmount = bn(2_500);
        sablierV2Pro.withdraw(streamId, withdrawAmount);
        uint256 expectedWithdrawableAmount = stream.depositAmount - withdrawAmount;
        uint256 actualWithdrawableAmount = sablierV2Pro.getWithdrawableAmount(streamId);
        assertEq(expectedWithdrawableAmount, actualWithdrawableAmount);
    }

    /// @dev When the current time is greater than the stop time and there have been no withdrawals, it should
    /// return the deposit amount.
    function testGetWithdrawableAmount__CurrentTimeGreaterThanStopTime__NoWithdrawals() external {
        vm.warp(stream.stopTime + 1 seconds);
        uint256 expectedWithdrawableAmount = stream.depositAmount;
        uint256 actualWithdrawableAmount = sablierV2Pro.getWithdrawableAmount(streamId);
        assertEq(expectedWithdrawableAmount, actualWithdrawableAmount);
    }

    /// @dev When the current time is equal to the stop time and there have been withdrawals, it should
    /// return the deposit amount minus the withdrawn amount.
    function testGetWithdrawableAmount__CurrentTimeEqualToStopTime__WithWithdrawals() external {
        vm.warp(stream.stopTime);
        uint256 withdrawAmount = bn(2_500);
        sablierV2Pro.withdraw(streamId, withdrawAmount);
        uint256 expectedWithdrawableAmount = stream.depositAmount - withdrawAmount;
        uint256 actualWithdrawableAmount = sablierV2Pro.getWithdrawableAmount(streamId);
        assertEq(expectedWithdrawableAmount, actualWithdrawableAmount);
    }

    /// @dev When the current time is equal to the stop time and there have been no withdrawals, it should
    /// return the deposit amount.
    function testGetWithdrawableAmount__CurrentTimeEqualToStopTime__NoWithdrawals() external {
        vm.warp(stream.stopTime);
        uint256 expectedWithdrawableAmount = stream.depositAmount;
        uint256 actualWithdrawableAmount = sablierV2Pro.getWithdrawableAmount(streamId);
        assertEq(expectedWithdrawableAmount, actualWithdrawableAmount);
    }
}

/// @dev Wrapper contract for the case when the current time is less than the stop time.
contract SablierV2Pro__GetWithdrawableAmount__SegmentsUnitTest is SablierV2ProUnitTest {
    uint256 internal streamId;

    /// @dev A setup function invoked before each test case.
    function setUp() public override {
        super.setUp();

        // Create the default stream, most tests need it.
        streamId = createDefaultStream();
    }

    /// @dev When there have been withdrawals, it should return the correct withdrawable amount.
    function testGetWithdrawableAmount__WithWithdrawals() external {
        vm.warp(stream.startTime + 500 seconds); // 500 seconds is 25% of the way in the first segment.
        uint256 withdrawAmount = bn(5);
        sablierV2Pro.withdraw(streamId, withdrawAmount);
        uint256 expectedWithdrawableAmount = 25.73721928961166e18 - withdrawAmount; // 1st term: ~2,000*0.25^{3.14}
        uint256 actualWithdrawableAmount = sablierV2Pro.getWithdrawableAmount(streamId);
        assertEq(expectedWithdrawableAmount, actualWithdrawableAmount);
    }

    /// @dev When there is one segment and there haven't been withdrawals, it should return the correct withdrawable
    /// amount.
    function testGetWithdrawableAmount__OneSegment() external {
        uint256 depositAmount = SEGMENT_AMOUNTS[0] + SEGMENT_AMOUNTS[1];
        uint256[] memory segmentAmounts = createDynamicArray(depositAmount);
        SD59x18[] memory segmentExponents = createDynamicArray(SEGMENT_EXPONENTS[1]);
        uint256[] memory segmentMilestones = createDynamicArray(SEGMENT_MILESTONES[1]);

        streamId = sablierV2Pro.create(
            stream.sender,
            stream.recipient,
            depositAmount,
            stream.token,
            stream.startTime,
            segmentAmounts,
            segmentExponents,
            segmentMilestones,
            stream.cancelable
        );

        vm.warp(stream.startTime + 2_000 seconds); // 2,000 seconds is 20% of the stream duration.
        uint256 expectedWithdrawableAmount = 4472.13595499957941e18; // ~10,000*0.2^{0.5}
        uint256 actualWithdrawableAmount = sablierV2Pro.getWithdrawableAmount(streamId);
        assertEq(expectedWithdrawableAmount, actualWithdrawableAmount);
    }

    /// @dev When there are multiple segments and the current milestone is the 1st in the array,
    /// it should return the correct withdrawable amount.
    function testGetWithdrawableAmount__MultipleSegments__CurrentMilestone__1st() external {
        vm.warp(stream.startTime + 500 seconds); // 500 seconds is 25% of the way in the first segment.
        uint256 expectedWithdrawableAmount = 25.73721928961166e18; // ~2,000*0.25^{3.14}
        uint256 actualWithdrawableAmount = sablierV2Pro.getWithdrawableAmount(streamId);
        assertEq(expectedWithdrawableAmount, actualWithdrawableAmount);
    }

    /// @dev When there are multiple segments and the current milestone is the 2nd in the array,
    /// it should return the correct withdrawable amount.
    function testGetWithdrawableAmount__MultipleSegments__CurrentMilestone__2nd() external {
        vm.warp(stream.startTime + 2_800 seconds); // 2,800 seconds is 10% of the way in the second segment.
        uint256 expectedWithdrawableAmount = SEGMENT_AMOUNTS[0] + 2529.822128134703472e18; // 2nd term: ~8,000*0.1^{0.5}
        uint256 actualWithdrawableAmount = sablierV2Pro.getWithdrawableAmount(streamId);
        assertEq(expectedWithdrawableAmount, actualWithdrawableAmount);
    }

    /// @dev When there are multiple segments and the current milestone is the 200th in the array,
    /// it should return the correct withdrawable amount.
    function testGetWithdrawableAmount__MultipleSegments__CurrentMilestone__200th() external {
        uint256 count = sablierV2Pro.MAX_SEGMENT_ARRAY_LENGTH();
        uint256[] memory segmentAmounts = new uint256[](count);
        SD59x18[] memory segmentExponents = new SD59x18[](count);
        uint256[] memory segmentMilestones = new uint256[](count);

        unchecked {
            // Generate 200 segments that hold the same amount, same exponent and are evenly spread apart.
            uint256 segmentAmount = stream.depositAmount / count;
            SD59x18 segmentExponent = e();
            uint256 totalDuration = stream.stopTime - stream.startTime;
            uint256 segmentDuration = totalDuration / count;
            for (uint256 i = 0; i < count; ) {
                segmentAmounts[i] = segmentAmount;
                segmentExponents[i] = segmentExponent;
                segmentMilestones[i] = stream.startTime + segmentDuration * (i + 1);
                i += 1;
            }

            // Create the 200-segment stream.
            streamId = sablierV2Pro.create(
                stream.sender,
                stream.recipient,
                stream.depositAmount,
                stream.token,
                stream.startTime,
                segmentAmounts,
                segmentExponents,
                segmentMilestones,
                stream.cancelable
            );
            vm.warp(stream.stopTime - segmentDuration / 2);

            // The 3rd term is 50*0.5^e
            uint256 expectedWithdrawableAmount = segmentAmount * (count - 1) + 7.59776116289564825e18;
            uint256 actualWithdrawableAmount = sablierV2Pro.getWithdrawableAmount(streamId);
            assertEq(expectedWithdrawableAmount, actualWithdrawableAmount);
        }
    }
}
