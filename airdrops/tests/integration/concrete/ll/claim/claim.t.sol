// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierMerkleLL } from "src/interfaces/ISablierMerkleLL.sol";
import { MerkleLL } from "src/types/DataTypes.sol";

import { Claim_Integration_Test } from "../../shared/claim/claim.t.sol";
import { MerkleLL_Integration_Shared_Test, Integration_Test } from "../MerkleLL.t.sol";

contract Claim_MerkleLL_Integration_Test is Claim_Integration_Test, MerkleLL_Integration_Shared_Test {
    MerkleLL.Schedule internal schedule;

    function setUp() public virtual override(MerkleLL_Integration_Shared_Test, Integration_Test) {
        MerkleLL_Integration_Shared_Test.setUp();
        schedule = defaults.schedule();
    }

    function test_WhenScheduledCliffDurationZero() external whenMerkleProofValid whenScheduledStartTimeZero {
        schedule.cliffDuration = 0;
        schedule.cliffAmount = 0;

        merkleLL = merkleFactory.createMerkleLL({
            baseParams: defaults.baseParams(),
            lockup: lockup,
            cancelable: defaults.CANCELABLE(),
            transferable: defaults.TRANSFERABLE(),
            schedule: schedule,
            aggregateAmount: defaults.AGGREGATE_AMOUNT(),
            recipientCount: defaults.RECIPIENT_COUNT()
        });

        // It should create a stream with block.timestamp as start time.
        // It should create a stream with cliff as zero.
        _test_Claim({ startTime: getBlockTimestamp(), cliffTime: 0 });
    }

    function test_WhenScheduledCliffDurationNotZero() external whenMerkleProofValid whenScheduledStartTimeZero {
        // It should create a stream with block.timestamp as start time.
        // It should create a stream with cliff as start time + cliff duration.
        _test_Claim({ startTime: getBlockTimestamp(), cliffTime: getBlockTimestamp() + defaults.CLIFF_DURATION() });
    }

    function test_WhenScheduledStartTimeNotZero() external whenMerkleProofValid {
        schedule.startTime = defaults.STREAM_START_TIME_NON_ZERO();

        merkleLL = merkleFactory.createMerkleLL({
            baseParams: defaults.baseParams(),
            lockup: lockup,
            cancelable: defaults.CANCELABLE(),
            transferable: defaults.TRANSFERABLE(),
            schedule: schedule,
            aggregateAmount: defaults.AGGREGATE_AMOUNT(),
            recipientCount: defaults.RECIPIENT_COUNT()
        });

        // It should create a stream with scheduled start time as start time.
        _test_Claim({
            startTime: defaults.STREAM_START_TIME_NON_ZERO(),
            cliffTime: defaults.STREAM_START_TIME_NON_ZERO() + defaults.CLIFF_DURATION()
        });
    }

    /// @dev Helper function to test claim.
    function _test_Claim(uint40 startTime, uint40 cliffTime) private {
        uint256 fee = defaults.DEFAULT_FEE();
        deal({ token: address(dai), to: address(merkleLL), give: defaults.AGGREGATE_AMOUNT() });

        uint256 expectedStreamId = lockup.nextStreamId();
        uint256 previousFeeAccrued = address(merkleLL).balance;

        // It should emit a {Claim} event.
        vm.expectEmit({ emitter: address(merkleLL) });
        emit ISablierMerkleLL.Claim(defaults.INDEX1(), users.recipient1, defaults.CLAIM_AMOUNT(), expectedStreamId);

        expectCallToTransferFrom({ from: address(merkleLL), to: address(lockup), value: defaults.CLAIM_AMOUNT() });
        expectCallToClaimWithMsgValue(address(merkleLL), fee);

        // Claim the airstream.
        merkleLL.claim{ value: fee }(
            defaults.INDEX1(), users.recipient1, defaults.CLAIM_AMOUNT(), defaults.index1Proof()
        );

        // Assert that the stream has been created successfully.
        assertEq(lockup.getDepositedAmount(expectedStreamId), defaults.CLAIM_AMOUNT(), "depositedAmount");
        assertEq(lockup.getAsset(expectedStreamId), dai, "token");
        assertEq(lockup.getCliffTime(expectedStreamId), cliffTime, "cliff time");
        assertEq(lockup.getEndTime(expectedStreamId), startTime + defaults.TOTAL_DURATION(), "end time");
        assertEq(lockup.isCancelable(expectedStreamId), defaults.CANCELABLE(), "is cancelable");
        assertEq(lockup.isDepleted(expectedStreamId), false, "is depleted");
        assertEq(lockup.isStream(expectedStreamId), true, "is stream");
        assertEq(lockup.isTransferable(expectedStreamId), defaults.TRANSFERABLE(), "is transferable");
        assertEq(lockup.getRecipient(expectedStreamId), users.recipient1, "recipient");
        assertEq(lockup.getSender(expectedStreamId), users.campaignOwner, "sender");
        assertEq(lockup.getStartTime(expectedStreamId), startTime, "start time");
        assertEq(lockup.wasCanceled(expectedStreamId), false, "was canceled");

        assertEq(lockup.getUnlockAmounts(expectedStreamId).start, defaults.START_AMOUNT(), "unlock amount start");

        uint128 expectedCliffAmount = cliffTime > 0 ? defaults.CLIFF_AMOUNT() : 0;
        assertEq(lockup.getUnlockAmounts(expectedStreamId).cliff, expectedCliffAmount, "unlock amount cliff");

        assertTrue(merkleLL.hasClaimed(defaults.INDEX1()), "not claimed");

        assertEq(address(merkleLL).balance, previousFeeAccrued + defaults.DEFAULT_FEE(), "fee collected");
    }
}
