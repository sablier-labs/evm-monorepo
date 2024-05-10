// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

abstract contract Modifiers {
    /*//////////////////////////////////////////////////////////////////////////
                                       COMMON
    //////////////////////////////////////////////////////////////////////////*/

    modifier whenratePerSecondNonZero() {
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

    modifier givenNotCanceled() {
        _;
    }

    modifier givenNotNull() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                              ADJUST-AMOUNT-PER-SECOND
    //////////////////////////////////////////////////////////////////////////*/

    modifier whenratePerSecondNotDifferent() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  CANCEL-MULTIPLE
    //////////////////////////////////////////////////////////////////////////*/

    modifier whenArrayCountNotZero() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                       CREATE
    //////////////////////////////////////////////////////////////////////////*/

    modifier whenSenderNonZeroAddress() {
        _;
    }

    modifier whenRecipientNonZeroAddress() {
        _;
    }

    modifier whenAssetContract() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  CREATE-MULTIPLE
    //////////////////////////////////////////////////////////////////////////*/

    modifier whenArrayCountsNotEqual() {
        _;
    }

    modifier whenArrayCountsEqual() {
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
                                      WITHDRAW
    //////////////////////////////////////////////////////////////////////////*/

    modifier givenBalanceNotZero() {
        _;
    }

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

    modifier whenWithdrawalTimeGreaterThanLastUpdate() {
        _;
    }
}
