// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.13;

/// @title ISablierV2LockupSender
/// @notice Interface for sender contracts capable of reacting to cancellations.
/// @dev Implementation of this interface is optional. If a sender contract doesn't implement this interface,
/// function execution won't revert.
interface ISablierV2LockupSender {
    /// @notice Responds to recipient-triggered cancellations.
    ///
    /// @dev Notes:
    /// - This function may revert, but the Sablier contract will ignore the revert.
    ///
    /// @param streamId The id of the canceled stream.
    /// @param senderAmount The amount of assets returned to the sender, denoted in units of the asset's decimals.
    /// @param recipientAmount The amount of assets withdrawn to the recipient, denoted in units of the asset's
    /// decimals.
    function onStreamCanceled(uint256 streamId, uint128 senderAmount, uint128 recipientAmount) external;
}
