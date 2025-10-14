// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { StreamedAmountOf_Integration_Concrete_Test } from "../../lockup/streamed-amount-of/streamedAmountOf.t.sol";
import { Lockup_Linear_Integration_Concrete_Test, Integration_Test } from "./../LockupLinear.t.sol";

contract StreamedAmountOf_Lockup_Linear_Integration_Concrete_Test is
    Lockup_Linear_Integration_Concrete_Test,
    StreamedAmountOf_Integration_Concrete_Test
{
    function setUp() public virtual override(Lockup_Linear_Integration_Concrete_Test, Integration_Test) {
        Lockup_Linear_Integration_Concrete_Test.setUp();
    }

    function test_GivenCliffTimeZero() external givenSTREAMINGStatus {
        _defaultParams.cliffTime = 0;
        _defaultParams.unlockAmounts.cliff = 0;
        uint256 streamId = createDefaultStream();
        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });
        uint128 actualStreamedAmount = lockup.streamedAmountOf(streamId);
        uint128 expectedStreamedAmount = defaults.STREAMED_AMOUNT_26_PERCENT();
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }

    function test_GivenCliffTimeInFuture() external givenSTREAMINGStatus givenCliffTimeNotZero {
        _defaultParams.unlockAmounts.start = 1;
        uint256 streamId = createDefaultStream();
        vm.warp({ newTimestamp: defaults.CLIFF_TIME() - 1 });
        uint128 actualStreamedAmount = lockup.streamedAmountOf(streamId);
        uint128 expectedStreamedAmount = 1;
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }

    function test_GivenCliffTimeInFuture_Zero() external givenSTREAMINGStatus givenCliffTimeNotZero {
        vm.warp({ newTimestamp: defaults.CLIFF_TIME() - 1 });
        uint128 actualStreamedAmount = lockup.streamedAmountOf(ids.defaultStream);
        uint128 expectedStreamedAmount = 0;
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }

    function test_GivenCliffTimeInPresent() external givenSTREAMINGStatus givenCliffTimeNotZero {
        vm.warp({ newTimestamp: defaults.CLIFF_TIME() });
        uint128 actualStreamedAmount = lockup.streamedAmountOf(ids.defaultStream);
        uint128 expectedStreamedAmount = defaults.CLIFF_AMOUNT();
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }

    function test_GivenStartAmount() external givenSTREAMINGStatus givenCliffTimeNotZero givenCliffTimeInPast {
        _defaultParams.unlockAmounts.start = 1;
        uint256 streamId = createDefaultStream();
        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });
        uint128 actualStreamedAmount = lockup.streamedAmountOf(streamId);
        uint128 expectedStreamedAmount = defaults.STREAMED_AMOUNT_26_PERCENT() + 1;
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }

    function test_GivenNoCliffAmount()
        external
        givenSTREAMINGStatus
        givenCliffTimeNotZero
        givenCliffTimeInPast
        givenNoStartAmount
    {
        _defaultParams.unlockAmounts.cliff = 0;
        uint256 streamId = createDefaultStream();
        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });

        uint128 actualStreamedAmount = lockup.streamedAmountOf(streamId);
        uint128 expectedStreamedAmount = calculateStreamedAmountLL(
            _defaultParams.createWithTimestamps.timestamps.start,
            _defaultParams.cliffTime,
            _defaultParams.createWithTimestamps.timestamps.end,
            defaults.DEPOSIT_AMOUNT(),
            _defaultParams.unlockAmounts
        );

        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }

    function test_GivenCliffAmount()
        external
        givenSTREAMINGStatus
        givenCliffTimeNotZero
        givenCliffTimeInPast
        givenNoStartAmount
    {
        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });
        uint128 actualStreamedAmount = lockup.streamedAmountOf(ids.defaultStream);
        uint128 expectedStreamedAmount = defaults.STREAMED_AMOUNT_26_PERCENT();
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }
}
