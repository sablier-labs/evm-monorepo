// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.18;

/// @title ISablierV2Adminable
/// @notice Contract module that provides a basic access control mechanism, with an admin that can be
/// granted exclusive access to specific functions. The inheriting contract must set the admin in the
/// constructor.
interface ISablierV2Adminable {
    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice The address of the admin account or contract.
    function admin() external view returns (address);

    /*//////////////////////////////////////////////////////////////////////////
                               NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Transfers the admin of the contract to a new address.
    ///
    /// Notes:
    /// - Does not revert if the admin is the same.
    /// - This function can potentially leave the contract without an admin, thereby removing any
    /// functionality that is only available to the admin.
    ///
    /// Requirements:
    /// - The caller must be the current contract admin.
    ///
    /// @param newAdmin The address of the new admin.
    function transferAdmin(address newAdmin) external;
}
