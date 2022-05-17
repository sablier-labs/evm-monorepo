// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.13;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { ISablierV2 } from "./ISablierV2.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";

/// @title ISablierV2Pro
/// @author Sablier Labs Ltd
/// @notice Creates streams with custom emission curves.
interface ISablierV2Pro is ISablierV2 {
    /// CUSTOM ERRORS ///

    /// @notice Emitted when attempting to create a stream with segment elements size is not equal.
    error SablierV2Pro__ElementsLengthIsNotEqual(uint256 amountLength, uint256 exponentLength, uint256 milestoneLength);

    /// @notice Emitted when attempting to create a stream with an empty segment elements.
    error SablierV2Pro__SegmentsLengthIsZero(uint256 amountLength);

    /// @notice Emitted when attempting to create a stream with start time greater than a segment milestone.
    error SablierV2Pro__StartTimeGreaterThanMilestone(uint256 startTime, uint256 segmentMilestone);

    /// @notice Emitted when attempting to create a stream with a milestone greater than stop time.
    error SablierV2Pro__MilestoneGreaterThanStopTime(uint256 milestone, uint256 stopTime);

    /// @notice Emitted when attempting to create a stream with a previous milestone greater than milestone.
    error SablierV2Pro__PreviousMilestoneIsEqualOrGreaterThanMilestone(uint256 previousMilestonene, uint256 milestone);

    /// @notice Emitted when attempting to create a stream with a segment exponent equal zero.
    error SablierV2Pro__SegmentExponentIsZero(uint256 exponent);

    /// @notice Emitted when attempting to create a stream with a segment exponent greater than two.
    error SablierV2Pro__SegmentExponentGreaterThanTwo(uint256 exponent);

    /// @notice Emitted when attempting to create a stream with a deposit amount not equal segement amount cumulated.
    error SablierV2Pro__DepositIsNotEqualToSegmentAmounts(uint256 depositAmount, UD60x18 cumulativeAmount);

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
        uint256[] segmentExponents,
        uint256[] segmentMilestones,
        bool cancelable
    );

    /// STRUCTS ///

    /// @notice Pro stream segment struct.
    /// @dev Based on the streaming function $f(x) = x^{exponent}$, where x is the elapsed time divided by
    /// the total time.
    /// @member amount The total amount of tokens to be streamed.
    /// @member milestone The unix timestamp in seconds for when the segment ends.
    /// @member exponent The exponent in the streaming function.

    /// @notice Pro stream struct.
    /// @dev The members are arranged like this to save gas via tight variable packing.
    struct Stream {
        uint256[] segmentAmounts;
        uint256[] segmentExponents;
        uint256[] segmentMilestones;
        uint256 depositAmount;
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

    /// @notice Creates a new stream funded by `msg.sender`.
    ///
    /// @dev Emits a {CreateStream} event.
    ///
    /// Requirements:
    /// - `sender` cannot be the zero address.
    /// - `recipient` cannot be the zero address.
    /// - `depositAmount` cannot be zero.
    /// - `startTime` cannot be greater than `stopTime`.
    /// - `segmentAmounts` must be non-empty.
    /// - `segmentExponents` must be non-empty.
    /// - `segmentMilestones` must be non-empty.
    /// - `msg.sender` must have allowed this contract to spend `depositAmount` tokens.
    ///
    /// @param sender The address from which to stream the money.
    /// @param recipient The address toward which to stream the money.
    /// @param token The address of the ERC-20 token to use for streaming.
    /// @param depositAmount The total amount of money to be streamed.
    /// @param startTime The unix timestamp in seconds for when the stream will start.
    /// @param stopTime The unix timestamp in seconds for when the stream will stop.
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
        uint256 stopTime,
        uint256[] memory segmentAmounts,
        uint256[] memory segmentExponents,
        uint256[] memory segmentMilestones,
        bool cancelable
    ) external returns (uint256 streamId);

    /// @notice Creates a new stream funded by `from`.
    ///
    /// @dev Emits a {CreateStream} event and an {Authorize} event.
    ///
    /// Requirements:
    /// - `from` must have allowed `msg.sender` to create a stream worth `depositAmount` tokens.
    /// - `sender` cannot be the zero address.
    /// - `recipient` cannot be the zero address.
    /// - `depositAmount` cannot be zero.
    /// - `startTime` cannot be greater than `stopTime`.
    /// - `segmentAmounts` must be non-empty.
    /// - `segmentExponents` must be non-empty.
    /// - `segmentMilestones` must be non-empty.
    /// - `msg.sender` must have allowed this contract to spend `depositAmount` tokens.
    ///
    /// @param from The address which funds the stream.
    /// @param sender The address from which to stream the money.
    /// @param recipient The address toward which to stream the money.
    /// @param token The address of the ERC-20 token to use for streaming.
    /// @param depositAmount The amount of money to be streamed.
    /// @param startTime The unix timestamp in seconds for when the stream will start.
    /// @param stopTime The unix timestamp in seconds for when the stream will stop.
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
        uint256 stopTime,
        uint256[] memory segmentAmounts,
        uint256[] memory segmentExponents,
        uint256[] memory segmentMilestones,
        bool cancelable
    ) external returns (uint256 streamId);
}
