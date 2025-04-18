// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IAdminable } from "./IAdminable.sol";

/// @title IRoleAdminable
/// @notice Contract module that provides role-based access control mechanisms, including an admin that can be granted
/// exclusive access to specific functions. The inheriting contract must set the initial admin in the constructor.
interface IRoleAdminable is IAdminable {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when `account` is granted `role`.
    /// @param admin The address of the admin that granted the role.
    /// @param account The address of the account to which the role is granted.
    /// @param role The identifier of the role.
    event RoleGranted(address indexed admin, address indexed account, bytes32 indexed role);

    /// @notice Emitted when `account` is revoked `role`.
    /// @param admin The address of the admin that revoked the role.
    /// @param account The address of the account from which the role is revoked.
    /// @param role The identifier of the role.
    event RoleRevoked(address indexed admin, address indexed account, bytes32 indexed role);

    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice A role with the authority to collect fees from the Sablier contracts.
    function FEE_COLLECTOR_ROLE() external view returns (bytes32);

    /// @notice A role with the authority to update fees across the Sablier contracts.
    function FEE_MANAGEMENT_ROLE() external view returns (bytes32);

    /// @notice Returns `true` if `account` has the `role` or is the admin.
    function hasRoleOrIsAdmin(bytes32 role, address account) external view returns (bool);

    /*//////////////////////////////////////////////////////////////////////////
                               NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Grants `role` to `account`. Reverts if `account` already has the role.
    ///
    /// @dev Emits {RoleGranted} event.
    ///
    /// Requirements:
    /// - `msg.sender` must be the admin.
    ///
    /// @param role The identifier of the role.
    /// @param account The address of the account to which the role is granted.
    function grantRole(bytes32 role, address account) external;

    /// @notice Revokes `role` from `account`. Reverts if `account` does not have the role.
    ///
    /// @dev Emits {RoleRevoked} event.
    ///
    /// Requirements:
    /// - `msg.sender` must be the admin.
    ///
    /// @param role The identifier of the role.
    /// @param account The address of the account from which the role is revoked.
    function revokeRole(bytes32 role, address account) external;
}
