// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { SafeERC20__CallToNonContract } from "@prb/contracts/token/erc20/SafeERC20.sol";
import { ISablierV2 } from "@sablier/v2-core/interfaces/ISablierV2.sol";
import { ISablierV2Pro } from "@sablier/v2-core/interfaces/ISablierV2Pro.sol";
import { SablierV2Pro } from "@sablier/v2-core/SablierV2Pro.sol";
import { SD59x18, ZERO } from "@prb/math/SD59x18.sol";

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

    /// @dev When the length of segment amounts is not equal to the other segment variables length, it should revert.
    function testCannotCreate__SegmentAmountsLengthNotEqual() external {
        uint256[] memory segmentAmounts = new uint256[](1);
        segmentAmounts[0] = DEFAULT_SEGMENT_AMOUNTS[0];
        vm.expectRevert(
            abi.encodeWithSelector(
                ISablierV2Pro.SablierV2Pro__SegmentArraysLengthsUnequal.selector,
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
    function testCannotCreate__SegmentExponentsLenghtsNotEqual() external {
        SD59x18[] memory segmentExponents = new SD59x18[](1);
        segmentExponents[0] = DEFAULT_SEGMENT_EXPONENTS[0];
        vm.expectRevert(
            abi.encodeWithSelector(
                ISablierV2Pro.SablierV2Pro__SegmentArraysLengthsUnequal.selector,
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
    function testCannotCreate__SegmentArraysLengthsUnequal() external {
        uint256[] memory segmentMilestones = new uint256[](1);
        segmentMilestones[0] = DEFAULT_SEGMENT_MILESTONES[0];
        vm.expectRevert(
            abi.encodeWithSelector(
                ISablierV2Pro.SablierV2Pro__SegmentArraysLengthsUnequal.selector,
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
    function testCannotCreate__ArraysLengthZero() external {
        uint256[] memory segmentAmounts;
        SD59x18[] memory segmentExponents;
        uint256[] memory segmentMilestones;
        vm.expectRevert(abi.encodeWithSelector(ISablierV2Pro.SablierV2Pro__SegmentArraysLengthZero.selector));
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

    /// @dev When the segment arrays length is out of bounds, it should revert.
    /// TODO: test case when the array length is greater than the maximum permitted by Sablier (200).
    function testCannotCreate__SegmentArraysLengthOutOfBounds() external {
        uint256[] memory segmentAmounts = new uint256[](6);
        segmentAmounts[0] = DEFAULT_SEGMENT_AMOUNTS[0];
        segmentAmounts[1] = DEFAULT_SEGMENT_AMOUNTS[0];
        segmentAmounts[2] = DEFAULT_SEGMENT_AMOUNTS[0];
        segmentAmounts[3] = DEFAULT_SEGMENT_AMOUNTS[0];
        segmentAmounts[4] = DEFAULT_SEGMENT_AMOUNTS[0];
        segmentAmounts[5] = DEFAULT_SEGMENT_AMOUNTS[0];

        SD59x18[] memory segmentExponents = new SD59x18[](6);
        segmentExponents[0] = DEFAULT_SEGMENT_EXPONENTS[0];
        segmentExponents[1] = DEFAULT_SEGMENT_EXPONENTS[0];
        segmentExponents[2] = DEFAULT_SEGMENT_EXPONENTS[0];
        segmentExponents[3] = DEFAULT_SEGMENT_EXPONENTS[0];
        segmentExponents[4] = DEFAULT_SEGMENT_EXPONENTS[0];
        segmentExponents[5] = DEFAULT_SEGMENT_EXPONENTS[0];

        uint256[] memory segmentMilestones = new uint256[](6);
        segmentMilestones[0] = DEFAULT_SEGMENT_MILESTONES[0];
        segmentMilestones[1] = segmentMilestones[0] + 1 seconds;
        segmentMilestones[2] = segmentMilestones[0] + 2 seconds;
        segmentMilestones[3] = segmentMilestones[0] + 3 seconds;
        segmentMilestones[4] = segmentMilestones[0] + 4 seconds;
        segmentMilestones[5] = DEFAULT_SEGMENT_MILESTONES[1];

        vm.expectRevert(
            abi.encodeWithSelector(
                ISablierV2Pro.SablierV2Pro__SegmentArraysLengthOutOfBounds.selector,
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
        uint256[] memory segmentMilestones = new uint256[](2);
        segmentMilestones[0] = firstMilestone;
        segmentMilestones[1] = stream.stopTime;
        vm.expectRevert(
            abi.encodeWithSelector(
                ISablierV2Pro.SablierV2Pro__StartTimeGreaterThanFirstMilestone.selector,
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
        uint256[] memory segmentMilestones = new uint256[](2);
        segmentMilestones[0] = DEFAULT_SEGMENT_MILESTONES[0];
        segmentMilestones[1] = lastMilestone;
        vm.expectRevert(
            abi.encodeWithSelector(
                ISablierV2Pro.SablierV2Pro__LastMilestoneGreaterThanStopTime.selector,
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

    /// @dev When the previous milestone is greater than or equal to the current milestone, it should revert.
    function testCannotCreate__PreviousMilestoneGreaterThanOrEqualToCurrentMilestone() external {
        uint256 milestone = DEFAULT_SEGMENT_MILESTONES[0];
        uint256[] memory segmentMilestones = new uint256[](2);
        segmentMilestones[0] = milestone;
        segmentMilestones[1] = milestone;
        vm.expectRevert(
            abi.encodeWithSelector(ISablierV2Pro.SablierV2Pro__UnorderedMilestones.selector, 1, milestone, milestone)
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

    ///@dev When the exponent is greater than the maximum permitted by Sablier, it should revert.
    function testCannotCreate__ExponentGreaterThanMax() external {
        SD59x18 exponentTooBig = MAX_EXPONENT.uncheckedAdd(SD59x18.wrap(1));
        SD59x18[] memory segmentExponents = new SD59x18[](2);
        segmentExponents[0] = exponentTooBig;
        segmentExponents[1] = DEFAULT_SEGMENT_EXPONENTS[0];
        vm.expectRevert(
            abi.encodeWithSelector(ISablierV2Pro.SablierV2Pro__SegmentExponentOutOfBounds.selector, exponentTooBig)
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
    function testCannotCreate__DepositNotEqualToSegmentAmounts() external {
        uint256[] memory segmentAmounts = new uint256[](2);
        segmentAmounts[0] = DEFAULT_SEGMENT_AMOUNTS[0];
        segmentAmounts[1] = DEFAULT_SEGMENT_AMOUNTS[0];
        uint256 segmentAmountsSum = DEFAULT_SEGMENT_AMOUNTS[0] + DEFAULT_SEGMENT_AMOUNTS[0];
        vm.expectRevert(
            abi.encodeWithSelector(
                ISablierV2Pro.SablierV2Pro__DepositAmountNotEqualToSegmentAmountsSum.selector,
                stream.depositAmount,
                segmentAmountsSum
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
