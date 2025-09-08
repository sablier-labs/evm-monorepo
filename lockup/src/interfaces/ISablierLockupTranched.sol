// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { Lockup } from "../types/Lockup.sol";
import { LockupTranched } from "../types/LockupTranched.sol";
import { ISablierLockupState } from "./ISablierLockupState.sol";

/// @title ISablierLockupTranched
/// @notice Creates Lockup streams with tranched distribution model.
interface ISablierLockupTranched is ISablierLockupState {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when an LT stream is created.
    /// @param streamId The ID of the newly created stream.
    /// @param commonParams Common parameters emitted in Create events across all Lockup models.
    /// @param tranches The tranches the protocol uses to compose the tranched distribution function.
    event CreateLockupTranchedStream(
        uint256 indexed streamId, Lockup.CreateEventCommon commonParams, LockupTranched.Tranche[] tranches
    );

    /*//////////////////////////////////////////////////////////////////////////
                        USER-FACING STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Creates a stream by setting the start time to `block.timestamp`, and the end time to the sum of
    /// `block.timestamp` and all specified time durations. The tranche timestamps are derived from these
    /// durations. The stream is funded by `msg.sender` and is wrapped in an ERC-721 NFT.
    ///
    /// @dev Emits a {Transfer}, {CreateLockupTrancheStream} and {MetadataUpdate} event.
    ///
    /// Requirements:
    /// - All requirements in {createWithTimestampsLT} must be met for the calculated parameters.
    ///
    /// @param params Struct encapsulating the function parameters, which are documented in {Lockup} type.
    /// @param tranchesWithDuration Tranches with durations used to compose the tranched distribution function.
    /// Timestamps are calculated by starting from `block.timestamp` and adding each duration to the previous timestamp.
    /// @return streamId The ID of the newly created stream.
    function createWithDurationsLT(
        Lockup.CreateWithDurations calldata params,
        LockupTranched.TrancheWithDuration[] calldata tranchesWithDuration
    )
        external
        payable
        returns (uint256 streamId);

    /// @notice Creates a stream with the provided tranche timestamps, implying the end time from the last timestamp.
    /// The stream is funded by `msg.sender` and is wrapped in an ERC-721 NFT.
    ///
    /// @dev Emits a {Transfer}, {CreateLockupTrancheStream} and {MetadataUpdate} event.
    ///
    /// Notes:
    /// - As long as the tranche timestamps are arranged in ascending order, it is not an error for some
    /// of them to be in the past.
    ///
    /// Requirements:
    /// - Must not be delegate called.
    /// - `params.depositAmount` must be greater than zero.
    /// - `params.timestamps.start` must be greater than zero and less than the first tranche's timestamp.
    /// - `tranches` must have at least one tranche.
    /// - The tranche timestamps must be arranged in ascending order.
    /// - `params.timestamps.end` must be equal to the last tranche's timestamp.
    /// - The sum of the tranche amounts must equal the deposit amount.
    /// - `params.recipient` must not be the zero address.
    /// - `params.sender` must not be the zero address.
    /// - `msg.sender` must have allowed this contract to spend at least `params.depositAmount` tokens.
    /// - `params.token` must not be the native token.
    /// - `params.shape.length` must not be greater than 32 characters.
    ///
    /// @param params Struct encapsulating the function parameters, which are documented in {Lockup} type.
    /// @param tranches Tranches used to compose the tranched distribution function.
    /// @return streamId The ID of the newly created stream.
    function createWithTimestampsLT(
        Lockup.CreateWithTimestamps calldata params,
        LockupTranched.Tranche[] calldata tranches
    )
        external
        payable
        returns (uint256 streamId);
}
