// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors } from "src/periphery/libraries/Errors.sol";

import { MerkleCampaign_Integration_Shared_Test } from "../MerkleCampaign.t.sol";

abstract contract Claim_Integration_Test is MerkleCampaign_Integration_Shared_Test {
    function setUp() public virtual override {
        MerkleCampaign_Integration_Shared_Test.setUp();
    }

    function test_RevertGiven_CampaignExpired() external {
        uint40 expiration = defaults.EXPIRATION();
        uint256 warpTime = expiration + 1 seconds;
        bytes32[] memory merkleProof;
        vm.warp({ newTimestamp: warpTime });
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierMerkleBase_CampaignExpired.selector, warpTime, expiration));
        merkleBase.claim({ index: 1, recipient: users.recipient1, amount: 1, merkleProof: merkleProof });
    }

    function test_RevertGiven_AlreadyClaimed() external givenCampaignNotExpired {
        claim();
        uint256 index1 = defaults.INDEX1();
        uint128 amount = defaults.CLAIM_AMOUNT();
        bytes32[] memory merkleProof = defaults.index1Proof();
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierMerkleBase_StreamClaimed.selector, index1));
        merkleBase.claim(index1, users.recipient1, amount, merkleProof);
    }

    function test_RevertWhen_InvalidIndex()
        external
        givenCampaignNotExpired
        givenNotClaimed
        givenNotIncludedInMerkleTree
    {
        uint256 invalidIndex = 1337;
        uint128 amount = defaults.CLAIM_AMOUNT();
        bytes32[] memory merkleProof = defaults.index1Proof();
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierMerkleBase_InvalidProof.selector));
        merkleBase.claim(invalidIndex, users.recipient1, amount, merkleProof);
    }

    function test_RevertWhen_InvalidRecipient()
        external
        givenCampaignNotExpired
        givenNotClaimed
        givenNotIncludedInMerkleTree
    {
        uint256 index1 = defaults.INDEX1();
        address invalidRecipient = address(1337);
        uint128 amount = defaults.CLAIM_AMOUNT();
        bytes32[] memory merkleProof = defaults.index1Proof();
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierMerkleBase_InvalidProof.selector));
        merkleBase.claim(index1, invalidRecipient, amount, merkleProof);
    }

    function test_RevertWhen_InvalidAmount()
        external
        givenCampaignNotExpired
        givenNotClaimed
        givenNotIncludedInMerkleTree
    {
        uint256 index1 = defaults.INDEX1();
        uint128 invalidAmount = 1337;
        bytes32[] memory merkleProof = defaults.index1Proof();
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierMerkleBase_InvalidProof.selector));
        merkleBase.claim(index1, users.recipient1, invalidAmount, merkleProof);
    }

    function test_RevertWhen_InvalidMerkleProof()
        external
        givenCampaignNotExpired
        givenNotClaimed
        givenNotIncludedInMerkleTree
    {
        uint256 index1 = defaults.INDEX1();
        uint128 amount = defaults.CLAIM_AMOUNT();
        bytes32[] memory invalidMerkleProof = defaults.index2Proof();
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierMerkleBase_InvalidProof.selector));
        merkleBase.claim(index1, users.recipient1, amount, invalidMerkleProof);
    }

    /// @dev Since the implementation of `_claim()` differs in each Merkle campaign, we declare this test as virtual and
    /// will be overridden in the Child contracts.
    function test_Claim() external virtual givenCampaignNotExpired givenNotClaimed givenIncludedInMerkleTree {
        // The child contract must check that the claim event is emitted.
        // It should also mark the index as claimed.
    }
}
