// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

import { Lockup } from "../types/Lockup.sol";
import { LockupPriceGated } from "../types/LockupPriceGated.sol";
import { ISablierLockupState } from "./ISablierLockupState.sol";

/// @title ISablierLockupPriceGated
/// @notice Creates Lockup streams with price-gated distribution model.
interface ISablierLockupPriceGated is ISablierLockupState {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when an LPG stream is created.
    /// @param streamId The ID of the newly created stream.
    /// @param oracle The price feed oracle used for retrieving the latest price.
    /// @param targetPrice The price that must be reached to unlock the tokens, denominated in Chainlink's 8-decimal,
    /// where 1e8 = $1.
    event CreateLockupPriceGatedStream(
        uint256 indexed streamId,
        AggregatorV3Interface indexed oracle,
        uint128 targetPrice
    );

    /*//////////////////////////////////////////////////////////////////////////
                        USER-FACING STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Creates a stream with the provided start time and end time. The stream is funded by `msg.sender` and is
    /// wrapped in an ERC-721 NFT.
    /// @dev Emits a {Transfer}, {CreateLockupPriceGatedStream} and {MetadataUpdate} event.
    ///
    /// Notes:
    /// - The recipient can withdraw the full deposited amount when either:
    ///   1. The oracle price reaches or exceeds the target price, OR
    ///   2. Current time is greater than the stream's end time.
    /// - The sender can cancel the stream when price is less than target price AND end time is in the future.
    /// - The function does not check if the provided oracle reports the price for the deposited token.
    ///
    /// Requirements:
    /// - Must not be delegate called.
    /// - `params.depositAmount` must be greater than zero.
    /// - `params.sender` must not be the zero address.
    /// - `params.recipient` must not be the zero address.
    /// - `params.timestamps.start` must not be zero.
    /// - `params.timestamps.start` must be less than `params.timestamps.end`.
    /// - `unlockParams.oracle` must implement Chainlink's {AggregatorV3Interface} interface.
    /// - `unlockParams.oracle` must return 8 decimals when the `decimals()` function is called.
    /// - `unlockParams.oracle` must return a positive price when the `latestRoundData()` function is called.
    /// - `unlockParams.targetPrice` must be greater than the current oracle price.
    /// - `msg.sender` must have allowed this contract to spend at least `params.depositAmount` tokens.
    /// - `params.token` must not be the native token.
    /// - `params.shape.length` must not be greater than 32 characters.
    ///
    /// @param params Struct encapsulating the function parameters, which are documented in {Lockup} type.
    /// @param unlockParams Struct encapsulating the unlock parameters, documented in {LockupPriceGated}.
    /// @return streamId The ID of the newly created stream.
    function createWithTimestampsLPG(
        Lockup.CreateWithTimestamps calldata params,
        LockupPriceGated.UnlockParams calldata unlockParams
    )
        external
        payable
        returns (uint256 streamId);
}
