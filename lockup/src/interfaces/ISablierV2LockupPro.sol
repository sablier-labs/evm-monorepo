// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.18;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";
import { UD2x18 } from "@prb/math/UD2x18.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";

import { LockupPro } from "../types/DataTypes.sol";
import { ISablierV2Lockup } from "./ISablierV2Lockup.sol";

/// @title ISablierV2LockupPro
/// @notice Creates and manages lockup streams with custom streaming curves.
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

    /// @notice Calculates the amount that has been streamed to the recipient, in units of the asset's decimals.
    /// @dev The streaming function is:
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
    ///
    /// @param streamId The id of the stream to make the query for.
    function streamedAmountOf(uint256 streamId) external view returns (uint128 streamedAmount);

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
    /// @param params Struct that encapsulates the function parameters.
    /// @return streamId The id of the newly created stream.
    function createWithDeltas(LockupPro.CreateWithDeltas calldata params) external returns (uint256 streamId);

    /// @notice Create a stream by using the provided milestones, implying the end time from the last segment's
    /// milestone. The stream is funded by `msg.sender` and is wrapped in an ERC-721 NFT.
    ///
    /// @dev Emits a {CreateLockupProStream} and a {Transfer} event.
    ///
    /// Notes:
    /// - As long as they are ordered, it is not an error to set the `params.startTime` and the milestones to a range
    /// that is in the past.
    ///
    /// Requirements:
    /// - `params.recipient` must not be the zero address.
    /// - `params.totalAmount` must not be zero.
    /// - `params.segments` must be non-empty and not greater than `MAX_SEGMENT_COUNT`.
    /// - The segment amounts summed up must be equal to the deposit amount.
    /// - The first segment's milestone must be greater than or equal to `params.startTime`.
    /// - `params.startTime` must not be greater than the milestone of the last segment.
    /// - `msg.sender` must have allowed this contract to spend at least `params.totalAmount` assets.
    /// - If set, `params.broker.fee` must not be greater than `MAX_FEE`.
    ///
    /// @param params Struct that encapsulates the function parameters.
    /// @return streamId The id of the newly created stream.
    function createWithMilestones(LockupPro.CreateWithMilestones calldata params) external returns (uint256 streamId);
}
