// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierComptroller } from "@sablier/evm-utils/src/interfaces/ISablierComptroller.sol";
import { ISablierFactoryMerkleExecute } from "src/interfaces/ISablierFactoryMerkleExecute.sol";
import { ISablierMerkleExecute } from "src/interfaces/ISablierMerkleExecute.sol";
import { MerkleExecute } from "src/types/MerkleExecute.sol";

import { LeafData } from "../../utils/MerkleBuilder.sol";
import { Params } from "../../utils/Types.sol";
import { Shared_Integration_Fuzz_Test, Integration_Test } from "./Fuzz.t.sol";

contract MerkleExecute_Integration_Fuzz_Test is Shared_Integration_Fuzz_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Integration_Test.setUp();

        // Cast the {FactoryMerkleExecute} contract as {ISablierFactoryMerkleBase}
        factoryMerkleBase = factoryMerkleExecute;

        // Set the campaign type.
        campaignType = "execute";
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Given enough fuzz runs, all of the following scenarios will be fuzzed:
    ///
    /// - Fuzzed custom fee.
    /// - MerkleExecute campaign with fuzzed leaves data, and expiration.
    /// - Both finite (only in future) and infinite expiration.
    /// - Claiming multiple airdrops with fuzzed claim fee at different point in time.
    /// - Fuzzed clawback amount.
    /// - Collect fees earned.
    function testFuzz_MerkleExecute(Params memory params) external {
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

        // Test creating the MerkleExecute campaign.
        _testCreateMerkleExecute(aggregateAmount, expiration_, params.feeForUser, merkleRoot);

        // Test claiming the airdrop for the given indexes.
        testClaimMultipleAirdrops(params.indexesToClaim, params.msgValue, params.to);

        // Test clawback of funds.
        testClawback(params.clawbackAmount);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    CREATE-HELPER
    //////////////////////////////////////////////////////////////////////////*/

    function _testCreateMerkleExecute(
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

        MerkleExecute.ConstructorParams memory params = merkleExecuteConstructorParams(expiration);
        params.merkleRoot = merkleRoot;

        // Precompute the deterministic address.
        address expectedMerkleExecute = computeMerkleExecuteAddress(params, users.campaignCreator);

        // Expect a {CreateMerkleExecute} event.
        vm.expectEmit({ emitter: address(factoryMerkleExecute) });
        emit ISablierFactoryMerkleExecute.CreateMerkleExecute({
            merkleExecute: ISablierMerkleExecute(expectedMerkleExecute),
            campaignParams: params,
            aggregateAmount: aggregateAmount,
            recipientCount: leavesData.length,
            comptroller: address(comptroller),
            minFeeUSD: feeForUser
        });

        // Create the campaign.
        merkleExecute = factoryMerkleExecute.createMerkleExecute(params, aggregateAmount, leavesData.length);

        // It should deploy the contract at the correct address.
        assertGt(address(merkleExecute).code.length, 0, "MerkleExecute contract not created");
        assertEq(
            address(merkleExecute), expectedMerkleExecute, "MerkleExecute contract does not match computed address"
        );

        // It should return false for hasExpired.
        assertFalse(merkleExecute.hasExpired(), "isExpired");

        // Fund the MerkleExecute contract.
        deal({ token: address(dai), to: address(merkleExecute), give: aggregateAmount });

        // Cast the {MerkleExecute} contract as {ISablierMerkleBase}
        merkleBase = merkleExecute;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                CLAIM-EVENT-HELPER
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Expect the {ClaimExecute} event and token transfer to the target.
    function expectClaimEvent(LeafData memory leafData, address) internal override {
        vm.expectEmit({ emitter: address(merkleExecute) });
        emit ISablierMerkleExecute.ClaimExecute({
            index: leafData.index,
            recipient: leafData.recipient,
            amount: leafData.amount,
            target: address(mockStaking)
        });

        // Tokens are transferred to the target (mockStaking), not to the recipient.
        expectCallToTransferFrom({
            token: dai,
            from: address(merkleExecute),
            to: address(mockStaking),
            value: leafData.amount
        });
    }
}
