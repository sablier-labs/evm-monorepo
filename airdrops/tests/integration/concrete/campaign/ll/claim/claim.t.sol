// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ud, ZERO } from "@prb/math/src/UD60x18.sol";
import { Errors as LockupErrors } from "@sablier/lockup/src/libraries/Errors.sol";
import { Lockup } from "@sablier/lockup/src/types/DataTypes.sol";

import { ISablierMerkleLL } from "src/interfaces/ISablierMerkleLL.sol";
import { MerkleLL } from "src/types/DataTypes.sol";

import { Claim_Integration_Test } from "../../shared/claim/claim.t.sol";
import { MerkleLL_Integration_Shared_Test, Integration_Test } from "../MerkleLL.t.sol";

contract Claim_MerkleLL_Integration_Test is Claim_Integration_Test, MerkleLL_Integration_Shared_Test {
    function setUp() public virtual override(MerkleLL_Integration_Shared_Test, Integration_Test) {
        MerkleLL_Integration_Shared_Test.setUp();
    }

    function test_WhenVestingEndTimeNotExceedClaimTime() external whenMerkleProofValid {
        // Forward in time to the end of the vesting period.
        vm.warp({ newTimestamp: VESTING_END_TIME });

        uint256 expectedRecipientBalance = dai.balanceOf(users.recipient) + CLAIM_AMOUNT;

        // It should emit a {ClaimLLWithTransfer} event.
        vm.expectEmit({ emitter: address(merkleLL) });
        emit ISablierMerkleLL.ClaimLLWithTransfer(
            getIndexInMerkleTree(), users.recipient, CLAIM_AMOUNT, users.recipient, false
        );

        expectCallToTransfer({ to: users.recipient, value: CLAIM_AMOUNT });
        expectCallToClaimWithMsgValue(address(merkleLL), AIRDROP_MIN_FEE_WEI);

        claim();

        // It should transfer the tokens to the recipient.
        assertEq(dai.balanceOf(users.recipient), expectedRecipientBalance, "recipient balance");
    }

    function test_RevertWhen_TotalPercentageGreaterThan100()
        external
        whenMerkleProofValid
        whenVestingEndTimeExceedsClaimTime
    {
        MerkleLL.ConstructorParams memory params = merkleLLConstructorParams();

        // Crate a MerkleLL campaign with a total percentage greater than 100.
        params.startUnlockPercentage = ud(0.5e18);
        params.cliffUnlockPercentage = ud(0.6e18);

        merkleLL = factoryMerkleLL.createMerkleLL(params, AGGREGATE_AMOUNT, RECIPIENT_COUNT);

        // Cast the {MerkleLL} contract as {ISablierMerkleBase}.
        merkleBase = merkleLL;

        uint128 startUnlockAmount = ud(CLAIM_AMOUNT).mul(ud(0.5e18)).intoUint128();
        uint128 cliffUnlockAmount = ud(CLAIM_AMOUNT).mul(ud(0.6e18)).intoUint128();

        vm.expectRevert(
            abi.encodeWithSelector(
                LockupErrors.SablierHelpers_UnlockAmountsSumTooHigh.selector,
                CLAIM_AMOUNT,
                startUnlockAmount,
                cliffUnlockAmount
            )
        );

        // Claim the airdrop.
        claim();
    }

    function test_WhenVestingStartTimeZero()
        external
        whenMerkleProofValid
        whenVestingEndTimeExceedsClaimTime
        whenTotalPercentageNotGreaterThan100
    {
        MerkleLL.ConstructorParams memory params = merkleLLConstructorParams();
        params.vestingStartTime = 0;

        merkleLL = factoryMerkleLL.createMerkleLL(params, AGGREGATE_AMOUNT, RECIPIENT_COUNT);

        // It should create a stream with block timestamp as vesting start time.
        _test_Claim({ streamStartTime: getBlockTimestamp(), cliffTime: getBlockTimestamp() + VESTING_CLIFF_DURATION });
    }

    function test_WhenCliffDurationZero()
        external
        whenMerkleProofValid
        whenVestingEndTimeExceedsClaimTime
        whenTotalPercentageNotGreaterThan100
        whenVestingStartTimeNotZero
    {
        MerkleLL.ConstructorParams memory params = merkleLLConstructorParams();
        params.cliffDuration = 0;
        params.cliffUnlockPercentage = ZERO;

        merkleLL = factoryMerkleLL.createMerkleLL(params, AGGREGATE_AMOUNT, RECIPIENT_COUNT);

        // It should create a stream with block timestamp as vesting start time.
        // It should create a stream with cliff as zero.
        _test_Claim({ streamStartTime: VESTING_START_TIME, cliffTime: 0 });
    }

    function test_WhenCliffDurationNotZero()
        external
        whenMerkleProofValid
        whenVestingEndTimeExceedsClaimTime
        whenTotalPercentageNotGreaterThan100
        whenVestingStartTimeNotZero
    {
        // It should create a stream with block timestamp as vesting start time.
        // It should create a stream with cliff as vesting start time + cliff duration.
        _test_Claim({ streamStartTime: VESTING_START_TIME, cliffTime: VESTING_START_TIME + VESTING_CLIFF_DURATION });
    }

    /// @dev Helper function to test claim.
    function _test_Claim(uint40 streamStartTime, uint40 cliffTime) private {
        // Cast the {MerkleLL} contract as {ISablierMerkleBase}.
        merkleBase = merkleLL;

        deal({ token: address(dai), to: address(merkleLL), give: AGGREGATE_AMOUNT });

        uint256 expectedStreamId = lockup.nextStreamId();
        uint256 previousFeeAccrued = address(comptroller).balance;

        // It should emit a {ClaimLLWithVesting} event.
        vm.expectEmit({ emitter: address(merkleLL) });
        emit ISablierMerkleLL.ClaimLLWithVesting(
            getIndexInMerkleTree(), users.recipient, CLAIM_AMOUNT, expectedStreamId, users.recipient, false
        );

        expectCallToTransferFrom({ from: address(merkleLL), to: address(lockup), value: CLAIM_AMOUNT });
        expectCallToClaimWithMsgValue(address(merkleLL), AIRDROP_MIN_FEE_WEI);

        // Claim the airstream.
        claim();

        uint128 expectedUnlockCliffAmount = cliffTime > 0 ? CLIFF_AMOUNT : 0;

        // Assert that the stream has been created successfully.
        assertEq(lockup.getCliffTime(expectedStreamId), cliffTime, "vesting cliff time");
        assertEq(lockup.getDepositedAmount(expectedStreamId), CLAIM_AMOUNT, "depositedAmount");
        assertEq(lockup.getEndTime(expectedStreamId), streamStartTime + VESTING_TOTAL_DURATION, "stream end time");
        assertEq(lockup.getRecipient(expectedStreamId), users.recipient, "recipient");
        assertEq(lockup.getSender(expectedStreamId), users.campaignCreator, "sender");
        assertEq(lockup.getStartTime(expectedStreamId), streamStartTime, "stream start time");
        assertEq(lockup.getUnderlyingToken(expectedStreamId), dai, "token");
        assertEq(lockup.getUnlockAmounts(expectedStreamId).cliff, expectedUnlockCliffAmount, "unlock cliff amount");
        assertEq(lockup.getUnlockAmounts(expectedStreamId).start, UNLOCK_START_AMOUNT, "unlock start amount");
        assertEq(lockup.isCancelable(expectedStreamId), STREAM_CANCELABLE, "is cancelable");
        assertEq(lockup.isDepleted(expectedStreamId), false, "is depleted");
        assertEq(lockup.isStream(expectedStreamId), true, "is stream");
        assertEq(lockup.isTransferable(expectedStreamId), STREAM_TRANSFERABLE, "is transferable");
        assertEq(lockup.wasCanceled(expectedStreamId), false, "was canceled");

        assertTrue(merkleLL.hasClaimed(getIndexInMerkleTree()), "not claimed");

        // It should create the stream with the correct Lockup model.
        assertEq(lockup.getLockupModel(expectedStreamId), Lockup.Model.LOCKUP_LINEAR);

        uint256[] memory expectedClaimedStreamIds = new uint256[](1);
        expectedClaimedStreamIds[0] = expectedStreamId;
        assertEq(merkleLL.claimedStreams(users.recipient), expectedClaimedStreamIds, "claimed streams");

        assertEq(address(comptroller).balance, previousFeeAccrued + AIRDROP_MIN_FEE_WEI, "fee collected");
    }
}
