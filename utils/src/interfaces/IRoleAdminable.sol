// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";

/// @title IRoleAdminable
/// @notice Contract module that provides role-based access control mechanisms through OpenZeppelin's AccessControl
/// contract, including an admin that can be granted exclusive access to specific functions. The inheriting contract
/// must set the initial admin in the constructor.
interface IRoleAdminable is IAccessControl {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when the admin is transferred.
    /// @param oldAdmin The address of the old admin.
    /// @param newAdmin The address of the new admin.
    event TransferAdmin(address indexed oldAdmin, address indexed newAdmin);

    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice A role with the authority to collect fees from the Sablier contracts.
    function FEE_COLLECTOR_ROLE() external view returns (bytes32);

    /// @notice A role with the authority to update fees across the Sablier contracts.
    function FEE_MANAGEMENT_ROLE() external view returns (bytes32);

    /// @notice Returns the address of the admin.
    function admin() external view returns (address);

    /// @notice Returns `true` if `msg.sender` has the `role` or is the admin.
    function hasRoleOrIsAdmin(bytes32 role) external view returns (bool);

    /*//////////////////////////////////////////////////////////////////////////
                               NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Transfers the admin to a new address.
    ///
    /// @dev Notes:
    /// - Revokes the {AccessControl.DEFAULT_ADMIN_ROLE} from the old admin.
    /// - Grants the {AccessControl.DEFAULT_ADMIN_ROLE} to the new admin.
    /// - Does not revert if the admin is the same.
    /// - This function can potentially leave the contract without an admin, thereby removing any
    /// functionality that is only available to the admin.
    ///
    /// Requirements:
    /// - `msg.sender` must be the current admin.
    ///
    /// @param newAdmin The address of the new admin.
    function transferAdmin(address newAdmin) external;
}
