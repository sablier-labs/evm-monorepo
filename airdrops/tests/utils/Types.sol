// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

struct Users {
    // User authorized for fee related actions.
    address payable accountant;
    // Default admin.
    address payable admin;
    // Default campaign creator.
    address payable campaignCreator;
    // Malicious user.
    address payable eve;
    // Default stream recipient.
    address payable recipient;
    // Other recipients.
    address payable recipient1;
    address payable recipient2;
    address payable recipient3;
    address payable recipient4;
    // Default stream sender.
    address payable sender;
}
