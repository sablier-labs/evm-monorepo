// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Linear_Shared_Test } from "../Linear.t.sol";

abstract contract CreateWithRange_Linear_Shared_Test is Linear_Shared_Test {
    uint256 internal streamId;

    function setUp() public virtual override {
        streamId = linear.nextStreamId();
    }

    modifier whenNoDelegateCall() {
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
