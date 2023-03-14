// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.18;

import { ISablierV2Adminable } from "../interfaces/ISablierV2Adminable.sol";
import { Errors } from "../libraries/Errors.sol";

/// @title SablierV2Adminable
/// @notice See the documentation in {ISablierV2Adminable}.
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
                         USER-FACING NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc ISablierV2Adminable
    function transferAdmin(address newAdmin) public virtual override onlyAdmin {
        // Effects: update the admin.
        admin = newAdmin;

        // Log the transfer of the admin.
        emit ISablierV2Adminable.TransferAdmin({ oldAdmin: msg.sender, newAdmin: newAdmin });
    }
}
