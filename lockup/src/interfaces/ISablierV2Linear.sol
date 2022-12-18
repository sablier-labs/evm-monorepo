// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.13;

import { UD60x18 } from "@prb/math/UD60x18.sol";

import { DataTypes } from "../libraries/DataTypes.sol";

import { ISablierV2 } from "./ISablierV2.sol";

/// @title ISablierV2Linear
/// @notice Creates streams whose streaming function is $f(x) = x$ after a cliff period, where x is the
/// elapsed time divided by the total duration of the stream.
interface ISablierV2Linear is ISablierV2 {
    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Queries the cliff time of the stream.
    /// @param streamId The id of the stream to make the query for.
    /// @return cliffTime The cliff time of the stream.
    function getCliffTime(uint256 streamId) external view returns (uint40 cliffTime);

    /// @notice Queries the stream struct.
    /// @param streamId The id of the stream to make the query for.
    /// @return stream The stream struct.
    function getStream(uint256 streamId) external view returns (DataTypes.LinearStream memory stream);

    /*//////////////////////////////////////////////////////////////////////////
                               NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Creates a new stream funded by `msg.sender` wrapped in a NFT.
    ///
    /// @dev Emits a {CreateLinearStream} and a {Transfer} event.
    ///
    /// Requirements:
    /// - `sender` must not be the zero address.
    /// - `recipient` must not be the zero address.
    /// - `grossDepositAmount` must not be zero.
    /// - `operatorFee` must not be greater than `MAX_FEE`.
    /// - `startTime` must not be greater than `stopTime`.
    /// - `startTime` must not be greater than cliffTime`.
    /// - `cliffTime` must not be greater than `stopTime`.
    /// - `msg.sender` must have allowed this contract to spend `depositAmount` tokens.
    ///
    /// @param sender The address from which to stream the tokens, which will have the ability to cancel the stream.
    /// It doesn't have to be the same as `msg.sender`.
    /// @param recipient The address toward which to stream the tokens.
    /// @param grossDepositAmount The gross amount of tokens to be deposited, inclusive of fees, in units of the ERC-20
    /// token's decimals.
    /// @param operatorFee The fee that the operator charges on the deposit amount, as an UD60x18 number treated as
    /// a percentage with 100% = 1e18.
    /// @param operator The address of the operator who has helped create the stream, e.g. a front-end website, who
    /// receives the fee.
    /// @param token The address of the ERC-20 token to use for streaming.
    /// @param cancelable Whether the stream will be cancelable or not.
    /// @param startTime The unix timestamp in seconds for when the stream will start.
    /// @param cliffTime The unix timestamp in seconds for when the recipient will be able to withdraw tokens.
    /// @param stopTime The unix timestamp in seconds for when the stream will stop.
    /// @return streamId The id of the newly created stream.
    function create(
        address sender,
        address recipient,
        uint128 grossDepositAmount,
        UD60x18 operatorFee,
        address operator,
        address token,
        bool cancelable,
        uint40 startTime,
        uint40 cliffTime,
        uint40 stopTime
    ) external returns (uint256 streamId);

    /// @notice Creates a stream funded by `msg.sender` wrapped in an ERC-721 NFT and sets the start time to
    /// `block.timestamp` and the stop time to `block.timestamp + duration`.
    ///
    /// @dev Emits a {CreateLinearStream} and a {Transfer} event.
    ///
    /// Requirements:
    /// - All from `create`.
    ///
    /// @param sender The address from which to stream the tokens with a cliff period, which will have the ability to
    /// cancel the stream. It doesn't have to be the same as `msg.sender`.
    /// @param recipient The address toward which to stream the tokens.
    /// @param grossDepositAmount The gross amount of tokens to be deposited, inclusive of fees, in units of the ERC-20
    /// token's decimals.
    /// @param token The address of the ERC-20 token to use for streaming.
    /// @param cancelable Whether the stream will be cancelable or not.
    /// @param operatorFee The fee that the operator charges on the deposit amount, as an UD60x18 number treated as
    /// a percentage with 100% = 1e18.
    /// @param operator The address of the operator who has helped create the stream, e.g. a front-end website, who
    /// receives the fee.
    /// @param cliffDuration The number of seconds for how long the cliff period will last.
    /// @param totalDuration The total number of seconds for how long the stream will last.
    /// @return streamId The id of the newly created stream.
    function createWithDuration(
        address sender,
        address recipient,
        uint128 grossDepositAmount,
        UD60x18 operatorFee,
        address operator,
        address token,
        bool cancelable,
        uint40 cliffDuration,
        uint40 totalDuration
    ) external returns (uint256 streamId);
}
