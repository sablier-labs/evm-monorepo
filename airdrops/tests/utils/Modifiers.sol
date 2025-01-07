// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { Defaults } from "./Defaults.sol";
import { Users } from "./Types.sol";

import { Utils } from "./Utils.sol";

abstract contract Modifiers is Utils {
    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    Defaults private defaults;
    Users private users;

    function setVariables(Defaults _defaults, Users memory _users) public {
        defaults = _defaults;
        users = _users;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                       GIVEN
    //////////////////////////////////////////////////////////////////////////*/

    modifier givenCampaignNotExists() {
        _;
    }

    modifier givenCampaignNotExpired() {
        _;
    }

    modifier givenMsgValueNotLessThanFee() {
        _;
    }

    modifier givenRecipientNotClaimed() {
        _;
    }

    modifier givenSevenDaysPassed() {
        vm.warp({ newTimestamp: getBlockTimestamp() + 8 days });
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                        WHEN
    //////////////////////////////////////////////////////////////////////////*/

    modifier whenAmountValid() {
        _;
    }

    modifier whenCallerAdmin() {
        // Make the Admin the caller in the rest of this test suite.
        resetPrank({ msgSender: users.admin });
        _;
    }

    modifier whenCallerCampaignOwner() {
        resetPrank({ msgSender: users.campaignOwner });
        _;
    }

    modifier whenCampaignNameNotExceed32Bytes() {
        _;
    }

    modifier whenExpirationNotZero() {
        _;
    }

    modifier whenFactoryAdminIsContract() {
        _;
    }

    modifier whenIndexInMerkleTree() {
        _;
    }

    modifier whenIndexValid() {
        _;
    }

    modifier whenMerkleProofValid() {
        _;
    }

    modifier whenPercentagesSumNot100Pct() {
        _;
    }

    modifier whenProvidedMerkleLockupValid() {
        _;
    }

    modifier whenRecipientValid() {
        _;
    }

    modifier whenScheduledStartTimeZero() {
        _;
    }

    modifier whenShapeNotExceed32Bytes() {
        _;
    }

    modifier whenTotalPercentage100() {
        _;
    }

    modifier whenTotalPercentageNot100() {
        _;
    }

    modifier whenTotalPercentageNotGreaterThan100() {
        _;
    }

    modifier whenWithdrawalAddressNotZero() {
        _;
    }
}
