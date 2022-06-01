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

    /// @notice Emitted when attempting to create a stream with a deposit amount that is not equal to the segment
    /// amounts summed together.
    error SablierV2Pro__DepositAmountNotEqualToSegmentAmountsSum(uint256 depositAmount, uint256 sum);

    /// @notice Emitted when attempting to create a stream with a milestone greater than the stop time.
    error SablierV2Pro__LastMilestoneGreaterThanStopTime(uint256 milestone, uint256 stopTime);

    /// @notice Emitted when attempting to create a stream with unequal segment variables lengths.
    error SablierV2Pro__SegmentArraysLengthsUnequal(
        uint256 amountLength,
        uint256 exponentLength,
        uint256 milestoneLength
    );

    /// @notice Emitted when attempting to create a stream with zero segments.
    error SablierV2Pro__SegmentArraysLengthZero();

    /// @notice Emitted when attempting to create a stream with an out of bounds segments variables length.
    error SablierV2Pro__SegmentArraysLengthOutOfBounds(uint256 length);

    /// @notice Emitted when attempting to create a stream with an out of bounds exponent.
    error SablierV2Pro__SegmentExponentOutOfBounds(SD59x18 exponent);

    /// @notice Emitted when attempting to create a stream with start time greater than a segment milestone.
    error SablierV2Pro__StartTimeGreaterThanFirstMilestone(uint256 startTime, uint256 segmentMilestone);

    /// @notice Emitted when attempting to create a stream with unordered milestones.
    error SablierV2Pro__UnorderedMilestones(uint256 index, uint256 previousMilestonene, uint256 milestone);

    /// EVENTS ///

    /// @notice Emitted when a pro stream is created.
    /// @param streamId The id of the newly created stream.
    /// @param sender The address from which to stream the money.
    /// @param recipient The address toward which to stream the money.
    /// @param token The address of the ERC-20 token to use for streaming.
    /// @param depositAmount The amount of money to be streamed.
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
        IERC20 token,
        uint256 depositAmount,
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

    function getStream(uint256 streamId) external view returns (Stream memory stream);

    /// NON-CONSTANT FUNCTIONS ///

    /// @notice Creates a new stream funded by `msg.sender`. The `stopTime` is given by the last element in the
    /// `segmentMilestones` array.
    ///
    /// @dev Emits a {CreateStream} event.
    ///
    /// Requirements:
    /// - `sender` cannot be the zero address.
    /// - `recipient` cannot be the zero address.
    /// - `depositAmount` cannot be zero.
    /// - `startTime` cannot be greater than `stopTime`.
    /// - `segmentAmounts` must be non-empty and not greater than five elements.
    /// - `segmentAmounts` summed up must be equal to 'depositAmount'.
    /// - `segmentExponents` must be non-empty and not greater than five elements.
    /// - `segmentExponents` must be bounded between one and three.
    /// - `segmentMilestones` must be non-empty and not greater than five elements.
    /// - `segmentMilestones` must be bounded between 'startTime' and 'stopTime'.
    /// - `msg.sender` must have allowed this contract to spend `depositAmount` tokens.
    ///
    /// @param sender The address from which to stream the money.
    /// @param recipient The address toward which to stream the money.
    /// @param token The address of the ERC-20 token to use for streaming.
    /// @param depositAmount The total amount of money to be streamed.
    /// @param startTime The unix timestamp in seconds for when the stream will start.
    /// @param segmentAmounts The array of amounts used to compose the custom emission curve.
    /// @param segmentExponents The array of exponents used to compose the custom emission curve.
    /// @param segmentMilestones The array of milestones used to compose the custom emission curve.
    /// @param cancelable Whether the stream will be cancelable or not.
    /// @return streamId The id of the newly created stream.
    function create(
        address sender,
        address recipient,
        IERC20 token,
        uint256 depositAmount,
        uint256 startTime,
        uint256[] memory segmentAmounts,
        SD59x18[] memory segmentExponents,
        uint256[] memory segmentMilestones,
        bool cancelable
    ) external returns (uint256 streamId);

    /// @notice Creates a new stream funded by `from`. The `stopTime` is given by the last element in the
    /// `segmentMilestones` array.
    ///
    /// @dev Emits a {CreateStream} event and an {Authorize} event.
    ///
    /// Requirements:
    /// - `from` must have allowed `msg.sender` to create a stream worth `depositAmount` tokens.
    /// - `sender` cannot be the zero address.
    /// - `recipient` cannot be the zero address.
    /// - `depositAmount` cannot be zero.
    /// - `startTime` cannot be greater than `stopTime`.
    /// - `segmentAmounts` must be non-empty and not greater than five elements.
    /// - `segmentAmounts` summed up must be equal to 'depositAmount'.
    /// - `segmentExponents` must be non-empty and not greater than five elements.
    /// - `segmentExponents` must be bounded between one and three.
    /// - `segmentMilestones` must be non-empty and not greater than five elements.
    /// - `segmentMilestones` must be bounded between 'startTime' and 'stopTime'.
    /// - `msg.sender` must have allowed this contract to spend `depositAmount` tokens.
    ///
    /// @param from The address which funds the stream.
    /// @param sender The address from which to stream the money.
    /// @param recipient The address toward which to stream the money.
    /// @param token The address of the ERC-20 token to use for streaming.
    /// @param depositAmount The amount of money to be streamed.
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
        IERC20 token,
        uint256 depositAmount,
        uint256 startTime,
        uint256[] memory segmentAmounts,
        SD59x18[] memory segmentExponents,
        uint256[] memory segmentMilestones,
        bool cancelable
    ) external returns (uint256 streamId);
}
