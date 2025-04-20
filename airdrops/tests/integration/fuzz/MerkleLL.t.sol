// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { UD60x18, ZERO } from "@prb/math/src/UD60x18.sol";

import { ISablierFactoryMerkleLL } from "src/interfaces/ISablierFactoryMerkleLL.sol";
import { ISablierMerkleLL } from "src/interfaces/ISablierMerkleLL.sol";
import { ISablierMerkleLockup } from "src/interfaces/ISablierMerkleLockup.sol";

import { MerkleLL } from "src/types/DataTypes.sol";

import { LeafData } from "../../utils/MerkleBuilder.sol";
import { Shared_Fuzz_Test, Integration_Test } from "./Fuzz.t.sol";

contract MerkleLL_Fuzz_Test is Shared_Fuzz_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Integration_Test.setUp();

        // Cast the {FactoryMerkleLL} contract as {ISablierFactoryMerkleBase}
        factoryMerkleBase = factoryMerkleLL;

        // Set the campaign type.
        campaignType = "ll";
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Given enough fuzz runs, all of the following scenarios will be fuzzed:
    ///
    /// - Fuzzed custom fee.
    /// - MerkleLL campaign with fuzzed leaves data, expiration, start time, start unlock, cliff duration, cliff unlock
    /// percentage,  percentage and total duration.
    /// - Both finite (only in future) and infinite expiration.
    /// - Claiming multiple airdrops with fuzzed claim fee at different point in time.
    /// - Fuzzed clawback amount.
    /// - Collect fees earned.
    function testFuzz_MerkleLL(
        uint128 clawbackAmount,
        uint40 cliffDuration,
        UD60x18 cliffUnlockPercentage,
        bool enableCustomFee,
        uint40 expiration,
        uint256 feeForUser,
        uint256[] memory indexesToClaim,
        uint256 msgValue,
        LeafData[] memory rawLeavesData,
        uint40 startTime,
        UD60x18 startUnlockPercentage,
        uint40 totalDuration
    )
        external
    {
        // Bound the fuzzed params and construct the Merkle tree.
        (uint256 aggregateAmount, uint40 expiration_, bytes32 merkleRoot) =
            prepareCommonCreateParams(rawLeavesData, expiration, indexesToClaim.length);

        // Set the custom fee if enabled.
        feeForUser = enableCustomFee ? testSetCustomFeeUSD(feeForUser) : MIN_FEE_USD;

        // Test creating the MerkleLL campaign.
        _testCreateMerkleLL(
            aggregateAmount,
            cliffDuration,
            cliffUnlockPercentage,
            expiration_,
            feeForUser,
            merkleRoot,
            startTime,
            startUnlockPercentage,
            totalDuration
        );

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

    function _testCreateMerkleLL(
        uint256 aggregateAmount,
        uint40 cliffDuration,
        UD60x18 cliffUnlockPercentage,
        uint40 expiration,
        uint256 feeForUser,
        bytes32 merkleRoot,
        uint40 startTime,
        UD60x18 startUnlockPercentage,
        uint40 totalDuration
    )
        private
        givenCampaignNotExists
        whenTotalPercentageNotGreaterThan100
    {
        // Bound the start time.
        startTime = boundUint40(startTime, 0, MAX_UNIX_TIMESTAMP - 1);

        // Expected start time is the start time if it is set, otherwise the current block time.
        uint40 expectedStartTime = startTime == 0 ? getBlockTimestamp() : startTime;

        // Bound cliff duration so that it does not overflow timestamps.
        cliffDuration = boundUint40(cliffDuration, 0, MAX_UNIX_TIMESTAMP - expectedStartTime - 1);

        // Bound the total duration so that the end time to be greater than the cliff time.
        totalDuration = boundUint40(totalDuration, cliffDuration + 1, MAX_UNIX_TIMESTAMP - expectedStartTime);

        // Bound unlock percentages so that the sum does not exceed 100%.
        startUnlockPercentage = _bound(startUnlockPercentage, 0, 1e18);

        // Bound cliff percentage so that the sum does not exceed 100% and is 0 if cliff duration is 0.
        cliffUnlockPercentage =
            cliffDuration > 0 ? _bound(cliffUnlockPercentage, 0, 1e18 - startUnlockPercentage.unwrap()) : ZERO;

        // Set campaign creator as the caller.
        setMsgSender(users.campaignCreator);

        MerkleLL.ConstructorParams memory params = merkleLLConstructorParams(expiration);
        params.cliffDuration = cliffDuration;
        params.cliffUnlockPercentage = cliffUnlockPercentage;
        params.startTime = startTime;
        params.startUnlockPercentage = startUnlockPercentage;
        params.merkleRoot = merkleRoot;
        params.totalDuration = totalDuration;

        // Precompute the deterministic address.
        address expectedMerkleLL = computeMerkleLLAddress(params, users.campaignCreator);

        // Expect a {CreateMerkleLL} event.
        vm.expectEmit({ emitter: address(factoryMerkleLL) });
        emit ISablierFactoryMerkleLL.CreateMerkleLL({
            merkleLL: ISablierMerkleLL(expectedMerkleLL),
            params: params,
            aggregateAmount: aggregateAmount,
            recipientCount: leavesData.length,
            minFeeUSD: feeForUser,
            oracle: address(oracle)
        });

        // Create the campaign.
        merkleLL = factoryMerkleLL.createMerkleLL(params, aggregateAmount, leavesData.length);

        // It should deploy the contract at the correct address.
        assertGt(address(merkleLL).code.length, 0, "MerkleLL contract not created");
        assertEq(address(merkleLL), expectedMerkleLL, "MerkleLL contract does not match computed address");

        // It should return false for hasExpired.
        assertFalse(merkleLL.hasExpired(), "isExpired");

        // It should return the correct contract state.
        assertEq(merkleLL.VESTING_CLIFF_DURATION(), cliffDuration, "vesting cliff duration");
        assertEq(merkleLL.VESTING_CLIFF_UNLOCK_PERCENTAGE(), cliffUnlockPercentage, "vesting cliff unlock percentage");
        assertEq(merkleLL.VESTING_START_TIME(), startTime, "vesting start time");
        assertEq(merkleLL.VESTING_START_UNLOCK_PERCENTAGE(), startUnlockPercentage, "vesting start unlock percentage");
        assertEq(merkleLL.VESTING_TOTAL_DURATION(), totalDuration, "vesting total duration");

        // Fund the MerkleLL contract.
        deal({ token: address(dai), to: address(merkleLL), give: aggregateAmount });

        // Cast the {MerkleLL} contract as {ISablierMerkleBase}
        merkleBase = merkleLL;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                CLAIM-EVENT-HELPER
    //////////////////////////////////////////////////////////////////////////*/

    function expectClaimEvent(LeafData memory leafData) internal override {
        // It should emit {Claim} event based on the end time.
        uint40 expectedVestingStartTime =
            merkleLL.VESTING_START_TIME() == 0 ? getBlockTimestamp() : merkleLL.VESTING_START_TIME();

        // If the vesting has ended, the claim should be transferred directly to the recipient.
        if (expectedVestingStartTime + merkleLL.VESTING_TOTAL_DURATION() <= getBlockTimestamp()) {
            vm.expectEmit({ emitter: address(merkleLL) });
            emit ISablierMerkleLockup.Claim(leafData.index, leafData.recipient, leafData.amount);

            expectCallToTransfer({ token: dai, to: leafData.recipient, value: leafData.amount });
        }
        // Otherwise, the claim should be made via a Lockup stream.
        else {
            uint256 expectedStreamId = lockup.nextStreamId();
            vm.expectEmit({ emitter: address(merkleLL) });
            emit ISablierMerkleLockup.Claim(leafData.index, leafData.recipient, leafData.amount, expectedStreamId);

            expectCallToTransferFrom({ token: dai, from: address(merkleLL), to: address(lockup), value: leafData.amount });
        }
    }
}
