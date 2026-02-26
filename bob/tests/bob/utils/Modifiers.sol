// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { BaseTest as EvmUtilsBase } from "@sablier/evm-utils/src/tests/BaseTest.sol";

import { Constants } from "./Constants.sol";

abstract contract Modifiers is Constants, EvmUtilsBase {
    /*//////////////////////////////////////////////////////////////////////////
                                       GIVEN
    //////////////////////////////////////////////////////////////////////////*/

    modifier givenACTIVE() {
        _;
    }

    modifier givenAdapter() {
        _;
    }

    modifier givenFirstDepositTimeNotZero() {
        _;
    }

    modifier givenNoAdapter() {
        _;
    }

    modifier givenNotACTIVE() {
        _;
    }

    modifier givenNotNull() {
        _;
    }

    modifier givenNotUnstaked() {
        _;
    }

    modifier givenSETTLED() {
        _;
    }

    modifier givenYieldTokenBalanceNotZero() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                        WHEN
    //////////////////////////////////////////////////////////////////////////*/

    modifier whenAmountNotZero() {
        _;
    }

    modifier whenCallerComptroller() {
        setMsgSender(address(comptroller));
        _;
    }

    modifier whenCallerVaultShareToken() {
        _;
    }

    modifier whenExpiryInFuture() {
        _;
    }

    modifier whenGraceEndTimeInFuture() {
        _;
    }

    modifier whenNewAdapterNotZeroAddress() {
        _;
    }

    modifier whenNotNativeToken() {
        _;
    }

    modifier whenProvidedAddressNotZero() {
        _;
    }

    modifier whenSharesNotZero() {
        _;
    }

    modifier whenTargetPriceExceedsOraclePrice() {
        _;
    }

    modifier whenTargetPriceNotZero() {
        _;
    }

    modifier whenTokenNotZero() {
        _;
    }
}
