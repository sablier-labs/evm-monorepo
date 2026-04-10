// SPDX-License-Identifier: MIT
pragma solidity >=0.8.22;

/// @notice Minimal interface for Aave V3 pool data provider.
/// @dev Used to look up Aave Token addresses for a given underlying asset.
interface IAavePoolDataProvider {
    /*//////////////////////////////////////////////////////////////////////////
                                READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Returns the token addresses for a given reserve.
    /// @param asset The address of the underlying ERC20 token.
    /// @return aaveTokenAddress The Aave Token (interest-bearing) address.
    /// @return stableDebtTokenAddress The stable debt token address.
    /// @return variableDebtTokenAddress The variable debt token address.
    function getReserveTokensAddresses(address asset)
        external
        view
        returns (address aaveTokenAddress, address stableDebtTokenAddress, address variableDebtTokenAddress);
}
