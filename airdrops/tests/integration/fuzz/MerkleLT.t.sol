// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierComptroller } from "@sablier/evm-utils/src/interfaces/ISablierComptroller.sol";
import { ISablierFactoryMerkleLT } from "src/interfaces/ISablierFactoryMerkleLT.sol";
import { ISablierMerkleLT } from "src/interfaces/ISablierMerkleLT.sol";

import { MerkleLT } from "src/types/DataTypes.sol";

import { LeafData } from "../../utils/MerkleBuilder.sol";
import { Params } from "../../utils/Types.sol";
import { Shared_Fuzz_Test, Integration_Test } from "./Fuzz.t.sol";

contract MerkleLT_Fuzz_Test is Shared_Fuzz_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Integration_Test.setUp();

        // Cast the {FactoryMerkleLT} contract as {ISablierFactoryMerkleBase}
        factoryMerkleBase = factoryMerkleLT;

        // Set the campaign type.
        campaignType = "lt";
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
    /// - Claiming airdrops using both {claim} and {claimTo} functions with fuzzed `to` address.
    /// - Fuzzed clawback amount.
    /// - Collect fees earned.
    function testFuzz_MerkleLT(
        Params memory params,
        MerkleLT.TrancheWithPercentage[] memory tranches,
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
            comptroller.setCustomFeeUSDFor(
                ISablierComptroller.Protocol.Airdrops, users.campaignCreator, params.feeForUser
            );
        } else {
            params.feeForUser = AIRDROP_MIN_FEE_USD;
        }

        // Test creating the MerkleLT campaign.
        _testCreateMerkleLT(aggregateAmount, expiration_, params.feeForUser, merkleRoot, tranches, vestingStartTime);

        // Test claiming the airdrop for the given indexes.
        testClaimMultipleAirdrops(params.indexesToClaim, params.msgValue, params.to);

        // Test clawbacking funds.
        testClawback(params.clawbackAmount);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    CREATE-HELPER
    //////////////////////////////////////////////////////////////////////////*/

    function _testCreateMerkleLT(
        uint256 aggregateAmount,
        uint40 expiration,
        uint256 feeForUser,
        bytes32 merkleRoot,
        MerkleLT.TrancheWithPercentage[] memory tranches,
        uint40 vestingStartTime
    )
        private
        givenCampaignNotExists
        givenCampaignStartTimeNotInFuture
        whenTotalPercentage100
    {
        // Ensure that tranches are not empty and not too large.
        vm.assume(tranches.length <= 1000 && tranches.length > 0);

        // Bound the vesting start time.
        vestingStartTime = boundUint40(vestingStartTime, 0, getBlockTimestamp() + 1000);

        uint40 streamDuration = fuzzTranchesMerkleLT(vestingStartTime, tranches);

        // Set campaign creator as the caller.
        setMsgSender(users.campaignCreator);

        MerkleLT.ConstructorParams memory params = merkleLTConstructorParams(expiration);
        params.merkleRoot = merkleRoot;
        params.tranchesWithPercentages = tranches;
        params.vestingStartTime = vestingStartTime;

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
            comptroller: address(comptroller),
            minFeeUSD: feeForUser
        });

        // Create the campaign.
        merkleLT = factoryMerkleLT.createMerkleLT(params, aggregateAmount, leavesData.length);

        // It should deploy the contract at the correct address.
        assertGt(address(merkleLT).code.length, 0, "MerkleLT contract not created");
        assertEq(address(merkleLT), expectedMerkleLT, "MerkleLT contract does not match computed address");

        // It should return false for hasExpired.
        assertFalse(merkleLT.hasExpired(), "isExpired");

        // It should return the correct schedule tranches.
        assertEq(merkleLT.tranchesWithPercentages(), tranches);
        assertEq(merkleLT.VESTING_START_TIME(), vestingStartTime);

        // Fund the MerkleLT contract.
        deal({ token: address(dai), to: address(merkleLT), give: aggregateAmount });

        // Cast the {MerkleLT} contract as {ISablierMerkleBase}
        merkleBase = merkleLT;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                CLAIM-EVENT-HELPER
    //////////////////////////////////////////////////////////////////////////*/

    function expectClaimEvent(LeafData memory leafData, address to) internal override {
        uint40 totalDuration = getTotalDuration(merkleLT.tranchesWithPercentages());

        // Calculate vesting end time based on the vesting start time.
        uint40 vestingStartTime = merkleLT.VESTING_START_TIME();
        uint40 vestingEndTime =
            vestingStartTime == 0 ? getBlockTimestamp() + totalDuration : vestingStartTime + totalDuration;

        // If the vesting has ended, the claim should be transferred directly to the `to` address.
        if (vestingEndTime <= getBlockTimestamp()) {
            vm.expectEmit({ emitter: address(merkleLT) });
            emit ISablierMerkleLT.ClaimLTWithTransfer({
                index: leafData.index,
                recipient: leafData.recipient,
                amount: leafData.amount,
                to: to,
                viaSig: false
            });

            expectCallToTransfer({ token: dai, to: to, value: leafData.amount });
        }
        // Otherwise, the claim should be transferred to the lockup contract.
        else {
            uint256 expectedStreamId = lockup.nextStreamId();
            vm.expectEmit({ emitter: address(merkleLT) });
            emit ISablierMerkleLT.ClaimLTWithVesting({
                index: leafData.index,
                recipient: leafData.recipient,
                amount: leafData.amount,
                streamId: expectedStreamId,
                to: to,
                viaSig: false
            });

            expectCallToTransferFrom({ token: dai, from: address(merkleLT), to: address(lockup), value: leafData.amount });
        }
    }
}
