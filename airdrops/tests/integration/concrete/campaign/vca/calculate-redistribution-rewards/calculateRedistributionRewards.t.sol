// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Errors } from "src/libraries/Errors.sol";
import { MerkleVCA } from "src/types/MerkleVCA.sol";

import { MerkleVCA_Integration_Shared_Test } from "../MerkleVCA.t.sol";

contract CalculateRedistributionRewards_MerkleVCA_Integration_Concrete_Test is MerkleVCA_Integration_Shared_Test {
    function setUp() public override {
        MerkleVCA_Integration_Shared_Test.setUp();

        // Warp to campaign start time.
        vm.warp({ newTimestamp: CAMPAIGN_START_TIME });
    }

    function test_RevertGiven_RedistributionNotEnabled() external {
        // It should revert.
        vm.expectRevert(Errors.SablierMerkleVCA_RedistributionNotEnabled.selector);
        merkleVCA.calculateRedistributionRewards(VCA_FULL_AMOUNT);
    }

    function test_GivenTotalForgoneAmountZero() external givenRedistributionEnabled(merkleVCA) {
        // It should have zero total forgone amount.
        assertEq(merkleVCA.totalForgoneAmount(), 0, "total forgone amount");

        // It should return zero.
        assertEq(merkleVCA.calculateRedistributionRewards(VCA_FULL_AMOUNT), 0, "rewards");
    }

    function test_GivenAggregateAmountUndervalued()
        external
        givenRedistributionEnabled(merkleVCA)
        givenTotalForgoneAmountNotZero
    {
        // Create a new campaign with aggregate amount less than the actual aggregate amount.
        MerkleVCA.ConstructorParams memory params = merkleVCAConstructorParams();
        params.aggregateAmount = VCA_FULL_AMOUNT - 1;
        merkleVCA = createMerkleVCA(params);
        merkleBase = merkleVCA;

        // Enable the redistribution on new campaign.
        merkleVCA.enableRedistribution();

        // Claim early so that there is some forgone amount.
        setMsgSender(users.recipient);
        claimTo({
            msgValue: AIRDROP_MIN_FEE_WEI,
            index: getIndexInMerkleTree(),
            to: users.recipient,
            amount: CLAIM_AMOUNT,
            merkleProof: getMerkleProof()
        });

        // It should have non-zero total forgone amount.
        assertGt(merkleVCA.totalForgoneAmount(), 0, "total forgone amount");

        // It should return zero.
        assertEq(merkleVCA.calculateRedistributionRewards(VCA_FULL_AMOUNT), 0, "rewards");
    }

    function test_GivenAggregateAmountNotUndervalued()
        external
        givenRedistributionEnabled(merkleVCA)
        givenTotalForgoneAmountNotZero
    {
        // Claim early so that there is some forgone amount.
        setMsgSender(users.recipient);
        claimTo({
            msgValue: AIRDROP_MIN_FEE_WEI,
            index: getIndexInMerkleTree(),
            to: users.recipient,
            amount: CLAIM_AMOUNT,
            merkleProof: getMerkleProof()
        });

        // It should return correct value.
        assertEq(merkleVCA.calculateRedistributionRewards(VCA_FULL_AMOUNT), VCA_REWARD_AMOUNT_PER_USER, "rewards");
    }
}
