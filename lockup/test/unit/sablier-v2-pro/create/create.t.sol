// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { ISablierV2 } from "@sablier/v2-core/interfaces/ISablierV2.sol";
import { ISablierV2Pro } from "@sablier/v2-core/interfaces/ISablierV2Pro.sol";
import { SafeERC20__CallToNonContract } from "@prb/contracts/token/erc20/SafeERC20.sol";
import { SCALE, SD59x18 } from "@prb/math/SD59x18.sol";
import { stdError } from "forge-std/Test.sol";

import { SablierV2ProUnitTest } from "../SablierV2ProUnitTest.t.sol";

contract SablierV2Pro__Create is SablierV2ProUnitTest {
    /// @dev it should revert.
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

    modifier RecipientNonZeroAddress() {
        _;
    }

    /// @dev it should revert.
    function testCannotCreate__DepositAmountZero() external RecipientNonZeroAddress {
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

    modifier DepositAmountNotZero() {
        _;
    }

    /// @dev it should revert.
    function testCannotCreate__SegmentCountZero() external RecipientNonZeroAddress DepositAmountNotZero {
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

    modifier SegmentCountNotZero() {
        _;
    }

    /// @dev it should revert.
    function testCannotCreate__SegmentCountOutOfBounds()
        external
        RecipientNonZeroAddress
        DepositAmountNotZero
        SegmentCountNotZero
    {
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

    modifier SegmentCountWithinBounds() {
        _;
    }

    /// @dev it should revert.
    function testCannotCreate__SegmentCountsNotEqual__SegmentExponentsNotEqual()
        external
        RecipientNonZeroAddress
        DepositAmountNotZero
        SegmentCountNotZero
        SegmentCountWithinBounds
    {
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

    /// @dev it should revert.
    function testCannotCreate__SegmentCountsNotEqual__SegmentMilestonesNotEqual()
        external
        RecipientNonZeroAddress
        DepositAmountNotZero
        SegmentCountNotZero
        SegmentCountWithinBounds
    {
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

    modifier SegmentCountsEqual() {
        _;
    }

    /// @dev it should revert.
    function testCannotCreate()
        external
        RecipientNonZeroAddress
        DepositAmountNotZero
        SegmentCountNotZero
        SegmentCountWithinBounds
        SegmentCountsEqual
    {
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

    /// @dev it should create the stream.
    function testCreate__StartTimeEqualToStopTime()
        external
        RecipientNonZeroAddress
        DepositAmountNotZero
        SegmentCountNotZero
        SegmentCountWithinBounds
        SegmentCountsEqual
    {
        uint256 depositAmount = SEGMENT_AMOUNTS_DAI[0];
        uint256[] memory segmentAmounts = createDynamicArray(SEGMENT_AMOUNTS_DAI[0]);
        SD59x18[] memory segmentExponents = createDynamicArray(SEGMENT_EXPONENTS[0]);
        uint256[] memory segmentMilestones = createDynamicArray(daiStream.stopTime);
        uint256 daiStreamId = sablierV2Pro.create(
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
        ISablierV2Pro.Stream memory actualStream = sablierV2Pro.getStream(daiStreamId);
        assertEq(actualStream.sender, daiStream.sender);
        assertEq(actualStream.recipient, daiStream.recipient);
        assertEq(actualStream.depositAmount, depositAmount);
        assertEq(actualStream.token, daiStream.token);
        assertEq(actualStream.startTime, daiStream.startTime);
        assertEq(actualStream.segmentAmounts, segmentAmounts);
        assertEq(actualStream.segmentExponents, segmentExponents);
        assertEq(actualStream.segmentMilestones, segmentMilestones);
        assertEq(actualStream.cancelable, daiStream.cancelable);
        assertEq(actualStream.withdrawnAmount, daiStream.withdrawnAmount);
    }

    modifier StartTimeLessThanStopTime() {
        _;
    }

    /// @dev When the segment amounts sum overflows, it should revert.
    function testCannotCreate__SegmentAmountsSumOverflow()
        external
        RecipientNonZeroAddress
        DepositAmountNotZero
        SegmentCountNotZero
        SegmentCountWithinBounds
        SegmentCountsEqual
        StartTimeLessThanStopTime
    {
        uint256[] memory segmentAmounts = createDynamicArray(UINT256_MAX, 1);
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

    modifier SegmentAmountsSumDoesNotOverflow() {
        _;
    }

    /// @dev it should revert.
    function testCannotCreate__SegmentMilestonesNotOrdered()
        external
        RecipientNonZeroAddress
        DepositAmountNotZero
        SegmentCountNotZero
        SegmentCountWithinBounds
        SegmentCountsEqual
        StartTimeLessThanStopTime
        SegmentAmountsSumDoesNotOverflow
    {
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

    modifier SegmentMilestonesOrdered() {
        _;
    }

    /// @dev it should revert.
    function testCannotCreate__SegmentExponentsOutOfBounds()
        external
        RecipientNonZeroAddress
        DepositAmountNotZero
        SegmentCountNotZero
        SegmentCountWithinBounds
        SegmentCountsEqual
        StartTimeLessThanStopTime
        SegmentAmountsSumDoesNotOverflow
        SegmentMilestonesOrdered
    {
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

    modifier SegmentExponentsWithinBounds() {
        _;
    }

    /// @dev it should revert.
    function testCannotCreate__DepositAmountNotEqualtoSegmentAmountsSum()
        external
        RecipientNonZeroAddress
        DepositAmountNotZero
        SegmentCountNotZero
        SegmentCountWithinBounds
        SegmentCountsEqual
        StartTimeLessThanStopTime
        SegmentAmountsSumDoesNotOverflow
        SegmentMilestonesOrdered
        SegmentExponentsWithinBounds
    {
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

    modifier DepositAmountEqualtoSegmentAmountsSum() {
        _;
    }

    /// @dev it should revert.
    function testCannotCreate__TokenNotContract()
        external
        RecipientNonZeroAddress
        DepositAmountNotZero
        SegmentCountNotZero
        SegmentCountWithinBounds
        SegmentCountsEqual
        StartTimeLessThanStopTime
        SegmentAmountsSumDoesNotOverflow
        SegmentMilestonesOrdered
        SegmentExponentsWithinBounds
        DepositAmountEqualtoSegmentAmountsSum
    {
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

    modifier TokenContract() {
        _;
    }

    /// @dev it should create the stream.
    function testCreate__TokenMissingReturnValue()
        external
        RecipientNonZeroAddress
        DepositAmountNotZero
        SegmentCountNotZero
        SegmentCountWithinBounds
        SegmentCountsEqual
        StartTimeLessThanStopTime
        SegmentAmountsSumDoesNotOverflow
        SegmentMilestonesOrdered
        SegmentExponentsWithinBounds
        DepositAmountEqualtoSegmentAmountsSum
        TokenContract
    {
        IERC20 token = IERC20(address(nonCompliantToken));

        uint256 daiStreamId = sablierV2Pro.create(
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

        ISablierV2Pro.Stream memory actualStream = sablierV2Pro.getStream(daiStreamId);
        assertEq(actualStream.sender, daiStream.sender);
        assertEq(actualStream.recipient, daiStream.recipient);
        assertEq(actualStream.depositAmount, daiStream.depositAmount);
        assertEq(address(actualStream.token), address(nonCompliantToken));
        assertEq(actualStream.startTime, daiStream.startTime);
        assertEq(actualStream.stopTime, daiStream.stopTime);
        assertEq(actualStream.cancelable, daiStream.cancelable);
        assertEq(actualStream.withdrawnAmount, daiStream.withdrawnAmount);
    }

    modifier TokenCompliant() {
        _;
    }

    /// @dev it should create the stream.
    function testCreate__Token6Decimals()
        external
        RecipientNonZeroAddress
        DepositAmountNotZero
        SegmentCountNotZero
        SegmentCountWithinBounds
        SegmentCountsEqual
        StartTimeLessThanStopTime
        SegmentAmountsSumDoesNotOverflow
        SegmentMilestonesOrdered
        SegmentExponentsWithinBounds
        DepositAmountEqualtoSegmentAmountsSum
        TokenContract
        TokenCompliant
    {
        uint256 usdcStreamId = createDefaultUsdcStream();
        ISablierV2Pro.Stream memory actualStream = sablierV2Pro.getStream(usdcStreamId);
        ISablierV2Pro.Stream memory expectedStream = usdcStream;
        assertEq(actualStream, expectedStream);
    }

    /// @dev it should bump the next stream id.
    function testCreate__Token6Decimals__NextStreamId()
        external
        RecipientNonZeroAddress
        DepositAmountNotZero
        SegmentCountNotZero
        SegmentCountWithinBounds
        SegmentCountsEqual
        StartTimeLessThanStopTime
        SegmentAmountsSumDoesNotOverflow
        SegmentMilestonesOrdered
        SegmentExponentsWithinBounds
        DepositAmountEqualtoSegmentAmountsSum
        TokenContract
        TokenCompliant
    {
        uint256 nextStreamId = sablierV2Pro.nextStreamId();
        createDefaultUsdcStream();
        uint256 actualNextStreamId = sablierV2Pro.nextStreamId();
        uint256 expectedNextStreamId = nextStreamId + 1;
        assertEq(actualNextStreamId, expectedNextStreamId);
    }

    /// @dev it should emit a CreateStream event.
    function testCreate__Token6Decimals__Event()
        external
        RecipientNonZeroAddress
        DepositAmountNotZero
        SegmentCountNotZero
        SegmentCountWithinBounds
        SegmentCountsEqual
        StartTimeLessThanStopTime
        SegmentAmountsSumDoesNotOverflow
        SegmentMilestonesOrdered
        SegmentExponentsWithinBounds
        DepositAmountEqualtoSegmentAmountsSum
        TokenContract
        TokenCompliant
    {
        uint256 usdcStreamId = sablierV2Pro.nextStreamId();
        vm.expectEmit(true, true, true, true);
        address funder = usdcStream.sender;
        emit CreateStream(
            usdcStreamId,
            funder,
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

    modifier Token18Decimals() {
        _;
    }

    /// @dev it should create the stream.
    function testCreate__CallerNotSender()
        external
        RecipientNonZeroAddress
        DepositAmountNotZero
        SegmentCountNotZero
        SegmentCountWithinBounds
        SegmentCountsEqual
        StartTimeLessThanStopTime
        SegmentAmountsSumDoesNotOverflow
        SegmentMilestonesOrdered
        SegmentExponentsWithinBounds
        DepositAmountEqualtoSegmentAmountsSum
        TokenContract
        TokenCompliant
        Token18Decimals
    {
        // Make Alice the funder of the stream.
        changePrank(users.alice);
        uint256 daiStreamId = createDefaultDaiStream();

        // Run the test.
        ISablierV2Pro.Stream memory actualStream = sablierV2Pro.getStream(daiStreamId);
        ISablierV2Pro.Stream memory expectedStream = daiStream;
        assertEq(actualStream, expectedStream);
    }

    /// @dev it should bump the next stream id.
    function testCreate__CallerNotSender__NextStreamId()
        external
        RecipientNonZeroAddress
        DepositAmountNotZero
        SegmentCountNotZero
        SegmentCountWithinBounds
        SegmentCountsEqual
        StartTimeLessThanStopTime
        SegmentAmountsSumDoesNotOverflow
        SegmentMilestonesOrdered
        SegmentExponentsWithinBounds
        DepositAmountEqualtoSegmentAmountsSum
        TokenContract
        TokenCompliant
        Token18Decimals
    {
        uint256 nextStreamId = sablierV2Pro.nextStreamId();

        // Make Alice the funder of the stream.
        changePrank(users.alice);
        createDefaultDaiStream();

        // Run the test.
        uint256 actualNextStreamId = sablierV2Pro.nextStreamId();
        uint256 expectedNextStreamId = nextStreamId + 1;
        assertEq(actualNextStreamId, expectedNextStreamId);
    }

    /// @dev it should emit a CreateStream event.
    function testCreate__CallerNotSender__Event() external {
        // Make Alice the funder of the stream.
        changePrank(users.alice);

        // Run the test.
        uint256 daiStreamId = sablierV2Pro.nextStreamId();
        vm.expectEmit(true, true, true, true);
        address funder = users.alice;
        emit CreateStream(
            daiStreamId,
            funder,
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

    modifier CallerSender() {
        _;
    }

    /// @dev it should create the stream.
    function testCreate()
        external
        RecipientNonZeroAddress
        DepositAmountNotZero
        SegmentCountNotZero
        SegmentCountWithinBounds
        SegmentCountsEqual
        StartTimeLessThanStopTime
        SegmentAmountsSumDoesNotOverflow
        SegmentMilestonesOrdered
        SegmentExponentsWithinBounds
        DepositAmountEqualtoSegmentAmountsSum
        TokenContract
        TokenCompliant
        Token18Decimals
        CallerSender
    {
        uint256 daiStreamId = createDefaultDaiStream();
        ISablierV2Pro.Stream memory actualStream = sablierV2Pro.getStream(daiStreamId);
        ISablierV2Pro.Stream memory expectedStream = daiStream;
        assertEq(actualStream, expectedStream);
    }

    /// @dev it should bump the next stream id.
    function testCreate__NextStreamId()
        external
        RecipientNonZeroAddress
        DepositAmountNotZero
        SegmentCountNotZero
        SegmentCountWithinBounds
        SegmentCountsEqual
        StartTimeLessThanStopTime
        SegmentAmountsSumDoesNotOverflow
        SegmentMilestonesOrdered
        SegmentExponentsWithinBounds
        DepositAmountEqualtoSegmentAmountsSum
        TokenContract
        TokenCompliant
        Token18Decimals
        CallerSender
    {
        uint256 nextStreamId = sablierV2Pro.nextStreamId();
        createDefaultDaiStream();
        uint256 actualNextStreamId = sablierV2Pro.nextStreamId();
        uint256 expectedNextStreamId = nextStreamId + 1;
        assertEq(actualNextStreamId, expectedNextStreamId);
    }

    /// @dev it should emit a CreateStream event.
    function testCreate__Event()
        external
        RecipientNonZeroAddress
        DepositAmountNotZero
        SegmentCountNotZero
        SegmentCountWithinBounds
        SegmentCountsEqual
        StartTimeLessThanStopTime
        SegmentAmountsSumDoesNotOverflow
        SegmentMilestonesOrdered
        SegmentExponentsWithinBounds
        DepositAmountEqualtoSegmentAmountsSum
        TokenContract
        TokenCompliant
        Token18Decimals
        CallerSender
    {
        uint256 daiStreamId = sablierV2Pro.nextStreamId();
        vm.expectEmit(true, true, true, true);
        address funder = daiStream.sender;
        emit CreateStream(
            daiStreamId,
            funder,
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
