// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.13;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

import { Lockup, LockupDynamic } from "../types/DataTypes.sol";
import { ISablierV2Lockup } from "./ISablierV2Lockup.sol";

/// @title ISablierV2LockupDynamic
/// @notice Creates and manages lockup streams with custom streaming curves.
interface ISablierV2LockupDynamic is ISablierV2Lockup {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a lockup dynamic stream is created.
    /// @param streamId The id of the newly created lockup stream.
    /// @param funder The address which has funded the stream.
    /// @param sender The address from which to stream the assets, who will have the ability to cancel the stream.
    /// @param recipient The address toward which to stream the assets.
    /// @param amounts Struct that encapsulates (i) the deposit amount, (ii) the protocol fee amount, and (iii) the
    /// broker fee amount, each in units of the asset's decimals.
    /// @param asset The contract address of the ERC-20 asset used for streaming.
    /// @param cancelable Boolean that indicates whether the stream will be cancelable or not.
    /// @param segments The segments the protocol uses to compose the custom streaming curve.
    /// @param range Struct that encapsulates (i) the start time of the stream, and (ii) the end time of the stream,
    /// both as Unix timestamps.
    /// @param broker The address of the broker who has helped create the stream, e.g. a front-end website.
    event CreateLockupDynamicStream(
        uint256 streamId,
        address indexed funder,
        address indexed sender,
        address indexed recipient,
        Lockup.CreateAmounts amounts,
        IERC20 asset,
        bool cancelable,
        LockupDynamic.Segment[] segments,
        LockupDynamic.Range range,
        address broker
    );

    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice The maximum number of segments permitted in a lockup dynamic stream.
    /// @dev This is initialized at construction time and cannot be changed later.
    function MAX_SEGMENT_COUNT() external view returns (uint256);

    /// @notice Queries the range of the lockup dynamic stream, a struct that encapsulates (i) the start time of the
    /// stream, and (ii) the end time of of the stream, both as Unix timestamps.
    /// @param streamId The id of the lockup dynamic stream to make the query for.
    function getRange(uint256 streamId) external view returns (LockupDynamic.Range memory range);

    /// @notice Queries the segments the protocol uses to compose the custom streaming curve.
    /// @param streamId The id of the lockup dynamic stream to make the query for.
    function getSegments(uint256 streamId) external view returns (LockupDynamic.Segment[] memory segments);

    /// @notice Queries the lockup dynamic stream entity.
    /// @param streamId The id of the lockup dynamic stream to make the query for.
    function getStream(uint256 streamId) external view returns (LockupDynamic.Stream memory stream);

    /// @notice Calculates the amount that has been streamed to the recipient, in units of the asset's decimals.
    /// @dev The streaming function is:
    ///
    /// $$
    /// f(x) = x^{exp} * csa + \Sigma(esa)
    /// $$
    ///
    /// Where:
    ///
    /// - $x$ is the elapsed time divided by the total time in the current segment.
    /// - $exp$ is the current segment exponent.
    /// - $csa$ is the current segment amount.
    /// - $\Sigma(esa)$ is the sum of all elapsed segments' amounts.
    ///
    /// @param streamId The id of the lockup dynamic stream to make the query for.
    function streamedAmountOf(uint256 streamId) external view returns (uint128 streamedAmount);

    /*//////////////////////////////////////////////////////////////////////////
                               NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Creates a lockup dynamic stream by setting the start time to `block.timestamp`, and the end time
    /// to the sum of `block.timestamp` and all specified time deltas. The segment milestones are derived from these
    /// deltas. The stream is funded by `msg.sender` and is wrapped in an ERC-721 NFT.
    ///
    /// @dev Emits a {CreateLockupDynamicStream} and a {Transfer} event.
    ///
    /// Requirements:
    /// - All from {createWithMilestones}.
    ///
    /// @param params Struct that encapsulates the function parameters.
    /// @return streamId The id of the newly created lockup dynamic stream.
    function createWithDeltas(LockupDynamic.CreateWithDeltas calldata params) external returns (uint256 streamId);

    /// @notice Creates a lockup dynamic stream with the provided milestones, implying the end time from the last
    /// segment's milestone. The stream is funded by `msg.sender` and is wrapped in an ERC-721 NFT.
    ///
    /// @dev Emits a {CreateLockupDynamicStream} and a {Transfer} event.
    ///
    /// Notes:
    /// - As long as the segment milestones are arranged in ascending order, it is not an error for some
    /// of them to be in the past.
    ///
    /// Requirements:
    /// - The call must not be a delegate call.
    /// - `params.totalAmount` must not be zero.
    /// - If set, `params.broker.fee` must not be greater than `MAX_FEE`.
    /// - `params.segments` must have at least one segment, but not more than `MAX_SEGMENT_COUNT`.
    /// - The first segment's milestone must be greater than or equal to `params.startTime`.
    /// - The segment milestones must be arranged in ascending order.
    /// - `params.startTime` must not be greater than the last segment's milestone.
    /// - The sum of the segment amounts must be equal to the deposit amount.
    /// - `params.recipient` must not be the zero address.
    /// - `msg.sender` must have allowed this contract to spend at least `params.totalAmount` assets.
    ///
    /// @param params Struct that encapsulates the function parameters.
    /// @return streamId The id of the newly created lockup dynamic stream.
    function createWithMilestones(LockupDynamic.CreateWithMilestones calldata params)
        external
        returns (uint256 streamId);
}
