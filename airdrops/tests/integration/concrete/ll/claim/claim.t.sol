// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ud2x18 } from "@prb/math/src/UD2x18.sol";
import { ud60x18 } from "@prb/math/src/UD60x18.sol";
import { Errors as LockupErrors } from "@sablier/lockup/src/libraries/Errors.sol";

import { ISablierMerkleLockup } from "src/interfaces/ISablierMerkleLockup.sol";
import { MerkleLL } from "src/types/DataTypes.sol";

import { Claim_Integration_Test } from "../../shared/claim/claim.t.sol";
import { MerkleLL_Integration_Shared_Test, Integration_Test } from "../MerkleLL.t.sol";

contract Claim_MerkleLL_Integration_Test is Claim_Integration_Test, MerkleLL_Integration_Shared_Test {
    function setUp() public virtual override(MerkleLL_Integration_Shared_Test, Integration_Test) {
        MerkleLL_Integration_Shared_Test.setUp();
    }

    function test_RevertWhen_TotalPercentageGreaterThan100() external whenMerkleProofValid {
        uint256 fee = defaults.MINIMUM_FEE();

        MerkleLL.ConstructorParams memory params = merkleLLConstructorParams();

        // Crate a MerkleLL campaign with a total percentage greater than 100.
        params.schedule.startPercentage = ud2x18(0.5e18);
        params.schedule.cliffPercentage = ud2x18(0.6e18);

        merkleLL = merkleFactory.createMerkleLL(params, defaults.AGGREGATE_AMOUNT(), defaults.RECIPIENT_COUNT());

        uint128 depositAmount = defaults.CLAIM_AMOUNT();
        uint128 startUnlockAmount = ud60x18(depositAmount).mul(ud60x18(0.5e18)).intoUint128();
        uint128 cliffUnlockAmount = ud60x18(depositAmount).mul(ud60x18(0.6e18)).intoUint128();
        bytes32[] memory merkleProof = defaults.index1Proof();

        vm.expectRevert(
            abi.encodeWithSelector(
                LockupErrors.SablierHelpers_UnlockAmountsSumTooHigh.selector,
                depositAmount,
                startUnlockAmount,
                cliffUnlockAmount
            )
        );

        // Claim the airdrop.
        merkleLL.claim{ value: fee }({
            index: 1,
            recipient: users.recipient1,
            amount: depositAmount,
            merkleProof: merkleProof
        });
    }

    function test_WhenScheduledCliffDurationZero()
        external
        whenMerkleProofValid
        whenTotalPercentageNotGreaterThan100
        whenScheduledStartTimeZero
    {
        MerkleLL.ConstructorParams memory params = merkleLLConstructorParams();
        params.schedule.cliffDuration = 0;
        params.schedule.cliffPercentage = ud2x18(0);

        merkleLL = merkleFactory.createMerkleLL(params, defaults.AGGREGATE_AMOUNT(), defaults.RECIPIENT_COUNT());

        // It should create a stream with block.timestamp as start time.
        // It should create a stream with cliff as zero.
        _test_Claim({ startTime: getBlockTimestamp(), cliffTime: 0 });
    }

    function test_WhenScheduledCliffDurationNotZero()
        external
        whenMerkleProofValid
        whenTotalPercentageNotGreaterThan100
        whenScheduledStartTimeZero
    {
        // It should create a stream with block.timestamp as start time.
        // It should create a stream with cliff as start time + cliff duration.
        _test_Claim({ startTime: getBlockTimestamp(), cliffTime: getBlockTimestamp() + defaults.CLIFF_DURATION() });
    }

    function test_WhenScheduledStartTimeNotZero() external whenMerkleProofValid whenTotalPercentageNotGreaterThan100 {
        MerkleLL.ConstructorParams memory params = merkleLLConstructorParams();
        params.schedule.startTime = defaults.STREAM_START_TIME_NON_ZERO();

        merkleLL = merkleFactory.createMerkleLL(params, defaults.AGGREGATE_AMOUNT(), defaults.RECIPIENT_COUNT());

        // It should create a stream with scheduled start time as start time.
        _test_Claim({
            startTime: defaults.STREAM_START_TIME_NON_ZERO(),
            cliffTime: defaults.STREAM_START_TIME_NON_ZERO() + defaults.CLIFF_DURATION()
        });
    }

    /// @dev Helper function to test claim.
    function _test_Claim(uint40 startTime, uint40 cliffTime) private {
        uint256 fee = defaults.MINIMUM_FEE();
        deal({ token: address(dai), to: address(merkleLL), give: defaults.AGGREGATE_AMOUNT() });

        uint256 expectedStreamId = lockup.nextStreamId();
        uint256 previousFeeAccrued = address(merkleLL).balance;

        // It should emit a {Claim} event.
        vm.expectEmit({ emitter: address(merkleLL) });
        emit ISablierMerkleLockup.Claim(defaults.INDEX1(), users.recipient1, defaults.CLAIM_AMOUNT(), expectedStreamId);

        expectCallToTransferFrom({ from: address(merkleLL), to: address(lockup), value: defaults.CLAIM_AMOUNT() });
        expectCallToClaimWithMsgValue(address(merkleLL), fee);

        // Claim the airstream.
        merkleLL.claim{ value: fee }(
            defaults.INDEX1(), users.recipient1, defaults.CLAIM_AMOUNT(), defaults.index1Proof()
        );

        uint128 expectedCliffAmount = cliffTime > 0 ? defaults.CLIFF_AMOUNT() : 0;

        // Assert that the stream has been created successfully.
        assertEq(lockup.getCliffTime(expectedStreamId), cliffTime, "cliff time");
        assertEq(lockup.getDepositedAmount(expectedStreamId), defaults.CLAIM_AMOUNT(), "depositedAmount");
        assertEq(lockup.getEndTime(expectedStreamId), startTime + defaults.TOTAL_DURATION(), "end time");
        assertEq(lockup.getRecipient(expectedStreamId), users.recipient1, "recipient");
        assertEq(lockup.getSender(expectedStreamId), users.campaignOwner, "sender");
        assertEq(lockup.getStartTime(expectedStreamId), startTime, "start time");
        assertEq(lockup.getUnderlyingToken(expectedStreamId), dai, "token");
        assertEq(lockup.getUnlockAmounts(expectedStreamId).cliff, expectedCliffAmount, "unlock amount cliff");
        assertEq(lockup.getUnlockAmounts(expectedStreamId).start, defaults.START_AMOUNT(), "unlock amount start");
        assertEq(lockup.isCancelable(expectedStreamId), defaults.CANCELABLE(), "is cancelable");
        assertEq(lockup.isDepleted(expectedStreamId), false, "is depleted");
        assertEq(lockup.isStream(expectedStreamId), true, "is stream");
        assertEq(lockup.isTransferable(expectedStreamId), defaults.TRANSFERABLE(), "is transferable");
        assertEq(lockup.wasCanceled(expectedStreamId), false, "was canceled");

        assertTrue(merkleLL.hasClaimed(defaults.INDEX1()), "not claimed");

        assertEq(address(merkleLL).balance, previousFeeAccrued + defaults.MINIMUM_FEE(), "fee collected");
    }
}
