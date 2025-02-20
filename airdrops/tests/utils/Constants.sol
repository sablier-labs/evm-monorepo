// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { UD2x18, uUNIT } from "@prb/math/src/UD2x18.sol";
import { ud } from "@prb/math/src/UD60x18.sol";

abstract contract Constants {
    // Amounts
    uint256 public constant AGGREGATE_AMOUNT = CLAIM_AMOUNT * RECIPIENT_COUNT;
    uint128 public constant CLAIM_AMOUNT = 10_000e18;
    uint128 public constant CLIFF_AMOUNT = (CLAIM_AMOUNT * CLIFF_DURATION) / TOTAL_DURATION;
    UD2x18 public immutable CLIFF_PERCENTAGE = (ud(CLIFF_AMOUNT).div(ud(CLAIM_AMOUNT)).intoUD2x18());
    uint256 public constant MINIMUM_FEE = 0.005e18;
    uint128 public constant START_AMOUNT = 100e18;
    UD2x18 public immutable START_PERCENTAGE = (ud(START_AMOUNT).div(ud(CLAIM_AMOUNT)).intoUD2x18());

    // Durations and Timestamps
    uint40 public constant CLIFF_DURATION = 2 days;
    uint40 public immutable EXPIRATION = JULY_1_2024 + 12 weeks;
    uint40 public constant FIRST_CLAIM_TIME = JULY_1_2024;
    uint40 public immutable RANGED_STREAM_START_TIME = JULY_1_2024 - 2 days;
    uint40 public immutable RANGED_STREAM_END_TIME = RANGED_STREAM_START_TIME + TOTAL_DURATION;
    uint40 public constant TOTAL_DURATION = 10 days;

    // Merkle Campaigns
    string public CAMPAIGN_NAME = "Airdrop Campaign";
    bool public constant CANCELABLE = false;
    uint256 public constant INDEX1 = 1;
    uint256 public constant INDEX2 = 2;
    uint256 public constant INDEX3 = 3;
    uint256 public constant INDEX4 = 4;
    string public constant IPFS_CID = "QmbWqxBEKC3P8tqsKc98xmWNzrzDtRLMiMPL8wBuTGsMnR";
    uint256[] public LEAVES = new uint256[](RECIPIENT_COUNT);
    uint256 public constant RECIPIENT_COUNT = 4;
    bytes32 public MERKLE_ROOT;
    string public SHAPE = "A custom stream shape";
    bool public constant TRANSFERABLE = false;

    // Global
    uint40 internal constant JULY_1_2024 = 1_719_792_000;
    uint128 internal constant MAX_UINT128 = type(uint128).max;
    uint256 internal constant MAX_UINT256 = type(uint256).max;
    uint40 internal constant MAX_UNIX_TIMESTAMP = 2_147_483_647; // 2^31 - 1
    uint64 public constant TOTAL_PERCENTAGE = uUNIT;
    uint40 internal constant ZERO = 0;
}
