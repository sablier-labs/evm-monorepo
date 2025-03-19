// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleFactoryInstant } from "src/interfaces/ISablierMerkleFactoryInstant.sol";
import { ISablierMerkleInstant } from "src/interfaces/ISablierMerkleInstant.sol";

import { MerkleInstant } from "src/types/DataTypes.sol";

import { LeafData } from "../../utils/MerkleBuilder.sol";
import { Shared_Fuzz_Test, Integration_Test } from "./Fuzz.t.sol";

contract MerkleInstant_Fuzz_Test is Shared_Fuzz_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Integration_Test.setUp();

        // Cast the {merkleFactoryInstant} contract as {ISablierMerkleFactoryBase}
        merkleFactoryBase = merkleFactoryInstant;
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
    /// - Fuzzed clawback amount.
    /// - Collect fees earned.
    function testFuzz_MerkleInstant(
        uint128 clawbackAmount,
        bool enableCustomFee,
        uint40 expiration,
        uint256 feeForUser,
        uint256[] memory indexesToClaim,
        uint256 msgValue,
        LeafData[] memory rawLeavesData
    )
        external
    {
        // Bound the fuzzed params and construct the Merkle tree.
        (uint256 aggregateAmount, uint40 expiration_, bytes32 merkleRoot) =
            prepareCommonCreateParams(rawLeavesData, expiration, indexesToClaim.length);

        // Set the custom fee if enabled.
        feeForUser = enableCustomFee ? testSetCustomFee(feeForUser) : MINIMUM_FEE;

        // Test creating the MerkleInstant campaign.
        _testCreateMerkleInstant(aggregateAmount, expiration_, feeForUser, merkleRoot);

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

    function _testCreateMerkleInstant(
        uint256 aggregateAmount,
        uint40 expiration,
        uint256 feeForUser,
        bytes32 merkleRoot
    )
        private
        givenCampaignNotExists
    {
        // Set campaign creator as the caller.
        resetPrank(users.campaignCreator);

        MerkleInstant.ConstructorParams memory params = merkleInstantConstructorParams(expiration);
        params.merkleRoot = merkleRoot;

        // Precompute the deterministic address.
        address expectedMerkleInstant = computeMerkleInstantAddress(params, users.campaignCreator);

        // Expect a {CreateMerkleInstant} event.
        vm.expectEmit({ emitter: address(merkleFactoryInstant) });
        emit ISablierMerkleFactoryInstant.CreateMerkleInstant({
            merkleInstant: ISablierMerkleInstant(expectedMerkleInstant),
            params: params,
            aggregateAmount: aggregateAmount,
            recipientCount: leavesData.length,
            fee: feeForUser,
            oracle: address(oracle)
        });

        // Create the campaign.
        merkleInstant = merkleFactoryInstant.createMerkleInstant(params, aggregateAmount, leavesData.length);

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

    function expectClaimEvent(LeafData memory leafData) internal override {
        // it should emit a {Claim} event.
        vm.expectEmit({ emitter: address(merkleInstant) });
        emit ISablierMerkleInstant.Claim(leafData.index, leafData.recipient, leafData.amount);

        // It should transfer the claim amount to the recipient.
        expectCallToTransfer({ token: dai, to: leafData.recipient, value: leafData.amount });
    }
}
