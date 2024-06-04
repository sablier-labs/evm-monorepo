// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

abstract contract Modifiers {
    /*//////////////////////////////////////////////////////////////////////////
                                       COMMON
    //////////////////////////////////////////////////////////////////////////*/

    modifier givenBalanceNotZero() {
        _;
    }

    modifier givenBalanceZero() {
        _;
    }

    modifier givenNotNull() {
        _;
    }

    modifier givenNotPaused() {
        _;
    }

    modifier givenRemainingAmountNotZero() {
        _;
    }

    modifier givenRemainingAmountZero() {
        _;
    }

    modifier whenAssetDoesNotMissERC20Return() {
        _;
    }

    modifier whenBrokerAddressIsNotZero() {
        _;
    }

    modifier whenBrokerFeeNotGreaterThanMaxFee() {
        _;
    }

    modifier whenCallerIsNotSender() {
        _;
    }

    modifier whenCallerIsSender() {
        _;
    }

    modifier whenNotDelegateCalled() {
        _;
    }

    modifier whenRatePerSecondIsNotZero() {
        _;
    }

    modifier whenSenderIsNotZeroAddress() {
        _;
    }

    modifier whenTokenDecimalIsNotZero() {
        _;
    }

    modifier whenTotalAmountIsNotZero() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                              ADJUST-AMOUNT-PER-SECOND
    //////////////////////////////////////////////////////////////////////////*/

    modifier whenRatePerSecondNotDifferent() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                       CREATE
    //////////////////////////////////////////////////////////////////////////*/

    modifier whenAssetContract() {
        _;
    }

    modifier whenAssetValidDecimals() {
        _;
    }

    modifier whenRecipientIsNotZeroAddress() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      DEPOSIT
    //////////////////////////////////////////////////////////////////////////*/

    modifier whenDepositAmountNonZero() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                       PAUSE
    //////////////////////////////////////////////////////////////////////////*/

    modifier givenStreamHasNoDebt() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                       REFUND
    //////////////////////////////////////////////////////////////////////////*/

    modifier whenNoOverrefund() {
        _;
    }

    modifier whenRefundAmountNotZero() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      RESTART
    //////////////////////////////////////////////////////////////////////////*/

    modifier givenPaused() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    WITHDRAW-AT
    //////////////////////////////////////////////////////////////////////////*/

    modifier whenCallerRecipient() {
        _;
    }

    modifier whenToNonZeroAddress() {
        _;
    }

    modifier whenWithdrawalAddressIsRecipient() {
        _;
    }

    modifier whenWithdrawalAddressNotRecipient() {
        _;
    }

    modifier whenWithdrawalTimeNotInTheFuture() {
        _;
    }

    modifier whenWithdrawalTimeNotLessThanLastTime() {
        _;
    }
}
