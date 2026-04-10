// SPDX-License-Identifier: MIT
pragma solidity >=0.8.22;

/// @notice Minimal interface for Aave V3 Pool.
interface IAavePool {
    /*//////////////////////////////////////////////////////////////////////////
                                READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Returns the ongoing normalized income for the reserve, expressed in RAY (1e27).
    /// @param asset The address of the underlying ERC20 token.
    function getReserveNormalizedIncome(address asset) external view returns (uint256);

    /*//////////////////////////////////////////////////////////////////////////
                              STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Supplies an amount of underlying asset into the pool, receiving Aave Tokens in return.
    /// @param asset The address of the underlying ERC20 token.
    /// @param amount The amount to supply.
    /// @param onBehalfOf The address that will receive the Aave Tokens.
    /// @param referralCode Referral code for tracking.
    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

    /// @notice Withdraws an amount of underlying asset from the pool, burning the equivalent Aave Tokens.
    /// @param asset The address of the underlying ERC20 token.
    /// @param amount The amount to withdraw.
    /// @param to The address that will receive the underlying tokens.
    /// @return The actual amount withdrawn.
    function withdraw(address asset, uint256 amount, address to) external returns (uint256);
}
