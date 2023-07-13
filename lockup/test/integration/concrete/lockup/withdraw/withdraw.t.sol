// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { ISablierV2Lockup } from "src/interfaces/ISablierV2Lockup.sol";
import { ISablierV2LockupRecipient } from "src/interfaces/hooks/ISablierV2LockupRecipient.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Lockup } from "src/types/DataTypes.sol";

import { Withdraw_Integration_Shared_Test } from "../../../shared/lockup/withdraw.t.sol";
import { Integration_Test } from "../../../Integration.t.sol";

abstract contract Withdraw_Integration_Concrete_Test is Integration_Test, Withdraw_Integration_Shared_Test {
    function setUp() public virtual override(Integration_Test, Withdraw_Integration_Shared_Test) {
        Withdraw_Integration_Shared_Test.setUp();
    }

    function test_RevertWhen_DelegateCalled() external {
        uint128 withdrawAmount = defaults.WITHDRAW_AMOUNT();
        bytes memory callData =
            abi.encodeCall(ISablierV2Lockup.withdraw, (defaultStreamId, users.recipient, withdrawAmount));
        (bool success, bytes memory returnData) = address(lockup).delegatecall(callData);
        expectRevertDueToDelegateCall(success, returnData);
    }

    function test_RevertWhen_Null() external whenNotDelegateCalled {
        uint256 nullStreamId = 1729;
        uint128 withdrawAmount = defaults.WITHDRAW_AMOUNT();
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_Null.selector, nullStreamId));
        lockup.withdraw({ streamId: nullStreamId, to: users.recipient, amount: withdrawAmount });
    }

    function test_RevertWhen_StreamDepleted() external whenNotDelegateCalled whenNotNull {
        vm.warp({ timestamp: defaults.END_TIME() });
        lockup.withdrawMax({ streamId: defaultStreamId, to: users.recipient });

        uint128 withdrawAmount = defaults.WITHDRAW_AMOUNT();
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_StreamDepleted.selector, defaultStreamId));
        lockup.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: withdrawAmount });
    }

    function test_RevertWhen_CallerUnauthorized_Sender()
        external
        whenNotDelegateCalled
        whenNotNull
        whenStreamNotDepleted
        whenCallerUnauthorized
    {
        // Make the Sender the caller in this test.
        changePrank({ msgSender: users.sender });

        // Run the test.
        uint128 withdrawAmount = defaults.WITHDRAW_AMOUNT();
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2Lockup_InvalidSenderWithdrawal.selector, defaultStreamId, users.sender, users.sender
            )
        );
        lockup.withdraw({ streamId: defaultStreamId, to: users.sender, amount: withdrawAmount });
    }

    function test_RevertWhen_CallerUnauthorized_MaliciousThirdParty()
        external
        whenNotDelegateCalled
        whenNotNull
        whenStreamNotDepleted
        whenCallerUnauthorized
    {
        // Make Eve the caller in this test.
        changePrank({ msgSender: users.eve });

        // Run the test.
        uint128 withdrawAmount = defaults.WITHDRAW_AMOUNT();
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_Unauthorized.selector, defaultStreamId, users.eve)
        );
        lockup.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: withdrawAmount });
    }

    function test_RevertWhen_FormerRecipient() external whenNotDelegateCalled whenNotNull whenStreamNotDepleted {
        // Transfer the stream to Alice.
        lockup.transferFrom(users.recipient, users.alice, defaultStreamId);

        // Run the test.
        uint128 withdrawAmount = defaults.WITHDRAW_AMOUNT();
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_Unauthorized.selector, defaultStreamId, users.recipient)
        );
        lockup.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: withdrawAmount });
    }

    function test_RevertWhen_ToZeroAddress()
        external
        whenNotDelegateCalled
        whenNotNull
        whenStreamNotDepleted
        whenCallerAuthorized
    {
        uint128 withdrawAmount = defaults.WITHDRAW_AMOUNT();
        vm.expectRevert(Errors.SablierV2Lockup_WithdrawToZeroAddress.selector);
        lockup.withdraw({ streamId: defaultStreamId, to: address(0), amount: withdrawAmount });
    }

    function test_RevertWhen_WithdrawAmountZero()
        external
        whenNotDelegateCalled
        whenNotNull
        whenStreamNotDepleted
        whenCallerAuthorized
        whenToNonZeroAddress
    {
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_WithdrawAmountZero.selector, defaultStreamId));
        lockup.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: 0 });
    }

    function test_RevertWhen_Overdraw()
        external
        whenNotDelegateCalled
        whenNotNull
        whenStreamNotDepleted
        whenCallerAuthorized
        whenToNonZeroAddress
        whenWithdrawAmountNotZero
    {
        uint128 withdrawableAmount = 0;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2Lockup_Overdraw.selector, defaultStreamId, MAX_UINT128, withdrawableAmount
            )
        );
        lockup.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: MAX_UINT128 });
    }

    modifier whenNoOverdraw() {
        _;
    }

    function test_Withdraw_CallerRecipient()
        external
        whenNotDelegateCalled
        whenNotNull
        whenStreamNotDepleted
        whenCallerAuthorized
        whenToNonZeroAddress
        whenWithdrawAmountNotZero
        whenNoOverdraw
    {
        // Simulate the passage of time.
        vm.warp({ timestamp: defaults.WARP_26_PERCENT() });

        // Make Alice the `to` address in this test.
        address to = users.alice;

        // Make the withdrawal.
        lockup.withdraw({ streamId: defaultStreamId, to: to, amount: defaults.WITHDRAW_AMOUNT() });

        // Assert that the withdrawn amount has been updated.
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(defaultStreamId);
        uint128 expectedWithdrawnAmount = defaults.WITHDRAW_AMOUNT();
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount, "withdrawnAmount");
    }

    function test_Withdraw_CallerApprovedOperator()
        external
        whenNotDelegateCalled
        whenNotNull
        whenStreamNotDepleted
        whenCallerAuthorized
        whenToNonZeroAddress
        whenWithdrawAmountNotZero
        whenNoOverdraw
    {
        // Approve the operator to handle the stream.
        lockup.approve({ to: users.operator, tokenId: defaultStreamId });

        // Make the operator the caller in this test.
        changePrank({ msgSender: users.operator });

        // Simulate the passage of time.
        vm.warp({ timestamp: defaults.WARP_26_PERCENT() });

        // Make the withdrawal.
        lockup.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: defaults.WITHDRAW_AMOUNT() });

        // Assert that the withdrawn amount has been updated.
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(defaultStreamId);
        uint128 expectedWithdrawnAmount = defaults.WITHDRAW_AMOUNT();
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount, "withdrawnAmount");
    }

    modifier whenCallerSender() {
        changePrank({ msgSender: users.sender });
        _;
    }

    function test_Withdraw_EndTimeNotInTheFuture()
        external
        whenNotDelegateCalled
        whenNotNull
        whenStreamNotDepleted
        whenCallerAuthorized
        whenToNonZeroAddress
        whenWithdrawAmountNotZero
        whenNoOverdraw
        whenCallerSender
    {
        // Warp to the stream's end.
        vm.warp({ timestamp: defaults.END_TIME() });

        // Make the withdrawal.
        lockup.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: defaults.DEPOSIT_AMOUNT() });

        // Assert that the stream's status is "DEPLETED".
        Lockup.Status actualStatus = lockup.statusOf(defaultStreamId);
        Lockup.Status expectedStatus = Lockup.Status.DEPLETED;
        assertEq(actualStatus, expectedStatus);

        // Assert that the stream is not cancelable anymore.
        bool isCancelable = lockup.isCancelable(defaultStreamId);
        assertFalse(isCancelable, "isCancelable");

        // Assert that the NFT has not been burned.
        address actualNFTowner = lockup.ownerOf({ tokenId: defaultStreamId });
        address expectedNFTOwner = users.recipient;
        assertEq(actualNFTowner, expectedNFTOwner, "NFT owner");
    }

    modifier whenEndTimeInTheFuture() {
        // Simulate the passage of time.
        vm.warp({ timestamp: defaults.WARP_26_PERCENT() });
        _;
    }

    function test_Withdraw_StreamHasBeenCanceled()
        external
        whenNotDelegateCalled
        whenNotNull
        whenStreamNotDepleted
        whenCallerAuthorized
        whenToNonZeroAddress
        whenWithdrawAmountNotZero
        whenNoOverdraw
        whenCallerSender
        whenEndTimeInTheFuture
        whenRecipientContract
        whenRecipientImplementsHook
        whenRecipientDoesNotRevert
        whenNoRecipientReentrancy
    {
        // Create the stream with a contract as the stream's recipient.
        uint256 streamId = createDefaultStreamWithRecipient(address(goodRecipient));

        // Cancel the stream.
        lockup.cancel(streamId);

        // Set the withdraw amount to the withdrawable amount.
        uint128 withdrawAmount = lockup.withdrawableAmountOf(streamId);

        // Make the withdrawal.
        lockup.withdraw({ streamId: streamId, to: address(goodRecipient), amount: withdrawAmount });

        // Assert that the stream's status is "DEPLETED".
        Lockup.Status actualStatus = lockup.statusOf(streamId);
        Lockup.Status expectedStatus = Lockup.Status.DEPLETED;
        assertEq(actualStatus, expectedStatus);

        // Assert that the withdrawn amount has been updated.
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(streamId);
        uint128 expectedWithdrawnAmount = withdrawAmount;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount, "withdrawnAmount");

        // Assert that the NFT has not been burned.
        address actualNFTowner = lockup.ownerOf({ tokenId: streamId });
        address expectedNFTOwner = address(goodRecipient);
        assertEq(actualNFTowner, expectedNFTOwner, "NFT owner");
    }

    function test_Withdraw_RecipientNotContract()
        external
        whenNotDelegateCalled
        whenNotNull
        whenStreamNotDepleted
        whenCallerAuthorized
        whenToNonZeroAddress
        whenWithdrawAmountNotZero
        whenNoOverdraw
        whenCallerSender
        whenEndTimeInTheFuture
        whenStreamHasNotBeenCanceled
    {
        // Set the withdraw amount to the streamed amount.
        uint128 withdrawAmount = lockup.streamedAmountOf(defaultStreamId);

        // Expect the assets to be transferred to the Recipient.
        expectCallToTransfer({ to: users.recipient, amount: withdrawAmount });

        // Expect the relevant event to be emitted.
        vm.expectEmit({ emitter: address(lockup) });
        emit WithdrawFromLockupStream({ streamId: defaultStreamId, to: users.recipient, amount: withdrawAmount });

        // Make the withdrawal.
        lockup.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: withdrawAmount });

        // Assert that the stream's status is still "STREAMING".
        Lockup.Status actualStatus = lockup.statusOf(defaultStreamId);
        Lockup.Status expectedStatus = Lockup.Status.STREAMING;
        assertEq(actualStatus, expectedStatus);

        // Assert that the withdrawn amount has been updated.
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(defaultStreamId);
        uint128 expectedWithdrawnAmount = withdrawAmount;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount, "withdrawnAmount");
    }

    modifier whenRecipientContract() {
        _;
    }

    function test_Withdraw_RecipientDoesNotImplementHook()
        external
        whenNotDelegateCalled
        whenNotNull
        whenStreamNotDepleted
        whenCallerAuthorized
        whenToNonZeroAddress
        whenWithdrawAmountNotZero
        whenNoOverdraw
        whenCallerSender
        whenEndTimeInTheFuture
        whenStreamHasNotBeenCanceled
        whenRecipientContract
    {
        // Create the stream with a no-op contract as the stream's recipient.
        uint256 streamId = createDefaultStreamWithRecipient(address(noop));

        // Expect a call to the hook.
        vm.expectCall(
            address(noop),
            abi.encodeCall(
                ISablierV2LockupRecipient.onStreamWithdrawn,
                (streamId, users.sender, address(noop), defaults.WITHDRAW_AMOUNT())
            )
        );

        // Make the withdrawal.
        lockup.withdraw({ streamId: streamId, to: address(noop), amount: defaults.WITHDRAW_AMOUNT() });

        // Assert that the stream's status is still "STREAMING".
        Lockup.Status actualStatus = lockup.statusOf(streamId);
        Lockup.Status expectedStatus = Lockup.Status.STREAMING;
        assertEq(actualStatus, expectedStatus);

        // Assert that the withdrawn amount has been updated.
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(streamId);
        uint128 expectedWithdrawnAmount = defaults.WITHDRAW_AMOUNT();
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount, "withdrawnAmount");
    }

    modifier whenRecipientImplementsHook() {
        _;
    }

    function test_Withdraw_RecipientReverts()
        external
        whenNotDelegateCalled
        whenNotNull
        whenStreamNotDepleted
        whenCallerAuthorized
        whenToNonZeroAddress
        whenWithdrawAmountNotZero
        whenNoOverdraw
        whenCallerSender
        whenEndTimeInTheFuture
        whenStreamHasNotBeenCanceled
        whenRecipientContract
        whenRecipientImplementsHook
    {
        // Create the stream with a reverting contract as the stream's recipient.
        uint256 streamId = createDefaultStreamWithRecipient(address(revertingRecipient));

        // Expect a call to the hook.
        vm.expectCall(
            address(revertingRecipient),
            abi.encodeCall(
                ISablierV2LockupRecipient.onStreamWithdrawn,
                (streamId, users.sender, address(revertingRecipient), defaults.WITHDRAW_AMOUNT())
            )
        );

        // Make the withdrawal.
        lockup.withdraw({ streamId: streamId, to: address(revertingRecipient), amount: defaults.WITHDRAW_AMOUNT() });

        // Assert that the stream's status is still "STREAMING".
        Lockup.Status actualStatus = lockup.statusOf(streamId);
        Lockup.Status expectedStatus = Lockup.Status.STREAMING;
        assertEq(actualStatus, expectedStatus);

        // Assert that the withdrawn amount has been updated.
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(streamId);
        uint128 expectedWithdrawnAmount = defaults.WITHDRAW_AMOUNT();
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount, "withdrawnAmount");
    }

    modifier whenRecipientDoesNotRevert() {
        _;
    }

    function test_Withdraw_RecipientReentrancy()
        external
        whenNotDelegateCalled
        whenNotNull
        whenStreamNotDepleted
        whenCallerAuthorized
        whenToNonZeroAddress
        whenWithdrawAmountNotZero
        whenNoOverdraw
        whenCallerSender
        whenEndTimeInTheFuture
        whenStreamHasNotBeenCanceled
        whenRecipientContract
        whenRecipientImplementsHook
        whenRecipientDoesNotRevert
    {
        // Create the stream with a reentrant contract as the stream's recipient.
        uint256 streamId = createDefaultStreamWithRecipient(address(reentrantRecipient));

        // Halve the withdraw amount so that the recipient can re-entry and make another withdrawal.
        uint128 withdrawAmount = defaults.WITHDRAW_AMOUNT() / 2;

        // Expect a call to the hook.
        vm.expectCall(
            address(reentrantRecipient),
            abi.encodeCall(
                ISablierV2LockupRecipient.onStreamWithdrawn,
                (streamId, users.sender, address(reentrantRecipient), withdrawAmount)
            )
        );

        // Make the withdrawal.
        lockup.withdraw({ streamId: streamId, to: address(reentrantRecipient), amount: withdrawAmount });

        // Assert that the stream's status is still "STREAMING".
        Lockup.Status actualStatus = lockup.statusOf(streamId);
        Lockup.Status expectedStatus = Lockup.Status.STREAMING;
        assertEq(actualStatus, expectedStatus);

        // Assert that the withdrawn amount has been updated.
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(streamId);
        uint128 expectedWithdrawnAmount = defaults.WITHDRAW_AMOUNT();
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount, "withdrawnAmount");
    }

    modifier whenNoRecipientReentrancy() {
        _;
    }

    function test_Withdraw()
        external
        whenNotDelegateCalled
        whenNotNull
        whenStreamNotDepleted
        whenCallerAuthorized
        whenToNonZeroAddress
        whenWithdrawAmountNotZero
        whenNoOverdraw
        whenCallerSender
        whenEndTimeInTheFuture
        whenStreamHasNotBeenCanceled
        whenRecipientContract
        whenRecipientImplementsHook
        whenRecipientDoesNotRevert
        whenNoRecipientReentrancy
    {
        // Create the stream with a contract as the stream's recipient.
        uint256 streamId = createDefaultStreamWithRecipient(address(goodRecipient));

        // Set the withdraw amount to the streamed amount.
        uint128 withdrawAmount = lockup.streamedAmountOf(streamId);

        // Expect the assets to be transferred to the recipient contract.
        expectCallToTransfer({ to: address(goodRecipient), amount: withdrawAmount });

        // Expect a call to the hook.
        vm.expectCall(
            address(goodRecipient),
            abi.encodeCall(
                ISablierV2LockupRecipient.onStreamWithdrawn,
                (streamId, users.sender, address(goodRecipient), withdrawAmount)
            )
        );

        // Expect the relevant events to be emitted.
        vm.expectEmit({ emitter: address(lockup) });
        emit WithdrawFromLockupStream({ streamId: streamId, to: address(goodRecipient), amount: withdrawAmount });
        vm.expectEmit({ emitter: address(lockup) });
        emit MetadataUpdate({ _tokenId: streamId });

        // Make the withdrawal.
        lockup.withdraw({ streamId: streamId, to: address(goodRecipient), amount: withdrawAmount });

        // Assert that the stream's status is still "STREAMING".
        Lockup.Status actualStatus = lockup.statusOf(streamId);
        Lockup.Status expectedStatus = Lockup.Status.STREAMING;
        assertEq(actualStatus, expectedStatus);

        // Assert that the withdrawn amount has been updated.
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(streamId);
        uint128 expectedWithdrawnAmount = withdrawAmount;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount, "withdrawnAmount");
    }
}
