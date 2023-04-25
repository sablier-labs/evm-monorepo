// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19 <0.9.0;

import { ISablierV2Lockup } from "src/interfaces/ISablierV2Lockup.sol";
import { ISablierV2LockupRecipient } from "src/interfaces/hooks/ISablierV2LockupRecipient.sol";
import { Errors } from "src/libraries/Errors.sol";

import { Lockup } from "src/types/DataTypes.sol";

import { Lockup_Shared_Test } from "../../../../shared/lockup/Lockup.t.sol";
import { Unit_Test } from "../../../Unit.t.sol";

abstract contract Withdraw_Unit_Test is Unit_Test, Lockup_Shared_Test {
    uint256 internal defaultStreamId;

    function setUp() public virtual override(Unit_Test, Lockup_Shared_Test) {
        defaultStreamId = createDefaultStream();
        changePrank({ msgSender: users.recipient });
    }

    function test_RevertWhen_DelegateCall() external {
        bytes memory callData =
            abi.encodeCall(ISablierV2Lockup.withdraw, (defaultStreamId, users.recipient, DEFAULT_WITHDRAW_AMOUNT));
        (bool success, bytes memory returnData) = address(lockup).delegatecall(callData);
        expectRevertDueToDelegateCall(success, returnData);
    }

    modifier whenNoDelegateCall() {
        _;
    }

    function test_RevertWhen_Null() external whenNoDelegateCall {
        uint256 nullStreamId = 1729;
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_Null.selector, nullStreamId));
        lockup.withdraw({ streamId: nullStreamId, to: users.recipient, amount: DEFAULT_WITHDRAW_AMOUNT });
    }

    modifier whenNotNull() {
        _;
    }

    function test_RevertWhen_StreamDepleted() external whenNoDelegateCall whenNotNull {
        vm.warp({ timestamp: DEFAULT_END_TIME });
        lockup.withdrawMax({ streamId: defaultStreamId, to: users.recipient });
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_StreamDepleted.selector, defaultStreamId));
        lockup.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: DEFAULT_WITHDRAW_AMOUNT });
    }

    modifier whenStreamNeitherPendingNorDepleted() {
        _;
    }

    modifier whenCallerUnauthorized() {
        _;
    }

    function test_RevertWhen_CallerUnauthorized_MaliciousThirdParty()
        external
        whenNoDelegateCall
        whenNotNull
        whenStreamNeitherPendingNorDepleted
        whenCallerUnauthorized
    {
        // Make Eve the caller in this test.
        changePrank({ msgSender: users.eve });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_Unauthorized.selector, defaultStreamId, users.eve)
        );
        lockup.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: DEFAULT_WITHDRAW_AMOUNT });
    }

    function test_RevertWhen_CallerUnauthorized_Sender()
        external
        whenNoDelegateCall
        whenNotNull
        whenStreamNeitherPendingNorDepleted
        whenCallerUnauthorized
    {
        // Make the sender the caller in this test.
        changePrank({ msgSender: users.sender });

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2Lockup_WithdrawSenderUnauthorized.selector, defaultStreamId, users.sender, users.sender
            )
        );
        lockup.withdraw({ streamId: defaultStreamId, to: users.sender, amount: DEFAULT_WITHDRAW_AMOUNT });
    }

    function test_RevertWhen_FormerRecipient()
        external
        whenNoDelegateCall
        whenNotNull
        whenStreamNeitherPendingNorDepleted
    {
        // Transfer the stream to Alice.
        lockup.transferFrom(users.recipient, users.alice, defaultStreamId);

        // Run the test.
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierV2Lockup_Unauthorized.selector, defaultStreamId, users.recipient)
        );
        lockup.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: DEFAULT_WITHDRAW_AMOUNT });
    }

    modifier whenCallerAuthorized() {
        _;
    }

    function test_RevertWhen_ZeroAddress()
        external
        whenNoDelegateCall
        whenNotNull
        whenStreamNeitherPendingNorDepleted
        whenCallerAuthorized
    {
        vm.expectRevert(Errors.SablierV2Lockup_WithdrawToZeroAddress.selector);
        lockup.withdraw({ streamId: defaultStreamId, to: address(0), amount: DEFAULT_WITHDRAW_AMOUNT });
    }

    modifier whenToNonZeroAddress() {
        _;
    }

    function test_RevertWhen_WithdrawAmountZero()
        external
        whenNoDelegateCall
        whenNotNull
        whenStreamNeitherPendingNorDepleted
        whenCallerAuthorized
        whenToNonZeroAddress
    {
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierV2Lockup_WithdrawAmountZero.selector, defaultStreamId));
        lockup.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: 0 });
    }

    modifier whenWithdrawAmountNotZero() {
        _;
    }

    function test_RevertWhen_Overdraw()
        external
        whenNoDelegateCall
        whenNotNull
        whenStreamNeitherPendingNorDepleted
        whenCallerAuthorized
        whenToNonZeroAddress
        whenWithdrawAmountNotZero
    {
        uint128 withdrawableAmount = 0;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierV2Lockup_Overdraw.selector, defaultStreamId, UINT128_MAX, withdrawableAmount
            )
        );
        lockup.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: UINT128_MAX });
    }

    modifier whenNoOverdraw() {
        _;
    }

    function test_Withdraw_CallerRecipient()
        external
        whenNoDelegateCall
        whenNotNull
        whenStreamNeitherPendingNorDepleted
        whenCallerAuthorized
        whenToNonZeroAddress
        whenWithdrawAmountNotZero
        whenNoOverdraw
    {
        // Warp into the future.
        vm.warp({ timestamp: WARP_26_PERCENT });

        // Make Alice the `to` address in this test.
        address to = users.alice;

        // Make the withdrawal.
        lockup.withdraw({ streamId: defaultStreamId, to: to, amount: DEFAULT_WITHDRAW_AMOUNT });

        // Assert that the stream's status is still streaming.
        Lockup.Status actualStatus = lockup.statusOf(defaultStreamId);
        Lockup.Status expectedStatus = Lockup.Status.STREAMING;
        assertEq(actualStatus, expectedStatus);

        // Assert that the withdrawn amount has been updated.
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(defaultStreamId);
        uint128 expectedWithdrawnAmount = DEFAULT_WITHDRAW_AMOUNT;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount, "withdrawnAmount");
    }

    function test_Withdraw_CallerApprovedOperator()
        external
        whenNoDelegateCall
        whenNotNull
        whenStreamNeitherPendingNorDepleted
        whenCallerAuthorized
        whenToNonZeroAddress
        whenWithdrawAmountNotZero
        whenNoOverdraw
    {
        // Approve the operator to handle the stream.
        lockup.approve({ to: users.operator, tokenId: defaultStreamId });

        // Make the operator the caller in this test.
        changePrank({ msgSender: users.operator });

        // Warp into the future.
        vm.warp({ timestamp: WARP_26_PERCENT });

        // Make the withdrawal.
        lockup.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: DEFAULT_WITHDRAW_AMOUNT });

        // Assert that the stream's status is still streaming.
        Lockup.Status actualStatus = lockup.statusOf(defaultStreamId);
        Lockup.Status expectedStatus = Lockup.Status.STREAMING;
        assertEq(actualStatus, expectedStatus);

        // Assert that the withdrawn amount has been updated.
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(defaultStreamId);
        uint128 expectedWithdrawnAmount = DEFAULT_WITHDRAW_AMOUNT;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount, "withdrawnAmount");
    }

    modifier whenCallerSender() {
        changePrank({ msgSender: users.sender });
        _;
    }

    function test_Withdraw_EndTimeInThePresent()
        external
        whenNoDelegateCall
        whenNotNull
        whenStreamNeitherPendingNorDepleted
        whenCallerAuthorized
        whenToNonZeroAddress
        whenWithdrawAmountNotZero
        whenNoOverdraw
        whenCallerSender
    {
        // Warp to the end of the stream.
        vm.warp({ timestamp: DEFAULT_END_TIME });

        // Make the withdrawal.
        lockup.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: DEFAULT_DEPOSIT_AMOUNT });

        // Assert that the stream's status is depleted.
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
        // Warp into the future.
        vm.warp({ timestamp: WARP_26_PERCENT });
        _;
    }

    function test_Withdraw_StreamHasBeenCanceled()
        external
        whenNoDelegateCall
        whenNotNull
        whenStreamNeitherPendingNorDepleted
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
        // Create the stream with a contract as the recipient.
        uint256 streamId = createDefaultStreamWithRecipient(address(goodRecipient));

        // Cancel the stream.
        lockup.cancel(streamId);

        // Set the withdraw amount to the withdrawable amount.
        uint128 withdrawAmount = lockup.withdrawableAmountOf(streamId);

        // Make the withdrawal.
        lockup.withdraw({ streamId: streamId, to: address(goodRecipient), amount: withdrawAmount });

        // Assert that the stream's status is depleted.
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

    modifier whenStreamHasNotBeenCanceled() {
        _;
    }

    function test_Withdraw_RecipientNotContract()
        external
        whenNoDelegateCall
        whenNotNull
        whenStreamNeitherPendingNorDepleted
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

        // Expect the assets to be transferred to the recipient.
        expectTransferCall({ to: users.recipient, amount: withdrawAmount });

        // Expect a {WithdrawFromLockupStream} event to be emitted.
        vm.expectEmit({ emitter: address(lockup) });
        emit WithdrawFromLockupStream({ streamId: defaultStreamId, to: users.recipient, amount: withdrawAmount });

        // Make the withdrawal.
        lockup.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: withdrawAmount });

        // Assert that the stream's status is still streaming.
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
        whenNoDelegateCall
        whenNotNull
        whenStreamNeitherPendingNorDepleted
        whenCallerAuthorized
        whenToNonZeroAddress
        whenWithdrawAmountNotZero
        whenNoOverdraw
        whenCallerSender
        whenEndTimeInTheFuture
        whenStreamHasNotBeenCanceled
        whenRecipientContract
    {
        // Create the stream with an empty contract as the recipient.
        uint256 streamId = createDefaultStreamWithRecipient(address(empty));

        // Expect a call to the recipient hook.
        vm.expectCall(
            address(empty),
            abi.encodeCall(
                ISablierV2LockupRecipient.onStreamWithdrawn,
                (lockup, streamId, users.sender, address(empty), DEFAULT_WITHDRAW_AMOUNT)
            )
        );

        // Make the withdrawal.
        lockup.withdraw({ streamId: streamId, to: address(empty), amount: DEFAULT_WITHDRAW_AMOUNT });

        // Assert that the stream's status is still streaming.
        Lockup.Status actualStatus = lockup.statusOf(streamId);
        Lockup.Status expectedStatus = Lockup.Status.STREAMING;
        assertEq(actualStatus, expectedStatus);

        // Assert that the withdrawn amount has been updated.
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(streamId);
        uint128 expectedWithdrawnAmount = DEFAULT_WITHDRAW_AMOUNT;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount, "withdrawnAmount");
    }

    modifier whenRecipientImplementsHook() {
        _;
    }

    function test_Withdraw_RecipientReverts()
        external
        whenNoDelegateCall
        whenNotNull
        whenStreamNeitherPendingNorDepleted
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
        // Create the stream with a reverting contract as the recipient.
        uint256 streamId = createDefaultStreamWithRecipient(address(revertingRecipient));

        // Expect a call to the recipient hook.
        vm.expectCall(
            address(revertingRecipient),
            abi.encodeCall(
                ISablierV2LockupRecipient.onStreamWithdrawn,
                (lockup, streamId, users.sender, address(revertingRecipient), DEFAULT_WITHDRAW_AMOUNT)
            )
        );

        // Make the withdrawal.
        lockup.withdraw({ streamId: streamId, to: address(revertingRecipient), amount: DEFAULT_WITHDRAW_AMOUNT });

        // Assert that the stream's status is still streaming.
        Lockup.Status actualStatus = lockup.statusOf(streamId);
        Lockup.Status expectedStatus = Lockup.Status.STREAMING;
        assertEq(actualStatus, expectedStatus);

        // Assert that the withdrawn amount has been updated.
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(streamId);
        uint128 expectedWithdrawnAmount = DEFAULT_WITHDRAW_AMOUNT;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount, "withdrawnAmount");
    }

    modifier whenRecipientDoesNotRevert() {
        _;
    }

    function test_Withdraw_RecipientReentrancy()
        external
        whenNoDelegateCall
        whenNotNull
        whenStreamNeitherPendingNorDepleted
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
        // Create the stream with a reentrant contract as the recipient.
        uint256 streamId = createDefaultStreamWithRecipient(address(reentrantRecipient));

        // Halve the withdraw amount so that the recipient can re-entry and make another withdrawal.
        uint128 withdrawAmount = DEFAULT_WITHDRAW_AMOUNT / 2;

        // Expect a call to the recipient hook.
        vm.expectCall(
            address(reentrantRecipient),
            abi.encodeCall(
                ISablierV2LockupRecipient.onStreamWithdrawn,
                (lockup, streamId, users.sender, address(reentrantRecipient), withdrawAmount)
            )
        );

        // Make the withdrawal.
        lockup.withdraw({ streamId: streamId, to: address(reentrantRecipient), amount: withdrawAmount });

        // Assert that the stream's status is still streaming.
        Lockup.Status actualStatus = lockup.statusOf(streamId);
        Lockup.Status expectedStatus = Lockup.Status.STREAMING;
        assertEq(actualStatus, expectedStatus);

        // Assert that the withdrawn amount has been updated.
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(streamId);
        uint128 expectedWithdrawnAmount = DEFAULT_WITHDRAW_AMOUNT;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount, "withdrawnAmount");
    }

    modifier whenNoRecipientReentrancy() {
        _;
    }

    function test_Withdraw()
        external
        whenNoDelegateCall
        whenNotNull
        whenStreamNeitherPendingNorDepleted
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
        // Create the stream with a contract as the recipient.
        uint256 streamId = createDefaultStreamWithRecipient(address(goodRecipient));

        // Set the withdraw amount to the streamed amount.
        uint128 withdrawAmount = lockup.streamedAmountOf(streamId);

        // Expect the assets to be transferred to the recipient.
        expectTransferCall({ to: address(goodRecipient), amount: withdrawAmount });

        // Expect a call to the recipient hook.
        vm.expectCall(
            address(goodRecipient),
            abi.encodeCall(
                ISablierV2LockupRecipient.onStreamWithdrawn,
                (lockup, streamId, users.sender, address(goodRecipient), withdrawAmount)
            )
        );

        // Expect a {WithdrawFromLockupStream} event to be emitted.
        vm.expectEmit({ emitter: address(lockup) });
        emit WithdrawFromLockupStream({ streamId: streamId, to: address(goodRecipient), amount: withdrawAmount });

        // Make the withdrawal.
        lockup.withdraw({ streamId: streamId, to: address(goodRecipient), amount: withdrawAmount });

        // Assert that the stream's status is still streaming.
        Lockup.Status actualStatus = lockup.statusOf(streamId);
        Lockup.Status expectedStatus = Lockup.Status.STREAMING;
        assertEq(actualStatus, expectedStatus);

        // Assert that the withdrawn amount has been updated.
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(streamId);
        uint128 expectedWithdrawnAmount = withdrawAmount;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount, "withdrawnAmount");
    }
}
