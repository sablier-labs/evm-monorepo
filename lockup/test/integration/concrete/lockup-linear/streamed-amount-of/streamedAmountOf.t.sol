// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { LockupLinear_Integration_Concrete_Test } from "../LockupLinear.t.sol";
import { StreamedAmountOf_Integration_Concrete_Test } from "../../lockup/streamed-amount-of/streamedAmountOf.t.sol";

contract StreamedAmountOf_LockupLinear_Integration_Concrete_Test is
    LockupLinear_Integration_Concrete_Test,
    StreamedAmountOf_Integration_Concrete_Test
{
    function setUp()
        public
        virtual
        override(LockupLinear_Integration_Concrete_Test, StreamedAmountOf_Integration_Concrete_Test)
    {
        LockupLinear_Integration_Concrete_Test.setUp();
        StreamedAmountOf_Integration_Concrete_Test.setUp();
    }

    function test_StreamedAmountOf_CliffTimeInThePast()
        external
        whenNotNull
        whenStreamHasNotBeenCanceled
        whenStatusStreaming
    {
        uint128 actualStreamedAmount = lockupLinear.streamedAmountOf(defaultStreamId);
        uint128 expectedStreamedAmount = 0;
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }

    function test_StreamedAmountOf_CliffTimeInThePresent()
        external
        whenNotNull
        whenStreamHasNotBeenCanceled
        whenStatusStreaming
    {
        vm.warp({ timestamp: defaults.CLIFF_TIME() });
        uint128 actualStreamedAmount = lockupLinear.streamedAmountOf(defaultStreamId);
        uint128 expectedStreamedAmount = defaults.CLIFF_AMOUNT();
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }

    function test_StreamedAmountOf_CliffTimeInTheFuture()
        external
        whenNotNull
        whenStreamHasNotBeenCanceled
        whenStatusStreaming
    {
        vm.warp({ timestamp: defaults.WARP_26_PERCENT() });
        uint128 actualStreamedAmount = lockupLinear.streamedAmountOf(defaultStreamId);
        uint128 expectedStreamedAmount = 2600e18;
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }
}
