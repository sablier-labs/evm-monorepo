// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { ISablierLockup } from "src/core/interfaces/ISablierLockup.sol";

import { Defaults } from "./Defaults.sol";
import { Fuzzers } from "./Fuzzers.sol";
import { Users } from "./Types.sol";

abstract contract Modifiers is Fuzzers {
    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    Defaults private defaults;
    Users private users;

    function setVariables(Defaults _defaults, Users memory _users) public {
        defaults = _defaults;
        users = _users;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                       COMMON
    //////////////////////////////////////////////////////////////////////////*/

    modifier givenCliffTimeNotInFuture() {
        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });
        _;
    }

    modifier givenEndTimeInFuture() {
        // Simulate the passage of time.
        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });
        _;
    }

    modifier givenNFTExists() {
        _;
    }

    modifier givenNotCanceledStream() {
        _;
    }

    modifier givenNotNull() {
        _;
    }

    modifier givenPreviousWithdrawal() {
        _;
    }

    modifier givenRecipientAllowedToHook() {
        _;
    }

    modifier givenStartTimeInPast() {
        _;
    }

    modifier givenSTREAMINGStatus() {
        // Warp to the future, after the stream's start time but before the stream's end time.
        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });
        _;
    }

    modifier givenWarmStream() {
        _;
    }

    modifier whenAssetContract() {
        _;
    }

    modifier whenAssetERC20() {
        _;
    }

    modifier whenCallerAdmin() {
        // Make the Admin the caller in the rest of this test suite.
        resetPrank({ msgSender: users.admin });
        _;
    }

    modifier whenCallerRecipient() {
        resetPrank({ msgSender: users.recipient });
        _;
    }

    modifier whenCallerSender() {
        resetPrank({ msgSender: users.sender });
        _;
    }

    modifier whenNoDelegateCall() {
        _;
    }

    modifier whenNonRevertingRecipient() {
        _;
    }

    modifier whenProvidedAddressContract() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                       BATCH
    //////////////////////////////////////////////////////////////////////////*/

    modifier whenCallFunctionExists() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                        BURN
    //////////////////////////////////////////////////////////////////////////*/

    modifier whenCallerNotRecipient() {
        _;
    }

    modifier givenNotDepletedStream() {
        _;
    }

    modifier givenDepletedStream(ISablierLockup lockup, uint256 streamId) {
        vm.warp({ newTimestamp: defaults.END_TIME() });
        lockup.withdrawMax({ streamId: streamId, to: users.recipient });
        _;
    }

    modifier givenTransferableNFT() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  CAMPAIGN-COMMON
    //////////////////////////////////////////////////////////////////////////*/

    modifier givenCampaignNotExpired() {
        _;
    }

    modifier givenMsgValueNotLessThanSablierFee() {
        _;
    }

    modifier givenRecipientNotClaimed() {
        _;
    }

    modifier givenSevenDaysPassed() {
        vm.warp({ newTimestamp: getBlockTimestamp() + 8 days });
        _;
    }

    modifier whenAmountValid() {
        _;
    }

    modifier whenCallerCampaignOwner() {
        resetPrank({ msgSender: users.campaignOwner });
        _;
    }

    modifier whenExpirationNotZero() {
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

    modifier whenPercentagesSumNot100Pct() {
        _;
    }

    modifier whenPercentagesSumNotOverflow() {
        _;
    }

    modifier whenProvidedMerkleLockupValid() {
        _;
    }

    modifier whenRecipientValid() {
        _;
    }

    modifier whenScheduledStartTimeZero() {
        _;
    }

    modifier whenTotalPercentage100() {
        _;
    }

    modifier whenTotalPercentageNot100() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                       CANCEL
    //////////////////////////////////////////////////////////////////////////*/

    modifier givenCancelableStream() {
        _;
    }

    modifier givenColdStream() {
        _;
    }

    modifier whenRecipientNotReentrant() {
        _;
    }

    modifier whenRecipientReturnsValidSelector() {
        _;
    }

    modifier whenCallerNotSender() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  CANCEL-MULTIPLE
    //////////////////////////////////////////////////////////////////////////*/

    modifier givenAllStreamsCancelable() {
        _;
    }

    modifier givenNoColdStreams() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   CREATE-COMMON
    //////////////////////////////////////////////////////////////////////////*/

    modifier whenBrokerFeeNotExceedMaxValue() {
        _;
    }

    modifier whenSegmentCountNotExceedMaxValue() {
        _;
    }

    modifier whenTrancheCountNotExceedMaxValue() {
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

    modifier whenRecipientNotZeroAddress() {
        _;
    }

    modifier whenSegmentAmountsSumNotOverflow() {
        _;
    }

    modifier whenSegmentCountNotZero() {
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

    modifier whenTrancheTimestampsAreOrdered() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   CREATE-MERKLE
    //////////////////////////////////////////////////////////////////////////*/

    modifier givenCampaignNotExists() {
        _;
    }

    modifier whenNameNotTooLong() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                CREATE-WITH-DURATION
    //////////////////////////////////////////////////////////////////////////*/

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

    modifier whenStartTimeNotExceedsFirstTimestamp() {
        _;
    }

    modifier whenTimestampsCalculationNotOverflow() {
        _;
    }

    modifier whenTimestampsCalculationOverflows() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                 SAFE-ASSET-SYMBOL
    //////////////////////////////////////////////////////////////////////////*/

    modifier givenSymbolImplemented() {
        _;
    }

    modifier givenSymbolAsString() {
        _;
    }

    modifier givenSymbolNotLongerThan30Chars() {
        _;
    }

    modifier whenNotEmptyString() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     MAP-SYMBOL
    //////////////////////////////////////////////////////////////////////////*/

    modifier givenKnownNFTContract() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     STATUS-OF
    //////////////////////////////////////////////////////////////////////////*/

    modifier givenAssetsNotFullyWithdrawn() {
        _;
    }

    modifier givenStartTimeNotInFuture() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                 STREAMED-AMOUNT-OF
    //////////////////////////////////////////////////////////////////////////*/

    modifier givenCliffTimeInPast() {
        _;
    }

    modifier givenPENDINGStatus() {
        _;
    }

    modifier givenMultipleSegments() {
        _;
    }

    modifier whenCurrentTimestampNot1st() {
        _;
    }

    modifier givenMultipleTranches() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   TRANSFER-ADMIN
    //////////////////////////////////////////////////////////////////////////*/

    modifier whenNewAdminNotSameAsCurrentAdmin() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      WITHDRAW
    //////////////////////////////////////////////////////////////////////////*/

    modifier givenNotDEPLETEDStatus() {
        vm.warp({ newTimestamp: defaults.START_TIME() });
        _;
    }

    modifier whenHookReturnsValidSelector() {
        _;
    }

    modifier whenNonZeroWithdrawAmount() {
        _;
    }

    modifier whenWithdrawalAddressNotZero() {
        _;
    }

    modifier whenWithdrawalAddressRecipient() {
        _;
    }

    modifier whenWithdrawAmountNotOverdraw() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   WITHDRAW-HOOKS
    //////////////////////////////////////////////////////////////////////////*/

    modifier givenRecipientNotSameAsSender() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                 WITHDRAW-MULTIPLE
    //////////////////////////////////////////////////////////////////////////*/

    modifier whenArraysEqual() {
        _;
    }

    modifier givenNoDEPLETEDStreams() {
        vm.warp({ newTimestamp: defaults.START_TIME() });
        _;
    }

    modifier givenNoNullStreams() {
        _;
    }

    modifier whenEqualArraysLength() {
        _;
    }

    modifier whenNonZeroArrayLength() {
        _;
    }

    modifier whenNoAmountOverdraws() {
        _;
    }

    modifier whenNoZeroAmounts() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                             WITHDRAW-MAX-AND-TRANSFER
    //////////////////////////////////////////////////////////////////////////*/

    modifier givenNonZeroWithdrawableAmount() {
        _;
    }

    modifier givenNotBurnedNFT() {
        _;
    }

    modifier givenTransferableStream() {
        _;
    }
}
