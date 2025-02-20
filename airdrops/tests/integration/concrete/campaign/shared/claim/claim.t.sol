// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";

import { Integration_Test } from "../../../../Integration.t.sol";

abstract contract Claim_Integration_Test is Integration_Test {
    function test_RevertGiven_CampaignExpired() external {
        uint40 expiration = defaults.EXPIRATION();
        uint256 fee = defaults.MINIMUM_FEE();
        uint256 warpTime = expiration + 1 seconds;
        bytes32[] memory merkleProof;
        vm.warp({ newTimestamp: warpTime });
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierMerkleBase_CampaignExpired.selector, warpTime, expiration));
        merkleBase.claim{ value: fee }({ index: 1, recipient: users.recipient1, amount: 1, merkleProof: merkleProof });
    }

    function test_RevertGiven_MsgValueLessThanFee() external givenCampaignNotExpired {
        uint256 index1 = defaults.INDEX1();
        uint128 amount = defaults.CLAIM_AMOUNT();
        bytes32[] memory merkleProof = defaults.index1Proof();
        uint256 fee = defaults.MINIMUM_FEE();

        vm.expectRevert(abi.encodeWithSelector(Errors.SablierMerkleBase_InsufficientFeePayment.selector, 0, fee));
        merkleBase.claim{ value: 0 }(index1, users.recipient1, amount, merkleProof);
    }

    function test_RevertGiven_RecipientClaimed() external givenCampaignNotExpired givenMsgValueNotLessThanFee {
        claim();
        uint256 index1 = defaults.INDEX1();
        uint128 amount = defaults.CLAIM_AMOUNT();
        uint256 fee = defaults.MINIMUM_FEE();
        bytes32[] memory merkleProof = defaults.index1Proof();
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierMerkleBase_StreamClaimed.selector, index1));
        merkleBase.claim{ value: fee }(index1, users.recipient1, amount, merkleProof);
    }

    function test_RevertWhen_IndexNotValid()
        external
        givenCampaignNotExpired
        givenMsgValueNotLessThanFee
        givenRecipientNotClaimed
    {
        uint256 invalidIndex = 1337;
        uint128 amount = defaults.CLAIM_AMOUNT();
        uint256 fee = defaults.MINIMUM_FEE();
        bytes32[] memory merkleProof = defaults.index1Proof();
        vm.expectRevert(Errors.SablierMerkleBase_InvalidProof.selector);
        merkleBase.claim{ value: fee }(invalidIndex, users.recipient1, amount, merkleProof);
    }

    function test_RevertWhen_RecipientNotValid()
        external
        givenCampaignNotExpired
        givenMsgValueNotLessThanFee
        givenRecipientNotClaimed
        whenIndexValid
    {
        uint256 index1 = defaults.INDEX1();
        address invalidRecipient = address(1337);
        uint128 amount = defaults.CLAIM_AMOUNT();
        uint256 fee = defaults.MINIMUM_FEE();
        bytes32[] memory merkleProof = defaults.index1Proof();
        vm.expectRevert(Errors.SablierMerkleBase_InvalidProof.selector);
        merkleBase.claim{ value: fee }(index1, invalidRecipient, amount, merkleProof);
    }

    function test_RevertWhen_AmountNotValid()
        external
        givenCampaignNotExpired
        givenMsgValueNotLessThanFee
        givenRecipientNotClaimed
        whenIndexValid
        whenRecipientValid
    {
        uint256 index1 = defaults.INDEX1();
        uint128 invalidAmount = 1337;
        uint256 fee = defaults.MINIMUM_FEE();
        bytes32[] memory merkleProof = defaults.index1Proof();
        vm.expectRevert(Errors.SablierMerkleBase_InvalidProof.selector);
        merkleBase.claim{ value: fee }(index1, users.recipient1, invalidAmount, merkleProof);
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
        uint256 index1 = defaults.INDEX1();
        uint128 amount = defaults.CLAIM_AMOUNT();
        uint256 fee = defaults.MINIMUM_FEE();
        bytes32[] memory invalidMerkleProof = defaults.index2Proof();
        vm.expectRevert(Errors.SablierMerkleBase_InvalidProof.selector);
        merkleBase.claim{ value: fee }(index1, users.recipient1, amount, invalidMerkleProof);
    }

    /// @dev Since the implementation of `_claim()` differs in each Merkle campaign, we declare this dummy test and
    /// the Child contracts implement the actual claim test functions.
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
