// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.4;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { ISablierV2 } from "./ISablierV2.sol";

/// @title ISablierV2Linear
/// @author Sablier Labs Ltd
/// @notice Creates linear streams where the streaming function is f(x) = x.
interface ISablierV2Linear is ISablierV2 {
    /// EVENTS ///

    /// @notice Emitted when a linear stream is created.
    /// @param streamId The id of the newly created linear stream.
    /// @param sender The address from which to linearly stream the money.
    /// @param recipient The address toward which to linearly stream the money.
    /// @param depositAmount The amount of money to be streamed.
    /// @param token The address of the ERC-20 token to use for streaming.
    /// @param startTime The unix timestamp in seconds for when the linear stream will start.
    /// @param stopTime The unix timestamp in seconds for when the linear stream will stop.
    /// @param cancelable Whether the linear stream is cancelable or not.
    event CreateLinearStream(
        uint256 indexed streamId,
        address indexed sender,
        address indexed recipient,
        uint256 depositAmount,
        IERC20 token,
        uint256 startTime,
        uint256 stopTime,
        bool cancelable
    );

    /// STRUCTS ///

    /// @notice Linear stream struct.
    /// @dev The members are arranged like this to save gas via tight variable packing.
    struct LinearStream {
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

    function getLinearStream(uint256 streamId) external view returns (LinearStream memory linearStream);

    /// NON-CONSTANT FUNCTIONS ///

    /// @notice Creates a new linear stream funded by `msg.sender`.
    ///
    /// @dev Emits a {CreateLinearStream} event and an {Approve} event.
    ///
    /// Requirements:
    /// - `sender` cannot be the zero address.
    /// - `recipient` cannot be the zero address.
    /// - `depositAmount` cannot be zero.
    /// - `startTime` cannot be greater than `stopTime`.
    /// - `msg.sender` must have allowed this contract to spend `depositAmount` tokens.
    ///
    /// @param sender The address from which to linearly stream the money.
    /// @param recipient The address toward which to linearly stream the money.
    /// @param depositAmount The amount of money to be streamed.
    /// @param token The address of the ERC-20 token to use for streaming.
    /// @param startTime The unix timestamp in seconds for when the linear stream will start.
    /// @param stopTime The unix timestamp in seconds for when the linear stream will stop.
    /// @param cancelable Whether the linear stream is cancelable or not.
    /// @return streamId The id of the newly created linear stream.
    function create(
        address sender,
        address recipient,
        uint256 depositAmount,
        IERC20 token,
        uint256 startTime,
        uint256 stopTime,
        bool cancelable
    ) external returns (uint256 streamId);

    /// @notice Creates a new linear stream funded by `from`.
    ///
    /// @dev Emits a {CreateLinearStream} event.
    ///
    /// Requirements:
    /// - `from` must have allowed `msg.sender` to create a stream worth `depositAmount` tokens.
    /// - `sender` cannot be the zero address.
    /// - `recipient` cannot be the zero address.
    /// - `depositAmount` cannot be zero.
    /// - `startTime` cannot be greater than `stopTime`.
    /// - `msg.sender` must have allowed this contract to spend `depositAmount` tokens.
    ///
    /// @param from The address which funds the linear stream.
    /// @param sender The address from which to linearly stream the money.
    /// @param recipient The address toward which to linearly stream the money.
    /// @param depositAmount The amount of money to be streamed.
    /// @param token The address of the ERC-20 token to use for streaming.
    /// @param startTime The unix timestamp in seconds for when the linear stream will start.
    /// @param stopTime The unix timestamp in seconds for when the linear stream will stop.
    /// @param cancelable Whether the linear stream is cancelable or not.
    /// @return streamId The id of the newly created linear stream.
    function createFrom(
        address from,
        address sender,
        address recipient,
        uint256 depositAmount,
        IERC20 token,
        uint256 startTime,
        uint256 stopTime,
        bool cancelable
    ) external returns (uint256 streamId);

    /// @notice Creates a linear stream funded by `from`. Sets the start time to `block.timestamp` and the stop
    /// time to `block.timestamp + duration`.
    ///
    /// @dev Emits a {CreateLinearStream} event and an {Approve} event.
    ///
    /// Requirements:
    /// - `from` must have allowed `msg.sender` to create a stream worth `depositAmount` tokens.
    /// - The duration calculation cannot overflow uint256.
    ///
    /// @param from The address which funds the linear stream.
    /// @param sender The address from which to linearly stream the money.
    /// @param recipient The address toward which to linearly stream the money.
    /// @param depositAmount The amount of money to be streamed.
    /// @param token The address of the ERC-20 token to use for streaming.
    /// @param duration The number of seconds for how long the linear stream will last.
    /// @param cancelable Whether the linear stream is cancelable or not.
    /// @return streamId The id of the newly created linear stream.
    function createFromWithDuration(
        address from,
        address sender,
        address recipient,
        uint256 depositAmount,
        IERC20 token,
        uint256 duration,
        bool cancelable
    ) external returns (uint256 streamId);

    /// @notice Creates a linear stream funded by `msg.sender`. Sets the start time to `block.timestamp` and the stop
    /// time to `block.timestamp + duration`.
    ///
    /// @dev Emits a {CreateLinearStream} event.
    ///
    /// Requirements:
    /// - The duration calculation cannot overflow uint256.
    ///
    /// @param sender The address from which to linearly stream the money.
    /// @param recipient The address toward which to linearly stream the money.
    /// @param depositAmount The amount of money to be streamed.
    /// @param token The address of the ERC-20 token to use for streaming.
    /// @param duration The number of seconds for how long the linear stream will last.
    /// @param cancelable Whether the linear stream is cancelable or not.
    /// @return streamId The id of the newly created linear stream.
    function createWithDuration(
        address sender,
        address recipient,
        uint256 depositAmount,
        IERC20 token,
        uint256 duration,
        bool cancelable
    ) external returns (uint256 streamId);
}
