// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { SafeERC20__CallToNonContract } from "@prb/contracts/token/erc20/SafeERC20.sol";
import { ISablierV2 } from "@sablier/v2-core/interfaces/ISablierV2.sol";
import { ISablierV2Pro } from "@sablier/v2-core/interfaces/ISablierV2Pro.sol";
import { SablierV2Pro } from "@sablier/v2-core/SablierV2Pro.sol";

import { DSTest } from "ds-test/test.sol";
import { stdError } from "forge-std/Test.sol";
import { Vm } from "forge-std/Vm.sol";

import { SablierV2ProUnitTest } from "../SablierV2ProUnitTest.t.sol";

contract SablierV2Pro__Create__UnitTest is SablierV2ProUnitTest {
    /// @dev When the recipient is the zero address, it should revert.
    function testCannotCreate__RecipientZeroAddress() external {
        vm.expectRevert(ISablierV2.SablierV2__RecipientZeroAddress.selector);
        address recipient = address(0);
        sablierV2Pro.create(
            stream.sender,
            recipient,
            stream.token,
            stream.depositAmount,
            stream.startTime,
            stream.stopTime,
            stream.segmentAmounts,
            stream.segmentExponents,
            stream.segmentMilestones,
            stream.cancelable
        );
    }

    /// @dev When the deposit amount is zero, it should revert.
    function testCannotCreate__DepositAmountZero() external {
        vm.expectRevert(ISablierV2.SablierV2__DepositAmountZero.selector);
        uint256 depositAmount = 0;
        sablierV2Pro.create(
            stream.sender,
            stream.recipient,
            stream.token,
            depositAmount,
            stream.startTime,
            stream.stopTime,
            stream.segmentAmounts,
            stream.segmentExponents,
            stream.segmentMilestones,
            stream.cancelable
        );
    }

    /// @dev When the start time is greater than the stop time, it should revert.
    function testCannotCreate__StartTimeGreaterThanStopTime() external {
        uint256 startTime = stream.stopTime;
        uint256 stopTime = stream.startTime;
        vm.expectRevert(
            abi.encodeWithSelector(ISablierV2.SablierV2__StartTimeGreaterThanStopTime.selector, startTime, stopTime)
        );
        sablierV2Pro.create(
            stream.sender,
            stream.recipient,
            stream.token,
            stream.depositAmount,
            startTime,
            stopTime,
            stream.segmentAmounts,
            stream.segmentExponents,
            stream.segmentMilestones,
            stream.cancelable
        );
    }

    /// @dev When the length of segment amounts is not equal to other segment variables length, it should revert.
    function testCannotCreate__SegmentAmountsLengthIsNotEqual() external {
        uint256 amount = DEFAULT_SEGMENT_AMOUNT_1;
        uint256[] memory segmentAmounts = fixedSizeToDynamic(amount);
        vm.expectRevert(
            abi.encodeWithSelector(
                ISablierV2Pro.SablierV2Pro__SegmentVariablesLengthIsNotEqual.selector,
                segmentAmounts.length,
                stream.segmentExponents.length,
                stream.segmentMilestones.length
            )
        );
        sablierV2Pro.create(
            stream.sender,
            stream.recipient,
            stream.token,
            stream.depositAmount,
            stream.startTime,
            stream.stopTime,
            segmentAmounts,
            stream.segmentExponents,
            stream.segmentMilestones,
            stream.cancelable
        );
    }

    /// @dev When the length of segment exponents is not equal to other segment variables length, it should revert.
    function testCannotCreate__SegmentExponentsLengthIsNotEqual() external {
        uint256 exponent = DEFAULT_SEGMENT_EXPONENT_1;
        uint256[] memory segmentExponents = fixedSizeToDynamic(exponent);
        vm.expectRevert(
            abi.encodeWithSelector(
                ISablierV2Pro.SablierV2Pro__SegmentVariablesLengthIsNotEqual.selector,
                stream.segmentAmounts.length,
                segmentExponents.length,
                stream.segmentMilestones.length
            )
        );
        sablierV2Pro.create(
            stream.sender,
            stream.recipient,
            stream.token,
            stream.depositAmount,
            stream.startTime,
            stream.stopTime,
            stream.segmentAmounts,
            segmentExponents,
            stream.segmentMilestones,
            stream.cancelable
        );
    }

    /// @dev When the length of segment milestones is not equal to other segment variables length, it should revert.
    function testCannotCreate__SegmentMilestonesLengthIsNotEqual() external {
        uint256 milestone = DEFAULT_SEGMENT_MILESTONE_1;
        uint256[] memory segmentMilestones = fixedSizeToDynamic(milestone);
        vm.expectRevert(
            abi.encodeWithSelector(
                ISablierV2Pro.SablierV2Pro__SegmentVariablesLengthIsNotEqual.selector,
                stream.segmentAmounts.length,
                stream.segmentExponents.length,
                segmentMilestones.length
            )
        );
        sablierV2Pro.create(
            stream.sender,
            stream.recipient,
            stream.token,
            stream.depositAmount,
            stream.startTime,
            stream.stopTime,
            stream.segmentAmounts,
            stream.segmentExponents,
            segmentMilestones,
            stream.cancelable
        );
    }

    /// @dev When the variables that represent a segment lenght is zero, it should revert.
    function testCannotCreate__VariablesLengthIsZero() external {
        uint256[] memory segmentAmounts;
        uint256[] memory segmentExponents;
        uint256[] memory segmentMilestones;
        vm.expectRevert(
            abi.encodeWithSelector(
                ISablierV2Pro.SablierV2Pro__SegmentVariablesLengthIsOutOfBounds.selector,
                segmentAmounts.length
            )
        );
        sablierV2Pro.create(
            stream.sender,
            stream.recipient,
            stream.token,
            stream.depositAmount,
            stream.startTime,
            stream.stopTime,
            segmentAmounts,
            segmentExponents,
            segmentMilestones,
            stream.cancelable
        );
    }

    /// @dev When the variables that represent a segment lenght is greater than five, it should revert.
    function testCannotCreate__VariablesLengthIsGreaterThanFive() external {
        uint256[] memory segmentAmounts = fixedSizeToDynamic(
            [
                DEFAULT_SEGMENT_AMOUNT_1,
                DEFAULT_SEGMENT_AMOUNT_1,
                DEFAULT_SEGMENT_AMOUNT_1,
                DEFAULT_SEGMENT_AMOUNT_1,
                DEFAULT_SEGMENT_AMOUNT_1,
                DEFAULT_SEGMENT_AMOUNT_1
            ]
        );
        uint256[] memory segmentExponents = fixedSizeToDynamic(
            [
                DEFAULT_SEGMENT_EXPONENT_1,
                DEFAULT_SEGMENT_EXPONENT_1,
                DEFAULT_SEGMENT_EXPONENT_1,
                DEFAULT_SEGMENT_EXPONENT_1,
                DEFAULT_SEGMENT_EXPONENT_1,
                DEFAULT_SEGMENT_EXPONENT_1
            ]
        );
        uint256[] memory segmentMilestones = fixedSizeToDynamic(
            [
                DEFAULT_SEGMENT_MILESTONE_1,
                DEFAULT_SEGMENT_MILESTONE_1 + 1 seconds,
                DEFAULT_SEGMENT_MILESTONE_1 + 2 seconds,
                DEFAULT_SEGMENT_MILESTONE_1 + 3 seconds,
                DEFAULT_SEGMENT_MILESTONE_1 + 4 seconds,
                DEFAULT_SEGMENT_MILESTONE_2
            ]
        );
        vm.expectRevert(
            abi.encodeWithSelector(
                ISablierV2Pro.SablierV2Pro__SegmentVariablesLengthIsOutOfBounds.selector,
                segmentAmounts.length
            )
        );
        sablierV2Pro.create(
            stream.sender,
            stream.recipient,
            stream.token,
            stream.depositAmount,
            stream.startTime,
            stream.stopTime,
            segmentAmounts,
            segmentExponents,
            segmentMilestones,
            stream.cancelable
        );
    }

    /// @dev When the start time is greater than the first milestone, it should revert.
    function testCannotCreate__StartTimeGreaterThanFirstMilestone() external {
        uint256 firstMilestone = stream.startTime - 1;
        uint256[] memory segmentMilestones = fixedSizeToDynamic([firstMilestone, stream.stopTime]);
        vm.expectRevert(
            abi.encodeWithSelector(
                ISablierV2Pro.SablierV2Pro__StartTimeGreaterThanMilestone.selector,
                stream.startTime,
                firstMilestone
            )
        );
        sablierV2Pro.create(
            stream.sender,
            stream.recipient,
            stream.token,
            stream.depositAmount,
            stream.startTime,
            stream.stopTime,
            stream.segmentAmounts,
            stream.segmentExponents,
            segmentMilestones,
            stream.cancelable
        );
    }

    /// @dev When the last milestone is greater than stop time, it should revert.
    function testCannotCreate__MilestoneGreaterThanStopTime() external {
        uint256 lastMilestone = stream.stopTime + 1;
        uint256[] memory segmentMilestones = fixedSizeToDynamic([DEFAULT_SEGMENT_MILESTONE_1, lastMilestone]);
        vm.expectRevert(
            abi.encodeWithSelector(
                ISablierV2Pro.SablierV2Pro__MilestoneGreaterThanStopTime.selector,
                lastMilestone,
                stream.stopTime
            )
        );
        sablierV2Pro.create(
            stream.sender,
            stream.recipient,
            stream.token,
            stream.depositAmount,
            stream.startTime,
            stream.stopTime,
            stream.segmentAmounts,
            stream.segmentExponents,
            segmentMilestones,
            stream.cancelable
        );
    }

    /// @dev When the previous milestone is equal or greater than milestone, it should revert.
    function testCannotCreate__PreviousMilestoneIsEqualOrGreaterThanMilestone() external {
        uint256 previousMilestone = DEFAULT_SEGMENT_MILESTONE_1;
        uint256 milestone = DEFAULT_SEGMENT_MILESTONE_1;
        uint256[] memory segmentMilestones = fixedSizeToDynamic([previousMilestone, milestone]);
        vm.expectRevert(
            abi.encodeWithSelector(
                ISablierV2Pro.SablierV2Pro__PreviousMilestoneIsEqualOrGreaterThanMilestone.selector,
                previousMilestone,
                milestone
            )
        );
        sablierV2Pro.create(
            stream.sender,
            stream.recipient,
            stream.token,
            stream.depositAmount,
            stream.startTime,
            stream.stopTime,
            stream.segmentAmounts,
            stream.segmentExponents,
            segmentMilestones,
            stream.cancelable
        );
    }

    /// @dev When the exponent is not greater than one, it should revert.
    function testCannotCreate__ExponentIsZero() external {
        uint256 exponentZero = 0;
        uint256[] memory segmentExponents = fixedSizeToDynamic([exponentZero, DEFAULT_SEGMENT_EXPONENT_1]);
        vm.expectRevert(
            abi.encodeWithSelector(ISablierV2Pro.SablierV2Pro__SegmentExponentIsOutOfBounds.selector, exponentZero)
        );
        sablierV2Pro.create(
            stream.sender,
            stream.recipient,
            stream.token,
            stream.depositAmount,
            stream.startTime,
            stream.stopTime,
            stream.segmentAmounts,
            segmentExponents,
            stream.segmentMilestones,
            stream.cancelable
        );
    }

    ///@dev When the exponent is greater than three, it should revert.
    function testCannotCreate__ExponentGreaterThanThree() external {
        uint256 exponentFour = 4;
        uint256[] memory segmentExponents = fixedSizeToDynamic([exponentFour, DEFAULT_SEGMENT_EXPONENT_1]);
        vm.expectRevert(
            abi.encodeWithSelector(ISablierV2Pro.SablierV2Pro__SegmentExponentIsOutOfBounds.selector, exponentFour)
        );
        sablierV2Pro.create(
            stream.sender,
            stream.recipient,
            stream.token,
            stream.depositAmount,
            stream.startTime,
            stream.stopTime,
            stream.segmentAmounts,
            segmentExponents,
            stream.segmentMilestones,
            stream.cancelable
        );
    }

    /// @dev When amount cumulated is not equal to deposit amount, it should revert.
    function testCannotCreate__DepositIsNotEqualToSegmentAmounts() external {
        uint256[] memory segmentAmounts = fixedSizeToDynamic([DEFAULT_SEGMENT_AMOUNT_1, DEFAULT_SEGMENT_AMOUNT_1]);
        uint256 cumulativeAmount = DEFAULT_SEGMENT_AMOUNT_1 + DEFAULT_SEGMENT_AMOUNT_1;
        vm.expectRevert(
            abi.encodeWithSelector(
                ISablierV2Pro.SablierV2Pro__DepositIsNotEqualToSegmentAmounts.selector,
                stream.depositAmount,
                cumulativeAmount
            )
        );

        sablierV2Pro.create(
            stream.sender,
            stream.recipient,
            stream.token,
            stream.depositAmount,
            stream.startTime,
            stream.stopTime,
            segmentAmounts,
            stream.segmentExponents,
            stream.segmentMilestones,
            stream.cancelable
        );
    }

    /// @dev When the token is not a contract, it should revert.
    function testCannotCreate__TokenNotContract() external {
        vm.expectRevert(abi.encodeWithSelector(SafeERC20__CallToNonContract.selector, address(6174)));
        IERC20 token = IERC20(address(6174));
        sablierV2Pro.create(
            stream.sender,
            stream.recipient,
            token,
            stream.depositAmount,
            stream.startTime,
            stream.stopTime,
            stream.segmentAmounts,
            stream.segmentExponents,
            stream.segmentMilestones,
            stream.cancelable
        );
    }

    /// @dev When the token is missing the return value, it should create the stream.
    function testCreate__TokenMissingReturnValue() external {
        nonStandardToken.mint(users.sender, DEFAULT_DEPOSIT_AMOUNT);
        nonStandardToken.approve(address(sablierV2Pro), DEFAULT_DEPOSIT_AMOUNT);
        IERC20 token = IERC20(address(nonStandardToken));

        uint256 streamId = sablierV2Pro.nextStreamId();
        sablierV2Pro.create(
            stream.sender,
            stream.recipient,
            token,
            stream.depositAmount,
            stream.startTime,
            stream.stopTime,
            stream.segmentAmounts,
            stream.segmentExponents,
            stream.segmentMilestones,
            stream.cancelable
        );

        ISablierV2Pro.Stream memory createdStream = sablierV2Pro.getStream(streamId);
        assertEq(stream.sender, createdStream.sender);
        assertEq(stream.recipient, createdStream.recipient);
        assertEq(stream.depositAmount, createdStream.depositAmount);
        assertEq(address(nonStandardToken), address(createdStream.token));
        assertEq(stream.startTime, createdStream.startTime);
        assertEq(stream.stopTime, createdStream.stopTime);
        assertEq(stream.segmentAmounts, createdStream.segmentAmounts);
        assertEq(stream.segmentExponents, createdStream.segmentExponents);
        assertEq(stream.segmentMilestones, createdStream.segmentMilestones);
        assertEq(stream.cancelable, createdStream.cancelable);
        assertEq(stream.withdrawnAmount, createdStream.withdrawnAmount);
    }

    /// @dev When all checks pass, it should create the stream.
    function testCreate() external {
        uint256 streamId = createDefaultStream();
        ISablierV2Pro.Stream memory createdStream = sablierV2Pro.getStream(streamId);
        assertEq(stream, createdStream);
    }

    /// @dev When all checks pass, it should bump the next stream id.
    function testCreate__NextStreamId() external {
        uint256 nextStreamId = sablierV2Pro.nextStreamId();
        uint256 expectedNextStreamId = nextStreamId + 1;
        createDefaultStream();
        uint256 actualNextStreamId = sablierV2Pro.nextStreamId();
        assertEq(expectedNextStreamId, actualNextStreamId);
    }

    /// @dev When all checks pass, it should emit a CreateStream event.
    function testCreate__Event() external {
        uint256 streamId = sablierV2Pro.nextStreamId();
        vm.expectEmit(true, true, true, true);
        emit CreateStream(
            streamId,
            stream.sender,
            stream.recipient,
            stream.token,
            stream.depositAmount,
            stream.startTime,
            stream.stopTime,
            stream.segmentAmounts,
            stream.segmentExponents,
            stream.segmentMilestones,
            stream.cancelable
        );
        createDefaultStream();
    }
}
