// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { DataTypes } from "src/libraries/DataTypes.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Events } from "src/libraries/Events.sol";

import { SablierV2LinearTest } from "../SablierV2LinearTest.t.sol";

contract Withdraw__Test is SablierV2LinearTest {
    uint256 internal daiStreamId;

    /// @dev A setup function invoked before each test case.
    function setUp() public override {
        super.setUp();

        // Create the default stream, since most tests need it.
        daiStreamId = createDefaultDaiStream();

        // Make the recipient the caller in this test suite.
        changePrank(users.recipient);
    }

    /// @dev it should revert.
    function testCannotWithdraw__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2__StreamNonExistent.selector, nonStreamId));
        sablierV2Linear.withdraw(nonStreamId, users.recipient, WITHDRAW_AMOUNT_DAI);
    }

    modifier StreamExistent() {
        _;
    }

    /// @dev it should revert.
    function testCannotWithdraw__CallerUnauthorized__MaliciousThirdParty() external StreamExistent {
        // Make Eve the caller in this test.
        changePrank(users.eve);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2__Unauthorized.selector, daiStreamId, users.eve));
        sablierV2Linear.withdraw(daiStreamId, users.recipient, WITHDRAW_AMOUNT_DAI);
    }

    /// @dev it should revert.
    function testCannotWithdraw__CallerUnauthorized__Sender() external StreamExistent {
        // Make the sender the caller in this test.
        changePrank(users.sender);

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2__WithdrawSenderUnauthorized.selector,
                daiStreamId,
                users.sender,
                users.sender
            )
        );
        sablierV2Linear.withdraw(daiStreamId, users.sender, WITHDRAW_AMOUNT_DAI);
    }

    modifier CallerAuthorized() {
        _;
    }

    /// @dev it should revert.
    function testCannotWithdraw__ToZeroAddress() external StreamExistent CallerAuthorized {
        vm.expectRevert(Errors.SablierV2__WithdrawToZeroAddress.selector);
        sablierV2Linear.withdraw(daiStreamId, address(0), daiStream.depositAmount);
    }

    modifier ToNonZeroAddress() {
        _;
    }

    /// @dev it should make the withdrawal to the recipient and update the withdrawn amount.
    function testWithdraw__CallerSender() external StreamExistent CallerAuthorized ToNonZeroAddress {
        // Make the sender the caller in this test.
        changePrank(users.sender);

        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp({ timestamp: daiStream.startTime + TIME_OFFSET });

        // Run the test.
        sablierV2Linear.withdraw(daiStreamId, users.recipient, WITHDRAW_AMOUNT_DAI);
        uint128 actualWithdrawnAmount = sablierV2Linear.getWithdrawnAmount(daiStreamId);
        uint128 expectedWithdrawnAmount = WITHDRAW_AMOUNT_DAI;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount);
    }

    /// @dev it should make the withdrawal to the provided address and update the withdrawn amount.
    function testWithdraw__CallerApprovedOperator() external StreamExistent CallerAuthorized ToNonZeroAddress {
        // Approve the operator to handle the stream.
        sablierV2Linear.approve(users.operator, daiStreamId);

        // Make the operator the caller in this test.
        changePrank(users.operator);

        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp({ timestamp: daiStream.startTime + TIME_OFFSET });

        // Run the test.
        sablierV2Linear.withdraw(daiStreamId, users.recipient, WITHDRAW_AMOUNT_DAI);
        uint128 actualWithdrawnAmount = sablierV2Linear.getWithdrawnAmount(daiStreamId);
        uint128 expectedWithdrawnAmount = WITHDRAW_AMOUNT_DAI;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount);
    }

    modifier CallerRecipient() {
        _;
    }

    /// @dev it should revert.
    function testCannotWithdraw__OriginalRecipientTransferredOwnership()
        external
        StreamExistent
        CallerAuthorized
        ToNonZeroAddress
        CallerRecipient
    {
        // Transfer the stream to Alice.
        sablierV2Linear.transferFrom(users.recipient, users.alice, daiStreamId);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2__Unauthorized.selector, daiStreamId, users.recipient));
        sablierV2Linear.withdraw(daiStreamId, users.recipient, WITHDRAW_AMOUNT_DAI);
    }

    modifier OriginalRecipient() {
        _;
    }

    /// @dev it should revert.
    function testCannotWithdraw__WithdrawAmountZero()
        external
        StreamExistent
        CallerAuthorized
        ToNonZeroAddress
        CallerRecipient
        OriginalRecipient
    {
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2__WithdrawAmountZero.selector, daiStreamId));
        sablierV2Linear.withdraw(daiStreamId, users.recipient, 0);
    }

    modifier WithdrawAmountNotZero() {
        _;
    }

    /// @dev it should revert.
    function testCannotWithdraw__WithdrawAmountGreaterThanWithdrawableAmount()
        external
        StreamExistent
        CallerAuthorized
        ToNonZeroAddress
        CallerRecipient
        OriginalRecipient
        WithdrawAmountNotZero
    {
        uint128 withdrawableAmount = 0;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2__WithdrawAmountGreaterThanWithdrawableAmount.selector,
                daiStreamId,
                UINT128_MAX,
                withdrawableAmount
            )
        );
        sablierV2Linear.withdraw(daiStreamId, users.recipient, UINT128_MAX);
    }

    modifier WithdrawAmountLessThanOrEqualToWithdrawableAmount() {
        _;
    }

    /// @dev it should make the withdrawal to the recipient and update the withdrawn amount.
    function testWithdraw__ToRecipient()
        external
        StreamExistent
        CallerAuthorized
        ToNonZeroAddress
        CallerRecipient
        OriginalRecipient
        WithdrawAmountNotZero
        WithdrawAmountLessThanOrEqualToWithdrawableAmount
    {
        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp({ timestamp: daiStream.startTime + TIME_OFFSET });

        // Run the test.
        sablierV2Linear.withdraw(daiStreamId, users.recipient, WITHDRAW_AMOUNT_DAI);
        uint128 actualWithdrawnAmount = sablierV2Linear.getWithdrawnAmount(daiStreamId);
        uint128 expectedWithdrawnAmount = WITHDRAW_AMOUNT_DAI;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount);
    }

    modifier ToThirdParty() {
        _;
    }

    /// @dev it should make the withdrawal to the provided address and delete the stream.
    function testWithdraw__StreamEnded()
        external
        StreamExistent
        CallerAuthorized
        ToNonZeroAddress
        CallerRecipient
        OriginalRecipient
        WithdrawAmountNotZero
        WithdrawAmountLessThanOrEqualToWithdrawableAmount
        ToThirdParty
    {
        // Warp to the end of the stream.
        vm.warp({ timestamp: daiStream.stopTime });

        // Run the test.
        sablierV2Linear.withdraw(daiStreamId, users.alice, daiStream.depositAmount);
        DataTypes.LinearStream memory deletedStream = sablierV2Linear.getStream(daiStreamId);
        DataTypes.LinearStream memory expectedStream;
        assertEq(deletedStream, expectedStream);

        address actualRecipient = sablierV2Linear.getRecipient(daiStreamId);
        address expectedRecipient = users.recipient;
        assertEq(actualRecipient, expectedRecipient);
    }

    modifier StreamOngoing() {
        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp({ timestamp: daiStream.startTime + TIME_OFFSET });
        _;
    }

    /// @dev it should make the withdrawal to the provided address and update the withdrawn amount.
    function testWithdraw__RecipientNotContract()
        external
        StreamExistent
        CallerAuthorized
        ToNonZeroAddress
        CallerRecipient
        OriginalRecipient
        WithdrawAmountNotZero
        WithdrawAmountLessThanOrEqualToWithdrawableAmount
        ToThirdParty
        StreamOngoing
    {
        sablierV2Linear.withdraw(daiStreamId, users.recipient, WITHDRAW_AMOUNT_DAI);
        uint128 actualWithdrawnAmount = sablierV2Linear.getWithdrawnAmount(daiStreamId);
        uint128 expectedWithdrawnAmount = WITHDRAW_AMOUNT_DAI;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount);
    }

    modifier RecipientContract() {
        // Make the sender the caller in this test, because the recipient is a contract.
        changePrank(users.sender);
        _;
    }

    /// @dev it should make the withdrawal to the provided address and update the withdrawn amount.
    function testWithdraw__RecipientDoesNotImplementHook()
        external
        StreamExistent
        CallerAuthorized
        ToNonZeroAddress
        CallerRecipient
        OriginalRecipient
        WithdrawAmountNotZero
        WithdrawAmountLessThanOrEqualToWithdrawableAmount
        ToThirdParty
        StreamOngoing
        RecipientContract
    {
        daiStreamId = createDefaultDaiStreamWithRecipient(address(empty));
        sablierV2Linear.withdraw(daiStreamId, address(empty), WITHDRAW_AMOUNT_DAI);
        uint128 actualWithdrawnAmount = sablierV2Linear.getWithdrawnAmount(daiStreamId);
        uint128 expectedWithdrawnAmount = WITHDRAW_AMOUNT_DAI;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount);
    }

    modifier RecipientImplementsHook() {
        _;
    }

    /// @dev it should make the withdrawal to the provided address and update the withdrawn amount.
    function testWithdraw__RecipientReverts()
        external
        StreamExistent
        CallerAuthorized
        ToNonZeroAddress
        CallerRecipient
        OriginalRecipient
        WithdrawAmountNotZero
        WithdrawAmountLessThanOrEqualToWithdrawableAmount
        ToThirdParty
        StreamOngoing
        RecipientContract
        RecipientImplementsHook
    {
        daiStreamId = createDefaultDaiStreamWithRecipient(address(revertingRecipient));
        sablierV2Linear.withdraw(daiStreamId, address(revertingRecipient), WITHDRAW_AMOUNT_DAI);
        uint128 actualWithdrawnAmount = sablierV2Linear.getWithdrawnAmount(daiStreamId);
        uint128 expectedWithdrawnAmount = WITHDRAW_AMOUNT_DAI;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount);
    }

    modifier RecipientDoesNotRevert() {
        _;
    }

    /// @dev it should make the withdrawal to the provided address and update the withdrawn amount.
    function testWithdraw__Reentrancy()
        external
        StreamExistent
        CallerAuthorized
        ToNonZeroAddress
        CallerRecipient
        OriginalRecipient
        WithdrawAmountNotZero
        WithdrawAmountLessThanOrEqualToWithdrawableAmount
        ToThirdParty
        StreamOngoing
        RecipientContract
        RecipientImplementsHook
        RecipientDoesNotRevert
    {
        daiStreamId = createDefaultDaiStreamWithRecipient(address(reentrantRecipient));
        uint128 withdrawAmount = WITHDRAW_AMOUNT_DAI / 2;
        sablierV2Linear.withdraw(daiStreamId, address(reentrantRecipient), withdrawAmount);
        uint128 actualWithdrawnAmount = sablierV2Linear.getWithdrawnAmount(daiStreamId);
        uint128 expectedWithdrawnAmount = WITHDRAW_AMOUNT_DAI;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount);
    }

    modifier NoReentrancy() {
        _;
    }

    /// @dev it should make the withdrawal to the provided address and update the withdrawn amount.
    function testWithdraw()
        external
        StreamExistent
        CallerAuthorized
        ToNonZeroAddress
        CallerRecipient
        OriginalRecipient
        WithdrawAmountNotZero
        WithdrawAmountLessThanOrEqualToWithdrawableAmount
        ToThirdParty
        StreamOngoing
        RecipientContract
        RecipientImplementsHook
        RecipientDoesNotRevert
        NoReentrancy
    {
        daiStreamId = createDefaultDaiStreamWithRecipient(address(nonRevertingRecipient));
        sablierV2Linear.withdraw(daiStreamId, address(nonRevertingRecipient), WITHDRAW_AMOUNT_DAI);
        uint128 actualWithdrawnAmount = sablierV2Linear.getWithdrawnAmount(daiStreamId);
        uint128 expectedWithdrawnAmount = WITHDRAW_AMOUNT_DAI;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount);
    }

    /// @dev it should emit a Withdraw event.
    function testWithdraw__Event()
        external
        StreamExistent
        CallerAuthorized
        ToNonZeroAddress
        CallerRecipient
        OriginalRecipient
        WithdrawAmountNotZero
        WithdrawAmountLessThanOrEqualToWithdrawableAmount
        ToThirdParty
        StreamOngoing
        RecipientContract
        RecipientImplementsHook
        RecipientDoesNotRevert
        NoReentrancy
    {
        daiStreamId = createDefaultDaiStreamWithRecipient(address(nonRevertingRecipient));
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: false, checkData: true });
        emit Events.Withdraw({
            streamId: daiStreamId,
            to: address(nonRevertingRecipient),
            amount: WITHDRAW_AMOUNT_DAI
        });
        sablierV2Linear.withdraw(daiStreamId, address(nonRevertingRecipient), WITHDRAW_AMOUNT_DAI);
    }
}
