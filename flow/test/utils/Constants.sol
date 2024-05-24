// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { UD60x18 } from "@prb/math/src/UD60x18.sol";

abstract contract Constants {
    UD60x18 public constant BROKER_FEE = UD60x18.wrap(0.01e18); // 1%
    uint128 public constant BROKER_FEE_AMOUNT = 505.050505050505050505e18; // 1% of total amount
    uint128 public constant DEPOSIT_AMOUNT = 50_000e18;
    uint128 public constant DEPOSIT_AMOUNT_WITH_BROKER_FEE = 50_505.050505050505050505e18; // deposit + broker fee
    bool public constant IS_TRANFERABLE = true;
    UD60x18 internal constant MAX_BROKER_FEE = UD60x18.wrap(0.1e18); // 10%
    uint40 internal constant MAY_1_2024 = 1_714_518_000;
    uint40 public immutable ONE_MONTH = 30 days; // "30/360" convention
    uint128 public constant ONE_MONTH_STREAMED_AMOUNT = 2592e18; // 86.4 * 30
    uint128 public constant ONE_MONTH_REFUNDABLE_AMOUNT = DEPOSIT_AMOUNT - ONE_MONTH_STREAMED_AMOUNT;
    uint128 public constant RATE_PER_SECOND = 0.001e18; // 86.4 daily
    uint128 public constant REFUND_AMOUNT = 10_000e18;
    uint128 public constant SOLVENCY_PERIOD = DEPOSIT_AMOUNT / RATE_PER_SECOND;
    uint40 public immutable WARP_ONE_MONTH = MAY_1_2024 + ONE_MONTH;
    uint128 public constant WITHDRAW_AMOUNT = 2500e18;
    uint40 public immutable WITHDRAW_TIME = MAY_1_2024 + 2_500_000;
}
