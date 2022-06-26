// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { ISablierV2 } from "@sablier/v2-core/interfaces/ISablierV2.sol";
import { ISablierV2Pro } from "@sablier/v2-core/interfaces/ISablierV2Pro.sol";
import { SafeERC20__CallToNonContract } from "@prb/contracts/token/erc20/SafeERC20.sol";
import { SCALE, SD59x18 } from "@prb/math/SD59x18.sol";
import { stdError } from "forge-std/Test.sol";

import { SablierV2ProUnitTest } from "../SablierV2ProUnitTest.t.sol";

contract SablierV2Pro__UnitTest__Create is SablierV2ProUnitTest {
    /// @dev When the recipient is the zero address, it should revert.
    function testCannotCreate__RecipientZeroAddress() external {
        vm.expectRevert(ISablierV2.SablierV2__RecipientZeroAddress.selector);
        address recipient = address(0);
        sablierV2Pro.create(
            daiStream.sender,
            recipient,
            daiStream.depositAmount,
            daiStream.token,
            daiStream.startTime,
            daiStream.segmentAmounts,
            daiStream.segmentExponents,
            daiStream.segmentMilestones,
            daiStream.cancelable
        );
    }

    /// @dev When the deposit amount is zero, it should revert.
    function testCannotCreate__DepositAmountZero() external {
        vm.expectRevert(ISablierV2.SablierV2__DepositAmountZero.selector);
        uint256 depositAmount = 0;
        sablierV2Pro.create(
            daiStream.sender,
            daiStream.recipient,
            depositAmount,
            daiStream.token,
            daiStream.startTime,
            daiStream.segmentAmounts,
            daiStream.segmentExponents,
            daiStream.segmentMilestones,
            daiStream.cancelable
        );
    }

    /// @dev When the segment count is zero, it should revert.
    function testCannotCreate__SegmentCountZero() external {
        vm.expectRevert(ISablierV2Pro.SablierV2Pro__SegmentCountZero.selector);
        uint256[] memory segmentAmounts;
        SD59x18[] memory segmentExponents;
        uint256[] memory segmentMilestones;
        sablierV2Pro.create(
            daiStream.sender,
            daiStream.recipient,
            daiStream.depositAmount,
            daiStream.token,
            daiStream.startTime,
            segmentAmounts,
            segmentExponents,
            segmentMilestones,
            daiStream.cancelable
        );
    }

    /// @dev When one of the segment counts is out of bounds, it should revert.
    function testCannotCreate__SegmentCountOfBounds() external {
        uint256 segmentCount = sablierV2Pro.MAX_SEGMENT_COUNT() + 1;
        vm.expectRevert(
            abi.encodeWithSelector(ISablierV2Pro.SablierV2Pro__SegmentCountOutOfBounds.selector, segmentCount)
        );
        uint256[] memory segmentAmounts = new uint256[](segmentCount);
        for (uint256 i = 0; i < segmentCount; ) {
            segmentAmounts[i] = i;
            unchecked {
                i += 1;
            }
        }
        sablierV2Pro.create(
            daiStream.sender,
            daiStream.recipient,
            daiStream.depositAmount,
            daiStream.token,
            daiStream.startTime,
            segmentAmounts,
            daiStream.segmentExponents,
            daiStream.segmentMilestones,
            daiStream.cancelable
        );
    }

    /// @dev When the segment counts are not equal, it should revert.
    function testCannotCreate__SegmentCountsNotEqual__SegmentExponents() external {
        SD59x18[] memory segmentExponents = createDynamicArray(SEGMENT_EXPONENTS[0]);
        vm.expectRevert(
            abi.encodeWithSelector(
                ISablierV2Pro.SablierV2Pro__SegmentCountsNotEqual.selector,
                daiStream.segmentAmounts.length,
                segmentExponents.length,
                daiStream.segmentMilestones.length
            )
        );
        sablierV2Pro.create(
            daiStream.sender,
            daiStream.recipient,
            daiStream.depositAmount,
            daiStream.token,
            daiStream.startTime,
            daiStream.segmentAmounts,
            segmentExponents,
            daiStream.segmentMilestones,
            daiStream.cancelable
        );
    }

    /// @dev When the segment counts are not equal, it should revert.
    function testCannotCreate__SegmentArraysLengthsNotEqual__SegmentMilestones() external {
        uint256[] memory segmentMilestones = createDynamicArray(SEGMENT_MILESTONES[0]);
        vm.expectRevert(
            abi.encodeWithSelector(
                ISablierV2Pro.SablierV2Pro__SegmentCountsNotEqual.selector,
                daiStream.segmentAmounts.length,
                daiStream.segmentExponents.length,
                segmentMilestones.length
            )
        );
        sablierV2Pro.create(
            daiStream.sender,
            daiStream.recipient,
            daiStream.depositAmount,
            daiStream.token,
            daiStream.startTime,
            daiStream.segmentAmounts,
            daiStream.segmentExponents,
            segmentMilestones,
            daiStream.cancelable
        );
    }

    /// @dev When the start time is greater than the stop time, it should revert.
    function testCannotCreate__StartTimeGreaterThanFirstMilestone() external {
        uint256 startTime = daiStream.segmentMilestones[0] + 1;
        vm.expectRevert(
            abi.encodeWithSelector(
                ISablierV2Pro.SablierV2Pro__StartTimeGreaterThanFirstMilestone.selector,
                startTime,
                daiStream.segmentMilestones[0]
            )
        );
        sablierV2Pro.create(
            daiStream.sender,
            daiStream.recipient,
            daiStream.depositAmount,
            daiStream.token,
            startTime,
            daiStream.segmentAmounts,
            daiStream.segmentExponents,
            daiStream.segmentMilestones,
            daiStream.cancelable
        );
    }

    /// @dev When the start time is equal to the stop time, it should create the stream.
    function testCreate__StartTimeEqualToStopTime() external {
        uint256 depositAmount = SEGMENT_AMOUNTS_DAI[0];
        uint256[] memory segmentAmounts = createDynamicArray(SEGMENT_AMOUNTS_DAI[0]);
        SD59x18[] memory segmentExponents = createDynamicArray(SEGMENT_EXPONENTS[0]);
        uint256[] memory segmentMilestones = createDynamicArray(daiStream.stopTime);
        uint256 streamId = sablierV2Pro.create(
            daiStream.sender,
            daiStream.recipient,
            depositAmount,
            daiStream.token,
            daiStream.startTime,
            segmentAmounts,
            segmentExponents,
            segmentMilestones,
            daiStream.cancelable
        );
        ISablierV2Pro.Stream memory createdStream = sablierV2Pro.getStream(streamId);
        assertEq(daiStream.sender, createdStream.sender);
        assertEq(daiStream.recipient, createdStream.recipient);
        assertEq(depositAmount, createdStream.depositAmount);
        assertEq(daiStream.token, createdStream.token);
        assertEq(daiStream.startTime, createdStream.startTime);
        assertEq(segmentAmounts, createdStream.segmentAmounts);
        assertEq(segmentExponents, createdStream.segmentExponents);
        assertEq(segmentMilestones, createdStream.segmentMilestones);
        assertEq(daiStream.cancelable, createdStream.cancelable);
        assertEq(daiStream.withdrawnAmount, createdStream.withdrawnAmount);
    }

    /// @dev When the segment amounts sum overflows, it should revert.
    function testCannotCreate__SegmentAmountsSumOverflow() external {
        uint256[] memory segmentAmounts = createDynamicArray(MAX_UINT_256, 1);
        vm.expectRevert(stdError.arithmeticError);
        sablierV2Pro.create(
            daiStream.sender,
            daiStream.recipient,
            daiStream.depositAmount,
            daiStream.token,
            daiStream.startTime,
            segmentAmounts,
            daiStream.segmentExponents,
            daiStream.segmentMilestones,
            daiStream.cancelable
        );
    }

    /// @dev When the segment milestones are not ordered, it should revert.
    function testCannotCreate__SegmentMilestonesNotOrdered() external {
        uint256[] memory segmentMilestones = createDynamicArray(SEGMENT_MILESTONES[1], SEGMENT_MILESTONES[0]);
        vm.expectRevert(
            abi.encodeWithSelector(
                ISablierV2Pro.SablierV2Pro__SegmentMilestonesNotOrdered.selector,
                1,
                segmentMilestones[0],
                segmentMilestones[1]
            )
        );
        sablierV2Pro.create(
            daiStream.sender,
            daiStream.recipient,
            daiStream.depositAmount,
            daiStream.token,
            daiStream.startTime,
            daiStream.segmentAmounts,
            daiStream.segmentExponents,
            segmentMilestones,
            daiStream.cancelable
        );
    }

    /// @dev When a segment exponent is out of bounds, it should revert.
    function testCannotCreate__SegmentExponentOutOfBounds() external {
        SD59x18 outOfBoundsExponent = sablierV2Pro.MAX_EXPONENT().uncheckedAdd(SCALE);
        SD59x18[] memory segmentExponents = createDynamicArray(SEGMENT_EXPONENTS[0], outOfBoundsExponent);
        vm.expectRevert(
            abi.encodeWithSelector(ISablierV2Pro.SablierV2Pro__SegmentExponentOutOfBounds.selector, outOfBoundsExponent)
        );
        sablierV2Pro.create(
            daiStream.sender,
            daiStream.recipient,
            daiStream.depositAmount,
            daiStream.token,
            daiStream.startTime,
            daiStream.segmentAmounts,
            segmentExponents,
            daiStream.segmentMilestones,
            daiStream.cancelable
        );
    }

    /// @dev When a segment exponent is out of bounds, it should revert.
    function testCannotCreate__DepositAmountNotEqualSegmentAmountsSum() external {
        uint256 depositAmount = daiStream.depositAmount + 1;
        vm.expectRevert(
            abi.encodeWithSelector(
                ISablierV2Pro.SablierV2Pro__DepositAmountNotEqualToSegmentAmountsSum.selector,
                depositAmount,
                daiStream.depositAmount
            )
        );
        sablierV2Pro.create(
            daiStream.sender,
            daiStream.recipient,
            depositAmount,
            daiStream.token,
            daiStream.startTime,
            daiStream.segmentAmounts,
            daiStream.segmentExponents,
            daiStream.segmentMilestones,
            daiStream.cancelable
        );
    }

    /// @dev When the token is not a contract, it should revert.
    function testCannotCreate__TokenNotContract() external {
        vm.expectRevert(abi.encodeWithSelector(SafeERC20__CallToNonContract.selector, address(6174)));
        IERC20 token = IERC20(address(6174));
        sablierV2Pro.create(
            daiStream.sender,
            daiStream.recipient,
            daiStream.depositAmount,
            token,
            daiStream.startTime,
            daiStream.segmentAmounts,
            daiStream.segmentExponents,
            daiStream.segmentMilestones,
            daiStream.cancelable
        );
    }

    /// @dev When the token is missing the return value, it should create the stream.
    function testCreate__TokenMissingReturnValue() external {
        IERC20 token = IERC20(address(nonStandardToken));

        uint256 streamId = sablierV2Pro.create(
            daiStream.sender,
            daiStream.recipient,
            daiStream.depositAmount,
            token,
            daiStream.startTime,
            daiStream.segmentAmounts,
            daiStream.segmentExponents,
            daiStream.segmentMilestones,
            daiStream.cancelable
        );

        ISablierV2Pro.Stream memory createdStream = sablierV2Pro.getStream(streamId);
        assertEq(daiStream.sender, createdStream.sender);
        assertEq(daiStream.recipient, createdStream.recipient);
        assertEq(daiStream.depositAmount, createdStream.depositAmount);
        assertEq(address(nonStandardToken), address(createdStream.token));
        assertEq(daiStream.startTime, createdStream.startTime);
        assertEq(daiStream.stopTime, createdStream.stopTime);
        assertEq(daiStream.cancelable, createdStream.cancelable);
        assertEq(daiStream.withdrawnAmount, createdStream.withdrawnAmount);
    }

    /// @dev When all checks pass and the token has 6 decimals, it should create the stream.
    function testCreate__6Decimals() external {
        uint256 streamId = createDefaultUsdcStream();
        ISablierV2Pro.Stream memory actualStream = sablierV2Pro.getStream(streamId);
        ISablierV2Pro.Stream memory expectedStream = usdcStream;
        assertEq(actualStream, expectedStream);
    }

    /// @dev When all checks pass and the token has 6 decimals, it should bump the next stream id.
    function testCreate__6Decimals__NextStreamId() external {
        uint256 nextStreamId = sablierV2Pro.nextStreamId();
        createDefaultUsdcStream();
        uint256 actualNextStreamId = sablierV2Pro.nextStreamId();
        uint256 expectedNextStreamId = nextStreamId + 1;
        assertEq(actualNextStreamId, expectedNextStreamId);
    }

    /// @dev When all checks pass and the token has 6 decimals, it should emit a CreateStream event.
    function testCreate__6Decimals__Event() external {
        uint256 streamId = sablierV2Pro.nextStreamId();
        vm.expectEmit(true, true, true, true);
        emit CreateStream(
            streamId,
            usdcStream.sender,
            usdcStream.sender,
            usdcStream.recipient,
            usdcStream.depositAmount,
            usdcStream.token,
            usdcStream.startTime,
            usdcStream.stopTime,
            usdcStream.segmentAmounts,
            usdcStream.segmentExponents,
            usdcStream.segmentMilestones,
            usdcStream.cancelable
        );
        createDefaultUsdcStream();
    }

    /// @dev When all checks pass and the token has 18 decimals, it should create the stream.
    function testCreate__18Decimals() external {
        uint256 streamId = createDefaultDaiStream();
        ISablierV2Pro.Stream memory actualStream = sablierV2Pro.getStream(streamId);
        ISablierV2Pro.Stream memory expectedStream = daiStream;
        assertEq(actualStream, expectedStream);
    }

    /// @dev When all checks pass and the token has 18 decimals, it should bump the next stream id.
    function testCreate__18Decimals__NextStreamId() external {
        uint256 nextStreamId = sablierV2Pro.nextStreamId();
        createDefaultDaiStream();
        uint256 actualNextStreamId = sablierV2Pro.nextStreamId();
        uint256 expectedNextStreamId = nextStreamId + 1;
        assertEq(actualNextStreamId, expectedNextStreamId);
    }

    /// @dev When all checks pass and the token has 18 decimals, it should emit a CreateStream event.
    function testCreate__18Decimals__Event() external {
        uint256 streamId = sablierV2Pro.nextStreamId();
        vm.expectEmit(true, true, true, true);
        emit CreateStream(
            streamId,
            daiStream.sender,
            daiStream.sender,
            daiStream.recipient,
            daiStream.depositAmount,
            daiStream.token,
            daiStream.startTime,
            daiStream.stopTime,
            daiStream.segmentAmounts,
            daiStream.segmentExponents,
            daiStream.segmentMilestones,
            daiStream.cancelable
        );
        createDefaultDaiStream();
    }
}
