// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierLockup } from "src/core/interfaces/ISablierLockup.sol";
import { ISablierLockupRecipient } from "src/core/interfaces/ISablierLockupRecipient.sol";
import { Errors } from "src/core/libraries/Errors.sol";
import { Lockup } from "src/core/types/DataTypes.sol";
import { Integration_Test } from "./../../../Integration.t.sol";
import { Withdraw_Integration_Shared_Test } from "./../../../shared/lockup/withdraw.t.sol";

abstract contract Withdraw_Integration_Concrete_Test is Integration_Test, Withdraw_Integration_Shared_Test {
    function setUp() public virtual override(Integration_Test, Withdraw_Integration_Shared_Test) {
        Withdraw_Integration_Shared_Test.setUp();
    }

    function test_RevertWhen_DelegateCall() external {
        uint128 withdrawAmount = defaults.WITHDRAW_AMOUNT();
        bytes memory callData =
            abi.encodeCall(ISablierLockup.withdraw, (defaultStreamId, users.recipient, withdrawAmount));
        (bool success, bytes memory returnData) = address(lockup).delegatecall(callData);
        expectRevertDueToDelegateCall(success, returnData);
    }

    function test_RevertGiven_Null() external whenNoDelegateCall {
        uint256 nullStreamId = 1729;
        uint128 withdrawAmount = defaults.WITHDRAW_AMOUNT();
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierLockup_Null.selector, nullStreamId));
        lockup.withdraw({ streamId: nullStreamId, to: users.recipient, amount: withdrawAmount });
    }

    function test_RevertGiven_DEPLETEDStatus() external whenNoDelegateCall givenNotNull {
        vm.warp({ newTimestamp: defaults.END_TIME() });
        lockup.withdrawMax({ streamId: defaultStreamId, to: users.recipient });

        uint128 withdrawAmount = defaults.WITHDRAW_AMOUNT();
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierLockup_StreamDepleted.selector, defaultStreamId));
        lockup.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: withdrawAmount });
    }

    function test_RevertWhen_WithdrawalAddressZero() external whenNoDelegateCall givenNotNull givenNotDEPLETEDStatus {
        uint128 withdrawAmount = defaults.WITHDRAW_AMOUNT();
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierLockup_WithdrawToZeroAddress.selector, defaultStreamId));
        lockup.withdraw({ streamId: defaultStreamId, to: address(0), amount: withdrawAmount });
    }

    function test_RevertWhen_ZeroWithdrawAmount()
        external
        whenNoDelegateCall
        givenNotNull
        givenNotDEPLETEDStatus
        whenWithdrawalAddressNotZero
    {
        vm.expectRevert(abi.encodeWithSelector(Errors.SablierLockup_WithdrawAmountZero.selector, defaultStreamId));
        lockup.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: 0 });
    }

    function test_RevertWhen_WithdrawAmountOverdraws()
        external
        whenNoDelegateCall
        givenNotNull
        givenNotDEPLETEDStatus
        whenWithdrawalAddressNotZero
        whenNonZeroWithdrawAmount
    {
        uint128 withdrawableAmount = 0;
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierLockup_Overdraw.selector, defaultStreamId, MAX_UINT128, withdrawableAmount
            )
        );
        lockup.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: MAX_UINT128 });
    }

    modifier whenWithdrawalAddressNotRecipient(bool isCallerRecipient) {
        if (!isCallerRecipient) {
            // When caller is unknown.
            caller = users.eve;
            resetPrank({ msgSender: caller });
            _;

            // When caller is sender.
            caller = users.sender;
            resetPrank({ msgSender: caller });
            _;

            // When caller is a former recipient.
            caller = users.recipient;
            resetPrank({ msgSender: caller });
            lockup.transferFrom(caller, users.eve, defaultStreamId);
            _;
        } else {
            // When caller is approved third party.
            caller = users.operator;
            lockup.approve({ to: caller, tokenId: defaultStreamId });
            resetPrank({ msgSender: caller });
            _;

            // When caller is recipient.
            caller = users.recipient;
            resetPrank({ msgSender: caller });
            _;
        }
    }

    function test_RevertWhen_CallerNotApprovedThirdPartyOrRecipient()
        external
        whenNoDelegateCall
        givenNotNull
        givenNotDEPLETEDStatus
        whenWithdrawalAddressNotZero
        whenNonZeroWithdrawAmount
        whenWithdrawAmountNotOverdraw
        whenWithdrawalAddressNotRecipient(false)
    {
        // Simulate the passage of time.
        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });

        // Set the withdraw amount to the default amount.
        uint128 withdrawAmount = defaults.WITHDRAW_AMOUNT();

        // It should revert.
        vm.expectRevert(
            abi.encodeWithSelector(
                Errors.SablierLockup_WithdrawalAddressNotRecipient.selector, defaultStreamId, caller, users.alice
            )
        );
        lockup.withdraw({ streamId: defaultStreamId, to: users.alice, amount: withdrawAmount });
    }

    function test_WhenCallerApprovedThirdPartyOrRecipient()
        external
        whenNoDelegateCall
        givenNotNull
        givenNotDEPLETEDStatus
        whenWithdrawalAddressNotZero
        whenNonZeroWithdrawAmount
        whenWithdrawAmountNotOverdraw
        whenWithdrawalAddressNotRecipient(true)
    {
        // Simulate the passage of time.
        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });

        // Set the withdraw amount to the default amount.
        uint128 withdrawAmount = defaults.WITHDRAW_AMOUNT() / 2;

        uint128 previousWithdrawnAmount = lockup.getWithdrawnAmount(defaultStreamId);

        // It should emit {WithdrawFromLockupStream} and {MetadataUpdate} events.
        vm.expectEmit({ emitter: address(lockup) });
        emit WithdrawFromLockupStream({ streamId: defaultStreamId, to: users.alice, asset: dai, amount: withdrawAmount });
        vm.expectEmit({ emitter: address(lockup) });
        emit MetadataUpdate({ _tokenId: defaultStreamId });

        // Make the withdrawal.
        lockup.withdraw({ streamId: defaultStreamId, to: users.alice, amount: withdrawAmount });

        // It should update the withdrawn amount.
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(defaultStreamId);
        uint128 expectedWithdrawnAmount = previousWithdrawnAmount + withdrawAmount;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount, "withdrawnAmount");
    }

    function test_WhenCallerUnknown()
        external
        whenNoDelegateCall
        givenNotNull
        givenNotDEPLETEDStatus
        whenWithdrawalAddressNotZero
        whenNonZeroWithdrawAmount
        whenWithdrawAmountNotOverdraw
        whenWithdrawalAddressRecipient
    {
        // Make the unknown address the caller in this test.
        resetPrank({ msgSender: address(0xCAFE) });

        // Simulate the passage of time.
        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });

        // Make the withdrawal.
        lockup.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: defaults.WITHDRAW_AMOUNT() });

        // It should update the withdrawn amount.
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(defaultStreamId);
        uint128 expectedWithdrawnAmount = defaults.WITHDRAW_AMOUNT();
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount, "withdrawnAmount");
    }

    function test_WhenCallerRecipient()
        external
        whenNoDelegateCall
        givenNotNull
        givenNotDEPLETEDStatus
        whenWithdrawalAddressNotZero
        whenNonZeroWithdrawAmount
        whenWithdrawAmountNotOverdraw
        whenWithdrawalAddressRecipient
    {
        // Simulate the passage of time.
        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });

        // Make the withdrawal.
        lockup.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: defaults.WITHDRAW_AMOUNT() });

        // It should update the withdrawn amount.
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(defaultStreamId);
        uint128 expectedWithdrawnAmount = defaults.WITHDRAW_AMOUNT();
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount, "withdrawnAmount");
    }

    function test_GivenEndTimeNotInFuture()
        external
        whenNoDelegateCall
        givenNotNull
        givenNotDEPLETEDStatus
        whenWithdrawalAddressNotZero
        whenNonZeroWithdrawAmount
        whenWithdrawAmountNotOverdraw
        whenWithdrawalAddressRecipient
        whenCallerSender
    {
        // Warp to the stream's end.
        vm.warp({ newTimestamp: defaults.END_TIME() });

        // Make the withdrawal.
        lockup.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: defaults.DEPOSIT_AMOUNT() });

        // It should mark the stream as depleted.
        Lockup.Status actualStatus = lockup.statusOf(defaultStreamId);
        Lockup.Status expectedStatus = Lockup.Status.DEPLETED;
        assertEq(actualStatus, expectedStatus);

        // It should make the stream not cancelable.
        bool isCancelable = lockup.isCancelable(defaultStreamId);
        assertFalse(isCancelable, "isCancelable");

        // Assert that the not burned NFT.
        address actualNFTowner = lockup.ownerOf({ tokenId: defaultStreamId });
        address expectedNFTOwner = users.recipient;
        assertEq(actualNFTowner, expectedNFTOwner, "NFT owner");
    }

    function test_GivenCanceledStream()
        external
        whenNoDelegateCall
        givenNotNull
        givenNotDEPLETEDStatus
        whenWithdrawalAddressNotZero
        whenNonZeroWithdrawAmount
        whenWithdrawAmountNotOverdraw
        whenWithdrawalAddressRecipient
        whenCallerSender
        givenEndTimeInFuture
    {
        // Cancel the stream.
        lockup.cancel(defaultStreamId);

        // Set the withdraw amount to the withdrawable amount.
        uint128 withdrawAmount = lockup.withdrawableAmountOf(defaultStreamId);

        // It should emit {WithdrawFromLockupStream} and {MetadataUpdate} events.
        vm.expectEmit({ emitter: address(lockup) });
        emit WithdrawFromLockupStream({
            streamId: defaultStreamId,
            to: users.recipient,
            asset: dai,
            amount: withdrawAmount
        });
        vm.expectEmit({ emitter: address(lockup) });
        emit MetadataUpdate({ _tokenId: defaultStreamId });

        // Make the withdrawal.
        lockup.withdraw({ streamId: defaultStreamId, to: users.recipient, amount: withdrawAmount });

        // It should mark the stream as depleted.
        Lockup.Status actualStatus = lockup.statusOf(defaultStreamId);
        Lockup.Status expectedStatus = Lockup.Status.DEPLETED;
        assertEq(actualStatus, expectedStatus);

        // It should update the withdrawn amount.
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(defaultStreamId);
        uint128 expectedWithdrawnAmount = withdrawAmount;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount, "withdrawnAmount");

        // Assert that the not burned NFT.
        address actualNFTowner = lockup.ownerOf({ tokenId: defaultStreamId });
        address expectedNFTOwner = users.recipient;
        assertEq(actualNFTowner, expectedNFTOwner, "NFT owner");
    }

    function test_GivenRecipientNotAllowedToHook()
        external
        whenNoDelegateCall
        givenNotNull
        givenNotDEPLETEDStatus
        whenWithdrawalAddressNotZero
        whenNonZeroWithdrawAmount
        whenWithdrawAmountNotOverdraw
        whenWithdrawalAddressRecipient
        whenCallerSender
        givenEndTimeInFuture
        givenNotCanceledStream
    {
        // Create the stream with a recipient contract that implements {ISablierLockupRecipient}.
        uint256 streamId = createDefaultStreamWithRecipient(address(recipientGood));

        // It should not make Sablier run the recipient hook.
        uint128 withdrawAmount = lockup.withdrawableAmountOf(streamId);
        vm.expectCall({
            callee: address(recipientGood),
            data: abi.encodeCall(
                ISablierLockupRecipient.onSablierLockupWithdraw,
                (streamId, users.sender, address(recipientGood), withdrawAmount)
            ),
            count: 0
        });

        // Make the withdrawal.
        lockup.withdraw({ streamId: streamId, to: address(recipientGood), amount: withdrawAmount });

        // It should update the withdrawn amount.
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(streamId);
        uint128 expectedWithdrawnAmount = withdrawAmount;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount, "withdrawnAmount");
    }

    function test_RevertWhen_RevertingRecipient()
        external
        whenNoDelegateCall
        givenNotNull
        givenNotDEPLETEDStatus
        whenWithdrawalAddressNotZero
        whenNonZeroWithdrawAmount
        whenWithdrawAmountNotOverdraw
        whenWithdrawalAddressRecipient
        whenCallerSender
        givenEndTimeInFuture
        givenNotCanceledStream
        givenRecipientAllowedToHook
    {
        // Allow the recipient to hook.
        resetPrank({ msgSender: users.admin });
        lockup.allowToHook(address(recipientReverting));
        resetPrank({ msgSender: users.sender });

        // Create the stream with a reverting contract as the stream's recipient.
        uint256 streamId = createDefaultStreamWithRecipient(address(recipientReverting));

        // Expect a revert.
        uint128 withdrawAmount = defaults.WITHDRAW_AMOUNT();
        vm.expectRevert("You shall not pass");

        // Make the withdrawal.
        lockup.withdraw({ streamId: streamId, to: address(recipientReverting), amount: withdrawAmount });
    }

    function test_RevertWhen_HookReturnsInvalidSelector()
        external
        whenNoDelegateCall
        givenNotNull
        givenNotDEPLETEDStatus
        whenWithdrawalAddressNotZero
        whenNonZeroWithdrawAmount
        whenWithdrawAmountNotOverdraw
        whenWithdrawalAddressRecipient
        whenCallerSender
        givenEndTimeInFuture
        givenNotCanceledStream
        givenRecipientAllowedToHook
        whenNonRevertingRecipient
    {
        // Allow the recipient to hook.
        resetPrank({ msgSender: users.admin });
        lockup.allowToHook(address(recipientInvalidSelector));
        resetPrank({ msgSender: users.sender });

        // Create the stream with a recipient contract that returns invalid selector bytes on the hook call.
        uint256 streamId = createDefaultStreamWithRecipient(address(recipientInvalidSelector));

        // Expect a revert.
        uint128 withdrawAmount = defaults.WITHDRAW_AMOUNT();
        vm.expectRevert(
            abi.encodeWithSelector(Errors.SablierLockup_InvalidHookSelector.selector, address(recipientInvalidSelector))
        );

        // Cancel the stream.
        lockup.withdraw({ streamId: streamId, to: address(recipientInvalidSelector), amount: withdrawAmount });
    }

    function test_WhenReentrancy()
        external
        whenNoDelegateCall
        givenNotNull
        givenNotDEPLETEDStatus
        whenWithdrawalAddressNotZero
        whenNonZeroWithdrawAmount
        whenWithdrawAmountNotOverdraw
        whenWithdrawalAddressRecipient
        whenCallerSender
        givenEndTimeInFuture
        givenNotCanceledStream
        givenRecipientAllowedToHook
        whenNonRevertingRecipient
        whenHookReturnsValidSelector
    {
        // Allow the recipient to hook.
        resetPrank({ msgSender: users.admin });
        lockup.allowToHook(address(recipientReentrant));
        resetPrank({ msgSender: users.sender });

        // Create the stream with a reentrant contract as the stream's recipient.
        uint256 streamId = createDefaultStreamWithRecipient(address(recipientReentrant));

        // Halve the withdraw amount so that the recipient can re-entry and make another withdrawal.
        uint128 withdrawAmount = defaults.WITHDRAW_AMOUNT() / 2;

        // It should make Sablier run the recipient hook.
        vm.expectCall(
            address(recipientReentrant),
            abi.encodeCall(
                ISablierLockupRecipient.onSablierLockupWithdraw,
                (streamId, users.sender, address(recipientReentrant), withdrawAmount)
            )
        );

        // It should make multiple withdrawals.
        lockup.withdraw({ streamId: streamId, to: address(recipientReentrant), amount: withdrawAmount });

        // Assert that the stream's status is still "STREAMING".
        Lockup.Status actualStatus = lockup.statusOf(streamId);
        Lockup.Status expectedStatus = Lockup.Status.STREAMING;
        assertEq(actualStatus, expectedStatus);

        // It should update the withdrawn amounts.
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(streamId);
        uint128 expectedWithdrawnAmount = defaults.WITHDRAW_AMOUNT();
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount, "withdrawnAmount");
    }

    function test_WhenNoReentrancy()
        external
        whenNoDelegateCall
        givenNotNull
        givenNotDEPLETEDStatus
        whenWithdrawalAddressNotZero
        whenNonZeroWithdrawAmount
        whenWithdrawAmountNotOverdraw
        whenWithdrawalAddressRecipient
        whenCallerSender
        givenEndTimeInFuture
        givenNotCanceledStream
        givenRecipientAllowedToHook
        whenNonRevertingRecipient
        whenHookReturnsValidSelector
    {
        // Allow the recipient to hook.
        resetPrank({ msgSender: users.admin });
        lockup.allowToHook(address(recipientGood));
        resetPrank({ msgSender: users.sender });

        // Create the stream with a contract as the stream's recipient.
        uint256 streamId = createDefaultStreamWithRecipient(address(recipientGood));

        // Set the withdraw amount to the default amount.
        uint128 withdrawAmount = defaults.WITHDRAW_AMOUNT();

        // Expect the assets to be transferred to the recipient contract.
        expectCallToTransfer({ to: address(recipientGood), value: withdrawAmount });

        // It should make Sablier run the recipient hook.
        vm.expectCall(
            address(recipientGood),
            abi.encodeCall(
                ISablierLockupRecipient.onSablierLockupWithdraw,
                (streamId, users.sender, address(recipientGood), withdrawAmount)
            )
        );

        // It should emit {WithdrawFromLockupStream} and {MetadataUpdate} events.
        vm.expectEmit({ emitter: address(lockup) });
        emit WithdrawFromLockupStream({
            streamId: streamId,
            to: address(recipientGood),
            asset: dai,
            amount: withdrawAmount
        });
        vm.expectEmit({ emitter: address(lockup) });
        emit MetadataUpdate({ _tokenId: streamId });

        // Make the withdrawal.
        lockup.withdraw({ streamId: streamId, to: address(recipientGood), amount: withdrawAmount });

        // Assert that the stream's status is still "STREAMING".
        Lockup.Status actualStatus = lockup.statusOf(streamId);
        Lockup.Status expectedStatus = Lockup.Status.STREAMING;
        assertEq(actualStatus, expectedStatus);

        // It should update the withdrawn amount.
        uint128 actualWithdrawnAmount = lockup.getWithdrawnAmount(streamId);
        uint128 expectedWithdrawnAmount = withdrawAmount;
        assertEq(actualWithdrawnAmount, expectedWithdrawnAmount, "withdrawnAmount");
    }
}
