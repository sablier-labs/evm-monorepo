// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleVCA } from "src/interfaces/ISablierMerkleVCA.sol";
import { Errors } from "src/libraries/Errors.sol";
import { MerkleVCA } from "src/types/DataTypes.sol";

import { ClaimTo_Integration_Test } from "../../shared/claim-to/claimTo.t.sol";
import { MerkleVCA_Integration_Shared_Test } from "../MerkleVCA.t.sol";

contract ClaimTo_MerkleVCA_Integration_Test is ClaimTo_Integration_Test, MerkleVCA_Integration_Shared_Test {
    function setUp() public virtual override(MerkleVCA_Integration_Shared_Test, ClaimTo_Integration_Test) {
        MerkleVCA_Integration_Shared_Test.setUp();
        ClaimTo_Integration_Test.setUp();
    }

    function test_RevertWhen_VestingStartTimeInFuture() external whenMerkleProofValid {
        // Create a new campaign with vesting start time in the future.
        MerkleVCA.ConstructorParams memory params = merkleVCAConstructorParams();
        params.vestingStartTime = getBlockTimestamp() + 1 seconds;
        merkleVCA = createMerkleVCA(params);

        // It should revert.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierMerkleVCA_ClaimAmountZero.selector, users.recipient));

        // Claim the airdrop.
        merkleVCA.claimTo{ value: MIN_FEE_WEI }({
            index: getIndexInMerkleTree(),
            to: users.eve,
            fullAmount: CLAIM_AMOUNT,
            merkleProof: getMerkleProof()
        });
    }

    function test_WhenVestingStartTimeInPresent() external whenMerkleProofValid whenVestingStartTimeNotInFuture {
        // Create a new campaign with vesting start time in the present.
        MerkleVCA.ConstructorParams memory params = merkleVCAConstructorParams();
        params.vestingStartTime = getBlockTimestamp();
        merkleVCA = createMerkleVCA(params);

        _test_ClaimTo(VCA_UNLOCK_AMOUNT);
    }

    function test_WhenVestingEndTimeInPast() external whenMerkleProofValid whenVestingStartTimeNotInFuture {
        // Forward in time so that the vesting end time is in the past.
        vm.warp({ newTimestamp: VESTING_END_TIME });

        _test_ClaimTo(VCA_FULL_AMOUNT);
    }

    function test_WhenVestingEndTimeNotInPast() external whenMerkleProofValid whenVestingStartTimeNotInFuture {
        _test_ClaimTo(VCA_CLAIM_AMOUNT);
    }

    function _test_ClaimTo(uint128 claimAmount) private {
        // Cast the {MerkleVCA} contract as {ISablierMerkleBase}.
        merkleBase = merkleVCA;

        uint256 index = getIndexInMerkleTree();

        uint128 forgoneAmount = VCA_FULL_AMOUNT - claimAmount;
        uint256 previousFeeAccrued = address(factoryMerkleVCA).balance;

        // It should emit a {Claim} event.
        vm.expectEmit({ emitter: address(merkleVCA) });
        emit ISablierMerkleVCA.Claim({
            index: index,
            recipient: users.recipient,
            claimAmount: claimAmount,
            forgoneAmount: forgoneAmount,
            to: users.eve
        });

        // It should transfer a portion of the amount to Eve.
        expectCallToTransfer({ to: users.eve, value: claimAmount });
        expectCallToClaimToWithMsgValue(address(merkleVCA), MIN_FEE_WEI);

        claimTo();

        // It should update the claimed status.
        assertTrue(merkleVCA.hasClaimed(index), "not claimed");

        // It should update the total forgone amount.
        assertEq(merkleVCA.totalForgoneAmount(), forgoneAmount, "total forgone amount");

        assertEq(address(factoryMerkleVCA).balance, previousFeeAccrued + MIN_FEE_WEI, "fee collected");
    }
}
