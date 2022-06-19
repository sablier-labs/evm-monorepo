// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.13;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { ISablierV2 } from "./ISablierV2.sol";
import { SD59x18 } from "@prb/math/SD59x18.sol";

/// @title ISablierV2Pro
/// @author Sablier Labs Ltd
/// @notice Creates streams with custom emission curves.
interface ISablierV2Pro is ISablierV2 {
    /// CUSTOM ERRORS ///

    /// @notice Emitted when attempting to create a stream with a deposit amount that does not qual the segment
    /// amounts sum.
    error SablierV2Pro__DepositAmountNotEqualToSegmentAmountsSum(uint256 depositAmount, uint256 segmentAmountsSum);

    /// @notice Emitted when attempting to create a stream with segment counts that are not equal.
    error SablierV2Pro__SegmentCountsNotEqual(uint256 amountLength, uint256 exponentLength, uint256 milestoneLength);

    /// @notice Emitted when attempting to create a stream with one or more out-of-bounds segment count.
    error SablierV2Pro__SegmentCountOutOfBounds(uint256 count);

    /// @notice Emitted when attempting to create a stream with zero segments.
    error SablierV2Pro__SegmentCountZero();

    /// @notice Emitted when attempting to create a stream with an out of bounds exponent.
    error SablierV2Pro__SegmentExponentOutOfBounds(SD59x18 exponent);

    /// @notice Emitted when attempting to create a stream with segment milestones which are not ordered.
    error SablierV2Pro__SegmentMilestonesNotOrdered(uint256 index, uint256 previousMilestonene, uint256 milestone);

    /// @notice Emitted when attempting to create a stream with the start time greater than the first segment milestone.
    error SablierV2Pro__StartTimeGreaterThanFirstMilestone(uint256 startTime, uint256 segmentMilestone);

    /// EVENTS ///

    /// @notice Emitted when a pro stream is created.
    /// @param streamId The id of the newly created stream.
    /// @param sender The address from which to stream the money.
    /// @param recipient The address toward which to stream the money.
    /// @param depositAmount The amount of money to be streamed.
    /// @param token The address of the ERC-20 token to use for streaming.
    /// @param segmentAmounts The array of amounts used to compose the custom emission curve.
    /// @param segmentExponents The array of exponents used to compose the custom emission curve.
    /// @param segmentMilestones The array of milestones used to compose the custom emission curve.
    /// @param startTime The unix timestamp in seconds for when the stream will start.
    /// @param stopTime The unix timestamp in seconds for when the stream will stop.
    /// @param cancelable Whether the stream will be cancelable or not.
    event CreateStream(
        uint256 indexed streamId,
        address indexed sender,
        address indexed recipient,
        uint256 depositAmount,
        IERC20 token,
        uint256 startTime,
        uint256 stopTime,
        uint256[] segmentAmounts,
        SD59x18[] segmentExponents,
        uint256[] segmentMilestones,
        bool cancelable
    );

    /// STRUCTS ///

    /// @notice Pro stream struct.
    /// @dev Based on the streaming function $f(x) = x^{exponent}$, where x is the elapsed time divided by
    /// the total time.
    /// @member segmentAmounts The amounts of tokens to be streamed in each segment.
    /// @member segmentExponents The exponents in the streaming function.
    /// @member segmentMilestones The unix timestamps in seconds for when each segment ends.
    /// @dev The members are arranged like this to save gas via tight variable packing.
    struct Stream {
        uint256 depositAmount;
        uint256[] segmentAmounts;
        SD59x18[] segmentExponents;
        uint256[] segmentMilestones;
        uint256 startTime;
        uint256 stopTime;
        uint256 withdrawnAmount;
        address recipient;
        address sender;
        IERC20 token;
        bool cancelable;
    }

    /// CONSTANT FUNCTIONS ///

    /// @notice Reads the stream struct.
    /// @param streamId The id of the stream to make the query for.
    /// @return stream The stream struct.
    function getStream(uint256 streamId) external view returns (Stream memory stream);

    /// NON-CONSTANT FUNCTIONS ///

    /// @notice Creates a new stream funded by `msg.sender`. The `stopTime` is implied by the last element in the
    /// `segmentMilestones` array.
    ///
    /// @dev Emits a {CreateStream} event.
    ///
    /// Requirements:
    /// - `sender` must not the zero address.
    /// - `recipient` must not the zero address.
    /// - `depositAmount` must not be zero.
    /// - `startTime` must not be greater than `stopTime`.
    /// - `segmentAmounts` must be non-empty and not greater than `MAX_SEGMENT_COUNT`.
    /// - `segmentAmounts` summed up must be equal to `depositAmount`.
    /// - `segmentExponents` must be non-empty and not greater than `MAX_SEGMENT_COUNT`.
    /// - `segmentExponents` must be bounded between one and three.
    /// - `segmentMilestones` must be non-empty and not greater than `MAX_SEGMENT_COUNT`.
    /// - `segmentMilestones` must be bounded between `startTime` and `stopTime`.
    /// - `msg.sender` must have allowed this contract to spend `depositAmount` tokens.
    ///
    /// @param sender The address from which to stream the money.
    /// @param recipient The address toward which to stream the money.
    /// @param depositAmount The total amount of money to be streamed.
    /// @param token The address of the ERC-20 token to use for streaming.
    /// @param startTime The unix timestamp in seconds for when the stream will start.
    /// @param segmentAmounts The array of amounts used to compose the custom emission curve.
    /// @param segmentExponents The array of exponents used to compose the custom emission curve.
    /// @param segmentMilestones The array of milestones used to compose the custom emission curve.
    /// @param cancelable Whether the stream will be cancelable or not.
    /// @return streamId The id of the newly created stream.
    function create(
        address sender,
        address recipient,
        uint256 depositAmount,
        IERC20 token,
        uint256 startTime,
        uint256[] memory segmentAmounts,
        SD59x18[] memory segmentExponents,
        uint256[] memory segmentMilestones,
        bool cancelable
    ) external returns (uint256 streamId);

    /// @notice Creates a new stream funded by `from`. The `stopTime` is implied by the last element in the
    /// `segmentMilestones` array.
    ///
    /// @dev Emits a {CreateStream} event and an {Authorize} event.
    ///
    /// Requirements:
    /// - All from `create`.
    /// - `from` must have allowed `msg.sender` to create a stream worth `depositAmount` tokens.
    ///
    /// @param from The address which funds the stream.
    /// @param sender The address from which to stream the money.
    /// @param recipient The address toward which to stream the money.
    /// @param depositAmount The amount of money to be streamed.
    /// @param token The address of the ERC-20 token to use for streaming.
    /// @param startTime The unix timestamp in seconds for when the stream will start.
    /// @param segmentAmounts The array of amounts used to compose the custom emission curve.
    /// @param segmentExponents The array of exponents used to compose the custom emission curve.
    /// @param segmentMilestones The array of milestones used to compose the custom emission curve.
    /// @param cancelable Whether the stream will be cancelable or not.
    /// @return streamId The id of the newly created stream.
    function createFrom(
        address from,
        address sender,
        address recipient,
        uint256 depositAmount,
        IERC20 token,
        uint256 startTime,
        uint256[] memory segmentAmounts,
        SD59x18[] memory segmentExponents,
        uint256[] memory segmentMilestones,
        bool cancelable
    ) external returns (uint256 streamId);

    /// @notice Creates a stream funded by `msg.sender`. Sets the start time to `block.timestamp` and the stop
    /// time to `block.timestamp + sum(segmentDeltas)`.
    ///
    /// @dev Emits a {CreateStream} event.
    ///
    /// Requirements:
    /// - All from `create`.
    ///
    /// @param sender The address from which to stream the money.
    /// @param recipient The address toward which to stream the money.
    /// @param depositAmount The amount of money to be streamed.
    /// @param token The address of the ERC-20 token to use for streaming.
    /// @param segmentAmounts The array of amounts used to compose the custom emission curve.
    /// @param segmentExponents The array of exponents used to compose the custom emission curve.
    /// @param segmentDeltas The array of differences between the milestones used to compose the custom emission curve.
    /// @param cancelable Whether the stream is cancelable or not.
    /// @return streamId The id of the newly created stream.
    function createWithDuration(
        address sender,
        address recipient,
        uint256 depositAmount,
        IERC20 token,
        uint256[] memory segmentAmounts,
        SD59x18[] memory segmentExponents,
        uint256[] memory segmentDeltas,
        bool cancelable
    ) external returns (uint256 streamId);
}
