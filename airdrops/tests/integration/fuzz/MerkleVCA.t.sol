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
    /// - MerkleVCA campaign with fuzzed leaves data, expiration, end time and start time.
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
        uint40 startTime
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
        _testCreateMerkleVCA(aggregateAmount, endTime, expiration, feeForUser, merkleRoot, startTime);

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
        uint40 startTime
    )
        private
        givenCampaignNotExists
        whenStartTimeNotZero
        whenEndTimeGreaterThanStartTime
        whenNotZeroExpiration
        whenExpirationExceedsOneWeekFromEndTime
    {
        // Bound start time to be in the past.
        startTime = boundUint40(startTime, 1 seconds, getBlockTimestamp() - 1 seconds);

        // Bound end time to be greater than the start time but within than a year from now.
        endTime = boundUint40(endTime, startTime + 1, getBlockTimestamp() + 365 days);

        // Set campaign creator as the caller.
        setMsgSender(users.campaignCreator);

        MerkleVCA.ConstructorParams memory params = merkleVCAConstructorParams(expiration);
        params.merkleRoot = merkleRoot;
        params.endTime = endTime;
        params.startTime = startTime;

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

        // It should set return the correct end time.
        assertEq(merkleVCA.END_TIME(), endTime, "end time");

        // It should set return the correct start time.
        assertEq(merkleVCA.START_TIME(), startTime, "start time");

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
            endTime: merkleVCA.END_TIME(),
            startTime: merkleVCA.START_TIME()
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
