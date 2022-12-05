// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { DataTypes } from "src/libraries/DataTypes.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Events } from "src/libraries/Events.sol";

import { SablierV2LinearTest } from "../SablierV2LinearTest.t.sol";

contract WithdrawAllTo__Test is SablierV2LinearTest {
    uint128[] internal defaultAmounts;
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

    /// @dev it should revert.
    function testCannotWithdrawAllTo__ToZeroAddress() external {
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2__WithdrawZeroAddress.selector));
        sablierV2Linear.withdrawAllTo({ streamIds: defaultStreamIds, to: address(0), amounts: defaultAmounts });
    }

    modifier ToNonZeroAddress() {
        _;
    }

    /// @dev it should revert.
    function testCannotWithdrawAllTo__ArraysNotEqual() external ToNonZeroAddress {
        uint256[] memory streamIds = new uint256[](2);
        uint128[] memory amounts = new uint128[](1);
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2__WithdrawAllArraysNotEqual.selector,
                streamIds.length,
                amounts.length
            )
        );
        sablierV2Linear.withdrawAllTo({ streamIds: streamIds, to: users.alice, amounts: amounts });
    }

    modifier ArraysEqual() {
        _;
    }

    /// @dev it should do nothing.
    function testCannotWithdrawAllTo__OnlyNonExistentStreams() external ToNonZeroAddress ArraysEqual {
        uint256 nonStreamId = 1729;
        uint256[] memory nonStreamIds = createDynamicArray(nonStreamId);
        uint128[] memory amounts = createDynamicUint128Array(WITHDRAW_AMOUNT_DAI);
        sablierV2Linear.withdrawAllTo({ streamIds: nonStreamIds, to: users.alice, amounts: amounts });
    }

    /// @dev it should make the withdrawals for the existent streams.
    function testCannotWithdrawAllTo__SomeNonExistentStreams() external ToNonZeroAddress ArraysEqual {
        uint256 nonStreamId = 1729;
        uint256[] memory streamIds = createDynamicArray(nonStreamId, defaultStreamIds[0]);

        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp({ timestamp: daiStream.startTime + TIME_OFFSET });

        // Run the test.
        sablierV2Linear.withdrawAllTo({ streamIds: streamIds, to: users.alice, amounts: defaultAmounts });
        DataTypes.LinearStream memory queriedStream = sablierV2Linear.getStream(defaultStreamIds[0]);
        uint128 actualWithdrawnAmount = queriedStream.withdrawnAmount;
        uint128 expectedWithdrawnAmount = WITHDRAW_AMOUNT_DAI;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount);
    }

    modifier OnlyExistentStreams() {
        _;
    }

    /// @dev it should revert.
    function testCannotWithdrawAllTo__CallerSenderAllStreams()
        external
        ToNonZeroAddress
        ArraysEqual
        OnlyExistentStreams
    {
        // Make the sender the `msg.sender` in this test case.
        changePrank(users.sender);

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2__Unauthorized.selector, defaultStreamIds[0], users.sender)
        );
        sablierV2Linear.withdrawAllTo({ streamIds: defaultStreamIds, to: users.alice, amounts: defaultAmounts });
    }

    /// @dev it should revert.
    function testCannotWithdrawAllTo__CallerUnauthorizedThirdPartyAllStreams()
        external
        ToNonZeroAddress
        ArraysEqual
        OnlyExistentStreams
    {
        // Make eve the `msg.sender` in this test case.
        changePrank(users.eve);

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2__Unauthorized.selector, defaultStreamIds[0], users.eve)
        );
        sablierV2Linear.withdrawAllTo({ streamIds: defaultStreamIds, to: users.alice, amounts: defaultAmounts });
    }

    /// @dev it should revert.
    function testCannotWithdrawAllTo__CallerSenderSomeStreams()
        external
        ToNonZeroAddress
        ArraysEqual
        OnlyExistentStreams
    {
        // Create a stream with the sender as the recipient (reversing their roles).
        changePrank(users.recipient);
        uint256 reversedStreamId = sablierV2Linear.create(
            users.recipient,
            daiStream.sender,
            daiStream.depositAmount,
            daiStream.token,
            daiStream.startTime,
            daiStream.cliffTime,
            daiStream.stopTime,
            daiStream.cancelable
        );

        // Make Eve the sender the caller in the rest of this test case.
        changePrank(users.sender);

        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp({ timestamp: daiStream.startTime + TIME_OFFSET });

        // Run the test.
        uint256[] memory streamIds = createDynamicArray(reversedStreamId, defaultStreamIds[0]);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2__Unauthorized.selector, defaultStreamIds[0], users.sender)
        );
        sablierV2Linear.withdrawAllTo({ streamIds: streamIds, to: users.alice, amounts: defaultAmounts });
    }

    /// @dev it should revert.
    function testCannotWithdrawAllTo__CallerUnauthorizedThirdPartySomeStreams()
        external
        ToNonZeroAddress
        ArraysEqual
        OnlyExistentStreams
    {
        // Create a stream with Eve as the recipient.
        changePrank(users.sender);
        uint256 eveStreamId = sablierV2Linear.create(
            daiStream.sender,
            users.eve,
            daiStream.depositAmount,
            daiStream.token,
            daiStream.startTime,
            daiStream.cliffTime,
            daiStream.stopTime,
            daiStream.cancelable
        );

        // Make Eve the `msg.sender` the caller in the rest of this test case.
        changePrank(users.eve);

        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp({ timestamp: daiStream.startTime + TIME_OFFSET });

        // Run the test.
        uint256[] memory streamIds = createDynamicArray(eveStreamId, defaultStreamIds[0]);
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2__Unauthorized.selector, defaultStreamIds[0], users.eve)
        );
        sablierV2Linear.withdrawAllTo({ streamIds: streamIds, to: users.alice, amounts: defaultAmounts });
    }

    modifier CallerAuthorizedAllStreams() {
        _;
    }

    /// @dev it should make the withdrawals and update the withdrawn amounts.
    function testWithdrawAllTo__CallerApprovedOperatorAllStreams()
        external
        ToNonZeroAddress
        ArraysEqual
        OnlyExistentStreams
        CallerAuthorizedAllStreams
    {
        // Approve the operator for all streams.
        sablierV2Linear.setApprovalForAll({ operator: users.operator, approved: true });

        // Make the operator the `msg.sender` in this test case.
        changePrank(users.operator);

        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp({ timestamp: daiStream.startTime + TIME_OFFSET });

        // Run the test.
        sablierV2Linear.withdrawAllTo({ streamIds: defaultStreamIds, to: users.alice, amounts: defaultAmounts });
        DataTypes.LinearStream memory queriedStream0 = sablierV2Linear.getStream(defaultStreamIds[0]);
        DataTypes.LinearStream memory queriedStream1 = sablierV2Linear.getStream(defaultStreamIds[1]);

        uint128 actualWithdrawnAmount0 = queriedStream0.withdrawnAmount;
        uint128 actualWithdrawnAmount1 = queriedStream1.withdrawnAmount;
        uint128 expectedWithdrawnAmount0 = WITHDRAW_AMOUNT_DAI;
        uint128 expectedWithdrawnAmount1 = WITHDRAW_AMOUNT_DAI;

        assertEq(actualWithdrawnAmount0, expectedWithdrawnAmount0);
        assertEq(actualWithdrawnAmount1, expectedWithdrawnAmount1);
    }

    modifier CallerRecipientAllStreams() {
        _;
    }

    /// @dev it should revert.
    function testCannotWithdrawAllTo__OriginalRecipientTransferredOwnershipAllStreams()
        external
        ToNonZeroAddress
        ArraysEqual
        OnlyExistentStreams
        CallerAuthorizedAllStreams
        CallerRecipientAllStreams
    {
        // Transfer the streams to eve.
        sablierV2Linear.transferFrom(users.recipient, users.eve, defaultStreamIds[0]);
        sablierV2Linear.transferFrom(users.recipient, users.eve, defaultStreamIds[1]);

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2__Unauthorized.selector, defaultStreamIds[0], users.recipient)
        );
        sablierV2Linear.withdrawAllTo({ streamIds: defaultStreamIds, to: users.alice, amounts: defaultAmounts });
    }

    /// @dev it should revert.
    function testCannotWithdrawAllTo__OriginalRecipientTransferredOwnershipSomeStreams()
        external
        ToNonZeroAddress
        ArraysEqual
        OnlyExistentStreams
        CallerAuthorizedAllStreams
        CallerRecipientAllStreams
    {
        // Transfer one of the streams to eve.
        sablierV2Linear.transferFrom(users.recipient, users.eve, defaultStreamIds[0]);

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2__Unauthorized.selector, defaultStreamIds[0], users.recipient)
        );
        sablierV2Linear.withdrawAllTo({ streamIds: defaultStreamIds, to: users.alice, amounts: defaultAmounts });
    }

    modifier OriginalRecipientAllStreams() {
        _;
    }

    /// @dev it should revert.
    function testCannotWithdrawAllTo__SomeAmountsZero()
        external
        ToNonZeroAddress
        ArraysEqual
        OnlyExistentStreams
        CallerAuthorizedAllStreams
        CallerRecipientAllStreams
        OriginalRecipientAllStreams
    {
        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp({ timestamp: daiStream.startTime + TIME_OFFSET });

        // Run the test.
        uint128[] memory amounts = createDynamicUint128Array(WITHDRAW_AMOUNT_DAI, 0);
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2__WithdrawAmountZero.selector, defaultStreamIds[1]));
        sablierV2Linear.withdrawAllTo({ streamIds: defaultStreamIds, to: users.alice, amounts: amounts });
    }

    modifier AllAmountsNotZero() {
        _;
    }

    /// @dev it should revert.
    function testCannotWithdrawAllTo__SomeAmountsGreaterThanWithdrawableAmounts()
        external
        ToNonZeroAddress
        ArraysEqual
        OnlyExistentStreams
        CallerAuthorizedAllStreams
        CallerRecipientAllStreams
        OriginalRecipientAllStreams
        AllAmountsNotZero
    {
        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp({ timestamp: daiStream.startTime + TIME_OFFSET });

        // Run the test.
        uint128 withdrawableAmount = WITHDRAW_AMOUNT_DAI;
        uint128[] memory amounts = createDynamicUint128Array(withdrawableAmount, UINT128_MAX);
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2__WithdrawAmountGreaterThanWithdrawableAmount.selector,
                defaultStreamIds[1],
                UINT128_MAX,
                withdrawableAmount
            )
        );
        sablierV2Linear.withdrawAllTo({ streamIds: defaultStreamIds, to: users.alice, amounts: amounts });
    }

    modifier AllAmountsLessThanOrEqualToWithdrawableAmounts() {
        _;
    }

    /// @dev it should make the withdrawals and update the withdrawn amounts.
    function testWithdrawAllTo__ToRecipient()
        external
        ToNonZeroAddress
        ArraysEqual
        OnlyExistentStreams
        CallerAuthorizedAllStreams
        CallerRecipientAllStreams
        OriginalRecipientAllStreams
        AllAmountsNotZero
        AllAmountsLessThanOrEqualToWithdrawableAmounts
    {
        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp({ timestamp: daiStream.startTime + TIME_OFFSET });

        // Run the test.
        sablierV2Linear.withdrawAllTo({ streamIds: defaultStreamIds, to: users.recipient, amounts: defaultAmounts });
        DataTypes.LinearStream memory queriedStream0 = sablierV2Linear.getStream(defaultStreamIds[0]);
        DataTypes.LinearStream memory queriedStream1 = sablierV2Linear.getStream(defaultStreamIds[1]);

        uint128 actualWithdrawnAmount0 = queriedStream0.withdrawnAmount;
        uint128 actualWithdrawnAmount1 = queriedStream1.withdrawnAmount;
        uint128 expectedWithdrawnAmount0 = WITHDRAW_AMOUNT_DAI;
        uint128 expectedWithdrawnAmount1 = WITHDRAW_AMOUNT_DAI;

        assertEq(actualWithdrawnAmount0, expectedWithdrawnAmount0);
        assertEq(actualWithdrawnAmount1, expectedWithdrawnAmount1);
    }

    modifier ToThirdParty() {
        _;
    }

    /// @dev it should make the withdrawals, delete the streams and burn the NFTs.
    function testWithdrawAllTo__AllStreamsEnded()
        external
        ToNonZeroAddress
        ArraysEqual
        OnlyExistentStreams
        CallerAuthorizedAllStreams
        CallerRecipientAllStreams
        OriginalRecipientAllStreams
        AllAmountsNotZero
        AllAmountsLessThanOrEqualToWithdrawableAmounts
        ToThirdParty
    {
        // Warp to the end of the stream.
        vm.warp({ timestamp: daiStream.stopTime });

        // Run the test.
        uint128[] memory amounts = createDynamicUint128Array(daiStream.depositAmount, daiStream.depositAmount);
        sablierV2Linear.withdrawAllTo({ streamIds: defaultStreamIds, to: users.alice, amounts: amounts });

        DataTypes.LinearStream memory actualStream0 = sablierV2Linear.getStream(defaultStreamIds[0]);
        DataTypes.LinearStream memory actualStream1 = sablierV2Linear.getStream(defaultStreamIds[1]);
        DataTypes.LinearStream memory expectedStream;

        assertEq(actualStream0, expectedStream);
        assertEq(actualStream1, expectedStream);

        address actualRecipient0 = sablierV2Linear.getRecipient(defaultStreamIds[0]);
        address actualRecipient1 = sablierV2Linear.getRecipient(defaultStreamIds[1]);
        address expectedRecipient = address(0);
        assertEq(actualRecipient0, expectedRecipient);
        assertEq(actualRecipient1, expectedRecipient);
    }

    /// @dev it should emit multiple Withdraw events.
    function testWithdrawAllTo__AllStreamsEnded__Events()
        external
        ToNonZeroAddress
        ArraysEqual
        OnlyExistentStreams
        CallerAuthorizedAllStreams
        CallerRecipientAllStreams
        OriginalRecipientAllStreams
        AllAmountsNotZero
        AllAmountsLessThanOrEqualToWithdrawableAmounts
        ToThirdParty
    {
        // Warp to the end of the stream.
        vm.warp({ timestamp: daiStream.stopTime });

        // Run the test.
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: false, checkData: true });
        emit Events.Withdraw({
            streamId: defaultStreamIds[0],
            recipient: users.alice,
            amount: daiStream.depositAmount
        });
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: false, checkData: true });
        emit Events.Withdraw({
            streamId: defaultStreamIds[1],
            recipient: users.alice,
            amount: daiStream.depositAmount
        });

        uint128[] memory amounts = createDynamicUint128Array(daiStream.depositAmount, daiStream.depositAmount);
        sablierV2Linear.withdrawAllTo({ streamIds: defaultStreamIds, to: users.alice, amounts: amounts });
    }

    /// @dev it should make the withdrawals and update the withdrawn amounts.
    function testWithdrawAllTo__AllStreamsOngoing()
        external
        ToNonZeroAddress
        ArraysEqual
        OnlyExistentStreams
        CallerAuthorizedAllStreams
        CallerRecipientAllStreams
        OriginalRecipientAllStreams
        AllAmountsNotZero
        AllAmountsLessThanOrEqualToWithdrawableAmounts
        ToThirdParty
    {
        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp({ timestamp: daiStream.startTime + TIME_OFFSET });

        // Run the test.
        sablierV2Linear.withdrawAllTo({ streamIds: defaultStreamIds, to: users.alice, amounts: defaultAmounts });
        DataTypes.LinearStream memory queriedStream0 = sablierV2Linear.getStream(defaultStreamIds[0]);
        DataTypes.LinearStream memory queriedStream1 = sablierV2Linear.getStream(defaultStreamIds[1]);

        uint128 actualWithdrawnAmount0 = queriedStream0.withdrawnAmount;
        uint128 actualWithdrawnAmount1 = queriedStream1.withdrawnAmount;
        uint128 expectedWithdrawnAmount0 = WITHDRAW_AMOUNT_DAI;
        uint128 expectedWithdrawnAmount1 = WITHDRAW_AMOUNT_DAI;

        assertEq(actualWithdrawnAmount0, expectedWithdrawnAmount0);
        assertEq(actualWithdrawnAmount1, expectedWithdrawnAmount1);
    }

    /// @dev it should emit multiple Withdraw events.
    function testWithdrawAllTo__AllStreamsOngoing__Events()
        external
        ToNonZeroAddress
        ArraysEqual
        OnlyExistentStreams
        CallerAuthorizedAllStreams
        CallerRecipientAllStreams
        OriginalRecipientAllStreams
        AllAmountsNotZero
        AllAmountsLessThanOrEqualToWithdrawableAmounts
        ToThirdParty
    {
        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp({ timestamp: daiStream.startTime + TIME_OFFSET });

        // Run the test.
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: false, checkData: true });
        emit Events.Withdraw({ streamId: defaultStreamIds[0], recipient: users.alice, amount: WITHDRAW_AMOUNT_DAI });
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: false, checkData: true });
        emit Events.Withdraw({ streamId: defaultStreamIds[1], recipient: users.alice, amount: WITHDRAW_AMOUNT_DAI });

        sablierV2Linear.withdrawAllTo({ streamIds: defaultStreamIds, to: users.alice, amounts: defaultAmounts });
    }

    /// @dev it should make the withdrawals, delete the ended streams and burn the NFTs,
    /// and update the withdrawn amounts.
    function testWithdrawAllTo__SomeStreamsEndedSomeStreamsOngoing()
        external
        ToNonZeroAddress
        ArraysEqual
        OnlyExistentStreams
        CallerAuthorizedAllStreams
        CallerRecipientAllStreams
        OriginalRecipientAllStreams
        AllAmountsNotZero
        AllAmountsLessThanOrEqualToWithdrawableAmounts
        ToThirdParty
    {
        // Create the ended dai stream.
        changePrank(daiStream.sender);
        uint40 earlyStopTime = daiStream.startTime + TIME_OFFSET;
        uint256 endedDaiStreamId = sablierV2Linear.create(
            daiStream.sender,
            users.recipient,
            daiStream.depositAmount,
            daiStream.token,
            daiStream.startTime,
            daiStream.cliffTime,
            earlyStopTime,
            daiStream.cancelable
        );
        changePrank(users.recipient);

        // Use the first default stream as the ongoing DAI stream.
        uint256 ongoingStreamId = defaultStreamIds[0];

        // Warp to the end of the early DAI stream.
        vm.warp({ timestamp: earlyStopTime });

        // Run the test.
        uint128 endedWithdrawAmount = daiStream.depositAmount;
        uint128 ongoingWithdrawAmount = WITHDRAW_AMOUNT_DAI;
        uint256[] memory streamIds = createDynamicArray(endedDaiStreamId, ongoingStreamId);
        uint128[] memory amounts = createDynamicUint128Array(endedWithdrawAmount, ongoingWithdrawAmount);
        sablierV2Linear.withdrawAllTo({ streamIds: streamIds, to: users.alice, amounts: amounts });

        DataTypes.LinearStream memory actualEndedStream = sablierV2Linear.getStream(endedDaiStreamId);
        DataTypes.LinearStream memory expectedEndedStream;
        assertEq(actualEndedStream, expectedEndedStream);

        address actualEndedRecipient = sablierV2Linear.getRecipient(endedDaiStreamId);
        address expectedEndedRecipient = address(0);
        assertEq(actualEndedRecipient, expectedEndedRecipient);

        DataTypes.LinearStream memory queriedStream = sablierV2Linear.getStream(ongoingStreamId);
        uint128 actualWithdrawnAmount = queriedStream.withdrawnAmount;
        uint128 expectedWithdrawnAmount = WITHDRAW_AMOUNT_DAI;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount);
    }

    /// @dev it should emit Withdraw events.
    function testWithdrawAllTo__SomeStreamsEndedSomeStreamsOngoing__Events()
        external
        ToNonZeroAddress
        ArraysEqual
        OnlyExistentStreams
        CallerAuthorizedAllStreams
        CallerRecipientAllStreams
        OriginalRecipientAllStreams
        AllAmountsNotZero
        AllAmountsLessThanOrEqualToWithdrawableAmounts
        ToThirdParty
    {
        // Create the ended dai stream.
        changePrank(daiStream.sender);
        uint40 earlyStopTime = daiStream.startTime + TIME_OFFSET;
        uint256 endedDaiStreamId = sablierV2Linear.create(
            daiStream.sender,
            users.recipient,
            daiStream.depositAmount,
            daiStream.token,
            daiStream.startTime,
            daiStream.cliffTime,
            earlyStopTime,
            daiStream.cancelable
        );
        changePrank(users.recipient);

        // Use the first default stream as the ongoing DAI stream.
        uint256 ongoingStreamId = defaultStreamIds[0];

        // Warp to the end of the early DAI stream.
        vm.warp({ timestamp: earlyStopTime });

        // Run the test.
        uint128 endedWithdrawAmount = daiStream.depositAmount;
        uint128 ongoingWithdrawAmount = WITHDRAW_AMOUNT_DAI;

        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: false, checkData: true });
        emit Events.Withdraw({ streamId: endedDaiStreamId, recipient: users.alice, amount: endedWithdrawAmount });
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: false, checkData: true });
        emit Events.Withdraw({ streamId: ongoingStreamId, recipient: users.alice, amount: ongoingWithdrawAmount });

        uint256[] memory streamIds = createDynamicArray(endedDaiStreamId, ongoingStreamId);
        uint128[] memory amounts = createDynamicUint128Array(endedWithdrawAmount, ongoingWithdrawAmount);
        sablierV2Linear.withdrawAllTo({ streamIds: streamIds, to: users.alice, amounts: amounts });
    }
}
