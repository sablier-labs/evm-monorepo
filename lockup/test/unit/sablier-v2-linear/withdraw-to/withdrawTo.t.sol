// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { DataTypes } from "src/libraries/DataTypes.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Events } from "src/libraries/Events.sol";

import { SablierV2LinearTest } from "../SablierV2LinearTest.t.sol";

contract WithdrawTo__Test is SablierV2LinearTest {
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
    function testCannotWithdrawTo__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2__StreamNonExistent.selector, nonStreamId));
        uint128 withdrawAmount = 0;
        sablierV2Linear.withdrawTo({ streamId: nonStreamId, to: users.alice, amount: withdrawAmount });
    }

    modifier StreamExistent() {
        _;
    }

    /// @dev When the to address is zero, it should revert.
    function testCannotWithdrawTo__ToZeroAddress() external StreamExistent {
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2__WithdrawZeroAddress.selector));
        sablierV2Linear.withdrawTo({ streamId: daiStreamId, to: address(0), amount: 0 });
    }

    modifier ToNonZeroAddress() {
        _;
    }

    /// @dev it should revert.
    function testCannotWithdrawTo__CallerSender() external StreamExistent ToNonZeroAddress {
        // Make Eve the caller in this test.
        changePrank(users.sender);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2__Unauthorized.selector, daiStreamId, users.sender));
        sablierV2Linear.withdrawTo({ streamId: daiStreamId, to: users.alice, amount: 0 });
    }

    /// @dev it should revert.
    function testCannotWithdrawTo__CallerThirdParty() external StreamExistent ToNonZeroAddress {
        // Make Eve the caller in this test.
        changePrank(users.eve);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2__Unauthorized.selector, daiStreamId, users.eve));
        sablierV2Linear.withdrawTo({ streamId: daiStreamId, to: users.alice, amount: 0 });
    }

    modifier CallerAuthorized() {
        _;
    }

    /// @dev it should make the withdrawal.
    function testWithdrawTo__CallerApprovedOperator() external StreamExistent ToNonZeroAddress CallerAuthorized {
        // Approve the operator to handle the stream.
        sablierV2Linear.approve({ to: users.operator, tokenId: daiStreamId });

        // Make the approved operator the caller in this test.
        changePrank(users.operator);

        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp({ timestamp: daiStream.startTime + TIME_OFFSET });

        // Run the test.
        sablierV2Linear.withdrawTo({ streamId: daiStreamId, to: users.alice, amount: WITHDRAW_AMOUNT_DAI });
        DataTypes.LinearStream memory actualStream = sablierV2Linear.getStream(daiStreamId);
        uint128 actualWithdrawnAmount = actualStream.withdrawnAmount;
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
        ToNonZeroAddress
        CallerAuthorized
        CallerRecipient
    {
        // Transfer the stream to Alice.
        sablierV2Linear.transferFrom(users.recipient, users.alice, daiStreamId);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2__Unauthorized.selector, daiStreamId, users.recipient));
        sablierV2Linear.withdrawTo({ streamId: daiStreamId, to: users.alice, amount: daiStream.depositAmount });
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
        sablierV2Linear.withdrawTo({ streamId: daiStreamId, to: users.alice, amount: 0 });
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
        uint128 withdrawableAmount = 0;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2__WithdrawAmountGreaterThanWithdrawableAmount.selector,
                daiStreamId,
                UINT128_MAX,
                withdrawableAmount
            )
        );
        sablierV2Linear.withdrawTo({ streamId: daiStreamId, to: users.alice, amount: UINT128_MAX });
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
        vm.warp({ timestamp: daiStream.startTime + TIME_OFFSET });

        // Run the test.
        sablierV2Linear.withdrawTo(daiStreamId, users.recipient, WITHDRAW_AMOUNT_DAI);
        DataTypes.LinearStream memory actualStream = sablierV2Linear.getStream(daiStreamId);
        uint128 actualWithdrawnAmount = actualStream.withdrawnAmount;
        uint128 expectedWithdrawnAmount = WITHDRAW_AMOUNT_DAI;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount);
    }

    modifier ToThirdParty() {
        _;
    }

    /// @dev it should make the withdrawal and delete the stream.
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
        vm.warp({ timestamp: daiStream.stopTime });

        // Run the test.
        sablierV2Linear.withdrawTo({ streamId: daiStreamId, to: users.alice, amount: daiStream.depositAmount });
        DataTypes.LinearStream memory deletedStream = sablierV2Linear.getStream(daiStreamId);
        DataTypes.LinearStream memory expectedStream;
        assertEq(deletedStream, expectedStream);

        address actualRecipient = sablierV2Linear.getRecipient(daiStreamId);
        address expectedRecipient = users.recipient;
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
        vm.warp({ timestamp: daiStream.stopTime });

        // Run the test.
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: false, checkData: true });
        emit Events.Withdraw({ streamId: daiStreamId, recipient: users.alice, amount: daiStream.depositAmount });
        sablierV2Linear.withdrawTo({ streamId: daiStreamId, to: users.alice, amount: daiStream.depositAmount });
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
        vm.warp({ timestamp: daiStream.startTime + TIME_OFFSET });

        // Run the test.
        sablierV2Linear.withdrawTo({ streamId: daiStreamId, to: users.alice, amount: WITHDRAW_AMOUNT_DAI });
        DataTypes.LinearStream memory actualStream = sablierV2Linear.getStream(daiStreamId);
        uint128 actualWithdrawnAmount = actualStream.withdrawnAmount;
        uint128 expectedWithdrawnAmount = WITHDRAW_AMOUNT_DAI;
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
        vm.warp({ timestamp: daiStream.startTime + TIME_OFFSET });

        // Run the test.
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: false, checkData: true });
        emit Events.Withdraw({ streamId: daiStreamId, recipient: users.alice, amount: WITHDRAW_AMOUNT_DAI });
        sablierV2Linear.withdrawTo({ streamId: daiStreamId, to: users.alice, amount: WITHDRAW_AMOUNT_DAI });
    }
}
