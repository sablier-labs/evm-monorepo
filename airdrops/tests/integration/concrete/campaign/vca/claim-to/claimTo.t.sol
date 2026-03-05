// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleVCA } from "src/interfaces/ISablierMerkleVCA.sol";
import { Errors } from "src/libraries/Errors.sol";
import { ClaimType } from "src/types/MerkleBase.sol";
import { MerkleVCA } from "src/types/MerkleVCA.sol";

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
    function setUp() public override(MerkleVCA_Integration_Shared_Test, ClaimTo_Integration_Test, Integration_Test) {
        MerkleVCA_Integration_Shared_Test.setUp();
        ClaimTo_Integration_Test.setUp();

        // Warp to campaign start time.
        vm.warp({ newTimestamp: CAMPAIGN_START_TIME });

        // Claim early for a user so that there is some forgone amount.
        setMsgSender(users.unknownRecipient);
        claimTo({
            msgValue: AIRDROP_MIN_FEE_WEI,
            index: getIndexInMerkleTree(users.unknownRecipient),
            to: users.unknownRecipient,
            amount: VCA_FULL_AMOUNT,
            merkleProof: getMerkleProof(users.unknownRecipient)
        });

        // Set the recipient as the caller for this test.
        setMsgSender(users.recipient);
    }

    function test_RevertWhen_VestingStartTimeInFuture() external givenDefaultClaimType whenMerkleProofValid {
        // Create a new campaign with vesting start time in the future.
        MerkleVCA.ConstructorParams memory params = merkleVCAConstructorParams();
        params.vestingStartTime = getBlockTimestamp() + 1 seconds;
        merkleVCA = createMerkleVCA(params);
        merkleBase = merkleVCA;

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

    function test_WhenVestingStartTimeInPresent() external givenDefaultClaimType whenMerkleProofValid {
        // Create a new campaign with vesting start time in the present.
        MerkleVCA.ConstructorParams memory params = merkleVCAConstructorParams();
        params.vestingStartTime = getBlockTimestamp();
        merkleVCA = createMerkleVCA(params);
        merkleBase = merkleVCA;

        _test_ClaimTo({
            expectedTransferAmount: VCA_UNLOCK_AMOUNT,
            forgoneAmount: VCA_FULL_AMOUNT - VCA_UNLOCK_AMOUNT,
            isRedistributionEnabled: false
        });
    }

    function test_WhenVestingEndTimeInFuture()
        external
        givenDefaultClaimType
        whenMerkleProofValid
        whenVestingStartTimeInPast
    {
        _test_ClaimTo({
            expectedTransferAmount: VCA_CLAIM_AMOUNT,
            forgoneAmount: VCA_FULL_AMOUNT - VCA_CLAIM_AMOUNT,
            isRedistributionEnabled: false
        });
    }

    function test_GivenRedistributionNotEnabled()
        external
        givenDefaultClaimType
        whenMerkleProofValid
        whenVestingStartTimeInPast
        whenVestingEndTimeNotInFuture
    {
        // Forward in time so that the vesting end time is not in the future.
        vm.warp({ newTimestamp: VESTING_END_TIME });

        _test_ClaimTo({ expectedTransferAmount: VCA_FULL_AMOUNT, forgoneAmount: 0, isRedistributionEnabled: false });
    }

    function test_WhenRewardExceedsRemainingBalance()
        external
        givenDefaultClaimType
        whenMerkleProofValid
        whenVestingStartTimeInPast
        whenVestingEndTimeNotInFuture
        givenRedistributionEnabled(merkleVCA)
    {
        // Deploy a new campaign with undervalued aggregate amount. We choose the value such that after one early claim
        // (which sets `_fullAmountAllocatedToEarlyClaimers` = VCA_FULL_AMOUNT),
        // `fullAmountAllocatedToRemainingClaimers` becomes VCA_CLAIM_AMOUNT. This sets the uncapped reward to
        // (VCA_FULL_AMOUNT * (VCA_FULL_AMOUNT - VCA_CLAIM_AMOUNT)) / VCA_CLAIM_AMOUNT, which far exceeds the
        // redistribution balance (VCA_CLAIM_AMOUNT).
        MerkleVCA.ConstructorParams memory params = merkleVCAConstructorParams();
        params.aggregateAmount = VCA_FULL_AMOUNT + VCA_CLAIM_AMOUNT;
        params.enableRedistribution = true;
        merkleVCA = createMerkleVCA(params);

        // Have an early claim..
        setMsgSender(users.unknownRecipient);
        merkleVCA.claimTo{ value: AIRDROP_MIN_FEE_WEI }({
            index: getIndexInMerkleTree(users.unknownRecipient),
            to: users.unknownRecipient,
            fullAmount: VCA_FULL_AMOUNT,
            merkleProof: getMerkleProof(users.unknownRecipient)
        });

        // Forward in time so that the vesting end time is not in the future.
        vm.warp({ newTimestamp: VESTING_END_TIME });

        // The capped reward equals the total forgone amount since the uncapped reward exceeds
        // the remaining redistribution balance.
        uint128 expectedReward = VCA_FULL_AMOUNT - VCA_CLAIM_AMOUNT;

        // Change the caller to the recipient and test the claim.
        setMsgSender(users.recipient);
        _test_ClaimTo({
            expectedTransferAmount: VCA_FULL_AMOUNT + expectedReward,
            forgoneAmount: 0,
            isRedistributionEnabled: true
        });
    }

    function test_WhenRewardNotExceedRemainingBalance()
        external
        givenDefaultClaimType
        whenMerkleProofValid
        whenVestingStartTimeInPast
        whenVestingEndTimeNotInFuture
        givenRedistributionEnabled(merkleVCA)
    {
        // Forward in time so that the vesting end time is not in the future.
        vm.warp({ newTimestamp: VESTING_END_TIME });

        // Change the caller to the recipient and test the claim.
        setMsgSender(users.recipient);
        _test_ClaimTo({
            expectedTransferAmount: VCA_FULL_AMOUNT + VCA_REWARD_AMOUNT_PER_USER,
            forgoneAmount: 0,
            isRedistributionEnabled: true
        });
    }

    /// @dev Shared private function.
    function _test_ClaimTo(
        uint128 expectedTransferAmount,
        uint128 forgoneAmount,
        bool isRedistributionEnabled
    )
        private
    {
        // Cast the {MerkleVCA} contract as {ISablierMerkleBase}.
        merkleBase = merkleVCA;

        uint256 index = getIndexInMerkleTree();
        uint256 expectedTotalForgoneAmount = merkleVCA.totalForgoneAmount() + forgoneAmount;
        uint256 previousFeeAccrued = address(comptroller).balance;

        // Calculate the reward amount from the expected transfer amount and claim amount.
        uint128 claimAmount = VCA_FULL_AMOUNT - forgoneAmount;
        uint128 rewardAmount = expectedTransferAmount - claimAmount;
        uint128 previousRedistributionPaid = merkleVCA.totalRedistributionAmountPaid();

        // It should emit a {RedistributeReward} event for claims made after the vesting end time only if
        // redistribution is enabled.
        if (isRedistributionEnabled) {
            vm.expectEmit({ emitter: address(merkleVCA) });
            emit ISablierMerkleVCA.RedistributeReward({
                index: index,
                recipient: users.recipient,
                amount: rewardAmount,
                to: users.eve
            });
        }

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

        // It should transfer the expected amount to the recipient.
        expectCallToTransfer({ to: users.eve, value: expectedTransferAmount });
        expectCallToClaimToWithMsgValue(address(merkleVCA), AIRDROP_MIN_FEE_WEI);

        claimTo();

        // It should update the claimed status.
        assertTrue(merkleVCA.hasClaimed(index), "not claimed");

        // It should update the total forgone amount.
        assertEq(merkleVCA.totalForgoneAmount(), expectedTotalForgoneAmount, "total forgone amount");

        // It should update the total redistribution amount paid.
        if (isRedistributionEnabled) {
            assertEq(
                merkleVCA.totalRedistributionAmountPaid(),
                previousRedistributionPaid + rewardAmount,
                "totalRedistributionAmountPaid"
            );
        }

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

    /// @dev Overrides the {test_RevertGiven_NotDefaultClaimType} function defined in both {ClaimTo_Integration_Test}
    /// and {Claim_Integration_Test}.
    function test_RevertGiven_NotDefaultClaimType()
        external
        override(ClaimTo_Integration_Test, Claim_Integration_Test)
    {
        merkleBase = merkleBaseAttest;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierMerkleBase_UnsupportedClaimType.selector, ClaimType.DEFAULT, ClaimType.ATTEST
            )
        );
        claimTo();
    }

    /// @dev Overrides the {test_WhenMerkleProofValid} function defined in both {ClaimTo_Integration_Test} and
    /// {Claim_Integration_Test}.
    function test_WhenMerkleProofValid() external override(ClaimTo_Integration_Test, Claim_Integration_Test) { }
}
