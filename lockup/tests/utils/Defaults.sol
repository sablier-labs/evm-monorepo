// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.22;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ud2x18 } from "@prb/math/src/UD2x18.sol";

import { BatchLockup } from "../../src/types/BatchLockup.sol";
import { Lockup } from "../../src/types/Lockup.sol";
import { LockupDynamic } from "../../src/types/LockupDynamic.sol";
import { LockupLinear } from "../../src/types/LockupLinear.sol";
import { LockupTranched } from "../../src/types/LockupTranched.sol";
import { ArrayBuilder } from "./ArrayBuilder.sol";
import { BatchLockupBuilder } from "./BatchLockupBuilder.sol";
import { Constants } from "./Constants.sol";
import { Users } from "./Types.sol";

/// @notice Contract with default values used throughout the tests.
contract Defaults is Constants {
    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    IERC20 private token;
    Users private users;

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

    function durations() public pure returns (LockupLinear.Durations memory) {
        return LockupLinear.Durations({ cliff: CLIFF_DURATION, total: TOTAL_DURATION });
    }

    function lockupAmounts() public pure returns (Lockup.Amounts memory) {
        return Lockup.Amounts({ deposited: DEPOSIT_AMOUNT, refunded: 0, withdrawn: 0 });
    }

    function lockupCreateEvent(
        IERC20 token_,
        uint128 depositAmount
    )
        public
        view
        returns (Lockup.CreateEventCommon memory)
    {
        return lockupCreateEvent(depositAmount, token_, lockupTimestamps());
    }

    function lockupCreateEvent(Lockup.Timestamps memory timestamps)
        public
        view
        returns (Lockup.CreateEventCommon memory)
    {
        return lockupCreateEvent(DEPOSIT_AMOUNT, token, timestamps);
    }

    function lockupCreateEvent(
        uint128 depositAmount,
        Lockup.Timestamps memory timestamps
    )
        public
        view
        returns (Lockup.CreateEventCommon memory)
    {
        return lockupCreateEvent(depositAmount, token, timestamps);
    }

    function lockupCreateEvent(
        uint128 depositAmount,
        IERC20 token_,
        Lockup.Timestamps memory timestamps
    )
        public
        view
        returns (Lockup.CreateEventCommon memory)
    {
        Lockup.CreateWithTimestamps memory params = createWithTimestamps();
        params.depositAmount = depositAmount;
        params.timestamps = timestamps;
        return lockupCreateEvent(params, token_);
    }

    function lockupCreateEvent(
        Lockup.CreateWithTimestamps memory params,
        IERC20 token_
    )
        public
        pure
        returns (Lockup.CreateEventCommon memory)
    {
        return Lockup.CreateEventCommon({
            sender: params.sender,
            recipient: params.recipient,
            depositAmount: params.depositAmount,
            token: token_,
            cancelable: params.cancelable,
            transferable: params.transferable,
            timestamps: params.timestamps,
            shape: params.shape
        });
    }

    function lockupTimestamps() public pure returns (Lockup.Timestamps memory) {
        return Lockup.Timestamps({ start: START_TIME, end: END_TIME });
    }

    function segments() public pure returns (LockupDynamic.Segment[] memory segments_) {
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
        pure
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

    function tranches() public pure returns (LockupTranched.Tranche[] memory tranches_) {
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
            depositAmount: DEPOSIT_AMOUNT,
            token: token,
            cancelable: true,
            transferable: true,
            shape: SHAPE
        });
    }

    function createWithTimestamps() public view returns (Lockup.CreateWithTimestamps memory) {
        return Lockup.CreateWithTimestamps({
            sender: users.sender,
            recipient: users.recipient,
            depositAmount: DEPOSIT_AMOUNT,
            token: token,
            cancelable: true,
            transferable: true,
            timestamps: lockupTimestamps(),
            shape: SHAPE
        });
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    BATCH-LOCKUP
    //////////////////////////////////////////////////////////////////////////*/

    function incrementalStreamIds(uint256 firstStreamId) public pure returns (uint256[] memory streamIds) {
        return ArrayBuilder.fillStreamIds({ firstStreamId: firstStreamId, batchSize: BATCH_SIZE });
    }

    /// @dev Returns a default-size batch of {BatchLockup.CreateWithDurationsLD} parameters.
    function batchCreateWithDurationsLD() public view returns (BatchLockup.CreateWithDurationsLD[] memory batch) {
        batch = BatchLockupBuilder.fillBatch(createWithDurations(), segmentsWithDurations(), BATCH_SIZE);
    }

    /// @dev Returns a default-size batch of {BatchLockup.CreateWithDurationsLL} parameters.
    function batchCreateWithDurationsLL() public view returns (BatchLockup.CreateWithDurationsLL[] memory batch) {
        batch = BatchLockupBuilder.fillBatch(createWithDurations(), unlockAmounts(), durations(), BATCH_SIZE);
    }

    /// @dev Returns a default-size batch of {BatchLockup.CreateWithDurationsLT} parameters.
    function batchCreateWithDurationsLT() public view returns (BatchLockup.CreateWithDurationsLT[] memory batch) {
        batch = BatchLockupBuilder.fillBatch(createWithDurations(), tranchesWithDurations(), BATCH_SIZE);
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
        batch = BatchLockupBuilder.fillBatch(createWithTimestamps(), segments(), batchSize);
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
        batch = BatchLockupBuilder.fillBatch(createWithTimestamps(), unlockAmounts(), CLIFF_TIME, batchSize);
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
        batch = BatchLockupBuilder.fillBatch(createWithTimestamps(), tranches(), batchSize);
    }
}
