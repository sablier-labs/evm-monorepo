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
        uint256 fee = defaults.MINIMUM_FEE();
        uint128 claimAmount = defaults.CLAIM_AMOUNT();
        bytes32[] memory merkleProof = defaults.index1Proof();
        uint40 unlockStartTime = defaults.RANGED_STREAM_START_TIME();

        // Move back in time so that the unlock start time is in the future.
        vm.warp({ newTimestamp: unlockStartTime - 1 });

        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierMerkleVCA_ClaimNotStarted.selector, unlockStartTime));

        // Claim the airdrop.
        merkleVCA.claim{ value: fee }({
            index: 1,
            recipient: users.recipient1,
            amount: claimAmount,
            merkleProof: merkleProof
        });
    }

    function test_WhenEndTimeInPast() external whenMerkleProofValid whenStartTimeNotInFuture {
        // Forward in time so that the unlock end time is in the past.
        vm.warp({ newTimestamp: defaults.RANGED_STREAM_END_TIME() });

        // It should emit a {Claim} event.
        vm.expectEmit({ emitter: address(merkleVCA) });
        emit ISablierMerkleVCA.Claim(
            defaults.INDEX1(), users.recipient1, defaults.CLAIM_AMOUNT(), defaults.CLAIM_AMOUNT()
        );

        // It should transfer the full amount.
        expectCallToTransfer({ to: users.recipient1, value: defaults.CLAIM_AMOUNT() });
        expectCallToClaimWithMsgValue(address(merkleVCA), defaults.MINIMUM_FEE());

        merkleVCA.claim{ value: defaults.MINIMUM_FEE() }({
            index: 1,
            recipient: users.recipient1,
            amount: defaults.CLAIM_AMOUNT(),
            merkleProof: defaults.index1Proof()
        });

        // It should update the claimed status.
        assertTrue(merkleVCA.hasClaimed(defaults.INDEX1()), "not claimed");

        // It should not update forgone amount.
        assertEq(merkleVCA.forgoneAmount(), 0, "forgone amount");
    }

    function test_WhenEndTimeNotInPast() external whenMerkleProofValid whenStartTimeNotInFuture {
        uint128 claimableAmount = (defaults.CLAIM_AMOUNT() * 2 days) / defaults.TOTAL_DURATION();

        // It should emit a {Claim} event.
        vm.expectEmit({ emitter: address(merkleVCA) });
        emit ISablierMerkleVCA.Claim(defaults.INDEX1(), users.recipient1, claimableAmount, defaults.CLAIM_AMOUNT());

        // It should transfer a portion of the amount.
        expectCallToTransfer({ to: users.recipient1, value: claimableAmount });
        expectCallToClaimWithMsgValue(address(merkleVCA), defaults.MINIMUM_FEE());

        merkleVCA.claim{ value: defaults.MINIMUM_FEE() }({
            index: 1,
            recipient: users.recipient1,
            amount: defaults.CLAIM_AMOUNT(),
            merkleProof: defaults.index1Proof()
        });

        // It should update the claimed status.
        assertTrue(merkleVCA.hasClaimed(defaults.INDEX1()), "not claimed");

        // It should update forgone amount.
        assertEq(merkleVCA.forgoneAmount(), defaults.CLAIM_AMOUNT() - claimableAmount, "forgone amount");
    }
}
