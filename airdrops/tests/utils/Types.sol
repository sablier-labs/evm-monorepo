// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { LeafData } from "./MerkleBuilder.sol";

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

/// @dev Struct to hold the common parameters needed for fuzz tests.
struct Params {
    uint128 clawbackAmount;
    bool enableCustomFeeUSD;
    uint40 expiration;
    uint256 feeForUser;
    uint256[] indexesToClaim;
    uint256 msgValue;
    LeafData[] rawLeavesData;
    address to;
}
