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
        // Move back in time so that the start time is in the future.
        vm.warp({ newTimestamp: VESTING_START_TIME - 1 seconds });

        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierMerkleVCA_ClaimAmountZero.selector, users.recipient1));

        // Claim the airdrop.
        merkleVCA.claim{ value: MIN_FEE_WEI }({
            index: 1,
            recipient: users.recipient1,
            amount: VCA_FULL_AMOUNT,
            merkleProof: index1Proof()
        });
    }

    function test_WhenStartTimeInPresent() external whenMerkleProofValid whenStartTimeNotInFuture {
        // Forward in time so that the end time is in the past.
        vm.warp({ newTimestamp: VCA_START_TIME });

        _test_Claim(VCA_UNLOCK_AMOUNT);
    }

    function test_WhenEndTimeInPast() external whenMerkleProofValid whenStartTimeNotInFuture {
        // Forward in time so that the end time is in the past.
        vm.warp({ newTimestamp: VESTING_END_TIME });

        _test_Claim(VCA_FULL_AMOUNT);
    }

    function test_WhenEndTimeNotInPast() external whenMerkleProofValid whenStartTimeNotInFuture {
        _test_Claim(VCA_CLAIM_AMOUNT);
    }

    function _test_Claim(uint128 claimAmount) private {
        uint128 forgoneAmount = VCA_FULL_AMOUNT - claimAmount;

        // It should emit a {Claim} event.
        vm.expectEmit({ emitter: address(merkleVCA) });
        emit ISablierMerkleVCA.Claim({
            index: INDEX1,
            recipient: users.recipient1,
            claimAmount: claimAmount,
            forgoneAmount: forgoneAmount
        });

        // It should transfer a portion of the amount.
        expectCallToTransfer({ to: users.recipient1, value: claimAmount });
        expectCallToClaimWithMsgValue(address(merkleVCA), MIN_FEE_WEI);

        merkleVCA.claim{ value: MIN_FEE_WEI }({
            index: INDEX1,
            recipient: users.recipient1,
            amount: VCA_FULL_AMOUNT,
            merkleProof: index1Proof()
        });

        // It should update the claimed status.
        assertTrue(merkleVCA.hasClaimed(INDEX1), "not claimed");

        // It should update the total forgone amount.
        assertEq(merkleVCA.totalForgoneAmount(), forgoneAmount, "total forgone amount");
    }
}
