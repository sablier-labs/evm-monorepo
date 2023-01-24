// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { IERC20 } from "@prb/contracts/token/erc20/IERC20.sol";

import { Errors } from "src/libraries/Errors.sol";
import { Events } from "src/libraries/Events.sol";
import { Status } from "src/types/Enums.sol";

import { SharedTest } from "../SharedTest.t.sol";

abstract contract Withdraw_Test is SharedTest {
    uint256 internal defaultStreamId;

    function setUp() public virtual override {
        super.setUp();

        // Make the recipient the caller in this test suite.
        changePrank(users.recipient);

        // Create the default stream.
        defaultStreamId = createDefaultStream();
    }

    modifier streamNotActive() {
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_StreamNull() external streamNotActive {
        uint256 nullStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2_StreamNotActive.selector, nullStreamId));
        sablierV2.withdraw({ streamId: nullStreamId, to: users.recipient, amount: DEFAULT_WITHDRAW_AMOUNT });
    }

    /// @dev it should revert.
    function test_RevertWhen_StreamCanceled() external streamNotActive {
        sablierV2.cancel(defaultStreamId);
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2_StreamNotActive.selector, defaultStreamId));
        sablierV2.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: DEFAULT_WITHDRAW_AMOUNT });
    }

    /// @dev it should revert.
    function test_RevertWhen_StreamDepleted() external streamNotActive {
        vm.warp({ timestamp: DEFAULT_STOP_TIME });
        sablierV2.withdrawMax({ streamId: defaultStreamId, to: users.recipient });
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2_StreamNotActive.selector, defaultStreamId));
        sablierV2.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: DEFAULT_WITHDRAW_AMOUNT });
    }

    modifier streamActive() {
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_CallerUnauthorized_MaliciousThirdParty(address eve) external streamActive {
        vm.assume(eve != address(0) && eve != users.sender && eve != users.recipient);

        // Make Eve the caller in this test.
        changePrank(eve);

        // Run the test.
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2_Unauthorized.selector, defaultStreamId, eve));
        sablierV2.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: DEFAULT_WITHDRAW_AMOUNT });
    }

    /// @dev it should revert.
    function test_RevertWhen_CallerUnauthorized_Sender() external streamActive {
        // Make the sender the caller in this test.
        changePrank(users.sender);

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2_WithdrawSenderUnauthorized.selector,
                defaultStreamId,
                users.sender,
                users.sender
            )
        );
        sablierV2.withdraw({ streamId: defaultStreamId, to: users.sender, amount: DEFAULT_WITHDRAW_AMOUNT });
    }

    /// @dev it should revert.
    function test_RevertWhen_FormerRecipient() external streamActive {
        // Transfer the stream to Alice.
        sablierV2.transferFrom(users.recipient, users.alice, defaultStreamId);

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2_Unauthorized.selector, defaultStreamId, users.recipient)
        );
        sablierV2.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: DEFAULT_WITHDRAW_AMOUNT });
    }

    modifier callerAuthorized() {
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_ToZeroAddress() external streamActive callerAuthorized {
        vm.expectRevert(Errors.SablierV2_WithdrawToZeroAddress.selector);
        sablierV2.withdraw({ streamId: defaultStreamId, to: address(0), amount: DEFAULT_WITHDRAW_AMOUNT });
    }

    modifier toNonZeroAddress() {
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_WithdrawAmountZero() external streamActive callerAuthorized toNonZeroAddress {
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2_WithdrawAmountZero.selector, defaultStreamId));
        sablierV2.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: 0 });
    }

    modifier withdrawAmountNotZero() {
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_WithdrawAmountGreaterThanWithdrawableAmount()
        external
        streamActive
        callerAuthorized
        toNonZeroAddress
        withdrawAmountNotZero
    {
        uint128 withdrawableAmount = 0;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2_WithdrawAmountGreaterThanWithdrawableAmount.selector,
                defaultStreamId,
                UINT128_MAX,
                withdrawableAmount
            )
        );
        sablierV2.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: UINT128_MAX });
    }

    modifier withdrawAmountLessThanOrEqualToWithdrawableAmount() {
        _;
    }

    /// @dev it should make the withdrawal and update the withdrawn amount.
    function testFuzz_Withdraw_CallerRecipient(
        address to
    )
        external
        streamActive
        callerAuthorized
        toNonZeroAddress
        withdrawAmountNotZero
        withdrawAmountLessThanOrEqualToWithdrawableAmount
    {
        vm.assume(to != address(0));

        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp({ timestamp: DEFAULT_START_TIME + DEFAULT_TIME_WARP });

        // Run the test.
        sablierV2.withdraw({ streamId: defaultStreamId, to: to, amount: DEFAULT_WITHDRAW_AMOUNT });
        uint128 actualWithdrawnAmount = sablierV2.getWithdrawnAmount(defaultStreamId);
        uint128 expectedWithdrawnAmount = DEFAULT_WITHDRAW_AMOUNT;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount);
    }

    /// @dev it should make the withdrawal and update the withdrawn amount.
    function testFuzz_Withdraw_CallerApprovedOperator(
        address to
    )
        external
        streamActive
        callerAuthorized
        toNonZeroAddress
        withdrawAmountNotZero
        withdrawAmountLessThanOrEqualToWithdrawableAmount
    {
        vm.assume(to != address(0));

        // Approve the operator to handle the stream.
        sablierV2.approve(users.operator, defaultStreamId);

        // Make the operator the caller in this test.
        changePrank(users.operator);

        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp({ timestamp: DEFAULT_START_TIME + DEFAULT_TIME_WARP });

        // Make the withdrawal.
        sablierV2.withdraw({ streamId: defaultStreamId, to: to, amount: DEFAULT_WITHDRAW_AMOUNT });

        // Run the test.
        uint128 actualWithdrawnAmount = sablierV2.getWithdrawnAmount(defaultStreamId);
        uint128 expectedWithdrawnAmount = DEFAULT_WITHDRAW_AMOUNT;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount);
    }

    modifier callerSender() {
        // Make the sender the caller in this test suite.
        changePrank(users.sender);
        _;
    }

    /// @dev it should make the withdrawal and mark the stream as depleted.
    function test_Withdraw_CurrentTimeEqualToStopTime()
        external
        streamActive
        callerAuthorized
        toNonZeroAddress
        withdrawAmountNotZero
        withdrawAmountLessThanOrEqualToWithdrawableAmount
        callerSender
    {
        // Warp to the end of the stream.
        vm.warp({ timestamp: DEFAULT_STOP_TIME });

        // Make the withdrawal.
        sablierV2.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: DEFAULT_NET_DEPOSIT_AMOUNT });

        // Assert that the stream was marked as depleted.
        Status actualStatus = sablierV2.getStatus(defaultStreamId);
        Status expectedStatus = Status.DEPLETED;
        assertEq(actualStatus, expectedStatus);

        // Assert that the NFT was not burned.
        address actualNFTowner = sablierV2.ownerOf({ tokenId: defaultStreamId });
        address expectedNFTOwner = users.recipient;
        assertEq(actualNFTowner, expectedNFTOwner);
    }

    modifier currentTimeLessThanStopTime() {
        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp({ timestamp: DEFAULT_START_TIME + DEFAULT_TIME_WARP });
        _;
    }

    /// @dev it should make the withdrawal and update the withdrawn amount.
    function testFuzz_Withdraw_RecipientNotContract(
        uint256 timeWarp,
        address to,
        uint128 withdrawAmount
    )
        external
        streamActive
        callerAuthorized
        toNonZeroAddress
        withdrawAmountNotZero
        withdrawAmountLessThanOrEqualToWithdrawableAmount
        callerSender
        currentTimeLessThanStopTime
    {
        timeWarp = bound(timeWarp, DEFAULT_CLIFF_DURATION, DEFAULT_TOTAL_DURATION - 1);
        vm.assume(to != address(0) && to.code.length == 0);

        // Create the stream with the fuzzed recipient that is not a contract.
        uint256 streamId = createDefaultStreamWithRecipient(to);

        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_START_TIME + timeWarp });

        // Bound the withdraw amount.
        uint128 withdrawableAmount = sablierV2.getWithdrawableAmount(streamId);
        withdrawAmount = boundUint128(withdrawAmount, 1, withdrawableAmount);

        // Expect the withdrawal to be made to the recipient.
        vm.expectCall(address(dai), abi.encodeCall(IERC20.transfer, (to, withdrawAmount)));

        // Expect an event to be emitted.
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: false, checkData: true });
        emit Events.Withdraw({ streamId: streamId, to: to, amount: withdrawAmount });

        // Make the withdrawal.
        sablierV2.withdraw({ streamId: streamId, to: to, amount: withdrawAmount });

        // Assert that the withdrawn amount was updated.
        uint128 actualWithdrawnAmount = sablierV2.getWithdrawnAmount(streamId);
        uint128 expectedWithdrawnAmount = withdrawAmount;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount);
    }

    modifier recipientContract() {
        _;
    }

    /// @dev it should ignore the revert and make the withdrawal and update the withdrawn amount.
    function test_Withdraw_RecipientDoesNotImplementHook()
        external
        streamActive
        callerAuthorized
        toNonZeroAddress
        withdrawAmountNotZero
        withdrawAmountLessThanOrEqualToWithdrawableAmount
        callerSender
        currentTimeLessThanStopTime
        recipientContract
    {
        // Create the stream with the recipient as a contract.
        uint256 streamId = createDefaultStreamWithRecipient(address(empty));

        // Make the withdrawal.
        sablierV2.withdraw({ streamId: streamId, to: address(empty), amount: DEFAULT_WITHDRAW_AMOUNT });

        // Assert that the withdrawn amount was updated.
        uint128 actualWithdrawnAmount = sablierV2.getWithdrawnAmount(streamId);
        uint128 expectedWithdrawnAmount = DEFAULT_WITHDRAW_AMOUNT;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount);
    }

    modifier recipientImplementsHook() {
        _;
    }

    /// @dev it should ignore the revert and make the withdrawal and update the withdrawn amount.
    function test_Withdraw_RecipientReverts()
        external
        streamActive
        callerAuthorized
        toNonZeroAddress
        withdrawAmountNotZero
        withdrawAmountLessThanOrEqualToWithdrawableAmount
        callerSender
        currentTimeLessThanStopTime
        recipientContract
        recipientImplementsHook
    {
        // Create the stream with the recipient as a contract.
        uint256 streamId = createDefaultStreamWithRecipient(address(revertingRecipient));

        // Make the withdrawal.
        sablierV2.withdraw({ streamId: streamId, to: address(revertingRecipient), amount: DEFAULT_WITHDRAW_AMOUNT });

        // Assert that the withdrawn amount was updated.
        uint128 actualWithdrawnAmount = sablierV2.getWithdrawnAmount(streamId);
        uint128 expectedWithdrawnAmount = DEFAULT_WITHDRAW_AMOUNT;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount);
    }

    modifier recipientDoesNotRevert() {
        _;
    }

    /// @dev it should make multiple withdrawals and update the withdrawn amounts.
    function test_Withdraw_RecipientReentrancy()
        external
        streamActive
        callerAuthorized
        toNonZeroAddress
        withdrawAmountNotZero
        withdrawAmountLessThanOrEqualToWithdrawableAmount
        callerSender
        currentTimeLessThanStopTime
        recipientContract
        recipientImplementsHook
        recipientDoesNotRevert
    {
        // Create the stream with the recipient as a contract.
        uint256 streamId = createDefaultStreamWithRecipient(address(reentrantRecipient));

        // Halve the withdraw amount so that the recipient can re-entry and make another withdrawal.
        uint128 withdrawAmount = DEFAULT_WITHDRAW_AMOUNT / 2;

        // Make the withdrawal.
        sablierV2.withdraw({ streamId: streamId, to: address(reentrantRecipient), amount: withdrawAmount });

        // Assert that the withdrawn amount was updated.
        uint128 actualWithdrawnAmount = sablierV2.getWithdrawnAmount(streamId);
        uint128 expectedWithdrawnAmount = DEFAULT_WITHDRAW_AMOUNT;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount);
    }

    modifier noRecipientReentrancy() {
        _;
    }

    /// @dev it should make the withdrawal, emit a Withdraw event, and update the withdrawn amount.
    function testFuzz_Withdraw(
        uint256 timeWarp,
        uint128 withdrawAmount
    )
        external
        streamActive
        callerAuthorized
        toNonZeroAddress
        withdrawAmountNotZero
        withdrawAmountLessThanOrEqualToWithdrawableAmount
        callerSender
        currentTimeLessThanStopTime
        recipientContract
        recipientImplementsHook
        recipientDoesNotRevert
        noRecipientReentrancy
    {
        timeWarp = bound(timeWarp, DEFAULT_CLIFF_DURATION, DEFAULT_TOTAL_DURATION - 1);

        // Create the stream with the recipient as a contract.
        uint256 streamId = createDefaultStreamWithRecipient(address(goodRecipient));

        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_START_TIME + timeWarp });

        // Bound the withdraw amount.
        uint128 withdrawableAmount = sablierV2.getWithdrawableAmount(streamId);
        withdrawAmount = boundUint128(withdrawAmount, 1, withdrawableAmount);

        // Expect the withdrawal to be made to the recipient.
        vm.expectCall(address(dai), abi.encodeCall(IERC20.transfer, (address(goodRecipient), withdrawAmount)));

        // Expect an event to be emitted.
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: false, checkData: true });
        emit Events.Withdraw({ streamId: streamId, to: address(goodRecipient), amount: withdrawAmount });

        // Make the withdrawal.
        sablierV2.withdraw(streamId, address(goodRecipient), withdrawAmount);

        // Assert that the withdrawn amount was updated.
        uint128 actualWithdrawnAmount = sablierV2.getWithdrawnAmount(streamId);
        uint128 expectedWithdrawnAmount = withdrawAmount;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount);
    }
}
