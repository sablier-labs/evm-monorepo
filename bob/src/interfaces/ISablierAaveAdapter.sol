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

    /// @notice Returns the address of the Aave V3 PoolDataProvider contract address.
    /// @dev This is an immutable state variable.
    function AAVE_POOL_DATA_PROVIDER() external view returns (address);

    /// @notice Returns the total underlying tokens received after unstaking for a vault.
    /// @dev This value is set during {unstakeFullAmount} and used for proportional redemption calculations.
    /// @param vaultId The ID of the vault.
    /// @return The total amount of underlying tokens received from withdrawing the vault's Aave position.
    function getTokensReceivedAfterUnstaking(uint256 vaultId) external view returns (uint256);

    /// @notice Returns the total aToken scaled balance for a vault.
    /// @dev The aToken scaled balance is the sum of all users' aToken scaled balances. It is used as the
    /// denominator in proportional redemption calculations.
    /// @param vaultId The ID of the vault.
    /// @return The total aToken scaled balance for the vault.
    function getATokenTotalScaledBalance(uint256 vaultId) external view returns (uint256);

    /// @notice Returns the aToken scaled balance for a specific user in a vault.
    /// @dev The aToken scaled balance encodes both the deposit amount and deposit timing via the Aave liquidity index.
    /// @param vaultId The ID of the vault.
    /// @param user The address of the user.
    /// @return The user's aToken scaled balance in the vault.
    function getATokenUserScaledBalance(uint256 vaultId, address user) external view returns (uint256);
}
