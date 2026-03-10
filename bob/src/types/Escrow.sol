// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice Namespace for the structs and enums used in the Sablier Escrow protocol.
library Escrow {
    /// @notice Enum representing the different statuses of an order.
    /// @dev The status is derived at runtime from boolean flags and timestamps, not stored directly.
    /// @custom:value0 CANCELLED Order has been cancelled by the seller.
    /// @custom:value1 EXPIRED Order has expired without being filled.
    /// @custom:value2 FILLED Order has been successfully filled.
    /// @custom:value3 OPEN Order is open and can be filled or cancelled.
    enum Status {
        CANCELLED,
        EXPIRED,
        FILLED,
        OPEN
    }

    /// @notice Struct encapsulating all the configuration and state of an order.
    /// @dev The fields are arranged for gas optimization via tight variable packing.
    /// @param seller The address that created the order and deposited the sell token.
    /// @param buyer The designated counterparty address specified by the seller. If its zero address, the order can be
    /// filled by anyone.
    /// @param sellToken The ERC-20 token being sold, deposited by the seller when the order is created.
    /// @param buyToken The ERC-20 token the seller wants to receive.
    /// @param sellAmount The amount of sell token that the seller is willing to exchange.
    /// @param minBuyAmount The minimum amount of buy token required to fill the order.
    /// @param expiryTime The Unix timestamp when the order expires. Zero is sentinel for orders that never expire.
    /// @param wasCanceled Boolean indicating if the order was canceled.
    /// @param wasFilled Boolean indicating if the order was filled.
    struct Order {
        // slot 0
        address seller;
        uint40 expiryTime;
        bool wasCanceled;
        bool wasFilled;
        // slot 1
        address buyer;
        // slot 2
        IERC20 sellToken;
        // slot 3
        IERC20 buyToken;
        // slot 4
        uint128 sellAmount;
        uint128 minBuyAmount;
    }
}
