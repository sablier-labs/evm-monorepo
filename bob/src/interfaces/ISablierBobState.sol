// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { Bob } from "../types/Bob.sol";
import { IBobVaultShare } from "./IBobVaultShare.sol";
import { ISablierBobAdapter } from "./ISablierBobAdapter.sol";

/// @title ISablierBobState
/// @notice Contract with state variables for the {SablierBob} contract, their respective getters and modifiers.
interface ISablierBobState {
    /*//////////////////////////////////////////////////////////////////////////
                                READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Returns the adapter configured for a specific vault.
    /// @dev Reverts if `vaultId` references a null vault.
    function getAdapter(uint256 vaultId) external view returns (ISablierBobAdapter adapter);

    /// @notice Returns the default adapter for a given token.
    /// @dev Zero address means no adapter is set.
    /// @param token The ERC-20 token to query the default adapter for.
    /// @return adapter The default adapter for the token.
    function getDefaultAdapterFor(IERC20 token) external view returns (ISablierBobAdapter adapter);

    /// @notice Returns the timestamp when the vault expires.
    /// @dev Reverts if `vaultId` references a null vault.
    function getExpiry(uint256 vaultId) external view returns (uint40 expiry);

    /// @notice Returns the timestamp when a user first deposited into a vault.
    /// @dev Reverts if `vaultId` references a null vault.
    function getFirstDepositTime(uint256 vaultId, address user) external view returns (uint40 depositedAt);

    /// @notice Returns the timestamp when the oracle price was last synced for a vault.
    /// @dev Reverts if `vaultId` references a null vault.
    function getLastSyncedAt(uint256 vaultId) external view returns (uint40 lastSyncedAt);

    /// @notice Returns the oracle price stored for a vault.
    /// @dev Reverts if `vaultId` references a null vault.
    function getLastSyncedPrice(uint256 vaultId) external view returns (uint128 lastSyncedPrice);

    /// @notice Returns the oracle address set for a vault.
    /// @dev Reverts if `vaultId` references a null vault.
    function getOracle(uint256 vaultId) external view returns (AggregatorV3Interface oracle);

    /// @notice Returns the address of the ERC-20 share token for a vault.
    /// @dev Reverts if `vaultId` references a null vault.
    function getShareToken(uint256 vaultId) external view returns (IBobVaultShare shareToken);

    /// @notice Returns the target price at which the vault settles.
    /// @dev Reverts if `vaultId` references a null vault.
    function getTargetPrice(uint256 vaultId) external view returns (uint128 targetPrice);

    /// @notice Returns the ERC-20 token accepted for deposits in a vault.
    /// @dev Reverts if `vaultId` references a null vault.
    function getUnderlyingToken(uint256 vaultId) external view returns (IERC20 token);

    /// @notice Returns whether the vault tokens are staked in an adapter.
    /// @dev Reverts if `vaultId` references a null vault.
    function isStakedInAdapter(uint256 vaultId) external view returns (bool stakedInAdapter);

    /// @notice Retrieves the address of the ERC-20 interface of the native token, if it exists.
    /// @dev The native tokens on some chains have a dual interface as ERC-20. For example, on Polygon the $POL token
    /// is the native token and has an ERC-20 version at 0x0000000000000000000000000000000000001010. This means
    /// that `address(this).balance` returns the same value as `balanceOf(address(this))`. To avoid any unintended
    /// behavior, these tokens cannot be used in Sablier. As an alternative, users can use the Wrapped version of the
    /// token, i.e. WMATIC, which is a standard ERC-20 token.
    function nativeToken() external view returns (address);

    /// @notice Counter for vault IDs, incremented every time a new vault is created.
    function nextVaultId() external view returns (uint256);

    /// @notice Returns the vault status.
    /// @dev Reverts if `vaultId` references a null vault.
    function statusOf(uint256 vaultId) external view returns (Bob.Status status);
}
