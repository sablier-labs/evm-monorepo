// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { DataTypes } from "@sablier/v2-core/libraries/DataTypes.sol";
import { Errors } from "@sablier/v2-core/libraries/Errors.sol";
import { Events } from "@sablier/v2-core/libraries/Events.sol";

import { SablierV2LinearBaseTest } from "../SablierV2LinearBaseTest.t.sol";

contract WithdrawTo__Tests is SablierV2LinearBaseTest {
    uint256 internal daiStreamId;
    address internal toAlice;

    /// @dev A setup function invoked before each test case.
    function setUp() public override {
        super.setUp();

        // Create the default stream, since most tests need it.
        daiStreamId = createDefaultDaiStream();

        // Make the recipient the `msg.sender` in this test suite.
        changePrank(users.recipient);

        // Make Alice the address that will receive the tokens.
        toAlice = users.alice;
    }

    /// @dev it should revert.
    function testCannotWithdrawTo__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2__StreamNonExistent.selector, nonStreamId));
        uint256 withdrawAmount = 0;
        sablierV2Linear.withdrawTo(nonStreamId, toAlice, withdrawAmount);
    }

    modifier StreamExistent() {
        _;
    }

    /// @dev When the to address is zero, it should revert.
    function testCannotWithdrawTo__ToZeroAddress() external StreamExistent {
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2__WithdrawZeroAddress.selector));
        address toZero = address(0);
        uint256 withdrawAmount = 0;
        sablierV2Linear.withdrawTo(daiStreamId, toZero, withdrawAmount);
    }

    modifier ToNonZeroAddress() {
        _;
    }

    /// @dev it should revert.
    function testCannotWithdrawTo__CallerSender() external StreamExistent ToNonZeroAddress {
        // Make Eve the `msg.sender` in this test case.
        changePrank(users.sender);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2__Unauthorized.selector, daiStreamId, users.sender));
        uint256 withdrawAmount = 0;
        sablierV2Linear.withdrawTo(daiStreamId, toAlice, withdrawAmount);
    }

    /// @dev it should revert.
    function testCannotWithdrawTo__CallerThirdParty() external StreamExistent ToNonZeroAddress {
        // Make Eve the `msg.sender` in this test case.
        changePrank(users.eve);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2__Unauthorized.selector, daiStreamId, users.eve));
        uint256 withdrawAmount = 0;
        sablierV2Linear.withdrawTo(daiStreamId, toAlice, withdrawAmount);
    }

    modifier CallerAuthorized() {
        _;
    }

    /// @dev it should make the withdrawal.
    function testWithdrawTo__CallerApprovedOperator() external StreamExistent ToNonZeroAddress CallerAuthorized {
        // Approve the operator to handle the stream.
        sablierV2Linear.approve(users.operator, daiStreamId);

        // Make the operator the `msg.sender` in this test case.
        changePrank(users.operator);

        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp(daiStream.startTime + TIME_OFFSET);

        // Run the test.
        sablierV2Linear.withdrawTo(daiStreamId, toAlice, WITHDRAW_AMOUNT_DAI);
        DataTypes.LinearStream memory actualStream = sablierV2Linear.getStream(daiStreamId);
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
        ToNonZeroAddress
        CallerAuthorized
        CallerRecipient
    {
        // Transfer the stream to Alice.
        sablierV2Linear.transferFrom(users.recipient, users.alice, daiStreamId);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2__Unauthorized.selector, daiStreamId, users.recipient));
        sablierV2Linear.withdrawTo(daiStreamId, toAlice, daiStream.depositAmount);
    }

    modifier OriginalRecipient() {
        _;
    }

    /// @dev it should revert.
    function testCannotWithdrawTo__WithdrawAmountZero()
        external
        StreamExistent
        ToNonZeroAddress
        CallerAuthorized
        CallerRecipient
        OriginalRecipient
    {
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2__WithdrawAmountZero.selector, daiStreamId));
        uint256 withdrawAmountZero = 0;
        sablierV2Linear.withdrawTo(daiStreamId, toAlice, withdrawAmountZero);
    }

    modifier WithdrawAmountNotZero() {
        _;
    }

    /// @dev When the amount is greater than the withdrawable amount, it should revert.
    function testCannotWithdrawTo__WithdrawAmountGreaterThanWithdrawableAmount()
        external
        StreamExistent
        ToNonZeroAddress
        CallerAuthorized
        CallerRecipient
        OriginalRecipient
        WithdrawAmountNotZero
    {
        uint256 withdrawAmountMaxUint256 = UINT256_MAX;
        uint256 withdrawableAmount = 0;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2__WithdrawAmountGreaterThanWithdrawableAmount.selector,
                daiStreamId,
                withdrawAmountMaxUint256,
                withdrawableAmount
            )
        );
        sablierV2Linear.withdrawTo(daiStreamId, toAlice, withdrawAmountMaxUint256);
    }

    modifier WithdrawAmountLessThanOrEqualToWithdrawableAmount() {
        _;
    }

    /// @dev When the to address is the recipient, it should make the withdrawal.
    function testWithdrawTo__ToRecipient()
        external
        StreamExistent
        ToNonZeroAddress
        CallerAuthorized
        CallerRecipient
        OriginalRecipient
        WithdrawAmountNotZero
        WithdrawAmountLessThanOrEqualToWithdrawableAmount
    {
        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp(daiStream.startTime + TIME_OFFSET);

        // Run the test.
        sablierV2Linear.withdrawTo(daiStreamId, users.recipient, WITHDRAW_AMOUNT_DAI);
        DataTypes.LinearStream memory actualStream = sablierV2Linear.getStream(daiStreamId);
        uint256 actualWithdrawnAmount = actualStream.withdrawnAmount;
        uint256 expectedWithdrawnAmount = WITHDRAW_AMOUNT_DAI;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount);
    }

    modifier ToThirdParty() {
        _;
    }

    /// @dev it should make the withdrawal and delete the stream and burn the NFT.
    function testWithdrawTo__StreamEnded()
        external
        StreamExistent
        ToNonZeroAddress
        CallerAuthorized
        CallerRecipient
        OriginalRecipient
        WithdrawAmountNotZero
        WithdrawAmountLessThanOrEqualToWithdrawableAmount
        ToThirdParty
    {
        // Warp to the end of the stream.
        vm.warp(daiStream.stopTime);

        // Run the test.
        sablierV2Linear.withdrawTo(daiStreamId, toAlice, daiStream.depositAmount);
        DataTypes.LinearStream memory deletedStream = sablierV2Linear.getStream(daiStreamId);
        DataTypes.LinearStream memory expectedStream;
        assertEq(deletedStream, expectedStream);

        address actualRecipient = sablierV2Linear.getRecipient(daiStreamId);
        address expectedRecipient = address(0);
        assertEq(actualRecipient, expectedRecipient);
    }

    /// @dev it should emit a Withdraw event.
    function testWithdrawTo__StreamEnded__Event()
        external
        StreamExistent
        ToNonZeroAddress
        CallerAuthorized
        CallerRecipient
        OriginalRecipient
        WithdrawAmountNotZero
        WithdrawAmountLessThanOrEqualToWithdrawableAmount
        ToThirdParty
    {
        // Warp to the end of the stream.
        vm.warp(daiStream.stopTime);

        // Run the test.
        vm.expectEmit(true, true, false, true);
        emit Events.Withdraw(daiStreamId, toAlice, daiStream.depositAmount);
        sablierV2Linear.withdrawTo(daiStreamId, toAlice, daiStream.depositAmount);
    }

    /// @dev it should make the withdrawal and update the withdrawn amount.
    function testWithdrawTo__StreamOngoing()
        external
        StreamExistent
        ToNonZeroAddress
        CallerAuthorized
        CallerRecipient
        OriginalRecipient
        WithdrawAmountNotZero
        WithdrawAmountLessThanOrEqualToWithdrawableAmount
        ToThirdParty
    {
        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp(daiStream.startTime + TIME_OFFSET);

        // Run the test.
        sablierV2Linear.withdrawTo(daiStreamId, toAlice, WITHDRAW_AMOUNT_DAI);
        DataTypes.LinearStream memory actualStream = sablierV2Linear.getStream(daiStreamId);
        uint256 actualWithdrawnAmount = actualStream.withdrawnAmount;
        uint256 expectedWithdrawnAmount = WITHDRAW_AMOUNT_DAI;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount);
    }

    /// @dev it should emit a Withdraw event.
    function testWithdrawTo__StreamOngoing__Event()
        external
        StreamExistent
        ToNonZeroAddress
        CallerAuthorized
        CallerRecipient
        OriginalRecipient
        WithdrawAmountNotZero
        WithdrawAmountLessThanOrEqualToWithdrawableAmount
        ToThirdParty
    {
        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp(daiStream.startTime + TIME_OFFSET);

        // Run the test.
        vm.expectEmit(true, true, false, true);
        emit Events.Withdraw(daiStreamId, toAlice, WITHDRAW_AMOUNT_DAI);
        sablierV2Linear.withdrawTo(daiStreamId, toAlice, WITHDRAW_AMOUNT_DAI);
    }
}
