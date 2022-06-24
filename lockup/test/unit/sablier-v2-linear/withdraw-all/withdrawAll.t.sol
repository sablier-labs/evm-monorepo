// solhint-disable max-line-length
// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ISablierV2 } from "@sablier/v2-core/interfaces/ISablierV2.sol";
import { ISablierV2Linear } from "@sablier/v2-core/interfaces/ISablierV2Linear.sol";

import { SablierV2LinearUnitTest } from "../SablierV2LinearUnitTest.t.sol";

contract SablierV2Linear__WithdrawAll is SablierV2LinearUnitTest {
    uint256[] internal defaultAmounts;
    uint256[] internal defaultStreamIds;

    /// @dev A setup function invoked before each test case.
    function setUp() public override {
        super.setUp();

        // Define the default amounts, since most tests need them.
        defaultAmounts.push(WITHDRAW_AMOUNT_DAI);
        defaultAmounts.push(WITHDRAW_AMOUNT_DAI);

        // Create the default streams, since most tests need them.
        defaultStreamIds.push(createDefaultDaiStream());
        defaultStreamIds.push(createDefaultDaiStream());

        // Make the recipient the `msg.sender` in this test suite.
        changePrank(users.recipient);
    }
}

contract SablierV2Linear__WithdrawAll__ArraysNotEqual is SablierV2Linear__WithdrawAll {
    /// @dev it should revert.
    function testCannotWithdrawAll() external {
        uint256[] memory streamIds = new uint256[](2);
        uint256[] memory amounts = new uint256[](1);
        vm.expectRevert(
            abi.encodeWithSelector(
                ISablierV2.SablierV2__WithdrawAllArraysNotEqual.selector,
                streamIds.length,
                amounts.length
            )
        );
        sablierV2Linear.withdrawAll(streamIds, amounts);
    }
}

contract ArraysEqual {}

contract SablierV2Linear__WithdrawAll__OnlyNonExistentStreams is SablierV2Linear__WithdrawAll, ArraysEqual {
    /// @dev it should do nothing.
    function testCannotWithdrawAll() external {
        uint256 nonStreamId = 1729;
        uint256[] memory nonStreamIds = createDynamicArray(nonStreamId);
        uint256[] memory amounts = createDynamicArray(WITHDRAW_AMOUNT_DAI);
        sablierV2Linear.withdrawAll(nonStreamIds, amounts);
    }
}

contract SablierV2Linear__WithdrawAll__SomeNonExistentStreams is SablierV2Linear__WithdrawAll, ArraysEqual {
    /// @dev it should make the withdrawals for the existent streams.
    function testCannotWithdrawAll() external {
        uint256 nonStreamId = 1729;
        uint256[] memory streamIds = createDynamicArray(nonStreamId, defaultStreamIds[0]);

        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp(daiStream.startTime + TIME_OFFSET);

        // Run the test.
        sablierV2Linear.withdrawAll(streamIds, defaultAmounts);
        ISablierV2Linear.Stream memory queriedStream = sablierV2Linear.getStream(defaultStreamIds[0]);
        uint256 actualWithdrawnAmount = queriedStream.withdrawnAmount;
        uint256 expectedWithdrawnAmount = WITHDRAW_AMOUNT_DAI;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount);
    }
}

contract OnlyExistentStreams {}

contract SablierV2Linear__WithdrawAll__CallerUnauthorizedAllStreams is
    SablierV2Linear__WithdrawAll,
    ArraysEqual,
    OnlyExistentStreams
{
    /// @dev it should revert.
    function testCannotWithdrawAll() external {
        // Make Eve the `msg.sender` in this test case.
        changePrank(users.eve);

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(ISablierV2.SablierV2__Unauthorized.selector, defaultStreamIds[0], users.eve)
        );
        sablierV2Linear.withdrawAll(defaultStreamIds, defaultAmounts);
    }
}

contract SablierV2Linear__WithdrawAll__CallerUnauthorizedSomeStreams is
    SablierV2Linear__WithdrawAll,
    ArraysEqual,
    OnlyExistentStreams
{
    /// @dev it should revert.
    function testCannotWithdrawAll() external {
        // Make Eve the `msg.sender` in this test case.
        changePrank(users.eve);

        // Create a stream with Eve as the sender.
        uint256 eveStreamId = sablierV2Linear.create(
            users.eve,
            daiStream.recipient,
            daiStream.depositAmount,
            daiStream.token,
            daiStream.startTime,
            daiStream.cliffTime,
            daiStream.stopTime,
            daiStream.cancelable
        );

        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp(daiStream.startTime + TIME_OFFSET);

        // Run the test.
        uint256[] memory streamIds = createDynamicArray(eveStreamId, defaultStreamIds[0]);
        vm.expectRevert(
            abi.encodeWithSelector(ISablierV2.SablierV2__Unauthorized.selector, defaultStreamIds[0], users.eve)
        );
        sablierV2Linear.withdrawAll(streamIds, defaultAmounts);
    }
}

contract SablierV2Linear__WithdrawAll__CallerSenderAllStreams is SablierV2Linear__WithdrawAll {
    /// @dev it should make the withdrawals and update the withdrawn amounts.
    function testWithdrawAll() external {
        // Make the sender the `msg.sender` in this test case.
        changePrank(users.sender);

        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp(daiStream.startTime + TIME_OFFSET);

        // Run the test.
        sablierV2Linear.withdrawAll(defaultStreamIds, defaultAmounts);
        ISablierV2Linear.Stream memory queriedStream0 = sablierV2Linear.getStream(defaultStreamIds[0]);
        ISablierV2Linear.Stream memory queriedStream1 = sablierV2Linear.getStream(defaultStreamIds[1]);

        uint256 actualWithdrawnAmount0 = queriedStream0.withdrawnAmount;
        uint256 actualWithdrawnAmount1 = queriedStream1.withdrawnAmount;
        uint256 expectedWithdrawnAmount0 = WITHDRAW_AMOUNT_DAI;
        uint256 expectedWithdrawnAmount1 = WITHDRAW_AMOUNT_DAI;

        assertEq(actualWithdrawnAmount0, expectedWithdrawnAmount0);
        assertEq(actualWithdrawnAmount1, expectedWithdrawnAmount1);
    }
}

contract CallerRecipientAllStreams {}

contract SablierV2Linear__WithdrawAll__SomeAmountsZero is
    SablierV2Linear__WithdrawAll,
    ArraysEqual,
    OnlyExistentStreams,
    CallerRecipientAllStreams
{
    /// @dev it should revert.
    function testCannotWithdrawAll__SomeAmountsZero() external {
        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp(daiStream.startTime + TIME_OFFSET);

        // Run the test.
        uint256[] memory amounts = createDynamicArray(WITHDRAW_AMOUNT_DAI, 0);
        vm.expectRevert(abi.encodeWithSelector(ISablierV2.SablierV2__WithdrawAmountZero.selector, defaultStreamIds[1]));
        sablierV2Linear.withdrawAll(defaultStreamIds, amounts);
    }
}

contract AllAmountsNotZero {}

contract SablierV2Linear__WithdrawAll__SomeAmountsGreaterThanWithdrawableAmounts is
    SablierV2Linear__WithdrawAll,
    ArraysEqual,
    OnlyExistentStreams,
    CallerRecipientAllStreams,
    AllAmountsNotZero
{
    /// @dev it should revert.
    function testCannotWithdrawAll() external {
        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp(daiStream.startTime + TIME_OFFSET);

        // Run the test.
        uint256 withdrawableAmount = WITHDRAW_AMOUNT_DAI;
        uint256 withdrawAmountMaxUint256 = UINT256_MAX;
        uint256[] memory amounts = createDynamicArray(withdrawableAmount, withdrawAmountMaxUint256);
        vm.expectRevert(
            abi.encodeWithSelector(
                ISablierV2.SablierV2__WithdrawAmountGreaterThanWithdrawableAmount.selector,
                defaultStreamIds[1],
                withdrawAmountMaxUint256,
                withdrawableAmount
            )
        );
        sablierV2Linear.withdrawAll(defaultStreamIds, amounts);
    }
}

contract AllAmountsLessThanOrEqualToWithdrawableAmounts {}

contract SablierV2Linear__WithdrawAll__AllStreamEnded is
    SablierV2Linear__WithdrawAll,
    ArraysEqual,
    OnlyExistentStreams,
    CallerRecipientAllStreams,
    AllAmountsNotZero,
    AllAmountsLessThanOrEqualToWithdrawableAmounts
{
    /// @dev it should make the withdrawals and delete the streams.
    function testWithdrawAll() external {
        // Warp to the end of the stream.
        vm.warp(daiStream.stopTime);

        // Run the test.
        uint256[] memory amounts = createDynamicArray(daiStream.depositAmount, daiStream.depositAmount);
        sablierV2Linear.withdrawAll(defaultStreamIds, amounts);

        ISablierV2Linear.Stream memory actualStream0 = sablierV2Linear.getStream(defaultStreamIds[0]);
        ISablierV2Linear.Stream memory actualStream1 = sablierV2Linear.getStream(defaultStreamIds[1]);
        ISablierV2Linear.Stream memory expectedStream;

        assertEq(actualStream0, expectedStream);
        assertEq(actualStream1, expectedStream);
    }

    /// @dev it should emit multiple Withdraw events.
    function testWithdrawAll__Events() external {
        // Warp to the end of the stream.
        vm.warp(daiStream.stopTime);

        // Run the test.
        uint256 withdrawAmount = daiStream.depositAmount;
        vm.expectEmit(true, true, false, true);
        emit Withdraw(defaultStreamIds[0], daiStream.recipient, withdrawAmount);
        vm.expectEmit(true, true, false, true);
        emit Withdraw(defaultStreamIds[1], daiStream.recipient, withdrawAmount);
        uint256[] memory amounts = createDynamicArray(withdrawAmount, withdrawAmount);
        sablierV2Linear.withdrawAll(defaultStreamIds, amounts);
    }
}

contract SablierV2Linear__WithdrawAll__AllStreamsOngoing is
    SablierV2Linear__WithdrawAll,
    ArraysEqual,
    OnlyExistentStreams,
    CallerRecipientAllStreams,
    AllAmountsNotZero,
    AllAmountsLessThanOrEqualToWithdrawableAmounts
{
    /// @dev it should make the withdrawals and update the withdrawn amounts.
    function testWithdrawAll() external {
        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp(daiStream.startTime + TIME_OFFSET);

        // Run the test.
        sablierV2Linear.withdrawAll(defaultStreamIds, defaultAmounts);
        ISablierV2Linear.Stream memory queriedStream0 = sablierV2Linear.getStream(defaultStreamIds[0]);
        ISablierV2Linear.Stream memory queriedStream1 = sablierV2Linear.getStream(defaultStreamIds[1]);

        uint256 actualWithdrawnAmount0 = queriedStream0.withdrawnAmount;
        uint256 actualWithdrawnAmount1 = queriedStream1.withdrawnAmount;
        uint256 expectedWithdrawnAmount0 = WITHDRAW_AMOUNT_DAI;
        uint256 expectedWithdrawnAmount1 = WITHDRAW_AMOUNT_DAI;

        assertEq(actualWithdrawnAmount0, expectedWithdrawnAmount0);
        assertEq(actualWithdrawnAmount1, expectedWithdrawnAmount1);
    }

    /// @dev it should emit multiple Withdraw events.
    function testWithdrawAll__Events() external {
        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp(daiStream.startTime + TIME_OFFSET);

        // Run the test.
        uint256 withdrawAmount = WITHDRAW_AMOUNT_DAI;
        vm.expectEmit(true, true, false, true);
        emit Withdraw(defaultStreamIds[0], daiStream.recipient, withdrawAmount);
        vm.expectEmit(true, true, false, true);
        emit Withdraw(defaultStreamIds[1], daiStream.recipient, withdrawAmount);
        sablierV2Linear.withdrawAll(defaultStreamIds, defaultAmounts);
    }
}

contract SablierV2Linear__WithdrawAll__SomeStreamsEndedSomeStreamsOngoing is
    SablierV2Linear__WithdrawAll,
    ArraysEqual,
    OnlyExistentStreams,
    CallerRecipientAllStreams,
    AllAmountsNotZero,
    AllAmountsLessThanOrEqualToWithdrawableAmounts
{
    /// @dev it should make the withdrawals, delete the ended streams and update the withdrawn amounts.
    function testWithdrawAll__SomeStreamsEndedSomeStreamsOngoing() external {
        // Create the ended dai stream.
        changePrank(daiStream.sender);
        uint256 earlyStopTime = daiStream.startTime + TIME_OFFSET;
        uint256 endedDaiStreamId = sablierV2Linear.create(
            daiStream.sender,
            daiStream.recipient,
            daiStream.depositAmount,
            daiStream.token,
            daiStream.startTime,
            daiStream.cliffTime,
            earlyStopTime,
            daiStream.cancelable
        );
        changePrank(daiStream.recipient);

        // Use the first default stream as the ongoing daiStream.
        uint256 ongoingStreamId = defaultStreamIds[0];

        // Warp to the end of the early daiStream.
        vm.warp(earlyStopTime);

        // Run the test.
        uint256 endedWithdrawAmount = daiStream.depositAmount;
        uint256 ongoingWithdrawAmount = WITHDRAW_AMOUNT_DAI;
        uint256[] memory streamIds = createDynamicArray(endedDaiStreamId, ongoingStreamId);
        uint256[] memory amounts = createDynamicArray(endedWithdrawAmount, ongoingWithdrawAmount);
        sablierV2Linear.withdrawAll(streamIds, amounts);

        ISablierV2Linear.Stream memory actualStream0 = sablierV2Linear.getStream(endedDaiStreamId);
        ISablierV2Linear.Stream memory expectedStream0;
        assertEq(actualStream0, expectedStream0);

        ISablierV2Linear.Stream memory queriedStream1 = sablierV2Linear.getStream(ongoingStreamId);
        uint256 actualWithdrawnAmount1 = queriedStream1.withdrawnAmount;
        uint256 expectedWithdrawnAmount1 = WITHDRAW_AMOUNT_DAI;
        assertEq(actualWithdrawnAmount1, expectedWithdrawnAmount1);
    }

    /// @dev it should emit multiple Withdraw events.
    function testWithdrawAll__Events() external {
        // Create the ended dai stream.
        changePrank(daiStream.sender);
        uint256 earlyStopTime = daiStream.startTime + TIME_OFFSET;
        uint256 endedDaiStreamId = sablierV2Linear.create(
            daiStream.sender,
            daiStream.recipient,
            daiStream.depositAmount,
            daiStream.token,
            daiStream.startTime,
            daiStream.cliffTime,
            earlyStopTime,
            daiStream.cancelable
        );
        changePrank(daiStream.recipient);

        // Use the first default stream as the ongoing daiStream.
        uint256 ongoingStreamId = defaultStreamIds[0];

        // Warp to the end of the early daiStream.
        vm.warp(earlyStopTime);

        // Run the test.
        uint256 endedWithdrawAmount = daiStream.depositAmount;
        uint256 ongoingWithdrawAmount = WITHDRAW_AMOUNT_DAI;

        vm.expectEmit(true, true, false, true);
        emit Withdraw(endedDaiStreamId, daiStream.recipient, endedWithdrawAmount);
        vm.expectEmit(true, true, false, true);
        emit Withdraw(ongoingStreamId, daiStream.recipient, ongoingWithdrawAmount);

        uint256[] memory streamIds = createDynamicArray(endedDaiStreamId, ongoingStreamId);
        uint256[] memory amounts = createDynamicArray(endedWithdrawAmount, ongoingWithdrawAmount);
        sablierV2Linear.withdrawAll(streamIds, amounts);
    }
}
