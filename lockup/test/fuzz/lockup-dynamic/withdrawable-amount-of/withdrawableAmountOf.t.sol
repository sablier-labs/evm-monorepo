// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { ZERO } from "@prb/math/UD60x18.sol";

import { Broker, LockupDynamic } from "src/types/DataTypes.sol";

import { Dynamic_Fuzz_Test } from "../Dynamic.t.sol";

contract WithdrawableAmountOf_Dynamic_Fuzz_Test is Dynamic_Fuzz_Test {
    uint256 internal defaultStreamId;

    modifier whenStatusStreaming() {
        defaultStreamId = createDefaultStream();

        // Disable the protocol fee so that it doesn't interfere with the calculations.
        changePrank({ msgSender: users.admin });
        comptroller.setProtocolFee({ asset: usdc, newProtocolFee: ZERO });
        changePrank({ msgSender: users.sender });
        _;
    }

    modifier whenStartTimeInThePast() {
        _;
    }

    /// @dev Given enough test runs, all of the following scenarios will be fuzzed:
    ///
    /// - End time in the past
    /// - End time in the present
    /// - End time in the future
    /// - Status streaming
    /// - Status settled
    function testFuzz_WithdrawableAmountOf_NoPreviousWithdrawals(uint40 timeWarp)
        external
        whenStatusStreaming
        whenStartTimeInThePast
    {
        timeWarp = boundUint40(timeWarp, defaults.CLIFF_DURATION(), defaults.TOTAL_DURATION() * 2);

        // Create the stream with a custom total amount. The broker fee is disabled so that it doesn't interfere with
        // the calculations.
        LockupDynamic.CreateWithMilestones memory params = defaultParams.createWithMilestones;
        params.totalAmount = defaults.DEPOSIT_AMOUNT();
        params.broker = Broker({ account: address(0), fee: ZERO });
        uint256 streamId = dynamic.createWithMilestones(params);

        // Simulate the passage of time.
        uint40 currentTime = defaults.START_TIME() + timeWarp;
        vm.warp({ timestamp: currentTime });

        // Run the test.
        uint128 actualWithdrawableAmount = dynamic.withdrawableAmountOf(streamId);
        uint128 expectedWithdrawableAmount =
            calculateStreamedAmountForMultipleSegments(currentTime, defaults.segments(), defaults.DEPOSIT_AMOUNT());
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }

    modifier whenWithWithdrawals() {
        _;
    }

    /// @dev Given enough test runs, all of the following scenarios will be fuzzed:
    ///
    /// - End time in the past
    /// - End time in the present
    /// - End time in the future
    /// - Multiple withdraw amounts
    /// - Status streaming
    /// - Status settled
    /// - Status depleted
    /// - Withdraw amount equal to deposited amount and not
    function testFuzz_WithdrawableAmountOf(
        uint40 timeWarp,
        uint128 withdrawAmount
    )
        external
        whenStatusStreaming
        whenStartTimeInThePast
        whenWithWithdrawals
    {
        timeWarp = boundUint40(timeWarp, defaults.CLIFF_DURATION(), defaults.TOTAL_DURATION() * 2);

        // Define the current time.
        uint40 currentTime = defaults.START_TIME() + timeWarp;

        // Bound the withdraw amount.
        uint128 streamedAmount =
            calculateStreamedAmountForMultipleSegments(currentTime, defaults.segments(), defaults.DEPOSIT_AMOUNT());
        withdrawAmount = boundUint128(withdrawAmount, 1, streamedAmount);

        // Create the stream with a custom total amount. The broker fee is disabled so that it doesn't interfere with
        // the calculations.
        LockupDynamic.CreateWithMilestones memory params = defaultParams.createWithMilestones;
        params.totalAmount = defaults.DEPOSIT_AMOUNT();
        params.broker = Broker({ account: address(0), fee: ZERO });
        uint256 streamId = dynamic.createWithMilestones(params);

        // Simulate the passage of time.
        vm.warp({ timestamp: currentTime });

        // Make the withdrawal.
        dynamic.withdraw({ streamId: streamId, to: users.recipient, amount: withdrawAmount });

        // Run the test.
        uint128 actualWithdrawableAmount = dynamic.withdrawableAmountOf(streamId);
        uint128 expectedWithdrawableAmount = streamedAmount - withdrawAmount;
        assertEq(actualWithdrawableAmount, expectedWithdrawableAmount, "withdrawableAmount");
    }
}
