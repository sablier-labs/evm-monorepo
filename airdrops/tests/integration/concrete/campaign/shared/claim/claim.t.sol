// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../../../Integration.t.sol";

abstract contract Claim_Integration_Test is Integration_Test {
    function test_RevertGiven_CampaignExpired() external {
        uint256 warpTime = EXPIRATION + 1 seconds;
        bytes32[] memory merkleProof;
        vm.warp({ newTimestamp: warpTime });
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierMerkleBase_CampaignExpired.selector, warpTime, EXPIRATION));
        merkleBase.claim{ value: MIN_FEE_WEI }({
            index: 1,
            recipient: users.recipient1,
            amount: 1,
            merkleProof: merkleProof
        });
    }

    function test_RevertGiven_MsgValueLessThanFee() external givenCampaignNotExpired {
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierMerkleBase_InsufficientFeePayment.selector, 0, MIN_FEE_WEI)
        );
        merkleBase.claim{ value: 0 }(INDEX1, users.recipient1, CLAIM_AMOUNT, index1Proof());
    }

    function test_RevertGiven_RecipientClaimed() external givenCampaignNotExpired givenMsgValueNotLessThanFee {
        claim();
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierMerkleBase_IndexClaimed.selector, INDEX1));
        merkleBase.claim{ value: MIN_FEE_WEI }(INDEX1, users.recipient1, CLAIM_AMOUNT, index1Proof());
    }

    function test_RevertWhen_IndexNotValid()
        external
        givenCampaignNotExpired
        givenMsgValueNotLessThanFee
        givenRecipientNotClaimed
    {
        uint256 invalidIndex = 1337;
        vm.expectRevert(Errors.SablierMerkleBase_InvalidProof.selector);
        merkleBase.claim{ value: MIN_FEE_WEI }(invalidIndex, users.recipient1, CLAIM_AMOUNT, index1Proof());
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
        merkleBase.claim{ value: MIN_FEE_WEI }(INDEX1, invalidRecipient, CLAIM_AMOUNT, index1Proof());
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
        merkleBase.claim{ value: MIN_FEE_WEI }(INDEX1, users.recipient1, invalidAmount, index1Proof());
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
        merkleBase.claim{ value: MIN_FEE_WEI }(INDEX1, users.recipient1, CLAIM_AMOUNT, index2Proof());
    }

    /// @dev Since the implementation of `_claim()` differs in each Merkle campaign, we declare this dummy test. The
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
