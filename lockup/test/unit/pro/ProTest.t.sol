// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SD1x18 } from "@prb/math/SD1x18.sol";
import { SD59x18, toSD59x18 } from "@prb/math/SD59x18.sol";
import { UD60x18 } from "@prb/math/UD60x18.sol";

import { Amounts, ProStream, Segment } from "src/types/Structs.sol";

import { SablierV2Pro } from "src/SablierV2Pro.sol";

import { UnitTest } from "../UnitTest.t.sol";

/// @title ProTest
/// @notice Common contract members needed across SablierV2Pro unit tests.
abstract contract ProTest is UnitTest {
    /*//////////////////////////////////////////////////////////////////////////
                                      STRUCTS
    //////////////////////////////////////////////////////////////////////////*/

    struct CreateWithDeltasArgs {
        address sender;
        address recipient;
        uint128 grossDepositAmount;
        Segment[] segments;
        address operator;
        UD60x18 operatorFee;
        address token;
        bool cancelable;
        uint40[] deltas;
    }

    struct CreateWithMilestonesArgs {
        address sender;
        address recipient;
        uint128 grossDepositAmount;
        Segment[] segments;
        address operator;
        UD60x18 operatorFee;
        address token;
        bool cancelable;
        uint40 startTime;
    }

    struct DefaultArgs {
        CreateWithDeltasArgs createWithDeltas;
        CreateWithMilestonesArgs createWithMilestones;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  TESTING VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    DefaultArgs internal defaultArgs;
    ProStream internal defaultStream;

    /*//////////////////////////////////////////////////////////////////////////
                                   SETUP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        super.setUp();

        // Create the default args to be used for the create functions.
        defaultArgs.createWithDeltas.sender = users.sender;
        defaultArgs.createWithDeltas.recipient = users.recipient;
        defaultArgs.createWithDeltas.grossDepositAmount = DEFAULT_GROSS_DEPOSIT_AMOUNT;
        defaultArgs.createWithDeltas.operator = users.operator;
        defaultArgs.createWithDeltas.operatorFee = DEFAULT_OPERATOR_FEE;
        defaultArgs.createWithDeltas.token = address(dai);
        defaultArgs.createWithDeltas.cancelable = true;

        defaultArgs.createWithMilestones.sender = users.sender;
        defaultArgs.createWithMilestones.recipient = users.recipient;
        defaultArgs.createWithMilestones.grossDepositAmount = DEFAULT_GROSS_DEPOSIT_AMOUNT;
        defaultArgs.createWithMilestones.operator = users.operator;
        defaultArgs.createWithMilestones.operatorFee = DEFAULT_OPERATOR_FEE;
        defaultArgs.createWithMilestones.token = address(dai);
        defaultArgs.createWithMilestones.cancelable = true;
        defaultArgs.createWithMilestones.startTime = DEFAULT_START_TIME;

        // See https://github.com/ethereum/solidity/issues/12783
        for (uint256 i = 0; i < DEFAULT_SEGMENTS.length; ++i) {
            defaultArgs.createWithDeltas.segments.push(DEFAULT_SEGMENTS[i]);
            defaultArgs.createWithDeltas.deltas.push(DEFAULT_SEGMENT_DELTAS[i]);
            defaultArgs.createWithMilestones.segments.push(DEFAULT_SEGMENTS[i]);
        }

        // Create the default stream to be used across the tests.
        defaultStream.amounts = DEFAULT_AMOUNTS;
        defaultStream.isCancelable = defaultArgs.createWithMilestones.cancelable;
        defaultStream.isEntity = true;
        defaultStream.segments = defaultArgs.createWithMilestones.segments;
        defaultStream.sender = defaultArgs.createWithMilestones.sender;
        defaultStream.startTime = defaultArgs.createWithMilestones.startTime;
        defaultStream.token = defaultArgs.createWithMilestones.token;

        // Set the default protocol fee.
        comptroller.setProtocolFee(address(dai), DEFAULT_PROTOCOL_FEE);
        comptroller.setProtocolFee(address(nonCompliantToken), DEFAULT_PROTOCOL_FEE);

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
            SD59x18 elapsedTimePercentage = toSD59x18(int256(uint256(elapsedSegmentTime))).div(
                toSD59x18(int256(uint256(totalSegmentTime)))
            );
            SD59x18 multiplier = elapsedTimePercentage.pow(SD59x18.wrap(int256(SD1x18.unwrap(currentSegmentExponent))));
            SD59x18 proRataAmount = multiplier.mul(SD59x18.wrap(int256(uint256(currentSegmentAmount))));
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
            uint40 elapsedSegmentTime = currentTime - defaultStream.startTime;
            uint40 totalSegmentTime = DEFAULT_TOTAL_DURATION;
            SD59x18 elapsedTimePercentage = toSD59x18(int256(uint256(elapsedSegmentTime))).div(
                toSD59x18(int256(uint256(totalSegmentTime)))
            );
            SD59x18 multiplier = elapsedTimePercentage.pow(SD59x18.wrap(int256(SD1x18.unwrap(segmentExponent))));
            streamedAmount = uint128(
                uint256(SD59x18.unwrap(multiplier.mul(SD59x18.wrap(int256(uint256(depositAmount))))))
            );
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                               NON-CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Helper function to create the default stream.
    function createDefaultStream() internal returns (uint256 defaultStreamId) {
        defaultStreamId = pro.createWithMilestones(
            defaultArgs.createWithMilestones.sender,
            defaultArgs.createWithMilestones.recipient,
            defaultArgs.createWithMilestones.grossDepositAmount,
            defaultArgs.createWithMilestones.segments,
            defaultArgs.createWithMilestones.operator,
            defaultArgs.createWithMilestones.operatorFee,
            defaultArgs.createWithMilestones.token,
            defaultArgs.createWithMilestones.cancelable,
            defaultArgs.createWithMilestones.startTime
        );
    }

    /// @dev Helper function to create the default stream with the provided gross deposit amount.
    function createDefaultStreamWithGrossDepositAmount(uint128 grossDepositAmount) internal returns (uint256 streamId) {
        streamId = pro.createWithMilestones(
            defaultArgs.createWithMilestones.sender,
            defaultArgs.createWithMilestones.recipient,
            grossDepositAmount,
            defaultArgs.createWithMilestones.segments,
            defaultArgs.createWithMilestones.operator,
            defaultArgs.createWithMilestones.operatorFee,
            defaultArgs.createWithMilestones.token,
            defaultArgs.createWithMilestones.cancelable,
            defaultArgs.createWithMilestones.startTime
        );
    }

    /// @dev Helper function to create the default stream with the provided segments.
    function createDefaultStreamWithSegments(Segment[] memory segments) internal returns (uint256 streamId) {
        streamId = pro.createWithMilestones(
            defaultArgs.createWithMilestones.sender,
            defaultArgs.createWithMilestones.recipient,
            defaultArgs.createWithMilestones.grossDepositAmount,
            segments,
            defaultArgs.createWithMilestones.operator,
            defaultArgs.createWithMilestones.operatorFee,
            defaultArgs.createWithMilestones.token,
            defaultArgs.createWithMilestones.cancelable,
            defaultArgs.createWithMilestones.startTime
        );
    }

    /// @dev Helper function to create the default stream with the provided deltas.
    function createDefaultStreamWithDeltas(uint40[] memory deltas) internal returns (uint256 streamId) {
        streamId = pro.createWithDeltas(
            defaultArgs.createWithDeltas.sender,
            defaultArgs.createWithDeltas.recipient,
            defaultArgs.createWithDeltas.grossDepositAmount,
            defaultArgs.createWithDeltas.segments,
            defaultArgs.createWithDeltas.operator,
            defaultArgs.createWithDeltas.operatorFee,
            defaultArgs.createWithDeltas.token,
            defaultArgs.createWithDeltas.cancelable,
            deltas
        );
    }

    /// @dev Helper function to create the default stream with the provided recipient.
    function createDefaultStreamWithRecipient(address recipient) internal returns (uint256 streamId) {
        streamId = pro.createWithMilestones(
            defaultArgs.createWithMilestones.sender,
            recipient,
            defaultArgs.createWithMilestones.grossDepositAmount,
            defaultArgs.createWithMilestones.segments,
            defaultArgs.createWithMilestones.operator,
            defaultArgs.createWithMilestones.operatorFee,
            defaultArgs.createWithMilestones.token,
            defaultArgs.createWithMilestones.cancelable,
            defaultArgs.createWithMilestones.startTime
        );
    }

    /// @dev Helper function to create a non-cancelable stream.
    function createDefaultStreamNonCancelable() internal returns (uint256 streamId) {
        bool isCancelable = false;
        streamId = pro.createWithMilestones(
            defaultArgs.createWithMilestones.sender,
            defaultArgs.createWithMilestones.recipient,
            defaultArgs.createWithMilestones.grossDepositAmount,
            defaultArgs.createWithMilestones.segments,
            defaultArgs.createWithMilestones.operator,
            defaultArgs.createWithMilestones.operatorFee,
            defaultArgs.createWithMilestones.token,
            isCancelable,
            defaultArgs.createWithMilestones.startTime
        );
    }
}
