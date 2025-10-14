// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { LeafData } from "./MerkleBuilder.sol";

struct Users {
    // Default campaign creator.
    address payable campaignCreator;
    // Malicious user.
    address payable eve;
    // The default recipient to be used for claiming during tests.
    address payable recipient;
    // A contract recipient supporting the IERC1271 interface.
    address payable smartWalletWithIERC1271;
    // A contract recipient not supporting the IERC1271 interface.
    address payable smartWalletWithoutIERC1271;
    // Default stream sender.
    address payable sender;
    // An unknown recipient.
    address payable unknownRecipient;
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
