// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { UD21x18 } from "@prb/math/src/UD21x18.sol";
import { CommonConstants } from "@sablier/evm-utils/tests/utils/Constants.sol";

abstract contract Constants is CommonConstants {
    // Amounts
    uint128 internal constant DEPOSIT_AMOUNT_18D = 50_000e18;
    uint128 internal constant DEPOSIT_AMOUNT_6D = 50_000e6;

    uint128 internal constant REFUND_AMOUNT_18D = 10_000e18;
    uint128 internal constant REFUND_AMOUNT_6D = 10_000e6;
    uint128 internal constant TRANSFER_VALUE = 50_000;
    uint128 internal constant WITHDRAW_AMOUNT_18D = 500e18;
    uint128 internal constant WITHDRAW_AMOUNT_6D = 500e6;

    // Misc
    uint8 internal constant DECIMALS = 6;
    UD21x18 internal constant RATE_PER_SECOND = UD21x18.wrap(0.001e18); // 86.4 daily
    uint128 internal constant RATE_PER_SECOND_U128 = 0.001e18; // 86.4 daily
    uint256 internal constant SCALE_FACTOR = 10 ** 12;
    bool internal constant TRANSFERABLE = true;
    uint40 internal constant ZERO = 0;

    // Streaming amounts
    uint128 internal constant ONE_MONTH_DEBT_6D = 2592e6; // 86.4 * 30
    uint128 internal constant ONE_MONTH_DEBT_18D = 2592e18; // 86.4 * 30
    uint128 internal constant ONE_MONTH_REFUNDABLE_AMOUNT_6D = DEPOSIT_AMOUNT_6D - ONE_MONTH_DEBT_6D;

    // Time
    uint40 internal constant FEB_1_2025 = 1_738_368_000;
    uint40 internal constant ONE_MONTH = 30 days; // "30/360" convention
    uint40 internal constant ONE_MONTH_SINCE_CREATE = FEB_1_2025 + ONE_MONTH;
    // Solvency period is 49999999.999999 seconds.
    uint40 internal constant SOLVENCY_PERIOD = uint40(DEPOSIT_AMOUNT_18D / RATE_PER_SECOND_U128); // ~578 days
    // The following variable represents the timestamp at which the stream depletes all its balance.
    uint40 internal constant WARP_SOLVENCY_PERIOD = FEB_1_2025 + SOLVENCY_PERIOD;
    uint40 internal constant WITHDRAW_TIME = FEB_1_2025 + 2_500_000;
}
