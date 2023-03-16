// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.13;

/// @title ISablierV2LockupSender
/// @notice Interface for sender contracts that can react to cancellations.
/// @dev Implementing this interface is entirely optional. If a sender contract does not implement this interface,
/// the function execution will not revert.
interface ISablierV2LockupSender {
    /// @notice Reacts to the cancellation of a stream. Sablier V2 invokes this function on the sender after a
    /// cancellation triggered by the recipient.
    ///
    /// @dev Notes:
    /// - This function may revert, but the Sablier contract will always ignore the revert.
    ///
    /// @param streamId The id of the stream that has been canceled.
    /// @param senderAmount The amount of assets returned to the sender, in units of the asset's decimals.
    /// @param recipientAmount The amount of assets withdrawn to the recipient, in units of the asset's decimals.
    function onStreamCanceled(uint256 streamId, uint128 senderAmount, uint128 recipientAmount) external;
}
