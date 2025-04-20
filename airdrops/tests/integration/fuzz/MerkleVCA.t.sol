// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ud, UD60x18, UNIT } from "@prb/math/src/UD60x18.sol";
import { ISablierFactoryMerkleVCA } from "src/interfaces/ISablierFactoryMerkleVCA.sol";
import { ISablierMerkleVCA } from "src/interfaces/ISablierMerkleVCA.sol";
import { MerkleVCA } from "src/types/DataTypes.sol";

import { LeafData } from "../../utils/MerkleBuilder.sol";
import { Shared_Fuzz_Test, Integration_Test } from "./Fuzz.t.sol";

contract MerkleVCA_Fuzz_Test is Shared_Fuzz_Test {
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
        uint128 actualForgoneAmount = merkleVCA.calculateForgoneAmount(fullAmount, claimTime);

        // Because zero is the sentinel value for `block.timestamp`, warp to the claim time if its not 0.
        if (claimTime > 0) {
            vm.warp({ newTimestamp: claimTime });
        }

        // Assert the claim and forgone amounts if start time is in the future.
        if (getBlockTimestamp() < VCA_START_TIME) {
            assertEq(actualClaimAmount, 0, "claim amount before start time");
            assertEq(actualForgoneAmount, 0, "forgone amount before start time");
        }

        // Assert the claim and forgone amounts if start time is in the present.
        if (getBlockTimestamp() == VCA_START_TIME) {
            uint128 unlockAmount = VCA_UNLOCK_PERCENTAGE.mul(ud(fullAmount)).intoUint128();

            assertEq(actualClaimAmount, unlockAmount, "claim amount at start time");
            assertEq(actualForgoneAmount, fullAmount - unlockAmount, "forgone amount at start time");
        }
        // Assert the claim and forgone amounts if start time is in the past.
        else {
            // Assert the claim and forgone amounts if end time is in the future.
            if (getBlockTimestamp() < VCA_END_TIME) {
                (uint128 expectedClaimAmount, uint128 expectedForgoneAmount) = calculateMerkleVCAAmounts({
                    fullAmount: fullAmount,
                    unlockPercentage: VCA_UNLOCK_PERCENTAGE,
                    endTime: VCA_END_TIME,
                    startTime: VCA_START_TIME
                });

                assertEq(actualClaimAmount, expectedClaimAmount, "claim amount before end time");
                assertEq(actualForgoneAmount, expectedForgoneAmount, "forgone amount before end time");
            }
            // Assert the claim and forgone amounts if end time is not in the future.
            else {
                assertEq(actualClaimAmount, fullAmount, "claim amount after end time");
                assertEq(actualForgoneAmount, 0, "forgone amount after end time");
            }
        }
    }

    /// @dev Given enough fuzz runs, all of the following scenarios will be fuzzed:
    ///
    /// - Fuzzed custom fee.
    /// - MerkleVCA campaign with fuzzed leaves data, expiration, end time and start time.
    /// - Unlock percentage does not exceed 1e18.
    /// - Finite (only in future) expiration.
    /// - Start time in the past.
    /// - Claiming airdrops for multiple indexes with fuzzed claim fee.
    /// - Fuzzed clawback amount.
    /// - Collect fees earned.
    function testFuzz_MerkleVCA(
        uint128 clawbackAmount,
        bool enableCustomFeeUSD,
        uint40 endTime,
        uint40 expiration,
        uint256 feeForUser,
        uint256[] memory indexesToClaim,
        uint256 msgValue,
        LeafData[] memory rawLeavesData,
        uint40 startTime,
        UD60x18 unlockPercentage
    )
        external
    {
        // Bound the fuzzed params and construct the Merkle tree.
        (uint256 aggregateAmount,, bytes32 merkleRoot) =
            prepareCommonCreateParams(rawLeavesData, expiration, indexesToClaim.length);

        // Bound expiration so that its not zero. Unlike other campaigns, MerkleVCA requires a non-zero expiration.
        expiration = boundUint40(expiration, getBlockTimestamp() + 365 days + 1 weeks, MAX_UNIX_TIMESTAMP);

        // Set the custom fee if enabled.
        feeForUser = enableCustomFeeUSD ? testSetCustomFeeUSD(feeForUser) : MIN_FEE_USD;

        // Test creating the MerkleVCA campaign.
        _testCreateMerkleVCA(aggregateAmount, endTime, expiration, feeForUser, merkleRoot, startTime, unlockPercentage);

        // Test claiming the airdrop for the given indexes.
        testClaimMultipleAirdrops(indexesToClaim, msgValue);

        // Test clawback of funds.
        testClawback(clawbackAmount);

        // Test collecting fees earned.
        testCollectFees();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    CREATE-HELPER
    //////////////////////////////////////////////////////////////////////////*/

    function _testCreateMerkleVCA(
        uint256 aggregateAmount,
        uint40 endTime,
        uint40 expiration,
        uint256 feeForUser,
        bytes32 merkleRoot,
        uint40 startTime,
        UD60x18 unlockPercentage
    )
        private
        givenCampaignNotExists
        whenUnlockPercentageNotGreaterThan100
        whenStartTimeNotZero
        whenEndTimeGreaterThanStartTime
        whenNotZeroExpiration
        whenExpirationExceedsOneWeekFromEndTime
    {
        // Bound start time to be in the past.
        startTime = boundUint40(startTime, 1 seconds, getBlockTimestamp() - 1 seconds);

        // Bound end time to be greater than the start time but within than a year from now.
        endTime = boundUint40(endTime, startTime + 1, getBlockTimestamp() + 365 days);

        // Bound unlock percentage to be less than or equal to 1e18.
        unlockPercentage = bound(unlockPercentage, 0, UNIT);

        // Set campaign creator as the caller.
        setMsgSender(users.campaignCreator);

        MerkleVCA.ConstructorParams memory params = merkleVCAConstructorParams(expiration);
        params.merkleRoot = merkleRoot;
        params.endTime = endTime;
        params.startTime = startTime;
        params.unlockPercentage = unlockPercentage;

        // Precompute the deterministic address.
        address expectedMerkleVCA = computeMerkleVCAAddress(params, users.campaignCreator);

        // Expect a {CreateMerkleVCA} event.
        vm.expectEmit({ emitter: address(factoryMerkleVCA) });
        emit ISablierFactoryMerkleVCA.CreateMerkleVCA({
            merkleVCA: ISablierMerkleVCA(expectedMerkleVCA),
            params: params,
            aggregateAmount: aggregateAmount,
            recipientCount: leavesData.length,
            minFeeUSD: feeForUser,
            oracle: address(oracle)
        });

        // Create the campaign.
        merkleVCA = factoryMerkleVCA.createMerkleVCA(params, aggregateAmount, leavesData.length);

        // Verify that the contract is deployed at the correct address.
        assertGt(address(merkleVCA).code.length, 0, "MerkleVCA contract not created");
        assertEq(address(merkleVCA), expectedMerkleVCA, "MerkleVCA contract does not match computed address");

        // It should return false for hasExpired.
        assertFalse(merkleVCA.hasExpired(), "isExpired");

        // It should set the correct unlock percentage.
        assertEq(merkleVCA.UNLOCK_PERCENTAGE(), unlockPercentage, "unlock percentage");

        // It should set the correct vesting end time.
        assertEq(merkleVCA.VESTING_END_TIME(), endTime, "vesting end time");

        // It should set the correct vesting start time.
        assertEq(merkleVCA.VESTING_START_TIME(), startTime, "vesting start time");

        // Fund the MerkleVCA contract.
        deal({ token: address(dai), to: address(merkleVCA), give: aggregateAmount });

        // Cast the {MerkleVCA} contract as {ISablierMerkleBase}
        merkleBase = merkleVCA;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                CLAIM-EVENT-HELPER
    //////////////////////////////////////////////////////////////////////////*/

    function expectClaimEvent(LeafData memory leafData) internal override {
        // Calculate claim and forgone amount based on the vesting start and end time.
        (uint256 claimAmount, uint256 forgoneAmount) = calculateMerkleVCAAmounts({
            fullAmount: leafData.amount,
            unlockPercentage: merkleVCA.UNLOCK_PERCENTAGE(),
            endTime: merkleVCA.VESTING_END_TIME(),
            startTime: merkleVCA.VESTING_START_TIME()
        });

        // It should emit a {Claim} event.
        vm.expectEmit({ emitter: address(merkleVCA) });
        emit ISablierMerkleVCA.Claim({
            index: leafData.index,
            recipient: leafData.recipient,
            claimAmount: uint128(claimAmount),
            forgoneAmount: uint128(forgoneAmount)
        });

        // It should transfer the claim amount to the recipient.
        expectCallToTransfer({ token: dai, to: leafData.recipient, value: claimAmount });
    }
}
