// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

import { Status } from "src/types/Enums.sol";
import { Broker, LockupAmounts, LockupProStream, Segment } from "src/types/Structs.sol";

import { Lockup_Shared_Test } from "test/shared/lockup/Lockup.t.sol";

/// @title Pro_Shared_Test
/// @notice Common testing logic needed across {SablierV2LockupPro} unit and fuzz tests.
abstract contract Pro_Shared_Test is Lockup_Shared_Test {
    /*//////////////////////////////////////////////////////////////////////////
                                      STRUCTS
    //////////////////////////////////////////////////////////////////////////*/

    struct CreateWithDeltasParams {
        address sender;
        address recipient;
        uint128 grossDepositAmount;
        Segment[] segments;
        IERC20 asset;
        bool cancelable;
        uint40[] deltas;
        Broker broker;
    }

    struct CreateWithMilestonesParams {
        address sender;
        address recipient;
        uint128 grossDepositAmount;
        Segment[] segments;
        IERC20 asset;
        bool cancelable;
        uint40 startTime;
        Broker broker;
    }

    struct DefaultParams {
        CreateWithDeltasParams createWithDeltas;
        CreateWithMilestonesParams createWithMilestones;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                   TEST VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    LockupProStream internal defaultStream;
    DefaultParams internal defaultParams;

    /*//////////////////////////////////////////////////////////////////////////
                                   SETUP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Lockup_Shared_Test.setUp();

        // Initialize the default params to be used for the create functions.
        defaultParams.createWithDeltas.sender = users.sender;
        defaultParams.createWithDeltas.recipient = users.recipient;
        defaultParams.createWithDeltas.grossDepositAmount = DEFAULT_GROSS_DEPOSIT_AMOUNT;
        defaultParams.createWithDeltas.asset = DEFAULT_ASSET;
        defaultParams.createWithDeltas.cancelable = true;
        defaultParams.createWithDeltas.broker = Broker({ addr: users.broker, fee: DEFAULT_BROKER_FEE });

        defaultParams.createWithMilestones.sender = users.sender;
        defaultParams.createWithMilestones.recipient = users.recipient;
        defaultParams.createWithMilestones.grossDepositAmount = DEFAULT_GROSS_DEPOSIT_AMOUNT;
        defaultParams.createWithMilestones.asset = DEFAULT_ASSET;
        defaultParams.createWithMilestones.cancelable = true;
        defaultParams.createWithMilestones.startTime = DEFAULT_START_TIME;
        defaultParams.createWithMilestones.broker = Broker({ addr: users.broker, fee: DEFAULT_BROKER_FEE });

        // See https://github.com/ethereum/solidity/issues/12783
        for (uint256 i = 0; i < DEFAULT_SEGMENTS.length; ++i) {
            defaultParams.createWithDeltas.segments.push(DEFAULT_SEGMENTS[i]);
            defaultParams.createWithDeltas.deltas.push(DEFAULT_SEGMENT_DELTAS[i]);
            defaultParams.createWithMilestones.segments.push(DEFAULT_SEGMENTS[i]);
        }

        // Create the default stream to be used across the tests.
        defaultStream.amounts = DEFAULT_LOCKUP_AMOUNTS;
        defaultStream.isCancelable = defaultParams.createWithMilestones.cancelable;
        defaultStream.segments = defaultParams.createWithMilestones.segments;
        defaultStream.sender = defaultParams.createWithMilestones.sender;
        defaultStream.startTime = defaultParams.createWithMilestones.startTime;
        defaultStream.status = Status.ACTIVE;
        defaultStream.stopTime = DEFAULT_STOP_TIME;
        defaultStream.asset = defaultParams.createWithMilestones.asset;
    }

    /*//////////////////////////////////////////////////////////////////////////
                               NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Creates the default stream.
    function createDefaultStream() internal override returns (uint256 streamId) {
        streamId = pro.createWithMilestones(
            defaultParams.createWithMilestones.sender,
            defaultParams.createWithMilestones.recipient,
            defaultParams.createWithMilestones.grossDepositAmount,
            defaultParams.createWithMilestones.segments,
            defaultParams.createWithMilestones.asset,
            defaultParams.createWithMilestones.cancelable,
            defaultParams.createWithMilestones.startTime,
            defaultParams.createWithMilestones.broker
        );
    }

    /// @dev Creates the default stream with deltas.
    function createDefaultStreamWithDeltas() internal returns (uint256 streamId) {
        streamId = pro.createWithDeltas(
            defaultParams.createWithDeltas.sender,
            defaultParams.createWithDeltas.recipient,
            defaultParams.createWithDeltas.grossDepositAmount,
            defaultParams.createWithDeltas.segments,
            defaultParams.createWithDeltas.asset,
            defaultParams.createWithDeltas.cancelable,
            defaultParams.createWithDeltas.deltas,
            defaultParams.createWithDeltas.broker
        );
    }

    /// @dev Creates the default stream with the provided deltas.
    function createDefaultStreamWithDeltas(uint40[] memory deltas) internal returns (uint256 streamId) {
        streamId = pro.createWithDeltas(
            defaultParams.createWithDeltas.sender,
            defaultParams.createWithDeltas.recipient,
            defaultParams.createWithDeltas.grossDepositAmount,
            defaultParams.createWithDeltas.segments,
            defaultParams.createWithDeltas.asset,
            defaultParams.createWithDeltas.cancelable,
            deltas,
            defaultParams.createWithDeltas.broker
        );
    }

    /// @dev Creates the default stream with the provided gross deposit amount.
    function createDefaultStreamWithGrossDepositAmount(uint128 grossDepositAmount) internal returns (uint256 streamId) {
        streamId = pro.createWithMilestones(
            defaultParams.createWithMilestones.sender,
            defaultParams.createWithMilestones.recipient,
            grossDepositAmount,
            defaultParams.createWithMilestones.segments,
            defaultParams.createWithMilestones.asset,
            defaultParams.createWithMilestones.cancelable,
            defaultParams.createWithMilestones.startTime,
            defaultParams.createWithMilestones.broker
        );
    }

    /// @dev Creates a non-cancelable stream.
    function createDefaultStreamNonCancelable() internal override returns (uint256 streamId) {
        bool isCancelable = false;
        streamId = pro.createWithMilestones(
            defaultParams.createWithMilestones.sender,
            defaultParams.createWithMilestones.recipient,
            defaultParams.createWithMilestones.grossDepositAmount,
            defaultParams.createWithMilestones.segments,
            defaultParams.createWithMilestones.asset,
            isCancelable,
            defaultParams.createWithMilestones.startTime,
            defaultParams.createWithMilestones.broker
        );
    }

    /// @dev Creates the default stream with the provided recipient.
    function createDefaultStreamWithRecipient(address recipient) internal override returns (uint256 streamId) {
        streamId = pro.createWithMilestones(
            defaultParams.createWithMilestones.sender,
            recipient,
            defaultParams.createWithMilestones.grossDepositAmount,
            defaultParams.createWithMilestones.segments,
            defaultParams.createWithMilestones.asset,
            defaultParams.createWithMilestones.cancelable,
            defaultParams.createWithMilestones.startTime,
            defaultParams.createWithMilestones.broker
        );
    }

    /// @dev Creates the default stream with the provided segments.
    function createDefaultStreamWithSegments(Segment[] memory segments) internal returns (uint256 streamId) {
        streamId = pro.createWithMilestones(
            defaultParams.createWithMilestones.sender,
            defaultParams.createWithMilestones.recipient,
            defaultParams.createWithMilestones.grossDepositAmount,
            segments,
            defaultParams.createWithMilestones.asset,
            defaultParams.createWithMilestones.cancelable,
            defaultParams.createWithMilestones.startTime,
            defaultParams.createWithMilestones.broker
        );
    }

    /// @dev Creates the default stream with the provided sender.
    function createDefaultStreamWithSender(address sender) internal override returns (uint256 streamId) {
        streamId = pro.createWithMilestones(
            sender,
            defaultParams.createWithMilestones.recipient,
            defaultParams.createWithMilestones.grossDepositAmount,
            defaultParams.createWithMilestones.segments,
            defaultParams.createWithMilestones.asset,
            defaultParams.createWithMilestones.cancelable,
            defaultParams.createWithMilestones.startTime,
            defaultParams.createWithMilestones.broker
        );
    }

    /// @dev Creates the default stream with the provided stop time. In this case, the last milestone is the stop time.
    function createDefaultStreamWithStopTime(uint40 stopTime) internal override returns (uint256 streamId) {
        Segment[] memory segments = defaultParams.createWithMilestones.segments;
        segments[1].milestone = stopTime;
        streamId = pro.createWithMilestones(
            defaultParams.createWithMilestones.sender,
            defaultParams.createWithMilestones.recipient,
            defaultParams.createWithMilestones.grossDepositAmount,
            segments,
            defaultParams.createWithMilestones.asset,
            defaultParams.createWithMilestones.cancelable,
            defaultParams.createWithMilestones.startTime,
            defaultParams.createWithMilestones.broker
        );
    }
}
