// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { UD21x18 } from "@prb/math/src/UD21x18.sol";
import { UD60x18 } from "@prb/math/src/UD60x18.sol";

abstract contract Constants {
    // Amounts
    uint128 internal constant DEPOSIT_AMOUNT_18D = 50_000e18;
    uint128 internal constant DEPOSIT_AMOUNT_6D = 50_000e6;
    uint128 internal constant REFUND_AMOUNT_18D = 10_000e18;
    uint128 internal constant REFUND_AMOUNT_6D = 10_000e6;
    uint128 internal constant TRANSFER_VALUE = 50_000;
    uint128 internal constant TOTAL_AMOUNT_WITH_BROKER_FEE_6D = DEPOSIT_AMOUNT_6D + BROKER_FEE_AMOUNT_6D;
    uint128 internal constant TOTAL_AMOUNT_WITH_BROKER_FEE_18D = DEPOSIT_AMOUNT_18D + BROKER_FEE_AMOUNT_18D;
    uint128 internal constant WITHDRAW_AMOUNT_6D = 2500e6;
    uint128 internal constant WITHDRAW_AMOUNT_18D = 2500e18;

    // Broker
    UD60x18 internal constant BROKER_FEE = UD60x18.wrap(0.01e18); // 1%
    uint128 internal constant BROKER_FEE_AMOUNT_18D = 505.050505050505050505e18; // 1% of total amount
    uint128 internal constant BROKER_FEE_AMOUNT_6D = 505.050505e6; // 1% of total amount
    UD60x18 internal constant MAX_BROKER_FEE = UD60x18.wrap(0.1e18); // 10%

    // Max value
    uint128 internal constant UINT128_MAX = type(uint128).max;
    uint40 internal constant UINT40_MAX = type(uint40).max;

    // Time
    uint40 internal constant MAY_1_2024 = 1_714_518_000;
    uint40 internal constant ONE_MONTH = 30 days; // "30/360" convention
    uint40 internal constant SOLVENCY_PERIOD = uint40(DEPOSIT_AMOUNT_18D / RATE_PER_SECOND_U128); // 578 days
    uint40 internal constant WARP_ONE_MONTH = MAY_1_2024 + ONE_MONTH;
    uint40 internal constant WARP_SOLVENCY_PERIOD = MAY_1_2024 + SOLVENCY_PERIOD;
    uint40 internal constant WITHDRAW_TIME = MAY_1_2024 + 2_500_000;

    // Streaming amounts
    uint128 internal constant ONE_MONTH_DEBT_6D = 2592e6; // 86.4 * 30
    uint128 internal constant ONE_MONTH_REFUNDABLE_AMOUNT_6D = DEPOSIT_AMOUNT_6D - ONE_MONTH_DEBT_6D;

    // Misc
    uint8 internal constant DECIMALS = 6;
    bool internal constant TRANSFERABLE = true;
    UD21x18 internal constant RATE_PER_SECOND = UD21x18.wrap(0.001e18); // 86.4 daily
    uint128 internal constant RATE_PER_SECOND_U128 = 0.001e18; // 86.4 daily
}
