// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IAavePool } from "./external/IAavePool.sol";
import { ISablierBobAdapter } from "./ISablierBobAdapter.sol";

/// @title ISablierAaveAdapter
/// @notice Interface for the Aave V3 yield adapter that supplies deposited tokens to Aave lending pools.
/// @dev Extends the base adapter interface with Aave specific functionalities.
interface ISablierAaveAdapter is ISablierBobAdapter {
    /*//////////////////////////////////////////////////////////////////////////
                                READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Returns the Aave V3 Pool contract.
    /// @dev This is an immutable state variable.
    function AAVE_POOL() external view returns (IAavePool);

    /// @notice Returns the address of the Aave V3 pool data provider.
    /// @dev This is an immutable state variable.
    function AAVE_POOL_DATA_PROVIDER() external view returns (address);

    /// @notice Returns the total Aave Token scaled balance for a vault.
    /// @param vaultId The ID of the vault.
    function getAaveTokenBalanceScaled(uint256 vaultId) external view returns (uint256);

    /// @notice Returns the Aave Token scaled balance for a specific user in a vault.
    /// @param vaultId The ID of the vault.
    /// @param user The address of the user.
    function getAaveTokenBalanceScaledFor(uint256 vaultId, address user) external view returns (uint256);

    /// @notice Returns the total underlying tokens received after unstaking for a vault.
    /// @param vaultId The ID of the vault.
    function getTokensReceivedAfterUnstaking(uint256 vaultId) external view returns (uint256);
}
