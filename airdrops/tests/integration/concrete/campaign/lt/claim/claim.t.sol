// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Lockup } from "@sablier/lockup/src/types/DataTypes.sol";

import { ISablierMerkleLT } from "src/interfaces/ISablierMerkleLT.sol";
import { MerkleLT } from "src/types/DataTypes.sol";

import { Claim_Integration_Test } from "../../shared/claim/claim.t.sol";
import { MerkleLT_Integration_Shared_Test, Integration_Test } from "../MerkleLT.t.sol";

contract Claim_MerkleLT_Integration_Test is Claim_Integration_Test, MerkleLT_Integration_Shared_Test {
    function setUp() public virtual override(MerkleLT_Integration_Shared_Test, Integration_Test) {
        MerkleLT_Integration_Shared_Test.setUp();
    }

    function test_WhenVestingEndTimeNotExceedClaimTime() external whenMerkleProofValid {
        // Forward in time to the end of the vesting period.
        vm.warp({ newTimestamp: VESTING_END_TIME });

        uint256 expectedRecipientBalance = dai.balanceOf(users.recipient) + CLAIM_AMOUNT;

        // It should emit a {ClaimLTWithTransfer} event.
        vm.expectEmit({ emitter: address(merkleLT) });
        emit ISablierMerkleLT.ClaimLTWithTransfer(
            getIndexInMerkleTree(), users.recipient, CLAIM_AMOUNT, users.recipient, false
        );

        expectCallToTransfer({ to: users.recipient, value: CLAIM_AMOUNT });
        expectCallToClaimWithMsgValue(address(merkleLT), AIRDROP_MIN_FEE_WEI);

        claim();

        // It should transfer the tokens to the recipient.
        assertEq(dai.balanceOf(users.recipient), expectedRecipientBalance, "recipient balance");
    }

    function test_WhenVestingStartTimeZero() external whenMerkleProofValid whenVestingEndTimeExceedsClaimTime {
        MerkleLT.ConstructorParams memory params = merkleLTConstructorParams();
        params.vestingStartTime = 0;

        // Create the MerkleLT campaign and cast it as {ISablierMerkleBase}.
        merkleLT = factoryMerkleLT.createMerkleLT(params, AGGREGATE_AMOUNT, RECIPIENT_COUNT);
        merkleBase = merkleLT;

        // It should create a stream with `block.timestamp` as vesting start time.
        _test_Claim({ streamStartTime: getBlockTimestamp() });
    }

    function test_WhenVestingStartTimeNotZero() external whenMerkleProofValid whenVestingEndTimeExceedsClaimTime {
        // It should create a ranged stream with provided vesting start time.
        _test_Claim({ streamStartTime: VESTING_START_TIME });
    }

    /// @dev Helper function to test claim.
    function _test_Claim(uint40 streamStartTime) private {
        deal({ token: address(dai), to: address(merkleLT), give: AGGREGATE_AMOUNT });

        uint256 expectedStreamId = lockup.nextStreamId();
        uint256 previousFeeAccrued = address(comptroller).balance;

        // It should emit a {ClaimLTWithVesting} event.
        vm.expectEmit({ emitter: address(merkleLT) });
        emit ISablierMerkleLT.ClaimLTWithVesting(
            getIndexInMerkleTree(), users.recipient, CLAIM_AMOUNT, expectedStreamId, users.recipient, false
        );

        expectCallToTransferFrom({ from: address(merkleLT), to: address(lockup), value: CLAIM_AMOUNT });
        expectCallToClaimWithMsgValue(address(merkleLT), AIRDROP_MIN_FEE_WEI);

        // Claim the airstream.
        claim();

        // Assert that the stream has been created successfully.
        assertEq(lockup.getDepositedAmount(expectedStreamId), CLAIM_AMOUNT, "depositedAmount");
        assertEq(lockup.getEndTime(expectedStreamId), streamStartTime + VESTING_TOTAL_DURATION, "stream end time");
        assertEq(lockup.getRecipient(expectedStreamId), users.recipient, "recipient");
        assertEq(lockup.getSender(expectedStreamId), users.campaignCreator, "sender");
        assertEq(lockup.getStartTime(expectedStreamId), streamStartTime, "stream start time");
        // It should create a stream with `VESTING_START_TIME` as vesting start time.
        assertEq(
            lockup.getTranches(expectedStreamId),
            tranchesMerkleLT({ streamStartTime: streamStartTime, totalAmount: CLAIM_AMOUNT })
        );
        assertEq(lockup.getUnderlyingToken(expectedStreamId), dai, "token");
        assertEq(lockup.isCancelable(expectedStreamId), STREAM_CANCELABLE, "is cancelable");
        assertEq(lockup.isDepleted(expectedStreamId), false, "is depleted");
        assertEq(lockup.isStream(expectedStreamId), true, "is stream");
        assertEq(lockup.isTransferable(expectedStreamId), STREAM_TRANSFERABLE, "is transferable");
        assertEq(lockup.wasCanceled(expectedStreamId), false, "was canceled");

        assertTrue(merkleLT.hasClaimed(getIndexInMerkleTree()), "not claimed");

        // It should create the stream with the correct Lockup model.
        assertEq(lockup.getLockupModel(expectedStreamId), Lockup.Model.LOCKUP_TRANCHED);

        uint256[] memory expectedClaimedStreamIds = new uint256[](1);
        expectedClaimedStreamIds[0] = expectedStreamId;
        assertEq(merkleLT.claimedStreams(users.recipient), expectedClaimedStreamIds, "claimed streams");

        assertEq(address(comptroller).balance, previousFeeAccrued + AIRDROP_MIN_FEE_WEI, "fee collected");
    }
}
