// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { Lockup } from "../types/Lockup.sol";
import { LockupLinear } from "../types/LockupLinear.sol";
import { ISablierLockupState } from "./ISablierLockupState.sol";

/// @title ISablierLockupLinear
/// @notice Creates Lockup streams with linear distribution model.
interface ISablierLockupLinear is ISablierLockupState {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when an LL stream is created.
    /// @param streamId The ID of the newly created stream.
    /// @param commonParams Common parameters emitted in Create events across all Lockup models.
    /// @param cliffTime The Unix timestamp for the cliff period's end. A value of zero means there is no cliff.
    /// @param unlockAmounts Struct encapsulating (i) the amount to unlock at the start time and (ii) the amount to
    /// unlock at the cliff time.
    event CreateLockupLinearStream(
        uint256 indexed streamId,
        Lockup.CreateEventCommon commonParams,
        uint40 cliffTime,
        LockupLinear.UnlockAmounts unlockAmounts
    );

    /*//////////////////////////////////////////////////////////////////////////
                        USER-FACING STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Creates a stream by setting the start time to `block.timestamp`, and the end time to
    /// the sum of `block.timestamp` and `durations.total`. The stream is funded by `msg.sender` and is wrapped in an
    /// ERC-721 NFT.
    ///
    /// @dev Emits a {Transfer}, {CreateLockupLinearStream} and {MetadataUpdate} event.
    ///
    /// Requirements:
    /// - All requirements in {createWithTimestampsLL} must be met for the calculated parameters.
    ///
    /// @param params Struct encapsulating the function parameters, which are documented in {Lockup} type.
    /// @param durations Struct encapsulating (i) cliff period duration and (ii) total stream duration, both in seconds.
    /// @param unlockAmounts Struct encapsulating (i) the amount to unlock at the start time and (ii) the amount to
    /// unlock at the cliff time.
    /// @return streamId The ID of the newly created stream.
    function createWithDurationsLL(
        Lockup.CreateWithDurations calldata params,
        LockupLinear.UnlockAmounts calldata unlockAmounts,
        LockupLinear.Durations calldata durations
    )
        external
        payable
        returns (uint256 streamId);

    /// @notice Creates a stream with the provided start time and end time. The stream is funded by `msg.sender` and is
    /// wrapped in an ERC-721 NFT.
    ///
    /// @dev Emits a {Transfer}, {CreateLockupLinearStream} and {MetadataUpdate} event.
    ///
    /// Notes:
    /// - A cliff time of zero means there is no cliff.
    /// - As long as the times are ordered, it is not an error for the start or the cliff time to be in the past.
    ///
    /// Requirements:
    /// - Must not be delegate called.
    /// - `params.depositAmount` must be greater than zero.
    /// - `params.timestamps.start` must be greater than zero and less than `params.timestamps.end`.
    /// - If set, `cliffTime` must be greater than `params.timestamps.start` and less than
    /// `params.timestamps.end`.
    /// - `params.recipient` must not be the zero address.
    /// - `params.sender` must not be the zero address.
    /// - The sum of `params.unlockAmounts.start` and `params.unlockAmounts.cliff` must be less than or equal to
    /// deposit amount.
    /// - If `params.timestamps.cliff` not set, the `params.unlockAmounts.cliff` must be zero.
    /// - `msg.sender` must have allowed this contract to spend at least `params.depositAmount` tokens.
    /// - `params.token` must not be the native token.
    /// - `params.shape.length` must not be greater than 32 characters.
    ///
    /// @param params Struct encapsulating the function parameters, which are documented in {Lockup} type.
    /// @param cliffTime The Unix timestamp for the cliff period's end. A value of zero means there is no cliff.
    /// @param unlockAmounts Struct encapsulating (i) the amount to unlock at the start time and (ii) the amount to
    /// unlock at the cliff time.
    /// @return streamId The ID of the newly created stream.
    function createWithTimestampsLL(
        Lockup.CreateWithTimestamps calldata params,
        LockupLinear.UnlockAmounts calldata unlockAmounts,
        uint40 cliffTime
    )
        external
        payable
        returns (uint256 streamId);
}
