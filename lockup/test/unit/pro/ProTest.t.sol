// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SD1x18 } from "@prb/math/SD1x18.sol";
import { SD59x18, toSD59x18 } from "@prb/math/SD59x18.sol";
import { toUD60x18, ud, UD60x18 } from "@prb/math/UD60x18.sol";

import { DataTypes } from "src/libraries/DataTypes.sol";
import { SablierV2Pro } from "src/SablierV2Pro.sol";

import { BaseTest } from "../../BaseTest.t.sol";

/// @title ProTest
/// @notice Common contract members needed across SablierV2Pro unit tests.
abstract contract ProTest is BaseTest {
    /*//////////////////////////////////////////////////////////////////////////
                                      CONSTANTS
    //////////////////////////////////////////////////////////////////////////*/

    uint128[] internal DEFAULT_SEGMENT_AMOUNTS = [2_500e18, 7_500e18];
    uint40[] internal DEFAULT_SEGMENT_DELTAS = [2_500 seconds, 7_500 seconds];
    SD1x18[] internal DEFAULT_SEGMENT_EXPONENTS = [SD1x18.wrap(3.14e18), SD1x18.wrap(0.5e18)];
    uint40[] internal DEFAULT_SEGMENT_MILESTONES;

    /*//////////////////////////////////////////////////////////////////////////
                                      STRUCTS
    //////////////////////////////////////////////////////////////////////////*/

    struct CreateWithDeltasArgs {
        address sender;
        address recipient;
        uint128 grossDepositAmount;
        uint128[] segmentAmounts;
        SD1x18[] segmentExponents;
        address operator;
        UD60x18 operatorFee;
        address token;
        bool cancelable;
        uint40[] segmentDeltas;
    }

    struct CreateWithMilestonesArgs {
        address sender;
        address recipient;
        uint128 grossDepositAmount;
        uint128[] segmentAmounts;
        SD1x18[] segmentExponents;
        address operator;
        UD60x18 operatorFee;
        address token;
        bool cancelable;
        uint40 startTime;
        uint40[] segmentMilestones;
    }

    struct DefaultArgs {
        CreateWithDeltasArgs createWithDeltas;
        CreateWithMilestonesArgs createWithMilestones;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                  TESTING VARIABLES
    //////////////////////////////////////////////////////////////////////////*/

    DefaultArgs internal defaultArgs;
    DataTypes.ProStream internal defaultStream;

    /*//////////////////////////////////////////////////////////////////////////
                                   SETUP FUNCTION
    //////////////////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        super.setUp();

        // Initialize the immutables.
        DEFAULT_SEGMENT_MILESTONES = [
            DEFAULT_START_TIME + DEFAULT_CLIFF_DURATION,
            DEFAULT_START_TIME + DEFAULT_TOTAL_DURATION
        ];

        // Create the default args to be used for the create functions.
        defaultArgs = DefaultArgs({
            createWithDeltas: CreateWithDeltasArgs({
                sender: users.sender,
                recipient: users.recipient,
                grossDepositAmount: DEFAULT_GROSS_DEPOSIT_AMOUNT,
                segmentAmounts: DEFAULT_SEGMENT_AMOUNTS,
                segmentExponents: DEFAULT_SEGMENT_EXPONENTS,
                operator: users.operator,
                operatorFee: DEFAULT_OPERATOR_FEE,
                token: address(dai),
                cancelable: true,
                segmentDeltas: DEFAULT_SEGMENT_DELTAS
            }),
            createWithMilestones: CreateWithMilestonesArgs({
                sender: users.sender,
                recipient: users.recipient,
                grossDepositAmount: DEFAULT_GROSS_DEPOSIT_AMOUNT,
                segmentAmounts: DEFAULT_SEGMENT_AMOUNTS,
                segmentExponents: DEFAULT_SEGMENT_EXPONENTS,
                operator: users.operator,
                operatorFee: DEFAULT_OPERATOR_FEE,
                token: address(dai),
                cancelable: true,
                startTime: DEFAULT_START_TIME,
                segmentMilestones: DEFAULT_SEGMENT_MILESTONES
            })
        });

        // Create the default streams to be used across the tests.
        defaultStream = DataTypes.ProStream({
            depositAmount: DEFAULT_NET_DEPOSIT_AMOUNT,
            isCancelable: defaultArgs.createWithMilestones.cancelable,
            isEntity: true,
            segmentAmounts: defaultArgs.createWithMilestones.segmentAmounts,
            segmentExponents: defaultArgs.createWithMilestones.segmentExponents,
            segmentMilestones: defaultArgs.createWithMilestones.segmentMilestones,
            sender: defaultArgs.createWithMilestones.sender,
            startTime: defaultArgs.createWithMilestones.startTime,
            stopTime: DEFAULT_SEGMENT_MILESTONES[1],
            token: address(dai),
            withdrawnAmount: 0
        });

        // Set the default protocol fee.
        comptroller.setProtocolFee(address(dai), DEFAULT_PROTOCOL_FEE);
        comptroller.setProtocolFee(address(nonCompliantToken), DEFAULT_PROTOCOL_FEE);

        // Approve the SablierV2Pro contract to spend tokens from the sender, recipient, Alice and Eve.
        approveMax({ caller: users.sender, spender: address(pro) });
        approveMax({ caller: users.recipient, spender: address(pro) });
        approveMax({ caller: users.alice, spender: address(pro) });
        approveMax({ caller: users.eve, spender: address(pro) });

        // Make the sender the default caller in all subsequent tests.
        changePrank(users.sender);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                 CONSTANT FUNCTIONS
    //////////////////////////////////////////////////////////////////////////*/

    /// @dev Calculate the segment amounts as two fractions of the provided net deposit amount, one 20%, the other 80%.
    function calculateSegmentAmounts(uint128 netDepositAmount) internal pure returns (uint128[] memory segmentAmounts) {
        segmentAmounts = new uint128[](2);
        segmentAmounts[0] = uint128(UD60x18.unwrap(ud(netDepositAmount).mul(ud(0.2e18))));
        segmentAmounts[1] = netDepositAmount - segmentAmounts[0];
    }

    /// @dev Helper function that replicates the logic of the `getWithdrawableAmountForMultipleSegment` function, but
    /// which does not subtract the withdrawn amount.
    function calculateStreamedAmountForMultipleSegments(
        uint40 currentTime,
        uint128[] memory segmentAmounts,
        SD1x18[] memory segmentExponents,
        uint40[] memory segmentMilestones
    ) internal view returns (uint128 streamedAmount) {
        unchecked {
            // Sum up the amounts found in all preceding segments. Set the sum to the negation of the first segment
            // amount such that we avoid adding an if statement in the while loop.
            uint128 previousSegmentAmounts;
            uint40 currentSegmentMilestone = segmentMilestones[0];
            uint256 index = 1;
            while (currentSegmentMilestone < currentTime) {
                previousSegmentAmounts += segmentAmounts[index - 1];
                currentSegmentMilestone = segmentMilestones[index];
                index += 1;
            }

            // After the loop exits, the current segment is found at index `index - 1`, while the previous segment
            // is found at `index - 2`.
            uint128 currentSegmentAmount = segmentAmounts[index - 1];
            SD1x18 currentSegmentExponent = segmentExponents[index - 1];
            currentSegmentMilestone = segmentMilestones[index - 1];

            // Define the time variables.
            uint40 elapsedSegmentTime;
            uint40 totalSegmentTime;

            // If the current segment is at an index that is >= 2, we take the difference between the current
            // segment milestone and the previous segment milestone.
            if (index > 1) {
                uint40 previousSegmentMilestone = segmentMilestones[index - 2];
                elapsedSegmentTime = currentTime - previousSegmentMilestone;

                // Calculate the time between the current segment milestone and the previous segment milestone.
                totalSegmentTime = currentSegmentMilestone - previousSegmentMilestone;
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
            streamedAmount = previousSegmentAmounts + uint128(uint256(SD59x18.unwrap(proRataAmount)));
        }
    }

    /// @dev Helper function that replicates the logic of the `getWithdrawableAmountForOneSegment` function, but which
    /// does not subtract the withdrawn amount.
    function calculateStreamedAmountForOneSegment(
        uint40 currentTime,
        uint128 depositAmount,
        SD1x18 segmentExponent
    ) internal view returns (uint128 streamedAmount) {
        unchecked {
            uint40 elapsedSegmentTime = currentTime - defaultStream.startTime;
            uint40 totalSegmentTime = defaultStream.stopTime - defaultStream.startTime;
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

    /// @dev Helper function to create a default stream with $DAI used as streaming currency.
    function createDefaultStream() internal returns (uint256 defaultStreamId) {
        defaultStreamId = pro.createWithMilestones(
            defaultArgs.createWithMilestones.sender,
            defaultArgs.createWithMilestones.recipient,
            defaultArgs.createWithMilestones.grossDepositAmount,
            defaultArgs.createWithMilestones.segmentAmounts,
            defaultArgs.createWithMilestones.segmentExponents,
            defaultArgs.createWithMilestones.operator,
            defaultArgs.createWithMilestones.operatorFee,
            defaultArgs.createWithMilestones.token,
            defaultArgs.createWithMilestones.cancelable,
            defaultArgs.createWithMilestones.startTime,
            defaultArgs.createWithMilestones.segmentMilestones
        );
    }

    /// @dev Helper function to create a default stream with the provided recipient.
    function createDefaultStreamWithRecipient(address recipient) internal returns (uint256 streamId) {
        streamId = pro.createWithMilestones(
            defaultArgs.createWithMilestones.sender,
            recipient,
            defaultArgs.createWithMilestones.grossDepositAmount,
            defaultArgs.createWithMilestones.segmentAmounts,
            defaultArgs.createWithMilestones.segmentExponents,
            defaultArgs.createWithMilestones.operator,
            defaultArgs.createWithMilestones.operatorFee,
            defaultArgs.createWithMilestones.token,
            defaultArgs.createWithMilestones.cancelable,
            defaultArgs.createWithMilestones.startTime,
            defaultArgs.createWithMilestones.segmentMilestones
        );
    }

    /// @dev Helper function to create a non-cancelable stream.
    function createDefaultStreamNonCancelable() internal returns (uint256 streamId) {
        bool isCancelable = false;
        streamId = pro.createWithMilestones(
            defaultArgs.createWithMilestones.sender,
            defaultArgs.createWithMilestones.recipient,
            defaultArgs.createWithMilestones.grossDepositAmount,
            defaultArgs.createWithMilestones.segmentAmounts,
            defaultArgs.createWithMilestones.segmentExponents,
            defaultArgs.createWithMilestones.operator,
            defaultArgs.createWithMilestones.operatorFee,
            defaultArgs.createWithMilestones.token,
            isCancelable,
            defaultArgs.createWithMilestones.startTime,
            defaultArgs.createWithMilestones.segmentMilestones
        );
    }
}
