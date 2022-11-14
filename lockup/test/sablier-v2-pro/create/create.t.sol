// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { DataTypes } from "@sablier/v2-core/libraries/DataTypes.sol";
import { Errors } from "@sablier/v2-core/libraries/Errors.sol";
import { Events } from "@sablier/v2-core/libraries/Events.sol";
import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";
import { SafeERC20__CallToNonContract } from "@prb/contracts/token/erc20/SafeERC20.sol";
import { SCALE, SD59x18 } from "@prb/math/SD59x18.sol";
import { stdError } from "forge-std/StdError.sol";

import { SablierV2ProBaseTest } from "../SablierV2ProBaseTest.t.sol";

contract Create__Tests is SablierV2ProBaseTest {
    /// @dev it should revert.
    function testCannotCreate__RecipientZeroAddress() external {
        vm.expectRevert(Errors.SablierV2__RecipientZeroAddress.selector);
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
        vm.expectRevert(Errors.SablierV2__DepositAmountZero.selector);
        uint256 depositAmount = 0;
        sablierV2Pro.create(
            daiStream.sender,
            users.recipient,
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
        vm.expectRevert(Errors.SablierV2Pro__SegmentCountZero.selector);
        uint256[] memory segmentAmounts;
        SD59x18[] memory segmentExponents;
        uint64[] memory segmentMilestones;
        sablierV2Pro.create(
            daiStream.sender,
            users.recipient,
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
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Pro__SegmentCountOutOfBounds.selector, segmentCount));
        uint256[] memory segmentAmounts = new uint256[](segmentCount);
        for (uint256 i = 0; i < segmentCount; ) {
            segmentAmounts[i] = i;
            unchecked {
                i += 1;
            }
        }
        sablierV2Pro.create(
            daiStream.sender,
            users.recipient,
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
                Errors.SablierV2Pro__SegmentCountsNotEqual.selector,
                daiStream.segmentAmounts.length,
                segmentExponents.length,
                daiStream.segmentMilestones.length
            )
        );
        sablierV2Pro.create(
            daiStream.sender,
            users.recipient,
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
        uint64[] memory segmentMilestones = createDynamicUint64Array(SEGMENT_MILESTONES[0]);
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2Pro__SegmentCountsNotEqual.selector,
                daiStream.segmentAmounts.length,
                daiStream.segmentExponents.length,
                segmentMilestones.length
            )
        );
        sablierV2Pro.create(
            daiStream.sender,
            users.recipient,
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

    /// @dev When the segment amounts sum overflows, it should revert.
    function testCannotCreate__SegmentAmountsSumOverflows()
        external
        RecipientNonZeroAddress
        DepositAmountNotZero
        SegmentCountNotZero
        SegmentCountWithinBounds
        SegmentCountsEqual
    {
        uint256[] memory segmentAmounts = createDynamicArray(UINT256_MAX, 1);
        vm.expectRevert(stdError.arithmeticError);
        sablierV2Pro.create(
            daiStream.sender,
            users.recipient,
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
        SegmentAmountsSumDoesNotOverflow
    {
        uint64[] memory segmentMilestones = createDynamicUint64Array(SEGMENT_MILESTONES[1], SEGMENT_MILESTONES[0]);
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2Pro__SegmentMilestonesNotOrdered.selector,
                1,
                segmentMilestones[0],
                segmentMilestones[1]
            )
        );
        sablierV2Pro.create(
            daiStream.sender,
            users.recipient,
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
        SegmentAmountsSumDoesNotOverflow
        SegmentMilestonesOrdered
    {
        SD59x18 outOfBoundsExponent = sablierV2Pro.MAX_EXPONENT().uncheckedAdd(SCALE);
        SD59x18[] memory segmentExponents = createDynamicArray(SEGMENT_EXPONENTS[0], outOfBoundsExponent);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Pro__SegmentExponentOutOfBounds.selector, outOfBoundsExponent)
        );
        sablierV2Pro.create(
            daiStream.sender,
            users.recipient,
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
    function testCannotCreate__DepositAmountNotEqualToSegmentAmountsSum()
        external
        RecipientNonZeroAddress
        DepositAmountNotZero
        SegmentCountNotZero
        SegmentCountWithinBounds
        SegmentCountsEqual
        SegmentAmountsSumDoesNotOverflow
        SegmentMilestonesOrdered
        SegmentExponentsWithinBounds
    {
        uint256 depositAmount = daiStream.depositAmount + 1;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2Pro__DepositAmountNotEqualToSegmentAmountsSum.selector,
                depositAmount,
                daiStream.depositAmount
            )
        );
        sablierV2Pro.create(
            daiStream.sender,
            users.recipient,
            depositAmount,
            daiStream.token,
            daiStream.startTime,
            daiStream.segmentAmounts,
            daiStream.segmentExponents,
            daiStream.segmentMilestones,
            daiStream.cancelable
        );
    }

    modifier DepositAmountEqualToSegmentAmountsSum() {
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
        SegmentAmountsSumDoesNotOverflow
        SegmentMilestonesOrdered
        SegmentExponentsWithinBounds
        DepositAmountEqualToSegmentAmountsSum
    {
        vm.expectRevert(abi.encodeWithSelector(SafeERC20__CallToNonContract.selector, address(6174)));
        IERC20 token = IERC20(address(6174));
        sablierV2Pro.create(
            daiStream.sender,
            users.recipient,
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
        SegmentAmountsSumDoesNotOverflow
        SegmentMilestonesOrdered
        SegmentExponentsWithinBounds
        DepositAmountEqualToSegmentAmountsSum
        TokenContract
    {
        IERC20 token = IERC20(address(nonCompliantToken));

        uint256 daiStreamId = sablierV2Pro.create(
            daiStream.sender,
            users.recipient,
            daiStream.depositAmount,
            token,
            daiStream.startTime,
            daiStream.segmentAmounts,
            daiStream.segmentExponents,
            daiStream.segmentMilestones,
            daiStream.cancelable
        );

        DataTypes.ProStream memory actualStream = sablierV2Pro.getStream(daiStreamId);
        assertEq(actualStream.sender, daiStream.sender);
        assertEq(actualStream.depositAmount, daiStream.depositAmount);
        assertEq(address(actualStream.token), address(nonCompliantToken));
        assertEq(actualStream.startTime, daiStream.startTime);
        assertEq(actualStream.stopTime, daiStream.stopTime);
        assertEq(actualStream.cancelable, daiStream.cancelable);
        assertEq(actualStream.withdrawnAmount, daiStream.withdrawnAmount);

        address actualRecipient = sablierV2Pro.getRecipient(daiStreamId);
        assertEq(actualRecipient, users.recipient);
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
        SegmentAmountsSumDoesNotOverflow
        SegmentMilestonesOrdered
        SegmentExponentsWithinBounds
        DepositAmountEqualToSegmentAmountsSum
        TokenContract
        TokenCompliant
    {
        uint256 usdcStreamId = createDefaultUsdcStream();
        DataTypes.ProStream memory actualStream = sablierV2Pro.getStream(usdcStreamId);
        DataTypes.ProStream memory expectedStream = usdcStream;
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
        SegmentAmountsSumDoesNotOverflow
        SegmentMilestonesOrdered
        SegmentExponentsWithinBounds
        DepositAmountEqualToSegmentAmountsSum
        TokenContract
        TokenCompliant
    {
        uint256 nextStreamId = sablierV2Pro.nextStreamId();
        createDefaultUsdcStream();
        uint256 actualNextStreamId = sablierV2Pro.nextStreamId();
        uint256 expectedNextStreamId = nextStreamId + 1;
        assertEq(actualNextStreamId, expectedNextStreamId);
    }

    /// @dev it should emit a CreateProStream event.
    function testCreate__Token6Decimals__Event()
        external
        RecipientNonZeroAddress
        DepositAmountNotZero
        SegmentCountNotZero
        SegmentCountWithinBounds
        SegmentCountsEqual
        SegmentAmountsSumDoesNotOverflow
        SegmentMilestonesOrdered
        SegmentExponentsWithinBounds
        DepositAmountEqualToSegmentAmountsSum
        TokenContract
        TokenCompliant
    {
        uint256 usdcStreamId = sablierV2Pro.nextStreamId();
        vm.expectEmit(true, true, true, true);
        address funder = usdcStream.sender;
        emit Events.CreateProStream(
            usdcStreamId,
            funder,
            usdcStream.sender,
            users.recipient,
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

    /// @dev it should create the stream.
    function testCreate__Token18Decimals__CallerNotSender()
        external
        RecipientNonZeroAddress
        DepositAmountNotZero
        SegmentCountNotZero
        SegmentCountWithinBounds
        SegmentCountsEqual
        SegmentAmountsSumDoesNotOverflow
        SegmentMilestonesOrdered
        SegmentExponentsWithinBounds
        DepositAmountEqualToSegmentAmountsSum
        TokenContract
        TokenCompliant
    {
        // Make Alice the funder of the stream.
        changePrank(users.alice);
        uint256 daiStreamId = createDefaultDaiStream();

        // Run the test.
        DataTypes.ProStream memory actualStream = sablierV2Pro.getStream(daiStreamId);
        DataTypes.ProStream memory expectedStream = daiStream;
        assertEq(actualStream, expectedStream);
    }

    /// @dev it should bump the next stream id.
    function testCreate__Token18Decimals__CallerNotSender__NextStreamId()
        external
        RecipientNonZeroAddress
        DepositAmountNotZero
        SegmentCountNotZero
        SegmentCountWithinBounds
        SegmentCountsEqual
        SegmentAmountsSumDoesNotOverflow
        SegmentMilestonesOrdered
        SegmentExponentsWithinBounds
        DepositAmountEqualToSegmentAmountsSum
        TokenContract
        TokenCompliant
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

    /// @dev it should emit a CreateProStream event.
    function testCreate__Token18Decimals__CallerNotSender__Event() external {
        // Make Alice the funder of the stream.
        changePrank(users.alice);

        // Run the test.
        uint256 daiStreamId = sablierV2Pro.nextStreamId();
        vm.expectEmit(true, true, true, true);
        address funder = users.alice;
        emit Events.CreateProStream(
            daiStreamId,
            funder,
            daiStream.sender,
            users.recipient,
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

    /// @dev it should create the stream.
    function testCreate__Token18Decimals__CallerSender()
        external
        RecipientNonZeroAddress
        DepositAmountNotZero
        SegmentCountNotZero
        SegmentCountWithinBounds
        SegmentCountsEqual
        SegmentAmountsSumDoesNotOverflow
        SegmentMilestonesOrdered
        SegmentExponentsWithinBounds
        DepositAmountEqualToSegmentAmountsSum
        TokenContract
        TokenCompliant
    {
        uint256 daiStreamId = createDefaultDaiStream();
        DataTypes.ProStream memory actualStream = sablierV2Pro.getStream(daiStreamId);
        DataTypes.ProStream memory expectedStream = daiStream;
        assertEq(actualStream, expectedStream);
    }

    /// @dev it should bump the next stream id.
    function testCreate__Token18Decimals__CallerSender__NextStreamId()
        external
        RecipientNonZeroAddress
        DepositAmountNotZero
        SegmentCountNotZero
        SegmentCountWithinBounds
        SegmentCountsEqual
        SegmentAmountsSumDoesNotOverflow
        SegmentMilestonesOrdered
        SegmentExponentsWithinBounds
        DepositAmountEqualToSegmentAmountsSum
        TokenContract
        TokenCompliant
    {
        uint256 nextStreamId = sablierV2Pro.nextStreamId();
        createDefaultDaiStream();
        uint256 actualNextStreamId = sablierV2Pro.nextStreamId();
        uint256 expectedNextStreamId = nextStreamId + 1;
        assertEq(actualNextStreamId, expectedNextStreamId);
    }

    /// @dev it should emit a CreateProStream event.
    function testCreate__Token18Decimals__CallerSender__Event()
        external
        RecipientNonZeroAddress
        DepositAmountNotZero
        SegmentCountNotZero
        SegmentCountWithinBounds
        SegmentCountsEqual
        SegmentAmountsSumDoesNotOverflow
        SegmentMilestonesOrdered
        SegmentExponentsWithinBounds
        DepositAmountEqualToSegmentAmountsSum
        TokenContract
        TokenCompliant
    {
        uint256 daiStreamId = sablierV2Pro.nextStreamId();
        vm.expectEmit(true, true, true, true);
        address funder = daiStream.sender;
        emit Events.CreateProStream(
            daiStreamId,
            funder,
            daiStream.sender,
            users.recipient,
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
