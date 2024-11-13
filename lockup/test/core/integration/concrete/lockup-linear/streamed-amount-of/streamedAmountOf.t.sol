// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { StreamedAmountOf_Integration_Concrete_Test } from
    "./../../lockup-base/streamed-amount-of/streamedAmountOf.t.sol";
import { Lockup_Linear_Integration_Concrete_Test, Integration_Test } from "./../LockupLinear.t.sol";

contract StreamedAmountOf_Lockup_Linear_Integration_Concrete_Test is
    Lockup_Linear_Integration_Concrete_Test,
    StreamedAmountOf_Integration_Concrete_Test
{
    function setUp() public virtual override(Lockup_Linear_Integration_Concrete_Test, Integration_Test) {
        Lockup_Linear_Integration_Concrete_Test.setUp();
    }

    function test_GivenCliffTimeZero() external givenPENDINGStatus {
        uint40 cliffTime = 0;
        uint256 streamId = lockup.createWithTimestampsLL(_defaultParams.createWithTimestamps, cliffTime);

        vm.warp({ newTimestamp: defaults.START_TIME() - 1 });

        uint128 actualStreamedAmount = lockup.streamedAmountOf(streamId);
        uint128 expectedStreamedAmount = 0;
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }

    function test_GivenCliffTimeNotZero() external givenPENDINGStatus {
        vm.warp({ newTimestamp: defaults.START_TIME() - 1 });

        uint128 actualStreamedAmount = lockup.streamedAmountOf(defaultStreamId);
        uint128 expectedStreamedAmount = 0;
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }

    function test_GivenCliffTimeInFuture() external givenSTREAMINGStatus {
        vm.warp({ newTimestamp: defaults.CLIFF_TIME() - 1 });
        uint128 actualStreamedAmount = lockup.streamedAmountOf(defaultStreamId);
        uint128 expectedStreamedAmount = 0;
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }

    function test_GivenCliffTimeInPresent() external givenSTREAMINGStatus {
        vm.warp({ newTimestamp: defaults.CLIFF_TIME() });
        uint128 actualStreamedAmount = lockup.streamedAmountOf(defaultStreamId);
        uint128 expectedStreamedAmount = defaults.CLIFF_AMOUNT();
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }

    function test_GivenEndTimeNotInFuture() external givenSTREAMINGStatus givenCliffTimeInPast {
        vm.warp({ newTimestamp: defaults.END_TIME() + 1 });
        uint128 actualStreamedAmount = lockup.streamedAmountOf(defaultStreamId);
        uint128 expectedStreamedAmount = defaults.DEPOSIT_AMOUNT();
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }

    function test_GivenEndTimeInFuture() external givenSTREAMINGStatus givenCliffTimeInPast {
        uint128 actualStreamedAmount = lockup.streamedAmountOf(defaultStreamId);
        uint128 expectedStreamedAmount = 2600e18;
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }
}
