// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { UD60x18 } from "@prb/math/src/UD60x18.sol";

import { Escrow } from "../types/Escrow.sol";

/// @title ISablierEscrowState
/// @notice Interface containing state variables (storage and constants) for the {SablierEscrow} contract, along with
/// their respective getters.
interface ISablierEscrowState {
    /*//////////////////////////////////////////////////////////////////////////
                                READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Returns the maximum trade fee that can be applied, denominated in UD60x18, where 1e18 = 100%.
    /// @dev This is a constant state variable.
    function MAX_TRADE_FEE() external view returns (UD60x18);

    /// @notice Retrieves the buyer address for the given order. If its zero address, the order can be filled by any
    /// address.
    /// @dev Reverts if `orderId` references a null order.
    function getBuyer(uint256 orderId) external view returns (address buyer);

    /// @notice Retrieves the address of the ERC-20 token the seller wants to receive.
    /// @dev Reverts if `orderId` references a null order.
    function getBuyToken(uint256 orderId) external view returns (IERC20 buyToken);

    /// @notice Retrieves the time when the order expires and can no longer be filled. Zero is sentinel for orders that
    /// never expire.
    /// @dev Reverts if `orderId` references a null order.
    function getExpiryTime(uint256 orderId) external view returns (uint40 expiryTime);

    /// @notice Retrieves the minimum amount of buy token required to fill the order.
    /// @dev Reverts if `orderId` references a null order.
    function getMinBuyAmount(uint256 orderId) external view returns (uint128 minBuyAmount);

    /// @notice Retrieves the amount of sell token that the seller is willing to sell.
    /// @dev Reverts if `orderId` references a null order.
    function getSellAmount(uint256 orderId) external view returns (uint128 sellAmount);

    /// @notice Retrieves the address of the seller who created the order.
    /// @dev Reverts if `orderId` references a null order.
    function getSeller(uint256 orderId) external view returns (address seller);

    /// @notice Retrieves the address of the ERC-20 token that the seller is willing to sell.
    /// @dev Reverts if `orderId` references a null order.
    function getSellToken(uint256 orderId) external view returns (IERC20 sellToken);

    /// @notice Retrieves the address of the ERC-20 interface of the native token, if it exists.
    /// @dev The native tokens on some chains have a dual interface as ERC-20. For example, on Polygon the $POL token
    /// is the native token and has an ERC-20 version at 0x0000000000000000000000000000000000001010. This means
    /// that `address(this).balance` returns the same value as `balanceOf(address(this))`. To avoid any unintended
    /// behavior, these tokens cannot be used in Sablier. As an alternative, users can use the Wrapped version of the
    /// token, i.e. WMATIC, which is a standard ERC-20 token.
    function nativeToken() external view returns (address);

    /// @notice Counter for order IDs. It's incremented every time a new order is created.
    function nextOrderId() external view returns (uint256);

    /// @notice Returns the status of the order.
    /// @dev Reverts if `orderId` references a null order.
    function statusOf(uint256 orderId) external view returns (Escrow.Status status);

    /// @notice Returns the fee percentage, denominated in UD60x18, where 1e18 = 100%.
    /// @dev This trade fee is taken from both the sell and buy amounts in their respective tokens.
    function tradeFee() external view returns (UD60x18);

    /// @notice Retrieves a flag indicating whether the order was canceled.
    /// @dev Reverts if `orderId` references a null order.
    function wasCanceled(uint256 orderId) external view returns (bool);

    /// @notice Retrieves a flag indicating whether the order was filled.
    /// @dev Reverts if `orderId` references a null order.
    function wasFilled(uint256 orderId) external view returns (bool);
}
