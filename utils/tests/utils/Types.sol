// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

struct Users {
    // User authorized for fee related actions.
    address payable accountant;
    // Impartial user.
    address payable alice;
    // A campaign creator.
    address payable campaignCreator;
    // Malicious user.
    address payable eve;
    // A stream creator.
    address payable sender;
}
