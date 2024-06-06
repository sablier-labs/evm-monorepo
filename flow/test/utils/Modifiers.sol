// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

abstract contract Modifiers {
    /*//////////////////////////////////////////////////////////////////////////
                                       COMMON
    //////////////////////////////////////////////////////////////////////////*/

    modifier givenBalanceNotZero() virtual {
        _;
    }

    modifier givenNotNull() {
        _;
    }

    modifier givenNotPaused() {
        _;
    }

    modifier whenAssetDoesNotMissERC20Return() {
        _;
    }

    modifier whenCallerNotSender() {
        _;
    }

    modifier whenCallerSender() {
        _;
    }

    modifier whenNoDelegateCall() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                              ADJUST-AMOUNT-PER-SECOND
    //////////////////////////////////////////////////////////////////////////*/

    modifier whenNewRatePerSecondNotZero() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                       CREATE
    //////////////////////////////////////////////////////////////////////////*/

    modifier whenAssetDecimalsDoesNotExceed18() {
        _;
    }

    modifier whenAssetImplementsDecimals() {
        _;
    }

    modifier whenRatePerSecondNotZero() {
        _;
    }

    modifier whenSenderNotAddressZero() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      DEPOSIT
    //////////////////////////////////////////////////////////////////////////*/

    modifier whenBrokerAddressNotZero() {
        _;
    }

    modifier whenBrokerFeeNotGreaterThanMaxFee() {
        _;
    }

    modifier whenTransferAmountNotZero() {
        _;
    }

    modifier whenTotalAmountNotZero() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                       REFUND
    //////////////////////////////////////////////////////////////////////////*/

    modifier whenNoOverRefund() {
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

    modifier whenWithdrawalAddressNotOwner() {
        _;
    }

    modifier whenWithdrawalAddressNotZero() {
        _;
    }

    modifier whenWithdrawalAddressIsOwner() {
        _;
    }
}
