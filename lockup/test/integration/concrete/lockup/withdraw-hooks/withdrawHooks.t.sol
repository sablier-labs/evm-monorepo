// SPDX-License-Identifier: UNLICENSED
// solhint-disable max-line-length
pragma solidity >=0.8.22 <0.9.0;

import { ISablierV2Recipient } from "src/interfaces/hooks/ISablierV2Recipient.sol";
import { ISablierV2Sender } from "src/interfaces/hooks/ISablierV2Sender.sol";

import { Integration_Test } from "../../../Integration.t.sol";
import { Withdraw_Integration_Shared_Test } from "../../../shared/lockup/withdraw.t.sol";

abstract contract WithdrawHooks_Integration_Concrete_Test is Integration_Test, Withdraw_Integration_Shared_Test {
    function setUp() public virtual override(Integration_Test, Withdraw_Integration_Shared_Test) {
        Withdraw_Integration_Shared_Test.setUp();
    }

    modifier givenDifferentSenderAndRecipient() {
        _;
    }

    function test_WithdrawHooks_CallerUnknown()
        external
        givenSenderContract
        givenRecipientContract
        givenDifferentSenderAndRecipient
    {
        address unknownCaller = address(0xCAFE);

        // Create the stream with sender and recipient as contracts.
        uint256 streamId = createDefaultStreamWithUsers(address(goodRecipient), address(goodSender));

        // Make `unknownCaller` the caller in this test.
        changePrank({ msgSender: unknownCaller });

        // Simulate the passage of time.
        vm.warp({ timestamp: defaults.WARP_26_PERCENT() });

        // Set the withdraw amount to the default amount.
        uint128 withdrawAmount = defaults.WITHDRAW_AMOUNT();

        // Expect a call to the recipient hook.
        vm.expectCall({
            callee: address(goodRecipient),
            data: abi.encodeCall(
                ISablierV2Recipient.onLockupStreamWithdrawn,
                (streamId, unknownCaller, address(goodRecipient), withdrawAmount)
                ),
            count: 1
        });

        // Expect a call to the sender hook.
        vm.expectCall({
            callee: address(goodSender),
            data: abi.encodeCall(
                ISablierV2Sender.onLockupStreamWithdrawn, (streamId, unknownCaller, address(goodRecipient), withdrawAmount)
                ),
            count: 1
        });

        // Make the withdrawal.
        lockup.withdraw({ streamId: streamId, to: address(goodRecipient), amount: withdrawAmount });
    }

    function test_WithdrawHooks_CallerApprovedOperator()
        external
        givenSenderContract
        givenRecipientContract
        givenDifferentSenderAndRecipient
    {
        // Create the stream with sender and recipient as contracts.
        uint256 streamId = createDefaultStreamWithUsers(address(goodRecipient), address(goodSender));

        // Approve the operator to handle the stream.
        changePrank({ msgSender: address(goodRecipient) });
        lockup.approve({ to: users.operator, tokenId: streamId });

        // Make the operator the caller in this test.
        changePrank({ msgSender: users.operator });

        // Simulate the passage of time.
        vm.warp({ timestamp: defaults.WARP_26_PERCENT() });

        // Set the withdraw amount to the default amount.
        uint128 withdrawAmount = defaults.WITHDRAW_AMOUNT();

        // Expect a call to the recipient hook.
        vm.expectCall({
            callee: address(goodRecipient),
            data: abi.encodeCall(
                ISablierV2Recipient.onLockupStreamWithdrawn,
                (streamId, users.operator, address(goodRecipient), withdrawAmount)
                ),
            count: 1
        });

        // Expect a call to the sender hook.
        vm.expectCall({
            callee: address(goodSender),
            data: abi.encodeCall(
                ISablierV2Sender.onLockupStreamWithdrawn, (streamId, users.operator, address(goodRecipient), withdrawAmount)
                ),
            count: 1
        });

        // Make the withdrawal.
        lockup.withdraw({ streamId: streamId, to: address(goodRecipient), amount: withdrawAmount });
    }

    function test_WithdrawHooks_CallerSender()
        external
        givenSenderContract
        givenRecipientContract
        givenDifferentSenderAndRecipient
    {
        // Create the stream with sender and recipient as contracts.
        uint256 streamId = createDefaultStreamWithUsers(address(goodRecipient), address(goodSender));

        // Make the sender the caller in this test.
        changePrank({ msgSender: address(goodSender) });

        // Simulate the passage of time.
        vm.warp({ timestamp: defaults.WARP_26_PERCENT() });

        // Set the withdraw amount to the default amount.
        uint128 withdrawAmount = defaults.WITHDRAW_AMOUNT();

        // Expect 1 call to the recipient hook.
        vm.expectCall({
            callee: address(goodRecipient),
            data: abi.encodeCall(
                ISablierV2Recipient.onLockupStreamWithdrawn,
                (streamId, address(goodSender), address(goodRecipient), withdrawAmount)
                ),
            count: 1
        });

        // Expect 0 calls to the sender hook.
        vm.expectCall({
            callee: address(goodSender),
            data: abi.encodeCall(
                ISablierV2Sender.onLockupStreamWithdrawn,
                (streamId, address(goodSender), address(goodRecipient), withdrawAmount)
                ),
            count: 0
        });

        // Make the withdrawal.
        lockup.withdraw({ streamId: streamId, to: address(goodRecipient), amount: withdrawAmount });
    }

    function test_WithdrawHooks_CallerRecipient()
        external
        givenSenderContract
        givenRecipientContract
        givenDifferentSenderAndRecipient
    {
        // Create the stream with sender and recipient as contracts.
        uint256 streamId = createDefaultStreamWithUsers(address(goodRecipient), address(goodSender));

        // Make the recipient the caller in this test.
        changePrank({ msgSender: address(goodRecipient) });

        // Simulate the passage of time.
        vm.warp({ timestamp: defaults.WARP_26_PERCENT() });

        // Set the withdraw amount to the default amount.
        uint128 withdrawAmount = defaults.WITHDRAW_AMOUNT();

        // Expect 0 calls to the recipient hook.
        vm.expectCall({
            callee: address(goodRecipient),
            data: abi.encodeCall(
                ISablierV2Recipient.onLockupStreamWithdrawn,
                (streamId, address(goodRecipient), address(goodRecipient), withdrawAmount)
                ),
            count: 0
        });

        // Expect 1 call to the sender hook.
        vm.expectCall({
            callee: address(goodSender),
            data: abi.encodeCall(
                ISablierV2Sender.onLockupStreamWithdrawn,
                (streamId, address(goodRecipient), address(goodRecipient), withdrawAmount)
                ),
            count: 1
        });

        // Make the withdrawal.
        lockup.withdraw({ streamId: streamId, to: address(goodRecipient), amount: withdrawAmount });
    }

    modifier givenSameSenderAndRecipient() {
        _;
    }

    function test_WithdrawHooks_SenderHook_CallerUnknown() external givenSenderContract givenSameSenderAndRecipient {
        address unknownCaller = address(0xCAFE);

        // Create the stream with recipient which is same as the sender contract.
        uint256 streamId = createDefaultStreamToSender(address(goodSender));

        // Make unknownCaller the caller in this test.
        changePrank({ msgSender: unknownCaller });

        // Simulate the passage of time.
        vm.warp({ timestamp: defaults.WARP_26_PERCENT() });

        // Set the withdraw amount to the default amount.
        uint128 withdrawAmount = defaults.WITHDRAW_AMOUNT();

        // Expect a call to the sender hook.
        vm.expectCall({
            callee: address(goodSender),
            data: abi.encodeCall(
                ISablierV2Sender.onLockupStreamWithdrawn, (streamId, unknownCaller, address(goodSender), withdrawAmount)
                ),
            count: 1
        });

        // Make the withdrawal.
        lockup.withdraw({ streamId: streamId, to: address(goodSender), amount: withdrawAmount });
    }

    function test_WithdrawHooks_SenderHook_CallerApprovedOperator()
        external
        givenSenderContract
        givenSameSenderAndRecipient
    {
        // Create the stream with recipient which is same as the sender contract.
        uint256 streamId = createDefaultStreamToSender(address(goodSender));

        // Approve the operator to handle the stream.
        changePrank({ msgSender: address(goodSender) });
        lockup.approve({ to: users.operator, tokenId: streamId });

        // Make the operator the caller in this test.
        changePrank({ msgSender: users.operator });

        // Simulate the passage of time.
        vm.warp({ timestamp: defaults.WARP_26_PERCENT() });

        // Set the withdraw amount to the default amount.
        uint128 withdrawAmount = defaults.WITHDRAW_AMOUNT();

        // Expect a call to the sender hook.
        vm.expectCall({
            callee: address(goodSender),
            data: abi.encodeCall(
                ISablierV2Sender.onLockupStreamWithdrawn, (streamId, users.operator, address(goodSender), withdrawAmount)
                ),
            count: 1
        });

        // Make the withdrawal.
        lockup.withdraw({ streamId: streamId, to: address(goodSender), amount: withdrawAmount });
    }

    function test_WithdrawHooks_SenderHook_CallerSender() external givenSenderContract givenSameSenderAndRecipient {
        // Create the stream with the sender as the recipient.
        uint256 streamId = createDefaultStreamToSender(address(goodSender));

        // Approve the operator to handle the stream.
        changePrank({ msgSender: address(goodSender) });

        // Simulate the passage of time.
        vm.warp({ timestamp: defaults.WARP_26_PERCENT() });

        // Set the withdraw amount to the default amount.
        uint128 withdrawAmount = defaults.WITHDRAW_AMOUNT();

        // Expect 0 calls to the sender hook.
        vm.expectCall({
            callee: address(goodSender),
            data: abi.encodeCall(
                ISablierV2Sender.onLockupStreamWithdrawn,
                (streamId, address(goodSender), address(goodSender), withdrawAmount)
                ),
            count: 0
        });

        // Make the withdrawal.
        lockup.withdraw({ streamId: streamId, to: address(goodSender), amount: withdrawAmount });
    }
}
