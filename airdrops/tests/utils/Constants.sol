// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { uUNIT } from "@prb/math/src/UD2x18.sol";
import { UD60x18, ud60x18 } from "@prb/math/src/UD60x18.sol";
import { ud } from "@prb/math/src/UD60x18.sol";

abstract contract Constants {
    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    // Amounts
    uint128 public constant AGGREGATE_AMOUNT = CLAIM_AMOUNT * uint128(RECIPIENT_COUNT);
    uint128 public constant CLAIM_AMOUNT = 10_000e18;
    uint128 public constant CLIFF_AMOUNT = (CLAIM_AMOUNT * VESTING_CLIFF_DURATION) / VESTING_TOTAL_DURATION;
    uint128 public constant UNLOCK_START_AMOUNT = 100e18;
    uint128 public constant VCA_FULL_AMOUNT = CLAIM_AMOUNT;

    // Durations and Timestamps
    uint40 public constant EXPIRATION = FEB_1_2025 + 12 weeks;
    uint40 public constant CAMPAIGN_START_TIME = FEB_1_2025;
    uint40 public constant FIRST_CLAIM_TIME = FEB_1_2025;
    uint40 public constant VALID_FROM = FEB_1_2025;
    uint40 public constant VESTING_CLIFF_DURATION = 2 days;
    uint40 public constant VESTING_END_TIME = VESTING_START_TIME + VESTING_TOTAL_DURATION;
    uint40 public constant VESTING_GRANULARITY = 1 seconds;
    uint40 public constant VESTING_START_TIME = FEB_1_2025 - 2 days;
    uint40 public constant VESTING_TOTAL_DURATION = 10 days;
    uint40 public constant VCA_END_TIME = VESTING_END_TIME;
    uint40 public constant VCA_START_TIME = VESTING_START_TIME;

    // Global
    uint40 public constant FEB_1_2025 = 1_738_368_000;
    uint64 public constant TRANCHES_TOTAL_PERCENTAGE = uUNIT;

    // Merkle Campaigns
    string public CAMPAIGN_NAME = "Airdrop Campaign";
    uint256 public constant INDEX1 = 1;
    uint256 public constant INDEX2 = 2;
    uint256 public constant INDEX3 = 3;
    uint256 public constant INDEX4 = 4;
    string public constant IPFS_CID = "QmbWqxBEKC3P8tqsKc98xmWNzrzDtRLMiMPL8wBuTGsMnR";
    uint256[] public LEAVES = new uint256[](RECIPIENT_COUNT);
    uint256 public constant RECIPIENT_COUNT = 4;
    bytes32 public MERKLE_ROOT;
    bool public constant STREAM_CANCELABLE = false;
    string public STREAM_SHAPE = "A custom stream shape";
    bool public constant STREAM_TRANSFERABLE = false;

    // EIP-712
    string public constant PROTOCOL_NAME = "Sablier Airdrops Protocol";
    string public constant SCHEMA_CLAIM =
        "Claim(uint256 index,address recipient,address to,uint128 amount,uint40 validFrom)";
    string public constant SCHEMA_EIP712_DOMAIN = "EIP712Domain(string name,uint256 chainId,address verifyingContract)";
    string public constant SCHEMA_IDENTITY = "Identity(address recipient,uint40 expireAt)";

    /*//////////////////////////////////////////////////////////////////////////
                                     IMMUTABLES
    //////////////////////////////////////////////////////////////////////////*/

    UD60x18 public immutable VESTING_CLIFF_UNLOCK_PERCENTAGE = ud(CLIFF_AMOUNT).div(ud(CLAIM_AMOUNT));
    UD60x18 public immutable VESTING_START_UNLOCK_PERCENTAGE = ud(UNLOCK_START_AMOUNT).div(ud(CLAIM_AMOUNT));
    uint128 public immutable VCA_VESTING_AMOUNT = CLAIM_AMOUNT - UNLOCK_START_AMOUNT;
    uint128 public immutable VCA_UNLOCK_AMOUNT = UNLOCK_START_AMOUNT; // 1% of full amount.
    uint128 public immutable VCA_CLAIM_AMOUNT =
        VCA_UNLOCK_AMOUNT + (VCA_VESTING_AMOUNT * 2 days) / VESTING_TOTAL_DURATION; // 2080e18

    // Reward amount per user if one user claims at campaign start time, and the remaining 3 users claim after vesting
    // end time.
    uint128 public immutable VCA_REWARD_AMOUNT_PER_USER =
        (VCA_FULL_AMOUNT - VCA_CLAIM_AMOUNT) / (uint128(RECIPIENT_COUNT) - 1); // 2640e18
    UD60x18 public immutable VCA_UNLOCK_PERCENTAGE = ud60x18(0.01e18); // 1%.
}
