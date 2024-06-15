// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { Errors } from "../libraries/Errors.sol";

/// @title Batch
/// @notice This contract implements logic to batch call any function.
/// @dev Forked from: https://github.com/boringcrypto/BoringSolidity/blob/master/contracts/BoringBatchable.sol
abstract contract Batch {
    /*//////////////////////////////////////////////////////////////////////////
                         USER-FACING NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Allows batched call to self, `this` contract.
    /// @param calls An array of inputs for each call.
    function batch(bytes[] calldata calls) external {
        uint256 count = calls.length;

        for (uint256 i = 0; i < count; ++i) {
            (bool success, bytes memory result) = address(this).delegatecall(calls[i]);
            if (!success) {
                revert Errors.BatchError(result);
            }
        }
    }
}
