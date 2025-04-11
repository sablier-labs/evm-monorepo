// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { IRoleAdminable } from "./interfaces/IRoleAdminable.sol";
import { Errors } from "./libraries/Errors.sol";

/// @title RoleAdminable
/// @notice See the documentation in {IRoleAdminable}.
abstract contract RoleAdminable is IRoleAdminable, AccessControl {
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

    /// @inheritdoc IRoleAdminable
    address public override admin;

    /*//////////////////////////////////////////////////////////////////////////
                                      MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Reverts if called by any account other than the admin.
    modifier onlyAdmin() {
        _onlyAdmin();
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Emits a {TransferAdmin} event.
    /// @param initialAdmin The address of the initial admin.
    constructor(address initialAdmin) {
        // Effect: set the admin.
        admin = initialAdmin;

        // Effect: grant the default admin role to the initial admin.
        _grantRole(DEFAULT_ADMIN_ROLE, initialAdmin);

        // Log the transfer of the admin.
        emit IRoleAdminable.TransferAdmin({ oldAdmin: address(0), newAdmin: initialAdmin });
    }

    /*//////////////////////////////////////////////////////////////////////////
                            USER-FACING CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IRoleAdminable
    function hasRoleOrIsAdmin(bytes32 role) public view override returns (bool) {
        return hasRole(role, _msgSender()) || admin == _msgSender();
    }

    /*//////////////////////////////////////////////////////////////////////////
                         USER-FACING NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IRoleAdminable
    function transferAdmin(address newAdmin) public virtual override onlyAdmin {
        // Effect: update the admin.
        admin = newAdmin;

        // Effect: revoke the default admin role from the old admin.
        _revokeRole(DEFAULT_ADMIN_ROLE, _msgSender());

        // Effect: grant the default admin role to the new admin.
        _grantRole(DEFAULT_ADMIN_ROLE, newAdmin);

        // Log the transfer of the admin.
        emit IRoleAdminable.TransferAdmin({ oldAdmin: _msgSender(), newAdmin: newAdmin });
    }

    /*//////////////////////////////////////////////////////////////////////////
                             PRIVATE CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Overrides the {AccessControl-_checkRole} function to allow the admin to bypass the `role` check. This also
    /// changes the behavior of the {onlyRole} modifier.
    function _checkRole(bytes32 role) internal view override {
        // Checks: if `_msgSender()` is not the admin, it has the `role`, otherwise reverts with the
        // {AccessControlUnauthorizedAccount} error.
        if (_msgSender() != admin) {
            _checkRole(role, _msgSender());
        }
    }

    /// @dev A private function is used instead of inlining this logic in a modifier because Solidity copies modifiers
    /// into every function that uses them.
    function _onlyAdmin() private view {
        if (admin != _msgSender()) {
            revert Errors.CallerNotAdmin({ admin: admin, caller: _msgSender() });
        }
    }
}
