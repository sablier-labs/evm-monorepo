// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleVCA } from "src/interfaces/ISablierMerkleVCA.sol";
import { Errors } from "src/libraries/Errors.sol";
import { MerkleVCA } from "src/types/DataTypes.sol";

import { Claim_Integration_Test } from "../../shared/claim/claim.t.sol";
import { MerkleVCA_Integration_Shared_Test, Integration_Test } from "../MerkleVCA.t.sol";

contract Claim_MerkleVCA_Integration_Test is Claim_Integration_Test, MerkleVCA_Integration_Shared_Test {
    function setUp() public virtual override(MerkleVCA_Integration_Shared_Test, Integration_Test) {
        MerkleVCA_Integration_Shared_Test.setUp();
    }

    function test_RevertWhen_VestingStartTimeInFuture() external whenMerkleProofValid {
        // Create a new campaign with vesting start time in the future.
        MerkleVCA.ConstructorParams memory params = merkleVCAConstructorParams();
        params.vestingStartTime = getBlockTimestamp() + 1 seconds;
        merkleVCA = createMerkleVCA(params);

        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierMerkleVCA_ClaimAmountZero.selector, users.recipient1));

        // Claim the airdrop.
        merkleVCA.claim{ value: MIN_FEE_WEI }({
            index: INDEX1,
            recipient: users.recipient1,
            fullAmount: CLAIM_AMOUNT,
            merkleProof: index1Proof()
        });
    }

    function test_WhenVestingStartTimeInPresent() external whenMerkleProofValid whenVestingStartTimeNotInFuture {
        // Create a new campaign with vesting start time in the present.
        MerkleVCA.ConstructorParams memory params = merkleVCAConstructorParams();
        params.vestingStartTime = getBlockTimestamp();
        merkleVCA = createMerkleVCA(params);

        _test_Claim(VCA_UNLOCK_AMOUNT);
    }

    function test_WhenVestingEndTimeInPast() external whenMerkleProofValid whenVestingStartTimeNotInFuture {
        // Forward in time so that the vesting end time is in the past.
        vm.warp({ newTimestamp: VESTING_END_TIME });

        _test_Claim(VCA_FULL_AMOUNT);
    }

    function test_WhenVestingEndTimeNotInPast() external whenMerkleProofValid whenVestingStartTimeNotInFuture {
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
            forgoneAmount: forgoneAmount,
            to: users.recipient1
        });

        // It should transfer a portion of the amount.
        expectCallToTransfer({ to: users.recipient1, value: claimAmount });
        expectCallToClaimWithMsgValue(address(merkleVCA), MIN_FEE_WEI);

        claim();

        // It should update the claimed status.
        assertTrue(merkleVCA.hasClaimed(INDEX1), "not claimed");

        // It should update the total forgone amount.
        assertEq(merkleVCA.totalForgoneAmount(), forgoneAmount, "total forgone amount");
    }
}
