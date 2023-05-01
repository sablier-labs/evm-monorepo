// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";

import { Linear_Unit_Test } from "../Linear.t.sol";
import { StreamedAmountOf_Unit_Test } from "../../lockup/streamed-amount-of/streamedAmountOf.t.sol";

contract StreamedAmountOf_Linear_Unit_Test is Linear_Unit_Test, StreamedAmountOf_Unit_Test {
    function setUp() public virtual override(Linear_Unit_Test, StreamedAmountOf_Unit_Test) {
        Linear_Unit_Test.setUp();
        StreamedAmountOf_Unit_Test.setUp();
    }

    modifier whenStatusStreaming() {
        _;
    }

    function test_StreamedAmountOf_CliffTimeInTheFuture()
        external
        whenNotNull
        whenStreamHasNotBeenCanceled
        whenStatusStreaming
    {
        uint128 actualStreamedAmount = linear.streamedAmountOf(defaultStreamId);
        uint128 expectedStreamedAmount = 0;
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }

    modifier whenCliffTimeInThePast() {
        _;
    }

    function test_StreamedAmountOf()
        external
        whenNotNull
        whenStreamHasNotBeenCanceled
        whenStatusStreaming
        whenCliffTimeInThePast
    {
        vm.warp({ timestamp: defaults.WARP_26_PERCENT() });
        uint128 actualStreamedAmount = linear.streamedAmountOf(defaultStreamId);
        uint128 expectedStreamedAmount = 2600e18;
        assertEq(actualStreamedAmount, expectedStreamedAmount, "streamedAmount");
    }
}
