// SPDX-License-Identifier: MIT
pragma solidity >=0.8.22;

/// @notice Minimal interface for Aave V3 interest-bearing tokens.
/// @dev Aave tokens are rebasing tokens: `balanceOf` returns an increasing value over time. Internally they store a
/// scaled balance and multiply by the liquidity index on read.
interface IAaveToken {
    /*//////////////////////////////////////////////////////////////////////////
                                READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Returns the actual balance including accrued interest.
    /// @dev Equivalent to: scaledBalanceOf(user) * liquidityIndex / 1e27
    function balanceOf(address user) external view returns (uint256);

    /// @notice Returns the scaled balance (the raw internal balance before index multiplication).
    /// @dev This value is fixed at deposit time and does not change. Use this for per-vault accounting when a single
    /// contract holds aTokens for multiple vaults.
    function scaledBalanceOf(address user) external view returns (uint256);
}
