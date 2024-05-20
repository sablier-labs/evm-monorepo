// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// TODO: add Broker

library OpenEnded {
    /// @notice OpenEnded stream.
    /// @dev The fields are arranged like this to save gas via tight variable packing.
    /// @param balance The amount of assets that is currently available in the stream, i.e. the sum of deposited amounts
    /// subtracted by the sum of withdrawn amounts, denoted in 18 decimals.
    /// @param ratePerSecond The amount of assets that is increasing by every second, denoted in 18 decimals.
    /// @param sender The address streaming the assets, with the ability to cancel the stream.
    /// @param lastTimeUpdate The Unix timestamp for the streamed amount calculation.
    /// @param isStream Boolean indicating if the struct entity exists.
    /// @param isCanceled Boolean indicating if the stream is canceled.
    /// @param isTransferable Boolean indicating if the stream NFT is transferable.
    /// @param asset The contract address of the ERC-20 asset used for streaming.
    /// @param assetDecimals The decimals of the ERC-20 asset used for streaming.
    /// @param remainingAmount The amount of assets still available for withdrawal, when the stream is canceled or the
    /// `ratePerSecond` is adjusted, denoted in 18 decimals.
    struct Stream {
        // slot 0
        uint128 balance;
        uint128 ratePerSecond;
        // slot 1
        address sender;
        uint40 lastTimeUpdate;
        bool isStream;
        bool isCanceled;
        bool isTransferable;
        // slot 2
        IERC20 asset;
        uint8 assetDecimals;
        // slot 3
        uint128 remainingAmount;
    }
}
