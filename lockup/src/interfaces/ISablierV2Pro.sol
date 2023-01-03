// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.13;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { SD1x18 } from "@prb/math/SD1x18.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";

import { ProStream, Segment } from "../types/Structs.sol";

import { ISablierV2 } from "./ISablierV2.sol";

/// @title ISablierV2Pro
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
/// - $csa* is the current segment amount.
/// - $esas$ are the elapsed segment amounts summed up.
interface ISablierV2Pro is ISablierV2 {
    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice The maximum number of segments allowed in a stream.
    /// @dev This is initialized at construction time and cannot be changed later.
    function MAX_SEGMENT_COUNT() external view returns (uint256);

    /// @notice Queries the segments used to compose the custom streaming curve.
    /// @param streamId The id of the stream to make the query for.
    /// @return segments The segments used to compose the custom streaming curve.
    function getSegments(uint256 streamId) external view returns (Segment[] memory segments);

    /// @notice Queries the stream struct.
    /// @param streamId The id of the stream to make the query for.
    /// @return stream The stream struct.
    function getStream(uint256 streamId) external view returns (ProStream memory stream);

    /*//////////////////////////////////////////////////////////////////////////
                               NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Creates a stream funded by `msg.sender` wrapped in an ERC-721 NFT, setting the start time to
    /// `block.timestamp` and the stop time to `block.timestamp + sum(deltas)`.
    ///
    /// @dev Emits a {CreateProStream} and a {Transfer} event.
    ///
    /// Requirements:
    /// - All from `createWithMilestones`.
    ///
    /// @param sender The address from which to stream the tokens, which will have the ability to cancel the stream.
    /// It doesn't have to be the same as `msg.sender`.
    /// @param recipient The address toward which to stream the tokens.
    /// @param grossDepositAmount The gross amount of tokens to be deposited, inclusive of fees, in units of the token's
    /// decimals.
    /// @param segments The segments used to compose the custom streaming curve.
    /// @param operator The address of the operator who has helped create the stream, e.g. a front-end website, who
    /// receives the fee.
    /// @param operatorFee The fee that the operator charges on the deposit amount, as an UD60x18 number treated as
    /// a percentage with 100% = 1e18.
    /// @param token The address of the ERC-20 token to use for streaming.
    /// @param cancelable Whether the stream is cancelable or not.
    /// @param deltas The differences between the unix timestamp milestones used to compose the custom streaming
    /// curve.
    /// @return streamId The id of the newly created stream.
    function createWithDeltas(
        address sender,
        address recipient,
        uint128 grossDepositAmount,
        Segment[] memory segments,
        address operator,
        UD60x18 operatorFee,
        IERC20 token,
        bool cancelable,
        uint40[] memory deltas
    ) external returns (uint256 streamId);

    /// @notice Creates a new stream funded by `msg.sender` wrapped in an ERC-721 NFT, implying the stop time by
    /// the last segment's milestone.
    ///
    /// @dev Emits a {CreateProStream} and a {Transfer} event.
    ///
    /// Notes:
    /// - As long as they are ordered, it is not an error to set the `startTime` and the milestones to past range.
    ///
    /// Requirements:
    /// - `sender` must not be the zero address.
    /// - `recipient` must not be the zero address.
    /// - `grossDepositAmount` must not be zero.
    /// - `segments` must be non-empty and not greater than `MAX_SEGMENT_COUNT`.
    /// - The segment amounts summed up must be equal to the net deposit amount.
    /// - The first segment's milestone must be greater than or equal to `startTime`.
    /// - `operatorFee` must not be greater than `MAX_FEE`.
    /// - `startTime` must not be greater than the milestone of the last segment.
    /// - `msg.sender` must have allowed this contract to spend at least `grossDepositAmount` tokens.
    ///
    /// @param sender The address from which to stream the tokens, which will have the ability to cancel the stream.
    /// It doesn't have to be the same as `msg.sender`.
    /// @param recipient The address toward which to stream the tokens.
    /// @param grossDepositAmount The gross amount of tokens to be deposited, inclusive of fees, in units of the token's
    /// decimals.
    /// @param segments The segments used to compose the custom streaming curve.
    /// @param operator The address of the operator who has helped create the stream, e.g. a front-end website, who
    /// receives the fee.
    /// @param operatorFee The fee that the operator charges on the deposit amount, as an UD60x18 number treated as
    /// a percentage with 100% = 1e18.
    /// @param token The address of the ERC-20 token to use for streaming.
    /// @param cancelable Whether the stream will be cancelable or not.
    /// @param startTime The unix timestamp in seconds for when the stream will start.
    /// @return streamId The id of the newly created stream.
    function createWithMilestones(
        address sender,
        address recipient,
        uint128 grossDepositAmount,
        Segment[] memory segments,
        address operator,
        UD60x18 operatorFee,
        IERC20 token,
        bool cancelable,
        uint40 startTime
    ) external returns (uint256 streamId);
}
