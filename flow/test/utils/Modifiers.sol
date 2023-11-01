// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.20;

abstract contract Modifiers {
    /*//////////////////////////////////////////////////////////////////////////
                                       COMMON
    //////////////////////////////////////////////////////////////////////////*/

    modifier whenAmountPerSecondNonZero() {
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

    modifier whenAmountPerSecondNotDifferent() {
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
                                      WITHDRAW
    //////////////////////////////////////////////////////////////////////////*/

    modifier whenNoOverdraw() {
        _;
    }

    modifier whenToNonZeroAddress() {
        _;
    }

    modifier whenWithdrawAmountNotZero() {
        _;
    }
}
