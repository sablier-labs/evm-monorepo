// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IBatch } from "./interfaces/IBatch.sol";
import { Errors } from "./libraries/Errors.sol";

/// @title Batch
/// @notice See the documentation in {IBatch}.
/// @dev Forked from: https://github.com/boringcrypto/BoringSolidity/blob/master/contracts/BoringBatchable.sol
abstract contract Batch is IBatch {
    /*//////////////////////////////////////////////////////////////////////////
                         USER-FACING NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IBatch
    function batch(bytes[] calldata calls) external override {
        uint256 count = calls.length;

        for (uint256 i = 0; i < count; ++i) {
            (bool success, bytes memory result) = address(this).delegatecall(calls[i]);
            if (!success) {
                revert Errors.BatchError(result);
            }
        }
    }
}
