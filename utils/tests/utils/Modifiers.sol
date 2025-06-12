// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { BaseTest } from "src/tests/BaseTest.sol";

abstract contract Modifiers is BaseTest {
    /*//////////////////////////////////////////////////////////////////////////
                                       GIVEN
    //////////////////////////////////////////////////////////////////////////*/

    modifier givenOracleNotZero() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                        WHEN
    //////////////////////////////////////////////////////////////////////////*/

    modifier whenAccountHasRole() {
        _;
    }

    modifier whenAccountNotAdmin() {
        _;
    }

    modifier whenAccountNotHaveRole() {
        _;
    }

    modifier whenCallerAdmin() {
        setMsgSender(admin);
        _;
    }

    modifier whenCallerNotAdmin() {
        _;
    }

    modifier whenCallerCurrentComptroller() {
        setMsgSender(address(comptroller));
        _;
    }

    modifier whenCallerWithoutFeeCollectorRole() {
        _;
    }

    modifier whenCallReverts() {
        _;
    }

    modifier whenFeeRecipientContract() {
        _;
    }

    modifier whenFlowCallNotRevert() {
        _;
    }

    modifier whenFunctionExists() {
        _;
    }

    modifier whenMinFeeUSDNotZero() {
        _;
    }

    modifier whenNewAdminNotSameAsCurrentAdmin() {
        _;
    }

    modifier whenNewFeeNotExceedMaxFee() {
        _;
    }

    modifier whenNewOracleNotZero() {
        _;
    }

    modifier whenNonStateChangingFunction() {
        _;
    }

    modifier whenNotPayable() {
        _;
    }

    modifier whenOraclePriceNotOutdated() {
        _;
    }

    modifier whenOraclePriceNotZero() {
        _;
    }

    modifier whenOracleUpdatedTimeNotInFuture() {
        _;
    }

    modifier whenPayable() {
        _;
    }

    modifier whenStateChangingFunction() {
        _;
    }

    modifier whenTargetContract() {
        _;
    }
}
