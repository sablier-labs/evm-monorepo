// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

/// @title Errors
/// @notice Library with custom errors used across the contracts.
library Errors {
    /*//////////////////////////////////////////////////////////////////////////
                                      GENERICS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when `msg.sender` is not the admin.
    error CallerNotAdmin(address admin, address caller);

    /// @notice Thrown when trying to delegate call to a function that disallows delegate calls.
    error DelegateCall();

    /*//////////////////////////////////////////////////////////////////////////
                                    ROLE-ADMINABLE
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Thrown when trying to grant role to an `account` that already has the `role`.
    error AccountAlreadyHasRole(bytes32 role, address account);

    /// @notice Thrown when trying to revoke role from an `account` that does not have the `role`.
    error AccountDoesNotHaveRole(bytes32 role, address account);

    /// @notice Thrown if `caller` is missing the `neededRole` and is not the admin.
    error UnauthorizedAccess(address caller, bytes32 neededRole);
}
