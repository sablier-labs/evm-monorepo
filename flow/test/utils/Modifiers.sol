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

    modifier givenNotCanceled() {
        _;
    }

    modifier givenNotNull() {
        _;
    }

    modifier givenRemainingAmountZero() {
        _;
    }

    modifier givenRemainingAmountNotZero() {
        _;
    }

    modifier whenCallerAuthorized() {
        _;
    }

    modifier whenCallerUnauthorized() {
        _;
    }

    modifier whenNotDelegateCalled() {
        _;
    }

    modifier whenRatePerSecondNonZero() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                              ADJUST-AMOUNT-PER-SECOND
    //////////////////////////////////////////////////////////////////////////*/

    modifier whenRatePerSecondNotDifferent() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                       CANCEL
    //////////////////////////////////////////////////////////////////////////*/

    modifier whenRefundableAmountNotZero() {
        _;
    }

    modifier whenWithdrawableAmountNotZero() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                       CREATE
    //////////////////////////////////////////////////////////////////////////*/

    modifier whenAssetContract() {
        _;
    }

    modifier whenRecipientNonZeroAddress() {
        _;
    }

    modifier whenSenderNonZeroAddress() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      DEPOSIT
    //////////////////////////////////////////////////////////////////////////*/

    modifier whenDepositAmountNonZero() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                 REFUND-FROM-STREAM
    //////////////////////////////////////////////////////////////////////////*/

    modifier whenNoOverrefund() {
        _;
    }

    modifier whenRefundAmountNotZero() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   RESTART-STREAM
    //////////////////////////////////////////////////////////////////////////*/

    modifier givenCanceled() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    WITHDRAW-AT
    //////////////////////////////////////////////////////////////////////////*/

    modifier whenCallerRecipient() {
        _;
    }

    modifier whenLastTimeNotLessThanWithdrawalTime() {
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
}
