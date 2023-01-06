// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.13;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { SD1x18 } from "@prb/math/SD1x18.sol";
import { SD59x18 } from "@prb/math/SD59x18.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";

import { ISablierV2Comptroller } from "../interfaces/ISablierV2Comptroller.sol";
import { CreateAmounts, Range, Segment } from "../types/Structs.sol";

/// @title Events
/// @notice Library with events emitted across the core contracts.
library Events {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when a stream is canceled.
    /// @param streamId The id of the stream.
    /// @param sender The address of the sender.
    /// @param recipient The address of the recipient.
    /// @param senderAmount The amount of tokens returned to the sender, in units of the token's decimals.
    /// @param recipientAmount The amount of tokens withdrawn to the recipient, in units of the token's decimals.
    event Cancel(
        uint256 indexed streamId,
        address indexed sender,
        address indexed recipient,
        uint128 senderAmount,
        uint128 recipientAmount
    );

    /// @notice Emitted when the contract owner claims all protocol revenues accrued for the provided token.
    /// @param owner The address of the current contract owner.
    /// @param token The address of the ERC-20 token the protocol revenues have been claimed for.
    /// @param protocolRevenues The amount of protocol revenues claimed, in units of the token's decimals.
    event ClaimProtocolRevenues(address indexed owner, IERC20 indexed token, uint128 protocolRevenues);

    /// @notice Emitted when a linear stream is created.
    /// @param streamId The id of the newly created stream.
    /// @param funder The address which has funded the stream.
    /// @param sender The address from which to stream the tokens, who will have the ability to cancel the stream.
    /// @param recipient The address toward which to stream the tokens.
    /// @param amounts A struct that encapsulates (i) the net deposit amount, (i) the protocol fee amount, and (iii) the
    /// broker fee amount, each in units of the token's decimals.
    /// @param token The address of the ERC-20 token used for streaming.
    /// @param cancelable A boolean that indicates whether the stream will be cancelable or not.
    /// @param range A struct that encapsulates (i) the start time of the stream, (ii) the cliff time of the stream,
    /// and (iii) the stop time of the stream, all as Unix timestamps.
    /// @param broker The address of the broker who has helped create the stream, e.g. a front-end website.
    event CreateLinearStream(
        uint256 streamId,
        address indexed funder,
        address indexed sender,
        address indexed recipient,
        CreateAmounts amounts,
        IERC20 token,
        bool cancelable,
        Range range,
        address broker
    );

    /// @notice Emitted when a pro stream is created.
    /// @param streamId The id of the newly created stream.
    /// @param funder The address which has funded the stream.
    /// @param sender The address from which to stream the tokens, who will have the ability to cancel the stream.
    /// @param recipient The address toward which to stream the tokens.
    /// @param amounts A struct that encapsulates (i) the net deposit amount, (i) the protocol fee amount, and (iii) the
    /// broker fee amount, each in units of the token's decimals.
    /// @param segments The segments the protocol uses to compose the custom streaming curve.
    /// @param token The address of the ERC-20 token used for streaming.
    /// @param cancelable A boolean that indicates whether the stream will be cancelable or not.
    /// @param startTime The Unix timestamp for when the stream will start.
    /// @param stopTime The Unix timestamp for when the stream will stop.
    /// @param broker The address of the broker who has helped create the stream, e.g. a front-end website.
    event CreateProStream(
        uint256 streamId,
        address indexed funder,
        address indexed sender,
        address indexed recipient,
        CreateAmounts amounts,
        Segment[] segments,
        IERC20 token,
        bool cancelable,
        uint40 startTime,
        uint40 stopTime,
        address broker
    );

    /// @notice Emitted when a sender makes a stream non-cancelable.
    /// @param streamId The id of the stream.
    event Renounce(uint256 indexed streamId);

    /// @notice Emitted when the SablierV2Comptroller contract is set.
    /// @param newComptroller The address of the new SablierV2Comptroller contract.
    event SetComptroller(
        address indexed owner,
        ISablierV2Comptroller oldComptroller,
        ISablierV2Comptroller newComptroller
    );

    /// @notice Emitted when the contract owner sets a new protocol fee for the provided token.
    /// @param owner The address of the current contract owner.
    /// @param token The address of the ERC-20 token the new protocol fee was set for.
    /// @param oldFee The old global fee for the provided token, as an UD60x18 number.
    /// @param newFee The new global fee for the provided token, as an UD60x18 number.
    event SetProtocolFee(address indexed owner, IERC20 indexed token, UD60x18 oldFee, UD60x18 newFee);

    /// @notice Emitted when tokens are withdrawn from a stream.
    /// @param streamId The id of the stream.
    /// @param to The address that has received the withdrawn tokens.
    /// @param amount The amount of tokens withdrawn, in units of the token's decimals.
    event Withdraw(uint256 indexed streamId, address indexed to, uint128 amount);
}
