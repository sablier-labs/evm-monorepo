// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { LockupLinear } from "src/types/LockupLinear.sol";

import { Lockup_Linear_Integration_Fuzz_Test } from "./LockupLinear.t.sol";

contract StreamedAmountOf_Lockup_Linear_Integration_Fuzz_Test is Lockup_Linear_Integration_Fuzz_Test {
    function testFuzz_StreamedAmountOf_CliffTimeInFuture(
        uint40 timeJump,
        uint128 depositAmount,
        LockupLinear.UnlockAmounts memory unlockAmounts
    )
        external
        givenNotNull
        givenNotCanceledStream
    {
        vm.assume(depositAmount != 0);
        timeJump = boundUint40(timeJump, 1, defaults.CLIFF_DURATION() - 1);

        // Bound the unlock amounts.
        unlockAmounts.start = boundUint128(unlockAmounts.start, 0, depositAmount);
        unlockAmounts.cliff = boundUint128(unlockAmounts.start, 0, depositAmount - unlockAmounts.start);

        // Mint enough tokens to the Sender.
        deal({ token: address(dai), to: users.sender, give: depositAmount });

        // Approve the lockup contract to transfer the deposit amount.
        dai.approve(address(lockup), depositAmount);

        // Create the stream with the fuzzed deposit amount.
        _defaultParams.createWithTimestamps.depositAmount = depositAmount;
        _defaultParams.unlockAmounts = unlockAmounts;
        uint256 streamId = createDefaultStream();

        vm.warp({ newTimestamp: defaults.START_TIME() + timeJump });
        uint128 actualStreamedAmount = lockup.streamedAmountOf(streamId);
        uint128 expectedStreamedAmount = unlockAmounts.start > 0 ? unlockAmounts.start : 0;
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
        uint128 depositAmount,
        LockupLinear.UnlockAmounts memory unlockAmounts
    )
        external
        givenNotNull
        givenNotCanceledStream
        givenCliffTimeNotInFuture
    {
        vm.assume(depositAmount != 0);
        timeJump = boundUint40(timeJump, defaults.CLIFF_DURATION(), defaults.TOTAL_DURATION() * 2);

        // Bound the unlock amounts.
        unlockAmounts.start = boundUint128(unlockAmounts.start, 0, depositAmount);
        unlockAmounts.cliff = boundUint128(unlockAmounts.start, 0, depositAmount - unlockAmounts.start);

        // Mint enough tokens to the Sender.
        deal({ token: address(dai), to: users.sender, give: depositAmount });

        // Approve the lockup contract to transfer the deposit amount.
        dai.approve(address(lockup), depositAmount);

        // Create the stream with the fuzzed deposit amount.
        _defaultParams.createWithTimestamps.depositAmount = depositAmount;
        _defaultParams.unlockAmounts = unlockAmounts;
        uint256 streamId = createDefaultStream();

        // Simulate the passage of time.
        vm.warp({ newTimestamp: defaults.START_TIME() + timeJump });

        // Run the test.
        uint128 actualStreamedAmount = lockup.streamedAmountOf(streamId);
        uint128 expectedStreamedAmount = calculateStreamedAmountLL(
            defaults.START_TIME(), defaults.CLIFF_TIME(), defaults.END_TIME(), depositAmount, unlockAmounts
        );
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }

    /// @dev The streamed amount must never go down over time.
    function testFuzz_StreamedAmountOf_Monotonicity(
        uint40 timeWarp0,
        uint40 timeWarp1,
        uint128 depositAmount,
        LockupLinear.UnlockAmounts memory unlockAmounts
    )
        external
        givenNotNull
        givenNotCanceledStream
        givenCliffTimeNotInFuture
    {
        vm.assume(depositAmount != 0);
        timeWarp0 = boundUint40(timeWarp0, defaults.CLIFF_DURATION(), defaults.TOTAL_DURATION() - 1 seconds);
        timeWarp1 = boundUint40(timeWarp1, timeWarp0, defaults.TOTAL_DURATION());

        // Bound the unlock amounts.
        unlockAmounts.start = boundUint128(unlockAmounts.start, 0, depositAmount);
        unlockAmounts.cliff = boundUint128(unlockAmounts.start, 0, depositAmount - unlockAmounts.start);

        // Mint enough tokens to the Sender.
        deal({ token: address(dai), to: users.sender, give: depositAmount });

        // Approve the lockup contract to transfer the deposit amount.
        dai.approve(address(lockup), depositAmount);

        // Create the stream with the fuzzed deposit amount.
        _defaultParams.unlockAmounts = unlockAmounts;
        _defaultParams.createWithTimestamps.depositAmount = depositAmount;
        uint256 streamId = createDefaultStream();

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
