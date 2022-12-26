// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.13;

import { SD1x18 } from "@prb/math/SD1x18.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";

import { DataTypes } from "../libraries/DataTypes.sol";

import { ISablierV2 } from "./ISablierV2.sol";

/// @title ISablierV2Pro
/// @notice Creates streams with custom emission curves.
interface ISablierV2Pro is ISablierV2 {
    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice The maximum number of segments allowed in a stream.
    /// @dev This is initialized at construction time.
    function MAX_SEGMENT_COUNT() external view returns (uint256);

    /// @notice Queries the segment amounts used to compose the custom streaming curve.
    /// @param streamId The id of the stream to make the query for.
    /// @return segmentAmounts The segment amounts used to compose the custom streaming curve.
    function getSegmentAmounts(uint256 streamId) external view returns (uint128[] memory segmentAmounts);

    /// @notice Queries the segment exponents used to compose the custom streaming curve.
    /// @param streamId The id of the stream to make the query for.
    /// @return segmentExponents The segment exponents used to compose the custom streaming curve.
    function getSegmentExponents(uint256 streamId) external view returns (SD1x18[] memory segmentExponents);

    /// @notice Queries the segment milestones used to compose the custom streaming curve.
    /// @param streamId The id of the stream to make the query for.
    /// @return segmentMilestones The segment milestones used to compose the custom streaming curve.
    function getSegmentMilestones(uint256 streamId) external view returns (uint40[] memory segmentMilestones);

    /// @notice Queries the stream struct.
    /// @param streamId The id of the stream to make the query for.
    /// @return stream The stream struct.
    function getStream(uint256 streamId) external view returns (DataTypes.ProStream memory stream);

    /*//////////////////////////////////////////////////////////////////////////
                               NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Creates a stream funded by `msg.sender` wrapped in an ERC-721 NFT, setting the start time to
    /// `block.timestamp` and the stop time to `block.timestamp + sum(segmentDeltas)`.
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
    /// @param segmentAmounts The amounts used to compose the custom streaming curve, in units of the token's decimals.
    /// @param segmentExponents The exponents used to compose the custom streaming curve, as SD1x18 numbers.
    /// @param operator The address of the operator who has helped create the stream, e.g. a front-end website, who
    /// receives the fee.
    /// @param operatorFee The fee that the operator charges on the deposit amount, as an UD60x18 number treated as
    /// a percentage with 100% = 1e18.
    /// @param token The address of the ERC-20 token to use for streaming.
    /// @param cancelable Whether the stream is cancelable or not.
    /// @param segmentDeltas The differences between the unix timestamp milestones used to compose the custom streaming
    /// curve.
    /// @return streamId The id of the newly created stream.
    function createWithDeltas(
        address sender,
        address recipient,
        uint128 grossDepositAmount,
        uint128[] memory segmentAmounts,
        SD1x18[] memory segmentExponents,
        address operator,
        UD60x18 operatorFee,
        address token,
        bool cancelable,
        uint40[] memory segmentDeltas
    ) external returns (uint256 streamId);

    /// @notice Creates a new stream funded by `msg.sender` wrapped in an ERC-721 NFT, implying the `stopTime` by
    /// the last element in the `segmentMilestones` array.
    ///
    /// @dev Emits a {CreateProStream} and a {Transfer} event.
    ///
    /// Notes:
    /// - As long as they are ordered, it is not an error to set `startTime` and `segmentMilestones` to
    /// past times.
    ///
    /// Requirements:
    /// - `sender` must not be the zero address.
    /// - `recipient` must not be the zero address.
    /// - `grossDepositAmount` must not be zero.
    /// - `segmentAmounts` must be non-empty and not greater than `MAX_SEGMENT_COUNT`.
    /// - `segmentAmounts` summed up must be equal to the net deposit amount.
    /// - `segmentExponents` must be non-empty and not greater than `MAX_SEGMENT_COUNT`.
    /// - `operatorFee` must not be greater than `MAX_FEE`.
    /// - `startTime` must not be greater than `stopTime`.
    /// - `segmentMilestones` must be non-empty and not greater than `MAX_SEGMENT_COUNT`.
    /// - `segmentMilestones` must be bounded between `startTime` and `stopTime`.
    /// - `msg.sender` must have allowed this contract to spend at least `grossDepositAmount` tokens.
    ///
    /// @param sender The address from which to stream the tokens, which will have the ability to cancel the stream.
    /// It doesn't have to be the same as `msg.sender`.
    /// @param recipient The address toward which to stream the tokens.
    /// @param grossDepositAmount The gross amount of tokens to be deposited, inclusive of fees, in units of the token's
    /// decimals.
    /// @param segmentAmounts The amounts used to compose the custom streaming curve, in units of the token's decimals.
    /// @param segmentExponents The exponents used to compose the custom streaming curve, as SD1x18 numbers.
    /// @param operator The address of the operator who has helped create the stream, e.g. a front-end website, who
    /// receives the fee.
    /// @param operatorFee The fee that the operator charges on the deposit amount, as an UD60x18 number treated as
    /// a percentage with 100% = 1e18.
    /// @param token The address of the ERC-20 token to use for streaming.
    /// @param cancelable Whether the stream will be cancelable or not.
    /// @param startTime The unix timestamp in seconds for when the stream will start.
    /// @param segmentMilestones The unix timestamp milestones used to compose the custom streaming curve.
    /// @return streamId The id of the newly created stream.
    function createWithMilestones(
        address sender,
        address recipient,
        uint128 grossDepositAmount,
        uint128[] memory segmentAmounts,
        SD1x18[] memory segmentExponents,
        address operator,
        UD60x18 operatorFee,
        address token,
        bool cancelable,
        uint40 startTime,
        uint40[] memory segmentMilestones
    ) external returns (uint256 streamId);
}
