// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.20;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// TODO: add Broker

library OpenEnded {
    /// @notice OpenEnded stream.
    /// @dev The fields are arranged like this to save gas via tight variable packing.
    /// @param amountPerSecond The amount of assets that is increasing by every second,
    /// denoted in 18 decimals.
    /// @param balance The amount of assets that is currently available for withdrawal, i.e. the total deposited amounts
    /// subtracted by the total withdrawn amounts, denoted in 18 decimals.
    /// @param recipient The address receiving the assets.
    /// @param lastTimeUpdate The Unix timestamp for the streamed amount calculation.
    /// @param isStream Boolean indicating if the struct entity exists.
    /// @param isCanceled Boolean indicating if the stream is canceled.
    /// @param asset The contract address of the ERC-20 asset used for streaming.
    /// @param assetDecimals The decimals of the ERC-20 asset used for streaming.
    /// @param sender The address streaming the assets, with the ability to cancel the stream.
    struct Stream {
        // slot 0
        uint128 amountPerSecond;
        uint128 balance;
        // slot 1
        address recipient;
        uint40 lastTimeUpdate;
        bool isStream;
        bool isCanceled;
        // slot 2
        IERC20 asset;
        uint8 assetDecimals;
        // slot 3
        address sender;
    }
}
