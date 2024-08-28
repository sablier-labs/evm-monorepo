// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Lockup_Integration_Shared_Test } from "./Lockup.t.sol";

abstract contract CreateWithDurations_Integration_Shared_Test is Lockup_Integration_Shared_Test {
    uint256 internal streamId;

    function setUp() public virtual override {
        streamId = lockup.nextStreamId();
    }

    modifier whenCliffDurationNotZero() {
        _;
    }

    modifier whenCliffDurationZero() {
        _;
    }

    modifier WhenCliffTimeCalculationNotOverflow() {
        _;
    }

    modifier whenEndTimeCalculationNotOverflow() {
        _;
    }

    modifier whenFirstIndexHasNonZeroDuration() {
        _;
    }

    modifier whenNoDelegateCall() {
        _;
    }

    modifier whenSegmentCountNotExceedMaxValue() {
        _;
    }

    modifier whenStartTimeNotExceedsFirstTimestamp() {
        _;
    }

    modifier whenTimestampsCalculationNotOverflow() {
        _;
    }

    modifier whenTimestampsCalculationOverflows() {
        _;
    }

    modifier whenTrancheCountNotExceedMaxValue() {
        _;
    }
}
