// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { Dynamic_Shared_Test } from "../Dynamic.t.sol";

contract CreateWithMilestones_Dynamic_Shared_Test is Dynamic_Shared_Test {
    uint256 internal streamId;

    function setUp() public virtual override {
        streamId = dynamic.nextStreamId();
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

    modifier whenSegmentCountNotZero() {
        _;
    }

    modifier whenSegmentCountNotTooHigh() {
        _;
    }

    modifier whenSegmentAmountsSumDoesNotOverflow() {
        _;
    }

    modifier whenStartTimeLessThanFirstSegmentMilestone() {
        _;
    }

    modifier whenSegmentMilestonesOrdered() {
        _;
    }

    modifier whenEndTimeInTheFuture() {
        _;
    }

    modifier whenDepositAmountEqualToSegmentAmountsSum() {
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
