// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { UD2x18, ud2x18 } from "@prb/math/UD2x18.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";

import { CreateLockupAmounts, Durations, LockupAmounts, Range, Segment } from "src/types/Structs.sol";

abstract contract Constants {
    /*//////////////////////////////////////////////////////////////////////////
                                  SIMPLE CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    uint128 internal constant DEFAULT_BROKER_FEE_AMOUNT = 30.120481927710843373e18; // 0.3% of gross deposit
    uint40 internal immutable DEFAULT_CLIFF_TIME;
    uint40 internal constant DEFAULT_CLIFF_DURATION = 2_500 seconds;
    uint128 internal constant DEFAULT_GROSS_DEPOSIT_AMOUNT = 10_040.160642570281124497e18; // net deposit / (1 - fee)
    uint40 internal immutable DEFAULT_END_TIME;
    UD60x18 internal constant DEFAULT_FLASH_FEE = UD60x18.wrap(0.0005e18); // 0.05%
    UD60x18 internal constant DEFAULT_MAX_FEE = UD60x18.wrap(0.1e18); // 10%
    uint256 internal constant DEFAULT_MAX_SEGMENT_COUNT = 1_000;
    uint128 internal constant DEFAULT_NET_DEPOSIT_AMOUNT = 10_000e18;
    UD60x18 internal constant DEFAULT_BROKER_FEE = UD60x18.wrap(0.003e18); // 0.3%
    UD60x18 internal constant DEFAULT_PROTOCOL_FEE = UD60x18.wrap(0.001e18); // 0.1%
    uint128 internal constant DEFAULT_PROTOCOL_FEE_AMOUNT = 10.040160642570281124e18; // 0.1% of gross deposit
    uint40 internal immutable DEFAULT_START_TIME;
    uint40 internal constant DEFAULT_TIME_WARP = 2_600 seconds;
    uint40 internal constant DEFAULT_TOTAL_DURATION = 10_000 seconds;
    uint128 internal constant DEFAULT_WITHDRAW_AMOUNT = 2_600e18;
    bytes32 internal constant FLASH_LOAN_CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");
    uint128 internal constant UINT128_MAX = type(uint128).max;
    uint256 internal constant UINT256_MAX = type(uint256).max;
    uint40 internal constant UINT40_MAX = type(uint40).max;

    /*//////////////////////////////////////////////////////////////////////////
                                 COMPLEX CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    CreateLockupAmounts internal DEFAULT_LOCKUP_CREATE_AMOUNTS =
        CreateLockupAmounts({
            netDeposit: DEFAULT_NET_DEPOSIT_AMOUNT,
            protocolFee: DEFAULT_PROTOCOL_FEE_AMOUNT,
            brokerFee: DEFAULT_BROKER_FEE_AMOUNT
        });
    LockupAmounts internal DEFAULT_LOCKUP_AMOUNTS =
        LockupAmounts({ deposit: DEFAULT_NET_DEPOSIT_AMOUNT, withdrawn: 0 });
    Durations internal DEFAULT_DURATIONS = Durations({ cliff: DEFAULT_CLIFF_DURATION, total: DEFAULT_TOTAL_DURATION });
    Range internal DEFAULT_RANGE;
    Segment[] internal DEFAULT_SEGMENTS;
    Segment[] internal MAX_SEGMENTS;
    uint40[] internal DEFAULT_SEGMENT_DELTAS = [2_500 seconds, 7_500 seconds];

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor() {
        DEFAULT_START_TIME = uint40(block.timestamp);
        DEFAULT_CLIFF_TIME = DEFAULT_START_TIME + DEFAULT_CLIFF_DURATION;
        DEFAULT_END_TIME = DEFAULT_START_TIME + DEFAULT_TOTAL_DURATION;
        DEFAULT_RANGE = Range({ start: DEFAULT_START_TIME, cliff: DEFAULT_CLIFF_TIME, end: DEFAULT_END_TIME });

        DEFAULT_SEGMENTS.push(
            Segment({
                amount: 2_500e18,
                exponent: ud2x18(3.14e18),
                milestone: DEFAULT_START_TIME + DEFAULT_CLIFF_DURATION
            })
        );
        DEFAULT_SEGMENTS.push(
            Segment({
                amount: 7_500e18,
                exponent: ud2x18(0.5e18),
                milestone: DEFAULT_START_TIME + DEFAULT_TOTAL_DURATION
            })
        );

        unchecked {
            uint128 amount = DEFAULT_NET_DEPOSIT_AMOUNT / uint128(DEFAULT_MAX_SEGMENT_COUNT);
            UD2x18 exponent = ud2x18(2.71e18);
            uint40 duration = DEFAULT_TOTAL_DURATION / uint40(DEFAULT_MAX_SEGMENT_COUNT);

            // Generate a bunch of segments with the same amount, same exponent, and with milestones
            // evenly spread apart.
            for (uint40 i = 0; i < DEFAULT_MAX_SEGMENT_COUNT; ++i) {
                MAX_SEGMENTS.push(
                    Segment({ amount: amount, exponent: exponent, milestone: DEFAULT_START_TIME + duration * (i + 1) })
                );
            }
        }
    }
}
