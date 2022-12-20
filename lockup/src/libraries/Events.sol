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

    /// @notice Emitted when the contract owner claims all protocol revenues accrued for the provided token.
    /// @param owner The address of the current contract owner.
    /// @param token The address of the token the protocol revenues were claimed for.
    /// @param protocolRevenues The amount of protocol revenues claimed, in units of the token's decimals.
    event ClaimProtocolRevenues(address indexed owner, address indexed token, uint128 protocolRevenues);

    /// @notice Emitted when a linear stream is created.
    /// @param streamId The id of the newly created stream.
    /// @param funder The address which funded the stream.
    /// @param sender The address from which to stream the tokens, which has the ability to cancel the stream.
    /// @param recipient The address toward which to stream the tokens.
    /// @param depositAmount The amount of tokens to be streamed, in units of the token's decimals.
    /// @param protocolFeeAmount The amount of tokens charged by the protocol, in units of the token's decimals.
    /// @param operatorFeeAmount The amount of tokens charged by the stream operator, in units of the token's decimals.
    /// @param token The address of the ERC-20 token to use for streaming.
    /// @param cancelable Whether the stream will be cancelable or not.
    /// @param startTime The unix timestamp in seconds for when the stream will start.
    /// @param cliffTime The unix timestamp in seconds for when the cliff period will end.
    /// @param stopTime The unix timestamp in seconds for when the stream will stop.
    event CreateLinearStream(
        uint256 streamId,
        address indexed funder,
        address indexed sender,
        address indexed recipient,
        uint128 depositAmount,
        uint128 protocolFeeAmount,
        address operator,
        uint128 operatorFeeAmount,
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
    /// @param depositAmount The amount of tokens to be streamed, in units of the token's decimals.
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

    /// @notice Emitted when the SablierV2Comptroller contract is set.
    /// @param newComptroller The address of the new SablierV2Comptroller contract.
    event SetComptroller(address indexed owner, address oldComptroller, address newComptroller);

    /// @notice Emitted when the contract owner sets a new protocol fee for the provided token.
    /// @param owner The address of the current contract owner.
    /// @param token The address of the token the new protocol fee was set for.
    /// @param oldFee The old global fee for the provided token.
    /// @param newFee The new global fee for the provided token.
    event SetProtocolFee(address indexed owner, address indexed token, UD60x18 oldFee, UD60x18 newFee);

    /// @notice Emitted when tokens are withdrawn from a stream.
    /// @param streamId The id of the stream.
    /// @param to The address that received the withdrawn tokens.
    /// @param amount The amount of tokens withdrawn, in units of the token's decimals.
    event Withdraw(uint256 indexed streamId, address indexed to, uint128 amount);
}
