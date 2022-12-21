// SPDX-License-Identifier: LGPL-3.0
pragma solidity >=0.8.13;

/// @title ISablierV2Recipient
/// @notice Interface for Sablier V2 recipient contracts that can react to cancellations and withdrawals.
/// @dev Implementing this interface is entirely optional. If a recipient contract does not implement this interface,
/// the function execution will not revert.
interface ISablierV2Recipient {
    /// @notice Reacts to the cancellation of a stream. Sablier V2 invokes this function on the recipient
    /// after a cancellation triggered by the sender or an approved operator.
    ///
    /// @dev Notes:
    /// - This function may revert, but Sablier V2 will always ignore the revert.
    ///
    /// @param streamId The id of the stream that was canceled.
    /// @param caller The address of the original `msg.sender` address that triggered the cancellation.
    /// @param withdrawAmount The amount of tokens withdrawn to the recipient, in units of the token's decimals.
    /// @param returnAmount The amount of tokens returned to the sender, in units of the token's decimals.
    function onStreamCanceled(uint256 streamId, address caller, uint128 withdrawAmount, uint128 returnAmount) external;

    /// @notice Reacts to a withdrawal from a stream.
    /// @dev Sablier V2 invokes this function on the recipient after a withdrawal triggered by the sender or
    /// an approved operator.
    /// This function may revert, but Sablier V2 will always ignore the revert.
    /// @param streamId The id of the stream that was canceled.
    /// @param caller The address of the original `msg.sender` address that triggered the cancellation.
    /// @param withdrawAmount The amount of tokens that were withdrawn, in units of the token's decimals.
    function onStreamWithdrawn(uint256 streamId, address caller, uint128 withdrawAmount) external;
}
