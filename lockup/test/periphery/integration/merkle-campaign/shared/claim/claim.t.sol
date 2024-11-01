// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors } from "src/periphery/libraries/Errors.sol";

import { MerkleCampaign_Integration_Test } from "../../MerkleCampaign.t.sol";

abstract contract Claim_Integration_Test is MerkleCampaign_Integration_Test {
    function test_RevertGiven_CampaignExpired() external {
        uint40 expiration = defaults.EXPIRATION();
        uint256 sablierFee = defaults.DEFAULT_SABLIER_FEE();
        uint256 warpTime = expiration + 1 seconds;
        bytes32[] memory merkleProof;
        vm.warp({ newTimestamp: warpTime });
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierMerkleBase_CampaignExpired.selector, warpTime, expiration));
        merkleBase.claim{ value: sablierFee }({
            index: 1,
            recipient: users.recipient1,
            amount: 1,
            merkleProof: merkleProof
        });
    }

    function test_RevertGiven_MsgValueLessThanSablierFee() external givenCampaignNotExpired {
        uint256 index1 = defaults.INDEX1();
        uint128 amount = defaults.CLAIM_AMOUNT();
        bytes32[] memory merkleProof = defaults.index1Proof();
        uint256 sablierFee = defaults.DEFAULT_SABLIER_FEE();

        vm.expectRevert(abi.encodeWithSelector(Errors.SablierMerkleBase_InsufficientFeePayment.selector, 0, sablierFee));
        merkleBase.claim{ value: 0 }(index1, users.recipient1, amount, merkleProof);
    }

    function test_RevertGiven_RecipientClaimed() external givenCampaignNotExpired givenMsgValueNotLessThanSablierFee {
        claim();
        uint256 index1 = defaults.INDEX1();
        uint128 amount = defaults.CLAIM_AMOUNT();
        uint256 sablierFee = defaults.DEFAULT_SABLIER_FEE();
        bytes32[] memory merkleProof = defaults.index1Proof();
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierMerkleBase_StreamClaimed.selector, index1));
        merkleBase.claim{ value: sablierFee }(index1, users.recipient1, amount, merkleProof);
    }

    function test_RevertWhen_IndexNotValid()
        external
        givenCampaignNotExpired
        givenMsgValueNotLessThanSablierFee
        givenRecipientNotClaimed
    {
        uint256 invalidIndex = 1337;
        uint128 amount = defaults.CLAIM_AMOUNT();
        uint256 sablierFee = defaults.DEFAULT_SABLIER_FEE();
        bytes32[] memory merkleProof = defaults.index1Proof();
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierMerkleBase_InvalidProof.selector));
        merkleBase.claim{ value: sablierFee }(invalidIndex, users.recipient1, amount, merkleProof);
    }

    function test_RevertWhen_RecipientNotValid()
        external
        givenCampaignNotExpired
        givenMsgValueNotLessThanSablierFee
        givenRecipientNotClaimed
        whenIndexValid
    {
        uint256 index1 = defaults.INDEX1();
        address invalidRecipient = address(1337);
        uint128 amount = defaults.CLAIM_AMOUNT();
        uint256 sablierFee = defaults.DEFAULT_SABLIER_FEE();
        bytes32[] memory merkleProof = defaults.index1Proof();
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierMerkleBase_InvalidProof.selector));
        merkleBase.claim{ value: sablierFee }(index1, invalidRecipient, amount, merkleProof);
    }

    function test_RevertWhen_AmountNotValid()
        external
        givenCampaignNotExpired
        givenMsgValueNotLessThanSablierFee
        givenRecipientNotClaimed
        whenIndexValid
        whenRecipientValid
    {
        uint256 index1 = defaults.INDEX1();
        uint128 invalidAmount = 1337;
        uint256 sablierFee = defaults.DEFAULT_SABLIER_FEE();
        bytes32[] memory merkleProof = defaults.index1Proof();
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierMerkleBase_InvalidProof.selector));
        merkleBase.claim{ value: sablierFee }(index1, users.recipient1, invalidAmount, merkleProof);
    }

    function test_RevertWhen_MerkleProofNotValid()
        external
        givenCampaignNotExpired
        givenMsgValueNotLessThanSablierFee
        givenRecipientNotClaimed
        whenIndexValid
        whenRecipientValid
        whenAmountValid
    {
        uint256 index1 = defaults.INDEX1();
        uint128 amount = defaults.CLAIM_AMOUNT();
        uint256 sablierFee = defaults.DEFAULT_SABLIER_FEE();
        bytes32[] memory invalidMerkleProof = defaults.index2Proof();
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierMerkleBase_InvalidProof.selector));
        merkleBase.claim{ value: sablierFee }(index1, users.recipient1, amount, invalidMerkleProof);
    }

    /// @dev Since the implementation of `_claim()` differs in each Merkle campaign, we declare this dummy test and
    /// the Child contracts implement the actual claim test functions.
    function test_WhenMerkleProofValid()
        external
        givenCampaignNotExpired
        givenMsgValueNotLessThanSablierFee
        givenRecipientNotClaimed
        whenIndexValid
        whenRecipientValid
        whenAmountValid
    {
        // The child contract must check that the claim event is emitted.
        // It should mark the index as claimed.
        // It should transfer the sablier fee from the caller address to the merkle lockup.
    }
}
