// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { BaseTest as EvmUtilsBase } from "@sablier/evm-utils/src/tests/BaseTest.sol";

import { Constants } from "./Constants.sol";
import { Users } from "./Types.sol";

abstract contract Modifiers is Constants, EvmUtilsBase {
    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    Users internal users;

    function setVariables(Users memory _users) internal {
        users = _users;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                       GIVEN
    //////////////////////////////////////////////////////////////////////////*/

    modifier givenNativeTokenAlreadySet() {
        _;
    }

    modifier givenNativeTokenNotSet() {
        _;
    }

    modifier givenNotNull() {
        _;
    }

    modifier givenOPEN() {
        _;
    }

    modifier givenOrderWithDesignatedBuyer() {
        _;
    }

    modifier givenOrderWithoutDesignatedBuyer() {
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                        WHEN
    //////////////////////////////////////////////////////////////////////////*/

    modifier whenBuyAmountNotLessThanMinBuyAmount() {
        _;
    }

    modifier whenBuyTokenNotNativeToken() {
        _;
    }

    modifier whenBuyTokenNotZero() {
        _;
    }

    modifier whenCallerComptroller() {
        setMsgSender(address(comptroller));
        _;
    }

    modifier whenCallerSeller() {
        setMsgSender(users.seller);
        _;
    }

    modifier whenExpiryTimeInFuture() {
        _;
    }

    modifier whenExpiryTimeNotZero() {
        _;
    }

    modifier whenMinBuyAmountNotZero() {
        _;
    }

    modifier whenProvidedAddressNotZero() {
        _;
    }

    modifier whenSellAmountNotZero() {
        _;
    }

    modifier whenSellTokenNotNativeToken() {
        _;
    }

    modifier whenSellTokenNotZero() {
        _;
    }

    modifier whenTokensNotSame() {
        _;
    }
}
