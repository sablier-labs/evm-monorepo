// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

import { ISablierLockupPriceGated } from "src/interfaces/ISablierLockupPriceGated.sol";
import { Lockup } from "src/types/Lockup.sol";
import { LockupPriceGated } from "src/types/LockupPriceGated.sol";

import { Lockup_PriceGated_Integration_Fuzz_Test } from "./LockupPriceGated.t.sol";

contract CreateWithTimestampsLPG_Integration_Fuzz_Test is Lockup_PriceGated_Integration_Fuzz_Test {
    function testFuzz_CreateWithTimestampsLPG(uint128 targetPrice, uint40 duration) external whenNoDelegateCall {
        // Bound duration to be at least 1 second.
        duration = boundUint40(duration, 1 seconds, MAX_UNIX_TIMESTAMP);

        // Bound target price to be greater than latest oracle price.
        uint128 latestPrice = uint128(uint256(oracle.price()));
        targetPrice = uint128(bound(targetPrice, latestPrice + 1, type(uint128).max));

        uint256 expectedStreamId = lockup.nextStreamId();

        // Expect the tokens to be transferred from the sender to {SablierLockup}.
        expectCallToTransferFrom({ from: users.sender, to: address(lockup), value: defaults.DEPOSIT_AMOUNT() });

        // Create the timestamps struct.
        Lockup.Timestamps memory timestamps =
            Lockup.Timestamps({ start: getBlockTimestamp(), end: getBlockTimestamp() + duration });

        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(lockup) });
        emit ISablierLockupPriceGated.CreateLockupPriceGatedStream({
            streamId: expectedStreamId,
            oracle: AggregatorV3Interface(address(oracle)),
            targetPrice: targetPrice
        });

        // Build the create params.
        Lockup.CreateWithTimestamps memory createParams = Lockup.CreateWithTimestamps({
            sender: _defaultParams.createWithTimestamps.sender,
            recipient: _defaultParams.createWithTimestamps.recipient,
            depositAmount: _defaultParams.createWithTimestamps.depositAmount,
            token: _defaultParams.createWithTimestamps.token,
            cancelable: _defaultParams.createWithTimestamps.cancelable,
            transferable: _defaultParams.createWithTimestamps.transferable,
            timestamps: timestamps,
            shape: _defaultParams.createWithTimestamps.shape
        });

        // Create the stream.
        uint256 streamId = lockup.createWithTimestampsLPG(createParams, defaults.unlockParams(targetPrice));

        // It should create the stream.
        assertEq(lockup.getDepositedAmount(streamId), defaults.DEPOSIT_AMOUNT(), "depositedAmount");
        assertEq(lockup.getEndTime(streamId), timestamps.end, "endTime");
        assertEq(lockup.isCancelable(streamId), true, "isCancelable");
        assertFalse(lockup.isDepleted(streamId), "isDepleted");
        assertTrue(lockup.isStream(streamId), "isStream");
        assertTrue(lockup.isTransferable(streamId), "isTransferable");
        assertEq(lockup.getLockupModel(streamId), Lockup.Model.LOCKUP_PRICE_GATED);
        assertEq(lockup.getRecipient(streamId), users.recipient, "recipient");
        assertEq(lockup.getSender(streamId), users.sender, "sender");
        assertEq(lockup.getStartTime(streamId), timestamps.start, "startTime");
        assertFalse(lockup.wasCanceled(streamId), "wasCanceled");
        assertEq(lockup.getUnderlyingToken(streamId), dai, "underlyingToken");

        // It should store the unlock params.
        LockupPriceGated.UnlockParams memory unlockParams = lockup.getPriceGatedUnlockParams(streamId);
        assertEq(address(unlockParams.oracle), address(oracle), "oracle");
        assertEq(unlockParams.targetPrice, targetPrice, "targetPrice");

        // Assert that the next stream ID has been bumped.
        uint256 actualNextStreamId = lockup.nextStreamId();
        uint256 expectedNextStreamId = streamId + 1;
        assertEq(actualNextStreamId, expectedNextStreamId, "nextStreamId");
    }
}
