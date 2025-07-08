// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { ISablierComptroller } from "./ISablierComptroller.sol";

/// @title IComptrollerable
/// @notice Contract module that provides a setter and getter for the Sablier Comptroller.
interface IComptrollerable {
    /*//////////////////////////////////////////////////////////////////////////
                                       EVENTS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Emitted when the comptroller address is set by the admin.
    event SetComptroller(ISablierComptroller newComptroller, ISablierComptroller oldComptroller);

    /// @notice Emitted when the fees are transferred to the comptroller contract.
    event TransferFeesToComptroller(ISablierComptroller indexed comptroller, uint256 feeAmount);

    /*//////////////////////////////////////////////////////////////////////////
                                READ-ONLY FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Retrieves the address of the comptroller contract.
    function comptroller() external view returns (ISablierComptroller);

    /*//////////////////////////////////////////////////////////////////////////
                              STATE-CHANGING FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Sets the comptroller to a new address.
    /// @dev Emits a {SetComptroller} event.
    ///
    /// Requirements:
    /// - `msg.sender` must be the current comptroller.
    ///
    /// @param newComptroller The address of the new comptroller contract.
    function setComptroller(ISablierComptroller newComptroller) external;

    /// @notice Transfers the fees to the comptroller contract.
    /// @dev Emits a {TransferFeesToComptroller} event.
    function transferFeesToComptroller() external;
}
