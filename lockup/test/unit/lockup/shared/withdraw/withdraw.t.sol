// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

import { Errors } from "src/libraries/Errors.sol";
import { Events } from "src/libraries/Events.sol";
import { Lockup } from "src/types/DataTypes.sol";

import { Lockup_Shared_Test } from "../../../../shared/lockup/Lockup.t.sol";
import { Unit_Test } from "../../../Unit.t.sol";

abstract contract Withdraw_Unit_Test is Unit_Test, Lockup_Shared_Test {
    uint256 internal defaultStreamId;

    function setUp() public virtual override(Unit_Test, Lockup_Shared_Test) {
        // Make the recipient the caller in this test suite.
        changePrank({ who: users.recipient });

        // Create the default stream.
        defaultStreamId = createDefaultStream();
    }

    modifier streamNotActive() {
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_StreamNull() external streamNotActive {
        uint256 nullStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_StreamNotActive.selector, nullStreamId));
        lockup.withdraw({ streamId: nullStreamId, to: users.recipient, amount: DEFAULT_WITHDRAW_AMOUNT });
    }

    /// @dev it should revert.
    function test_RevertWhen_StreamCanceled() external streamNotActive {
        lockup.cancel(defaultStreamId);
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_StreamNotActive.selector, defaultStreamId));
        lockup.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: DEFAULT_WITHDRAW_AMOUNT });
    }

    /// @dev it should revert.
    function test_RevertWhen_StreamDepleted() external streamNotActive {
        vm.warp({ timestamp: DEFAULT_END_TIME });
        lockup.withdrawMax({ streamId: defaultStreamId, to: users.recipient });
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_StreamNotActive.selector, defaultStreamId));
        lockup.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: DEFAULT_WITHDRAW_AMOUNT });
    }

    modifier streamActive() {
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_CallerUnauthorized_MaliciousThirdParty() external streamActive {
        // Make Eve the caller in this test.
        changePrank({ who: users.eve });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_Unauthorized.selector, defaultStreamId, users.eve)
        );
        lockup.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: DEFAULT_WITHDRAW_AMOUNT });
    }

    /// @dev it should revert.
    function test_RevertWhen_CallerUnauthorized_Sender() external streamActive {
        // Make the sender the caller in this test.
        changePrank({ who: users.sender });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2Lockup_WithdrawSenderUnauthorized.selector,
                defaultStreamId,
                users.sender,
                users.sender
            )
        );
        lockup.withdraw({ streamId: defaultStreamId, to: users.sender, amount: DEFAULT_WITHDRAW_AMOUNT });
    }

    /// @dev it should revert.
    function test_RevertWhen_FormerRecipient() external streamActive {
        // Transfer the stream to Alice.
        lockup.transferFrom(users.recipient, users.alice, defaultStreamId);

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_Unauthorized.selector, defaultStreamId, users.recipient)
        );
        lockup.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: DEFAULT_WITHDRAW_AMOUNT });
    }

    modifier callerAuthorized() {
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_ToZeroAddress() external streamActive callerAuthorized {
        vm.expectRevert(Errors.SablierV2Lockup_WithdrawToZeroAddress.selector);
        lockup.withdraw({ streamId: defaultStreamId, to: address(0), amount: DEFAULT_WITHDRAW_AMOUNT });
    }

    modifier toNonZeroAddress() {
        _;
    }

    /// @dev it should revert.
    function test_RevertWhen_WithdrawAmountZero() external streamActive callerAuthorized toNonZeroAddress {
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_WithdrawAmountZero.selector, defaultStreamId));
        lockup.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: 0 });
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
                Errors.SablierV2Lockup_WithdrawAmountGreaterThanWithdrawableAmount.selector,
                defaultStreamId,
                UINT128_MAX,
                withdrawableAmount
            )
        );
        lockup.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: UINT128_MAX });
    }

    modifier withdrawAmountLessThanOrEqualToWithdrawableAmount() {
        _;
    }

    /// @dev it should make the withdrawal and update the withdrawn amount.
    function test_Withdraw_CallerRecipient()
        external
        streamActive
        callerAuthorized
        toNonZeroAddress
        withdrawAmountNotZero
        withdrawAmountLessThanOrEqualToWithdrawableAmount
    {
        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp({ timestamp: DEFAULT_START_TIME + DEFAULT_TIME_WARP });

        // Make Alice the `to` address in this test.
        address to = users.alice;

        // Run the test.
        lockup.withdraw({ streamId: defaultStreamId, to: to, amount: DEFAULT_WITHDRAW_AMOUNT });
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(defaultStreamId);
        uint128 expectedWithdrawnAmount = DEFAULT_WITHDRAW_AMOUNT;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount, "withdrawnAmount");
    }

    /// @dev it should make the withdrawal and update the withdrawn amount.
    function test_Withdraw_CallerApprovedOperator()
        external
        streamActive
        callerAuthorized
        toNonZeroAddress
        withdrawAmountNotZero
        withdrawAmountLessThanOrEqualToWithdrawableAmount
    {
        // Approve the operator to handle the stream.
        lockup.approve({ to: users.operator, tokenId: defaultStreamId });

        // Make the operator the caller in this test.
        changePrank({ who: users.operator });

        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp({ timestamp: DEFAULT_START_TIME + DEFAULT_TIME_WARP });

        // Make the withdrawal.
        lockup.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: DEFAULT_WITHDRAW_AMOUNT });

        // Run the test.
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(defaultStreamId);
        uint128 expectedWithdrawnAmount = DEFAULT_WITHDRAW_AMOUNT;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount, "withdrawnAmount");
    }

    modifier callerSender() {
        // Make the sender the caller in this test suite.
        changePrank({ who: users.sender });
        _;
    }

    /// @dev it should make the withdrawal and mark the stream as depleted.
    function test_Withdraw_CurrentTimeEqualToEndTime()
        external
        streamActive
        callerAuthorized
        toNonZeroAddress
        withdrawAmountNotZero
        withdrawAmountLessThanOrEqualToWithdrawableAmount
        callerSender
    {
        // Warp to the end of the stream.
        vm.warp({ timestamp: DEFAULT_END_TIME });

        // Make the withdrawal.
        lockup.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: DEFAULT_NET_DEPOSIT_AMOUNT });

        // Assert that the stream was marked as depleted.
        Lockup.Status actualStatus = lockup.getStatus(defaultStreamId);
        Lockup.Status expectedStatus = Lockup.Status.DEPLETED;
        assertEq(actualStatus, expectedStatus);

        // Assert that the NFT was not burned.
        address actualNFTowner = lockup.ownerOf({ tokenId: defaultStreamId });
        address expectedNFTOwner = users.recipient;
        assertEq(actualNFTowner, expectedNFTOwner, "NFT owner");
    }

    modifier currentTimeLessThanEndTime() {
        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp({ timestamp: DEFAULT_START_TIME + DEFAULT_TIME_WARP });
        _;
    }

    /// @dev it should make the withdrawal and update the withdrawn amount.
    function test_Withdraw_RecipientNotContract()
        external
        streamActive
        callerAuthorized
        toNonZeroAddress
        withdrawAmountNotZero
        withdrawAmountLessThanOrEqualToWithdrawableAmount
        callerSender
        currentTimeLessThanEndTime
    {
        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_START_TIME + DEFAULT_TIME_WARP });

        // Set the withdraw amount to the streamed amount.
        uint128 withdrawAmount = lockup.streamedAmountOf(defaultStreamId);

        // Expect the withdrawal to be made to the recipient.
        vm.expectCall(address(DEFAULT_ASSET), abi.encodeCall(IERC20.transfer, (users.recipient, withdrawAmount)));

        // Expect a {WithdrawFromLockupStream} event to be emitted.
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: false, checkData: true });
        emit Events.WithdrawFromLockupStream({
            streamId: defaultStreamId,
            to: users.recipient,
            amount: withdrawAmount
        });

        // Make the withdrawal.
        lockup.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: withdrawAmount });

        // Assert that the withdrawn amount was updated.
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(defaultStreamId);
        uint128 expectedWithdrawnAmount = withdrawAmount;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount, "withdrawnAmount");
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
        currentTimeLessThanEndTime
        recipientContract
    {
        // Create the stream with the recipient as a contract.
        uint256 streamId = createDefaultStreamWithRecipient(address(empty));

        // Make the withdrawal.
        lockup.withdraw({ streamId: streamId, to: address(empty), amount: DEFAULT_WITHDRAW_AMOUNT });

        // Assert that the withdrawn amount was updated.
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(streamId);
        uint128 expectedWithdrawnAmount = DEFAULT_WITHDRAW_AMOUNT;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount, "withdrawnAmount");
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
        currentTimeLessThanEndTime
        recipientContract
        recipientImplementsHook
    {
        // Create the stream with the recipient as a contract.
        uint256 streamId = createDefaultStreamWithRecipient(address(revertingRecipient));

        // Make the withdrawal.
        lockup.withdraw({ streamId: streamId, to: address(revertingRecipient), amount: DEFAULT_WITHDRAW_AMOUNT });

        // Assert that the withdrawn amount was updated.
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(streamId);
        uint128 expectedWithdrawnAmount = DEFAULT_WITHDRAW_AMOUNT;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount, "withdrawnAmount");
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
        currentTimeLessThanEndTime
        recipientContract
        recipientImplementsHook
        recipientDoesNotRevert
    {
        // Create the stream with the recipient as a contract.
        uint256 streamId = createDefaultStreamWithRecipient(address(reentrantRecipient));

        // Halve the withdraw amount so that the recipient can re-entry and make another withdrawal.
        uint128 withdrawAmount = DEFAULT_WITHDRAW_AMOUNT / 2;

        // Make the withdrawal.
        lockup.withdraw({ streamId: streamId, to: address(reentrantRecipient), amount: withdrawAmount });

        // Assert that the withdrawn amount was updated.
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(streamId);
        uint128 expectedWithdrawnAmount = DEFAULT_WITHDRAW_AMOUNT;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount, "withdrawnAmount");
    }

    modifier noRecipientReentrancy() {
        _;
    }

    /// @dev it should make the withdrawal, update the withdrawn amount, and emit a {WithdrawFromLockupStream} event.
    function test_Withdraw()
        external
        streamActive
        callerAuthorized
        toNonZeroAddress
        withdrawAmountNotZero
        withdrawAmountLessThanOrEqualToWithdrawableAmount
        callerSender
        currentTimeLessThanEndTime
        recipientContract
        recipientImplementsHook
        recipientDoesNotRevert
        noRecipientReentrancy
    {
        // Create the stream with the recipient as a contract.
        uint256 streamId = createDefaultStreamWithRecipient(address(goodRecipient));

        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_START_TIME + DEFAULT_TIME_WARP });

        // Set the withdraw amount to the streamed amount.
        uint128 withdrawAmount = lockup.streamedAmountOf(streamId);

        // Expect the withdrawal to be made to the recipient.
        vm.expectCall(
            address(DEFAULT_ASSET),
            abi.encodeCall(IERC20.transfer, (address(goodRecipient), withdrawAmount))
        );

        // Expect a {WithdrawFromLockupStream} event to be emitted.
        vm.expectEmit({ checkTopic1: true, checkTopic2: true, checkTopic3: false, checkData: true });
        emit Events.WithdrawFromLockupStream({
            streamId: streamId,
            to: address(goodRecipient),
            amount: withdrawAmount
        });

        // Make the withdrawal.
        lockup.withdraw({ streamId: streamId, to: address(goodRecipient), amount: withdrawAmount });

        // Assert that the withdrawn amount was updated.
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(streamId);
        uint128 expectedWithdrawnAmount = withdrawAmount;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount, "withdrawnAmount");
    }
}
