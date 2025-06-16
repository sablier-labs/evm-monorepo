// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { BatchLockup } from "../../src/types/BatchLockup.sol";
import { Lockup } from "../../src/types/Lockup.sol";
import { LockupDynamic } from "../../src/types/LockupDynamic.sol";
import { LockupLinear } from "../../src/types/LockupLinear.sol";
import { LockupTranched } from "../../src/types/LockupTranched.sol";

library BatchLockupBuilder {
    /// @notice Generates an array containing `batchSize` copies of `batchSingle`.
    function fillBatch(
        BatchLockup.CreateWithDurationsLD memory batchSingle,
        uint256 batchSize
    )
        internal
        pure
        returns (BatchLockup.CreateWithDurationsLD[] memory batch)
    {
        batch = new BatchLockup.CreateWithDurationsLD[](batchSize);
        for (uint256 i = 0; i < batchSize; ++i) {
            batch[i] = batchSingle;
        }
    }

    /// @notice Turns the inputs into an array of {BatchLockup.CreateWithDurationsLD} structs.
    function fillBatch(
        Lockup.CreateWithDurations memory params,
        LockupDynamic.SegmentWithDuration[] memory segmentsWithDurations,
        uint256 batchSize
    )
        internal
        pure
        returns (BatchLockup.CreateWithDurationsLD[] memory batch)
    {
        batch = new BatchLockup.CreateWithDurationsLD[](batchSize);
        BatchLockup.CreateWithDurationsLD memory batchSingle = BatchLockup.CreateWithDurationsLD({
            sender: params.sender,
            recipient: params.recipient,
            depositAmount: params.depositAmount,
            cancelable: params.cancelable,
            transferable: params.transferable,
            segmentsWithDuration: segmentsWithDurations,
            shape: params.shape
        });
        batch = fillBatch(batchSingle, batchSize);
    }

    /// @notice Generates an array containing `batchSize` copies of `batchSingle`.
    function fillBatch(
        BatchLockup.CreateWithDurationsLL memory batchSingle,
        uint256 batchSize
    )
        internal
        pure
        returns (BatchLockup.CreateWithDurationsLL[] memory batch)
    {
        batch = new BatchLockup.CreateWithDurationsLL[](batchSize);
        for (uint256 i = 0; i < batchSize; ++i) {
            batch[i] = batchSingle;
        }
    }

    /// @notice Turns the inputs into an array of {BatchLockup.CreateWithDurationsLL} structs.
    function fillBatch(
        Lockup.CreateWithDurations memory params,
        LockupLinear.UnlockAmounts memory unlockAmounts,
        LockupLinear.Durations memory durations,
        uint256 batchSize
    )
        internal
        pure
        returns (BatchLockup.CreateWithDurationsLL[] memory batch)
    {
        batch = new BatchLockup.CreateWithDurationsLL[](batchSize);
        BatchLockup.CreateWithDurationsLL memory batchSingle = BatchLockup.CreateWithDurationsLL({
            sender: params.sender,
            recipient: params.recipient,
            depositAmount: params.depositAmount,
            cancelable: params.cancelable,
            transferable: params.transferable,
            durations: durations,
            unlockAmounts: unlockAmounts,
            shape: params.shape
        });
        batch = fillBatch(batchSingle, batchSize);
    }

    /// @notice Generates an array containing `batchSize` copies of `batchSingle`.
    function fillBatch(
        BatchLockup.CreateWithDurationsLT memory batchSingle,
        uint256 batchSize
    )
        internal
        pure
        returns (BatchLockup.CreateWithDurationsLT[] memory batch)
    {
        batch = new BatchLockup.CreateWithDurationsLT[](batchSize);
        for (uint256 i = 0; i < batchSize; ++i) {
            batch[i] = batchSingle;
        }
    }

    /// @notice Turns the inputs into an array of {BatchLockup.CreateWithDurationsLT} structs.
    function fillBatch(
        Lockup.CreateWithDurations memory params,
        LockupTranched.TrancheWithDuration[] memory tranchesWithDuration,
        uint256 batchSize
    )
        internal
        pure
        returns (BatchLockup.CreateWithDurationsLT[] memory batch)
    {
        batch = new BatchLockup.CreateWithDurationsLT[](batchSize);
        BatchLockup.CreateWithDurationsLT memory batchSingle = BatchLockup.CreateWithDurationsLT({
            sender: params.sender,
            recipient: params.recipient,
            depositAmount: params.depositAmount,
            cancelable: params.cancelable,
            transferable: params.transferable,
            tranchesWithDuration: tranchesWithDuration,
            shape: params.shape
        });
        batch = fillBatch(batchSingle, batchSize);
    }

    /// @notice Generates an array containing `batchSize` copies of `batchSingle`.
    function fillBatch(
        BatchLockup.CreateWithTimestampsLD memory batchSingle,
        uint256 batchSize
    )
        internal
        pure
        returns (BatchLockup.CreateWithTimestampsLD[] memory batch)
    {
        batch = new BatchLockup.CreateWithTimestampsLD[](batchSize);
        for (uint256 i = 0; i < batchSize; ++i) {
            batch[i] = batchSingle;
        }
    }

    /// @notice Turns the inputs into an array of {BatchLockup.CreateWithTimestampsLDs} structs.
    function fillBatch(
        Lockup.CreateWithTimestamps memory params,
        LockupDynamic.Segment[] memory segments,
        uint256 batchSize
    )
        internal
        pure
        returns (BatchLockup.CreateWithTimestampsLD[] memory batch)
    {
        batch = new BatchLockup.CreateWithTimestampsLD[](batchSize);
        BatchLockup.CreateWithTimestampsLD memory batchSingle = BatchLockup.CreateWithTimestampsLD({
            sender: params.sender,
            recipient: params.recipient,
            depositAmount: params.depositAmount,
            cancelable: params.cancelable,
            transferable: params.transferable,
            startTime: params.timestamps.start,
            segments: segments,
            shape: params.shape
        });
        batch = fillBatch(batchSingle, batchSize);
    }

    /// @notice Generates an array containing `batchSize` copies of `batchSingle`.
    function fillBatch(
        BatchLockup.CreateWithTimestampsLL memory batchSingle,
        uint256 batchSize
    )
        internal
        pure
        returns (BatchLockup.CreateWithTimestampsLL[] memory batch)
    {
        batch = new BatchLockup.CreateWithTimestampsLL[](batchSize);
        for (uint256 i = 0; i < batchSize; ++i) {
            batch[i] = batchSingle;
        }
    }

    /// @notice Turns the inputs into an array of {BatchLockup.CreateWithTimestampsLL} structs.
    function fillBatch(
        Lockup.CreateWithTimestamps memory params,
        LockupLinear.UnlockAmounts memory unlockAmounts,
        uint40 cliffTime,
        uint256 batchSize
    )
        internal
        pure
        returns (BatchLockup.CreateWithTimestampsLL[] memory batch)
    {
        batch = new BatchLockup.CreateWithTimestampsLL[](batchSize);
        BatchLockup.CreateWithTimestampsLL memory batchSingle = BatchLockup.CreateWithTimestampsLL({
            sender: params.sender,
            recipient: params.recipient,
            depositAmount: params.depositAmount,
            cancelable: params.cancelable,
            transferable: params.transferable,
            timestamps: params.timestamps,
            cliffTime: cliffTime,
            unlockAmounts: unlockAmounts,
            shape: params.shape
        });
        batch = fillBatch(batchSingle, batchSize);
    }

    /// @notice Generates an array containing `batchSize` copies of `batchSingle`.
    function fillBatch(
        BatchLockup.CreateWithTimestampsLT memory batchSingle,
        uint256 batchSize
    )
        internal
        pure
        returns (BatchLockup.CreateWithTimestampsLT[] memory batch)
    {
        batch = new BatchLockup.CreateWithTimestampsLT[](batchSize);
        for (uint256 i = 0; i < batchSize; ++i) {
            batch[i] = batchSingle;
        }
    }

    /// @notice Turns the inputs into an array of {BatchLockup.CreateWithTimestampsLT} structs.
    function fillBatch(
        Lockup.CreateWithTimestamps memory params,
        LockupTranched.Tranche[] memory tranches,
        uint256 batchSize
    )
        internal
        pure
        returns (BatchLockup.CreateWithTimestampsLT[] memory batch)
    {
        batch = new BatchLockup.CreateWithTimestampsLT[](batchSize);
        BatchLockup.CreateWithTimestampsLT memory batchSingle = BatchLockup.CreateWithTimestampsLT({
            sender: params.sender,
            recipient: params.recipient,
            depositAmount: params.depositAmount,
            cancelable: params.cancelable,
            transferable: params.transferable,
            startTime: params.timestamps.start,
            tranches: tranches,
            shape: params.shape
        });
        batch = fillBatch(batchSingle, batchSize);
    }
}
