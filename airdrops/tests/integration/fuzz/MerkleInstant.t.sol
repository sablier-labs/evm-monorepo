// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierFactoryMerkleInstant } from "src/interfaces/ISablierFactoryMerkleInstant.sol";
import { ISablierMerkleInstant } from "src/interfaces/ISablierMerkleInstant.sol";

import { MerkleInstant } from "src/types/DataTypes.sol";

import { LeafData } from "../../utils/MerkleBuilder.sol";
import { Params } from "../../utils/Types.sol";
import { Shared_Fuzz_Test, Integration_Test } from "./Fuzz.t.sol";

contract MerkleInstant_Fuzz_Test is Shared_Fuzz_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Integration_Test.setUp();

        // Cast the {FactoryMerkleInstant} contract as {ISablierFactoryMerkleBase}
        factoryMerkleBase = factoryMerkleInstant;

        // Set the campaign type.
        campaignType = "instant";
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Given enough fuzz runs, all of the following scenarios will be fuzzed:
    ///
    /// - Fuzzed custom fee.
    /// - MerkleInstant campaign with fuzzed leaves data, and expiration.
    /// - Both finite (only in future) and infinite expiration.
    /// - Claiming multiple airdrops with fuzzed claim fee at different point in time.
    /// - Claiming airdrops using both {claim} and {claimTo} functions with fuzzed `to` address.
    /// - Fuzzed clawback amount.
    /// - Collect fees earned.
    function testFuzz_MerkleInstant(Params memory params) external {
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

        // Test creating the MerkleInstant campaign.
        _testCreateMerkleInstant(aggregateAmount, expiration_, params.feeForUser, merkleRoot);

        // Test claiming the airdrop for the given indexes.
        testClaimMultipleAirdrops(params.indexesToClaim, params.msgValue, params.to);

        // Test clawback of funds.
        testClawback(params.clawbackAmount);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    CREATE-HELPER
    //////////////////////////////////////////////////////////////////////////*/

    function _testCreateMerkleInstant(
        uint256 aggregateAmount,
        uint40 expiration,
        uint256 feeForUser,
        bytes32 merkleRoot
    )
        private
        givenCampaignNotExists
        givenCampaignStartTimeNotInFuture
    {
        // Set campaign creator as the caller.
        setMsgSender(users.campaignCreator);

        MerkleInstant.ConstructorParams memory params = merkleInstantConstructorParams(expiration);
        params.merkleRoot = merkleRoot;

        // Precompute the deterministic address.
        address expectedMerkleInstant = computeMerkleInstantAddress(params, users.campaignCreator);

        // Expect a {CreateMerkleInstant} event.
        vm.expectEmit({ emitter: address(factoryMerkleInstant) });
        emit ISablierFactoryMerkleInstant.CreateMerkleInstant({
            merkleInstant: ISablierMerkleInstant(expectedMerkleInstant),
            params: params,
            aggregateAmount: aggregateAmount,
            recipientCount: leavesData.length,
            comptroller: address(comptroller),
            minFeeUSD: feeForUser
        });

        // Create the campaign.
        merkleInstant = factoryMerkleInstant.createMerkleInstant(params, aggregateAmount, leavesData.length);

        // It should deploy the contract at the correct address.
        assertGt(address(merkleInstant).code.length, 0, "MerkleInstant contract not created");
        assertEq(
            address(merkleInstant), expectedMerkleInstant, "MerkleInstant contract does not match computed address"
        );

        // It should return false for hasExpired.
        assertFalse(merkleInstant.hasExpired(), "isExpired");

        // Fund the MerkleInstant contract.
        deal({ token: address(dai), to: address(merkleInstant), give: aggregateAmount });

        // Cast the {MerkleInstant} contract as {ISablierMerkleBase}
        merkleBase = merkleInstant;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                CLAIM-EVENT-HELPER
    //////////////////////////////////////////////////////////////////////////*/

    function expectClaimEvent(LeafData memory leafData, address to) internal override {
        // it should emit a {Claim} event.
        vm.expectEmit({ emitter: address(merkleInstant) });
        emit ISablierMerkleInstant.Claim({
            index: leafData.index,
            recipient: leafData.recipient,
            amount: leafData.amount,
            to: to
        });

        // It should transfer the claim amount to the `to` address.
        expectCallToTransfer({ token: dai, to: to, value: leafData.amount });
    }
}
