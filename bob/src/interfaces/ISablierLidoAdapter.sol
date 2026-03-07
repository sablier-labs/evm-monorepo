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

    /// @notice Emitted when the comptroller requests a Lido native withdrawal for a vault.
    event RequestLidoWithdrawal(
        uint256 indexed vaultId,
        address indexed comptroller,
        uint256 wstETHAmount,
        uint256 stETHAmount,
        uint256[] withdrawalRequestIds
    );

    /// @notice Emitted when the comptroller sets a new slippage tolerance.
    event SetSlippageTolerance(UD60x18 previousTolerance, UD60x18 newTolerance);

    /*//////////////////////////////////////////////////////////////////////////
                                READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Returns the address of the Curve stETH/ETH pool.
    /// @dev This is an immutable state variable.
    function CURVE_POOL() external view returns (address);

    /// @notice Returns the address of the Lido withdrawal queue contract.
    /// @dev This is an immutable state variable.
    function LIDO_WITHDRAWAL_QUEUE() external view returns (address);

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

    /// @notice Returns the Lido withdrawal request IDs for a vault.
    /// @dev Multiple request IDs may be generated for a vault if the total amount exceeds the Lido enforced
    /// per-withdrawal limit.
    function getLidoWithdrawalRequestIds(uint256 vaultId) external view returns (uint256[] memory);

    /// @notice Returns the total WETH received after unstaking for a vault.
    /// @param vaultId The ID of the vault.
    function getWethReceivedAfterUnstaking(uint256 vaultId) external view returns (uint256);

    /// @notice Returns the current slippage tolerance for Curve swaps, denominated in UD60x18, where 1e18 = 100%.
    function slippageTolerance() external view returns (UD60x18);

    /*//////////////////////////////////////////////////////////////////////////
                              STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Requests a native Lido withdrawal for a vault's staked tokens, bypassing the Curve swap.
    ///
    /// @dev Emits a {RequestLidoWithdrawal} event.
    ///
    /// Notes:
    /// - This unwraps the vault's wstETH to stETH and submits it to Lido's withdrawal queue.
    /// - Once called, the Curve swap is permanently disabled for `vaultId`.
    /// - After the queue finalizes the withdrawal, ETH can be redeemed by calling {unstakeFullAmount}.
    /// - Large amounts are automatically split into multiple requests to comply with Lido's per-request limit.
    ///
    /// Requirements:
    /// - The caller must be the comptroller.
    /// - The vault must have wstETH to withdraw.
    /// - The status of the vault must not be ACTIVE.
    /// - A withdrawal request must not have already been requested for this vault.
    /// - The total amount to withdraw must not be less than the minimum amount per request.
    ///
    /// @param vaultId The ID of the vault.
    function requestLidoWithdrawal(uint256 vaultId) external;

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
