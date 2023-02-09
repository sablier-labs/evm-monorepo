// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.18 <0.9.0;

import { ZERO } from "@prb/math/UD60x18.sol";

import { Broker } from "src/types/DataTypes.sol";

import { Pro_Fuzz_Test } from "../Pro.t.sol";

contract WithdrawableAmountOf_Pro_Fuzz_Test is Pro_Fuzz_Test {
    uint256 internal defaultStreamId;

    modifier streamActive() {
        // Create the default stream.
        defaultStreamId = createDefaultStream();

        // Disable the protocol fee so that it doesn't interfere with the calculations.
        changePrank({ msgSender: users.admin });
        comptroller.setProtocolFee({ asset: DEFAULT_ASSET, newProtocolFee: ZERO });
        changePrank({ msgSender: users.sender });
        _;
    }

    modifier startTimeLessThanCurrentTime() {
        _;
    }

    /// @dev it should return the correct withdrawable amount.
    ///
    /// The fuzzing ensures that all of the following scenarios are tested:
    ///
    /// - Current time < end time
    /// - Current time = end time
    /// - Current time > end time
    function testFuzz_WithdrawableAmountOf_WithoutWithdrawals(
        uint40 timeWarp
    ) external streamActive startTimeLessThanCurrentTime {
        timeWarp = boundUint40(timeWarp, DEFAULT_CLIFF_DURATION, DEFAULT_TOTAL_DURATION * 2);

        // Warp into the future.
        uint40 currentTime = DEFAULT_START_TIME + timeWarp;
        vm.warp({ timestamp: currentTime });

        // Create the stream with a custom total amount. The broker fee is disabled so that it doesn't interfere with
        // the calculations.
        uint256 streamId = pro.createWithMilestones(
            defaultParams.createWithMilestones.sender,
            defaultParams.createWithMilestones.recipient,
            DEFAULT_DEPOSIT_AMOUNT,
            defaultParams.createWithMilestones.segments,
            defaultParams.createWithMilestones.asset,
            defaultParams.createWithMilestones.cancelable,
            defaultParams.createWithMilestones.startTime,
            Broker({ addr: address(0), fee: ZERO })
        );

        // Run the test.
        uint128 actualWithdrawableAmount = pro.withdrawableAmountOf(streamId);
        uint128 expectedWithdrawableAmount = calculateStreamedAmountForMultipleSegments(
            currentTime,
            DEFAULT_SEGMENTS,
            DEFAULT_DEPOSIT_AMOUNT
        );
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }

    modifier withWithdrawals() {
        _;
    }

    /// @dev it should return the correct withdrawable amount.
    ///
    /// The fuzzing ensures that all of the following scenarios are tested:
    ///
    /// - Current time < end time
    /// - Current time = end time
    /// - Current time > end time
    /// - WithdrawFromLockupStream amount equal to deposit amount and not
    function testFuzz_WithdrawableAmountOf(
        uint40 timeWarp,
        uint128 withdrawAmount
    ) external streamActive startTimeLessThanCurrentTime withWithdrawals {
        timeWarp = boundUint40(timeWarp, DEFAULT_CLIFF_DURATION, DEFAULT_TOTAL_DURATION * 2);

        // Warp into the future.
        uint40 currentTime = DEFAULT_START_TIME + timeWarp;
        vm.warp({ timestamp: currentTime });

        // Bound the withdraw amount.
        uint128 streamedAmount = calculateStreamedAmountForMultipleSegments(
            currentTime,
            DEFAULT_SEGMENTS,
            DEFAULT_DEPOSIT_AMOUNT
        );
        withdrawAmount = boundUint128(withdrawAmount, 1, streamedAmount);

        // Create the stream with a custom total amount. The broker fee is disabled so that it doesn't interfere with
        // the calculations.
        uint256 streamId = pro.createWithMilestones(
            defaultParams.createWithMilestones.sender,
            defaultParams.createWithMilestones.recipient,
            DEFAULT_DEPOSIT_AMOUNT,
            defaultParams.createWithMilestones.segments,
            defaultParams.createWithMilestones.asset,
            defaultParams.createWithMilestones.cancelable,
            defaultParams.createWithMilestones.startTime,
            Broker({ addr: address(0), fee: ZERO })
        );

        // Make the withdrawal.
        pro.withdraw({ streamId: streamId, to: users.recipient, amount: withdrawAmount });

        // Run the test.
        uint128 actualWithdrawableAmount = pro.withdrawableAmountOf(streamId);
        uint128 expectedWithdrawableAmount = streamedAmount - withdrawAmount;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }
}
