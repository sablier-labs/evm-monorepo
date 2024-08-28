// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { Lockup, LockupLinear } from "src/core/types/DataTypes.sol";
import { MerkleLL } from "src/periphery/types/DataTypes.sol";

import { MerkleLL_Integration_Shared_Test } from "../MerkleLL.t.sol";
import { Claim_Integration_Test } from "../../shared/claim/claim.t.sol";

contract Claim_MerkleLL_Integration_Test is Claim_Integration_Test, MerkleLL_Integration_Shared_Test {
    MerkleLL.Schedule internal schedule;

    function setUp() public override(Claim_Integration_Test, MerkleLL_Integration_Shared_Test) {
        super.setUp();
        schedule = defaults.schedule();
    }

    modifier whenScheduledStartTimeZero() {
        _;
    }

    function test_WhenScheduledCliffDurationZero() external whenMerkleProofValid whenScheduledStartTimeZero {
        schedule.cliffDuration = 0;

        merkleLL = merkleFactory.createMerkleLL({
            baseParams: defaults.baseParams(),
            lockupLinear: lockupLinear,
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
            lockupLinear: lockupLinear,
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
        deal({ token: address(dai), to: address(merkleLL), give: defaults.AGGREGATE_AMOUNT() });

        uint256 expectedStreamId = lockupLinear.nextStreamId();

        // It should emit a {Claim} event.
        vm.expectEmit({ emitter: address(merkleLL) });
        emit Claim(defaults.INDEX1(), users.recipient1, defaults.CLAIM_AMOUNT(), expectedStreamId);

        // Claim the airstream.
        merkleLL.claim(defaults.INDEX1(), users.recipient1, defaults.CLAIM_AMOUNT(), defaults.index1Proof());

        LockupLinear.StreamLL memory actualStream = lockupLinear.getStream(expectedStreamId);
        LockupLinear.StreamLL memory expectedStream = LockupLinear.StreamLL({
            amounts: Lockup.Amounts({ deposited: defaults.CLAIM_AMOUNT(), refunded: 0, withdrawn: 0 }),
            asset: dai,
            cliffTime: cliffTime,
            endTime: startTime + defaults.TOTAL_DURATION(),
            isCancelable: defaults.CANCELABLE(),
            isDepleted: false,
            isStream: true,
            isTransferable: defaults.TRANSFERABLE(),
            recipient: users.recipient1,
            sender: users.admin,
            startTime: startTime,
            wasCanceled: false
        });

        assertEq(actualStream, expectedStream);
        assertTrue(merkleLL.hasClaimed(defaults.INDEX1()), "not claimed");
    }
}
