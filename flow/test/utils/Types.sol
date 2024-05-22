// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

struct Users {
    // Default stream broker.
    address payable broker;
    // Malicious user.
    address payable eve;
    // Default stream recipient.
    address payable recipient;
    // Default stream sender.
    address payable sender;
}
