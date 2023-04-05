// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { ZERO } from "@prb/math/UD60x18.sol";

import { Broker, LockupDynamic } from "src/types/DataTypes.sol";

import { Dynamic_Fuzz_Test } from "../Dynamic.t.sol";

contract WithdrawableAmountOf_Dynamic_Fuzz_Test is Dynamic_Fuzz_Test {
    uint256 internal defaultStreamId;

    modifier whenStreamActive() {
        // Create the default stream.
        defaultStreamId = createDefaultStream();

        // Disable the protocol fee so that it doesn't interfere with the calculations.
        changePrank({ msgSender: users.admin });
        comptroller.setProtocolFee({ asset: DEFAULT_ASSET, newProtocolFee: ZERO });
        changePrank({ msgSender: users.sender });
        _;
    }

    modifier whenStartTimeInThePast() {
        _;
    }

    /// @dev it should return the correct withdrawable amount.
    ///
    /// The fuzzing ensures that all of the following scenarios are tested:
    ///
    /// - End time in the past
    /// - End time in the present
    /// - End time in the future
    function testFuzz_WithdrawableAmountOf_WithoutWithdrawals(uint40 timeWarp)
        external
        whenStreamActive
        whenStartTimeInThePast
    {
        timeWarp = boundUint40(timeWarp, DEFAULT_CLIFF_DURATION, DEFAULT_TOTAL_DURATION * 2);

        // Create the stream with a custom total amount. The broker fee is disabled so that it doesn't interfere with
        // the calculations.
        LockupDynamic.CreateWithMilestones memory params = defaultParams.createWithMilestones;
        params.totalAmount = DEFAULT_DEPOSIT_AMOUNT;
        params.broker = Broker({ account: address(0), fee: ZERO });
        uint256 streamId = dynamic.createWithMilestones(params);

        // Warp into the future.
        uint40 currentTime = DEFAULT_START_TIME + timeWarp;
        vm.warp({ timestamp: currentTime });

        // Run the test.
        uint128 actualWithdrawableAmount = dynamic.withdrawableAmountOf(streamId);
        uint128 expectedWithdrawableAmount =
            calculateStreamedAmountForMultipleSegments(currentTime, DEFAULT_SEGMENTS, DEFAULT_DEPOSIT_AMOUNT);
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }

    modifier whenWithWithdrawals() {
        _;
    }

    /// @dev it should return the correct withdrawable amount.
    ///
    /// The fuzzing ensures that all of the following scenarios are tested:
    ///
    /// - End time in the past
    /// - End time in the present
    /// - End time in the future
    /// - Multiple withdraw amounts
    /// - Withdraw amount equal to deposit amount and not
    function testFuzz_WithdrawableAmountOf(
        uint40 timeWarp,
        uint128 withdrawAmount
    )
        external
        whenStreamActive
        whenStartTimeInThePast
        whenWithWithdrawals
    {
        timeWarp = boundUint40(timeWarp, DEFAULT_CLIFF_DURATION, DEFAULT_TOTAL_DURATION * 2);

        // Define the current time.
        uint40 currentTime = DEFAULT_START_TIME + timeWarp;

        // Bound the withdraw amount.
        uint128 streamedAmount =
            calculateStreamedAmountForMultipleSegments(currentTime, DEFAULT_SEGMENTS, DEFAULT_DEPOSIT_AMOUNT);
        withdrawAmount = boundUint128(withdrawAmount, 1, streamedAmount);

        // Create the stream with a custom total amount. The broker fee is disabled so that it doesn't interfere with
        // the calculations.
        LockupDynamic.CreateWithMilestones memory params = defaultParams.createWithMilestones;
        params.totalAmount = DEFAULT_DEPOSIT_AMOUNT;
        params.broker = Broker({ account: address(0), fee: ZERO });
        uint256 streamId = dynamic.createWithMilestones(params);

        // Warp into the future.
        vm.warp({ timestamp: currentTime });

        // Make the withdrawal.
        dynamic.withdraw({ streamId: streamId, to: users.recipient, amount: withdrawAmount });

        // Run the test.
        uint128 actualWithdrawableAmount = dynamic.withdrawableAmountOf(streamId);
        uint128 expectedWithdrawableAmount = streamedAmount - withdrawAmount;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }
}
