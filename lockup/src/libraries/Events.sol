// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.13;

import { SD1x18 } from "@prb/math/SD1x18.sol";
import { SD59x18 } from "@prb/math/SD59x18.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";

/// @title Events
/// @notice Library with events used across the core contracts.
library Events {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a stream is canceled.
    /// @param streamId The id of the stream.
    /// @param sender The address of the sender.
    /// @param recipient The address of the recipient.
    /// @param withdrawAmount The amount of tokens withdrawn to the recipient, in units of the token's decimals.
    /// @param returnAmount The amount of tokens returned to the sender, in units of the token's decimals.
    event Cancel(
        uint256 indexed streamId,
        address indexed sender,
        address indexed recipient,
        uint128 withdrawAmount,
        uint128 returnAmount
    );

    /// @notice Emitted when a linear stream is created.
    /// @param streamId The id of the newly created stream.
    /// @param funder The address which funded the stream.
    /// @param sender The address from which to stream the tokens, which has the ability to cancel the stream.
    /// @param recipient The address toward which to stream the tokens.
    /// @param depositAmount The amount of tokens to be streamed.
    /// @param token The address of the ERC-20 token to use for streaming.
    /// @param startTime The unix timestamp in seconds for when the stream will start.
    /// @param cliffTime The unix timestamp in seconds for when the cliff period will end.
    /// @param stopTime The unix timestamp in seconds for when the stream will stop.
    /// @param cancelable Whether the stream will be cancelable or not.
    event CreateLinearStream(
        uint256 streamId,
        address indexed funder,
        address indexed sender,
        address indexed recipient,
        uint128 depositAmount,
        address token,
        bool cancelable,
        uint40 startTime,
        uint40 cliffTime,
        uint40 stopTime
    );

    /// @notice Emitted when a pro stream is created.
    /// @param streamId The id of the newly created stream.
    /// @param funder The address which funded the stream.
    /// @param sender The address from which to stream the tokens, which has the ability to cancel the stream.
    /// @param recipient The address toward which to stream the tokens.
    /// @param depositAmount The amount of tokens to be streamed.
    /// @param token The address of the ERC-20 token to use for streaming.
    /// @param startTime The unix timestamp in seconds for when the stream will start.
    /// @param stopTime The calculated unix timestamp in seconds for when the stream will stop.
    /// @param segmentAmounts The array of amounts used to compose the custom emission curve.
    /// @param segmentExponents The array of exponents used to compose the custom emission curve.
    /// @param segmentMilestones The array of milestones used to compose the custom emission curve.
    /// @param cancelable Whether the stream will be cancelable or not.
    event CreateProStream(
        uint256 streamId,
        address indexed funder,
        address indexed sender,
        address indexed recipient,
        uint128 depositAmount,
        address token,
        bool cancelable,
        uint40 startTime,
        uint40 stopTime,
        uint128[] segmentAmounts,
        SD1x18[] segmentExponents,
        uint40[] segmentMilestones
    );

    /// @notice Emitted when a sender makes a stream non-cancelable.
    /// @param streamId The id of the stream.
    event Renounce(uint256 indexed streamId);

    /// @notice Emitted when the owner sets a new global fee for a token.
    /// @param owner The address of the current contract owner.
    /// @param token The address of the token the new global fee was set for.
    /// @param oldFee The old global fee for the token.
    /// @param newFee The new global fee for the token.
    event SetGlobalFee(address indexed owner, address indexed token, UD60x18 oldFee, UD60x18 newFee);

    /// @notice Emitted when tokens are withdrawn from a stream.
    /// @param streamId The id of the stream.
    /// @param to The address that received the withdrawn tokens.
    /// @param amount The amount of tokens withdrawn, in units of the token's decimals.
    event Withdraw(uint256 indexed streamId, address indexed to, uint128 amount);
}
