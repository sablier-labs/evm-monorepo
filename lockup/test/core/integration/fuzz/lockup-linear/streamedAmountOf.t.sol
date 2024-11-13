// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Lockup } from "src/core/types/DataTypes.sol";

import { Lockup_Linear_Integration_Shared_Test } from "./../../shared/lockup/LockupLinear.t.sol";

contract StreamedAmountOf_Lockup_Linear_Integration_Fuzz_Test is Lockup_Linear_Integration_Shared_Test {
    function testFuzz_StreamedAmountOf_CliffTimeInFuture(uint40 timeJump)
        external
        givenNotNull
        givenNotCanceledStream
    {
        timeJump = boundUint40(timeJump, 0, defaults.CLIFF_DURATION() - 1);
        vm.warp({ newTimestamp: defaults.START_TIME() + timeJump });
        uint128 actualStreamedAmount = lockup.streamedAmountOf(defaultStreamId);
        uint128 expectedStreamedAmount = 0;
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }

    /// @dev Given enough fuzz runs, all of the following scenarios will be fuzzed:
    ///
    /// - End time in the past
    /// - End time in the present
    /// - End time in the future
    /// - Multiple deposit amounts
    /// - Status streaming
    /// - Status settled
    function testFuzz_StreamedAmountOf_Calculation(
        uint40 timeJump,
        uint128 depositAmount
    )
        external
        givenNotNull
        givenNotCanceledStream
        givenCliffTimeNotInFuture
    {
        vm.assume(depositAmount != 0);
        timeJump = boundUint40(timeJump, defaults.CLIFF_DURATION(), defaults.TOTAL_DURATION() * 2);

        // Mint enough assets to the Sender.
        deal({ token: address(dai), to: users.sender, give: depositAmount });

        // Create the stream with the fuzzed deposit amount.
        Lockup.CreateWithTimestamps memory params = defaults.createWithTimestampsBrokerNull();
        params.totalAmount = depositAmount;
        uint256 streamId = lockup.createWithTimestampsLL(params, defaults.CLIFF_TIME());

        // Simulate the passage of time.
        vm.warp({ newTimestamp: defaults.START_TIME() + timeJump });

        // Run the test.
        uint128 actualStreamedAmount = lockup.streamedAmountOf(streamId);
        uint128 expectedStreamedAmount =
            calculateLockupLinearStreamedAmount(defaults.START_TIME(), defaults.END_TIME(), depositAmount);
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }

    /// @dev The streamed amount must never go down over time.
    function testFuzz_StreamedAmountOf_Monotonicity(
        uint40 timeWarp0,
        uint40 timeWarp1,
        uint128 depositAmount
    )
        external
        givenNotNull
        givenNotCanceledStream
        givenCliffTimeNotInFuture
    {
        vm.assume(depositAmount != 0);
        timeWarp0 = boundUint40(timeWarp0, defaults.CLIFF_DURATION(), defaults.TOTAL_DURATION() - 1 seconds);
        timeWarp1 = boundUint40(timeWarp1, timeWarp0, defaults.TOTAL_DURATION());

        // Mint enough assets to the Sender.
        deal({ token: address(dai), to: users.sender, give: depositAmount });

        // Create the stream with the fuzzed deposit amount.
        Lockup.CreateWithTimestamps memory params = defaults.createWithTimestampsBrokerNull();
        params.totalAmount = depositAmount;
        uint256 streamId = lockup.createWithTimestampsLL(params, defaults.CLIFF_TIME());

        // Warp to the future for the first time.
        vm.warp({ newTimestamp: defaults.START_TIME() + timeWarp0 });

        // Calculate the streamed amount at this midpoint in time.
        uint128 streamedAmount0 = lockup.streamedAmountOf(streamId);

        // Warp to the future for the second time.
        vm.warp({ newTimestamp: defaults.START_TIME() + timeWarp1 });

        // Assert that this streamed amount is greater than or equal to the previous streamed amount.
        uint128 streamedAmount1 = lockup.streamedAmountOf(streamId);
        assertGe(streamedAmount1, streamedAmount0, "streamedAmount");
    }
}
