// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.13;

/// @title ISablierV2Adminable
/// @notice Contract module that provides a basic access control mechanism, with an admin that can be
/// granted exclusive access to specific functions. The inheriting contract must set the admin in the
/// constructor.
interface ISablierV2Adminable {
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
    /// - The caller must be the contract admin.
    ///
    /// @param newAdmin The address of the new admin.
    function transferAdmin(address newAdmin) external;
}
