// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

abstract contract Constants {
    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    uint64 public constant BATCH_SIZE = 10;
    uint128 public constant CLIFF_AMOUNT = 2500e18 + 2534;
    uint128 public constant CLIFF_AMOUNT_6D = CLIFF_AMOUNT / 1e12;
    uint40 public constant CLIFF_DURATION = 2500 seconds;
    uint40 public constant CLIFF_TIME = START_TIME + CLIFF_DURATION;
    uint128 public constant DEPOSIT_AMOUNT = 10_000e18;
    uint128 public constant DEPOSIT_AMOUNT_6D = 10_000e6;
    uint40 public constant END_TIME = START_TIME + TOTAL_DURATION;
    uint40 public constant FEB_1_2025 = 1_738_368_000;
    uint128 public constant REFUND_AMOUNT = DEPOSIT_AMOUNT - WITHDRAW_AMOUNT;
    uint256 public constant SEGMENT_COUNT = 2;
    string public constant SHAPE = "emits in the event";
    uint128 public constant START_AMOUNT = 0;
    uint40 public constant START_TIME = FEB_1_2025 + 2 days;
    uint128 public constant STREAMED_AMOUNT_26_PERCENT = 2600e18;
    uint40 public constant TOTAL_DURATION = 10_000 seconds;
    uint128 public constant TOTAL_TRANSFER_AMOUNT = DEPOSIT_AMOUNT * uint128(BATCH_SIZE);
    uint256 public constant TRANCHE_COUNT = 2;
    uint40 public constant WARP_26_PERCENT = START_TIME + WARP_26_PERCENT_DURATION;
    uint40 public constant WARP_26_PERCENT_DURATION = 2600 seconds; // 26% of the way through the stream
    uint128 public constant WITHDRAW_AMOUNT = STREAMED_AMOUNT_26_PERCENT;
}
