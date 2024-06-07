// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { UD60x18 } from "@prb/math/src/UD60x18.sol";

abstract contract Constants {
    // Broker
    UD60x18 internal constant BROKER_FEE = UD60x18.wrap(0.01e18); // 1%
    uint128 internal constant BROKER_FEE_AMOUNT = 505.050505050505050505e18; // 1% of total amount
    uint128 internal constant BROKER_FEE_AMOUNT_6D = 505.050505e6; // 1% of total amount
    UD60x18 internal constant MAX_BROKER_FEE = UD60x18.wrap(0.1e18); // 10%

    // Amounts
    uint128 internal constant DEPOSIT_AMOUNT = TRANSFER_AMOUNT;
    uint128 internal constant REFUND_AMOUNT = 10_000e18;
    uint128 internal constant TRANSFER_VALUE = 50_000;
    uint128 internal constant TRANSFER_AMOUNT = TRANSFER_VALUE * 1e18;
    uint128 internal constant TRANSFER_AMOUNT_6D = TRANSFER_VALUE * 1e6;
    uint128 internal constant TOTAL_TRANSFER_AMOUNT_WITH_BROKER_FEE = TRANSFER_AMOUNT + BROKER_FEE_AMOUNT;
    uint128 internal constant TOTAL_TRANSFER_AMOUNT_WITH_BROKER_FEE_6D = TRANSFER_AMOUNT_6D + BROKER_FEE_AMOUNT_6D;
    uint128 internal constant WITHDRAW_AMOUNT = 2500e18;

    // Transferability and rate
    bool internal constant IS_TRANFERABLE = true;
    uint128 internal constant RATE_PER_SECOND = 0.001e18; // 86.4 daily

    // Time
    uint40 internal constant MAY_1_2024 = 1_714_518_000;
    uint40 internal immutable ONE_MONTH = 30 days; // "30/360" convention
    uint128 internal constant SOLVENCY_PERIOD = DEPOSIT_AMOUNT / RATE_PER_SECOND; // 578 days
    uint40 internal immutable WARP_ONE_MONTH = MAY_1_2024 + ONE_MONTH;
    uint40 internal immutable WITHDRAW_TIME = MAY_1_2024 + 2_500_000;

    // Streaming amounts
    uint128 internal constant ONE_MONTH_STREAMED_AMOUNT = 2592e18; // 86.4 * 30
    uint128 internal constant ONE_MONTH_REFUNDABLE_AMOUNT = DEPOSIT_AMOUNT - ONE_MONTH_STREAMED_AMOUNT;

    // Max value
    uint128 internal constant UINT128_MAX = type(uint128).max;
}
