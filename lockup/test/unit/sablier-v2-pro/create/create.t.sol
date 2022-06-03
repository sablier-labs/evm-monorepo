// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { ISablierV2 } from "@sablier/v2-core/interfaces/ISablierV2.sol";
import { ISablierV2Pro } from "@sablier/v2-core/interfaces/ISablierV2Pro.sol";
import { SafeERC20__CallToNonContract } from "@prb/contracts/token/erc20/SafeERC20.sol";
import { SD59x18 } from "@prb/math/SD59x18.sol";
import { stdError } from "forge-std/Test.sol";

import { SablierV2ProUnitTest } from "../SablierV2ProUnitTest.t.sol";

contract SablierV2Pro__Create__UnitTest is SablierV2ProUnitTest {
    /// @dev When the recipient is the zero address, it should revert.
    function testCannotCreate__RecipientZeroAddress() external {
        vm.expectRevert(ISablierV2.SablierV2__RecipientZeroAddress.selector);
        address recipient = address(0);
        sablierV2Pro.create(
            stream.sender,
            recipient,
            stream.depositAmount,
            stream.token,
            stream.startTime,
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
            depositAmount,
            stream.token,
            stream.startTime,
            stream.segmentAmounts,
            stream.segmentExponents,
            stream.segmentMilestones,
            stream.cancelable
        );
    }

    /// @dev When the deposit amount is zero, it should revert.
    function testCannotCreate__SegmentArraysLengthZero() external {
        vm.expectRevert(ISablierV2Pro.SablierV2Pro__SegmentArraysLengthZero.selector);
        uint256[] memory segmentAmounts;
        SD59x18[] memory segmentExponents;
        uint256[] memory segmentMilestones;
        sablierV2Pro.create(
            stream.sender,
            stream.recipient,
            stream.depositAmount,
            stream.token,
            stream.startTime,
            segmentAmounts,
            segmentExponents,
            segmentMilestones,
            stream.cancelable
        );
    }

    /// @dev When the deposit amount is zero, it should revert.
    function testCannotCreate__SegmentArraysLengthOutOfBounds() external {
        uint256 length = sablierV2Pro.MAX_SEGMENT_ARRAY_LENGTH() + 1;
        vm.expectRevert(
            abi.encodeWithSelector(ISablierV2Pro.SablierV2Pro__SegmentArraysLengthOutOfBounds.selector, length)
        );
        uint256[] memory segmentAmounts = new uint256[](length);
        for (uint256 i = 0; i < length; ) {
            segmentAmounts[i] = i;
            unchecked {
                i += 1;
            }
        }
        sablierV2Pro.create(
            stream.sender,
            stream.recipient,
            stream.depositAmount,
            stream.token,
            stream.startTime,
            segmentAmounts,
            stream.segmentExponents,
            stream.segmentMilestones,
            stream.cancelable
        );
    }

    /// @dev When the deposit amount is zero, it should revert.
    function testCannotCreate__SegmentArraysLengthsNotEqual__SegmentExponents() external {
        SD59x18[] memory segmentExponents = createDynamicArray(DEFAULT_SEGMENT_EXPONENTS[0]);
        vm.expectRevert(
            abi.encodeWithSelector(
                ISablierV2Pro.SablierV2Pro__SegmentArraysLengthsNotEqual.selector,
                stream.segmentAmounts.length,
                segmentExponents.length,
                stream.segmentMilestones.length
            )
        );
        sablierV2Pro.create(
            stream.sender,
            stream.recipient,
            stream.depositAmount,
            stream.token,
            stream.startTime,
            stream.segmentAmounts,
            segmentExponents,
            stream.segmentMilestones,
            stream.cancelable
        );
    }

    /// @dev When the deposit amount is zero, it should revert.
    function testCannotCreate__SegmentArraysLengthsNotEqual__SegmentMilestones() external {
        uint256[] memory segmentMilestones = createDynamicArray(DEFAULT_SEGMENT_MILESTONES[0]);
        vm.expectRevert(
            abi.encodeWithSelector(
                ISablierV2Pro.SablierV2Pro__SegmentArraysLengthsNotEqual.selector,
                stream.segmentAmounts.length,
                stream.segmentExponents.length,
                segmentMilestones.length
            )
        );
        sablierV2Pro.create(
            stream.sender,
            stream.recipient,
            stream.depositAmount,
            stream.token,
            stream.startTime,
            stream.segmentAmounts,
            stream.segmentExponents,
            segmentMilestones,
            stream.cancelable
        );
    }

    /// @dev When the start time is greater than the stop time, it should revert.
    function testCannotCreate__StartTimeGreaterThanFirstMilestone() external {
        uint256 startTime = stream.segmentMilestones[0] + 1;
        vm.expectRevert(
            abi.encodeWithSelector(
                ISablierV2Pro.SablierV2Pro__StartTimeGreaterThanFirstMilestone.selector,
                startTime,
                stream.segmentMilestones[0]
            )
        );
        sablierV2Pro.create(
            stream.sender,
            stream.recipient,
            stream.depositAmount,
            stream.token,
            startTime,
            stream.segmentAmounts,
            stream.segmentExponents,
            stream.segmentMilestones,
            stream.cancelable
        );
    }

    /// @dev When the start time is equal to the stop time, it should create the stream.
    function testCreate__StartTimeEqualToStopTime() external {
        uint256 depositAmount = DEFAULT_SEGMENT_AMOUNTS[0];
        uint256[] memory segmentAmounts = createDynamicArray(DEFAULT_SEGMENT_AMOUNTS[0]);
        SD59x18[] memory segmentExponents = createDynamicArray(DEFAULT_SEGMENT_EXPONENTS[0]);
        uint256[] memory segmentMilestones = createDynamicArray(stream.stopTime);
        uint256 streamId = sablierV2Pro.nextStreamId();
        sablierV2Pro.create(
            stream.sender,
            stream.recipient,
            depositAmount,
            stream.token,
            stream.startTime,
            segmentAmounts,
            segmentExponents,
            segmentMilestones,
            stream.cancelable
        );
        ISablierV2Pro.Stream memory createdStream = sablierV2Pro.getStream(streamId);
        assertEq(stream.sender, createdStream.sender);
        assertEq(stream.recipient, createdStream.recipient);
        assertEq(depositAmount, createdStream.depositAmount);
        assertEq(stream.token, createdStream.token);
        assertEq(stream.startTime, createdStream.startTime);
        assertEq(segmentAmounts, createdStream.segmentAmounts);
        assertEq(segmentExponents, createdStream.segmentExponents);
        assertEq(segmentMilestones, createdStream.segmentMilestones);
        assertEq(stream.cancelable, createdStream.cancelable);
        assertEq(stream.withdrawnAmount, createdStream.withdrawnAmount);
    }

    /// @dev When the segment amounts sum overflows, it should revert.
    function testCannotCreate__SegmentAmountsSumOverflow() external {
        uint256[] memory segmentAmounts = createDynamicArray(type(uint256).max, 1);
        vm.expectRevert(stdError.arithmeticError);
        sablierV2Pro.create(
            stream.sender,
            stream.recipient,
            stream.depositAmount,
            stream.token,
            stream.startTime,
            segmentAmounts,
            stream.segmentExponents,
            stream.segmentMilestones,
            stream.cancelable
        );
    }

    /// @dev When the segment milestones are not ordered, it should revert.
    function testCannotCreate__SegmentMilestonesNotOrdered() external {
        uint256[] memory segmentMilestones = createDynamicArray(
            DEFAULT_SEGMENT_MILESTONES[1],
            DEFAULT_SEGMENT_MILESTONES[0]
        );
        vm.expectRevert(
            abi.encodeWithSelector(
                ISablierV2Pro.SablierV2Pro__SegmentMilestonesNotOrdered.selector,
                1,
                segmentMilestones[0],
                segmentMilestones[1]
            )
        );
        sablierV2Pro.create(
            stream.sender,
            stream.recipient,
            stream.depositAmount,
            stream.token,
            stream.startTime,
            stream.segmentAmounts,
            stream.segmentExponents,
            segmentMilestones,
            stream.cancelable
        );
    }

    /// @dev When a segment exponent is out of bounds, it should revert.
    function testCannotCreate__SegmentExponentOutOfBounds() external {
        SD59x18 outOfBoundsExponent = sablierV2Pro.MAX_EXPONENT().uncheckedAdd(sd59x18(1));
        SD59x18[] memory segmentExponents = createDynamicArray(DEFAULT_SEGMENT_EXPONENTS[0], outOfBoundsExponent);
        vm.expectRevert(
            abi.encodeWithSelector(ISablierV2Pro.SablierV2Pro__SegmentExponentOutOfBounds.selector, outOfBoundsExponent)
        );
        sablierV2Pro.create(
            stream.sender,
            stream.recipient,
            stream.depositAmount,
            stream.token,
            stream.startTime,
            stream.segmentAmounts,
            segmentExponents,
            stream.segmentMilestones,
            stream.cancelable
        );
    }

    /// @dev When a segment exponent is out of bounds, it should revert.
    function testCannotCreate__DepositAmountNotEqualSegmentAmountsSum() external {
        uint256 depositAmount = stream.depositAmount + 1;
        vm.expectRevert(
            abi.encodeWithSelector(
                ISablierV2Pro.SablierV2Pro__DepositAmountNotEqualToSegmentAmountsSum.selector,
                depositAmount,
                stream.depositAmount
            )
        );
        sablierV2Pro.create(
            stream.sender,
            stream.recipient,
            depositAmount,
            stream.token,
            stream.startTime,
            stream.segmentAmounts,
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
            stream.depositAmount,
            token,
            stream.startTime,
            stream.segmentAmounts,
            stream.segmentExponents,
            stream.segmentMilestones,
            stream.cancelable
        );
    }

    /// @dev When the token is missing the return value, it should create the stream.
    function testCreate__TokenMissingReturnValue() external {
        IERC20 token = IERC20(address(nonStandardToken));

        uint256 streamId = sablierV2Pro.nextStreamId();
        sablierV2Pro.create(
            stream.sender,
            stream.recipient,
            stream.depositAmount,
            token,
            stream.startTime,
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
            stream.depositAmount,
            stream.token,
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
