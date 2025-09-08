// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { BaseTest as EvmUtilsBase } from "@sablier/evm-utils/src/tests/BaseTest.sol";

import { Utils } from "./Utils.sol";

abstract contract Modifiers is Utils, EvmUtilsBase {
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

    modifier givenNotPending() {
        _;
    }

    modifier givenNotVoided() {
        _;
    }

    modifier whenCallerComptroller() {
        setMsgSender(address(comptroller));
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

    modifier whenTokenNotMissERC20Return() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                       CREATE
    //////////////////////////////////////////////////////////////////////////*/

    modifier whenRatePerSecondZero() {
        _;
    }

    modifier whenRatePerSecondNotZero() {
        _;
    }

    modifier whenSenderNotAddressZero() {
        _;
    }

    modifier whenStartTimeInThePast() {
        _;
    }

    modifier whenStartTimeNotZero() {
        _;
    }

    modifier whenTokenDecimalsNotExceed18() {
        _;
    }

    modifier whenTokenImplementsDecimals() {
        _;
    }

    modifier whenTokenNotNativeToken() {
        _;
    }

    modifier whenRecipientNotAddressZero() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      DEPOSIT
    //////////////////////////////////////////////////////////////////////////*/

    modifier whenDepositAmountNotZero() {
        _;
    }

    modifier whenRecipientMatches() {
        _;
    }

    modifier whenSenderMatches() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                       PAUSE
    //////////////////////////////////////////////////////////////////////////*/

    modifier givenStarted() {
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
                                        VOID
    //////////////////////////////////////////////////////////////////////////*/

    modifier whenCallerAuthorized() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      WITHDRAW
    //////////////////////////////////////////////////////////////////////////*/

    modifier givenBalanceExceedsTotalDebt() virtual {
        _;
    }

    modifier givenBalanceNotExceedTotalDebt() {
        _;
    }

    modifier whenAmountGreaterThanSnapshotDebt() {
        _;
    }

    modifier whenAmountLessThanTotalDebt() {
        _;
    }

    modifier whenAmountNotZero() {
        _;
    }

    modifier whenFeeNotLessThanMinFee() {
        _;
    }

    modifier whenWithdrawalAddressNotOwner() {
        _;
    }

    modifier whenWithdrawalAddressNotZero() {
        _;
    }

    modifier whenWithdrawalAddressOwner() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-NATIVE-TOKEN
    //////////////////////////////////////////////////////////////////////////*/

    modifier whenProvidedAddressNotZero() {
        _;
    }
}
