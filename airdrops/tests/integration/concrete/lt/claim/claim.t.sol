// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ud2x18 } from "@prb/math/src/UD2x18.sol";

import { ISablierMerkleLT } from "src/interfaces/ISablierMerkleLT.sol";
import { Errors } from "src/libraries/Errors.sol";
import { MerkleLT } from "src/types/DataTypes.sol";

import { Claim_Integration_Test } from "../../shared/claim/claim.t.sol";
import { MerkleLT_Integration_Shared_Test, Integration_Test } from "../MerkleLT.t.sol";

contract Claim_MerkleLT_Integration_Test is Claim_Integration_Test, MerkleLT_Integration_Shared_Test {
    function setUp() public virtual override(MerkleLT_Integration_Shared_Test, Integration_Test) {
        MerkleLT_Integration_Shared_Test.setUp();
    }

    function test_RevertWhen_TotalPercentageLessThan100() external whenMerkleProofValid whenTotalPercentageNot100 {
        uint256 fee = defaults.FEE();

        // Create a MerkleLT campaign with a total percentage less than 100.
        MerkleLT.TrancheWithPercentage[] memory tranchesWithPercentages = defaults.tranchesWithPercentages();
        tranchesWithPercentages[0].unlockPercentage = ud2x18(0.05e18);
        tranchesWithPercentages[1].unlockPercentage = ud2x18(0.2e18);

        merkleLT = merkleFactory.createMerkleLT(
            defaults.baseParams(),
            lockup,
            defaults.CANCELABLE(),
            defaults.TRANSFERABLE(),
            defaults.STREAM_START_TIME_ZERO(),
            tranchesWithPercentages,
            defaults.AGGREGATE_AMOUNT(),
            defaults.RECIPIENT_COUNT()
        );

        uint64 totalPercentage =
            tranchesWithPercentages[0].unlockPercentage.unwrap() + tranchesWithPercentages[1].unlockPercentage.unwrap();

        // Claim an airstream.
        bytes32[] memory merkleProof = defaults.index1Proof();

        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierMerkleLT_TotalPercentageNotOneHundred.selector, totalPercentage)
        );

        merkleLT.claim{ value: fee }({
            index: 1,
            recipient: users.recipient1,
            amount: 10_000e18,
            merkleProof: merkleProof
        });
    }

    function test_RevertWhen_TotalPercentageGreaterThan100() external whenMerkleProofValid whenTotalPercentageNot100 {
        uint256 fee = defaults.FEE();
        // Create a MerkleLT campaign with a total percentage less than 100.
        MerkleLT.TrancheWithPercentage[] memory tranchesWithPercentages = defaults.tranchesWithPercentages();
        tranchesWithPercentages[0].unlockPercentage = ud2x18(0.75e18);
        tranchesWithPercentages[1].unlockPercentage = ud2x18(0.8e18);

        merkleLT = merkleFactory.createMerkleLT(
            defaults.baseParams(),
            lockup,
            defaults.CANCELABLE(),
            defaults.TRANSFERABLE(),
            defaults.STREAM_START_TIME_ZERO(),
            tranchesWithPercentages,
            defaults.AGGREGATE_AMOUNT(),
            defaults.RECIPIENT_COUNT()
        );

        uint64 totalPercentage =
            tranchesWithPercentages[0].unlockPercentage.unwrap() + tranchesWithPercentages[1].unlockPercentage.unwrap();

        // Claim an airstream.
        bytes32[] memory merkleProof = defaults.index1Proof();

        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierMerkleLT_TotalPercentageNotOneHundred.selector, totalPercentage)
        );

        merkleLT.claim{ value: fee }({
            index: 1,
            recipient: users.recipient1,
            amount: 10_000e18,
            merkleProof: merkleProof
        });
    }

    function test_WhenStreamStartTimeZero() external whenMerkleProofValid whenTotalPercentage100 {
        // It should create a stream with block.timestamp as start time.
        _test_Claim({ streamStartTime: 0, startTime: getBlockTimestamp() });
    }

    function test_WhenStreamStartTimeNotZero() external whenMerkleProofValid whenTotalPercentage100 {
        merkleLT = merkleFactory.createMerkleLT({
            baseParams: defaults.baseParams(),
            lockup: lockup,
            cancelable: defaults.CANCELABLE(),
            transferable: defaults.TRANSFERABLE(),
            streamStartTime: defaults.STREAM_START_TIME_NON_ZERO(),
            tranchesWithPercentages: defaults.tranchesWithPercentages(),
            aggregateAmount: defaults.AGGREGATE_AMOUNT(),
            recipientCount: defaults.RECIPIENT_COUNT()
        });

        // It should create a stream with `STREAM_START_TIME` as start time.
        _test_Claim({
            streamStartTime: defaults.STREAM_START_TIME_NON_ZERO(),
            startTime: defaults.STREAM_START_TIME_NON_ZERO()
        });
    }

    /// @dev Helper function to test claim.
    function _test_Claim(uint40 streamStartTime, uint40 startTime) private {
        uint256 fee = defaults.FEE();

        deal({ token: address(dai), to: address(merkleLT), give: defaults.AGGREGATE_AMOUNT() });

        uint256 expectedStreamId = lockup.nextStreamId();
        uint256 previousFeeAccrued = address(merkleLL).balance;

        // It should emit a {Claim} event.
        vm.expectEmit({ emitter: address(merkleLT) });
        emit ISablierMerkleLT.Claim(defaults.INDEX1(), users.recipient1, defaults.CLAIM_AMOUNT(), expectedStreamId);

        expectCallToTransferFrom({ from: address(merkleLT), to: address(lockup), value: defaults.CLAIM_AMOUNT() });
        expectCallToClaimWithMsgValue(address(merkleLT), fee);

        // Claim the airstream.
        merkleLT.claim{ value: fee }(
            defaults.INDEX1(), users.recipient1, defaults.CLAIM_AMOUNT(), defaults.index1Proof()
        );

        // Assert that the stream has been created successfully.
        assertEq(lockup.getDepositedAmount(expectedStreamId), defaults.CLAIM_AMOUNT(), "depositedAmount");
        assertEq(lockup.getEndTime(expectedStreamId), startTime + defaults.TOTAL_DURATION(), "end time");
        assertEq(lockup.getRecipient(expectedStreamId), users.recipient1, "recipient");
        assertEq(lockup.getSender(expectedStreamId), users.campaignOwner, "sender");
        assertEq(lockup.getStartTime(expectedStreamId), startTime, "start time");
        // It should create a stream with `STREAM_START_TIME` as start time.
        assertEq(
            lockup.getTranches(expectedStreamId),
            defaults.tranchesMerkleLT({ streamStartTime: streamStartTime, totalAmount: defaults.CLAIM_AMOUNT() }),
            "tranches"
        );
        assertEq(lockup.getUnderlyingToken(expectedStreamId), dai, "token");
        assertEq(lockup.isCancelable(expectedStreamId), defaults.CANCELABLE(), "is cancelable");
        assertEq(lockup.isDepleted(expectedStreamId), false, "is depleted");
        assertEq(lockup.isStream(expectedStreamId), true, "is stream");
        assertEq(lockup.isTransferable(expectedStreamId), defaults.TRANSFERABLE(), "is transferable");
        assertEq(lockup.wasCanceled(expectedStreamId), false, "was canceled");

        assertTrue(merkleLT.hasClaimed(defaults.INDEX1()), "not claimed");

        assertEq(address(merkleLT).balance, previousFeeAccrued + defaults.FEE(), "fee collected");
    }
}
