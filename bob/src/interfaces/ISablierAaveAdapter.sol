// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IAavePool } from "./external/IAavePool.sol";
import { ISablierBobAdapter } from "./ISablierBobAdapter.sol";

/// @title ISablierAaveAdapter
/// @notice Interface for the Aave V3 yield adapter that supplies tokens to Aave lending pools for yield generation.
/// @dev Extends the base adapter interface with Aave-specific view functions. Unlike the Lido adapter which is
/// WETH-only, this adapter is token-agnostic: it retrieves the underlying token and aToken per vault at registration
/// time, so a single adapter instance can serve all Aave-supported tokens. Internally, it uses Aave's scaled balances
/// to track per-vault and per-user positions within a monolith contract.
interface ISablierAaveAdapter is ISablierBobAdapter {
    /*//////////////////////////////////////////////////////////////////////////
                                READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Returns the Aave V3 Pool contract.
    /// @dev This is an immutable state variable retrieved from the PoolAddressesProvider at deployment.
    function AAVE_POOL() external view returns (IAavePool);

    /// @notice Returns the address of the Aave V3 PoolDataProvider contract.
    /// @dev This is an immutable state variable retrieved from the PoolAddressesProvider at deployment. Used in
    /// {registerVault} to retrieve the aToken address for each vault's underlying token.
    function AAVE_POOL_DATA_PROVIDER() external view returns (address);

    /// @notice Returns the current value of a vault's Aave position including accrued interest.
    /// @dev Computed as `totalScaledBalance * currentLiquidityIndex / 1e27`. Returns 0 if the vault has no position.
    /// @param vaultId The ID of the vault.
    /// @return The current value of the vault's position in the underlying token's native decimals.
    function getCurrentVaultValue(uint256 vaultId) external view returns (uint256);

    /// @notice Returns the total underlying tokens received after unstaking for a vault.
    /// @dev This value is set during {unstakeFullAmount} and used for proportional redemption calculations.
    /// @param vaultId The ID of the vault.
    /// @return The total amount of underlying tokens received from withdrawing the vault's Aave position.
    function getTokensReceivedAfterUnstaking(uint256 vaultId) external view returns (uint256);
}
