// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleVCA } from "src/interfaces/ISablierMerkleVCA.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Claim_Integration_Test } from "../../shared/claim/claim.t.sol";
import { MerkleVCA_Integration_Shared_Test, Integration_Test } from "../MerkleVCA.t.sol";

contract Claim_MerkleVCA_Integration_Test is Claim_Integration_Test, MerkleVCA_Integration_Shared_Test {
    function setUp() public virtual override(MerkleVCA_Integration_Shared_Test, Integration_Test) {
        MerkleVCA_Integration_Shared_Test.setUp();
    }

    function test_RevertWhen_StartTimeInFuture() external whenMerkleProofValid {
        // Move back in time so that the unlock start time is in the future.
        vm.warp({ newTimestamp: RANGED_STREAM_START_TIME - 1 });

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierMerkleVCA_ClaimNotStarted.selector, RANGED_STREAM_START_TIME)
        );

        // Claim the airdrop.
        merkleVCA.claim{ value: MINIMUM_FEE }({
            index: 1,
            recipient: users.recipient1,
            amount: CLAIM_AMOUNT,
            merkleProof: index1Proof()
        });
    }

    function test_WhenEndTimeInPast() external whenMerkleProofValid whenStartTimeNotInFuture {
        // Forward in time so that the unlock end time is in the past.
        vm.warp({ newTimestamp: RANGED_STREAM_END_TIME });

        // It should emit a {Claim} event.
        vm.expectEmit({ emitter: address(merkleVCA) });
        emit ISablierMerkleVCA.Claim(INDEX1, users.recipient1, CLAIM_AMOUNT, CLAIM_AMOUNT);

        // It should transfer the full amount.
        expectCallToTransfer({ to: users.recipient1, value: CLAIM_AMOUNT });
        expectCallToClaimWithMsgValue(address(merkleVCA), MINIMUM_FEE);

        merkleVCA.claim{ value: MINIMUM_FEE }({
            index: 1,
            recipient: users.recipient1,
            amount: CLAIM_AMOUNT,
            merkleProof: index1Proof()
        });

        // It should update the claimed status.
        assertTrue(merkleVCA.hasClaimed(INDEX1), "not claimed");

        // It should not update forgone amount.
        assertEq(merkleVCA.forgoneAmount(), 0, "forgone amount");
    }

    function test_WhenEndTimeNotInPast() external whenMerkleProofValid whenStartTimeNotInFuture {
        uint128 claimableAmount = (CLAIM_AMOUNT * 2 days) / TOTAL_DURATION;

        // It should emit a {Claim} event.
        vm.expectEmit({ emitter: address(merkleVCA) });
        emit ISablierMerkleVCA.Claim(INDEX1, users.recipient1, claimableAmount, CLAIM_AMOUNT);

        // It should transfer a portion of the amount.
        expectCallToTransfer({ to: users.recipient1, value: claimableAmount });
        expectCallToClaimWithMsgValue(address(merkleVCA), MINIMUM_FEE);

        merkleVCA.claim{ value: MINIMUM_FEE }({
            index: 1,
            recipient: users.recipient1,
            amount: CLAIM_AMOUNT,
            merkleProof: index1Proof()
        });

        // It should update the claimed status.
        assertTrue(merkleVCA.hasClaimed(INDEX1), "not claimed");

        // It should update forgone amount.
        assertEq(merkleVCA.forgoneAmount(), CLAIM_AMOUNT - claimableAmount, "forgone amount");
    }
}
