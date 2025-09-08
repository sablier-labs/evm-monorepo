// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { LockupDynamic } from "src/types/LockupDynamic.sol";
import { StreamedAmountOf_Integration_Concrete_Test } from "../../lockup/streamed-amount-of/streamedAmountOf.t.sol";
import { Lockup_Dynamic_Integration_Concrete_Test, Integration_Test } from "../LockupDynamic.t.sol";

contract StreamedAmountOf_Lockup_Dynamic_Integration_Concrete_Test is
    Lockup_Dynamic_Integration_Concrete_Test,
    StreamedAmountOf_Integration_Concrete_Test
{
    function setUp() public virtual override(Lockup_Dynamic_Integration_Concrete_Test, Integration_Test) {
        Lockup_Dynamic_Integration_Concrete_Test.setUp();
    }

    function test_GivenSingleSegment() external givenSTREAMINGStatus givenStartTimeInPast givenEndTimeInFuture {
        // Simulate the passage of time.
        vm.warp({ newTimestamp: defaults.START_TIME() + 2000 seconds });

        // Create an array with one segment.
        LockupDynamic.Segment[] memory segments = new LockupDynamic.Segment[](1);
        segments[0] = LockupDynamic.Segment({
            amount: defaults.DEPOSIT_AMOUNT(),
            exponent: defaults.segments()[1].exponent,
            timestamp: defaults.END_TIME()
        });

        // Create the stream.
        uint256 streamId = lockup.createWithTimestampsLD(_defaultParams.createWithTimestamps, segments);

        // It should return the correct streamed amount.
        uint128 actualStreamedAmount = lockup.streamedAmountOf(streamId);
        uint128 expectedStreamedAmount = 4472.13595499957941e18; // (0.2^0.5)*10,000
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }

    function test_GivenMultipleSegments() external givenSTREAMINGStatus givenStartTimeInPast givenEndTimeInFuture {
        // Simulate the passage of time. 740 seconds is ~10% of the way in the second segment.
        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() + 740 seconds });

        // It should return the correct streamed amount.
        uint128 actualStreamedAmount = lockup.streamedAmountOf(ids.defaultStream);
        uint128 expectedStreamedAmount = defaults.segments()[0].amount + 2340.0854685246007116e18; // ~7,400*0.1^{0.5}
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }
}
