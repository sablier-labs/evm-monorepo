// SPDX-License-Identifier: MIT
pragma solidity >=0.8.22;

/// @notice Minimal interface for Aave V3 interest-bearing tokens.
interface IAaveToken {
    /*//////////////////////////////////////////////////////////////////////////
                                READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Returns the actual balance including accrued interest.
    function balanceOf(address user) external view returns (uint256);

    /// @notice Returns the scaled balance (the raw internal balance before index multiplication).
    function scaledBalanceOf(address user) external view returns (uint256);
}
