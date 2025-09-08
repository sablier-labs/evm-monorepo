// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

/// @notice Enum to represent actions performed on a stream.
/// @dev If there are multiple functions that can perform the same action, the same enum value should be associated with
/// all of them. For example, a `WITHDRAW` action should be associated with `withdraw` and `withdrawMax` functions.
enum StreamAction {
    CANCEL,
    CREATE,
    WITHDRAW
}

struct StreamIds {
    // Default stream ID.
    uint256 defaultStream;
    // A stream with a recipient contract that is not allowed to hook.
    uint256 notAllowedToHookStream;
    // A non-cancelable stream ID.
    uint256 notCancelableStream;
    // A non-transferable stream ID.
    uint256 notTransferableStream;
    // A stream ID that does not exist.
    uint256 nullStream;
    // A stream with a recipient contract that implements {ISablierLockupRecipient}.
    uint256 recipientGoodStream;
    // A stream with a recipient contract that returns invalid selector bytes on the hook call.
    uint256 recipientInvalidSelectorStream;
    // A stream with a reentrant contract as the recipient.
    uint256 recipientReentrantStream;
    // A stream with a reverting contract as the stream's recipient.
    uint256 recipientRevertStream;
}

struct Users {
    // Impartial user.
    address payable alice;
    // Malicious user.
    address payable eve;
    // Default NFT operator.
    address payable operator;
    // Default stream recipient.
    address payable recipient;
    // Default stream sender.
    address payable sender;
}
