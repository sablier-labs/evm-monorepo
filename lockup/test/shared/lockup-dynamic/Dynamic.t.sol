// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

import { Broker, LockupDynamic } from "../../../src/types/DataTypes.sol";

import { Lockup_Shared_Test } from "../lockup/Lockup.t.sol";

/// @title Dynamic_Shared_Test
/// @notice Common testing logic needed across {SablierV2LockupDynamic} unit and fuzz tests.
abstract contract Dynamic_Shared_Test is Lockup_Shared_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                      STRUCTS
    //////////////////////////////////////////////////////////////////////////*/

    struct DefaultParams {
        LockupDynamic.CreateWithDeltas createWithDeltas;
        LockupDynamic.CreateWithMilestones createWithMilestones;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    LockupDynamic.Stream internal defaultStream;
    DefaultParams internal defaultParams;

    /*//////////////////////////////////////////////////////////////////////////
                                  SET-UP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        // Initialize the default params to be used for the create functions.
        defaultParams.createWithDeltas.sender = users.sender;
        defaultParams.createWithDeltas.recipient = users.recipient;
        defaultParams.createWithDeltas.totalAmount = defaults.TOTAL_AMOUNT();
        defaultParams.createWithDeltas.asset = usdc;
        defaultParams.createWithDeltas.cancelable = true;
        defaultParams.createWithDeltas.broker = Broker({ account: users.broker, fee: defaults.BROKER_FEE() });

        defaultParams.createWithMilestones.sender = users.sender;
        defaultParams.createWithMilestones.recipient = users.recipient;
        defaultParams.createWithMilestones.totalAmount = defaults.TOTAL_AMOUNT();
        defaultParams.createWithMilestones.asset = usdc;
        defaultParams.createWithMilestones.cancelable = true;
        defaultParams.createWithMilestones.startTime = defaults.START_TIME();
        defaultParams.createWithMilestones.broker = Broker({ account: users.broker, fee: defaults.BROKER_FEE() });

        // See https://github.com/ethereum/solidity/issues/12783
        LockupDynamic.SegmentWithDelta[] memory segmentsWithDeltas = defaults.segmentsWithDeltas();
        LockupDynamic.Segment[] memory segments = defaults.segments();
        for (uint256 i = 0; i < defaults.SEGMENT_COUNT(); ++i) {
            defaultParams.createWithDeltas.segments.push(segmentsWithDeltas[i]);
            defaultParams.createWithMilestones.segments.push(segments[i]);
        }

        // Create the default stream to be used across all tests.
        defaultStream.amounts = defaults.lockupAmounts();
        defaultStream.endTime = defaults.END_TIME();
        defaultStream.isCancelable = defaultParams.createWithMilestones.cancelable;
        defaultStream.isStream = true;
        defaultStream.segments = defaultParams.createWithMilestones.segments;
        defaultStream.sender = defaultParams.createWithMilestones.sender;
        defaultStream.startTime = defaults.START_TIME();
        defaultStream.asset = defaultParams.createWithMilestones.asset;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                      HELPERS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Creates the default stream.
    function createDefaultStream() internal override returns (uint256 streamId) {
        streamId = dynamic.createWithMilestones(defaultParams.createWithMilestones);
    }

    /// @dev Creates the default stream with the provided asset.
    function createDefaultStreamWithAsset(IERC20 asset) internal override returns (uint256 streamId) {
        LockupDynamic.CreateWithMilestones memory params = defaultParams.createWithMilestones;
        params.asset = asset;
        streamId = dynamic.createWithMilestones(params);
    }

    /// @dev Creates the default stream with the provided broker.
    function createDefaultStreamWithBroker(Broker memory broker) internal override returns (uint256 streamId) {
        LockupDynamic.CreateWithMilestones memory params = defaultParams.createWithMilestones;
        params.broker = broker;
        streamId = dynamic.createWithMilestones(params);
    }

    /// @dev Creates the default stream with deltas.
    function createDefaultStreamWithDeltas() internal returns (uint256 streamId) {
        streamId = dynamic.createWithDeltas(defaultParams.createWithDeltas);
    }

    /// @dev Creates the default stream with the provided deltas.
    function createDefaultStreamWithDeltas(LockupDynamic.SegmentWithDelta[] memory segments)
        internal
        returns (uint256 streamId)
    {
        LockupDynamic.CreateWithDeltas memory params = defaultParams.createWithDeltas;
        params.segments = segments;
        streamId = dynamic.createWithDeltas(params);
    }

    /// @dev Creates the default stream with the provided end time.
    function createDefaultStreamWithEndTime(uint40 endTime) internal override returns (uint256 streamId) {
        LockupDynamic.CreateWithMilestones memory params = defaultParams.createWithMilestones;
        params.segments[1].milestone = endTime;
        streamId = dynamic.createWithMilestones(params);
    }

    /// @dev Creates a stream that will not be cancelable.
    function createDefaultStreamNotCancelable() internal override returns (uint256 streamId) {
        LockupDynamic.CreateWithMilestones memory params = defaultParams.createWithMilestones;
        params.cancelable = false;
        streamId = dynamic.createWithMilestones(params);
    }

    /// @dev Creates the default stream with the provided range.
    function createDefaultStreamWithRange(LockupDynamic.Range memory range) internal returns (uint256 streamId) {
        LockupDynamic.CreateWithMilestones memory params = defaultParams.createWithMilestones;
        params.startTime = range.start;
        params.segments[1].milestone = range.end;
        streamId = dynamic.createWithMilestones(params);
    }

    /// @dev Creates the default stream with the provided recipient.
    function createDefaultStreamWithRecipient(address recipient) internal override returns (uint256 streamId) {
        LockupDynamic.CreateWithMilestones memory params = defaultParams.createWithMilestones;
        params.recipient = recipient;
        streamId = dynamic.createWithMilestones(params);
    }

    /// @dev Creates the default stream with the provided segments.
    function createDefaultStreamWithSegments(LockupDynamic.Segment[] memory segments)
        internal
        returns (uint256 streamId)
    {
        LockupDynamic.CreateWithMilestones memory params = defaultParams.createWithMilestones;
        params.segments = segments;
        streamId = dynamic.createWithMilestones(params);
    }

    /// @dev Creates the default stream with the provided sender.
    function createDefaultStreamWithSender(address sender) internal override returns (uint256 streamId) {
        LockupDynamic.CreateWithMilestones memory params = defaultParams.createWithMilestones;
        params.sender = sender;
        streamId = dynamic.createWithMilestones(params);
    }

    /// @dev Creates the default stream with the provided start time..
    function createDefaultStreamWithStartTime(uint40 startTime) internal override returns (uint256 streamId) {
        LockupDynamic.CreateWithMilestones memory params = defaultParams.createWithMilestones;
        params.startTime = startTime;
        streamId = dynamic.createWithMilestones(params);
    }

    /// @dev Creates the default stream with the provided total amount.
    function createDefaultStreamWithTotalAmount(uint128 totalAmount) internal returns (uint256 streamId) {
        LockupDynamic.CreateWithMilestones memory params = defaultParams.createWithMilestones;
        params.totalAmount = totalAmount;
        streamId = dynamic.createWithMilestones(params);
    }
}
