// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { IERC20 } from "@openzeppelin/token/ERC20/IERC20.sol";

import { ISablierV2LockupRecipient } from "src/interfaces/hooks/ISablierV2LockupRecipient.sol";
import { Errors } from "src/libraries/Errors.sol";
import { Events } from "src/libraries/Events.sol";
import { Lockup } from "src/types/DataTypes.sol";

import { Lockup_Shared_Test } from "../../../../shared/lockup/Lockup.t.sol";
import { Unit_Test } from "../../../Unit.t.sol";

abstract contract Withdraw_Unit_Test is Unit_Test, Lockup_Shared_Test {
    uint256 internal defaultStreamId;

    function setUp() public virtual override(Unit_Test, Lockup_Shared_Test) {
        // Make the recipient the caller in this test suite.
        changePrank({ msgSender: users.recipient });

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
        changePrank({ msgSender: users.eve });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_Unauthorized.selector, defaultStreamId, users.eve)
        );
        lockup.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: DEFAULT_WITHDRAW_AMOUNT });
    }

    /// @dev it should revert.
    function test_RevertWhen_CallerUnauthorized_Sender() external streamActive {
        // Make the sender the caller in this test.
        changePrank({ msgSender: users.sender });

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

    modifier withdrawAmountNotGreaterThanWithdrawableAmount() {
        _;
    }

    /// @dev it should make the withdrawal and update the withdrawn amount.
    function test_Withdraw_CallerRecipient()
        external
        streamActive
        callerAuthorized
        toNonZeroAddress
        withdrawAmountNotZero
        withdrawAmountNotGreaterThanWithdrawableAmount
    {
        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp({ timestamp: DEFAULT_START_TIME + DEFAULT_TIME_WARP });

        // Make Alice the `to` address in this test.
        address to = users.alice;

        // Make the withdrawal.
        lockup.withdraw({ streamId: defaultStreamId, to: to, amount: DEFAULT_WITHDRAW_AMOUNT });

        // Assert that the stream has remained active.
        Lockup.Status actualStatus = lockup.getStatus(defaultStreamId);
        Lockup.Status expectedStatus = Lockup.Status.ACTIVE;
        assertEq(actualStatus, expectedStatus);

        // Assert that the withdrawn amount has been updated.
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
        withdrawAmountNotGreaterThanWithdrawableAmount
    {
        // Approve the operator to handle the stream.
        lockup.approve({ to: users.operator, tokenId: defaultStreamId });

        // Make the operator the caller in this test.
        changePrank({ msgSender: users.operator });

        // Warp to 2,600 seconds after the start time (26% of the default stream duration).
        vm.warp({ timestamp: DEFAULT_START_TIME + DEFAULT_TIME_WARP });

        // Make the withdrawal.
        lockup.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: DEFAULT_WITHDRAW_AMOUNT });

        // Assert that the stream has remained active.
        Lockup.Status actualStatus = lockup.getStatus(defaultStreamId);
        Lockup.Status expectedStatus = Lockup.Status.ACTIVE;
        assertEq(actualStatus, expectedStatus);

        // Assert that the withdrawn amount has been updated.
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(defaultStreamId);
        uint128 expectedWithdrawnAmount = DEFAULT_WITHDRAW_AMOUNT;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount, "withdrawnAmount");
    }

    modifier callerSender() {
        // Make the sender the caller in this test suite.
        changePrank({ msgSender: users.sender });
        _;
    }

    /// @dev it should make the withdrawal and mark the stream as depleted.
    function test_Withdraw_CurrentTimeEqualToEndTime()
        external
        streamActive
        callerAuthorized
        toNonZeroAddress
        withdrawAmountNotZero
        withdrawAmountNotGreaterThanWithdrawableAmount
        callerSender
    {
        // Warp to the end of the stream.
        vm.warp({ timestamp: DEFAULT_END_TIME });

        // Make the withdrawal.
        lockup.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: DEFAULT_DEPOSIT_AMOUNT });

        // Assert that the stream has been marked as depleted.
        Lockup.Status actualStatus = lockup.getStatus(defaultStreamId);
        Lockup.Status expectedStatus = Lockup.Status.DEPLETED;
        assertEq(actualStatus, expectedStatus);

        // Assert that the NFT has not been burned.
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
        withdrawAmountNotGreaterThanWithdrawableAmount
        callerSender
        currentTimeLessThanEndTime
    {
        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_START_TIME + DEFAULT_TIME_WARP });

        // Set the withdraw amount to the streamed amount.
        uint128 withdrawAmount = lockup.streamedAmountOf(defaultStreamId);

        // Expect the ERC-20 assets to be transferred to the recipient.
        expectTransferCall({ to: users.recipient, amount: withdrawAmount });

        // Expect a {WithdrawFromLockupStream} event to be emitted.
        expectEmit();
        emit Events.WithdrawFromLockupStream({
            streamId: defaultStreamId,
            to: users.recipient,
            amount: withdrawAmount
        });

        // Make the withdrawal.
        lockup.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: withdrawAmount });

        // Assert that the stream has remained active.
        Lockup.Status actualStatus = lockup.getStatus(defaultStreamId);
        Lockup.Status expectedStatus = Lockup.Status.ACTIVE;
        assertEq(actualStatus, expectedStatus);

        // Assert that the withdrawn amount has been updated.
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(defaultStreamId);
        uint128 expectedWithdrawnAmount = withdrawAmount;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount, "withdrawnAmount");
    }

    modifier recipientContract() {
        _;
    }

    /// @dev it should make the withdrawal, update the withdrawn amount, call the recipient hook, and ignore the revert.
    function test_Withdraw_RecipientDoesNotImplementHook()
        external
        streamActive
        callerAuthorized
        toNonZeroAddress
        withdrawAmountNotZero
        withdrawAmountNotGreaterThanWithdrawableAmount
        callerSender
        currentTimeLessThanEndTime
        recipientContract
    {
        // Create the stream with an empty contract as the recipient.
        uint256 streamId = createDefaultStreamWithRecipient(address(empty));

        // Expect a call to the recipient hook.
        vm.expectCall(
            address(empty),
            abi.encodeCall(
                ISablierV2LockupRecipient.onStreamWithdrawn,
                (streamId, users.sender, address(empty), DEFAULT_WITHDRAW_AMOUNT)
            )
        );

        // Make the withdrawal.
        lockup.withdraw({ streamId: streamId, to: address(empty), amount: DEFAULT_WITHDRAW_AMOUNT });

        // Assert that the stream has remained active.
        Lockup.Status actualStatus = lockup.getStatus(streamId);
        Lockup.Status expectedStatus = Lockup.Status.ACTIVE;
        assertEq(actualStatus, expectedStatus);

        // Assert that the withdrawn amount has been updated.
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(streamId);
        uint128 expectedWithdrawnAmount = DEFAULT_WITHDRAW_AMOUNT;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount, "withdrawnAmount");
    }

    modifier recipientImplementsHook() {
        _;
    }

    /// @dev it should make the withdrawal, update the withdrawn amount, call the recipient hook, and ignore the revert.
    function test_Withdraw_RecipientReverts()
        external
        streamActive
        callerAuthorized
        toNonZeroAddress
        withdrawAmountNotZero
        withdrawAmountNotGreaterThanWithdrawableAmount
        callerSender
        currentTimeLessThanEndTime
        recipientContract
        recipientImplementsHook
    {
        // Create the stream with a reverting contract as the recipient.
        uint256 streamId = createDefaultStreamWithRecipient(address(revertingRecipient));

        // Expect a call to the recipient hook.
        vm.expectCall(
            address(revertingRecipient),
            abi.encodeCall(
                ISablierV2LockupRecipient.onStreamWithdrawn,
                (streamId, users.sender, address(revertingRecipient), DEFAULT_WITHDRAW_AMOUNT)
            )
        );

        // Make the withdrawal.
        lockup.withdraw({ streamId: streamId, to: address(revertingRecipient), amount: DEFAULT_WITHDRAW_AMOUNT });

        // Assert that the stream has remained active.
        Lockup.Status actualStatus = lockup.getStatus(streamId);
        Lockup.Status expectedStatus = Lockup.Status.ACTIVE;
        assertEq(actualStatus, expectedStatus);

        // Assert that the withdrawn amount has been updated.
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(streamId);
        uint128 expectedWithdrawnAmount = DEFAULT_WITHDRAW_AMOUNT;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount, "withdrawnAmount");
    }

    modifier recipientDoesNotRevert() {
        _;
    }

    /// @dev it should make multiple withdrawals, update the withdrawn amounts, and call the recipient hook.
    function test_Withdraw_RecipientReentrancy()
        external
        streamActive
        callerAuthorized
        toNonZeroAddress
        withdrawAmountNotZero
        withdrawAmountNotGreaterThanWithdrawableAmount
        callerSender
        currentTimeLessThanEndTime
        recipientContract
        recipientImplementsHook
        recipientDoesNotRevert
    {
        // Create the stream with a reentrant contract as the recipient.
        uint256 streamId = createDefaultStreamWithRecipient(address(reentrantRecipient));

        // Halve the withdraw amount so that the recipient can re-entry and make another withdrawal.
        uint128 withdrawAmount = DEFAULT_WITHDRAW_AMOUNT / 2;

        // Expect a call to the recipient hook.
        vm.expectCall(
            address(reentrantRecipient),
            abi.encodeCall(
                ISablierV2LockupRecipient.onStreamWithdrawn,
                (streamId, users.sender, address(reentrantRecipient), withdrawAmount)
            )
        );

        // Make the withdrawal.
        lockup.withdraw({ streamId: streamId, to: address(reentrantRecipient), amount: withdrawAmount });

        // Assert that the stream has remained active.
        Lockup.Status actualStatus = lockup.getStatus(streamId);
        Lockup.Status expectedStatus = Lockup.Status.ACTIVE;
        assertEq(actualStatus, expectedStatus);

        // Assert that the withdrawn amount has been updated.
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(streamId);
        uint128 expectedWithdrawnAmount = DEFAULT_WITHDRAW_AMOUNT;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount, "withdrawnAmount");
    }

    modifier noRecipientReentrancy() {
        _;
    }

    /// @dev it should make the withdrawal, update the withdrawn amount, call the recipient hook, and emit
    /// a {WithdrawFromLockupStream} event.
    function test_Withdraw()
        external
        streamActive
        callerAuthorized
        toNonZeroAddress
        withdrawAmountNotZero
        withdrawAmountNotGreaterThanWithdrawableAmount
        callerSender
        currentTimeLessThanEndTime
        recipientContract
        recipientImplementsHook
        recipientDoesNotRevert
        noRecipientReentrancy
    {
        // Create the stream with a contract as the recipient.
        uint256 streamId = createDefaultStreamWithRecipient(address(goodRecipient));

        // Warp into the future.
        vm.warp({ timestamp: DEFAULT_START_TIME + DEFAULT_TIME_WARP });

        // Set the withdraw amount to the streamed amount.
        uint128 withdrawAmount = lockup.streamedAmountOf(streamId);

        // Expect the ERC-20 assets to be transferred to the recipient.
        expectTransferCall({ to: address(goodRecipient), amount: withdrawAmount });

        // Expect a call to the recipient hook.
        vm.expectCall(
            address(goodRecipient),
            abi.encodeCall(
                ISablierV2LockupRecipient.onStreamWithdrawn,
                (streamId, users.sender, address(goodRecipient), withdrawAmount)
            )
        );

        // Expect a {WithdrawFromLockupStream} event to be emitted.
        expectEmit();
        emit Events.WithdrawFromLockupStream({
            streamId: streamId,
            to: address(goodRecipient),
            amount: withdrawAmount
        });

        // Make the withdrawal.
        lockup.withdraw({ streamId: streamId, to: address(goodRecipient), amount: withdrawAmount });

        // Assert that the stream has remained active.
        Lockup.Status actualStatus = lockup.getStatus(streamId);
        Lockup.Status expectedStatus = Lockup.Status.ACTIVE;
        assertEq(actualStatus, expectedStatus);

        // Assert that the withdrawn amount has been updated.
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(streamId);
        uint128 expectedWithdrawnAmount = withdrawAmount;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount, "withdrawnAmount");
    }
}
