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
    function test_GetWithdrawableAmount_StreamNull() external {
        uint256 nullStreamId = 1729;
        uint128 actualWithdrawableAmount = pro.getWithdrawableAmount(nullStreamId);
        uint128 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    modifier streamNonNull() {
        // Create the default stream.
        defaultStreamId = createDefaultStream();
        _;
    }

    /// @dev it should return zero.
    function test_GetWithdrawableAmount_StartTimeGreaterThanCurrentTime() external streamNonNull {
        vm.warp({ timestamp: 0 });
        uint128 actualWithdrawableAmount = pro.getWithdrawableAmount(defaultStreamId);
        uint128 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    /// @dev it should return zero.
    function test_GetWithdrawableAmount_StartTimeEqualToCurrentTime() external streamNonNull {
        vm.warp({ timestamp: DEFAULT_START_TIME });
        uint128 actualWithdrawableAmount = pro.getWithdrawableAmount(defaultStreamId);
        uint128 expectedWithdrawableAmount = 0;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    modifier startTimeLessThanCurrentTime() {
        // Disable the protocol fee so that it doesn't interfere with the calculations.
        changePrank(users.admin);
        comptroller.setProtocolFee(dai, ZERO);
        changePrank(users.sender);
        _;
    }

    /// @dev it should return the correct withdrawable amount.
    ///
    /// The fuzzing ensures that all of the following scenarios are tested:
    ///
    /// - Current time < stop time
    /// - Current time = stop time
    /// - Current time > stop time
    function testFuzz_GetWithdrawableAmount_WithoutWithdrawals(
        uint40 timeWarp
    ) external streamNonNull startTimeLessThanCurrentTime withWithdrawals {
        timeWarp = boundUint40(timeWarp, DEFAULT_CLIFF_DURATION, DEFAULT_TOTAL_DURATION * 2);

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
        uint40 currentTime = DEFAULT_START_TIME + timeWarp;
        vm.warp({ timestamp: currentTime });

        // Run the test.
        uint128 actualWithdrawableAmount = pro.getWithdrawableAmount(streamId);
        uint128 expectedWithdrawableAmount = calculateStreamedAmountForMultipleSegments(
            currentTime,
            DEFAULT_SEGMENTS,
            DEFAULT_NET_DEPOSIT_AMOUNT
        );
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }

    modifier withWithdrawals() {
        _;
    }

    /// @dev it should return the correct withdrawable amount.
    ///
    /// The fuzzing ensures that all of the following scenarios are tested:
    ///
    /// - Current time < stop time
    /// - Current time = stop time
    /// - Current time > stop time
    /// - Withdraw amount equal to deposit amount and not
    function testFuzz_GetWithdrawableAmount(
        uint40 timeWarp,
        uint128 withdrawAmount
    ) external streamNonNull startTimeLessThanCurrentTime withWithdrawals {
        timeWarp = boundUint40(timeWarp, DEFAULT_CLIFF_DURATION, DEFAULT_TOTAL_DURATION * 2);

        // Bound the withdraw amount.
        uint40 currentTime = DEFAULT_START_TIME + timeWarp;
        uint128 streamedAmount = calculateStreamedAmountForMultipleSegments(
            currentTime,
            DEFAULT_SEGMENTS,
            DEFAULT_NET_DEPOSIT_AMOUNT
        );
        withdrawAmount = boundUint128(withdrawAmount, 1, streamedAmount);

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
        uint128 expectedWithdrawableAmount = streamedAmount - withdrawAmount;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount);
    }
}
