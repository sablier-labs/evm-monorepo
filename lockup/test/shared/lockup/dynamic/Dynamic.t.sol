// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

import { Broker, Lockup, LockupDynamic } from "../../../../src/types/DataTypes.sol";

import { Lockup_Shared_Test } from "../Lockup.t.sol";

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
        Lockup_Shared_Test.setUp();

        // Initialize the default params to be used for the create functions.
        defaultParams.createWithDeltas.sender = users.sender;
        defaultParams.createWithDeltas.recipient = users.recipient;
        defaultParams.createWithDeltas.totalAmount = DEFAULT_TOTAL_AMOUNT;
        defaultParams.createWithDeltas.asset = DEFAULT_ASSET;
        defaultParams.createWithDeltas.cancelable = true;
        defaultParams.createWithDeltas.broker = Broker({ account: users.broker, fee: DEFAULT_BROKER_FEE });

        defaultParams.createWithMilestones.sender = users.sender;
        defaultParams.createWithMilestones.recipient = users.recipient;
        defaultParams.createWithMilestones.totalAmount = DEFAULT_TOTAL_AMOUNT;
        defaultParams.createWithMilestones.asset = DEFAULT_ASSET;
        defaultParams.createWithMilestones.cancelable = true;
        defaultParams.createWithMilestones.startTime = DEFAULT_START_TIME;
        defaultParams.createWithMilestones.broker = Broker({ account: users.broker, fee: DEFAULT_BROKER_FEE });

        // See https://github.com/ethereum/solidity/issues/12783
        for (uint256 i = 0; i < DEFAULT_SEGMENTS.length; ++i) {
            defaultParams.createWithDeltas.segments.push(DEFAULT_SEGMENTS_WITH_DELTAS[i]);
            defaultParams.createWithMilestones.segments.push(DEFAULT_SEGMENTS[i]);
        }

        // Create the default stream to be used across the tests.
        defaultStream.amounts = DEFAULT_LOCKUP_AMOUNTS;
        defaultStream.endTime = DEFAULT_END_TIME;
        defaultStream.isCancelable = defaultParams.createWithMilestones.cancelable;
        defaultStream.segments = defaultParams.createWithMilestones.segments;
        defaultStream.sender = defaultParams.createWithMilestones.sender;
        defaultStream.startTime = DEFAULT_START_TIME;
        defaultStream.status = Lockup.Status.ACTIVE;
        defaultStream.asset = defaultParams.createWithMilestones.asset;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  HELPER FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Creates the default stream.
    function createDefaultStream() internal override returns (uint256 streamId) {
        streamId = dynamic.createWithMilestones(defaultParams.createWithMilestones);
    }

    /// @dev Creates the default stream with the provided broker.
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

    /// @dev Creates a non-cancelable stream.
    function createDefaultStreamNonCancelable() internal override returns (uint256 streamId) {
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
