// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ISablierV2 } from "@sablier/v2-core/interfaces/ISablierV2.sol";
import { ISablierV2Linear } from "@sablier/v2-core/interfaces/ISablierV2Linear.sol";

import { SablierV2LinearUnitTest } from "../SablierV2LinearUnitTest.t.sol";

contract SablierV2Linear__UnitTest__WithdrawAll is SablierV2LinearUnitTest {
    uint256[] internal defaultAmounts;
    uint256[] internal defaultStreamIds;

    /// @dev A setup function invoked before each test case.
    function setUp() public override {
        super.setUp();

        // Define the default amounts, since most tests need them.
        defaultAmounts.push(WITHDRAW_AMOUNT);
        defaultAmounts.push(WITHDRAW_AMOUNT);

        // Create the default streams, since most tests need them.
        defaultStreamIds.push(createDefaultStream());
        defaultStreamIds.push(createDefaultStream());

        // Make the recipient the `msg.sender` in this test suite.
        changePrank(users.recipient);
    }

    /// @dev When the array counts are not equal, it should revert.
    function testCannotWithdrawAll__WithdrawAllArraysNotEqual() external {
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

    /// @dev When the stream ids array points only to non existent streams, it should do nothing.
    function testCannotWithdrawAll__OnlyNonExistentStreams() external {
        uint256 nonStreamId = 1729;
        uint256[] memory nonStreamIds = createDynamicArray(nonStreamId);
        uint256[] memory amounts = createDynamicArray(WITHDRAW_AMOUNT);
        sablierV2Linear.withdrawAll(nonStreamIds, amounts);
    }

    /// @dev When the stream ids array points to some non existent streams, it should make the withdrawals for
    /// the existing streams.
    function testCannotWithdrawAll__SomeNonExistentStreams() external {
        uint256 nonStreamId = 1729;
        uint256[] memory streamIds = createDynamicArray(nonStreamId, defaultStreamIds[0]);

        // Warp to 100 seconds after the start time (1% of the default stream duration).
        vm.warp(stream.startTime + TIME_OFFSET);

        // Run the test.
        sablierV2Linear.withdrawAll(streamIds, defaultAmounts);
        ISablierV2Linear.Stream memory queriedStream = sablierV2Linear.getStream(defaultStreamIds[0]);
        uint256 actualWithdrawnAmount = queriedStream.withdrawnAmount;
        uint256 expectedWithdrawnAmount = WITHDRAW_AMOUNT;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount);
    }

    /// @dev When the caller is neither the sender nor the recipient of any stream, it should revert.
    function testCannotWithdrawAll__CallerUnauthorized__AllStreams() external {
        // Make Eve the `msg.sender` in this test case.
        changePrank(users.eve);

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(ISablierV2.SablierV2__Unauthorized.selector, defaultStreamIds[0], users.eve)
        );
        sablierV2Linear.withdrawAll(defaultStreamIds, defaultAmounts);
    }

    /// @dev When the caller is neither the sender nor the recipient of some of the streams, it should revert.
    function testCannotWithdrawAll__CallerUnauthorized__SomeStreams() external {
        // Make Eve the `msg.sender` in this test case.
        changePrank(users.eve);

        // Create a stream with Eve as the sender.
        uint256 streamIdEve = sablierV2Linear.create(
            users.eve,
            stream.recipient,
            stream.depositAmount,
            stream.token,
            stream.startTime,
            stream.stopTime,
            stream.cancelable
        );

        // Warp to 100 seconds after the start time (1% of the default stream duration).
        vm.warp(stream.startTime + TIME_OFFSET);

        // Run the test.
        uint256[] memory streamIds = createDynamicArray(streamIdEve, defaultStreamIds[0]);
        vm.expectRevert(
            abi.encodeWithSelector(ISablierV2.SablierV2__Unauthorized.selector, defaultStreamIds[0], users.eve)
        );
        sablierV2Linear.withdrawAll(streamIds, defaultAmounts);
    }

    /// @dev When the caller is the sender of all streams, it should make the withdrawals and update the
    /// withdrawn amounts.
    function testWithdrawAll__CallerSender__AllStreams() external {
        // Make the sender the `msg.sender` in this test case.
        changePrank(users.sender);

        // Warp to 100 seconds after the start time (1% of the default stream duration).
        vm.warp(stream.startTime + TIME_OFFSET);

        // Run the test.
        sablierV2Linear.withdrawAll(defaultStreamIds, defaultAmounts);
        ISablierV2Linear.Stream memory queriedStream0 = sablierV2Linear.getStream(defaultStreamIds[0]);
        ISablierV2Linear.Stream memory queriedStream1 = sablierV2Linear.getStream(defaultStreamIds[1]);

        uint256 actualWithdrawnAmount0 = queriedStream0.withdrawnAmount;
        uint256 actualWithdrawnAmount1 = queriedStream1.withdrawnAmount;
        uint256 expectedWithdrawnAmount0 = stream.withdrawnAmount + WITHDRAW_AMOUNT;
        uint256 expectedWithdrawnAmount1 = stream.withdrawnAmount + WITHDRAW_AMOUNT;

        assertEq(actualWithdrawnAmount0, expectedWithdrawnAmount0);
        assertEq(actualWithdrawnAmount1, expectedWithdrawnAmount1);
    }

    /// @dev When some amounts are zero, it should revert.
    function testCannotWithdrawAll__SomeAmountsZero() external {
        // Warp to 100 seconds after the start time (1% of the default stream duration).
        vm.warp(stream.startTime + TIME_OFFSET);

        // Run the test.
        uint256[] memory amounts = createDynamicArray(WITHDRAW_AMOUNT, 0);
        vm.expectRevert(abi.encodeWithSelector(ISablierV2.SablierV2__WithdrawAmountZero.selector, defaultStreamIds[1]));
        sablierV2Linear.withdrawAll(defaultStreamIds, amounts);
    }

    /// @dev When some amounts are greater than the withrawable amounts, it should revert.
    function testCannotWithdrawAll__SomeAmountsGreaterThanWithdrawableAmount() external {
        // Warp to 100 seconds after the start time (1% of the default stream duration).
        vm.warp(stream.startTime + TIME_OFFSET);

        // Run the test.
        uint256 withdrawableAmount = WITHDRAW_AMOUNT;
        uint256 withdrawAmountMaxUint256 = MAX_UINT_256;
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

    /// @dev When all streams are ended, it should make the withdrawals and delete the streams.
    function testWithdrawAll__AllStreamsEnded() external {
        // Warp to the end of the stream.
        vm.warp(stream.stopTime);

        // Run the test.
        uint256[] memory amounts = createDynamicArray(stream.depositAmount, stream.depositAmount);
        sablierV2Linear.withdrawAll(defaultStreamIds, amounts);

        ISablierV2Linear.Stream memory actualStream0 = sablierV2Linear.getStream(defaultStreamIds[0]);
        ISablierV2Linear.Stream memory actualStream1 = sablierV2Linear.getStream(defaultStreamIds[1]);
        ISablierV2Linear.Stream memory expectedStream;

        assertEq(actualStream0, expectedStream);
        assertEq(actualStream1, expectedStream);
    }

    /// @dev When all streams are ended, it should emit multiple Withdraw events.
    function testWithdrawAll__AllStreamsEnded__Events() external {
        // Warp to the end of the stream.
        vm.warp(stream.stopTime);

        // Run the test.
        uint256 withdrawAmount = stream.depositAmount;
        vm.expectEmit(true, true, false, true);
        emit Withdraw(defaultStreamIds[0], stream.recipient, withdrawAmount);
        vm.expectEmit(true, true, false, true);
        emit Withdraw(defaultStreamIds[1], stream.recipient, withdrawAmount);
        uint256[] memory amounts = createDynamicArray(withdrawAmount, withdrawAmount);
        sablierV2Linear.withdrawAll(defaultStreamIds, amounts);
    }

    /// @dev When all streams are ongoing, it should make the withdrawals and update the withdrawn amounts.
    function testWithdrawAll__AllStreamsOngoing() external {
        // Warp to 100 seconds after the start time (1% of the default stream duration).
        vm.warp(stream.startTime + TIME_OFFSET);

        // Run the test.
        sablierV2Linear.withdrawAll(defaultStreamIds, defaultAmounts);
        ISablierV2Linear.Stream memory queriedStream0 = sablierV2Linear.getStream(defaultStreamIds[0]);
        ISablierV2Linear.Stream memory queriedStream1 = sablierV2Linear.getStream(defaultStreamIds[1]);

        uint256 actualWithdrawnAmount0 = queriedStream0.withdrawnAmount;
        uint256 actualWithdrawnAmount1 = queriedStream1.withdrawnAmount;
        uint256 expectedWithdrawnAmount0 = stream.withdrawnAmount + WITHDRAW_AMOUNT;
        uint256 expectedWithdrawnAmount1 = stream.withdrawnAmount + WITHDRAW_AMOUNT;

        assertEq(actualWithdrawnAmount0, expectedWithdrawnAmount0);
        assertEq(actualWithdrawnAmount1, expectedWithdrawnAmount1);
    }

    /// @dev When all streams are ongoing, it should emit multiple Withdraw events.
    function testWithdrawAll__AllStreamsOngoing__Events() external {
        // Warp to 100 seconds after the start time (1% of the default stream duration).
        vm.warp(stream.startTime + TIME_OFFSET);

        // Run the test.
        uint256 withdrawAmount = WITHDRAW_AMOUNT;
        vm.expectEmit(true, true, false, true);
        emit Withdraw(defaultStreamIds[0], stream.recipient, withdrawAmount);
        vm.expectEmit(true, true, false, true);
        emit Withdraw(defaultStreamIds[1], stream.recipient, withdrawAmount);
        sablierV2Linear.withdrawAll(defaultStreamIds, defaultAmounts);
    }

    /// @dev When some streams are ended and some streams are ongoing, it should make the withdrawals, delete the
    /// ended streams and update the withdrawn amounts.
    function testWithdrawAll__SomeStreamsEndedSomeStreamsOngoing() external {
        // Create the ended stream.
        uint256 earlyStopTime = stream.startTime + TIME_OFFSET;
        uint256 endedStreamId = sablierV2Linear.create(
            stream.sender,
            stream.recipient,
            stream.depositAmount,
            stream.token,
            stream.startTime,
            earlyStopTime,
            stream.cancelable
        );

        // Use the first default stream as the ongoing stream.
        uint256 ongoingStreamId = defaultStreamIds[0];

        // Warp to the end of the early stream.
        vm.warp(earlyStopTime);

        // Run the test.
        uint256 endedWithdrawAmount = stream.depositAmount;
        uint256 ongoingWithdrawAmount = WITHDRAW_AMOUNT;
        uint256[] memory streamIds = createDynamicArray(endedStreamId, ongoingStreamId);
        uint256[] memory amounts = createDynamicArray(endedWithdrawAmount, ongoingWithdrawAmount);
        sablierV2Linear.withdrawAll(streamIds, amounts);

        ISablierV2Linear.Stream memory actualStream0 = sablierV2Linear.getStream(endedStreamId);
        ISablierV2Linear.Stream memory expectedStream0;
        assertEq(actualStream0, expectedStream0);

        ISablierV2Linear.Stream memory queriedStream1 = sablierV2Linear.getStream(ongoingStreamId);
        uint256 actualWithdrawnAmount1 = queriedStream1.withdrawnAmount;
        uint256 expectedWithdrawnAmount1 = stream.withdrawnAmount + WITHDRAW_AMOUNT;
        assertEq(actualWithdrawnAmount1, expectedWithdrawnAmount1);
    }

    /// @dev When some streams are ended and some streams are ongoing, it should emit Withdraw events.
    function testWithdrawAll__SomeStreamsEndedSomeStreamsOngoing__Events() external {
        // Create the ended stream.
        uint256 earlyStopTime = stream.startTime + TIME_OFFSET;
        uint256 endedStreamId = sablierV2Linear.create(
            stream.sender,
            stream.recipient,
            stream.depositAmount,
            stream.token,
            stream.startTime,
            earlyStopTime,
            stream.cancelable
        );

        // Use the first default stream as the ongoing stream.
        uint256 ongoingStreamId = defaultStreamIds[0];

        // Warp to the end of the early stream.
        vm.warp(earlyStopTime);

        // Run the test.
        uint256 endedWithdrawAmount = stream.depositAmount;
        uint256 ongoingWithdrawAmount = WITHDRAW_AMOUNT;

        vm.expectEmit(true, true, false, true);
        emit Withdraw(endedStreamId, stream.recipient, endedWithdrawAmount);
        vm.expectEmit(true, true, false, true);
        emit Withdraw(ongoingStreamId, stream.recipient, ongoingWithdrawAmount);

        uint256[] memory streamIds = createDynamicArray(endedStreamId, ongoingStreamId);
        uint256[] memory amounts = createDynamicArray(endedWithdrawAmount, ongoingWithdrawAmount);
        sablierV2Linear.withdrawAll(streamIds, amounts);
    }
}
