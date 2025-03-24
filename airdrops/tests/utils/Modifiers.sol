// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { BaseTest as EvmUtilsBase } from "@sablier/evm-utils/src/tests/BaseTest.sol";
import { Users } from "./Types.sol";

abstract contract Modifiers is EvmUtilsBase {
    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    Users private users;

    function setVariables(Users memory _users) public {
        users = _users;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                       GIVEN
    //////////////////////////////////////////////////////////////////////////*/

    modifier givenCampaignNotExists() {
        _;
    }

    modifier givenCampaignNotExpired() {
        _;
    }

    modifier givenMinFeeUSDNotZero() {
        _;
    }

    modifier givenMsgValueNotLessThanFee() {
        _;
    }

    modifier givenOracleNotZero() {
        _;
    }

    modifier givenRecipientNotClaimed() {
        _;
    }

    modifier givenSevenDaysPassed() {
        vm.warp({ newTimestamp: getBlockTimestamp() + 8 days });
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                        WHEN
    //////////////////////////////////////////////////////////////////////////*/

    modifier whenAmountValid() {
        _;
    }

    modifier whenCallerAdmin() {
        // Make the Admin the caller in the rest of this test suite.
        setMsgSender(users.admin);
        _;
    }

    modifier whenCallerCampaignCreator() {
        setMsgSender(users.campaignCreator);
        _;
    }

    modifier whenCallerFactoryAdmin() {
        _;
    }

    modifier whenClaimTimeGreaterThanStartTime() {
        _;
    }

    modifier whenClaimTimeNotZero() {
        _;
    }

    modifier whenEndTimeGreaterThanStartTime() {
        _;
    }

    modifier whenExpirationNotZero() {
        _;
    }

    modifier whenExpirationZero() {
        _;
    }

    modifier whenExpirationExceedsOneWeekFromEndTime() {
        _;
    }

    modifier whenFactoryAdminIsContract() {
        _;
    }

    modifier whenIndexInMerkleTree() {
        _;
    }

    modifier whenIndexValid() {
        _;
    }

    modifier whenMerkleProofValid() {
        _;
    }

    modifier whenNativeTokenNotFound() {
        _;
    }

    modifier whenNewFeeLower() {
        _;
    }

    modifier whenNewFeeNotExceedMaxFee() {
        _;
    }

    modifier whenNewOracleNotZero() {
        _;
    }

    modifier whenNotZeroExpiration() {
        _;
    }

    modifier whenOracleUpdatedTimeNotInFuture() {
        _;
    }

    modifier whenOraclePriceNotOutdated() {
        _;
    }

    modifier whenOraclePriceNotZero() {
        _;
    }

    modifier whenPercentagesSumNot100Pct() {
        _;
    }

    modifier whenProvidedAddressNotZero() {
        _;
    }

    modifier whenProvidedMerkleLockupValid() {
        _;
    }

    modifier whenRecipientValid() {
        _;
    }

    modifier whenScheduledStartTimeNotZero() {
        _;
    }

    modifier whenStartTimeNotInFuture() {
        _;
    }

    modifier whenStartTimeNotZero() {
        _;
    }

    modifier whenTotalPercentage100() {
        _;
    }

    modifier whenTotalPercentageNot100() {
        _;
    }

    modifier whenTotalPercentageNotGreaterThan100() {
        _;
    }

    modifier whenVestingEndTimeExceedsClaimTime() {
        _;
    }

    modifier whenWithdrawalAddressNotZero() {
        _;
    }
}
