// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.18;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";

import { LockupLinear } from "../types/DataTypes.sol";
import { ISablierV2Lockup } from "./ISablierV2Lockup.sol";

/// @title ISablierV2LockupLinear
/// @notice Creates streams whose streaming function is:
///
/// $$
/// f(x) = x * d + c
/// $$
///
/// Where:
///
/// - $x$ is the elapsed time divided by the total duration of the stream.
/// - $d$ is the deposit amount.
/// - $c$ is the cliff amount.
interface ISablierV2LockupLinear is ISablierV2Lockup {
    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Queries the cliff time of the stream.
    /// @param streamId The id of the stream to make the query for.
    function getCliffTime(uint256 streamId) external view returns (uint40 cliffTime);

    /// @notice Queries the range of the stream, a struct that encapsulates (i) the start time of the stream,
    //// (ii) the cliff time of the stream, and (iii) the end time of the stream, all as Unix timestamps.
    /// @param streamId The id of the stream to make the query for.
    function getRange(uint256 streamId) external view returns (LockupLinear.Range memory range);

    /// @notice Queries the stream struct entity.
    /// @param streamId The id of the stream to make the query for.
    function getStream(uint256 streamId) external view returns (LockupLinear.Stream memory stream);

    /*//////////////////////////////////////////////////////////////////////////
                               NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Creates a stream by setting the start time to `block.timestamp` and the end time to `block.timestamp +
    /// params.durations.total`. The stream is funded by `msg.sender` and is wrapped in an ERC-721 NFT.
    ///
    /// @dev Emits a {CreateLockupLinearStream} and a {Transfer} event.
    ///
    /// Requirements:
    /// - All from {createWithRange}.
    ///
    /// @param params Struct that encapsulates the function parameters.
    /// @return streamId The id of the newly created stream.
    function createWithDurations(LockupLinear.CreateWithDurations calldata params) external returns (uint256 streamId);

    /// @notice Creates a stream with the provided start time and end time as the range of the stream. The stream is
    /// funded by `msg.sender` and is wrapped in an ERC-721 NFT.
    ///
    /// @dev Emits a {CreateLockupLinearStream} and a {Transfer} event.
    ///
    /// Notes:
    /// - As long as they are ordered, it is not an error to set a range that is in the past.
    ///
    /// Requirements:
    /// - `params.recipient` must not be the zero address.
    /// - `params.totalAmount` must not be zero.
    /// - `params.range.start` must not be greater than `params.range.cliff`.
    /// - `params.range.cliff` must not be greater than `params.range.end`.
    /// - `msg.sender` must have allowed this contract to spend at least `params.totalAmount` assets.
    /// - If set, `params.broker.fee` must not be greater than `MAX_FEE`.
    ///
    /// @param params Struct that encapsulates the function parameters.
    /// @return streamId The id of the newly created stream.
    function createWithRange(LockupLinear.CreateWithRange calldata params) external returns (uint256 streamId);
}
