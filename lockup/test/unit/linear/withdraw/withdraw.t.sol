// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";

import { Errors } from "src/libraries/Errors.sol";
import { Events } from "src/libraries/Events.sol";
import { LinearStream } from "src/types/Structs.sol";

import { LinearTest } from "../LinearTest.t.sol";

contract Withdraw__Test is LinearTest {
    uint256 internal defaultStreamId;

    function setUp() public override {
        LinearTest.setUp();

        // Make the recipient the caller in this test suite.
        changePrank(users.recipient);
    }

    /// @dev it should revert.
    function testCannotWithdraw__StreamNonExistent() external {
        uint256 nonStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2__StreamNonExistent.selector, nonStreamId));
        linear.withdraw({ streamId: nonStreamId, to: users.recipient, amount: DEFAULT_WITHDRAW_AMOUNT });
    }

    modifier StreamExistent() {
        // Create the default stream.
        defaultStreamId = createDefaultStream();
        _;
    }

    /// @dev it should revert.
    function testCannotWithdraw__CallerUnauthorized__MaliciousThirdParty(address eve) external StreamExistent {
        vm.assume(eve != address(0) && eve != defaultStream.sender && eve != users.recipient);

        // Make Eve the caller in this test.
        changePrank(eve);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2__Unauthorized.selector, defaultStreamId, eve));
        linear.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: DEFAULT_WITHDRAW_AMOUNT });
    }

    /// @dev it should revert.
    function testCannotWithdraw__CallerUnauthorized__Sender() external StreamExistent {
        // Make the sender the caller in this test.
        changePrank(users.sender);

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2__WithdrawSenderUnauthorized.selector,
                defaultStreamId,
                defaultStream.sender,
                defaultStream.sender
            )
        );
        linear.withdraw({ streamId: defaultStreamId, to: defaultStream.sender, amount: DEFAULT_WITHDRAW_AMOUNT });
    }

    /// @dev it should revert.
    function testCannotWithdraw__FormerRecipient() external StreamExistent {
        // Transfer the stream to Alice.
        linear.transferFrom(users.recipient, users.alice, defaultStreamId);

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2__Unauthorized.selector, defaultStreamId, users.recipient)
        );
        linear.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: DEFAULT_WITHDRAW_AMOUNT });
    }

    modifier CallerAuthorized() {
        _;
    }

    /// @dev it should revert.
    function testCannotWithdraw__ToZeroAddress() external StreamExistent CallerAuthorized {
        vm.expectRevert(Errors.SablierV2__WithdrawToZeroAddress.selector);
        linear.withdraw({ streamId: defaultStreamId, to: address(0), amount: defaultStream.amounts.deposit });
    }

    modifier ToNonZeroAddress() {
        _;
    }

    /// @dev it should revert.
    function testCannotWithdraw__WithdrawAmountZero() external StreamExistent CallerAuthorized ToNonZeroAddress {
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2__WithdrawAmountZero.selector, defaultStreamId));
        linear.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: 0 });
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
        WithdrawAmountNotZero
    {
        uint128 withdrawableAmount = 0;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2__WithdrawAmountGreaterThanWithdrawableAmount.selector,
                defaultStreamId,
                UINT128_MAX,
                withdrawableAmount
            )
        );
        linear.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: UINT128_MAX });
    }

    modifier WithdrawAmountLessThanOrEqualToWithdrawableAmount() {
        _;
    }

    /// @dev it should make the withdrawal and update the withdrawn amount.
    function testWithdraw__CallerRecipient(
        address to
    )
        external
        StreamExistent
        CallerAuthorized
        ToNonZeroAddress
        WithdrawAmountNotZero
        WithdrawAmountLessThanOrEqualToWithdrawableAmount
    {
        vm.assume(to != address(0));

        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp({ timestamp: defaultStream.range.start + DEFAULT_TIME_WARP });

        // Run the test.
        linear.withdraw({ streamId: defaultStreamId, to: to, amount: DEFAULT_WITHDRAW_AMOUNT });
        uint128 actualWithdrawnAmount = linear.getWithdrawnAmount(defaultStreamId);
        uint128 expectedWithdrawnAmount = DEFAULT_WITHDRAW_AMOUNT;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount);
    }

    /// @dev it should make the withdrawal and update the withdrawn amount.
    function testWithdraw__CallerApprovedOperator(
        address to
    )
        external
        StreamExistent
        CallerAuthorized
        ToNonZeroAddress
        WithdrawAmountNotZero
        WithdrawAmountLessThanOrEqualToWithdrawableAmount
    {
        vm.assume(to != address(0));

        // Approve the operator to handle the stream.
        linear.approve(users.operator, defaultStreamId);

        // Make the operator the caller in this test.
        changePrank(users.operator);

        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp({ timestamp: defaultStream.range.start + DEFAULT_TIME_WARP });

        // Make the withdrawal.
        linear.withdraw({ streamId: defaultStreamId, to: to, amount: DEFAULT_WITHDRAW_AMOUNT });

        // Run the test.
        uint128 actualWithdrawnAmount = linear.getWithdrawnAmount(defaultStreamId);
        uint128 expectedWithdrawnAmount = DEFAULT_WITHDRAW_AMOUNT;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount);
    }

    modifier CallerSender() {
        // Make the sender the caller in this test suite.
        changePrank(users.sender);
        _;
    }

    /// @dev it should make the withdrawal and delete the stream.
    function testWithdraw__StreamEnded()
        external
        StreamExistent
        CallerAuthorized
        ToNonZeroAddress
        WithdrawAmountNotZero
        WithdrawAmountLessThanOrEqualToWithdrawableAmount
        CallerSender
    {
        // Warp to the end of the stream.
        vm.warp({ timestamp: defaultStream.range.stop });

        // Make the withdrawal.
        linear.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: defaultStream.amounts.deposit });

        // Assert that the stream was deleted.
        LinearStream memory deletedStream = linear.getStream(defaultStreamId);
        LinearStream memory expectedStream;
        assertEq(deletedStream, expectedStream);

        // Assert that the NFT was not burned.
        address actualNFTowner = linear.ownerOf({ tokenId: defaultStreamId });
        address expectedNFTOwner = users.recipient;
        assertEq(actualNFTowner, expectedNFTOwner);
    }

    modifier StreamOngoing() {
        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp({ timestamp: defaultStream.range.start + DEFAULT_TIME_WARP });
        _;
    }

    /// @dev it should make the withdrawal and update the withdrawn amount.
    function testWithdraw__RecipientNotContract(
        uint256 timeWarp,
        address to,
        uint128 withdrawAmount
    )
        external
        StreamExistent
        CallerAuthorized
        ToNonZeroAddress
        WithdrawAmountNotZero
        WithdrawAmountLessThanOrEqualToWithdrawableAmount
        CallerSender
        StreamOngoing
    {
        timeWarp = bound(timeWarp, DEFAULT_CLIFF_DURATION, DEFAULT_TOTAL_DURATION - 1);
        vm.assume(to != address(0) && to.code.length == 0);

        // Create the stream with the fuzzed recipient that is not a contract.
        uint256 streamId = createDefaultStreamWithRecipient(to);

        // Warp into the future.
        vm.warp({ timestamp: defaultStream.range.start + timeWarp });

        // Bound the withdraw amount.
        uint128 withdrawableAmount = linear.getWithdrawableAmount(streamId);
        withdrawAmount = boundUint128(withdrawAmount, 1, withdrawableAmount);

        // Expect the withdrawal to be made to the recipient.
        vm.expectCall(defaultStream.token, abi.encodeCall(IERC20.transfer, (to, withdrawAmount)));

        // Expect an event to be emitted.
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: false, checkData: true });
        emit Events.Withdraw({ streamId: streamId, to: to, amount: withdrawAmount });

        // Make the withdrawal.
        linear.withdraw({ streamId: streamId, to: to, amount: withdrawAmount });

        // Assert that the withdrawn amount was updated.
        uint128 actualWithdrawnAmount = linear.getWithdrawnAmount(streamId);
        uint128 expectedWithdrawnAmount = withdrawAmount;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount);
    }

    modifier RecipientContract() {
        _;
    }

    /// @dev it should ignore the revert and make the withdrawal and update the withdrawn amount.
    function testWithdraw__RecipientDoesNotImplementHook()
        external
        StreamExistent
        CallerAuthorized
        ToNonZeroAddress
        WithdrawAmountNotZero
        WithdrawAmountLessThanOrEqualToWithdrawableAmount
        CallerSender
        StreamOngoing
        RecipientContract
    {
        // Create the stream with the recipient as a contract.
        uint256 streamId = createDefaultStreamWithRecipient(address(empty));

        // Make the withdrawal.
        linear.withdraw({ streamId: streamId, to: address(empty), amount: DEFAULT_WITHDRAW_AMOUNT });

        // Assert that the stream was deleted.
        uint128 actualWithdrawnAmount = linear.getWithdrawnAmount(streamId);
        uint128 expectedWithdrawnAmount = DEFAULT_WITHDRAW_AMOUNT;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount);
    }

    modifier RecipientImplementsHook() {
        _;
    }

    /// @dev it should ignore the revert and make the withdrawal and update the withdrawn amount.
    function testWithdraw__RecipientReverts()
        external
        StreamExistent
        CallerAuthorized
        ToNonZeroAddress
        WithdrawAmountNotZero
        WithdrawAmountLessThanOrEqualToWithdrawableAmount
        CallerSender
        StreamOngoing
        RecipientContract
        RecipientImplementsHook
    {
        // Create the stream with the recipient as a contract.
        uint256 streamId = createDefaultStreamWithRecipient(address(revertingRecipient));

        // Make the withdrawal.
        linear.withdraw({ streamId: streamId, to: address(revertingRecipient), amount: DEFAULT_WITHDRAW_AMOUNT });

        // Assert that the stream was deleted.
        uint128 actualWithdrawnAmount = linear.getWithdrawnAmount(streamId);
        uint128 expectedWithdrawnAmount = DEFAULT_WITHDRAW_AMOUNT;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount);
    }

    modifier RecipientDoesNotRevert() {
        _;
    }

    /// @dev it should make multiple withdrawals and update the withdrawn amounts.
    function testWithdraw__RecipientReentrancy()
        external
        StreamExistent
        CallerAuthorized
        ToNonZeroAddress
        WithdrawAmountNotZero
        WithdrawAmountLessThanOrEqualToWithdrawableAmount
        CallerSender
        StreamOngoing
        RecipientContract
        RecipientImplementsHook
        RecipientDoesNotRevert
    {
        // Create the stream with the recipient as a contract.
        uint256 streamId = createDefaultStreamWithRecipient(address(reentrantRecipient));

        // Halve the withdraw amount so that the recipient can re-entry and make another withdrawal.
        uint128 withdrawAmount = DEFAULT_WITHDRAW_AMOUNT / 2;

        // Make the withdrawal.
        linear.withdraw({ streamId: streamId, to: address(reentrantRecipient), amount: withdrawAmount });

        // Assert that the stream was deleted.
        uint128 actualWithdrawnAmount = linear.getWithdrawnAmount(streamId);
        uint128 expectedWithdrawnAmount = DEFAULT_WITHDRAW_AMOUNT;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount);
    }

    modifier NoRecipientReentrancy() {
        _;
    }

    /// @dev it should make the withdrawal, emit a Withdraw event, and update the withdrawn amount.
    function testWithdraw(
        uint256 timeWarp,
        uint128 withdrawAmount
    )
        external
        StreamExistent
        CallerAuthorized
        ToNonZeroAddress
        WithdrawAmountNotZero
        WithdrawAmountLessThanOrEqualToWithdrawableAmount
        CallerSender
        StreamOngoing
        RecipientContract
        RecipientImplementsHook
        RecipientDoesNotRevert
        NoRecipientReentrancy
    {
        timeWarp = bound(timeWarp, DEFAULT_CLIFF_DURATION, DEFAULT_TOTAL_DURATION - 1);

        // Create the stream with the recipient as a contract.
        uint256 streamId = createDefaultStreamWithRecipient(address(goodRecipient));

        // Warp into the future.
        vm.warp({ timestamp: defaultStream.range.start + timeWarp });

        // Bound the withdraw amount.
        uint128 withdrawableAmount = linear.getWithdrawableAmount(streamId);
        withdrawAmount = boundUint128(withdrawAmount, 1, withdrawableAmount);

        // Expect the withdrawal to be made to the recipient.
        vm.expectCall(defaultStream.token, abi.encodeCall(IERC20.transfer, (address(goodRecipient), withdrawAmount)));

        // Expect an event to be emitted.
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: false, checkData: true });
        emit Events.Withdraw({ streamId: streamId, to: address(goodRecipient), amount: withdrawAmount });

        // Make the withdrawal.
        linear.withdraw(streamId, address(goodRecipient), withdrawAmount);

        // Assert that the withdrawn amount was updated.
        uint128 actualWithdrawnAmount = linear.getWithdrawnAmount(streamId);
        uint128 expectedWithdrawnAmount = withdrawAmount;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount);
    }
}
