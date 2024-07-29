// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

struct Users {
    // Default admin for all contracts.
    address payable admin;
    // Impartial user.
    address payable alice;
    // Default stream broker.
    address payable broker;
    // Malicious user.
    address payable eve;
    // Default NFT operator.
    address payable operator;
    // Default stream recipients.
    address payable recipient0;
    address payable recipient1;
    address payable recipient2;
    address payable recipient3;
    address payable recipient4;
    // Default stream sender.
    address payable sender;
}
