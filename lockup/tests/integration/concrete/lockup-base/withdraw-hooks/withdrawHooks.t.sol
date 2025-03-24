// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.22 <0.9.0;

import { ISablierLockupRecipient } from "src/interfaces/ISablierLockupRecipient.sol";

import { Integration_Test } from "../../../Integration.t.sol";

contract WithdrawHooks_Integration_Concrete_Test is Integration_Test {
    // A stream ID with a different sender and recipient.
    uint256 internal differentSenderRecipientStreamId;

    uint128 internal withdrawAmount;

    function setUp() public virtual override {
        Integration_Test.setUp();

        differentSenderRecipientStreamId = createDefaultStreamWithRecipient(address(recipientGood));
        withdrawAmount = defaults.WITHDRAW_AMOUNT();
    }

    function test_GivenRecipientSameAsSender() external {
        uint256 identicalSenderRecipientStreamId = createDefaultStreamWithUsers(users.sender, users.sender);

        // Simulate the passage of time.
        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });

        // It should not make Sablier run the user hook.
        vm.expectCall({
            callee: users.sender,
            data: abi.encodeCall(
                ISablierLockupRecipient.onSablierLockupWithdraw,
                (identicalSenderRecipientStreamId, users.sender, users.sender, withdrawAmount)
            ),
            count: 0
        });

        // Make the withdrawal.
        lockup.withdraw({ streamId: identicalSenderRecipientStreamId, to: users.sender, amount: withdrawAmount });
    }

    function test_WhenCallerUnknown() external givenRecipientNotSameAsSender {
        // Make the unknown address the caller in this test.
        address unknownCaller = address(0xCAFE);
        setMsgSender(unknownCaller);

        // Simulate the passage of time.
        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });

        // It should make Sablier run the recipient hook.
        vm.expectCall({
            callee: address(recipientGood),
            data: abi.encodeCall(
                ISablierLockupRecipient.onSablierLockupWithdraw,
                (differentSenderRecipientStreamId, unknownCaller, address(recipientGood), withdrawAmount)
            ),
            count: 1
        });

        // Make the withdrawal.
        lockup.withdraw({
            streamId: differentSenderRecipientStreamId,
            to: address(recipientGood),
            amount: withdrawAmount
        });
    }

    function test_WhenCallerApprovedThirdParty() external givenRecipientNotSameAsSender {
        // Approve the operator to handle the stream.
        setMsgSender(address(recipientGood));
        lockup.approve({ to: users.operator, tokenId: differentSenderRecipientStreamId });

        // Make the operator the caller in this test.
        setMsgSender(users.operator);

        // Simulate the passage of time.
        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });

        // It should make Sablier run the recipient hook.
        vm.expectCall({
            callee: address(recipientGood),
            data: abi.encodeCall(
                ISablierLockupRecipient.onSablierLockupWithdraw,
                (differentSenderRecipientStreamId, users.operator, address(recipientGood), withdrawAmount)
            ),
            count: 1
        });

        // Make the withdrawal.
        lockup.withdraw({
            streamId: differentSenderRecipientStreamId,
            to: address(recipientGood),
            amount: withdrawAmount
        });
    }

    function test_WhenCallerSender() external givenRecipientNotSameAsSender {
        // Make the Sender the caller in this test.
        setMsgSender(users.sender);

        // Simulate the passage of time.
        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });

        // It should make Sablier run the recipient hook.
        vm.expectCall({
            callee: address(recipientGood),
            data: abi.encodeCall(
                ISablierLockupRecipient.onSablierLockupWithdraw,
                (differentSenderRecipientStreamId, users.sender, address(recipientGood), withdrawAmount)
            ),
            count: 1
        });

        // Make the withdrawal.
        lockup.withdraw({
            streamId: differentSenderRecipientStreamId,
            to: address(recipientGood),
            amount: withdrawAmount
        });
    }

    function test_WhenCallerRecipient() external givenRecipientNotSameAsSender {
        // Make the recipient contract the caller in this test.
        setMsgSender(address(recipientGood));

        // Simulate the passage of time.
        vm.warp({ newTimestamp: defaults.WARP_26_PERCENT() });

        // It should make Sablier run the recipient hook.
        vm.expectCall({
            callee: address(recipientGood),
            data: abi.encodeCall(
                ISablierLockupRecipient.onSablierLockupWithdraw,
                (differentSenderRecipientStreamId, address(recipientGood), address(recipientGood), withdrawAmount)
            ),
            count: 0
        });

        // Make the withdrawal.
        lockup.withdraw({
            streamId: differentSenderRecipientStreamId,
            to: address(recipientGood),
            amount: withdrawAmount
        });
    }
}
