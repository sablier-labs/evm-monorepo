// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { UD60x18 } from "@prb/math/src/UD60x18.sol";

import { ISablierBobAdapter } from "./ISablierBobAdapter.sol";

/// @title ISablierLidoAdapter
/// @notice Interface for the Lido yield adapter that stakes WETH as wstETH and unstakes it via Curve.
/// @dev Extends the base adapter interface with Lido and Curve specific functionalities.
interface ISablierLidoAdapter is ISablierBobAdapter {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when the comptroller sets a new slippage tolerance.
    event SetSlippageTolerance(UD60x18 previousTolerance, UD60x18 newTolerance);

    /*//////////////////////////////////////////////////////////////////////////
                                READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Returns the address of the Curve stETH/ETH pool.
    /// @dev This is an immutable state variable.
    function CURVE_POOL() external view returns (address);

    /// @notice Returns the maximum slippage tolerance that can be set, denominated in UD60x18, where 1e18 = 100%.
    /// @dev This is a constant state variable.
    function MAX_SLIPPAGE_TOLERANCE() external view returns (UD60x18);

    /// @notice Returns the address of the stETH contract.
    /// @dev This is an immutable state variable.
    function STETH() external view returns (address);

    /// @notice Returns the address of the Chainlink stETH/ETH oracle used in the calculation of `minEthOut` slippage.
    /// @dev This is an immutable state variable.
    function STETH_ETH_ORACLE() external view returns (address);

    /// @notice Returns the address of the WETH contract.
    /// @dev This is an immutable state variable.
    function WETH() external view returns (address);

    /// @notice Returns the address of the wstETH contract.
    /// @dev This is an immutable state variable.
    function WSTETH() external view returns (address);

    /// @notice Returns the total WETH received after unstaking for a vault.
    /// @param vaultId The ID of the vault.
    function getWethReceivedAfterUnstaking(uint256 vaultId) external view returns (uint256);

    /// @notice Returns the current slippage tolerance for Curve swaps, denominated in UD60x18, where 1e18 = 100%.
    function slippageTolerance() external view returns (UD60x18);

    /*//////////////////////////////////////////////////////////////////////////
                              STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Sets the slippage tolerance for Curve swaps.
    ///
    /// @dev Emits a {SetSlippageTolerance} event.
    ///
    /// Notes:
    /// - This affects all vaults.
    ///
    /// Requirements:
    /// - The caller must be the comptroller.
    /// - `newSlippageTolerance` must not exceed MAX_SLIPPAGE_TOLERANCE.
    ///
    /// @param newTolerance The new slippage tolerance as UD60x18.
    function setSlippageTolerance(UD60x18 newTolerance) external;
}
