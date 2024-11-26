// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ud2x18 } from "@prb/math/src/UD2x18.sol";
import { UD60x18, ZERO } from "@prb/math/src/UD60x18.sol";

import { BatchLockup, Broker, Lockup, LockupDynamic, LockupLinear, LockupTranched } from "../../src/types/DataTypes.sol";

import { ArrayBuilder } from "./ArrayBuilder.sol";
import { BatchLockupBuilder } from "./BatchLockupBuilder.sol";
import { Constants } from "./Constants.sol";
import { Users } from "./Types.sol";

/// @notice Contract with default values used throughout the tests.
contract Defaults is Constants {
    /*//////////////////////////////////////////////////////////////////////////
                                      GENERICS
    //////////////////////////////////////////////////////////////////////////*/

    uint64 public constant BATCH_SIZE = 10;
    UD60x18 public constant BROKER_FEE = UD60x18.wrap(0.003e18); // 0.3%
    uint128 public constant BROKER_FEE_AMOUNT = 30.090270812437311935e18; // 0.3% of total amount
    uint128 public constant CLIFF_AMOUNT = 2500e18 + 2534;
    uint40 public immutable CLIFF_TIME;
    uint40 public constant CLIFF_DURATION = 2500 seconds;
    uint128 public constant DEPOSIT_AMOUNT = 10_000e18;
    uint40 public immutable END_TIME;
    uint256 public constant MAX_COUNT = 10_000;
    uint40 public immutable MAX_SEGMENT_DURATION;
    uint256 public constant MAX_TRANCHE_COUNT = 10_000;
    uint128 public constant REFUND_AMOUNT = DEPOSIT_AMOUNT - WITHDRAW_AMOUNT;
    uint256 public constant SEGMENT_COUNT = 2;
    string public constant SHAPE = "emits in the event";
    uint40 public immutable START_TIME;
    uint128 public constant START_AMOUNT = 0;
    uint128 public constant STREAMED_AMOUNT_26_PERCENT = 2600e18;
    uint128 public constant TOTAL_AMOUNT = 10_030.090270812437311935e18; // deposit + broker fee
    uint40 public constant TOTAL_DURATION = 10_000 seconds;
    uint256 public constant TRANCHE_COUNT = 2;
    uint128 public constant TOTAL_TRANSFER_AMOUNT = DEPOSIT_AMOUNT * uint128(BATCH_SIZE);
    uint128 public constant WITHDRAW_AMOUNT = STREAMED_AMOUNT_26_PERCENT;
    uint40 public immutable WARP_26_PERCENT;
    uint40 public immutable WARP_26_PERCENT_DURATION = 2600 seconds; // 26% of the way through the stream

    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    IERC20 private token;
    Users private users;

    /*//////////////////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
    //////////////////////////////////////////////////////////////////////////*/

    constructor() {
        START_TIME = JULY_1_2024 + 2 days;
        CLIFF_TIME = START_TIME + CLIFF_DURATION;
        END_TIME = START_TIME + TOTAL_DURATION;
        MAX_SEGMENT_DURATION = TOTAL_DURATION / uint40(MAX_COUNT);
        WARP_26_PERCENT = START_TIME + WARP_26_PERCENT_DURATION;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    function setToken(IERC20 token_) public {
        token = token_;
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

    function brokerNull() public pure returns (Broker memory) {
        return Broker({ account: address(0), fee: ZERO });
    }

    function durations() public pure returns (LockupLinear.Durations memory) {
        return LockupLinear.Durations({ cliff: CLIFF_DURATION, total: TOTAL_DURATION });
    }

    function lockupAmounts() public pure returns (Lockup.Amounts memory) {
        return Lockup.Amounts({ deposited: DEPOSIT_AMOUNT, refunded: 0, withdrawn: 0 });
    }

    function lockupCreateAmounts() public pure returns (Lockup.CreateAmounts memory) {
        return Lockup.CreateAmounts({ deposit: DEPOSIT_AMOUNT, brokerFee: BROKER_FEE_AMOUNT });
    }

    function lockupCreateEvent(IERC20 token_) public view returns (Lockup.CreateEventCommon memory) {
        return lockupCreateEvent(token_, lockupCreateAmounts(), lockupTimestamps());
    }

    function lockupCreateEvent(Lockup.Timestamps memory timestamps)
        public
        view
        returns (Lockup.CreateEventCommon memory)
    {
        return lockupCreateEvent(token, lockupCreateAmounts(), timestamps);
    }

    function lockupCreateEvent(
        Lockup.CreateAmounts memory createAmounts,
        Lockup.Timestamps memory timestamps
    )
        public
        view
        returns (Lockup.CreateEventCommon memory)
    {
        return lockupCreateEvent(token, createAmounts, timestamps);
    }

    function lockupCreateEvent(
        IERC20 token_,
        Lockup.CreateAmounts memory createAmounts,
        Lockup.Timestamps memory timestamps
    )
        public
        view
        returns (Lockup.CreateEventCommon memory)
    {
        return Lockup.CreateEventCommon({
            funder: users.sender,
            sender: users.sender,
            recipient: users.recipient,
            amounts: createAmounts,
            token: token_,
            cancelable: true,
            transferable: true,
            timestamps: timestamps,
            shape: SHAPE,
            broker: users.broker
        });
    }

    function lockupTimestamps() public view returns (Lockup.Timestamps memory) {
        return Lockup.Timestamps({ start: START_TIME, end: END_TIME });
    }

    function segments() public view returns (LockupDynamic.Segment[] memory segments_) {
        segments_ = new LockupDynamic.Segment[](2);
        segments_[0] = (
            LockupDynamic.Segment({
                amount: 2600e18,
                exponent: ud2x18(3.14e18),
                timestamp: START_TIME + WARP_26_PERCENT_DURATION
            })
        );
        segments_[1] = (
            LockupDynamic.Segment({ amount: 7400e18, exponent: ud2x18(0.5e18), timestamp: START_TIME + TOTAL_DURATION })
        );
    }

    function segmentsWithDurations()
        public
        view
        returns (LockupDynamic.SegmentWithDuration[] memory segmentsWithDurations_)
    {
        LockupDynamic.Segment[] memory segments_ = segments();
        segmentsWithDurations_ = new LockupDynamic.SegmentWithDuration[](2);
        segmentsWithDurations_[0] = (
            LockupDynamic.SegmentWithDuration({
                amount: segments_[0].amount,
                exponent: segments_[0].exponent,
                duration: 2600 seconds
            })
        );
        segmentsWithDurations_[1] = (
            LockupDynamic.SegmentWithDuration({
                amount: segments_[1].amount,
                exponent: segments_[1].exponent,
                duration: 7400 seconds
            })
        );
    }

    function tranches() public view returns (LockupTranched.Tranche[] memory tranches_) {
        tranches_ = new LockupTranched.Tranche[](2);
        tranches_[0] = LockupTranched.Tranche({ amount: 2600e18, timestamp: WARP_26_PERCENT });
        tranches_[1] = LockupTranched.Tranche({ amount: 7400e18, timestamp: START_TIME + TOTAL_DURATION });
    }

    function tranchesWithDurations()
        public
        pure
        returns (LockupTranched.TrancheWithDuration[] memory tranchesWithDurations_)
    {
        tranchesWithDurations_ = new LockupTranched.TrancheWithDuration[](2);
        tranchesWithDurations_[0] = LockupTranched.TrancheWithDuration({ amount: 2600e18, duration: 2600 seconds });
        tranchesWithDurations_[1] = LockupTranched.TrancheWithDuration({ amount: 7400e18, duration: 7400 seconds });
    }

    function unlockAmounts() public pure returns (LockupLinear.UnlockAmounts memory) {
        return LockupLinear.UnlockAmounts({ start: START_AMOUNT, cliff: CLIFF_AMOUNT });
    }

    function unlockAmountsZero() public pure returns (LockupLinear.UnlockAmounts memory) {
        return LockupLinear.UnlockAmounts({ start: 0, cliff: 0 });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   CREATE-PARAMS
    //////////////////////////////////////////////////////////////////////////*/

    function createWithDurations() public view returns (Lockup.CreateWithDurations memory) {
        return Lockup.CreateWithDurations({
            sender: users.sender,
            recipient: users.recipient,
            totalAmount: TOTAL_AMOUNT,
            token: token,
            cancelable: true,
            transferable: true,
            shape: SHAPE,
            broker: broker()
        });
    }

    function createWithDurationsBrokerNull() public view returns (Lockup.CreateWithDurations memory params_) {
        params_ = createWithDurations();
        params_.totalAmount = DEPOSIT_AMOUNT;
        params_.broker = brokerNull();
    }

    function createWithTimestamps() public view returns (Lockup.CreateWithTimestamps memory) {
        return Lockup.CreateWithTimestamps({
            sender: users.sender,
            recipient: users.recipient,
            totalAmount: TOTAL_AMOUNT,
            token: token,
            cancelable: true,
            transferable: true,
            timestamps: lockupTimestamps(),
            shape: SHAPE,
            broker: broker()
        });
    }

    function createWithTimestampsBrokerNull() public view returns (Lockup.CreateWithTimestamps memory params_) {
        params_ = createWithTimestamps();
        params_.totalAmount = DEPOSIT_AMOUNT;
        params_.broker = brokerNull();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    BATCH-LOCKUP
    //////////////////////////////////////////////////////////////////////////*/

    function incrementalStreamIds(uint256 firstStreamId) public pure returns (uint256[] memory streamIds) {
        return ArrayBuilder.fillStreamIds({ firstStreamId: firstStreamId, batchSize: BATCH_SIZE });
    }

    /// @dev Returns a default-size batch of {BatchLockup.CreateWithDurationsLD} parameters.
    function batchCreateWithDurationsLD() public view returns (BatchLockup.CreateWithDurationsLD[] memory batch) {
        batch = BatchLockupBuilder.fillBatch(createWithDurationsBrokerNull(), segmentsWithDurations(), BATCH_SIZE);
    }

    /// @dev Returns a default-size batch of {BatchLockup.CreateWithDurationsLL} parameters.
    function batchCreateWithDurationsLL() public view returns (BatchLockup.CreateWithDurationsLL[] memory batch) {
        batch = BatchLockupBuilder.fillBatch(createWithDurationsBrokerNull(), unlockAmounts(), durations(), BATCH_SIZE);
    }

    /// @dev Returns a default-size batch of {BatchLockup.CreateWithDurationsLT} parameters.
    function batchCreateWithDurationsLT() public view returns (BatchLockup.CreateWithDurationsLT[] memory batch) {
        batch = BatchLockupBuilder.fillBatch(createWithDurationsBrokerNull(), tranchesWithDurations(), BATCH_SIZE);
    }

    /// @dev Returns a default-size batch of {BatchLockup.CreateWithTimestampsLD} parameters.
    function batchCreateWithTimestampsLD() public view returns (BatchLockup.CreateWithTimestampsLD[] memory batch) {
        batch = batchCreateWithTimestampsLD(BATCH_SIZE);
    }

    /// @dev Returns a batch of {BatchLockup.CreateWithTimestampsLD} parameters.
    function batchCreateWithTimestampsLD(uint256 batchSize)
        public
        view
        returns (BatchLockup.CreateWithTimestampsLD[] memory batch)
    {
        batch = BatchLockupBuilder.fillBatch(createWithTimestampsBrokerNull(), segments(), batchSize);
    }

    /// @dev Returns a default-size batch of {BatchLockup.CreateWithTimestampsLL} parameters.
    function batchCreateWithTimestampsLL() public view returns (BatchLockup.CreateWithTimestampsLL[] memory batch) {
        batch = batchCreateWithTimestampsLL(BATCH_SIZE);
    }

    /// @dev Returns a batch of {BatchLockup.CreateWithTimestampsLL} parameters.
    function batchCreateWithTimestampsLL(uint256 batchSize)
        public
        view
        returns (BatchLockup.CreateWithTimestampsLL[] memory batch)
    {
        batch = BatchLockupBuilder.fillBatch(createWithTimestampsBrokerNull(), unlockAmounts(), CLIFF_TIME, batchSize);
    }

    /// @dev Returns a default-size batch of {BatchLockup.CreateWithTimestampsLT} parameters.
    function batchCreateWithTimestampsLT() public view returns (BatchLockup.CreateWithTimestampsLT[] memory batch) {
        batch = batchCreateWithTimestampsLT(BATCH_SIZE);
    }

    /// @dev Returns a batch of {BatchLockup.CreateWithTimestampsLL} parameters.
    function batchCreateWithTimestampsLT(uint256 batchSize)
        public
        view
        returns (BatchLockup.CreateWithTimestampsLT[] memory batch)
    {
        batch = BatchLockupBuilder.fillBatch(createWithTimestampsBrokerNull(), tranches(), batchSize);
    }
}
