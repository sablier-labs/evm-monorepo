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
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    function claim() internal {
        merkleBase.claim{ value: defaults.DEFAULT_SABLIER_FEE() }({
            index: defaults.INDEX1(),
            recipient: users.recipient1,
            amount: defaults.CLAIM_AMOUNT(),
            merkleProof: defaults.index1Proof()
        });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    modifier givenCampaignNotExpired() {
        _;
    }

    modifier givenSevenDaysPassed() {
        vm.warp({ newTimestamp: getBlockTimestamp() + 8 days });
        _;
    }

    modifier whenCallerAdmin() {
        resetPrank({ msgSender: users.admin });
        _;
    }

    modifier whenCallerCampaignOwner() {
        resetPrank({ msgSender: users.campaignOwner });
        _;
    }

    modifier whenExpirationNotZero() {
        _;
    }

    modifier whenFirstClaimMade() {
        // Reset the prank to the recipient to make the first claim.
        resetPrank({ msgSender: users.recipient });
        // Make the first claim to set `_firstClaimTime`.
        claim();

        // Reset the prank back to the campaign owner.
        resetPrank(users.campaignOwner);
        _;
    }

    modifier whenIndexInMerkleTree() {
        _;
    }

    modifier whenMerkleProofValid() {
        _;
    }
}
