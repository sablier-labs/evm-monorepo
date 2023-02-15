// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.18;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { UD2x18 } from "@prb/math/UD2x18.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";

import { Broker, LockupPro } from "../types/DataTypes.sol";
import { ISablierV2Lockup } from "./ISablierV2Lockup.sol";

/// @title ISablierV2LockupPro
/// @notice Creates streams with custom streaming curves, based on the following mathematical model:
///
/// $$
/// f(x) = x^{exp} * csa + esas
/// $$
///
/// Where:
///
/// - $x$ is the elapsed time divided by the total time in the current segment.
/// - $exp$ is the current segment exponent.
/// - $csa$ is the current segment amount.
/// - $esas$ are the elapsed segment amounts summed up.
interface ISablierV2LockupPro is ISablierV2Lockup {
    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice The maximum number of segments permitted in a stream.
    /// @dev This is initialized at construction time and cannot be changed later.
    function MAX_SEGMENT_COUNT() external view returns (uint256);

    /// @notice Queries the range of the stream, a struct that encapsulates (i) the start time of the stream,
    /// and (ii) the end time of of the stream, both as Unix timestamps.
    /// @param streamId The id of the stream to make the query for.
    function getRange(uint256 streamId) external view returns (LockupPro.Range memory range);

    /// @notice Queries the segments the protocol uses to compose the custom streaming curve.
    /// @param streamId The id of the stream to make the query for.
    function getSegments(uint256 streamId) external view returns (LockupPro.Segment[] memory segments);

    /// @notice Queries the stream struct entity.
    /// @param streamId The id of the stream to make the query for.
    function getStream(uint256 streamId) external view returns (LockupPro.Stream memory stream);

    /*//////////////////////////////////////////////////////////////////////////
                               NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Create a stream by setting the start time to `block.timestamp` and the end time to the sum of
    /// `block.timestamp` and all segment deltas. The stream is funded by `msg.sender` and is wrapped in an
    /// ERC-721 NFT.
    ///
    /// @dev Emits a {CreateLockupProStream} and a {Transfer} event.
    ///
    /// Requirements:
    /// - All from {createWithMilestones}.
    ///
    /// @param sender The address from which to stream the assets, which will have the ability to cancel the stream.
    /// It doesn't have to be the same as `msg.sender`.
    /// @param recipient The address toward which to stream the assets.
    /// @param totalAmount The total amount of ERC-20 assets to be paid, which includes the stream deposit and any
    /// potential fees. This is represented in units of the asset's decimals.
    /// @param asset The contract address of the ERC-20 asset to use for streaming.
    /// @param cancelable Boolean that indicates whether the stream is cancelable or not.
    /// @param segments The segments with deltas the protocol will use to compose the custom streaming curve.
    /// The milestones will be be calculated by adding each delta to `block.timestamp`.
    /// @param broker An optional struct that encapsulates (i) the address of the broker that has helped create the
    /// stream and (ii) the percentage fee that the broker is paid from `totalAmount`, as an UD60x18 number.
    /// @return streamId The id of the newly created stream.
    function createWithDeltas(
        address sender,
        address recipient,
        uint128 totalAmount,
        IERC20 asset,
        bool cancelable,
        LockupPro.SegmentWithDelta[] memory segments,
        Broker calldata broker
    ) external returns (uint256 streamId);

    /// @notice Create a stream by using the provided milestones, implying the end time from the last segment's
    /// milestone. The stream is funded by `msg.sender` and is wrapped in an ERC-721 NFT.
    ///
    /// @dev Emits a {CreateLockupProStream} and a {Transfer} event.
    ///
    /// Notes:
    /// - As long as they are ordered, it is not an error to set the `startTime` and the milestones to a range that
    /// is in the past
    ///
    /// Requirements:
    /// - `recipient` must not be the zero address.
    /// - `totalAmount` must not be zero.
    /// - `segments` must be non-empty and not greater than `MAX_SEGMENT_COUNT`.
    /// - The segment amounts summed up must be equal to the deposit amount.
    /// - The first segment's milestone must be greater than or equal to `startTime`.
    /// - `startTime` must not be greater than the milestone of the last segment.
    /// - `msg.sender` must have allowed this contract to spend at least `totalAmount` assets.
    /// - If set, `broker.fee` must not be greater than `MAX_FEE`.
    ///
    /// @param sender The address from which to stream the assets, which will have the ability to cancel the stream.
    /// It doesn't have to be the same as `msg.sender`.
    /// @param recipient The address toward which to stream the assets.
    /// @param totalAmount The total amount of ERC-20 assets to be paid, which includes the stream deposit and any
    /// potential fees. This is represented in units of the asset's decimals.
    /// @param asset The contract address of the ERC-20 asset to use for streaming.
    /// @param cancelable Boolean that indicates whether the stream will be cancelable or not.
    /// @param segments  The segments the protocol uses to compose the custom streaming curve.
    /// @param startTime The Unix timestamp for when the stream will start.
    /// @param broker An optional struct that encapsulates (i) the address of the broker that has helped create the
    /// stream and (ii) the percentage fee that the broker is paid from `totalAmount`, as an UD60x18 number.
    /// @return streamId The id of the newly created stream.
    function createWithMilestones(
        address sender,
        address recipient,
        uint128 totalAmount,
        IERC20 asset,
        bool cancelable,
        LockupPro.Segment[] memory segments,
        uint40 startTime,
        Broker calldata broker
    ) external returns (uint256 streamId);
}
