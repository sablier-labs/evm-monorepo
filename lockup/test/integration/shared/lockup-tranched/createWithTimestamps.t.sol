// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { LockupTranched_Integration_Shared_Test } from "./LockupTranched.t.sol";

contract CreateWithTimestamps_Integration_Shared_Test is LockupTranched_Integration_Shared_Test {
    uint256 internal streamId;

    function setUp() public virtual override {
        streamId = lockupTranched.nextStreamId();
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

    modifier whenTrancheCountNotZero() {
        _;
    }

    modifier whenTrancheCountNotTooHigh() {
        _;
    }

    modifier whenTrancheAmountsSumDoesNotOverflow() {
        _;
    }

    modifier whenStartTimeLessThanFirstTrancheTimestamp() {
        _;
    }

    modifier whenTrancheTimestampsOrdered() {
        _;
    }

    modifier whenEndTimeInTheFuture() {
        _;
    }

    modifier whenDepositAmountEqualToTrancheAmountsSum() {
        _;
    }

    modifier givenProtocolFeeNotTooHigh() {
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
