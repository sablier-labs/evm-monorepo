// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

/// @notice This contract implements logic to batch call any function.
interface IBatch {
    /// @notice Allows batched calls to self, i.e., `this` contract.
    /// @dev Since `msg.value` can be reused across calls, be VERY CAREFUL when using it. Refer to
    /// https://paradigm.xyz/2021/08/two-rights-might-make-a-wrong for more information.
    /// @param calls An array of inputs for each call.
    /// @return results An array of results from each call. Empty when the calls do not return anything.
    function batch(bytes[] calldata calls) external payable returns (bytes[] memory results);
}
