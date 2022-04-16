// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.4;

/// @notice The common interface between all Sablier V2 streaming contracts.
/// @author Sablier Labs Ltd.

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { ISablierV2 } from "./ISablierV2.sol";

/// @title ISablierV2Cliff
/// @author Sablier Labs Ltd
/// @notice Creates linear streams where the streaming function is f(x) = x with a cliff.
interface ISablierV2Cliff is ISablierV2 {
    /// CUSTOM ERRORS ///

    /// @notice Emitted when attempting to create CliffStream with start time greater than cliff time;
    error SablierV2Cliff__CliffTimeGreaterThanStartTime(uint256, uint256);

    /// @notice Emitted when attempting to create CliffStrem with cliff time greater than stop time;
    error SablierV2Cliff__StopTimeGreaterThanStopTime(uint256, uint256);

    /// EVENTS ///

    /// @notice Emitted when a cliff stream is created.
    /// @param streamId The id of the newly created cliff stream.
    /// @param sender The address from which to stream the money with cliff.
    /// @param recipient The address toward which to stream the money with cliff.
    /// @param depositAmount The amount of money to be streamed.
    /// @param token The address of the ERC-20 token to use for streaming.
    /// @param startTime The unix timestamp in seconds for when the cliff stream will start.
    /// @param stopTime The unix timestamp in seconds for when the cliff stream will stop.
    /// @param cliffTime The unix timestamp in seconds for when the recipient will be able to withdraw tokens.
    /// @param cancelable Whether the cliff stream is cancelable or not.
    event CreateCliffStream(
        uint256 indexed streamId,
        address indexed sender,
        address indexed recipient,
        uint256 depositAmount,
        IERC20 token,
        uint256 startTime,
        uint256 stopTime,
        uint256 cliffTime,
        bool cancelable
    );

    /// STRUCTS ///

    /// @notice Cliff stream struct.
    /// @dev The members are arranged like this to save gas via tight variable packing.
    struct CliffStream {
        uint256 depositAmount;
        uint256 startTime;
        uint256 stopTime;
        uint256 withdrawnAmount;
        uint256 cliffTime;
        address recipient;
        address sender;
        IERC20 token;
        bool cancelable;
    }

    /// CONSTANT FUNCTIONS ///

    function getCliffStream(uint256 streamId) external view returns (CliffStream memory cliffStream);

    /// NON-CONSTANT FUNCTIONS ///

    /// @notice Creates a new cliff stream funded by `msg.sender`.
    ///
    /// @dev Emits a {CreateCliffStream} event and an {Approve} event.
    ///
    /// Requirements:
    /// - `sender` cannot be the zero address.
    /// - `recipient` cannot be the zero address.
    /// - `depositAmount` cannot be zero.
    /// - `startTime` cannot be greater than `stopTime`.
    /// - `msg.sender` must have allowed this contract to spend `depositAmount` tokens.
    ///
    /// @param sender The address from which to stream the money with cliff.
    /// @param recipient The address toward which to stream the money with cliff.
    /// @param depositAmount The amount of money to be streamed.
    /// @param token The address of the ERC-20 token to use for streaming.
    /// @param startTime The unix timestamp in seconds for when the cliff stream will start.
    /// @param stopTime The unix timestamp in seconds for when the cliff stream will stop.
    /// @param cliffTime The unix timestamp in seconds for when the recipient will be able to withdraw tokens.
    /// @param cancelable Whether the cliff stream is cancelable or not.
    /// @return streamId The id of the newly created cliff stream.
    function create(
        address sender,
        address recipient,
        uint256 depositAmount,
        IERC20 token,
        uint256 startTime,
        uint256 stopTime,
        uint256 cliffTime,
        bool cancelable
    ) external returns (uint256 streamId);

    /// @notice Creates a new cliff stream funded by `from`.
    ///
    /// @dev Emits a {CreateCliffStream} event.
    ///
    /// Requirements:
    /// - `from` must have allowed `msg.sender` to create a stream worth `depositAmount` tokens.
    /// - `sender` cannot be the zero address.
    /// - `recipient` cannot be the zero address.
    /// - `depositAmount` cannot be zero.
    /// - `startTime` cannot be greater than `stopTime`.
    /// - `msg.sender` must have allowed this contract to spend `depositAmount` tokens.
    ///
    /// @param from The address which funds the cliff stream.
    /// @param sender The address from which to stream the money with a cliff.
    /// @param recipient The address toward which to stream the money with a cliff.
    /// @param depositAmount The amount of money to be streamed.
    /// @param token The address of the ERC-20 token to use for streaming.
    /// @param startTime The unix timestamp in seconds for when the cliff stream will start.
    /// @param stopTime The unix timestamp in seconds for when the cliff stream will stop.
    /// @param cliffTime The unix timestamp in seconds for when the recipient will be able to withdraw tokens.
    /// @param cancelable Whether the cliff stream is cancelable or not.
    /// @return streamId The id of the newly created cliff stream.
    function createFrom(
        address from,
        address sender,
        address recipient,
        uint256 depositAmount,
        IERC20 token,
        uint256 startTime,
        uint256 stopTime,
        uint256 cliffTime,
        bool cancelable
    ) external returns (uint256 streamId);

    /// @notice Creates a cliff stream funded by `from`. Sets the start time to `block.timestamp` and the stop
    /// time to `block.timestamp + duration`.
    ///
    /// @dev Emits a {CreateCliffStream} event and an {Approve} event.
    ///
    /// Requirements:
    /// - `from` must have allowed `msg.sender` to create a stream worth `depositAmount` tokens.
    /// - The duration calculation cannot overflow uint256.
    ///
    /// @param from The address which funds the cliff stream.
    /// @param sender The address from which to stream the money with cliff.
    /// @param recipient The address toward which to stream the money with cliff.
    /// @param depositAmount The amount of money to be streamed.
    /// @param token The address of the ERC-20 token to use for streaming.
    /// @param duration The number of seconds for how long the cliff stream will last.
    /// @param cliffTime The unix timestamp in seconds for when the recipient will be able to withdraw tokens.
    /// @param cancelable Whether the cliff stream is cancelable or not.
    /// @return streamId The id of the newly created cliff stream.
    function createFromWithDuration(
        address from,
        address sender,
        address recipient,
        uint256 depositAmount,
        IERC20 token,
        uint256 duration,
        uint256 cliffTime,
        bool cancelable
    ) external returns (uint256 streamId);

    /// time to `block.timestamp + duration`.
    /// @notice Creates a cliff stream funded by `msg.sender`. Sets the start time to `block.timestamp` and the stop
    ///
    /// @dev Emits a {CreateCliffStream} event.
    ///
    /// Requirements:
    /// - The duration calculation cannot overflow uint256.
    ///
    /// @param sender The address from which to cliff stream the money.
    /// @param recipient The address toward which to cliff stream the money.
    /// @param depositAmount The amount of money to be streamed.
    /// @param token The address of the ERC-20 token to use for streaming.
    /// @param duration The number of seconds for how long the cliff stream will last.
    /// @param cliffTime The unix timestamp in seconds for when the recipient will be able to withdraw tokens.
    /// @param cancelable Whether the cliff stream is cancelable or not.
    /// @return streamId The id of the newly created cliff stream.
    function createWithDuration(
        address sender,
        address recipient,
        uint256 depositAmount,
        IERC20 token,
        uint256 duration,
        uint256 cliffTime,
        bool cancelable
    ) external returns (uint256 streamId);
}
