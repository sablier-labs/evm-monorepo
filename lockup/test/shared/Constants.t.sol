// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { UD2x18, ud2x18 } from "@prb/math/UD2x18.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";

import { Lockup, LockupDynamic, LockupLinear } from "../../src/types/DataTypes.sol";

abstract contract Constants {
    /*//////////////////////////////////////////////////////////////////////////
                                  SIMPLE CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    UD60x18 internal constant DEFAULT_BROKER_FEE = UD60x18.wrap(0.003e18); // 0.3%
    uint128 internal constant DEFAULT_BROKER_FEE_AMOUNT = 30.120481927710843373e18; // 0.3% of total amount
    uint40 internal immutable DEFAULT_CLIFF_TIME;
    uint40 internal constant DEFAULT_CLIFF_DURATION = 2500 seconds;
    uint128 internal constant DEFAULT_DEPOSIT_AMOUNT = 10_000e18;
    uint40 internal immutable DEFAULT_END_TIME;
    UD60x18 internal constant DEFAULT_FLASH_FEE = UD60x18.wrap(0.0005e18); // 0.05%
    uint256 internal constant DEFAULT_MAX_SEGMENT_COUNT = 1000;
    UD60x18 internal constant DEFAULT_PROTOCOL_FEE = UD60x18.wrap(0.001e18); // 0.1%
    uint128 internal constant DEFAULT_PROTOCOL_FEE_AMOUNT = 10.040160642570281124e18; // 0.1% of total amount
    uint40 internal immutable DEFAULT_START_TIME;
    uint40 internal constant DEFAULT_TIME_WARP = 2600 seconds;
    uint128 internal constant DEFAULT_TOTAL_AMOUNT = 10_040.160642570281124497e18; // deposit / (1 - fee)
    uint40 internal constant DEFAULT_TOTAL_DURATION = 10_000 seconds;
    uint128 internal constant DEFAULT_WITHDRAW_AMOUNT = 2600e18;
    bytes32 internal constant FLASH_LOAN_CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");
    UD60x18 internal constant MAX_FEE = UD60x18.wrap(0.1e18); // 10%
    uint40 internal immutable MAX_SEGMENT_DURATION;
    uint40 internal constant MAX_UNIX_TIMESTAMP = 2_147_483_647; // 2^31 - 1
    uint128 internal constant UINT128_MAX = type(uint128).max;
    uint256 internal constant UINT256_MAX = type(uint256).max;
    uint40 internal constant UINT40_MAX = type(uint40).max;

    /*//////////////////////////////////////////////////////////////////////////
                                 COMPLEX CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    Lockup.CreateAmounts internal DEFAULT_LOCKUP_CREATE_AMOUNTS = Lockup.CreateAmounts({
        deposit: DEFAULT_DEPOSIT_AMOUNT,
        protocolFee: DEFAULT_PROTOCOL_FEE_AMOUNT,
        brokerFee: DEFAULT_BROKER_FEE_AMOUNT
    });
    Lockup.Amounts internal DEFAULT_LOCKUP_AMOUNTS = Lockup.Amounts({ deposit: DEFAULT_DEPOSIT_AMOUNT, withdrawn: 0 });
    LockupLinear.Durations internal DEFAULT_DURATIONS =
        LockupLinear.Durations({ cliff: DEFAULT_CLIFF_DURATION, total: DEFAULT_TOTAL_DURATION });
    LockupDynamic.Range internal DEFAULT_DYNAMIC_RANGE;
    LockupLinear.Range internal DEFAULT_LINEAR_RANGE;
    LockupDynamic.Segment[] internal DEFAULT_SEGMENTS;
    LockupDynamic.SegmentWithDelta[] internal DEFAULT_SEGMENTS_WITH_DELTAS;
    LockupDynamic.Segment[] internal MAX_SEGMENTS;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor() {
        DEFAULT_START_TIME = uint40(1_677_632_400); // March 1, 2023 at 00:00 GMT
        DEFAULT_CLIFF_TIME = DEFAULT_START_TIME + DEFAULT_CLIFF_DURATION;
        DEFAULT_END_TIME = DEFAULT_START_TIME + DEFAULT_TOTAL_DURATION;
        DEFAULT_LINEAR_RANGE =
            LockupLinear.Range({ start: DEFAULT_START_TIME, cliff: DEFAULT_CLIFF_TIME, end: DEFAULT_END_TIME });
        DEFAULT_DYNAMIC_RANGE = LockupDynamic.Range({ start: DEFAULT_START_TIME, end: DEFAULT_END_TIME });

        DEFAULT_SEGMENTS.push(
            LockupDynamic.Segment({
                amount: 2500e18,
                exponent: ud2x18(3.14e18),
                milestone: DEFAULT_START_TIME + DEFAULT_CLIFF_DURATION
            })
        );
        DEFAULT_SEGMENTS.push(
            LockupDynamic.Segment({
                amount: 7500e18,
                exponent: ud2x18(0.5e18),
                milestone: DEFAULT_START_TIME + DEFAULT_TOTAL_DURATION
            })
        );

        DEFAULT_SEGMENTS_WITH_DELTAS.push(
            LockupDynamic.SegmentWithDelta({
                amount: DEFAULT_SEGMENTS[0].amount,
                exponent: DEFAULT_SEGMENTS[0].exponent,
                delta: 2500 seconds
            })
        );
        DEFAULT_SEGMENTS_WITH_DELTAS.push(
            LockupDynamic.SegmentWithDelta({
                amount: DEFAULT_SEGMENTS[1].amount,
                exponent: DEFAULT_SEGMENTS[1].exponent,
                delta: 7500 seconds
            })
        );

        unchecked {
            uint128 amount = DEFAULT_DEPOSIT_AMOUNT / uint128(DEFAULT_MAX_SEGMENT_COUNT);
            UD2x18 exponent = ud2x18(2.71e18);
            MAX_SEGMENT_DURATION = DEFAULT_TOTAL_DURATION / uint40(DEFAULT_MAX_SEGMENT_COUNT);

            // Generate a bunch of segments with the same amount, same exponent, and with milestones
            // evenly spread apart.
            for (uint40 i = 0; i < DEFAULT_MAX_SEGMENT_COUNT; ++i) {
                MAX_SEGMENTS.push(
                    LockupDynamic.Segment({
                        amount: amount,
                        exponent: exponent,
                        milestone: DEFAULT_START_TIME + MAX_SEGMENT_DURATION * (i + 1)
                    })
                );
            }
        }
    }
}
