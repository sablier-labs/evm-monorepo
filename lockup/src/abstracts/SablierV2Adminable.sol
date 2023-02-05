// SPDX-License-Identifier: MIT
pragma solidity >=0.8.18;

import { ISablierV2Adminable } from "../interfaces/ISablierV2Adminable.sol";
import { Errors } from "../libraries/Errors.sol";
import { Events } from "../libraries/Events.sol";

/// @title SablierV2Adminable
/// @dev Abstract contract that implements the {ISablierV2Adminable} interface.
abstract contract SablierV2Adminable is ISablierV2Adminable {
    /*//////////////////////////////////////////////////////////////////////////
                                       STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2Adminable
    address public override admin;

    /*//////////////////////////////////////////////////////////////////////////
                                      MODIFIERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Reverts if called by any account other than the admin.
    modifier onlyAdmin() {
        if (admin != msg.sender) {
            revert Errors.SablierV2Adminable_CallerNotAdmin({ admin: admin, caller: msg.sender });
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////////////////
                           PUBLIC NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2Adminable
    function transferAdmin(address newAdmin) public virtual override onlyAdmin {
        // Load the current admin in memory.
        address oldAdmin = admin;

        // Effects: update the admin.
        admin = newAdmin;

        // Log the transfer of the admin.
        emit Events.TransferAdmin(oldAdmin, newAdmin);
    }
}
