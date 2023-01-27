// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.13;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { UD2x18 } from "@prb/math/UD2x18.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";

import { Broker, LockupProStream, Segment } from "../types/Structs.sol";
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

    /// @notice Queries the segments the protocol uses to compose the custom streaming curve.
    /// @param streamId The id of the stream to make the query for.
    function getSegments(uint256 streamId) external view returns (Segment[] memory segments);

    /// @notice Queries the stream struct entity.
    /// @param streamId The id of the stream to make the query for.
    function getStream(uint256 streamId) external view returns (LockupProStream memory stream);

    /*//////////////////////////////////////////////////////////////////////////
                               NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Create a stream by setting the start time to `block.timestamp` and the stop time to the sum of
    /// `block.timestamp` and all `deltas`. The stream is funded by `msg.sender` and is wrapped in an ERC-721 NFT.
    ///
    /// @dev Emits a {CreateLockupProStream} and a {Transfer} event.
    ///
    /// Notes:
    /// - The segment milestones should be empty, as they will be overridden.
    ///
    /// Requirements:
    /// - All from {createWithMilestones}.
    ///
    /// @param sender The address from which to stream the assets, which will have the ability to cancel the stream.
    /// It doesn't have to be the same as `msg.sender`.
    /// @param recipient The address toward which to stream the assets.
    /// @param grossDepositAmount The gross amount of assets to be deposited, inclusive of fees, in units of the asset's
    /// decimals.
    /// @param segments The segments the protocol uses to compose the custom streaming curve.
    /// @param asset The contract address of the ERC-20 asset to use for streaming.
    /// @param cancelable A boolean that indicates whether the stream is cancelable or not.
    /// @param deltas The differences between the Unix timestamp milestones used to compose the custom streaming
    /// curve.
    /// @param broker An optional struct that encapsulates (i) the address of the broker that has helped create the
    /// stream and (ii) the percentage fee that the broker is paid from the deposit amount, as an UD60x18 number.
    /// @return streamId The id of the newly created stream.
    function createWithDeltas(
        address sender,
        address recipient,
        uint128 grossDepositAmount,
        Segment[] memory segments,
        IERC20 asset,
        bool cancelable,
        uint40[] memory deltas,
        Broker calldata broker
    ) external returns (uint256 streamId);

    /// @notice Create a stream by using the provided milestones, implying the stop time from the last segment's.
    /// milestone. The stream is funded by `msg.sender` and is wrapped in an ERC-721 NFT.
    ///
    /// @dev Emits a {CreateLockupProStream} and a {Transfer} event.
    ///
    /// Notes:
    /// - As long as they are ordered, it is not an error to set the `startTime` and the milestones to a past range.
    ///
    /// Requirements:
    /// - `recipient` must not be the zero address.
    /// - `grossDepositAmount` must not be zero.
    /// - `segments` must be non-empty and not greater than `MAX_SEGMENT_COUNT`.
    /// - The segment amounts summed up must be equal to the net deposit amount.
    /// - The first segment's milestone must be greater than or equal to `startTime`.
    /// - `startTime` must not be greater than the milestone of the last segment.
    /// - `msg.sender` must have allowed this contract to spend at least `grossDepositAmount` assets.
    /// - If set, `broker.fee` must not be greater than `MAX_FEE`.
    ///
    /// @param sender The address from which to stream the assets, which will have the ability to cancel the stream.
    /// It doesn't have to be the same as `msg.sender`.
    /// @param recipient The address toward which to stream the assets.
    /// @param grossDepositAmount The gross amount of assets to be deposited, inclusive of fees, in units of the asset's
    /// decimals.
    /// @param segments  The segments the protocol uses to compose the custom streaming curve.
    /// @param asset The contract address of the ERC-20 asset to use for streaming.
    /// @param cancelable A boolean that indicates whether the stream will be cancelable or not.
    /// @param startTime The Unix timestamp for when the stream will start.
    /// @return streamId The id of the newly created stream.
    function createWithMilestones(
        address sender,
        address recipient,
        uint128 grossDepositAmount,
        Segment[] memory segments,
        IERC20 asset,
        bool cancelable,
        uint40 startTime,
        Broker calldata broker
    ) external returns (uint256 streamId);
}
