// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { E, UD2x18 } from "@prb/math/UD2x18.sol";
import { UD60x18, ZERO } from "@prb/math/UD60x18.sol";
import { Solarray } from "solarray/Solarray.sol";

import { Broker, Segment } from "src/types/Structs.sol";

import { ProTest } from "../ProTest.t.sol";

contract GetWithdrawableAmount_ProTest is ProTest {
    uint256 internal defaultStreamId;
    Segment[] internal maxSegments;

    /// @dev it should return zero.
    function test_GetWithdrawableAmount_StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        uint128 actualWithdrawableAmount = pro.getWithdrawableAmount(nonStreamId);
        uint128 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    modifier streamExistent() {
        // Create the default stream.
        defaultStreamId = createDefaultStream();
        _;
    }

    /// @dev it should return zero.
    function test_GetWithdrawableAmount_StartTimeGreaterThanCurrentTime() external streamExistent {
        vm.warp({ timestamp: 0 });
        uint128 actualWithdrawableAmount = pro.getWithdrawableAmount(defaultStreamId);
        uint128 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    /// @dev it should return zero.
    function test_GetWithdrawableAmount_StartTimeEqualToCurrentTime() external streamExistent {
        vm.warp({ timestamp: DEFAULT_START_TIME });
        uint128 actualWithdrawableAmount = pro.getWithdrawableAmount(defaultStreamId);
        uint128 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    modifier startTimeLessThanCurrentTime() {
        _;
    }

    /// @dev it should return the deposit amount.
    ///
    /// The fuzzing ensures that all of the following scenarios are tested:
    ///
    /// - Current time > stop time
    /// - Current time = stop time
    function testFuzz_GetWithdrawableAmount_CurrentTimeGreaterThanOrEqualToStopTime_NoWithdrawals(
        uint256 timeWarp
    ) external streamExistent startTimeLessThanCurrentTime {
        timeWarp = bound(timeWarp, 0 seconds, DEFAULT_TOTAL_DURATION);

        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_STOP_TIME + timeWarp });

        // Run the test.
        uint128 actualWithdrawableAmount = pro.getWithdrawableAmount(defaultStreamId);
        uint128 expectedWithdrawableAmount = DEFAULT_NET_DEPOSIT_AMOUNT;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    /// @dev it should return the deposit amount minus the withdrawn amount.
    ///
    /// The fuzzing ensures that all of the following scenarios are tested:
    ///
    /// - Current time > stop time
    /// - Current time = stop time
    /// - Withdraw amount equal to deposit amount and not
    function testFuzz_GetWithdrawableAmount_CurrentTimeGreaterThanOrEqualToStopTime_WithWithdrawals(
        uint256 timeWarp,
        uint128 withdrawAmount
    ) external streamExistent startTimeLessThanCurrentTime {
        timeWarp = bound(timeWarp, 0 seconds, DEFAULT_TOTAL_DURATION);
        withdrawAmount = boundUint128(withdrawAmount, 1, DEFAULT_NET_DEPOSIT_AMOUNT);

        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_STOP_TIME + timeWarp });

        // Withdraw the amount.
        pro.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: withdrawAmount });

        // Run the test.
        uint128 actualWithdrawableAmount = pro.getWithdrawableAmount(defaultStreamId);
        uint128 expectedWithdrawableAmount = DEFAULT_NET_DEPOSIT_AMOUNT - withdrawAmount;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    modifier currentTimeLessThanStopTime() {
        // Disable the protocol fee so that it doesn't interfere with the calculations.
        changePrank(users.admin);
        comptroller.setProtocolFee(dai, ZERO);
        changePrank(users.sender);
        _;
    }

    /// @dev it should return the correct withdrawable amount.
    function testFuzz_GetWithdrawableAmount_WithWithdrawals(
        uint40 timeWarp,
        uint128 withdrawAmount
    ) external streamExistent startTimeLessThanCurrentTime currentTimeLessThanStopTime {
        timeWarp = boundUint40(timeWarp, DEFAULT_CLIFF_DURATION, DEFAULT_TOTAL_DURATION - 1);

        // Bound the withdraw amount.
        uint40 currentTime = DEFAULT_START_TIME + timeWarp;
        uint128 initialWithdrawableAmount = calculateStreamedAmountForMultipleSegments(currentTime, DEFAULT_SEGMENTS);
        withdrawAmount = boundUint128(withdrawAmount, 1, initialWithdrawableAmount);

        // Create the stream with a custom gross deposit amount. The broker fee is disabled so that it doesn't interfere
        // with the calculations.
        uint256 streamId = pro.createWithMilestones(
            params.createWithMilestones.sender,
            params.createWithMilestones.recipient,
            DEFAULT_NET_DEPOSIT_AMOUNT,
            params.createWithMilestones.segments,
            params.createWithMilestones.token,
            params.createWithMilestones.cancelable,
            params.createWithMilestones.startTime,
            Broker({ addr: address(0), fee: ZERO })
        );

        // Warp into the future.
        vm.warp({ timestamp: currentTime });

        // Make the withdrawal.
        pro.withdraw({ streamId: streamId, to: users.recipient, amount: withdrawAmount });

        // Run the test.
        uint128 actualWithdrawableAmount = pro.getWithdrawableAmount(streamId);
        uint128 expectedWithdrawableAmount = initialWithdrawableAmount - withdrawAmount;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    modifier noWithdrawals() {
        _;
    }

    /// @dev it should return the correct withdrawable amount.
    function testFuzz_GetWithdrawableAmount_OneSegment(
        uint40 timeWarp
    ) external streamExistent startTimeLessThanCurrentTime currentTimeLessThanStopTime noWithdrawals {
        timeWarp = boundUint40(timeWarp, DEFAULT_CLIFF_DURATION, DEFAULT_TOTAL_DURATION - 1);

        // Create a single-element segment array.
        uint128 depositAmount = DEFAULT_SEGMENTS[0].amount + DEFAULT_SEGMENTS[1].amount;
        Segment[] memory segments = new Segment[](1);
        segments[0] = Segment({
            amount: depositAmount,
            exponent: DEFAULT_SEGMENTS[1].exponent,
            milestone: DEFAULT_STOP_TIME
        });

        // Create the stream wit the one-segment arrays. The broker fee is disabled so that it doesn't interfere
        // with the calculations.
        uint256 streamId = pro.createWithMilestones(
            params.createWithMilestones.sender,
            params.createWithMilestones.recipient,
            depositAmount,
            segments,
            params.createWithMilestones.token,
            params.createWithMilestones.cancelable,
            params.createWithMilestones.startTime,
            Broker({ addr: address(0), fee: ZERO })
        );

        // Warp into the future.
        uint40 currentTime = DEFAULT_START_TIME + timeWarp;
        vm.warp({ timestamp: currentTime });

        // Run the test.
        uint128 actualWithdrawableAmount = pro.getWithdrawableAmount(streamId);
        uint128 expectedWithdrawableAmount = calculateStreamedAmountForOneSegment(
            currentTime,
            segments[0].exponent,
            depositAmount
        );
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    modifier multipleSegments() {
        unchecked {
            uint128 amount = DEFAULT_NET_DEPOSIT_AMOUNT / uint128(DEFAULT_MAX_SEGMENT_COUNT);
            UD2x18 exponent = E;
            uint40 duration = DEFAULT_TOTAL_DURATION / uint40(DEFAULT_MAX_SEGMENT_COUNT);

            // Generate a bunch of segments that each has the same amount, same exponent, and with milestones
            // evenly spread apart.
            for (uint40 i = 0; i < DEFAULT_MAX_SEGMENT_COUNT; i += 1) {
                maxSegments.push(
                    Segment({ amount: amount, exponent: exponent, milestone: DEFAULT_START_TIME + duration * (i + 1) })
                );
            }
        }
        _;
    }

    /// @dev it should return the correct withdrawable amount.
    function test_GetWithdrawableAmount_CurrentMilestone1st()
        external
        streamExistent
        currentTimeLessThanStopTime
        noWithdrawals
        multipleSegments
    {
        // Create the stream with the multiple-segment arrays. The broker fee is disabled so that it doesn't interfere
        // with the calculations.
        uint256 streamId = pro.createWithMilestones(
            params.createWithMilestones.sender,
            params.createWithMilestones.recipient,
            DEFAULT_NET_DEPOSIT_AMOUNT,
            maxSegments,
            params.createWithMilestones.token,
            params.createWithMilestones.cancelable,
            params.createWithMilestones.startTime,
            Broker({ addr: address(0), fee: ZERO })
        );

        // Run the test.
        uint128 actualWithdrawableAmount = pro.getWithdrawableAmount(streamId);
        uint128 expectedWithdrawableAmount = calculateStreamedAmountForMultipleSegments(
            uint40(block.timestamp),
            maxSegments
        );
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    modifier currentMilestoneNot1st() {
        _;
    }

    /// @dev it should return the correct withdrawable amount.
    function testFuzz_GetWithdrawableAmount_CurrentMilestoneNot1st(
        uint40 timeWarp
    ) external streamExistent currentTimeLessThanStopTime noWithdrawals multipleSegments currentMilestoneNot1st {
        timeWarp = boundUint40(timeWarp, maxSegments[0].milestone, DEFAULT_TOTAL_DURATION - 1);

        // Create the stream with the multiple-segment arrays. The broker fee is disabled so that it doesn't interfere
        // with the calculations.
        uint256 streamId = pro.createWithMilestones(
            params.createWithMilestones.sender,
            params.createWithMilestones.recipient,
            DEFAULT_NET_DEPOSIT_AMOUNT,
            maxSegments,
            params.createWithMilestones.token,
            params.createWithMilestones.cancelable,
            params.createWithMilestones.startTime,
            Broker({ addr: address(0), fee: ZERO })
        );

        // Warp into the future.
        uint40 currentTime = DEFAULT_START_TIME + timeWarp;
        vm.warp({ timestamp: currentTime });

        // Run the test.
        uint128 actualWithdrawableAmount = pro.getWithdrawableAmount(streamId);
        uint128 expectedWithdrawableAmount = calculateStreamedAmountForMultipleSegments(currentTime, maxSegments);
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }
}
