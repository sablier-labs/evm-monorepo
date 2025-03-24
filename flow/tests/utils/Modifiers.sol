// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { Users } from "./Types.sol";
import { Utils } from "./Utils.sol";

abstract contract Modifiers is Utils {
    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    Users private users;

    function setVariables(Users memory _users) public {
        users = _users;
    }

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

    modifier whenCallerAdmin() {
        setMsgSender({ msgSender: users.admin });
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
                                    COLLECT-FEES
    //////////////////////////////////////////////////////////////////////////*/

    modifier givenAdminIsContract() {
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

    modifier whenTotalAmountNotZero() {
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
