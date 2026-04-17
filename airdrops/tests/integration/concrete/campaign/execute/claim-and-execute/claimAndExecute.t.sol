// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import { ISablierMerkleExecute } from "src/interfaces/ISablierMerkleExecute.sol";
import { Errors } from "src/libraries/Errors.sol";
import { MerkleExecute } from "src/types/MerkleExecute.sol";

import {
    MockStakingReentrant,
    MockStakingRevert,
    MockStakingPartialTransfer
} from "./../../../../../mocks/MockStaking.sol";
import { Claim_Integration_Concrete_Test } from "./../../shared/claim/claim.t.sol";
import { Integration_Test, MerkleExecute_Integration_Shared_Test } from "./../MerkleExecute.t.sol";

contract ClaimAndExecute_MerkleExecute_Integration_Concrete_Test is
    Claim_Integration_Concrete_Test,
    MerkleExecute_Integration_Shared_Test
{
    function setUp() public virtual override(MerkleExecute_Integration_Shared_Test, Integration_Test) {
        MerkleExecute_Integration_Shared_Test.setUp();

        // Make the recipient the caller.
        setMsgSender(users.recipient);
    }

    /// @dev This test is not applicable to {MerkleExecute} campaigns since they have {ClaimType.EXECUTE} claim type by
    /// default.
    function test_RevertGiven_NotDefaultClaimType() external pure override { }

    function test_RevertWhen_TargetTransferAmountOverdraws() external whenMerkleProofValid {
        uint128 overdrawAmount = CLAIM_AMOUNT + 1;

        // It should revert because the `claimAndExecute` function only approves the claim amount.
        vm.expectRevert();
        merkleExecute.claimAndExecute{ value: AIRDROP_MIN_FEE_WEI }({
            index: getIndexInMerkleTree(),
            amount: CLAIM_AMOUNT,
            merkleProof: getMerkleProof(),
            selectorArguments: abi.encode(overdrawAmount)
        });
    }

    function test_RevertWhen_TargetCallNotSucceed() external whenMerkleProofValid whenTargetTransferAmountNotOverdraw {
        // Deploy the reverting staking contract.
        MockStakingRevert mockStakingRevert = new MockStakingRevert();

        // Create a campaign with a reverting target function.
        MerkleExecute.ConstructorParams memory params = merkleExecuteConstructorParams();
        params.target = address(mockStakingRevert);
        params.campaignName = "Reverting campaign";

        setMsgSender(users.campaignCreator);
        ISablierMerkleExecute revertingCampaign = createMerkleExecute(params);

        setMsgSender(users.recipient);

        // It should revert.
        vm.expectRevert("Shall not pass!");
        revertingCampaign.claimAndExecute{ value: AIRDROP_MIN_FEE_WEI }(
            getIndexInMerkleTree(), CLAIM_AMOUNT, getMerkleProof(), abi.encode(CLAIM_AMOUNT)
        );
    }

    function test_RevertWhen_Reentrancy()
        external
        whenMerkleProofValid
        whenTargetTransferAmountNotOverdraw
        whenTargetCallSucceeds
    {
        MockStakingReentrant mockStakingReentrant = new MockStakingReentrant(dai);

        // Create a campaign with the reentrant target.
        MerkleExecute.ConstructorParams memory params = merkleExecuteConstructorParams();
        params.target = address(mockStakingReentrant);
        params.selector = MockStakingReentrant.stake.selector;
        params.campaignName = "Reentrant campaign";

        setMsgSender(users.campaignCreator);
        ISablierMerkleExecute reentrantCampaign = createMerkleExecute(params);

        setMsgSender(users.recipient);

        uint256 index = getIndexInMerkleTree();
        bytes32[] memory merkleProof = getMerkleProof();

        // Encode the arguments that the reentrant mock will forward back to `claimAndExecute`.
        bytes memory selectorArguments = abi.encode(index, CLAIM_AMOUNT, merkleProof, abi.encode(CLAIM_AMOUNT));

        // It should revert due to reentrancy guard.
        vm.expectRevert(ReentrancyGuard.ReentrancyGuardReentrantCall.selector);
        reentrantCampaign.claimAndExecute{ value: AIRDROP_MIN_FEE_WEI }(
            index, CLAIM_AMOUNT, merkleProof, selectorArguments
        );
    }

    function test_RevertWhen_TransferAmountNotEqualClaimAmount()
        external
        whenMerkleProofValid
        whenTargetTransferAmountNotOverdraw
        whenTargetCallSucceeds
        whenNoReentrancy
    {
        MockStakingPartialTransfer mockStakingPartialTransfer = new MockStakingPartialTransfer(dai);

        // Create a custom campaign using the noop contract.
        MerkleExecute.ConstructorParams memory params = merkleExecuteConstructorParams();
        params.target = address(mockStakingPartialTransfer);

        setMsgSender(users.campaignCreator);
        ISablierMerkleExecute campaignWithInvalidTarget = createMerkleExecute(params);

        setMsgSender(users.recipient);

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierMerkleExecute_NotFullAmountTransferred.selector, CLAIM_AMOUNT / 2, CLAIM_AMOUNT
            )
        );
        campaignWithInvalidTarget.claimAndExecute{ value: AIRDROP_MIN_FEE_WEI }(
            getIndexInMerkleTree(), CLAIM_AMOUNT, getMerkleProof(), abi.encode(CLAIM_AMOUNT)
        );
    }

    function test_WhenTransferAmountEqualsClaimAmount()
        external
        whenMerkleProofValid
        whenTargetTransferAmountNotOverdraw
        whenTargetCallSucceeds
        whenNoReentrancy
    {
        uint256 previousFeeAccrued = address(comptroller).balance;
        uint256 index = getIndexInMerkleTree();
        uint256 initialCampaignBalance = dai.balanceOf(address(merkleExecute));

        // Expect the {ClaimExecute} event to be emitted.
        vm.expectEmit({ emitter: address(merkleExecute) });
        emit ISablierMerkleExecute.ClaimExecute(index, users.recipient, CLAIM_AMOUNT, address(mockStaking));

        // Claim and execute.
        claim();

        // It should mark the index as claimed.
        assertTrue(merkleExecute.hasClaimed(index), "not claimed");

        // It should collect the fee.
        assertEq(address(comptroller).balance, previousFeeAccrued + AIRDROP_MIN_FEE_WEI, "fee not collected");

        // It should transfer the tokens to the target.
        assertEq(dai.balanceOf(address(merkleExecute)), initialCampaignBalance - CLAIM_AMOUNT, "tokens not transferred");
        assertEq(dai.balanceOf(address(mockStaking)), CLAIM_AMOUNT, "tokens not received by target");
    }
}
