// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierLockupRecipient } from "src/interfaces/ISablierLockupRecipient.sol";

import { Integration_Test } from "../../../Integration.t.sol";
import { Withdraw_Integration_Shared_Test } from "../../../shared/lockup/withdraw.t.sol";

abstract contract WithdrawHooks_Integration_Concrete_Test is Integration_Test, Withdraw_Integration_Shared_Test {
    uint128 internal withdrawAmount;

    function setUp() public virtual override(Integration_Test, Withdraw_Integration_Shared_Test) {
        Withdraw_Integration_Shared_Test.setUp();
        withdrawAmount = defaults.WITHDRAW_AMOUNT();

        // Allow the good recipient to hook.
        resetPrank({ msgSender: users.admin });
        lockup.allowToHook(address(recipientGood));
        resetPrank({ msgSender: users.sender });
    }

    function test_WithdrawHooks_GivenSameSenderAndRecipient() external {
        // Create a stream with identical sender and recipient.
        uint256 streamId = createDefaultStreamWithIdenticalUsers(users.sender);

        // Simulate the passage of time.
        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });

        // Expect Sablier to NOT run the user hook.
        vm.expectCall({
            callee: users.sender,
            data: abi.encodeCall(
                ISablierLockupRecipient.onSablierLockupWithdraw, (streamId, users.sender, users.sender, withdrawAmount)
            ),
            count: 0
        });

        // Make the withdrawal.
        lockup.withdraw({ streamId: streamId, to: users.sender, amount: withdrawAmount });
    }

    modifier givenDifferentSenderAndRecipient() {
        _;
    }

    function test_WithdrawHooks_CallerUnknown() external givenDifferentSenderAndRecipient {
        // Create the test stream.
        uint256 streamId = createDefaultStreamWithUsers({ recipient: address(recipientGood), sender: users.sender });

        // Make the unknown address the caller in this test.
        address unknownCaller = address(0xCAFE);
        resetPrank({ msgSender: unknownCaller });

        // Simulate the passage of time.
        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });

        // Expect Sablier to run the recipient hook.
        vm.expectCall({
            callee: address(recipientGood),
            data: abi.encodeCall(
                ISablierLockupRecipient.onSablierLockupWithdraw,
                (streamId, unknownCaller, address(recipientGood), withdrawAmount)
            ),
            count: 1
        });

        // Make the withdrawal.
        lockup.withdraw({ streamId: streamId, to: address(recipientGood), amount: withdrawAmount });
    }

    function test_WithdrawHooks_CallerApprovedOperator() external givenDifferentSenderAndRecipient {
        // Create the test stream.
        uint256 streamId = createDefaultStreamWithUsers({ recipient: address(recipientGood), sender: users.sender });

        // Approve the operator to handle the stream.
        resetPrank({ msgSender: address(recipientGood) });
        lockup.approve({ to: users.operator, tokenId: streamId });

        // Make the operator the caller in this test.
        resetPrank({ msgSender: users.operator });

        // Simulate the passage of time.
        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });

        // Expect Sablier to run the recipient hook.
        vm.expectCall({
            callee: address(recipientGood),
            data: abi.encodeCall(
                ISablierLockupRecipient.onSablierLockupWithdraw,
                (streamId, users.operator, address(recipientGood), withdrawAmount)
            ),
            count: 1
        });

        // Make the withdrawal.
        lockup.withdraw({ streamId: streamId, to: address(recipientGood), amount: withdrawAmount });
    }

    function test_WithdrawHooks_CallerSender() external givenDifferentSenderAndRecipient {
        // Create the test stream.
        uint256 streamId = createDefaultStreamWithUsers({ recipient: address(recipientGood), sender: users.sender });

        // Make the Sender the caller in this test.
        resetPrank({ msgSender: users.sender });

        // Simulate the passage of time.
        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });

        // Expect Sablier to run the recipient hook.
        vm.expectCall({
            callee: address(recipientGood),
            data: abi.encodeCall(
                ISablierLockupRecipient.onSablierLockupWithdraw,
                (streamId, users.sender, address(recipientGood), withdrawAmount)
            ),
            count: 1
        });

        // Make the withdrawal.
        lockup.withdraw({ streamId: streamId, to: address(recipientGood), amount: withdrawAmount });
    }

    function test_WithdrawHooks_CallerRecipient() external givenDifferentSenderAndRecipient {
        // Create the test stream.
        uint256 streamId = createDefaultStreamWithUsers({ recipient: address(recipientGood), sender: users.sender });

        // Make the recipient contract the caller in this test.
        resetPrank({ msgSender: address(recipientGood) });

        // Simulate the passage of time.
        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });

        // Expect Sablier to NOT run the recipient hook.
        vm.expectCall({
            callee: address(recipientGood),
            data: abi.encodeCall(
                ISablierLockupRecipient.onSablierLockupWithdraw,
                (streamId, address(recipientGood), address(recipientGood), withdrawAmount)
            ),
            count: 0
        });

        // Make the withdrawal.
        lockup.withdraw({ streamId: streamId, to: address(recipientGood), amount: withdrawAmount });
    }
}
