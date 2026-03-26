// SPDX-License-Identifier: MIT
pragma solidity >=0.8.22;

/// @notice Minimal interface for Aave V3 PoolAddressesProvider.
/// @dev One per chain/market. Used to resolve Pool and DataProvider addresses.
interface IAavePoolAddressesProvider {
    /*//////////////////////////////////////////////////////////////////////////
                                READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Returns the address of the Pool proxy.
    function getPool() external view returns (address);

    /// @notice Returns the address of the PoolDataProvider.
    function getPoolDataProvider() external view returns (address);
}

