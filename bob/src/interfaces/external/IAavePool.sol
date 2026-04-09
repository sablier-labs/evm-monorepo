// SPDX-License-Identifier: MIT
pragma solidity >=0.8.22;

/// @notice Minimal interface for Aave V3 Pool.
interface IAavePool {
    /*//////////////////////////////////////////////////////////////////////////
                                READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Returns the ongoing normalized income for the reserve.
    /// @dev A value of 1e27 (RAY) means no interest has accrued. Grows over time. Used to convert scaled balances to
    /// actual balances: actualBalance = scaledBalance * income / 1e27
    /// @param asset The address of the underlying ERC20 token.
    /// @return The normalized income, expressed in RAY (1e27).
    function getReserveNormalizedIncome(address asset) external view returns (uint256);

    /*//////////////////////////////////////////////////////////////////////////
                              STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Supplies an `amount` of `asset` into the pool, receiving Aave Tokens in return.
    /// @param asset The address of the underlying ERC20 token.
    /// @param amount The amount to supply (in the asset's native decimals).
    /// @param onBehalfOf The address that will receive the Aave Tokens. Use address(this) for vaults.
    /// @param referralCode Referral code for tracking. Use 0 if not applicable.
    function supply(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;

    /// @notice Withdraws an `amount` of `asset` from the pool, burning the equivalent Aave Tokens.
    /// @param asset The address of the underlying ERC20 token.
    /// @param amount The amount to withdraw. Use type(uint256).max for the full balance.
    /// @param to The address that will receive the underlying tokens.
    /// @return The actual amount withdrawn.
    function withdraw(address asset, uint256 amount, address to) external returns (uint256);
}
