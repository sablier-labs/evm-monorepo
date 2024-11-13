// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { Broker, Lockup, LockupDynamic, LockupLinear, LockupTranched } from "src/core/types/DataTypes.sol";

import { Integration_Test } from "../../Integration.t.sol";

/// @dev A shared test containing various create functions for Lockup Dynamic, Lockup Linear, and Lockup Tranched.
abstract contract Lockup_Integration_Shared_Test is Integration_Test {
    struct CreateParams {
        Lockup.CreateWithTimestamps createWithTimestamps;
        Lockup.CreateWithDurations createWithDurations;
        uint40 cliffTime;
        LockupLinear.Durations durations;
        LockupDynamic.Segment[] segments;
        LockupDynamic.SegmentWithDuration[] segmentsWithDurations;
        LockupTranched.Tranche[] tranches;
        LockupTranched.TrancheWithDuration[] tranchesWithDurations;
    }

    CreateParams private _params;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Integration_Test.setUp();

        _params.createWithTimestamps = defaults.createWithTimestamps();
        _params.createWithDurations = defaults.createWithDurations();
        _params.cliffTime = defaults.CLIFF_TIME();
        _params.durations = defaults.durations();

        // See https://github.com/ethereum/solidity/issues/12783
        LockupDynamic.SegmentWithDuration[] memory segmentsWithDurations = defaults.segmentsWithDurations();
        LockupDynamic.Segment[] memory segments = defaults.segments();
        for (uint256 i; i < defaults.SEGMENT_COUNT(); ++i) {
            _params.segments.push(segments[i]);
            _params.segmentsWithDurations.push(segmentsWithDurations[i]);
        }
        LockupTranched.TrancheWithDuration[] memory tranchesWithDurations = defaults.tranchesWithDurations();
        LockupTranched.Tranche[] memory tranches = defaults.tranches();
        for (uint256 i; i < defaults.TRANCHE_COUNT(); ++i) {
            _params.tranches.push(tranches[i]);
            _params.tranchesWithDurations.push(tranchesWithDurations[i]);
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  LOCKUP-DYNAMIC
    //////////////////////////////////////////////////////////////////////////*/

    function createDefaultStreamLD() internal returns (uint256 streamId) {
        streamId = lockup.createWithTimestampsLD(_params.createWithTimestamps, _params.segments);
    }

    function createDefaultStreamWithAssetLD(IERC20 asset) internal returns (uint256 streamId) {
        Lockup.CreateWithTimestamps memory params = _params.createWithTimestamps;
        params.asset = asset;
        streamId = lockup.createWithTimestampsLD(params, _params.segments);
    }

    function createDefaultStreamWithBrokerLD(Broker memory broker) internal returns (uint256 streamId) {
        Lockup.CreateWithTimestamps memory params = _params.createWithTimestamps;
        params.broker = broker;
        streamId = lockup.createWithTimestampsLD(params, _params.segments);
    }

    /// @dev Creates the default stream with durations.
    function createDefaultStreamWithDurationsLD() internal returns (uint256 streamId) {
        streamId = lockup.createWithDurationsLD(_params.createWithDurations, _params.segmentsWithDurations);
    }

    /// @dev Creates the default stream with the provided durations.
    function createDefaultStreamWithDurationsLD(LockupDynamic.SegmentWithDuration[] memory segmentsWithDurations)
        internal
        returns (uint256 streamId)
    {
        streamId = lockup.createWithDurationsLD(_params.createWithDurations, segmentsWithDurations);
    }

    function createDefaultStreamWithEndTimeLD(uint40 endTime) internal returns (uint256 streamId) {
        Lockup.CreateWithTimestamps memory params = _params.createWithTimestamps;
        LockupDynamic.Segment[] memory segments_ = _params.segments;
        params.endTime = endTime;
        segments_[1].timestamp = endTime;
        streamId = lockup.createWithTimestampsLD(params, segments_);
    }

    function createDefaultStreamWithIdenticalUsersLD(address user) internal returns (uint256 streamId) {
        Lockup.CreateWithTimestamps memory params = _params.createWithTimestamps;
        params.sender = user;
        params.recipient = user;
        streamId = lockup.createWithTimestampsLD(params, _params.segments);
    }

    function createDefaultStreamNotCancelableLD() internal returns (uint256 streamId) {
        Lockup.CreateWithTimestamps memory params = _params.createWithTimestamps;
        params.cancelable = false;
        streamId = lockup.createWithTimestampsLD(params, _params.segments);
    }

    function createDefaultStreamNotTransferableLD() internal returns (uint256 streamId) {
        Lockup.CreateWithTimestamps memory params = _params.createWithTimestamps;
        params.transferable = false;
        streamId = lockup.createWithTimestampsLD(params, _params.segments);
    }

    function createDefaultStreamWithRecipientLD(address recipient) internal returns (uint256 streamId) {
        Lockup.CreateWithTimestamps memory params = _params.createWithTimestamps;
        params.recipient = recipient;
        streamId = lockup.createWithTimestampsLD(params, _params.segments);
    }

    /// @dev Creates the default stream with the provided segments.
    function createDefaultStreamWithSegmentsLD(LockupDynamic.Segment[] memory segments)
        internal
        returns (uint256 streamId)
    {
        streamId = lockup.createWithTimestampsLD(_params.createWithTimestamps, segments);
    }

    function createDefaultStreamWithSenderLD(address sender) internal returns (uint256 streamId) {
        Lockup.CreateWithTimestamps memory params = _params.createWithTimestamps;
        params.sender = sender;
        streamId = lockup.createWithTimestampsLD(params, _params.segments);
    }

    function createDefaultStreamWithStartTimeLD(uint40 startTime) internal returns (uint256 streamId) {
        Lockup.CreateWithTimestamps memory params = _params.createWithTimestamps;
        params.startTime = startTime;
        streamId = lockup.createWithTimestampsLD(params, _params.segments);
    }

    /// @dev Creates the default stream with the provided timestamps.
    function createDefaultStreamWithTimestampsLD(Lockup.Timestamps memory timestamps)
        internal
        returns (uint256 streamId)
    {
        Lockup.CreateWithTimestamps memory params = _params.createWithTimestamps;
        LockupDynamic.Segment[] memory segments_ = _params.segments;
        params.startTime = timestamps.start;
        params.endTime = timestamps.end;
        segments_[1].timestamp = timestamps.end;
        streamId = lockup.createWithTimestampsLD(params, segments_);
    }

    function createDefaultStreamWithTotalAmountLD(uint128 totalAmount) internal returns (uint256 streamId) {
        Lockup.CreateWithTimestamps memory params = _params.createWithTimestamps;
        params.totalAmount = totalAmount;
        streamId = lockup.createWithTimestampsLD(params, _params.segments);
    }

    function createDefaultStreamWithUsersLD(address recipient, address sender) internal returns (uint256 streamId) {
        Lockup.CreateWithTimestamps memory params = _params.createWithTimestamps;
        params.recipient = recipient;
        params.sender = sender;
        streamId = lockup.createWithTimestampsLD(params, _params.segments);
    }

    /// @dev The following two functions are used in `CancelMultiple` and `WithdrawMultiple` tests.
    function WarpAndCreateStreamsForCancelMultipleLD(uint40 warpTime) internal returns (uint256[2] memory streamIds) {
        vm.warp({ newTimestamp: warpTime });

        // Create the first stream.
        streamIds[0] = createDefaultStreamLD();

        // Create the second stream with an end time double that of the default stream so that the refund amounts are
        // different.
        streamIds[1] = createDefaultStreamWithEndTimeLD(defaults.END_TIME() + defaults.TOTAL_DURATION());
    }

    function WarpAndCreateStreamsWithdrawMultipleLD(uint40 warpTime) internal returns (uint256[3] memory streamIds) {
        vm.warp({ newTimestamp: warpTime });

        // Create three test streams:
        // 1. A default stream
        // 2. A stream with an early end time
        // 3. A stream meant to be canceled before the withdrawal is made
        streamIds[0] = createDefaultStreamLD();
        streamIds[1] = createDefaultStreamWithEndTimeLD(defaults.WARP_26_PERCENT());
        streamIds[2] = createDefaultStreamLD();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  LOCKUP-LINEAR
    //////////////////////////////////////////////////////////////////////////*/

    function createDefaultStreamLL() internal returns (uint256 streamId) {
        streamId = lockup.createWithTimestampsLL(_params.createWithTimestamps, _params.cliffTime);
    }

    function createDefaultStreamWithAssetLL(IERC20 asset) internal returns (uint256 streamId) {
        Lockup.CreateWithTimestamps memory params = _params.createWithTimestamps;
        params.asset = asset;
        streamId = lockup.createWithTimestampsLL(params, _params.cliffTime);
    }

    function createDefaultStreamWithBrokerLL(Broker memory broker) internal returns (uint256 streamId) {
        Lockup.CreateWithTimestamps memory params = _params.createWithTimestamps;
        params.broker = broker;
        streamId = lockup.createWithTimestampsLL(params, _params.cliffTime);
    }

    /// @dev Creates the default stream with durations.
    function createDefaultStreamWithDurationsLL() internal returns (uint256 streamId) {
        streamId = lockup.createWithDurationsLL(_params.createWithDurations, _params.durations);
    }

    /// @dev Creates the default stream with the provided durations.
    function createDefaultStreamWithDurationsLL(LockupLinear.Durations memory durations)
        internal
        returns (uint256 streamId)
    {
        streamId = lockup.createWithDurationsLL(_params.createWithDurations, durations);
    }

    function createDefaultStreamNotCancelableLL() internal returns (uint256 streamId) {
        Lockup.CreateWithTimestamps memory params = _params.createWithTimestamps;
        params.cancelable = false;
        streamId = lockup.createWithTimestampsLL(params, _params.cliffTime);
    }

    function createDefaultStreamNotTransferableLL() internal returns (uint256 streamId) {
        Lockup.CreateWithTimestamps memory params = _params.createWithTimestamps;
        params.transferable = false;
        streamId = lockup.createWithTimestampsLL(params, _params.cliffTime);
    }

    function createDefaultStreamWithEndTimeLL(uint40 endTime) internal returns (uint256 streamId) {
        Lockup.CreateWithTimestamps memory params = _params.createWithTimestamps;
        params.endTime = endTime;
        streamId = lockup.createWithTimestampsLL(params, _params.cliffTime);
    }

    function createDefaultStreamWithIdenticalUsersLL(address user) internal returns (uint256 streamId) {
        Lockup.CreateWithTimestamps memory params = _params.createWithTimestamps;
        params.sender = user;
        params.recipient = user;
        streamId = lockup.createWithTimestampsLL(params, _params.cliffTime);
    }

    function createDefaultStreamWithRecipientLL(address recipient) internal returns (uint256 streamId) {
        Lockup.CreateWithTimestamps memory params = _params.createWithTimestamps;
        params.recipient = recipient;
        streamId = lockup.createWithTimestampsLL(params, _params.cliffTime);
    }

    function createDefaultStreamWithSenderLL(address sender) internal returns (uint256 streamId) {
        Lockup.CreateWithTimestamps memory params = _params.createWithTimestamps;
        params.sender = sender;
        streamId = lockup.createWithTimestampsLL(params, _params.cliffTime);
    }

    function createDefaultStreamWithStartTimeLL(uint40 startTime) internal returns (uint256 streamId) {
        Lockup.CreateWithTimestamps memory params = _params.createWithTimestamps;
        params.startTime = startTime;
        streamId = lockup.createWithTimestampsLL(params, _params.cliffTime);
    }

    /// @dev Creates the default stream with the provided timestamps.
    function createDefaultStreamWithTimestampsLL(Lockup.Timestamps memory timestamps)
        internal
        returns (uint256 streamId)
    {
        Lockup.CreateWithTimestamps memory params = _params.createWithTimestamps;
        params.startTime = timestamps.start;
        params.endTime = timestamps.end;
        streamId = lockup.createWithTimestampsLL(params, timestamps.cliff);
    }

    function createDefaultStreamWithTotalAmountLL(uint128 totalAmount) internal returns (uint256 streamId) {
        Lockup.CreateWithTimestamps memory params = _params.createWithTimestamps;
        params.totalAmount = totalAmount;
        streamId = lockup.createWithTimestampsLL(params, _params.cliffTime);
    }

    function createDefaultStreamWithUsersLL(address recipient, address sender) internal returns (uint256 streamId) {
        Lockup.CreateWithTimestamps memory params = _params.createWithTimestamps;
        params.recipient = recipient;
        params.sender = sender;
        streamId = lockup.createWithTimestampsLL(params, _params.cliffTime);
    }

    /// @dev The following two functions are used in `CancelMultiple` and `WithdrawMultiple` tests.
    function WarpAndCreateStreamsForCancelMultipleLL(uint40 warpTime) internal returns (uint256[2] memory streamIds) {
        vm.warp({ newTimestamp: warpTime });

        // Create the first stream.
        streamIds[0] = createDefaultStreamLL();
        // Create the second stream with an end time double that of the default stream so that the refund amounts are
        // different.
        streamIds[1] = createDefaultStreamWithEndTimeLL(defaults.END_TIME() + defaults.TOTAL_DURATION());
    }

    function WarpAndCreateStreamsWithdrawMultipleLL(uint40 warpTime) internal returns (uint256[3] memory streamIds) {
        vm.warp({ newTimestamp: warpTime });

        // Create three test streams:
        // 1. A default stream
        // 2. A stream with an early end time
        // 3. A stream meant to be canceled before the withdrawal is made
        streamIds[0] = createDefaultStreamLL();
        streamIds[1] = createDefaultStreamWithEndTimeLL(defaults.WARP_26_PERCENT());
        streamIds[2] = createDefaultStreamLL();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  LOCKUP-TRANCHED
    //////////////////////////////////////////////////////////////////////////*/

    function createDefaultStreamLT() internal returns (uint256 streamId) {
        streamId = lockup.createWithTimestampsLT(_params.createWithTimestamps, _params.tranches);
    }

    function createDefaultStreamWithAssetLT(IERC20 asset) internal returns (uint256 streamId) {
        Lockup.CreateWithTimestamps memory params = _params.createWithTimestamps;
        params.asset = asset;
        streamId = lockup.createWithTimestampsLT(params, _params.tranches);
    }

    function createDefaultStreamWithBrokerLT(Broker memory broker) internal returns (uint256 streamId) {
        Lockup.CreateWithTimestamps memory params = _params.createWithTimestamps;
        params.broker = broker;
        streamId = lockup.createWithTimestampsLT(params, _params.tranches);
    }

    /// @dev Creates the default stream with durations.
    function createDefaultStreamWithDurationsLT() internal returns (uint256 streamId) {
        streamId = lockup.createWithDurationsLT(_params.createWithDurations, _params.tranchesWithDurations);
    }

    /// @dev Creates the default stream with the provided durations.
    function createDefaultStreamWithDurationsLT(LockupTranched.TrancheWithDuration[] memory tranchesWithDuration)
        internal
        returns (uint256 streamId)
    {
        streamId = lockup.createWithDurationsLT(_params.createWithDurations, tranchesWithDuration);
    }

    function createDefaultStreamWithEndTimeLT(uint40 endTime) internal returns (uint256 streamId) {
        Lockup.CreateWithTimestamps memory params = _params.createWithTimestamps;
        LockupTranched.Tranche[] memory tranches_ = _params.tranches;
        params.endTime = endTime;
        tranches_[2].timestamp = endTime;

        // Ensure the timestamps are arranged in ascending order.
        if (tranches_[2].timestamp <= tranches_[1].timestamp) {
            tranches_[1].timestamp = tranches_[2].timestamp - 1;
        }
        if (tranches_[1].timestamp <= tranches_[0].timestamp) {
            tranches_[0].timestamp = tranches_[1].timestamp - 1;
        }

        streamId = lockup.createWithTimestampsLT(params, tranches_);
    }

    function createDefaultStreamWithIdenticalUsersLT(address user) internal returns (uint256 streamId) {
        Lockup.CreateWithTimestamps memory params = _params.createWithTimestamps;
        params.sender = user;
        params.recipient = user;
        streamId = lockup.createWithTimestampsLT(params, _params.tranches);
    }

    function createDefaultStreamNotCancelableLT() internal returns (uint256 streamId) {
        Lockup.CreateWithTimestamps memory params = _params.createWithTimestamps;
        params.cancelable = false;
        streamId = lockup.createWithTimestampsLT(params, _params.tranches);
    }

    function createDefaultStreamNotTransferableLT() internal returns (uint256 streamId) {
        Lockup.CreateWithTimestamps memory params = _params.createWithTimestamps;
        params.transferable = false;
        streamId = lockup.createWithTimestampsLT(params, _params.tranches);
    }

    /// @dev Creates the default stream with the provided timestamps.
    function createDefaultStreamWithTimestampsLT(Lockup.Timestamps memory timestamps)
        internal
        returns (uint256 streamId)
    {
        Lockup.CreateWithTimestamps memory params = _params.createWithTimestamps;
        LockupTranched.Tranche[] memory tranches_ = _params.tranches;
        params.startTime = timestamps.start;
        params.endTime = timestamps.end;
        tranches_[1].timestamp = timestamps.end;
        streamId = lockup.createWithTimestampsLT(params, tranches_);
    }

    function createDefaultStreamWithRecipientLT(address recipient) internal returns (uint256 streamId) {
        Lockup.CreateWithTimestamps memory params = _params.createWithTimestamps;
        params.recipient = recipient;
        streamId = lockup.createWithTimestampsLT(params, _params.tranches);
    }

    /// @dev Creates the default stream with the provided tranches.
    function createDefaultStreamWithTranchesLT(LockupTranched.Tranche[] memory tranches)
        internal
        returns (uint256 streamId)
    {
        streamId = lockup.createWithTimestampsLT(_params.createWithTimestamps, tranches);
    }

    function createDefaultStreamWithSenderLT(address sender) internal returns (uint256 streamId) {
        Lockup.CreateWithTimestamps memory params = _params.createWithTimestamps;
        params.sender = sender;
        streamId = lockup.createWithTimestampsLT(params, _params.tranches);
    }

    function createDefaultStreamWithStartTimeLT(uint40 startTime) internal returns (uint256 streamId) {
        Lockup.CreateWithTimestamps memory params = _params.createWithTimestamps;
        params.startTime = startTime;
        streamId = lockup.createWithTimestampsLT(params, _params.tranches);
    }

    function createDefaultStreamWithTotalAmountLT(uint128 totalAmount) internal returns (uint256 streamId) {
        Lockup.CreateWithTimestamps memory params = _params.createWithTimestamps;
        params.totalAmount = totalAmount;
        streamId = lockup.createWithTimestampsLT(params, _params.tranches);
    }

    function createDefaultStreamWithUsersLT(address recipient, address sender) internal returns (uint256 streamId) {
        Lockup.CreateWithTimestamps memory params = _params.createWithTimestamps;
        params.recipient = recipient;
        params.sender = sender;
        streamId = lockup.createWithTimestampsLT(params, _params.tranches);
    }

    /// @dev The following two functions are used in `CancelMultiple` and `WithdrawMultiple` tests.
    function WarpAndCreateStreamsForCancelMultipleLT(uint40 warpTime) internal returns (uint256[2] memory streamIds) {
        vm.warp({ newTimestamp: warpTime });

        // Create the first stream.
        streamIds[0] = createDefaultStreamLT();
        // Create the second stream with an end time double that of the default stream so that the refund amounts are
        // different.
        streamIds[1] = createDefaultStreamWithEndTimeLT(defaults.END_TIME() + defaults.TOTAL_DURATION());
    }

    function WarpAndCreateStreamsWithdrawMultipleLT(uint40 warpTime) internal returns (uint256[3] memory streamIds) {
        vm.warp({ newTimestamp: warpTime });

        // Create three test streams:
        // 1. A default stream
        // 2. A stream with an early end time
        // 3. A stream meant to be canceled before the withdrawal is made
        streamIds[0] = createDefaultStreamLT();
        streamIds[1] = createDefaultStreamWithEndTimeLT(defaults.WARP_26_PERCENT());
        streamIds[2] = createDefaultStreamLT();
    }
}
