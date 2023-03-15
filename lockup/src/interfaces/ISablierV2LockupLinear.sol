// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.13;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";

import { Lockup, LockupLinear } from "../types/DataTypes.sol";
import { ISablierV2Lockup } from "./ISablierV2Lockup.sol";

/// @title ISablierV2LockupLinear
/// @notice Creates and manages lockup streams whose streaming function is strictly linear.
interface ISablierV2LockupLinear is ISablierV2Lockup {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a lockup linear stream is created.
    /// @param streamId The id of the newly created lockup linear stream.
    /// @param funder The address which has funded the stream.
    /// @param sender The address from which to stream the assets, who will have the ability to cancel the stream.
    /// @param recipient The address toward which to stream the assets.
    /// @param amounts Struct that encapsulates (i) the deposit amount, (ii) the protocol fee amount, and (iii) the
    /// broker fee amount, each in units of the asset's decimals.
    /// @param asset The contract address of the ERC-20 asset used for streaming.
    /// @param cancelable Boolean that indicates whether the stream will be cancelable or not.
    /// @param range Struct that encapsulates (i) the start time of the stream, (ii) the cliff time of the stream,
    /// and (iii) the end time of the stream, all as Unix timestamps.
    /// @param broker The address of the broker who has helped create the stream, e.g. a front-end website.
    event CreateLockupLinearStream(
        uint256 streamId,
        address indexed funder,
        address indexed sender,
        address indexed recipient,
        Lockup.CreateAmounts amounts,
        IERC20 asset,
        bool cancelable,
        LockupLinear.Range range,
        address broker
    );

    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Queries the cliff time of the lockup linear stream.
    /// @param streamId The id of the lockup linear stream to make the query for.
    function getCliffTime(uint256 streamId) external view returns (uint40 cliffTime);

    /// @notice Queries the range of the lockup linear stream, a struct that encapsulates (i) the start time of the
    /// stream, (ii) the cliff time of the stream, and (iii) the end time of the stream, all as Unix timestamps.
    /// @param streamId The id of the lockup linear stream to make the query for.
    function getRange(uint256 streamId) external view returns (LockupLinear.Range memory range);

    /// @notice Queries the lockup linear stream struct entity.
    /// @param streamId The id of the lockup linear stream to make the query for.
    function getStream(uint256 streamId) external view returns (LockupLinear.Stream memory stream);

    /// @notice Calculates the amount that has been streamed to the recipient, in units of the asset's decimals.
    /// @dev The streaming function is:
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
    ///
    /// @param streamId The id of the lockup linear stream to make the query for.
    function streamedAmountOf(uint256 streamId) external view returns (uint128 streamedAmount);

    /*//////////////////////////////////////////////////////////////////////////
                               NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Creates a lockup linear stream with the start time set to `block.timestamp`, and the end time set
    /// to `block.timestamp + params.durations.total`. The stream is funded by `msg.sender` and is wrapped in an
    /// ERC-721 NFT.
    ///
    /// @dev Emits a {CreateLockupLinearStream} and a {Transfer} event.
    ///
    /// Requirements:
    /// - All from {createWithRange}.
    ///
    /// @param params Struct that encapsulates the function parameters.
    /// @return streamId The id of the newly created lockup linear stream.
    function createWithDurations(LockupLinear.CreateWithDurations calldata params) external returns (uint256 streamId);

    /// @notice Creates a lockup linear stream with the provided start time and end time as the range. The stream is
    /// funded by `msg.sender` and is wrapped in an ERC-721 NFT.
    ///
    /// @dev Emits a {CreateLockupLinearStream} and a {Transfer} event.
    ///
    /// Notes:
    /// - As long as the times are ordered, it is not an error to set a range that is in the past.
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
    /// @return streamId The id of the newly created lockup linear stream.
    function createWithRange(LockupLinear.CreateWithRange calldata params) external returns (uint256 streamId);
}
