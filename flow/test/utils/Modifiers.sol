// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.20;

abstract contract Modifiers {
    /*//////////////////////////////////////////////////////////////////////////
                                       COMMON
    //////////////////////////////////////////////////////////////////////////*/

    modifier whenNotDelegateCalled() {
        _;
    }

    modifier givenNotNull() {
        _;
    }

    modifier givenNotCanceled() {
        _;
    }

    modifier whenAmountPerSecondNonZero() {
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

    modifier whenDepositAmountNonZero() {
        _;
    }
}
