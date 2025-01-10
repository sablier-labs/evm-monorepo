// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { ISablierFees } from "./interfaces/ISablierFees.sol";
import { Errors } from "./libraries/Errors.sol";

import { Adminable } from "./Adminable.sol";

/// @title SablierFees
/// @notice See the documentation in {ISablierFees}.
abstract contract SablierFees is Adminable, ISablierFees {
    constructor(address initialAdmin) Adminable(initialAdmin) { }

    /// @inheritdoc ISablierFees
    function collectFees() external override {
        uint256 feeAmount = address(this).balance;

        // Effect: transfer the fees to the admin.
        (bool success,) = admin.call{ value: feeAmount }("");

        // Revert if the call failed.
        if (!success) {
            revert Errors.SablierFees_FeeTransferFail(admin, feeAmount);
        }

        // Log the fee withdrawal.
        emit ISablierFees.CollectFees({ admin: admin, feeAmount: feeAmount });
    }
}
