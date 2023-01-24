// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { PRBMathCastingUint128 as CastingUint128 } from "@prb/math/casting/Uint128.sol";
import { PRBMathCastingUint40 as CastingUint40 } from "@prb/math/casting/Uint40.sol";
import { ud2x18, UD2x18 } from "@prb/math/UD2x18.sol";
import { sd, SD59x18 } from "@prb/math/SD59x18.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";

import { Status } from "src/types/Enums.sol";
import { LockupAmounts, Broker, LockupProStream, Segment } from "src/types/Structs.sol";
import { SablierV2LockupPro } from "src/SablierV2LockupPro.sol";

import { Lockup_Test } from "test/unit/lockup/Lockup.t.sol";
import { Unit_Test } from "test/unit/Unit.t.sol";

/// @title Pro_Test
/// @notice Common testing logic needed across SablierV2LockupPro unit tests.
abstract contract Pro_Test is Lockup_Test {
    using CastingUint128 for uint128;
    using CastingUint40 for uint40;

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
                                  TESTING VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    LockupProStream internal defaultStream;
    DefaultParams internal params;

    /*//////////////////////////////////////////////////////////////////////////
                                   SETUP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        Unit_Test.setUp();

        // Initialize the default params to be used for the create functions.
        params.createWithDeltas.sender = users.sender;
        params.createWithDeltas.recipient = users.recipient;
        params.createWithDeltas.grossDepositAmount = DEFAULT_GROSS_DEPOSIT_AMOUNT;
        params.createWithDeltas.asset = dai;
        params.createWithDeltas.cancelable = true;
        params.createWithDeltas.broker = Broker({ addr: users.broker, fee: DEFAULT_BROKER_FEE });

        params.createWithMilestones.sender = users.sender;
        params.createWithMilestones.recipient = users.recipient;
        params.createWithMilestones.grossDepositAmount = DEFAULT_GROSS_DEPOSIT_AMOUNT;
        params.createWithMilestones.asset = dai;
        params.createWithMilestones.cancelable = true;
        params.createWithMilestones.startTime = DEFAULT_START_TIME;
        params.createWithMilestones.broker = Broker({ addr: users.broker, fee: DEFAULT_BROKER_FEE });

        // See https://github.com/ethereum/solidity/issues/12783
        for (uint256 i = 0; i < DEFAULT_SEGMENTS.length; ++i) {
            params.createWithDeltas.segments.push(DEFAULT_SEGMENTS[i]);
            params.createWithDeltas.deltas.push(DEFAULT_SEGMENT_DELTAS[i]);
            params.createWithMilestones.segments.push(DEFAULT_SEGMENTS[i]);
        }

        // Create the default stream to be used across the tests.
        defaultStream.amounts = DEFAULT_AMOUNTS;
        defaultStream.isCancelable = params.createWithMilestones.cancelable;
        defaultStream.segments = params.createWithMilestones.segments;
        defaultStream.sender = params.createWithMilestones.sender;
        defaultStream.startTime = params.createWithMilestones.startTime;
        defaultStream.status = Status.ACTIVE;
        defaultStream.stopTime = DEFAULT_STOP_TIME;
        defaultStream.asset = params.createWithMilestones.asset;

        // Set the default protocol fee.
        comptroller.setProtocolFee(dai, DEFAULT_PROTOCOL_FEE);
        comptroller.setProtocolFee(IERC20(address(nonCompliantAsset)), DEFAULT_PROTOCOL_FEE);

        // Make the sender the default caller in all subsequent tests.
        changePrank(users.sender);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Helper function that replicates the logic of the `calculateStreamedAmountForMultipleSegments`.
    function calculateStreamedAmountForMultipleSegments(
        uint40 currentTime,
        Segment[] memory segments,
        uint128 depositAmount
    ) internal view returns (uint128 streamedAmount) {
        if (currentTime >= segments[segments.length - 1].milestone) {
            return depositAmount;
        }

        unchecked {
            // Sum up the amounts found in all preceding segments.
            uint128 previousSegmentAmounts;
            uint40 currentSegmentMilestone = segments[0].milestone;
            uint256 index = 1;
            while (currentSegmentMilestone < currentTime) {
                previousSegmentAmounts += segments[index - 1].amount;
                currentSegmentMilestone = segments[index].milestone;
                index += 1;
            }

            // After the loop exits, the current segment is found at index `index - 1`, whereas the previous segment
            // is found at `index - 2` (if there are at least two segments).
            SD59x18 currentSegmentAmount = segments[index - 1].amount.intoSD59x18();
            SD59x18 currentSegmentExponent = segments[index - 1].exponent.intoSD59x18();
            currentSegmentMilestone = segments[index - 1].milestone;

            uint40 previousMilestone;
            if (index > 1) {
                // If the current segment is at an index that is >= 2, we use the previous segment's milestone.
                previousMilestone = segments[index - 2].milestone;
            } else {
                // Otherwise, there is only one segment, so we use the start of the stream as the previous milestone.
                previousMilestone = DEFAULT_START_TIME;
            }

            // Calculate how much time has elapsed since the segment started, and the total time of the segment.
            SD59x18 elapsedSegmentTime = (currentTime - previousMilestone).intoSD59x18();
            SD59x18 totalSegmentTime = (currentSegmentMilestone - previousMilestone).intoSD59x18();

            // Calculate the streamed amount.
            SD59x18 elapsedSegmentTimePercentage = elapsedSegmentTime.div(totalSegmentTime);
            SD59x18 multiplier = elapsedSegmentTimePercentage.pow(currentSegmentExponent);
            streamedAmount = previousSegmentAmounts + uint128(multiplier.mul(currentSegmentAmount).intoUint256());
        }
    }

    /// @dev Helper function that replicates the logic of the `calculateStreamedAmountForOneSegment`.
    function calculateStreamedAmountForOneSegment(
        uint40 currentTime,
        UD2x18 exponent,
        uint128 depositAmount
    ) internal view returns (uint128 streamedAmount) {
        if (currentTime >= DEFAULT_STOP_TIME) {
            return depositAmount;
        }
        unchecked {
            // Calculate how much time has elapsed since the stream started, and the total time of the stream.
            SD59x18 elapsedTime = (currentTime - DEFAULT_START_TIME).intoSD59x18();
            SD59x18 totalTime = DEFAULT_TOTAL_DURATION.intoSD59x18();

            // Calculate the streamed amount.
            SD59x18 elapsedTimePercentage = elapsedTime.div(totalTime);
            SD59x18 multiplier = elapsedTimePercentage.pow(exponent.intoSD59x18());
            streamedAmount = uint128(multiplier.mul(depositAmount.intoSD59x18()).intoUint256());
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                               NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Creates the default stream.
    function createDefaultStream() internal override returns (uint256 streamId) {
        streamId = pro.createWithMilestones(
            params.createWithMilestones.sender,
            params.createWithMilestones.recipient,
            params.createWithMilestones.grossDepositAmount,
            params.createWithMilestones.segments,
            params.createWithMilestones.asset,
            params.createWithMilestones.cancelable,
            params.createWithMilestones.startTime,
            params.createWithMilestones.broker
        );
    }

    /// @dev Creates the default stream with deltas.
    function createDefaultStreamWithDeltas() internal returns (uint256 streamId) {
        streamId = pro.createWithDeltas(
            params.createWithDeltas.sender,
            params.createWithDeltas.recipient,
            params.createWithDeltas.grossDepositAmount,
            params.createWithDeltas.segments,
            params.createWithDeltas.asset,
            params.createWithDeltas.cancelable,
            params.createWithDeltas.deltas,
            params.createWithDeltas.broker
        );
    }

    /// @dev Creates the default stream with the provided deltas.
    function createDefaultStreamWithDeltas(uint40[] memory deltas) internal returns (uint256 streamId) {
        streamId = pro.createWithDeltas(
            params.createWithDeltas.sender,
            params.createWithDeltas.recipient,
            params.createWithDeltas.grossDepositAmount,
            params.createWithDeltas.segments,
            params.createWithDeltas.asset,
            params.createWithDeltas.cancelable,
            deltas,
            params.createWithDeltas.broker
        );
    }

    /// @dev Creates the default stream with the provided gross deposit amount.
    function createDefaultStreamWithGrossDepositAmount(uint128 grossDepositAmount) internal returns (uint256 streamId) {
        streamId = pro.createWithMilestones(
            params.createWithMilestones.sender,
            params.createWithMilestones.recipient,
            grossDepositAmount,
            params.createWithMilestones.segments,
            params.createWithMilestones.asset,
            params.createWithMilestones.cancelable,
            params.createWithMilestones.startTime,
            params.createWithMilestones.broker
        );
    }

    /// @dev Creates a non-cancelable stream.
    function createDefaultStreamNonCancelable() internal override returns (uint256 streamId) {
        bool isCancelable = false;
        streamId = pro.createWithMilestones(
            params.createWithMilestones.sender,
            params.createWithMilestones.recipient,
            params.createWithMilestones.grossDepositAmount,
            params.createWithMilestones.segments,
            params.createWithMilestones.asset,
            isCancelable,
            params.createWithMilestones.startTime,
            params.createWithMilestones.broker
        );
    }

    /// @dev Creates the default stream with the provided recipient.
    function createDefaultStreamWithRecipient(address recipient) internal override returns (uint256 streamId) {
        streamId = pro.createWithMilestones(
            params.createWithMilestones.sender,
            recipient,
            params.createWithMilestones.grossDepositAmount,
            params.createWithMilestones.segments,
            params.createWithMilestones.asset,
            params.createWithMilestones.cancelable,
            params.createWithMilestones.startTime,
            params.createWithMilestones.broker
        );
    }

    /// @dev Creates the default stream with the provided segments.
    function createDefaultStreamWithSegments(Segment[] memory segments) internal returns (uint256 streamId) {
        streamId = pro.createWithMilestones(
            params.createWithMilestones.sender,
            params.createWithMilestones.recipient,
            params.createWithMilestones.grossDepositAmount,
            segments,
            params.createWithMilestones.asset,
            params.createWithMilestones.cancelable,
            params.createWithMilestones.startTime,
            params.createWithMilestones.broker
        );
    }

    /// @dev Creates the default stream with the provided sender.
    function createDefaultStreamWithSender(address sender) internal override returns (uint256 streamId) {
        streamId = pro.createWithMilestones(
            sender,
            params.createWithMilestones.recipient,
            params.createWithMilestones.grossDepositAmount,
            params.createWithMilestones.segments,
            params.createWithMilestones.asset,
            params.createWithMilestones.cancelable,
            params.createWithMilestones.startTime,
            params.createWithMilestones.broker
        );
    }

    /// @dev Creates the default stream with the provided stop time. In this case, the last milestone is the stop time.
    function createDefaultStreamWithStopTime(uint40 stopTime) internal override returns (uint256 streamId) {
        Segment[] memory segments = params.createWithMilestones.segments;
        segments[1].milestone = stopTime;
        streamId = pro.createWithMilestones(
            params.createWithMilestones.sender,
            params.createWithMilestones.recipient,
            params.createWithMilestones.grossDepositAmount,
            segments,
            params.createWithMilestones.asset,
            params.createWithMilestones.cancelable,
            params.createWithMilestones.startTime,
            params.createWithMilestones.broker
        );
    }
}
