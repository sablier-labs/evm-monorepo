// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../../../Integration.t.sol";

abstract contract Claim_Integration_Test is Integration_Test {
    function test_RevertGiven_CampaignStartTimeInFuture() external {
        uint40 warpTime = CAMPAIGN_START_TIME - 1 seconds;
        vm.warp({ newTimestamp: warpTime });

        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierMerkleBase_CampaignNotStarted.selector, warpTime, CAMPAIGN_START_TIME)
        );
        claim();
    }

    function test_RevertGiven_CampaignExpired() external givenCampaignStartTimeNotInFuture {
        uint40 warpTime = EXPIRATION + 1 seconds;
        vm.warp({ newTimestamp: warpTime });

        vm.expectRevert(abi.encodeWithSelector(Errors.SablierMerkleBase_CampaignExpired.selector, warpTime, EXPIRATION));
        claim();
    }

    function test_RevertGiven_MsgValueLessThanFee()
        external
        givenCampaignStartTimeNotInFuture
        givenCampaignNotExpired
    {
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierMerkleBase_InsufficientFeePayment.selector, 0, AIRDROP_MIN_FEE_WEI)
        );
        claim({
            msgValue: 0,
            index: getIndexInMerkleTree(),
            recipient: users.recipient,
            amount: CLAIM_AMOUNT,
            merkleProof: getMerkleProof()
        });
    }

    function test_RevertGiven_RecipientClaimed()
        external
        givenCampaignStartTimeNotInFuture
        givenCampaignNotExpired
        givenMsgValueNotLessThanFee
    {
        claim();

        vm.expectRevert(abi.encodeWithSelector(Errors.SablierMerkleBase_IndexClaimed.selector, getIndexInMerkleTree()));
        claim();
    }

    function test_RevertWhen_IndexNotValid()
        external
        givenCampaignStartTimeNotInFuture
        givenCampaignNotExpired
        givenMsgValueNotLessThanFee
        givenRecipientNotClaimed
    {
        uint256 invalidIndex = 1337;

        vm.expectRevert(Errors.SablierMerkleBase_InvalidProof.selector);
        claim({
            msgValue: AIRDROP_MIN_FEE_WEI,
            index: invalidIndex,
            recipient: users.recipient,
            amount: CLAIM_AMOUNT,
            merkleProof: getMerkleProof()
        });
    }

    function test_RevertWhen_RecipientNotEligible()
        external
        givenCampaignStartTimeNotInFuture
        givenCampaignNotExpired
        givenMsgValueNotLessThanFee
        givenRecipientNotClaimed
        whenIndexValid
    {
        address invalidRecipient = address(1337);

        vm.expectRevert(Errors.SablierMerkleBase_InvalidProof.selector);
        claim({
            msgValue: AIRDROP_MIN_FEE_WEI,
            index: getIndexInMerkleTree(),
            recipient: invalidRecipient,
            amount: CLAIM_AMOUNT,
            merkleProof: getMerkleProof()
        });
    }

    function test_RevertWhen_AmountNotValid()
        external
        givenCampaignStartTimeNotInFuture
        givenCampaignNotExpired
        givenMsgValueNotLessThanFee
        givenRecipientNotClaimed
        whenIndexValid
        whenRecipientEligible
    {
        uint128 invalidAmount = 1337;

        vm.expectRevert(Errors.SablierMerkleBase_InvalidProof.selector);
        claim({
            msgValue: AIRDROP_MIN_FEE_WEI,
            index: getIndexInMerkleTree(),
            recipient: users.recipient,
            amount: invalidAmount,
            merkleProof: getMerkleProof()
        });
    }

    function test_RevertWhen_MerkleProofNotValid()
        external
        givenCampaignStartTimeNotInFuture
        givenCampaignNotExpired
        givenMsgValueNotLessThanFee
        givenRecipientNotClaimed
        whenIndexValid
        whenRecipientEligible
        whenAmountValid
    {
        vm.expectRevert(Errors.SablierMerkleBase_InvalidProof.selector);
        claim({
            msgValue: AIRDROP_MIN_FEE_WEI,
            index: getIndexInMerkleTree(),
            recipient: users.recipient,
            amount: CLAIM_AMOUNT,
            merkleProof: getMerkleProof(users.unknownRecipient)
        });
    }

    /// @dev Since the implementation of `claim()` differs in each Merkle campaign, we declare this virtual dummy test.
    /// The child contracts implement it.
    function test_WhenMerkleProofValid()
        external
        virtual
        givenCampaignStartTimeNotInFuture
        givenCampaignNotExpired
        givenMsgValueNotLessThanFee
        givenRecipientNotClaimed
        whenIndexValid
        whenRecipientEligible
        whenAmountValid
    {
        // The child contract must check that the claim event is emitted.
        // It should mark the index as claimed.
        // It should transfer the fee from the caller address to the merkle lockup.
    }
}
