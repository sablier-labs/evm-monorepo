// SPDX-License-Identifier: GPL-3.0-or-later
// solhint-disable no-inline-assembly
pragma solidity >=0.8.22;

import { IBatch } from "../interfaces/IBatch.sol";

/// @title Batch
/// @notice See the documentation in {IBatch}.
abstract contract Batch is IBatch {
    /*//////////////////////////////////////////////////////////////////////////
                         USER-FACING NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @inheritdoc IBatch
    /// @dev Since `msg.value` can be reused across calls, be VERY CAREFUL when using it. Refer to
    /// https://paradigm.xyz/2021/08/two-rights-might-make-a-wrong for more information.
    function batch(bytes[] calldata calls) external payable override returns (bytes[] memory results) {
        uint256 count = calls.length;
        results = new bytes[](count);

        for (uint256 i = 0; i < count; ++i) {
            (bool success, bytes memory result) = address(this).delegatecall(calls[i]);

            // Check: If the delegatecall failed, load and bubble up the revert data.
            if (!success) {
                assembly {
                    // Get the length of the result stored in the first 32 bytes.
                    let resultSize := mload(result)

                    // Forward the pointer by 32 bytes to skip the length argument, and revert with the result.
                    revert(add(32, result), resultSize)
                }
            }

            // Push the result into the results array.
            results[i] = result;
        }
    }
}
