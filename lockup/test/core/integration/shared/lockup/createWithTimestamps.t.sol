// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Lockup_Integration_Shared_Test } from "./Lockup.t.sol";

abstract contract CreateWithTimestamps_Integration_Shared_Test is Lockup_Integration_Shared_Test {
    uint256 internal streamId;

    function setUp() public virtual override {
        streamId = lockup.nextStreamId();
    }

    modifier whenAssetContract() {
        _;
    }

    modifier whenAssetERC20() {
        _;
    }

    modifier whenBrokerFeeNotExceedMaxValue() {
        _;
    }

    modifier whenCliffTimeNotZero() {
        _;
    }

    modifier whenCliffTimeZero() {
        _;
    }

    modifier whenCliffTimeLessThanEndTime() {
        _;
    }

    modifier whenDepositAmountNotZero() {
        _;
    }

    modifier whenDepositAmountNotEqualSegmentAmountsSum() {
        _;
    }

    modifier whenDepositAmountNotEqualTrancheAmountsSum() {
        _;
    }

    modifier whenNoDelegateCall() {
        _;
    }

    modifier whenRecipientNotZeroAddress() {
        _;
    }

    modifier whenSegmentAmountsSumNotOverflow() {
        _;
    }

    modifier whenSegmentCountNotZero() {
        _;
    }

    modifier whenSegmentCountNotExceedMaxValue() {
        _;
    }

    modifier whenSenderNotZeroAddress() {
        _;
    }

    modifier whenStartTimeNotZero() {
        _;
    }

    modifier whenStartTimeLessThanCliffTime() {
        _;
    }

    modifier whenStartTimeLessThanEndTime() {
        _;
    }

    modifier whenStartTimeLessThanFirstTimestamp() {
        _;
    }

    modifier whenTimestampsStrictlyIncreasing() {
        _;
    }

    modifier whenTrancheAmountsSumNotOverflow() {
        _;
    }

    modifier whenTrancheCountNotZero() {
        _;
    }

    modifier whenTrancheCountNotExceedMaxValue() {
        _;
    }

    modifier whenTrancheTimestampsAreOrdered() {
        _;
    }
}
