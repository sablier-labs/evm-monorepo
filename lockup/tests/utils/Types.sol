// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

struct StreamIds {
    // Default stream ID.
    uint256 defaultStream;
    // A stream with a recipient contract that is not allowed to hook.
    uint256 notAllowedtoHookStream;
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
    // User authorized for fee related actions.
    address payable accountant;
    // Default admin.
    address payable admin;
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
