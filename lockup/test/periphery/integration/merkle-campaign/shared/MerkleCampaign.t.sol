// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22;

import { ISablierMerkleBase } from "src/periphery/interfaces/ISablierMerkleBase.sol";

import { MerkleCampaign_Integration_Test } from "../MerkleCampaign.t.sol";

abstract contract MerkleCampaign_Integration_Shared_Test is MerkleCampaign_Integration_Test {
    /// @dev A test contract meant to be overridden by the implementing contract, which will be either
    /// {SablierMerkleLL}, {SablierMerkleLT} or {SablierMerkleInstant}.
    ISablierMerkleBase internal merkleBase;

    function setUp() public virtual override {
        MerkleCampaign_Integration_Test.setUp();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev A shared modifier meant to be overridden by the implementing test contracts.
    modifier afterFirstClaim() virtual {
        _;
    }

    modifier createMerkleCampaignWithZeroExpiry() virtual {
        _;
    }

    modifier givenCampaignExpired() {
        vm.warp({ newTimestamp: defaults.EXPIRATION() + 1 seconds });
        _;
    }

    modifier givenExpirationNotZero() {
        _;
    }

    modifier givenRecipientHasClaimed() virtual {
        _;
    }

    modifier postGracePeriod() {
        vm.warp({ newTimestamp: getBlockTimestamp() + 8 days });
        _;
    }

    modifier whenCallerAdmin() {
        resetPrank({ msgSender: users.admin });
        _;
    }

    modifier whenIndexInTree() {
        _;
    }
}
