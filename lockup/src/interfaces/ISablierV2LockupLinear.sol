// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.13;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

import { Lockup, LockupLinear } from "../types/DataTypes.sol";
import { ISablierV2Lockup } from "./ISablierV2Lockup.sol";

/// @title ISablierV2LockupLinear
/// @notice Creates and manages lockup streams with a linear streaming function.
interface ISablierV2LockupLinear is ISablierV2Lockup {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a linear stream is created.
    /// @param streamId The id of the newly created linear stream.
    /// @param funder The address which funded the stream.
    /// @param sender The address streaming the assets, with the ability to cancel the stream.
    /// @param recipient The address receiving the assets.
    /// @param amounts Struct that encapsulates (i) the deposit amount, (ii) the protocol fee amount, and (iii) the
    /// broker fee amount, all denoted in units of the asset's decimals.
    /// @param asset The contract address of the ERC-20 asset used for streaming.
    /// @param cancelable Boolean that indicates whether the stream will be cancelable or not.
    /// @param range Struct that encapsulates (i) the stream's start time, (ii) the stream's cliff time, and (iii)
    /// the stream's end time, all as Unix timestamps.
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

    /// @notice Retrieves the linear stream's cliff time, which is a Unix timestamp.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The linear stream id for the query.
    function getCliffTime(uint256 streamId) external view returns (uint40 cliffTime);

    /// @notice Retrieves the range of the linear stream, a struct that encapsulates (i) the start time of the
    /// stream, (ii) the stream's cliff time, and (iii) the stream's end time, all as Unix timestamps.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The linear stream id for the query.
    function getRange(uint256 streamId) external view returns (LockupLinear.Range memory range);

    /// @notice Retrieves the linear stream entity.
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The linear stream id for the query.
    function getStream(uint256 streamId) external view returns (LockupLinear.Stream memory stream);

    /// @notice Calculates the amount streamed to the recipient, denoted in units of the asset's decimals.
    ///
    /// When the stream is active, the streaming function is:
    ///
    /// $$
    /// f(x) = x * d + c
    /// $$
    ///
    /// Where:
    ///
    /// - $x$ is the elapsed time divided by the stream's total duration.
    /// - $d$ is the deposited amount.
    /// - $c$ is the cliff amount.
    ///
    /// When the stream is canceled, the streamed amount is frozen:
    ///
    /// $$
    /// s = d - r - w
    /// $$
    ///
    /// Where:
    ///
    /// - $d$ is the deposited amount.
    /// - $r$ is the returned amount.
    /// - $w$ is the withdrawn amount.
    ///
    /// @dev Reverts if `streamId` references a null stream.
    /// @param streamId The linear stream id for the query.
    function streamedAmountOf(uint256 streamId) external view returns (uint128 streamedAmount);

    /*//////////////////////////////////////////////////////////////////////////
                               NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Creates a linear stream by setting the start time to `block.timestamp`, and the end time to
    /// the sum of `block.timestamp` and `params.durations.total. The stream is funded by `msg.sender` and is wrapped
    /// in an ERC-721 NFT.
    ///
    /// @dev Emits a {CreateLockupLinearStream} and a {Transfer} event.
    ///
    /// Requirements:
    /// - All from {createWithRange}.
    ///
    /// @param params Struct that encapsulates the function parameters.
    /// @return streamId The id of the newly created linear stream.
    function createWithDurations(LockupLinear.CreateWithDurations calldata params)
        external
        returns (uint256 streamId);

    /// @notice Creates a linear stream with the provided start time and end time as the range. The stream is
    /// funded by `msg.sender` and is wrapped in an ERC-721 NFT.
    ///
    /// @dev Emits a {CreateLockupLinearStream} and a {Transfer} event.
    ///
    /// Notes:
    /// - As long as the times are ordered, it is not an error to set a range that is in the past.
    ///
    /// Requirements:
    /// - The call must not be a delegate call.
    /// - `params.totalAmount` must be greater than zero.
    /// - If set, `params.broker.fee` must not be greater than `MAX_FEE`.
    /// - `params.range.start` must be less than or equal to `params.range.cliff`.
    /// - `params.range.cliff` must be less than `params.range.end`.
    /// - `params.range.end` must not be in the past.
    /// - `params.recipient` must not be the zero address.
    /// - `msg.sender` must have allowed this contract to spend at least `params.totalAmount` assets.
    ///
    /// @param params Struct that encapsulates the function parameters.
    /// @return streamId The id of the newly created linear stream.
    function createWithRange(LockupLinear.CreateWithRange calldata params) external returns (uint256 streamId);
}
