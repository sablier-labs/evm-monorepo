// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { Lockup } from "../types/Lockup.sol";
import { LockupDynamic } from "../types/LockupDynamic.sol";
import { ISablierLockupState } from "./ISablierLockupState.sol";

/// @title ISablierLockupDynamic
/// @notice Creates Lockup streams with dynamic distribution model.
interface ISablierLockupDynamic is ISablierLockupState {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when an LD stream is created.
    /// @param streamId The ID of the newly created stream.
    /// @param commonParams Common parameters emitted in Create events across all Lockup models.
    /// @param segments The segments the protocol uses to compose the dynamic distribution function.
    event CreateLockupDynamicStream(
        uint256 indexed streamId, Lockup.CreateEventCommon commonParams, LockupDynamic.Segment[] segments
    );

    /*//////////////////////////////////////////////////////////////////////////
                        USER-FACING STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Creates a stream by setting the start time to `block.timestamp`, and the end time to the sum of
    /// `block.timestamp` and all specified time durations. The segment timestamps are derived from these
    /// durations. The stream is funded by `msg.sender` and is wrapped in an ERC-721 NFT.
    ///
    /// @dev Emits a {Transfer}, {CreateLockupDynamicStream} and {MetadataUpdate} event.
    ///
    /// Requirements:
    /// - All requirements in {createWithTimestampsLD} must be met for the calculated parameters.
    ///
    /// @param params Struct encapsulating the function parameters, which are documented in {Lockup} type.
    /// @param segmentsWithDuration Segments with durations used to compose the dynamic distribution function. Timestamps
    /// are calculated by starting from `block.timestamp` and adding each duration to the previous timestamp.
    /// @return streamId The ID of the newly created stream.
    function createWithDurationsLD(
        Lockup.CreateWithDurations calldata params,
        LockupDynamic.SegmentWithDuration[] calldata segmentsWithDuration
    )
        external
        payable
        returns (uint256 streamId);

    /// @notice Creates a stream with the provided segment timestamps, implying the end time from the last timestamp.
    /// The stream is funded by `msg.sender` and is wrapped in an ERC-721 NFT.
    ///
    /// @dev Emits a {Transfer}, {CreateLockupDynamicStream} and {MetadataUpdate} event.
    ///
    /// Notes:
    /// - As long as the segment timestamps are arranged in ascending order, it is not an error for some
    /// of them to be in the past.
    ///
    /// Requirements:
    /// - Must not be delegate called.
    /// - `params.depositAmount` must be greater than zero.
    /// - `params.timestamps.start` must be greater than zero and less than the first segment's timestamp.
    /// - `segments` must have at least one segment.
    /// - The segment timestamps must be arranged in ascending order.
    /// - `params.timestamps.end` must be equal to the last segment's timestamp.
    /// - The sum of the segment amounts must equal the deposit amount.
    /// - `params.recipient` must not be the zero address.
    /// - `params.sender` must not be the zero address.
    /// - `msg.sender` must have allowed this contract to spend at least `params.depositAmount` tokens.
    /// - `params.token` must not be the native token.
    /// - `params.shape.length` must not be greater than 32 characters.
    ///
    /// @param params Struct encapsulating the function parameters, which are documented in {Lockup} type.
    /// @param segments Segments used to compose the dynamic distribution function.
    /// @return streamId The ID of the newly created stream.
    function createWithTimestampsLD(
        Lockup.CreateWithTimestamps calldata params,
        LockupDynamic.Segment[] calldata segments
    )
        external
        payable
        returns (uint256 streamId);
}
