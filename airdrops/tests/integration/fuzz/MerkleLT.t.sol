// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierFactoryMerkleLT } from "src/interfaces/ISablierFactoryMerkleLT.sol";
import { ISablierMerkleLockup } from "src/interfaces/ISablierMerkleLockup.sol";
import { ISablierMerkleLT } from "src/interfaces/ISablierMerkleLT.sol";

import { MerkleLT } from "src/types/DataTypes.sol";

import { LeafData } from "../../utils/MerkleBuilder.sol";
import { Shared_Fuzz_Test, Integration_Test } from "./Fuzz.t.sol";

contract MerkleLT_Fuzz_Test is Shared_Fuzz_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Integration_Test.setUp();

        // Cast the {FactoryMerkleLT} contract as {ISablierFactoryMerkleBase}
        factoryMerkleBase = factoryMerkleLT;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Given enough fuzz runs, all of the following scenarios will be fuzzed:
    ///
    /// - Fuzzed custom fee.
    /// - MerkleLT campaign with fuzzed leaves data, expiration, and tranches.
    /// - Both finite (only in future) and infinite expiration.
    /// - Claiming multiple airdrops with fuzzed claim fee at different point in time.
    /// - Fuzzed clawback amount.
    /// - Collect fees earned.
    function testFuzz_MerkleLT(
        uint128 clawbackAmount,
        bool enableCustomFee,
        uint40 expiration,
        uint256 feeForUser,
        uint256[] memory indexesToClaim,
        uint256 msgValue,
        LeafData[] memory rawLeavesData,
        uint40 startTime,
        MerkleLT.TrancheWithPercentage[] memory tranches
    )
        external
    {
        // Bound the fuzzed params and construct the Merkle tree.
        (uint256 aggregateAmount, uint40 expiration_, bytes32 merkleRoot) =
            prepareCommonCreateParams(rawLeavesData, expiration, indexesToClaim.length);

        // Set the custom fee if enabled.
        feeForUser = enableCustomFee ? testSetCustomFeeUSD(feeForUser) : MIN_FEE_USD;

        // Test creating the MerkleLT campaign.
        _testCreateMerkleLT(aggregateAmount, expiration_, feeForUser, merkleRoot, startTime, tranches);

        // Test claiming the airdrop for the given indexes.
        testClaimMultipleAirdrops(indexesToClaim, msgValue);

        // Test clawbacking funds.
        testClawback(clawbackAmount);

        // Test collecting fees earned.
        testCollectFees();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    CREATE-HELPER
    //////////////////////////////////////////////////////////////////////////*/

    function _testCreateMerkleLT(
        uint256 aggregateAmount,
        uint40 expiration,
        uint256 feeForUser,
        bytes32 merkleRoot,
        uint40 startTime,
        MerkleLT.TrancheWithPercentage[] memory tranches
    )
        private
        givenCampaignNotExists
        whenTotalPercentage100
    {
        // Ensure that tranches are not empty and not too large.
        vm.assume(tranches.length <= 1000 && tranches.length > 0);

        // Bound the start time.
        startTime = boundUint40(startTime, 0, getBlockTimestamp() + 1000);

        uint40 streamDuration = fuzzTranchesMerkleLT(startTime, tranches);

        // Set campaign creator as the caller.
        setMsgSender(users.campaignCreator);

        MerkleLT.ConstructorParams memory params = merkleLTConstructorParams(expiration);
        params.merkleRoot = merkleRoot;
        params.streamStartTime = startTime;
        params.tranchesWithPercentages = tranches;

        // Precompute the deterministic address.
        address expectedMerkleLT = computeMerkleLTAddress(params, users.campaignCreator);

        // Expect a {CreateMerkleLT} event.
        vm.expectEmit({ emitter: address(factoryMerkleLT) });
        emit ISablierFactoryMerkleLT.CreateMerkleLT({
            merkleLT: ISablierMerkleLT(expectedMerkleLT),
            params: params,
            aggregateAmount: aggregateAmount,
            recipientCount: leavesData.length,
            totalDuration: streamDuration,
            minFeeUSD: feeForUser,
            oracle: address(oracle)
        });

        // Create the campaign.
        merkleLT = factoryMerkleLT.createMerkleLT(params, aggregateAmount, leavesData.length);

        // It should deploy the contract at the correct address.
        assertGt(address(merkleLT).code.length, 0, "MerkleLT contract not created");
        assertEq(address(merkleLT), expectedMerkleLT, "MerkleLT contract does not match computed address");

        // It should return false for hasExpired.
        assertFalse(merkleLT.hasExpired(), "isExpired");

        // It should return the correct schedule tranches.
        assertEq(merkleLT.getTranchesWithPercentages(), tranches);
        assertEq(merkleLT.STREAM_START_TIME(), startTime);
        assertEq(merkleLT.TOTAL_PERCENTAGE(), 1e18);

        // Fund the MerkleLT contract.
        deal({ token: address(dai), to: address(merkleLT), give: aggregateAmount });

        // Cast the {MerkleLT} contract as {ISablierMerkleBase}
        merkleBase = merkleLT;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                CLAIM-EVENT-HELPER
    //////////////////////////////////////////////////////////////////////////*/

    function expectClaimEvent(LeafData memory leafData) internal override {
        uint40 totalDuration = getTotalDuration(merkleLT.getTranchesWithPercentages());

        // Calculate end time based on the start time.
        uint40 startTime = merkleLT.STREAM_START_TIME();
        uint40 endTime = startTime == 0 ? getBlockTimestamp() + totalDuration : startTime + totalDuration;

        // If the vesting has ended, the claim should be transferred directly to the recipient.
        if (endTime <= getBlockTimestamp()) {
            vm.expectEmit({ emitter: address(merkleLT) });
            emit ISablierMerkleLockup.Claim(leafData.index, leafData.recipient, leafData.amount);

            expectCallToTransfer({ token: dai, to: leafData.recipient, value: leafData.amount });
        }
        // Otherwise, the claim should be transferred to the lockup contract.
        else {
            uint256 expectedStreamId = lockup.nextStreamId();
            vm.expectEmit({ emitter: address(merkleLT) });
            emit ISablierMerkleLockup.Claim(leafData.index, leafData.recipient, leafData.amount, expectedStreamId);

            expectCallToTransferFrom({ token: dai, from: address(merkleLT), to: address(lockup), value: leafData.amount });
        }
    }
}
