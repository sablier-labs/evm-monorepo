// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { UD2x18, ud2x18 } from "@prb/math/src/UD2x18.sol";
import { UD60x18 } from "@prb/math/src/UD60x18.sol";

import { Broker, Lockup, LockupDynamic, LockupLinear } from "../../src/types/DataTypes.sol";

import { Constants } from "./Constants.sol";
import { Users } from "./Types.sol";

/// @notice Contract with default values used throughout the tests.
contract Defaults is Constants {
    /*//////////////////////////////////////////////////////////////////////////
                                     CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    UD60x18 public constant BROKER_FEE = UD60x18.wrap(0.003e18); // 0.3%
    uint128 public constant BROKER_FEE_AMOUNT = 30.120481927710843373e18; // 0.3% of total amount
    uint128 public constant CLIFF_AMOUNT = 2500e18;
    uint40 public immutable CLIFF_TIME;
    uint40 public constant CLIFF_DURATION = 2500 seconds;
    uint128 public constant DEPOSIT_AMOUNT = 10_000e18;
    uint40 public immutable END_TIME;
    UD60x18 public constant FLASH_FEE = UD60x18.wrap(0.0005e18); // 0.05%
    uint256 public constant MAX_SEGMENT_COUNT = 300;
    uint40 public immutable MAX_SEGMENT_DURATION;
    UD60x18 public constant PROTOCOL_FEE = UD60x18.wrap(0.001e18); // 0.1%
    uint128 public constant PROTOCOL_FEE_AMOUNT = 10.040160642570281124e18; // 0.1% of total amount
    uint128 public constant REFUND_AMOUNT = DEPOSIT_AMOUNT - CLIFF_AMOUNT;
    uint256 public SEGMENT_COUNT;
    uint40 public immutable START_TIME;
    uint128 public constant TOTAL_AMOUNT = 10_040.160642570281124497e18; // deposit / (1 - fee)
    uint40 public constant TOTAL_DURATION = 10_000 seconds;
    uint128 public constant WITHDRAW_AMOUNT = 2600e18;
    uint40 public immutable WARP_26_PERCENT; // 26% of the way through the stream

    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    IERC20 private asset;
    Users private users;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor() {
        START_TIME = uint40(MAY_1_2023) + 2 days;
        CLIFF_TIME = START_TIME + CLIFF_DURATION;
        END_TIME = START_TIME + TOTAL_DURATION;
        MAX_SEGMENT_DURATION = TOTAL_DURATION / uint40(MAX_SEGMENT_COUNT);
        SEGMENT_COUNT = 2;
        WARP_26_PERCENT = START_TIME + CLIFF_DURATION + 100 seconds;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    function setAsset(IERC20 asset_) public {
        asset = asset_;
    }

    function setUsers(Users memory users_) public {
        users = users_;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      STRUCTS
    //////////////////////////////////////////////////////////////////////////*/

    function broker() public view returns (Broker memory) {
        return Broker({ account: users.broker, fee: BROKER_FEE });
    }

    function durations() public pure returns (LockupLinear.Durations memory) {
        return LockupLinear.Durations({ cliff: CLIFF_DURATION, total: TOTAL_DURATION });
    }

    function lockupAmounts() public pure returns (Lockup.Amounts memory) {
        return Lockup.Amounts({ deposited: DEPOSIT_AMOUNT, refunded: 0, withdrawn: 0 });
    }

    function lockupCreateAmounts() public pure returns (Lockup.CreateAmounts memory) {
        return Lockup.CreateAmounts({
            deposit: DEPOSIT_AMOUNT,
            protocolFee: PROTOCOL_FEE_AMOUNT,
            brokerFee: BROKER_FEE_AMOUNT
        });
    }

    function lockupDynamicRange() public view returns (LockupDynamic.Range memory) {
        return LockupDynamic.Range({ start: START_TIME, end: END_TIME });
    }

    function lockupDynamicStream() public view returns (LockupDynamic.Stream memory) {
        return LockupDynamic.Stream({
            amounts: lockupAmounts(),
            asset: asset,
            endTime: END_TIME,
            isCancelable: true,
            isDepleted: false,
            isStream: true,
            segments: segments(),
            sender: users.sender,
            startTime: START_TIME,
            wasCanceled: false
        });
    }

    function lockupLinearRange() public view returns (LockupLinear.Range memory) {
        return LockupLinear.Range({ start: START_TIME, cliff: CLIFF_TIME, end: END_TIME });
    }

    function lockupLinearStream() public view returns (LockupLinear.Stream memory) {
        return LockupLinear.Stream({
            amounts: lockupAmounts(),
            asset: asset,
            cliffTime: CLIFF_TIME,
            endTime: END_TIME,
            isCancelable: true,
            isDepleted: false,
            isStream: true,
            sender: users.sender,
            startTime: START_TIME,
            wasCanceled: false
        });
    }

    function maxSegments() public view returns (LockupDynamic.Segment[] memory maxSegments_) {
        uint128 amount = DEPOSIT_AMOUNT / uint128(MAX_SEGMENT_COUNT);
        UD2x18 exponent = ud2x18(2.71e18);

        // Generate a bunch of segments with the same amount, same exponent, and with milestones evenly spread apart.
        maxSegments_ = new LockupDynamic.Segment[](MAX_SEGMENT_COUNT);
        for (uint40 i = 0; i < MAX_SEGMENT_COUNT; ++i) {
            maxSegments_[i] = (
                LockupDynamic.Segment({
                    amount: amount,
                    exponent: exponent,
                    milestone: START_TIME + MAX_SEGMENT_DURATION * (i + 1)
                })
            );
        }
    }

    function segments() public view returns (LockupDynamic.Segment[] memory segments_) {
        segments_ = new LockupDynamic.Segment[](2);
        segments_[0] = (
            LockupDynamic.Segment({ amount: 2500e18, exponent: ud2x18(3.14e18), milestone: START_TIME + CLIFF_DURATION })
        );
        segments_[1] = (
            LockupDynamic.Segment({ amount: 7500e18, exponent: ud2x18(0.5e18), milestone: START_TIME + TOTAL_DURATION })
        );
    }

    function segmentsWithDeltas() public view returns (LockupDynamic.SegmentWithDelta[] memory segmentsWithDeltas_) {
        LockupDynamic.Segment[] memory segments_ = segments();
        segmentsWithDeltas_ = new LockupDynamic.SegmentWithDelta[](2);
        segmentsWithDeltas_[0] = (
            LockupDynamic.SegmentWithDelta({
                amount: segments_[0].amount,
                exponent: segments_[0].exponent,
                delta: 2500 seconds
            })
        );
        segmentsWithDeltas_[1] = (
            LockupDynamic.SegmentWithDelta({
                amount: segments_[1].amount,
                exponent: segments_[1].exponent,
                delta: 7500 seconds
            })
        );
    }

    /*//////////////////////////////////////////////////////////////////////////
                                       PARAMS
    //////////////////////////////////////////////////////////////////////////*/

    function createWithDeltas() public view returns (LockupDynamic.CreateWithDeltas memory) {
        return LockupDynamic.CreateWithDeltas({
            asset: asset,
            broker: broker(),
            cancelable: true,
            recipient: users.recipient,
            segments: segmentsWithDeltas(),
            sender: users.sender,
            totalAmount: TOTAL_AMOUNT
        });
    }

    function createWithDurations() public view returns (LockupLinear.CreateWithDurations memory) {
        return LockupLinear.CreateWithDurations({
            asset: asset,
            broker: broker(),
            cancelable: true,
            durations: durations(),
            recipient: users.recipient,
            sender: users.sender,
            totalAmount: TOTAL_AMOUNT
        });
    }

    function createWithMilestones() public view returns (LockupDynamic.CreateWithMilestones memory) {
        return LockupDynamic.CreateWithMilestones({
            asset: asset,
            broker: broker(),
            cancelable: true,
            recipient: users.recipient,
            segments: segments(),
            sender: users.sender,
            startTime: START_TIME,
            totalAmount: TOTAL_AMOUNT
        });
    }

    function createWithRange() public view returns (LockupLinear.CreateWithRange memory) {
        return LockupLinear.CreateWithRange({
            asset: asset,
            broker: broker(),
            cancelable: true,
            range: lockupLinearRange(),
            recipient: users.recipient,
            sender: users.sender,
            totalAmount: TOTAL_AMOUNT
        });
    }
}
