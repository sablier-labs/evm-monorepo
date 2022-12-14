// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { SafeERC20__CallToNonContract } from "@prb/contracts/token/erc20/SafeERC20.sol";
import { SD1x18 } from "@prb/math/SD1x18.sol";
import { stdError } from "forge-std/StdError.sol";

import { DataTypes } from "src/libraries/DataTypes.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Events } from "src/libraries/Events.sol";

import { SablierV2ProTest } from "../SablierV2ProTest.t.sol";

contract Create__Test is SablierV2ProTest {
    /// @dev it should revert.
    function testCannotCreate__RecipientZeroAddress() external {
        vm.expectRevert("ERC721: mint to the zero address");
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
        uint128 depositAmount = 0;
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
        uint128[] memory segmentAmounts;
        SD1x18[] memory segmentExponents;
        uint40[] memory segmentMilestones;
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
        uint128[] memory segmentAmounts = new uint128[](segmentCount);
        for (uint128 i = 0; i < segmentCount; ) {
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
        SD1x18[] memory segmentExponents = createDynamicArray(SEGMENT_EXPONENTS[0]);
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
        uint40[] memory segmentMilestones = createDynamicUint40Array(SEGMENT_MILESTONES[0]);
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
        uint128[] memory segmentAmounts = createDynamicUint128Array(UINT128_MAX, 1);
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
        uint40[] memory segmentMilestones = createDynamicUint40Array(SEGMENT_MILESTONES[1], SEGMENT_MILESTONES[0]);
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
    function testCannotCreate__DepositAmountNotEqualToSegmentAmountsSum()
        external
        RecipientNonZeroAddress
        DepositAmountNotZero
        SegmentCountNotZero
        SegmentCountWithinBounds
        SegmentCountsEqual
        SegmentAmountsSumDoesNotOverflow
        SegmentMilestonesOrdered
    {
        uint128 depositAmount = daiStream.depositAmount + 1;
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
        DepositAmountEqualToSegmentAmountsSum
    {
        vm.expectRevert(abi.encodeWithSelector(SafeERC20__CallToNonContract.selector, address(6174)));
        address token = address(6174);
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
        DepositAmountEqualToSegmentAmountsSum
        TokenContract
    {
        address token = address(nonCompliantToken);

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
        assertEq(actualStream.token, address(nonCompliantToken));
        assertEq(actualStream.startTime, daiStream.startTime);
        assertEq(actualStream.stopTime, daiStream.stopTime);
        assertEq(actualStream.cancelable, daiStream.cancelable);
        assertEq(actualStream.isEntity, daiStream.isEntity);
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
        DepositAmountEqualToSegmentAmountsSum
        TokenContract
        TokenCompliant
    {
        uint256 usdcStreamId = sablierV2Pro.nextStreamId();
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true });
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
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true });
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
        DepositAmountEqualToSegmentAmountsSum
        TokenContract
        TokenCompliant
    {
        uint256 daiStreamId = sablierV2Pro.nextStreamId();
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: true, checkData: true });
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
