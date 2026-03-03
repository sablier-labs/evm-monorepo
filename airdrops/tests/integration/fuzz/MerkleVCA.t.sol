// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ud, UD60x18, UNIT } from "@prb/math/src/UD60x18.sol";
import { ISablierComptroller } from "@sablier/evm-utils/src/interfaces/ISablierComptroller.sol";
import { ISablierFactoryMerkleVCA } from "src/interfaces/ISablierFactoryMerkleVCA.sol";
import { ISablierMerkleVCA } from "src/interfaces/ISablierMerkleVCA.sol";
import { Errors } from "src/libraries/Errors.sol";
import { MerkleVCA } from "src/types/MerkleVCA.sol";
import { LeafData } from "./../../utils/MerkleBuilder.sol";
import { Params } from "./../../utils/Types.sol";
import { Shared_Fuzz_Test, Integration_Test } from "./Fuzz.t.sol";

contract MerkleVCA_Fuzz_Test is Shared_Fuzz_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                 STATE-VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Track the amount claimed early.
    uint128 internal amountClaimedEarly;

    /// @dev Track the total forgone amount.
    uint128 internal totalForgoneAmount;

    /// @dev Track the total redistribution amount paid.
    uint128 internal totalRedistributionAmountPaid;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Integration_Test.setUp();

        // Cast the {FactoryMerkleVCA} contract as {ISablierFactoryMerkleBase}
        factoryMerkleBase = factoryMerkleVCA;

        // Set the campaign type.
        campaignType = "vca";
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Given enough fuzz runs, all possible values of claim time and full amount will be fuzzed. This test uses
    /// the instance of `merkleVCA` deployed in {Integration_Test}.
    function testFuzz_ClaimAndForgoneAmount(uint128 fullAmount, uint40 claimTime) external {
        uint128 actualClaimAmount = merkleVCA.calculateClaimAmount(fullAmount, claimTime);
        uint128 actualForgoneAmount;
        if (claimTime > 0 && claimTime < VCA_START_TIME) {
            vm.expectRevert(
                abi.encodeWithSelector(Errors.SablierMerkleVCA_VestingNotStarted.selector, claimTime, VCA_START_TIME)
            );
            merkleVCA.calculateForgoneAmount(fullAmount, claimTime);
            actualForgoneAmount = 0;
        } else {
            actualForgoneAmount = merkleVCA.calculateForgoneAmount(fullAmount, claimTime);
        }

        // Zero is used as a sentinel value for `block.timestamp`, so we warp to the claim time if it's greater than 0.
        if (claimTime > 0) {
            vm.warp({ newTimestamp: claimTime });
        }

        // Assert the claim and forgone amounts if vesting start time is in the future.
        if (getBlockTimestamp() < VCA_START_TIME) {
            assertEq(actualClaimAmount, 0, "claim amount before vesting start time");
            assertEq(actualForgoneAmount, 0, "forgone amount before vesting start time");
        }

        // Assert the claim and forgone amounts if vesting start time is in the present.
        if (getBlockTimestamp() == VCA_START_TIME) {
            uint128 unlockAmount = VCA_UNLOCK_PERCENTAGE.mul(ud(fullAmount)).intoUint128();

            assertEq(actualClaimAmount, unlockAmount, "claim amount at vesting start time");
            assertEq(actualForgoneAmount, fullAmount - unlockAmount, "forgone amount at vesting start time");
        }
        // Assert the claim and forgone amounts if vesting start time is in the past.
        else {
            // Assert the claim and forgone amounts if vesting end time is in the future.
            if (getBlockTimestamp() < VCA_END_TIME) {
                (uint128 expectedClaimAmount, uint128 expectedForgoneAmount) = calculateMerkleVCAAmounts({
                    fullAmount: fullAmount,
                    unlockPercentage: VCA_UNLOCK_PERCENTAGE,
                    vestingEndTime: VCA_END_TIME,
                    vestingStartTime: VCA_START_TIME
                });

                assertEq(actualClaimAmount, expectedClaimAmount, "claim amount before vesting end time");
                assertEq(actualForgoneAmount, expectedForgoneAmount, "forgone amount before end time");
            }
            // Assert the claim and forgone amounts if vesting end time is not in the future.
            else {
                assertEq(actualClaimAmount, fullAmount, "claim amount after vesting end time");
                assertEq(actualForgoneAmount, 0, "forgone amount after vesting end time");
            }
        }
    }

    /// @dev Given enough fuzz runs, all of the following scenarios will be fuzzed:
    ///
    /// - Fuzzed custom fee.
    /// - MerkleVCA campaign with fuzzed leaves data, expiration, vesting end and start times.
    /// - Unlock percentage does not exceed 1e18.
    /// - Finite (only in future) expiration.
    /// - Vesting start time in the past.
    /// - Claiming airdrops for multiple indexes with fuzzed claim fee.
    /// - Claiming airdrops using both {claim} and {claimTo} functions with fuzzed `to` address.
    /// - Fuzzed clawback amount.
    /// - Collect fees earned.
    function testFuzz_MerkleVCA(
        Params memory params,
        bool enableRedistribution,
        UD60x18 unlockPercentage,
        uint40 vestingEndTime,
        uint40 vestingStartTime
    )
        external
    {
        // Bound the fuzzed params and construct the Merkle tree.
        (uint128 aggregateAmount,, bytes32 merkleRoot) =
            prepareCommonCreateParams(params.rawLeavesData, params.expiration, params.indexesToClaim.length);

        // Bound expiration so that its not zero. Unlike other campaigns, MerkleVCA requires a non-zero expiration.
        params.expiration = boundUint40(params.expiration, getBlockTimestamp() + 365 days + 1 weeks, MAX_UNIX_TIMESTAMP);

        // Set the custom fee if enabled.
        if (params.enableCustomFeeUSD) {
            params.feeForUser = bound(params.feeForUser, 0, MAX_FEE_USD);
            setMsgSender(admin);
            comptroller.setCustomFeeUSDFor(
                ISablierComptroller.Protocol.Airdrops, users.campaignCreator, params.feeForUser
            );
        } else {
            params.feeForUser = AIRDROP_MIN_FEE_USD;
        }

        // Test creating the MerkleVCA campaign.
        _testCreateMerkleVCA(
            aggregateAmount,
            enableRedistribution,
            params.expiration,
            params.feeForUser,
            merkleRoot,
            unlockPercentage,
            vestingStartTime,
            vestingEndTime
        );

        // Test claiming the airdrop for the given indexes.
        testClaimMultipleAirdrops(params.indexesToClaim, params.msgValue, params.to);

        // Test clawback of funds.
        testClawback(params.clawbackAmount);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    CREATE-HELPER
    //////////////////////////////////////////////////////////////////////////*/

    function _testCreateMerkleVCA(
        uint128 aggregateAmount,
        bool enableRedistribution,
        uint40 expiration,
        uint256 feeForUser,
        bytes32 merkleRoot,
        UD60x18 unlockPercentage,
        uint40 vestingEndTime,
        uint40 vestingStartTime
    )
        private
        givenCampaignNotExists
        givenCampaignStartTimeNotInFuture
        whenUnlockPercentageNotGreaterThan100
        whenVestingStartTimeNotZero
        whenVestingEndTimeGreaterThanVestingStartTime
        whenExpirationNotZero
        whenExpirationExceedsOneWeekFromVestingEndTime
    {
        // Bound vesting start time to be in the past.
        vestingStartTime = boundUint40(vestingStartTime, 1 seconds, getBlockTimestamp() - 1 seconds);

        // Bound vesting end time to be greater than the vesting start time but within than a year from now.
        vestingEndTime = boundUint40(vestingEndTime, vestingStartTime + 1, getBlockTimestamp() + 365 days);

        // Bound unlock percentage to be less than or equal to 1e18.
        unlockPercentage = bound(unlockPercentage, 0, UNIT);

        // Set campaign creator as the caller.
        setMsgSender(users.campaignCreator);

        MerkleVCA.ConstructorParams memory params = merkleVCAConstructorParams(expiration);
        params.aggregateAmount = aggregateAmount;
        params.enableRedistribution = enableRedistribution;
        params.merkleRoot = merkleRoot;
        params.unlockPercentage = unlockPercentage;
        params.vestingEndTime = vestingEndTime;
        params.vestingStartTime = vestingStartTime;

        // Precompute the deterministic address.
        address expectedMerkleVCA = computeMerkleVCAAddress(params, users.campaignCreator);

        // Expect a {CreateMerkleVCA} event.
        vm.expectEmit({ emitter: address(factoryMerkleVCA) });
        emit ISablierFactoryMerkleVCA.CreateMerkleVCA({
            merkleVCA: ISablierMerkleVCA(expectedMerkleVCA),
            campaignParams: params,
            recipientCount: leavesData.length,
            comptroller: address(comptroller),
            minFeeUSD: feeForUser
        });

        // Create the campaign.
        merkleVCA = factoryMerkleVCA.createMerkleVCA(params, leavesData.length);

        // Verify that the contract is deployed at the correct address.
        assertGt(address(merkleVCA).code.length, 0, "MerkleVCA contract not created");
        assertEq(address(merkleVCA), expectedMerkleVCA, "MerkleVCA contract does not match computed address");

        // It should return false for hasExpired.
        assertFalse(merkleVCA.hasExpired(), "isExpired");

        // It should set the correct unlock percentage.
        assertEq(merkleVCA.UNLOCK_PERCENTAGE(), unlockPercentage, "unlock percentage");

        // It should set the correct vesting end time.
        assertEq(merkleVCA.VESTING_END_TIME(), vestingEndTime, "vesting end time");

        // It should set the correct vesting start time.
        assertEq(merkleVCA.VESTING_START_TIME(), vestingStartTime, "vesting start time");

        // Fund the MerkleVCA contract.
        deal({ token: address(dai), to: address(merkleVCA), give: aggregateAmount });

        // Cast the {MerkleVCA} contract as {ISablierMerkleBase}
        merkleBase = merkleVCA;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                CLAIM-EVENT-HELPER
    //////////////////////////////////////////////////////////////////////////*/

    function expectClaimEvent(LeafData memory leafData, address to) internal override {
        // Calculate claim and forgone amount based on the vesting start and end time.
        (uint128 claimAmount, uint128 forgoneAmount) = calculateMerkleVCAAmounts({
            fullAmount: leafData.amount,
            unlockPercentage: merkleVCA.UNLOCK_PERCENTAGE(),
            vestingEndTime: merkleVCA.VESTING_END_TIME(),
            vestingStartTime: merkleVCA.VESTING_START_TIME()
        });

        // Update the total forgone amount.
        totalForgoneAmount += forgoneAmount;

        // Update the amount claimed early if the vesting end time is in the future.
        if (getBlockTimestamp() < merkleVCA.VESTING_END_TIME()) {
            amountClaimedEarly += leafData.amount;
        }

        // Calculate the reward amount if vesting has ended and redistribution is enabled.
        uint128 expectedRewardAmount;
        if (getBlockTimestamp() >= merkleVCA.VESTING_END_TIME() && merkleVCA.isRedistributionEnabled()) {
            uint128 amountExpectedToClaimAfterVestingEndTime = merkleVCA.AGGREGATE_AMOUNT() - amountClaimedEarly;
            expectedRewardAmount =
                uint128((uint256(leafData.amount) * totalForgoneAmount) / amountExpectedToClaimAfterVestingEndTime);

            // Cap the reward to the remaining redistribution balance.
            uint128 remainingRedistributionBalance = totalForgoneAmount - totalRedistributionAmountPaid;
            if (expectedRewardAmount > remainingRedistributionBalance) {
                expectedRewardAmount = remainingRedistributionBalance;
            }

            // Update the total redistribution amount paid.
            totalRedistributionAmountPaid += expectedRewardAmount;

            // It should emit a {RedistributionReward} event if there are rewards to distribute.
            if (expectedRewardAmount > 0) {
                vm.expectEmit({ emitter: address(merkleVCA) });
                emit ISablierMerkleVCA.RedistributionReward({
                    index: leafData.index,
                    recipient: leafData.recipient,
                    amount: expectedRewardAmount,
                    to: to
                });
            }
        }

        // It should emit a {ClaimVCA} event.
        vm.expectEmit({ emitter: address(merkleVCA) });
        emit ISablierMerkleVCA.ClaimVCA({
            index: leafData.index,
            recipient: leafData.recipient,
            claimAmount: uint128(claimAmount),
            forgoneAmount: uint128(forgoneAmount),
            to: to,
            viaSig: false
        });

        // It should transfer the claim amount and reward amount (if any) to the `to` address.
        expectCallToTransfer({ token: dai, to: to, value: claimAmount + expectedRewardAmount });
    }
}
