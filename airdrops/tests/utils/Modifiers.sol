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

    modifier givenCallerNotClaimed() {
        _;
    }

    modifier givenCampaignNotExists() {
        _;
    }

    modifier givenCampaignNotExpired() {
        _;
    }

    modifier givenCampaignStartTimeNotInFuture() {
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
        // Skip forward by 8 days.
        skip(8 days);
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                        WHEN
    //////////////////////////////////////////////////////////////////////////*/

    modifier whenAmountValid() {
        _;
    }

    modifier whenCallerAdmin() {
        setMsgSender(users.admin);
        _;
    }

    modifier whenCallerCampaignCreator() {
        setMsgSender(users.campaignCreator);
        _;
    }

    modifier whenCallerEligible() {
        setMsgSender(users.recipient1);
        _;
    }

    modifier whenCallerFactoryAdmin() {
        _;
    }

    modifier whenCallerNotAdmin() {
        _;
    }

    modifier whenCallerWithoutFeeCollectorRole() {
        _;
    }

    modifier whenClaimTimeGreaterThanVestingStartTime() {
        _;
    }

    modifier whenClaimTimeNotZero() {
        _;
    }

    modifier whenExpirationNotZero() {
        _;
    }

    modifier whenExpirationZero() {
        _;
    }

    modifier whenExpirationExceedsOneWeekFromVestingEndTime() {
        _;
    }

    modifier whenFactoryAdminIsContract() {
        _;
    }

    modifier whenFeeRecipientContract() {
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

    modifier whenRecipientEligible() {
        _;
    }

    modifier whenToAddressNotZero() {
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

    modifier whenUnlockPercentageNotGreaterThan100() {
        _;
    }

    modifier whenVestingEndTimeExceedsClaimTime() {
        _;
    }

    modifier whenVestingEndTimeGreaterThanVestingStartTime() {
        _;
    }

    modifier whenVestingStartTimeNotInFuture() {
        _;
    }

    modifier whenVestingStartTimeNotZero() {
        _;
    }

    modifier whenWithdrawalAddressNotZero() {
        _;
    }
}
