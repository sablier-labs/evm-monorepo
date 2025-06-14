// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { UD60x18, ZERO } from "@prb/math/src/UD60x18.sol";

import { ISablierFactoryMerkleLL } from "src/interfaces/ISablierFactoryMerkleLL.sol";
import { ISablierMerkleLL } from "src/interfaces/ISablierMerkleLL.sol";
import { ISablierMerkleLockup } from "src/interfaces/ISablierMerkleLockup.sol";

import { MerkleLL } from "src/types/DataTypes.sol";

import { LeafData } from "../../utils/MerkleBuilder.sol";
import { Params } from "../../utils/Types.sol";
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
    /// - MerkleLL campaign with fuzzed leaves data, expiration, vesting start time, start unlock, cliff duration, cliff
    /// unlock percentage,  percentage and total duration.
    /// - Both finite (only in future) and infinite expiration.
    /// - Claiming multiple airdrops with fuzzed claim fee at different point in time.
    /// - Claiming airdrops using both {claim} and {claimTo} functions with fuzzed `to` address.
    /// - Fuzzed clawback amount.
    /// - Collect fees earned.
    function testFuzz_MerkleLL(
        Params memory params,
        uint40 cliffDuration,
        UD60x18 cliffUnlockPercentage,
        UD60x18 startUnlockPercentage,
        uint40 totalDuration,
        uint40 vestingStartTime
    )
        external
    {
        // Bound the fuzzed params and construct the Merkle tree.
        (uint256 aggregateAmount, uint40 expiration_, bytes32 merkleRoot) =
            prepareCommonCreateParams(params.rawLeavesData, params.expiration, params.indexesToClaim.length);

        // Set the custom fee if enabled.
        if (params.enableCustomFeeUSD) {
            params.feeForUser = bound(params.feeForUser, 0, MAX_FEE_USD);
            setMsgSender(admin);
            comptroller.setAirdropsCustomFeeUSD(users.campaignCreator, params.feeForUser);
        } else {
            params.feeForUser = AIRDROP_MIN_FEE_USD;
        }

        // Test creating the MerkleLL campaign.
        _testCreateMerkleLL(
            aggregateAmount,
            cliffDuration,
            cliffUnlockPercentage,
            expiration_,
            params.feeForUser,
            merkleRoot,
            startUnlockPercentage,
            totalDuration,
            vestingStartTime
        );

        // Test claiming the airdrop for the given indexes.
        testClaimMultipleAirdrops(params.indexesToClaim, params.msgValue, params.to);

        // Test clawbacking funds.
        testClawback(params.clawbackAmount);
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
        UD60x18 startUnlockPercentage,
        uint40 totalDuration,
        uint40 vestingStartTime
    )
        private
        givenCampaignNotExists
        givenCampaignStartTimeNotInFuture
        whenTotalPercentageNotGreaterThan100
    {
        // Bound the vesting start time.
        vestingStartTime = boundUint40(vestingStartTime, 0, MAX_UNIX_TIMESTAMP - 1);

        // Set expected vesting start time to the current block time if it is zero.
        uint40 expectedVestingStartTime = vestingStartTime == 0 ? getBlockTimestamp() : vestingStartTime;

        // Bound cliff duration so that it does not overflow timestamps.
        cliffDuration = boundUint40(cliffDuration, 0, MAX_UNIX_TIMESTAMP - expectedVestingStartTime - 1);

        // Bound the total duration so that the vesting end time to be greater than the cliff time.
        totalDuration = boundUint40(totalDuration, cliffDuration + 1, MAX_UNIX_TIMESTAMP - expectedVestingStartTime);

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
        params.startUnlockPercentage = startUnlockPercentage;
        params.merkleRoot = merkleRoot;
        params.totalDuration = totalDuration;
        params.vestingStartTime = vestingStartTime;

        // Precompute the deterministic address.
        address expectedMerkleLL = computeMerkleLLAddress(params, users.campaignCreator);

        // Expect a {CreateMerkleLL} event.
        vm.expectEmit({ emitter: address(factoryMerkleLL) });
        emit ISablierFactoryMerkleLL.CreateMerkleLL({
            merkleLL: ISablierMerkleLL(expectedMerkleLL),
            params: params,
            aggregateAmount: aggregateAmount,
            recipientCount: leavesData.length,
            comptroller: address(comptroller),
            minFeeUSD: feeForUser
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
        assertEq(merkleLL.VESTING_START_TIME(), vestingStartTime, "vesting start time");
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

    function expectClaimEvent(LeafData memory leafData, address to) internal override {
        // It should emit {Claim} event based on the vesting end time.
        uint40 expectedVestingStartTime =
            merkleLL.VESTING_START_TIME() == 0 ? getBlockTimestamp() : merkleLL.VESTING_START_TIME();

        // If the vesting has ended, the claim should be transferred directly to the `to` address.
        if (expectedVestingStartTime + merkleLL.VESTING_TOTAL_DURATION() <= getBlockTimestamp()) {
            vm.expectEmit({ emitter: address(merkleLL) });
            emit ISablierMerkleLockup.Claim({
                index: leafData.index,
                recipient: leafData.recipient,
                amount: leafData.amount,
                to: to
            });

            expectCallToTransfer({ token: dai, to: to, value: leafData.amount });
        }
        // Otherwise, the claim should be made via a Lockup stream.
        else {
            uint256 expectedStreamId = lockup.nextStreamId();
            vm.expectEmit({ emitter: address(merkleLL) });
            emit ISablierMerkleLockup.Claim({
                index: leafData.index,
                recipient: leafData.recipient,
                amount: leafData.amount,
                streamId: expectedStreamId,
                to: to
            });

            expectCallToTransferFrom({ token: dai, from: address(merkleLL), to: address(lockup), value: leafData.amount });
        }
    }
}
