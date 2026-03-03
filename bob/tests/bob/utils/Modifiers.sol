// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { BaseTest as EvmUtilsBase } from "@sablier/evm-utils/src/tests/BaseTest.sol";

import { Constants } from "./Constants.sol";

abstract contract Modifiers is Constants, EvmUtilsBase {
    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    address internal bob_;

    function setBob(address _bob) internal {
        bob_ = _bob;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                       GIVEN
    //////////////////////////////////////////////////////////////////////////*/

    modifier givenACTIVEStatus() {
        _;
    }

    modifier givenAdapter() {
        _;
    }

    modifier givenNoAdapter() {
        _;
    }

    modifier givenNotACTIVEStatus() {
        _;
    }

    modifier givenNotNull() {
        _;
    }

    modifier givenNotUnstaked() {
        _;
    }

    modifier givenSETTLEDStatus() {
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

    modifier whenCallerBob() {
        setMsgSender(bob_);
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

    modifier whenSyncChangesStatus() {
        _;
    }

    modifier whenSyncNotChangeStatus() {
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
