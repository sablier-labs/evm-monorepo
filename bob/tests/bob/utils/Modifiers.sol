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

    modifier givenAmountExceedsMaxPerRequest() {
        _;
    }

    modifier givenTotalScaledBalanceNotZero() {
        _;
    }

    modifier givenTotalTokensReceivedNotZero() {
        _;
    }

    modifier givenAmountExceedsMinPerRequest() {
        _;
    }

    modifier givenCurveWithdrawalRequested() {
        _;
    }

    modifier givenLidoWithdrawalNotRequested() {
        _;
    }

    modifier givenNoAdapter() {
        _;
    }

    modifier givenNotAlreadyUnstaked() {
        _;
    }

    modifier givenNotACTIVEStatus() {
        // Use expiry as a proxy to non-active status.
        vm.warp(EXPIRY);
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

    modifier givenTotalWETHNotZero() {
        _;
    }

    modifier givenTotalWstETHNotZero() {
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

    modifier whenMsgValueNotZero() {
        _;
    }

    modifier whenMsgValueZero() {
        _;
    }

    modifier whenNewAdapterNotZeroAddress() {
        _;
    }

    modifier whenNotNativeToken() {
        _;
    }

    modifier whenOraclePriceNotZero() {
        _;
    }

    modifier whenProvidedAddressNotZero() {
        _;
    }

    modifier whenSharesNotZero() {
        _;
    }

    modifier whenSlippageToleranceNotExceedMax() {
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

    modifier whenTokenWETH() {
        _;
    }

    modifier whenUserShareBalanceNotZero() {
        _;
    }
}
