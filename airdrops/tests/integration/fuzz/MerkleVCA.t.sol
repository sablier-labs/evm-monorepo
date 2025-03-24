// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

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
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Given enough fuzz runs, all of the following scenarios will be fuzzed:
    ///
    /// - Fuzzed custom fee.
    /// - MerkleVCA campaign with fuzzed leaves data, expiration, and schedule.
    /// - Finite (only in future) expiration.
    /// - Vesting start time in the past.
    /// - Claiming airdrops for multiple indexes with fuzzed claim fee.
    /// - Fuzzed clawback amount.
    /// - Collect fees earned.
    function testFuzz_MerkleVCA(
        uint128 clawbackAmount,
        bool enableCustomFeeUSD,
        uint40 expiration,
        uint256 feeForUser,
        uint256[] memory indexesToClaim,
        uint256 msgValue,
        LeafData[] memory rawLeavesData,
        MerkleVCA.Schedule memory schedule
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
        _testCreateMerkleVCA(aggregateAmount, expiration, feeForUser, merkleRoot, schedule);

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
        uint40 expiration,
        uint256 feeForUser,
        bytes32 merkleRoot,
        MerkleVCA.Schedule memory schedule
    )
        private
        givenCampaignNotExists
        whenStartTimeNotZero
        whenEndTimeGreaterThanStartTime
        whenNotZeroExpiration
        whenExpirationExceedsOneWeekFromEndTime
    {
        // Bound schedule so that campaign start time is in the past and end time exceed start time.
        schedule.startTime = boundUint40(schedule.startTime, 1 seconds, getBlockTimestamp() - 1 seconds);
        schedule.endTime = boundUint40(schedule.endTime, schedule.startTime + 1 seconds, getBlockTimestamp() + 365 days);

        // Set campaign creator as the caller.
        setMsgSender(users.campaignCreator);

        MerkleVCA.ConstructorParams memory params = merkleVCAConstructorParams(expiration);
        params.merkleRoot = merkleRoot;
        params.schedule = schedule;

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

        // It should set return the correct schedule.
        assertEq(merkleVCA.getSchedule().startTime, schedule.startTime, "schedule start time");
        assertEq(merkleVCA.getSchedule().endTime, schedule.endTime, "schedule end time");

        // Fund the MerkleVCA contract.
        deal({ token: address(dai), to: address(merkleVCA), give: aggregateAmount });

        // Cast the {MerkleVCA} contract as {ISablierMerkleBase}
        merkleBase = merkleVCA;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                CLAIM-EVENT-HELPER
    //////////////////////////////////////////////////////////////////////////*/

    function expectClaimEvent(LeafData memory leafData) internal override {
        MerkleVCA.Schedule memory schedule = merkleVCA.getSchedule();

        // Calculate claim amount based on the vesting schedule.
        uint256 claimAmount = getBlockTimestamp() < schedule.endTime
            ? (uint256(leafData.amount) * (getBlockTimestamp() - schedule.startTime))
                / (schedule.endTime - schedule.startTime)
            : leafData.amount;
        uint256 forgoneAmount = leafData.amount - claimAmount;

        // It should emit a {Claim} event.
        vm.expectEmit({ emitter: address(merkleVCA) });
        emit ISablierMerkleVCA.Claim({
            index: leafData.index,
            recipient: leafData.recipient,
            claimAmount: uint128(claimAmount),
            forgoneAmount: uint128(forgoneAmount)
        });

        // It should transfer the claimable amount to the recipient.
        expectCallToTransfer({ token: dai, to: leafData.recipient, value: claimAmount });
    }
}
