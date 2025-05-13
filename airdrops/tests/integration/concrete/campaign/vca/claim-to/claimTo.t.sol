// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleVCA } from "src/interfaces/ISablierMerkleVCA.sol";
import { Errors } from "src/libraries/Errors.sol";

import { ClaimTo_Integration_Test } from "../../shared/claim-to/claimTo.t.sol";
import { MerkleVCA_Integration_Shared_Test } from "../MerkleVCA.t.sol";

contract ClaimTo_MerkleVCA_Integration_Test is ClaimTo_Integration_Test, MerkleVCA_Integration_Shared_Test {
    function setUp() public virtual override(MerkleVCA_Integration_Shared_Test, ClaimTo_Integration_Test) {
        MerkleVCA_Integration_Shared_Test.setUp();
        ClaimTo_Integration_Test.setUp();
    }

    function test_RevertWhen_StartTimeInFuture() external whenMerkleProofValid {
        // Move back in time so that the start time is in the future.
        vm.warp({ newTimestamp: VESTING_START_TIME - 1 seconds });

        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierMerkleVCA_ClaimAmountZero.selector, users.recipient1));

        // Claim the airdrop.
        claimTo();
    }

    function test_WhenStartTimeInPresent() external whenMerkleProofValid whenStartTimeNotInFuture {
        // Forward in time so that the end time is in the past.
        vm.warp({ newTimestamp: VCA_START_TIME });

        _test_ClaimTo(VCA_UNLOCK_AMOUNT);
    }

    function test_WhenEndTimeInPast() external whenMerkleProofValid whenStartTimeNotInFuture {
        // Forward in time so that the end time is in the past.
        vm.warp({ newTimestamp: VESTING_END_TIME });

        _test_ClaimTo(VCA_FULL_AMOUNT);
    }

    function test_WhenEndTimeNotInPast() external whenMerkleProofValid whenStartTimeNotInFuture {
        _test_ClaimTo(VCA_CLAIM_AMOUNT);
    }

    function _test_ClaimTo(uint128 claimAmount) private {
        uint128 forgoneAmount = VCA_FULL_AMOUNT - claimAmount;

        // It should emit a {Claim} event.
        vm.expectEmit({ emitter: address(merkleVCA) });
        emit ISablierMerkleVCA.Claim({
            index: INDEX1,
            recipient: users.recipient1,
            claimAmount: claimAmount,
            forgoneAmount: forgoneAmount,
            to: users.eve
        });

        // It should transfer a portion of the amount to Eve.
        expectCallToTransfer({ to: users.eve, value: claimAmount });
        expectCallToClaimToWithMsgValue(address(merkleVCA), MIN_FEE_WEI);

        claimTo();

        // It should update the claimed status.
        assertTrue(merkleVCA.hasClaimed(INDEX1), "not claimed");

        // It should update the total forgone amount.
        assertEq(merkleVCA.totalForgoneAmount(), forgoneAmount, "total forgone amount");
    }
}
