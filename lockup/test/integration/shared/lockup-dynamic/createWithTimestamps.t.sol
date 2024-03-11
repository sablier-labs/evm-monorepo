// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { LockupDynamic_Integration_Shared_Test } from "./LockupDynamic.t.sol";

contract CreateWithTimestamps_Integration_Shared_Test is LockupDynamic_Integration_Shared_Test {
    uint256 internal streamId;

    function setUp() public virtual override {
        streamId = lockupDynamic.nextStreamId();
    }

    modifier whenNotDelegateCalled() {
        _;
    }

    modifier whenRecipientNonZeroAddress() {
        _;
    }

    modifier whenDepositAmountNotZero() {
        _;
    }

    modifier whenSegmentCountNotZero() {
        _;
    }

    modifier whenSegmentCountNotTooHigh() {
        _;
    }

    modifier whenSegmentAmountsSumDoesNotOverflow() {
        _;
    }

    modifier whenStartTimeLessThanFirstSegmentTimestamp() {
        _;
    }

    modifier whenSegmentTimestampsOrdered() {
        _;
    }

    modifier whenEndTimeInTheFuture() {
        _;
    }

    modifier whenDepositAmountEqualToSegmentAmountsSum() {
        _;
    }

    modifier whenBrokerFeeNotTooHigh() {
        _;
    }

    modifier whenAssetContract() {
        _;
    }

    modifier whenAssetERC20() {
        _;
    }
}
