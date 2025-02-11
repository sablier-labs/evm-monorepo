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

    modifier givenNotVoided() {
        _;
    }

    modifier whenCallerAdmin() {
        resetPrank({ msgSender: users.admin });
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
                               ADJUST-RATE-PER-SECOND
    //////////////////////////////////////////////////////////////////////////*/

    modifier whenNewRatePerSecondNotEqualsCurrentRatePerSecond() {
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

    modifier whenSenderNotAddressZero() {
        _;
    }

    modifier whenTokenDecimalsNotExceed18() {
        _;
    }

    modifier whenTokenImplementsDecimals() {
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
}
