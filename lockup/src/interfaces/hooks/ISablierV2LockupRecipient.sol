// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.18;

/// @title ISablierV2LockupRecipient
/// @notice Interface for Sablier V2 recipient contracts that can react to cancellations and withdrawals.
/// @dev Implementing this interface is entirely optional. If the recipient contract does not implement this interface,
/// the function execution will not revert. Furthermore, if the recipient contract implements this interface only
/// partially, the function execution will not revert either.
interface ISablierV2LockupRecipient {
    /// @notice Reacts to the cancellation of a stream. Sablier V2 invokes this function on the recipient
    /// after a cancellation triggered by the sender.
    ///
    /// @dev Notes:
    /// - This function may revert, but the {SablierV2Lockup} contract will always ignore the revert.
    ///
    /// @param streamId The id of the stream that has been canceled.
    /// @param senderAmount The amount of assets returned to the sender, in units of the asset's decimals.
    /// @param recipientAmount The amount of assets withdrawn to the recipient, in units of the asset's decimals.
    function onStreamCanceled(uint256 streamId, uint128 senderAmount, uint128 recipientAmount) external;

    /// @notice Reacts to the renouncement of a stream. Sablier V2 invokes this function on the recipient
    /// after a renouncement triggered by the sender.
    ///
    /// @dev Notes:
    /// - This function may revert, but the {SablierV2Lockup} contract will always ignore the revert.
    ///
    /// @param streamId The id of the stream that has been renounced.
    function onStreamRenounced(uint256 streamId) external;

    /// @notice Reacts to a withdrawal from a stream.
    /// @dev Sablier V2 invokes this function on the recipient after a withdrawal triggered by the sender or
    /// an approved operator.
    /// This function may revert, but the {SablierV2Lockup} contract will always ignore the revert.
    /// @param streamId The id of the stream that has been withdrawn from.
    /// @param caller The address of the original `msg.sender` address which triggered the cancellation.
    /// @param to The address that has received the withdrawn assets.
    /// @param amount The amount of assets that have been withdrawn, in units of the asset's decimals.
    function onStreamWithdrawn(uint256 streamId, address caller, address to, uint128 amount) external;
}
