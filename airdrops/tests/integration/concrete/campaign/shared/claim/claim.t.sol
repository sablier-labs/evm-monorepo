// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../../../Integration.t.sol";

abstract contract Claim_Integration_Test is Integration_Test {
    function test_RevertGiven_CampaignExpired() external {
        uint256 warpTime = EXPIRATION + 1 seconds;
        vm.warp({ newTimestamp: warpTime });

        vm.expectRevert(abi.encodeWithSelector(Errors.SablierMerkleBase_CampaignExpired.selector, warpTime, EXPIRATION));
        claim();
    }

    function test_RevertGiven_MsgValueLessThanFee() external givenCampaignNotExpired {
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierMerkleBase_InsufficientFeePayment.selector, 0, MIN_FEE_WEI)
        );
        claim({
            msgValue: 0,
            index: INDEX1,
            recipient: users.recipient1,
            amount: CLAIM_AMOUNT,
            merkleProof: index1Proof()
        });
    }

    function test_RevertGiven_RecipientClaimed() external givenCampaignNotExpired givenMsgValueNotLessThanFee {
        claim();

        vm.expectRevert(abi.encodeWithSelector(Errors.SablierMerkleBase_IndexClaimed.selector, INDEX1));
        claim();
    }

    function test_RevertWhen_IndexNotValid()
        external
        givenCampaignNotExpired
        givenMsgValueNotLessThanFee
        givenRecipientNotClaimed
    {
        uint256 invalidIndex = 1337;

        vm.expectRevert(Errors.SablierMerkleBase_InvalidProof.selector);
        claim({
            msgValue: MIN_FEE_WEI,
            index: invalidIndex,
            recipient: users.recipient1,
            amount: CLAIM_AMOUNT,
            merkleProof: index1Proof()
        });
    }

    function test_RevertWhen_RecipientNotValid()
        external
        givenCampaignNotExpired
        givenMsgValueNotLessThanFee
        givenRecipientNotClaimed
        whenIndexValid
    {
        address invalidRecipient = address(1337);

        vm.expectRevert(Errors.SablierMerkleBase_InvalidProof.selector);
        claim({
            msgValue: MIN_FEE_WEI,
            index: INDEX1,
            recipient: invalidRecipient,
            amount: CLAIM_AMOUNT,
            merkleProof: index1Proof()
        });
    }

    function test_RevertWhen_AmountNotValid()
        external
        givenCampaignNotExpired
        givenMsgValueNotLessThanFee
        givenRecipientNotClaimed
        whenIndexValid
        whenRecipientValid
    {
        uint128 invalidAmount = 1337;

        vm.expectRevert(Errors.SablierMerkleBase_InvalidProof.selector);
        claim({
            msgValue: MIN_FEE_WEI,
            index: INDEX1,
            recipient: users.recipient1,
            amount: invalidAmount,
            merkleProof: index1Proof()
        });
    }

    function test_RevertWhen_MerkleProofNotValid()
        external
        givenCampaignNotExpired
        givenMsgValueNotLessThanFee
        givenRecipientNotClaimed
        whenIndexValid
        whenRecipientValid
        whenAmountValid
    {
        vm.expectRevert(Errors.SablierMerkleBase_InvalidProof.selector);
        claim({
            msgValue: MIN_FEE_WEI,
            index: INDEX1,
            recipient: users.recipient1,
            amount: CLAIM_AMOUNT,
            merkleProof: index2Proof()
        });
    }

    /// @dev Since the implementation of `claim()` differs in each Merkle campaign, we declare this dummy test. The
    /// child contracts implement the rest of the tests.
    function test_WhenMerkleProofValid()
        external
        givenCampaignNotExpired
        givenMsgValueNotLessThanFee
        givenRecipientNotClaimed
        whenIndexValid
        whenRecipientValid
        whenAmountValid
    {
        // The child contract must check that the claim event is emitted.
        // It should mark the index as claimed.
        // It should transfer the fee from the caller address to the merkle lockup.
    }
}
