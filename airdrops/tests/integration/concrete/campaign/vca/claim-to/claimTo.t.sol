// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleVCA } from "src/interfaces/ISablierMerkleVCA.sol";
import { Errors } from "src/libraries/Errors.sol";
import { MerkleVCA } from "src/types/DataTypes.sol";

import { Integration_Test } from "../../../../Integration.t.sol";
import { ClaimTo_Integration_Test } from "../../shared/claim-to/claimTo.t.sol";
import { Claim_Integration_Test } from "../../shared/claim/claim.t.sol";
import { MerkleVCA_Integration_Shared_Test } from "../MerkleVCA.t.sol";

/// @dev The following contract inherits from both {Claim_Integration_Test} and {ClaimTo_Integration_Test} because there
/// is no {claim} function in {MerkleVCA}. So, the tests specified in {Claim_Integration_Test} are also required to be
/// run by this contract.
contract ClaimTo_MerkleVCA_Integration_Test is
    Claim_Integration_Test,
    ClaimTo_Integration_Test,
    MerkleVCA_Integration_Shared_Test
{
    function setUp()
        public
        virtual
        override(MerkleVCA_Integration_Shared_Test, ClaimTo_Integration_Test, Integration_Test)
    {
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
        merkleVCA.claimTo{ value: AIRDROP_MIN_FEE_WEI }({
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
        uint256 previousFeeAccrued = address(comptroller).balance;

        // It should emit a {ClaimVCA} event.
        vm.expectEmit({ emitter: address(merkleVCA) });
        emit ISablierMerkleVCA.ClaimVCA({
            index: index,
            recipient: users.recipient,
            claimAmount: claimAmount,
            forgoneAmount: forgoneAmount,
            to: users.eve,
            viaSig: false
        });

        // It should transfer a portion of the amount to Eve.
        expectCallToTransfer({ to: users.eve, value: claimAmount });
        expectCallToClaimToWithMsgValue(address(merkleVCA), AIRDROP_MIN_FEE_WEI);

        claimTo();

        // It should update the claimed status.
        assertTrue(merkleVCA.hasClaimed(index), "not claimed");

        // It should update the total forgone amount.
        assertEq(merkleVCA.totalForgoneAmount(), forgoneAmount, "total forgone amount");

        assertEq(address(comptroller).balance, previousFeeAccrued + AIRDROP_MIN_FEE_WEI, "fee collected");
    }

    /*//////////////////////////////////////////////////////////////////////////
                                OVERRIDDEN-FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Overrides the {claim} function defined in {Integration_Test} to use {claimTo} instead.
    function claim() internal override {
        claimTo({
            msgValue: AIRDROP_MIN_FEE_WEI,
            index: getIndexInMerkleTree(),
            to: users.recipient,
            amount: CLAIM_AMOUNT,
            merkleProof: getMerkleProof()
        });
    }

    /// @dev Overrides the {claim} function defined in {Integration_Test} to use {claimTo} instead.
    function claim(
        uint256 msgValue,
        uint256 index,
        address recipient,
        uint128 amount,
        bytes32[] memory merkleProof
    )
        internal
        override
    {
        address campaignAddr = address(merkleVCA);

        ISablierMerkleVCA(campaignAddr).claimTo{ value: msgValue }(index, recipient, amount, merkleProof);
    }

    /// @dev Overrides the {test_WhenMerkleProofValid} function defined in both {ClaimTo_Integration_Test} and
    /// {Claim_Integration_Test}.
    function test_WhenMerkleProofValid() external override(ClaimTo_Integration_Test, Claim_Integration_Test) { }
}
