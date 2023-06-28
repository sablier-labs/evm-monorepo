// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.19;

/// @title ISablierV2LockupSender
/// @notice Interface for sender contracts capable of reacting to cancellations.
/// @dev Implementation of this interface is optional. If a sender contract doesn't implement this interface,
/// function execution will not revert.
interface ISablierV2LockupSender {
    /// @notice Responds to recipient-triggered cancellations.
    ///
    /// @dev Notes:
    /// - This function may revert, but the Sablier contract will ignore the revert.
    ///
    /// @param streamId The id of the canceled stream.
    /// @param recipient The stream's recipient, who canceled the stream.
    /// @param senderAmount The amount of assets refunded to the stream's sender, denoted in units of the asset's
    /// decimals.
    /// @param recipientAmount The amount of assets left for the stream's recipient to withdraw, denoted in units of the
    /// asset's decimals.
    function onStreamCanceled(
        uint256 streamId,
        address recipient,
        uint128 senderAmount,
        uint128 recipientAmount
    )
        external;
}
