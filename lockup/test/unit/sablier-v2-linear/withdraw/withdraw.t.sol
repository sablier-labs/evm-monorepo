// solhint-disable max-line-length
// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { ISablierV2 } from "@sablier/v2-core/interfaces/ISablierV2.sol";
import { ISablierV2Linear } from "@sablier/v2-core/interfaces/ISablierV2Linear.sol";

import { SablierV2LinearUnitTest } from "../SablierV2LinearUnitTest.t.sol";

contract SablierV2Linear__Withdraw is SablierV2LinearUnitTest {
    uint256 internal daiStreamId;

    /// @dev A setup function invoked before each test case.
    function setUp() public override {
        super.setUp();

        // Create the default stream, since most tests need it.
        daiStreamId = createDefaultDaiStream();

        // Make the recipient the `msg.sender` in this test suite.
        changePrank(users.recipient);
    }

    /// @dev it should revert.
    function testCannotWithdraw__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(ISablierV2.SablierV2__StreamNonExistent.selector, nonStreamId));
        uint256 withdrawAmountZero = 0;
        sablierV2Linear.withdraw(nonStreamId, withdrawAmountZero);
    }

    modifier StreamExistent() {
        _;
    }

    /// @dev it should revert.
    function testCannotWithdraw__CallerUnauthorized() external StreamExistent {
        // Make Eve the `msg.sender` in this test case.
        changePrank(users.eve);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(ISablierV2.SablierV2__Unauthorized.selector, daiStreamId, users.eve));
        uint256 withdrawAmount = 0;
        sablierV2Linear.withdraw(daiStreamId, withdrawAmount);
    }

    modifier CallerAuthorized() {
        _;
    }

    /// @dev it should make the withdrawal and update the withdrawn amount.
    function testWithdraw__CallerSender() external StreamExistent CallerAuthorized {
        // Make the sender the `msg.sender` in this test case.
        changePrank(users.sender);

        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp(daiStream.startTime + TIME_OFFSET);

        // Run the test.
        sablierV2Linear.withdraw(daiStreamId, WITHDRAW_AMOUNT_DAI);
        ISablierV2Linear.Stream memory actualStream = sablierV2Linear.getStream(daiStreamId);
        uint256 actualWithdrawnAmount = actualStream.withdrawnAmount;
        uint256 expectedWithdrawnAmount = WITHDRAW_AMOUNT_DAI;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount);
    }

    /// @dev it should make the withdrawal and update the withdrawn amount.
    function testWithdraw__CallerApprovedOperator() external StreamExistent CallerAuthorized {
        // Approve the operator to handle the stream.
        sablierV2Linear.approve(users.operator, daiStreamId);

        // Make the operator the `msg.sender` in this test case.
        changePrank(users.operator);

        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp(daiStream.startTime + TIME_OFFSET);

        // Run the test.
        sablierV2Linear.withdraw(daiStreamId, WITHDRAW_AMOUNT_DAI);
        ISablierV2Linear.Stream memory actualStream = sablierV2Linear.getStream(daiStreamId);
        uint256 actualWithdrawnAmount = actualStream.withdrawnAmount;
        uint256 expectedWithdrawnAmount = WITHDRAW_AMOUNT_DAI;
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
        CallerRecipient
    {
        // Transfer the stream to Alice.
        sablierV2Linear.safeTransferFrom(users.recipient, users.alice, daiStreamId);

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(ISablierV2.SablierV2__Unauthorized.selector, daiStreamId, users.recipient)
        );
        sablierV2Linear.withdraw(daiStreamId, daiStream.depositAmount);
    }

    modifier OriginalRecipient() {
        _;
    }

    /// @dev it should revert.
    function testCannotWithdraw__WithdrawAmountZero()
        external
        StreamExistent
        CallerAuthorized
        CallerRecipient
        OriginalRecipient
    {
        vm.expectRevert(abi.encodeWithSelector(ISablierV2.SablierV2__WithdrawAmountZero.selector, daiStreamId));
        uint256 withdrawAmountZero = 0;
        sablierV2Linear.withdraw(daiStreamId, withdrawAmountZero);
    }

    modifier WithdrawAmountNotZero() {
        _;
    }

    /// @dev it should revert.
    function testCannotWithdraw__WithdrawAmountGreaterThanWithdrawableAmount()
        external
        StreamExistent
        CallerAuthorized
        CallerRecipient
        OriginalRecipient
        WithdrawAmountNotZero
    {
        uint256 withdrawAmountMaxUint256 = UINT256_MAX;
        uint256 withdrawableAmount = 0;
        vm.expectRevert(
            abi.encodeWithSelector(
                ISablierV2.SablierV2__WithdrawAmountGreaterThanWithdrawableAmount.selector,
                daiStreamId,
                withdrawAmountMaxUint256,
                withdrawableAmount
            )
        );
        sablierV2Linear.withdraw(daiStreamId, withdrawAmountMaxUint256);
    }

    modifier WithdrawAmountLessThanOrEqualToWithdrawableAmount() {
        _;
    }

    /// @dev it should make the withdrawal and delete the stream and burn the NFT.
    function testWithdraw__StreamEnded()
        external
        StreamExistent
        CallerAuthorized
        CallerRecipient
        OriginalRecipient
        WithdrawAmountNotZero
        WithdrawAmountLessThanOrEqualToWithdrawableAmount
    {
        // Warp to the end of the stream.
        vm.warp(daiStream.stopTime);

        // Run the test.
        sablierV2Linear.withdraw(daiStreamId, daiStream.depositAmount);
        ISablierV2Linear.Stream memory deletedStream = sablierV2Linear.getStream(daiStreamId);
        ISablierV2Linear.Stream memory expectedStream;
        assertEq(deletedStream, expectedStream);

        address actualRecipient = sablierV2Linear.getRecipient(daiStreamId);
        address expectedRecipient = address(0);
        assertEq(actualRecipient, expectedRecipient);
    }

    /// @dev it should emit a Withdraw event.
    function testWithdraw__StreamEnded__Event()
        external
        StreamExistent
        CallerAuthorized
        CallerRecipient
        OriginalRecipient
        WithdrawAmountNotZero
        WithdrawAmountLessThanOrEqualToWithdrawableAmount
    {
        // Warp to the end of the stream.
        vm.warp(daiStream.stopTime);

        // Run the test.
        vm.expectEmit(true, true, false, true);
        emit Withdraw(daiStreamId, users.recipient, daiStream.depositAmount);
        sablierV2Linear.withdraw(daiStreamId, daiStream.depositAmount);
    }

    /// @dev it should make the withdrawal and update the withdrawn amount.
    function testWithdraw__StreamOngoing()
        external
        StreamExistent
        CallerAuthorized
        CallerRecipient
        OriginalRecipient
        WithdrawAmountNotZero
        WithdrawAmountLessThanOrEqualToWithdrawableAmount
    {
        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp(daiStream.startTime + TIME_OFFSET);

        // Run the test.
        sablierV2Linear.withdraw(daiStreamId, WITHDRAW_AMOUNT_DAI);
        ISablierV2Linear.Stream memory actualStream = sablierV2Linear.getStream(daiStreamId);
        uint256 actualWithdrawnAmount = actualStream.withdrawnAmount;
        uint256 expectedWithdrawnAmount = WITHDRAW_AMOUNT_DAI;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount);
    }

    /// @dev it should emit a Withdraw event.
    function testWithdraw__StreamOngoing__Event()
        external
        StreamExistent
        CallerAuthorized
        CallerRecipient
        OriginalRecipient
        WithdrawAmountNotZero
        WithdrawAmountLessThanOrEqualToWithdrawableAmount
    {
        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp(daiStream.startTime + TIME_OFFSET);

        // Run the test.
        vm.expectEmit(true, true, false, true);
        emit Withdraw(daiStreamId, users.recipient, WITHDRAW_AMOUNT_DAI);
        sablierV2Linear.withdraw(daiStreamId, WITHDRAW_AMOUNT_DAI);
    }
}
