// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

import { Broker, LockupDynamic } from "src/types/DataTypes.sol";

import { Lockup_Integration_Shared_Test } from "../lockup/Lockup.t.sol";

/// @title Dynamic_Integration_Shared_Test
/// @notice Common testing logic needed across {SablierV2LockupDynamic} integration tests.
abstract contract Dynamic_Integration_Shared_Test is Lockup_Integration_Shared_Test {
    struct CreateParams {
        LockupDynamic.CreateWithDeltas createWithDeltas;
        LockupDynamic.CreateWithMilestones createWithMilestones;
    }

    /// @dev These have to be pre-declared so that `vm.expectRevert` does not expect a revert in `defaults`.
    /// See https://github.com/foundry-rs/foundry/issues/4762.
    CreateParams private _params;

    function setUp() public virtual override {
        Lockup_Integration_Shared_Test.setUp();

        _params.createWithDeltas.sender = users.sender;
        _params.createWithDeltas.recipient = users.recipient;
        _params.createWithDeltas.totalAmount = defaults.TOTAL_AMOUNT();
        _params.createWithDeltas.asset = dai;
        _params.createWithDeltas.cancelable = true;
        _params.createWithDeltas.broker = defaults.broker();

        _params.createWithMilestones.sender = users.sender;
        _params.createWithMilestones.recipient = users.recipient;
        _params.createWithMilestones.totalAmount = defaults.TOTAL_AMOUNT();
        _params.createWithMilestones.asset = dai;
        _params.createWithMilestones.cancelable = true;
        _params.createWithMilestones.startTime = defaults.START_TIME();
        _params.createWithMilestones.broker = defaults.broker();

        // See https://github.com/ethereum/solidity/issues/12783
        LockupDynamic.SegmentWithDelta[] memory segmentsWithDeltas = defaults.segmentsWithDeltas();
        LockupDynamic.Segment[] memory segments = defaults.segments();
        for (uint256 i = 0; i < defaults.SEGMENT_COUNT(); ++i) {
            _params.createWithDeltas.segments.push(segmentsWithDeltas[i]);
            _params.createWithMilestones.segments.push(segments[i]);
        }
    }

    /// @dev Creates the default stream.
    function createDefaultStream() internal override returns (uint256 streamId) {
        streamId = dynamic.createWithMilestones(_params.createWithMilestones);
    }

    /// @dev Creates the default stream with the provided asset.
    function createDefaultStreamWithAsset(IERC20 asset) internal override returns (uint256 streamId) {
        LockupDynamic.CreateWithMilestones memory params = _params.createWithMilestones;
        params.asset = asset;
        streamId = dynamic.createWithMilestones(params);
    }

    /// @dev Creates the default stream with the provided broker.
    function createDefaultStreamWithBroker(Broker memory broker) internal override returns (uint256 streamId) {
        LockupDynamic.CreateWithMilestones memory params = _params.createWithMilestones;
        params.broker = broker;
        streamId = dynamic.createWithMilestones(params);
    }

    /// @dev Creates the default stream with deltas.
    function createDefaultStreamWithDeltas() internal returns (uint256 streamId) {
        streamId = dynamic.createWithDeltas(_params.createWithDeltas);
    }

    /// @dev Creates the default stream with the provided deltas.
    function createDefaultStreamWithDeltas(LockupDynamic.SegmentWithDelta[] memory segments)
        internal
        returns (uint256 streamId)
    {
        LockupDynamic.CreateWithDeltas memory params = _params.createWithDeltas;
        params.segments = segments;
        streamId = dynamic.createWithDeltas(params);
    }

    /// @dev Creates the default stream with the provided end time.
    function createDefaultStreamWithEndTime(uint40 endTime) internal override returns (uint256 streamId) {
        LockupDynamic.CreateWithMilestones memory params = _params.createWithMilestones;
        params.segments[1].milestone = endTime;
        streamId = dynamic.createWithMilestones(params);
    }

    /// @dev Creates a stream that will not be cancelable.
    function createDefaultStreamNotCancelable() internal override returns (uint256 streamId) {
        LockupDynamic.CreateWithMilestones memory params = _params.createWithMilestones;
        params.cancelable = false;
        streamId = dynamic.createWithMilestones(params);
    }

    /// @dev Creates the default stream with the provided range.
    function createDefaultStreamWithRange(LockupDynamic.Range memory range) internal returns (uint256 streamId) {
        LockupDynamic.CreateWithMilestones memory params = _params.createWithMilestones;
        params.startTime = range.start;
        params.segments[1].milestone = range.end;
        streamId = dynamic.createWithMilestones(params);
    }

    /// @dev Creates the default stream with the provided recipient.
    function createDefaultStreamWithRecipient(address recipient) internal override returns (uint256 streamId) {
        LockupDynamic.CreateWithMilestones memory params = _params.createWithMilestones;
        params.recipient = recipient;
        streamId = dynamic.createWithMilestones(params);
    }

    /// @dev Creates the default stream with the provided segments.
    function createDefaultStreamWithSegments(LockupDynamic.Segment[] memory segments)
        internal
        returns (uint256 streamId)
    {
        LockupDynamic.CreateWithMilestones memory params = _params.createWithMilestones;
        params.segments = segments;
        streamId = dynamic.createWithMilestones(params);
    }

    /// @dev Creates the default stream with the provided sender.
    function createDefaultStreamWithSender(address sender) internal override returns (uint256 streamId) {
        LockupDynamic.CreateWithMilestones memory params = _params.createWithMilestones;
        params.sender = sender;
        streamId = dynamic.createWithMilestones(params);
    }

    /// @dev Creates the default stream with the provided start time..
    function createDefaultStreamWithStartTime(uint40 startTime) internal override returns (uint256 streamId) {
        LockupDynamic.CreateWithMilestones memory params = _params.createWithMilestones;
        params.startTime = startTime;
        streamId = dynamic.createWithMilestones(params);
    }

    /// @dev Creates the default stream with the provided total amount.
    function createDefaultStreamWithTotalAmount(uint128 totalAmount) internal override returns (uint256 streamId) {
        LockupDynamic.CreateWithMilestones memory params = _params.createWithMilestones;
        params.totalAmount = totalAmount;
        streamId = dynamic.createWithMilestones(params);
    }
}
