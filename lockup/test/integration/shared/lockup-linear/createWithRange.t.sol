// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { LockupLinear_Integration_Shared_Test } from "./LockupLinear.t.sol";

abstract contract CreateWithRange_Integration_Shared_Test is LockupLinear_Integration_Shared_Test {
    uint256 internal streamId;

    function setUp() public virtual override {
        streamId = lockupLinear.nextStreamId();
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

    modifier whenStartTimeNotGreaterThanCliffTime() {
        _;
    }

    modifier whenCliffTimeLessThanEndTime() {
        _;
    }

    modifier whenEndTimeInTheFuture() {
        _;
    }

    modifier whenProtocolFeeNotTooHigh() {
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
