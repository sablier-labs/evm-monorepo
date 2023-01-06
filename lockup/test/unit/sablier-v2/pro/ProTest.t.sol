// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { SD1x18 } from "@prb/math/SD1x18.sol";
import { SD59x18 } from "@prb/math/SD59x18.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";

import { Amounts, Broker, ProStream, Segment } from "src/types/Structs.sol";
import { SablierV2Pro } from "src/SablierV2Pro.sol";

import { SablierV2Test } from "test/unit/sablier-v2/SablierV2.t.sol";
import { UnitTest } from "test/unit/UnitTest.t.sol";

/// @title ProTest
/// @notice Common testing logic needed across SablierV2Pro unit tests.
abstract contract ProTest is SablierV2Test {
    /*//////////////////////////////////////////////////////////////////////////
                                      STRUCTS
    //////////////////////////////////////////////////////////////////////////*/

    struct CreateWithDeltasParams {
        address sender;
        address recipient;
        uint128 grossDepositAmount;
        Segment[] segments;
        IERC20 token;
        bool cancelable;
        uint40[] deltas;
        Broker broker;
    }

    struct CreateWithMilestonesParams {
        address sender;
        address recipient;
        uint128 grossDepositAmount;
        Segment[] segments;
        IERC20 token;
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

    ProStream internal defaultStream;
    DefaultParams internal params;

    /*//////////////////////////////////////////////////////////////////////////
                                   SETUP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        UnitTest.setUp();

        // Initialize the default params to be used for the create functions.
        params.createWithDeltas.sender = users.sender;
        params.createWithDeltas.recipient = users.recipient;
        params.createWithDeltas.grossDepositAmount = DEFAULT_GROSS_DEPOSIT_AMOUNT;
        params.createWithDeltas.token = dai;
        params.createWithDeltas.cancelable = true;
        params.createWithDeltas.broker = Broker({ addr: users.broker, fee: DEFAULT_BROKER_FEE });

        params.createWithMilestones.sender = users.sender;
        params.createWithMilestones.recipient = users.recipient;
        params.createWithMilestones.grossDepositAmount = DEFAULT_GROSS_DEPOSIT_AMOUNT;
        params.createWithMilestones.token = dai;
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
        defaultStream.isEntity = true;
        defaultStream.segments = params.createWithMilestones.segments;
        defaultStream.sender = params.createWithMilestones.sender;
        defaultStream.startTime = params.createWithMilestones.startTime;
        defaultStream.token = params.createWithMilestones.token;

        // Set the default protocol fee.
        comptroller.setProtocolFee(dai, DEFAULT_PROTOCOL_FEE);
        comptroller.setProtocolFee(IERC20(address(nonCompliantToken)), DEFAULT_PROTOCOL_FEE);

        // Make the sender the default caller in all subsequent tests.
        changePrank(users.sender);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Helper function that partially replicates the logic of the `calculateWithdrawableAmountForMultipleSegments`
    /// function, but which does not subtract the withdrawn amount.
    function calculateStreamedAmountForMultipleSegments(
        uint40 currentTime,
        Segment[] memory segments
    ) internal view returns (uint128 streamedAmount) {
        unchecked {
            // Sum up the amounts found in all preceding segments. Set the sum to the negation of the first segment
            // amount such that we avoid adding an if statement in the while loop.
            uint128 initialSegmentAmounts;
            uint40 currentSegmentMilestone = segments[0].milestone;
            uint256 index = 1;
            while (currentSegmentMilestone < currentTime) {
                initialSegmentAmounts += segments[index - 1].amount;
                currentSegmentMilestone = segments[index].milestone;
                index += 1;
            }

            // After the loop exits, the current segment is found at index `index - 1`, while the initial segment
            // is found at `index - 2`.
            uint128 currentSegmentAmount = segments[index - 1].amount;
            SD1x18 currentSegmentExponent = segments[index - 1].exponent;
            currentSegmentMilestone = segments[index - 1].milestone;

            // Define the time variables.
            uint40 elapsedSegmentTime;
            uint40 totalSegmentTime;

            // If the current segment is at an index that is >= 2, we take the difference between the current
            // segment milestone and the initial segment milestone.
            if (index > 1) {
                uint40 initialSegmentMilestone = segments[index - 2].milestone;
                elapsedSegmentTime = currentTime - initialSegmentMilestone;

                // Calculate the time between the current segment milestone and the initial segment milestone.
                totalSegmentTime = currentSegmentMilestone - initialSegmentMilestone;
            }
            // If the current segment is at index 1, we take the difference between the current segment milestone
            // and the start time of the stream.
            else {
                elapsedSegmentTime = currentTime - defaultStream.startTime;
                totalSegmentTime = currentSegmentMilestone - defaultStream.startTime;
            }

            // Calculate the streamed amount.
            SD59x18 elapsedTimePercentage = sdUint40(elapsedSegmentTime).div(sdUint40(totalSegmentTime));
            SD59x18 multiplier = elapsedTimePercentage.pow(SD59x18.wrap(int256(SD1x18.unwrap(currentSegmentExponent))));
            SD59x18 proRataAmount = multiplier.mul(sdUint128(currentSegmentAmount));
            streamedAmount = initialSegmentAmounts + uint128(uint256(SD59x18.unwrap(proRataAmount)));
        }
    }

    /// @dev Helper function that partially replicates the logic of the `calculateWithdrawableAmountForOneSegment`
    /// function, but which does not subtract the withdrawn amount.
    function calculateStreamedAmountForOneSegment(
        uint40 currentTime,
        uint128 depositAmount,
        SD1x18 segmentExponent
    ) internal view returns (uint128 streamedAmount) {
        unchecked {
            SD59x18 elapsedSegmentTime = sdUint40(currentTime - defaultStream.startTime);
            SD59x18 totalSegmentTime = sdUint40(DEFAULT_TOTAL_DURATION);
            SD59x18 elapsedTimePercentage = elapsedSegmentTime.div(totalSegmentTime);
            SD59x18 multiplier = elapsedTimePercentage.pow(SD59x18.wrap(int256(SD1x18.unwrap(segmentExponent))));
            streamedAmount = uint128(uint256(SD59x18.unwrap(multiplier.mul(sdUint128(depositAmount)))));
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                               NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Checks that the given stream was deleted.
    function assertDeleted(uint256 streamId) internal override {
        ProStream memory deletedStream = pro.getStream(streamId);
        ProStream memory expectedStream;
        assertEq(deletedStream, expectedStream);
    }

    /// @dev Checks that the given streams were deleted.
    function assertDeleted(uint256[] memory streamIds) internal override {
        for (uint256 i = 0; i < streamIds.length; ++i) {
            ProStream memory deletedStream = pro.getStream(streamIds[i]);
            ProStream memory expectedStream;
            assertEq(deletedStream, expectedStream);
        }
    }

    /// @dev Creates the default stream.
    function createDefaultStream() internal override returns (uint256 streamId) {
        streamId = pro.createWithMilestones(
            params.createWithMilestones.sender,
            params.createWithMilestones.recipient,
            params.createWithMilestones.grossDepositAmount,
            params.createWithMilestones.segments,
            params.createWithMilestones.token,
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
            params.createWithDeltas.token,
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
            params.createWithDeltas.token,
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
            params.createWithMilestones.token,
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
            params.createWithMilestones.token,
            isCancelable,
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
            params.createWithMilestones.token,
            params.createWithMilestones.cancelable,
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
            params.createWithMilestones.token,
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
            params.createWithMilestones.token,
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
            params.createWithMilestones.token,
            params.createWithMilestones.cancelable,
            params.createWithMilestones.startTime,
            params.createWithMilestones.broker
        );
    }
}
