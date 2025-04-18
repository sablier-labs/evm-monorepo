// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IRoleAdminable } from "./interfaces/IRoleAdminable.sol";
import { Errors } from "./libraries/Errors.sol";
import { Adminable } from "./Adminable.sol";

/// @title RoleAdminable
/// @notice See the documentation in {IRoleAdminable}.
/// @dev This contract is a lightweight version of OpenZeppelin's AccessControl contract which can be found at
/// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v5.0.2/contracts/access/AccessControl.sol.
abstract contract RoleAdminable is IRoleAdminable, Adminable {
    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IRoleAdminable
    bytes32 public constant override FEE_COLLECTOR_ROLE = keccak256("FEE_COLLECTOR_ROLE");

    /// @inheritdoc IRoleAdminable
    bytes32 public constant override FEE_MANAGEMENT_ROLE = keccak256("FEE_MANAGEMENT_ROLE");

    /*//////////////////////////////////////////////////////////////////////////
                                  STATE VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev A mapping of role identifiers to the addresses that have been granted the role. Roles are referred to by
    /// their `bytes32` identifier.
    mapping(bytes32 role => mapping(address account => bool)) private _roles;

    /*//////////////////////////////////////////////////////////////////////////
                                      MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Reverts if `msg.sender` neither has the `role` nor is the admin.
    modifier onlyRole(bytes32 role) {
        _checkRoleOrIsAdmin(role);
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @param initialAdmin The address of the initial admin.
    constructor(address initialAdmin) Adminable(initialAdmin) { }

    /*//////////////////////////////////////////////////////////////////////////
                            USER-FACING CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IRoleAdminable
    function hasRoleOrIsAdmin(bytes32 role, address account) public view override returns (bool) {
        return _hasRoleOrIsAdmin(role, account);
    }

    /*//////////////////////////////////////////////////////////////////////////
                         USER-FACING NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IRoleAdminable
    function grantRole(bytes32 role, address account) public override onlyAdmin {
        // Check: `account` does not have the `role`.
        if (_roles[role][account]) {
            revert Errors.AccountAlreadyHasRole(role, account);
        }

        // Effect: grant the `role` to `account`.
        _roles[role][account] = true;

        // Emit the {RoleGranted} event.
        emit RoleGranted({ admin: msg.sender, account: account, role: role });
    }

    /// @inheritdoc IRoleAdminable
    function revokeRole(bytes32 role, address account) public override onlyAdmin {
        // Check: `account` has the `role`.
        if (!_roles[role][account]) {
            revert Errors.AccountDoesNotHaveRole(role, account);
        }

        // Effect: revoke the `role` from `account`.
        _roles[role][account] = false;

        // Emit the {RoleRevoked} event.
        emit RoleRevoked({ admin: msg.sender, account: account, role: role });
    }

    /*//////////////////////////////////////////////////////////////////////////
                             PRIVATE CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Checks whether `msg.sender` has the `role` or is the admin. This is used in the {onlyRole} modifier.
    function _checkRoleOrIsAdmin(bytes32 role) private view {
        // Check: `msg.sender` is the admin or has the `role`.
        if (!_hasRoleOrIsAdmin(role, msg.sender)) {
            revert Errors.UnauthorizedAccess({ caller: msg.sender, neededRole: role });
        }
    }

    /// @dev Returns `true` if `account` is the admin or has the `role`.
    function _hasRoleOrIsAdmin(bytes32 role, address account) private view returns (bool) {
        // Returns true if `account` is the admin or has the `role`.
        if (admin == account || _roles[role][account]) {
            return true;
        }

        // Otherwise, return false.
        return false;
    }
}
